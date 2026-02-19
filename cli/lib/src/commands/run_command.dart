import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;

import '../content/content_loader.dart';
import '../content/skill_bundle.dart';
import '../content/skill_registry.dart';
import '../runner/agent_resolver.dart';
import '../runner/plan_parser.dart';
import '../runner/preflight.dart';
import '../runner/project_validator.dart';
import '../runner/run_config.dart';
import '../runner/step_executor.dart';
import '../utils/package_resolver.dart';

/// Executes a health audit or security audit step-by-step using an AI CLI.
///
/// Each rule runs in a fresh AI context, saving findings as artifacts.
/// Must be run from the target project's directory.
///
/// Available codes are derived dynamically from [SkillRegistry] — any
/// health or security audit bundle registered via `somnio add` is
/// automatically available without code changes.
///
/// Usage: `somnio run <code>`
class RunCommand extends Command<int> {
  RunCommand({required Logger logger}) : _logger = logger {
    argParser.addOption(
      'agent',
      abbr: 'a',
      help: 'AI CLI to use (auto-detected if not specified).',
      allowed: ['claude', 'cursor', 'gemini'],
    );
    argParser.addOption(
      'model',
      abbr: 'm',
      help: 'Model to use (skips interactive selection).\n'
          'Claude: haiku (default), sonnet, opus\n'
          'Cursor: auto (default), opus-4.6-thinking, gpt-5.2, composer-1, ...\n'
          'Gemini: gemini-3-flash (default), gemini-2.5-flash, gemini-2.5-pro, gemini-3-pro',
    );
    argParser.addFlag(
      'skip-validation',
      help: 'Skip project type validation.',
    );
    argParser.addFlag(
      'no-preflight',
      help: 'Skip CLI pre-flight (version setup, pub get, test coverage).',
    );
  }

  static const _claudeModels = ['haiku', 'sonnet', 'opus'];
  static const _cursorModels = [
    'auto',
    'opus-4.6-thinking',
    'opus-4.6',
    'opus-4.5',
    'opus-4.5-thinking',
    'sonnet-4.5',
    'sonnet-4.5-thinking',
    'composer-1',
    'gpt-5.2',
    'gpt-5.2-high',
    'gpt-5.2-codex',
    'gpt-5.2-codex-high',
    'gpt-5.2-codex-low',
    'gpt-5.2-codex-xhigh',
    'gpt-5.2-codex-fast',
    'gpt-5.2-codex-high-fast',
    'gpt-5.2-codex-low-fast',
    'gpt-5.2-codex-xhigh-fast',
    'gpt-5.1-codex-max',
    'gpt-5.1-codex-max-high',
    'gpt-5.1-high',
    'gemini-3-pro',
    'gemini-3-flash',
    'grok',
  ];
  static const _geminiModels = ['gemini-3-flash', 'gemini-2.5-flash', 'gemini-2.5-pro', 'gemini-3-pro'];

  final Logger _logger;

  @override
  String get name => 'run';

  @override
  String get description => 'Execute a health or security audit from the project terminal.\n'
      '\n'
      'Run from the target project root (e.g., inside a Flutter or NestJS repo).\n'
      'The CLI handles setup steps (tool install, version alignment, tests)\n'
      'via pre-flight, then delegates analysis steps to an AI CLI.\n'
      '\n'
      'Artifacts are saved to ./reports/.artifacts/ and the final report\n'
      'to ./reports/{tech}_audit.txt.';

  @override
  String get invocation => 'somnio run <code>';

  /// Returns all runnable audit bundles from the registry.
  ///
  /// Runnable audits are identified by `id` ending with `_health` or `_audit`.
  List<SkillBundle> get _runnableBundles =>
      SkillRegistry.skills
          .where((b) => b.id.endsWith('_health') || b.id.endsWith('_audit'))
          .toList();

  /// Derives the short code from a bundle name.
  ///
  /// `somnio-fh` → `fh`, `somnio-nh` → `nh`
  String _codeFromBundle(SkillBundle bundle) =>
      bundle.name.replaceFirst('somnio-', '');

  // techPrefix, planSubDir, and templateFile are derived from
  // SkillBundle getters — no local helpers needed.

