import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

import '../agents/agent_config.dart';
import '../agents/agent_registry.dart';
import '../content/content_loader.dart';
import '../content/skill_registry.dart';
import '../installers/agent_installer.dart';
import '../installers/installer.dart';
import '../utils/agent_detector.dart';
import '../utils/package_resolver.dart';

/// First-time setup command.
///
/// Detects installed agents, lets the user choose which to target,
/// and installs all skills globally.
class InitCommand extends Command<int> {
  InitCommand({required Logger logger}) : _logger = logger {
    argParser.addFlag(
      'force',
      abbr: 'f',
      help: 'Skip all prompts and install to all detected agents.',
    );
  }

  final Logger _logger;

  @override
  String get name => 'init';

  @override
  String get description =>
      'Auto-detect agents, select targets, and install skills.';

  @override
  Future<int> run() async {
    final force = argResults!['force'] as bool;

    // ── Detect agents ──────────────────────────────────────────────
    final detectProgress = _logger.progress('Detecting installed AI agents');
    final detector = AgentDetector();
    final agents = await detector.detect();
    detectProgress.complete('Agent detection complete');

    _logger.info('');

    // Show CLI agent detection results
    for (final entry in agents.entries) {
      final agent = entry.key;
      final info = entry.value;
      if (info.installed) {
        _logger.info(
          '  ${lightGreen.wrap('✓')} ${agent.displayName} '
          '(${info.path ?? 'found'})',
        );
      } else if (agent.canExecute) {
        _logger.info(
          '  ${lightRed.wrap('✗')} ${agent.displayName} (not found)',
        );
      }
    }
    _logger.info('');

    // Auto-select detected CLI agents
    final detectedAgents = agents.entries
        .where((e) => e.value.installed)
        .map((e) => e.key)
        .toList();

    // ── Select agents ──────────────────────────────────────────────
    final selectedAgents = <AgentConfig>[];

    if (force) {
      selectedAgents.addAll(detectedAgents);
      selectedAgents.addAll(AgentRegistry.ideAgents);
    } else {
      // CLI agents — confirm each detected one
      if (detectedAgents.isEmpty) {
        _logger.warn('No CLI agents detected.');
      } else if (detectedAgents.length == 1) {
        final confirm = _logger.confirm(
          'Install to ${detectedAgents.first.displayName}?',
        );
        if (confirm) selectedAgents.addAll(detectedAgents);
      } else {
        for (final agent in detectedAgents) {
          final install = _logger.confirm(
            'Install to ${agent.displayName}?',
            defaultValue: true,
          );
          if (install) selectedAgents.add(agent);
        }
      }

      // IDE agents — offer each one
      final ideAgents = AgentRegistry.ideAgents;
      if (ideAgents.isNotEmpty) {
        _logger.info('');
        _logger.info('IDE agents:');
        for (final agent in ideAgents) {
          final install = _logger.confirm(
            '  Install to ${agent.displayName}?',
          );
          if (install) selectedAgents.add(agent);
        }
      }
    }

    if (selectedAgents.isEmpty) {
      _logger.info('No agents selected.');
      return ExitCode.success.code;
    }

    // ── Select technologies ────────────────────────────────────────
    _logger.info('');
    final allTechs = SkillRegistry.technologies;
    List<String> selectedTechs;

    if (allTechs.length <= 1 || force) {
      selectedTechs = allTechs;
    } else {
      final techChoice = _logger.chooseOne(
        'Which technologies do you want to install?',
        choices: ['All', ...allTechs],
        defaultValue: 'All',
      );
      selectedTechs = techChoice == 'All' ? allTechs : [techChoice];
    }

    if (selectedTechs.isEmpty) {
      _logger.info('No technologies selected.');
      return ExitCode.success.code;
    }

    // ── Install ────────────────────────────────────────────────────
    final resolver = PackageResolver();
    final String repoRoot;
    try {
      repoRoot = await resolver.resolveRepoRoot();
    } catch (e) {
      _logger.err('$e');
      return ExitCode.software.code;
    }

    final loader = ContentLoader(repoRoot);
    final bundles = SkillRegistry.byTechnologies(selectedTechs);

    _logger.info('');
    var totalSkills = 0;

    for (final agentConfig in selectedAgents) {
      final progress = _logger.progress(agentConfig.displayName);

      final installer = AgentInstaller(
        logger: _logger,
        loader: loader,
        agentConfig: agentConfig,
      );
      final result = await installer.install(
        bundles: bundles,
        force: force,
      );
      totalSkills += result.skillCount;

      progress.complete(
        '${agentConfig.displayName}  '
        '${_installSummary(result, agentConfig)}',
      );
    }

    _logger.info('');
    _logger.success(
      'Done! Installed $totalSkills skills '
      'across ${selectedAgents.length} agents.',
    );
    _logger.info('');

    // Next steps
    _logger.info('Next steps:');
    _logger.info('  Run audit:    somnio run fh');
    _logger.info('  Check status: somnio status');
    _logger.info('  Update:       somnio update');

    return ExitCode.success.code;
  }

  String _installSummary(InstallResult result, AgentConfig agent) {
    final label = agent.contentLabel;
    final plural = result.skillCount == 1 ? label : '${label}s';
    final parts = <String>['${result.skillCount} $plural'];
    if (result.skippedCount > 0) {
      parts.add('${result.skippedCount} skipped');
    }
    return parts.join(', ');
  }
}
