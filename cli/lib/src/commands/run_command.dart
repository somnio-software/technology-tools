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

/// Executes a health audit step-by-step using an AI CLI.
///
/// Each rule runs in a fresh AI context, saving findings as artifacts.
/// Must be run from the target project's directory.
///
/// Available codes are derived dynamically from [SkillRegistry] — any
/// health audit bundle registered via `somnio add` is automatically
/// available without code changes.
///
/// Usage: `somnio run <code>`
class RunCommand extends Command<int> {
  RunCommand({required Logger logger}) : _logger = logger {
    argParser.addOption(
      'agent',
      abbr: 'a',
      help: 'AI CLI to use (auto-detected if not specified).',
      allowed: ['claude', 'gemini'],
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

  final Logger _logger;

  @override
  String get name => 'run';

  @override
  String get description =>
      'Execute a health audit step-by-step using an AI CLI.';

  @override
  String get invocation => 'somnio run <code>';

  /// Returns all health audit bundles from the registry.
  ///
  /// Health audits are identified by `id` ending with `_health`.
  List<SkillBundle> get _healthBundles =>
      SkillRegistry.skills.where((b) => b.id.endsWith('_health')).toList();

  /// Derives the short code from a bundle name.
  ///
  /// `somnio-fh` → `fh`, `somnio-nh` → `nh`
  String _codeFromBundle(SkillBundle bundle) =>
      bundle.name.replaceFirst('somnio-', '');

  /// Derives the technology prefix from a bundle ID.
  ///
  /// `flutter_health` → `flutter`, `nestjs_health` → `nestjs`
  String _techPrefixFromBundle(SkillBundle bundle) =>
      bundle.id.replaceAll(RegExp(r'_health$'), '');

  /// Derives the plan subdirectory name from the bundle's plan path.
  ///
  /// `flutter-plans/flutter_project_health_audit/plan/...`
  /// → `flutter_project_health_audit`
  String _planSubDirFromBundle(SkillBundle bundle) {
    final parts = bundle.planRelativePath.split('/');
    return parts.length >= 2 ? parts[1] : bundle.id;
  }

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

  /// Finds a health audit bundle by its short code.
  SkillBundle? _findBundleByCode(String code) {
    for (final bundle in _healthBundles) {
      if (_codeFromBundle(bundle) == code) return bundle;
    }
    return null;
  }

  @override
  Future<int> run() async {
    final bundles = _healthBundles;

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

    final techPrefix = _techPrefixFromBundle(bundle);
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
    if (!noPreflight) {
      final preflight = PreflightRunner(logger: _logger);
      await preflight.run(techPrefix, cwd);
    }

    // 4. Resolve AI agent
    final agentFlag = argResults!['agent'] as String?;
    RunAgent? preferredAgent;
    if (agentFlag != null) {
      preferredAgent =
          agentFlag == 'claude' ? RunAgent.claude : RunAgent.gemini;
    }

    final agentResolver = AgentResolver();
    final agent = await agentResolver.resolve(preferred: preferredAgent);
    if (agent == null) {
      final target = preferredAgent != null
          ? (preferredAgent == RunAgent.claude ? 'claude' : 'gemini')
          : 'claude or gemini';
      _logger.err(
        'No AI CLI found. Please install $target.\n'
        '  Claude Code: https://claude.ai/download\n'
        '  Gemini CLI:  npm install -g @google/gemini-cli',
      );
      return ExitCode.software.code;
    }

    final agentName = agent == RunAgent.claude ? 'Claude' : 'Gemini';
    _logger.info('${lightGreen.wrap('OK')} Using $agentName CLI.');

    // 4. Resolve rule paths and verify installation
    final planSubDir = _planSubDirFromBundle(bundle);
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

    // 6. Verify skills are installed
    final ruleNames = steps.map((s) => s.ruleName).toList();
    final verifyError = agentResolver.verifyInstallation(
      agent,
      ruleBase,
      ruleNames,
    );
    if (verifyError != null) {
      _logger.err(verifyError);
      return ExitCode.software.code;
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
    );

    // 8. Create artifacts directory
    Directory(artifactsDir).createSync(recursive: true);

    // 9. Print execution plan
    _logger.info('');
    _logger.info(bundle.displayName);
    _logger.info('${'=' * bundle.displayName.length}');
    _logger.info('Steps: ${steps.length} | Agent: $agentName');
    _logger.info('Artifacts: $artifactsDir');
    _logger.info('Report: $reportPath');
    _logger.info('');

    // 10. Execute steps
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
      final isReportGenerator = step.ruleName.endsWith('_report_generator');

      if (isReportGenerator) {
        result = await executor.executeReportGenerator(step);
      } else {
        result = await executor.execute(step);
      }

      results.add(result);

      if (result.success) {
        progress.complete(
          'Step ${step.index}/${steps.length}: ${step.ruleName} '
          '(${_formatDuration(result.durationSeconds)})',
        );
      } else {
        if (step.isMandatory) {
          progress.fail(
            'Step ${step.index}/${steps.length}: ${step.ruleName} '
            'FAILED (MANDATORY — aborting)',
          );
          if (result.errorMessage != null) {
            _logger.err(result.errorMessage!);
          }
          aborted = true;
          break;
        } else {
          progress.fail(
            'Step ${step.index}/${steps.length}: ${step.ruleName} '
            'FAILED (continuing)',
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

    if (!aborted && File(reportPath).existsSync()) {
      _logger.info('');
      _logger.info('Report saved to: $reportPath');
    }

    return aborted ? ExitCode.software.code : ExitCode.success.code;
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final minutes = seconds ~/ 60;
    final remaining = seconds % 60;
    return '${minutes}m ${remaining}s';
  }
}