  /// Derives the template file name from the bundle's template path.
  ///
  /// `.../flutter_report_template.txt` → `flutter_report_template.txt`
  String _templateFileFromBundle(SkillBundle bundle) {
    if (bundle.templatePath == null) return '';
    return bundle.templatePath!.split('/').last;
  }

  /// Derives the report file name from the technology prefix.
  ///
  /// `flutter` → `flutter_audit.txt`
  String _reportFileFromTechPrefix(String techPrefix) =>
      '${techPrefix}_audit.txt';

  /// Finds an audit bundle by its short code.
  SkillBundle? _findBundleByCode(String code) {
    for (final bundle in _runnableBundles) {
      if (_codeFromBundle(bundle) == code) return bundle;
    }
    return null;
  }

  @override
  Future<int> run() async {
    final bundles = _runnableBundles;

    // 1. Parse and validate the short code
    final code = argResults!.rest.firstOrNull;
    final bundle = code != null ? _findBundleByCode(code) : null;

    if (code == null || bundle == null) {
      _logger.err(
        code == null
            ? 'Missing required argument: audit code.'
            : 'Unknown audit code: "$code".',
      );
      _logger.info('');
      _logger.info('Available codes:');
      for (final b in bundles) {
        _logger.info(
          '  ${_codeFromBundle(b).padRight(4)} — ${b.displayName}',
        );
      }
      _logger.info('');
      _logger.info('Usage: somnio run <code>');
      if (bundles.isNotEmpty) {
        _logger.info(
          'Example: somnio run ${_codeFromBundle(bundles.first)}',
        );
      }
      return ExitCode.usage.code;
    }

    final techPrefix = bundle.techPrefix;
    final cwd = Directory.current.path;

    // 2. Validate project type
    final skipValidation = argResults!['skip-validation'] as bool;
    if (!skipValidation) {
      final validator = ProjectValidator();
      final error = validator.validate(techPrefix, cwd);
      if (error != null) {
        _logger.err(error);
        return ExitCode.usage.code;
      }
      _logger.info(
        '${lightGreen.wrap('OK')} ${bundle.displayName.split(' ').first} '
        'project detected.',
      );
    }

    // 3. Run pre-flight checks
    final noPreflight = argResults!['no-preflight'] as bool;
    var preflightResult = PreflightResult();
    if (!noPreflight) {
      final preflight = PreflightRunner(logger: _logger);
      preflightResult = await preflight.run(techPrefix, cwd);
    }

    // 4. Resolve AI agent
    final agentFlag = argResults!['agent'] as String?;
    final agentResolver = AgentResolver();
    RunAgent agent;

    if (agentFlag != null) {
      // Explicit --agent flag: validate it exists
      RunAgent? preferredAgent;
      switch (agentFlag) {
        case 'claude':
          preferredAgent = RunAgent.claude;
        case 'cursor':
          preferredAgent = RunAgent.cursor;
        case 'gemini':
          preferredAgent = RunAgent.gemini;
      }
      final resolved = await agentResolver.resolve(preferred: preferredAgent);
      if (resolved == null) {
        final String target;
        switch (preferredAgent!) {
          case RunAgent.claude:
            target = 'claude';
          case RunAgent.cursor:
            target = 'agent (Cursor CLI)';
          case RunAgent.gemini:
            target = 'gemini';
        }
        _logger.err(
          'No AI CLI found. Please install $target.\n'
          '  Claude Code:  https://claude.ai/download\n'
          '  Cursor CLI:   https://docs.cursor.com/cli\n'
          '  Gemini CLI:   npm install -g @google/gemini-cli',
        );
        return ExitCode.software.code;
      }
      agent = resolved;
    } else {
      // No flag: detect all available, prompt if more than one
      final available = await agentResolver.detectAll();
      if (available.isEmpty) {
        _logger.err(
          'No AI CLI found. Please install claude, agent (Cursor CLI), or gemini.\n'
          '  Claude Code:  https://claude.ai/download\n'
          '  Cursor CLI:   https://docs.cursor.com/cli\n'
          '  Gemini CLI:   npm install -g @google/gemini-cli',
        );
        return ExitCode.software.code;
      }
      if (available.length == 1) {
        agent = available.first;
      } else {
        // Interactive selection
        _logger.info('');
        _logger.info('Available AI CLIs:');
        for (var i = 0; i < available.length; i++) {
          final name = agentResolver.agentDisplayName(available[i]);
          _logger.info('  ${i + 1}. $name');
        }
        final input = _logger.prompt(
          'Select CLI (1-${available.length})',
          defaultValue: '1',
        );
        final index = int.tryParse(input);
        if (index != null && index >= 1 && index <= available.length) {
          agent = available[index - 1];
        } else {
          agent = available.first;
          _logger.warn(
            'Invalid selection, using '
            '${agentResolver.agentDisplayName(available.first)}.',
          );
        }
      }
    }
    final agentName = agentResolver.agentDisplayName(agent);
    _logger.info('${lightGreen.wrap('OK')} Using $agentName CLI.');

    // 4b. Resolve model
    final modelFlag = argResults!['model'] as String?;
    String? model;

    if (modelFlag != null) {
      final validModels = _modelsForAgent(agent);
      if (!validModels.contains(modelFlag)) {
        _logger.err(
          'Model "$modelFlag" is not valid for $agentName CLI.\n'
          'Valid models: ${validModels.join(", ")}',
        );
        return ExitCode.usage.code;
      }
      model = modelFlag;
    } else {
      final choices = _modelsForAgent(agent);
      _logger.info('');
      _logger.info('Available $agentName models:');
      for (var i = 0; i < choices.length; i++) {
        final tag = i == 0 ? ' (default)' : '';
        _logger.info('  ${i + 1}. ${choices[i]}$tag');
      }
      final input = _logger.prompt(
        'Select model (1-${choices.length})',
        defaultValue: '1',
      );
      final index = int.tryParse(input);
      if (index != null && index >= 1 && index <= choices.length) {
        model = choices[index - 1];
      } else {
        model = choices.first;
        _logger.warn('Invalid selection, using ${choices.first}.');
      }
    }
    _logger.info('${lightGreen.wrap('OK')} Model: $model');

    // 5. Resolve rule paths and verify installation
    final planSubDir = bundle.planSubDir;
    final templateFile = _templateFileFromBundle(bundle);
    final reportFile = _reportFileFromTechPrefix(techPrefix);

    final ruleBase = agentResolver.ruleBasePath(
      agent,
      bundle.name,
      planSubDir,
    );
    final templatePath = agentResolver.templatePath(
      agent,
      bundle.name,
      planSubDir,
      templateFile,
    );

    // 5. Parse plan to get execution steps
    final resolver = PackageResolver();
    final String repoRoot;
    try {
      repoRoot = await resolver.resolveRepoRoot();
    } catch (e) {
      _logger.err('$e');
      return ExitCode.software.code;
    }

    final loader = ContentLoader(repoRoot);
    final planContent = loader.loadPlan(bundle);

    final parser = PlanParser();
    final steps = parser.parse(planContent);
    if (steps.isEmpty) {
      _logger.err('No execution steps found in plan.');
      return ExitCode.software.code;
    }

    // 6. Verify skills are installed (skip rules handled by preflight)
    final preflightRuleNames = preflightResult.artifacts.keys.toSet();
    final ruleNames = steps
        .map((s) => s.ruleName)
        .where((name) => !preflightRuleNames.contains(name))
        .toList();
    if (ruleNames.isNotEmpty) {
      final verifyError = agentResolver.verifyInstallation(
        agent,
        ruleBase,
        ruleNames,
      );
      if (verifyError != null) {
        _logger.err(verifyError);
        return ExitCode.software.code;
      }
    }
    _logger.info('${lightGreen.wrap('OK')} Skills verified at: $ruleBase');

    // 7. Build RunConfig
    final artifactsDir = p.join(cwd, 'reports', '.artifacts');
    final reportPath = p.join(cwd, 'reports', reportFile);

    final config = RunConfig(
      bundleId: bundle.id,
      bundleName: bundle.name,
      displayName: bundle.displayName,
      techPrefix: techPrefix,
      agent: agent,
      steps: steps,
      ruleBasePath: ruleBase,
      templatePath: templatePath,
      artifactsDir: artifactsDir,
      reportPath: reportPath,
      model: model,
    );

    // 8. Clean previous run artifacts and report
    _cleanPreviousRun(artifactsDir, reportPath);

    // 9. Create artifacts directory
    Directory(artifactsDir).createSync(recursive: true);

    // 10. Print execution plan
    final preflightCount = steps
        .where((s) => preflightResult.artifacts.containsKey(s.ruleName))
        .length;
    final aiCount = steps.length - preflightCount;
    _logger.info('');
    _logger.info(bundle.displayName);
    _logger.info('${'=' * bundle.displayName.length}');
    _logger.info(
      'Steps: ${steps.length} '
      '($preflightCount pre-flight, $aiCount AI) | '
      'Agent: $agentName ($model)',
    );
    _logger.info('Artifacts: $artifactsDir');
    _logger.info('Report: $reportPath');
    _logger.info('');

    // 11. Execute steps
    final executor = StepExecutor(config: config, logger: _logger);
    final results = <StepResult>[];
    var aborted = false;

    for (final step in steps) {
      final mandatory = step.isMandatory ? ' [MANDATORY]' : '';
      final progress = _logger.progress(
        'Step ${step.index}/${steps.length}: '
        '${step.ruleName}$mandatory',
      );

      StepResult result;

      // Check if preflight already handled this step
      final preflightArtifact =
          preflightResult.artifacts[step.ruleName];

      if (preflightArtifact != null) {
        result = await executor.writePreflightArtifact(
          step,
          preflightArtifact,
        );
      } else if (step.ruleName.endsWith('_report_generator')) {
        result = await executor.executeReportGenerator(step);
      } else {
        result = await executor.execute(step);
      }

      results.add(result);

      if (result.success) {
        if (preflightArtifact != null) {
          progress.complete(
            'Step ${step.index}/${steps.length}: ${step.ruleName} '
            '(pre-flight)',
          );
        } else {
          progress.complete(
            'Step ${step.index}/${steps.length}: ${step.ruleName}  '
            '${_formatStepStats(result)}',
          );
        }
      } else {
        final stats = result.tokenUsage != null
            ? '  ${_formatStepStats(result)}  '
            : '';
        if (step.isMandatory) {
          progress.fail(
            'Step ${step.index}/${steps.length}: ${step.ruleName}'
            '${stats}FAILED (MANDATORY — aborting)',
          );
          if (result.errorMessage != null) {
            _logger.err(result.errorMessage!);
          }
          aborted = true;
          break;
        } else {
          progress.fail(
            'Step ${step.index}/${steps.length}: ${step.ruleName}'
            '${stats}FAILED (continuing)',
          );
          if (result.errorMessage != null) {
            _logger.warn(result.errorMessage!);
          }
        }
      }
    }

    // 11. Print summary
    _logger.info('');

    final succeeded = results.where((r) => r.success).length;
    final failed = results.where((r) => !r.success).length;
    final totalTime = results.fold<int>(
      0,
      (sum, r) => sum + r.durationSeconds,
    );
    final aiTime = results
        .where((r) => r.tokenUsage != null)
        .fold<int>(0, (sum, r) => sum + r.durationSeconds);
    final preflightTime = totalTime - aiTime;

    if (aborted) {
      _logger.err(
        'Audit ABORTED at mandatory step. '
        '$succeeded/${steps.length} steps completed.',
      );
    } else if (failed > 0) {
      _logger.warn(
        'Audit completed with warnings. '
        '$succeeded/${steps.length} steps succeeded, $failed failed.',
      );
    } else {
      _logger.success(
        'Audit completed successfully! '
        '$succeeded/${steps.length} steps in '
        '${_formatDuration(totalTime)}.',
      );
    }

    // Token usage summary
    _printUsageSummary(results, totalTime, aiTime, preflightTime);

    if (!aborted && File(reportPath).existsSync()) {
      _logger.info('');
      _logger.info('Report saved to: $reportPath');
    }

    // After a successful health audit, prompt for optional security audit
    if (!aborted && bundle.id.endsWith('_health')) {
      final securityBundle = SkillRegistry.findById('security_audit');
      if (securityBundle != null) {
        _logger.info('');
        _logger.info(
          'Would you like to run a Security Audit? '
          '(somnio run ${_codeFromBundle(securityBundle)})',
        );
        final answer = _logger.prompt(
          'Run security audit? (y/n)',
          defaultValue: 'n',
        );
        if (answer.toLowerCase() == 'y' || answer.toLowerCase() == 'yes') {
          _logger.info('');
          _logger.info(
            'Run: somnio run ${_codeFromBundle(securityBundle)}',
          );
        }
      }
    }

    return aborted ? ExitCode.software.code : ExitCode.success.code;
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final minutes = seconds ~/ 60;
    final remaining = seconds % 60;
    return '${minutes}m ${remaining}s';
  }

  /// Formats token count in K notation (e.g., 38200 → "38.2K").
  String _formatTokens(int tokens) {
    if (tokens < 1000) return '$tokens';
    final k = tokens / 1000;
    return '${k.toStringAsFixed(1)}K';
  }

  /// Formats per-step stats line: IT, OT, Time, and Cost (Claude only).
  String _formatStepStats(StepResult result) {
    final usage = result.tokenUsage;
    if (usage == null) return _formatDuration(result.durationSeconds);

    final it = _formatTokens(usage.totalInputTokens);
    final ot = _formatTokens(usage.outputTokens);
    final time = _formatDuration(result.durationSeconds);

    final buffer = StringBuffer('IT: $it  OT: $ot  Time: $time');
    if (usage.costUsd != null) {
      buffer.write('  Cost: \$${usage.costUsd!.toStringAsFixed(2)}');
    }
    return buffer.toString();
  }

  /// Prints aggregated token usage summary after all steps.
  void _printUsageSummary(
    List<StepResult> results,
    int totalTime,
    int aiTime,
    int preflightTime,
  ) {
    final aiResults = results.where((r) => r.tokenUsage != null).toList();
    if (aiResults.isEmpty) return;

    var totalInput = 0;
    var totalOutput = 0;
    var totalCost = 0.0;
    var hasCost = false;

    for (final r in aiResults) {
      final u = r.tokenUsage!;
      totalInput += u.totalInputTokens;
      totalOutput += u.outputTokens;
      if (u.costUsd != null) {
        totalCost += u.costUsd!;
        hasCost = true;
      }
    }

    const divider = '────────────────────────────────────────────────────';
    _logger.info(divider);
    _logger.info(
      'Total tokens  ─  Input: ${_formatTokens(totalInput)}  '
      'Output: ${_formatTokens(totalOutput)}',
    );
    if (hasCost) {
      _logger.info(
        'Total cost    ─  \$${totalCost.toStringAsFixed(2)}',
      );
    }
    _logger.info(
      'Total time    ─  ${_formatDuration(totalTime)}  '
      '(AI: ${_formatDuration(aiTime)} | '
      'Pre-flight: ~${_formatDuration(preflightTime)})',
    );
    _logger.info(divider);
  }

  /// Returns the valid model list for the given agent.
  List<String> _modelsForAgent(RunAgent agent) {
    switch (agent) {
      case RunAgent.claude:
        return _claudeModels;
      case RunAgent.cursor:
        return _cursorModels;
      case RunAgent.gemini:
        return _geminiModels;
    }
  }

  /// Removes previous run artifacts and report to prevent stale data.
  void _cleanPreviousRun(String artifactsDir, String reportPath) {
    final artifactsDirObj = Directory(artifactsDir);
    if (artifactsDirObj.existsSync()) {
      final files = artifactsDirObj
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.md'))
          .toList();
      if (files.isNotEmpty) {
        _logger.info(
          '${lightGreen.wrap('OK')} Cleaned ${files.length} '
          'previous artifact(s).',
        );
        for (final file in files) {
          file.deleteSync();
        }
      }
    }

    final reportFile = File(reportPath);
    if (reportFile.existsSync()) {
      reportFile.deleteSync();
      _logger.info(
        '${lightGreen.wrap('OK')} Cleaned previous report.',
      );
    }
  }
}
