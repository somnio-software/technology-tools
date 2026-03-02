import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

import '../agents/agent_config.dart';
import '../agents/agent_registry.dart';
import '../content/content_loader.dart';
import '../content/skill_registry.dart';
import '../installers/agent_installer.dart';
import '../installers/installer.dart';
import '../utils/agent_detector.dart';
import '../utils/cli_installer.dart';
import '../utils/package_resolver.dart';

/// Full guided setup wizard.
///
/// Walks the user through:
/// 1. CLI detection and installation
/// 2. Technology selection
/// 3. Skill installation to all agents (CLI + IDE, all global)
///
/// Designed for first-time users with zero prior setup knowledge.
class SetupCommand extends Command<int> {
  SetupCommand({required Logger logger}) : _logger = logger {
    argParser.addFlag(
      'force',
      abbr: 'f',
      help: 'Skip prompts, install all CLIs and technologies.',
    );
  }

  final Logger _logger;

  @override
  String get name => 'setup';

  @override
  String get description =>
      'Full guided setup: install CLIs, detect agents, and install skills.';

  @override
  Future<int> run() async {
    final force = argResults!['force'] as bool;
    final cliInstaller = CliInstaller(logger: _logger);

    // ── Step 1: Detect CLIs ─────────────────────────────────────────
    _logger.info('');
    _logger.info(
      '${lightCyan.wrap('Step 1/4')}  Checking installed CLIs...',
    );
    _logger.info('');

    final cliChecks = await cliInstaller.detectAll();

    for (final check in cliChecks) {
      if (check.installed) {
        _logger.info(
          '  ${lightGreen.wrap('✓')} ${check.agent.displayName}'
          '  (${check.path})',
        );
      } else {
        _logger.info(
          '  ${lightRed.wrap('✗')} ${check.agent.displayName}'
          '  (not found)',
        );
      }
    }
    _logger.info('');

    // ── Step 2: Install missing CLIs ────────────────────────────────
    final missingClis = cliChecks.where((c) => !c.installed).toList();

    if (missingClis.isNotEmpty) {
      _logger.info(
        '${lightCyan.wrap('Step 2/4')}  Install missing CLIs',
      );
      _logger.info('');

      final hasNpm = await cliInstaller.isNpmAvailable();

      for (final missing in missingClis) {
        final agent = missing.agent;

        final shouldInstall = force ||
            _logger.confirm(
              'Install ${agent.displayName}?',
              defaultValue: true,
            );

        if (!shouldInstall) continue;

        if (agent.npmPackage != null && hasNpm) {
          final success = await cliInstaller.installViaNpm(agent);
          if (!success) {
            cliInstaller.showManualInstructions(agent);
          }
        } else {
          cliInstaller.showManualInstructions(agent);
          if (agent.npmPackage != null && !hasNpm) {
            _logger.warn(
              '  npm not found — install Node.js first for auto-install.',
            );
          }
        }
        _logger.info('');
      }
    } else {
      _logger.info(
        '${lightCyan.wrap('Step 2/4')}  Install missing CLIs',
      );
      _logger.success('  All CLIs already installed!');
      _logger.info('');
    }

    // ── Step 3: Select technologies ─────────────────────────────────
    _logger.info(
      '${lightCyan.wrap('Step 3/4')}  Select technologies',
    );
    _logger.info('');

    final allTechs = SkillRegistry.technologies;
    List<String> selectedTechs;

    if (force || allTechs.length <= 1) {
      selectedTechs = allTechs;
      if (!force) {
        _logger.info('  Auto-selected: ${allTechs.join(', ')}');
      }
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

    _logger.info('');

    // ── Step 4: Detect agents & install skills ──────────────────────
    _logger.info(
      '${lightCyan.wrap('Step 4/4')}  Installing skills...',
    );
    _logger.info('');

    // Re-detect to pick up any CLIs installed in step 2
    final detectProgress = _logger.progress('Detecting agents');
    final detector = AgentDetector();
    final agents = await detector.detect();
    detectProgress.complete('Agent detection complete');

    final detectedAgents = agents.entries
        .where((e) => e.value.installed)
        .map((e) => e.key)
        .toList();

    // Collect all agents to install to
    final selectedAgents = <AgentConfig>[...detectedAgents];

    // Offer IDE agents
    final ideAgents = AgentRegistry.ideAgents;
    if (ideAgents.isNotEmpty && !force) {
      _logger.info('');
      _logger.info('IDE agents:');
      for (final agent in ideAgents) {
        final install = _logger.confirm(
          '  Install to ${agent.displayName}?',
        );
        if (install) selectedAgents.add(agent);
      }
    } else if (force) {
      selectedAgents.addAll(ideAgents);
    }

    if (selectedAgents.isEmpty) {
      _logger.info('');
      _logger.err('No agents selected.');
      _logger.info('');
      _logger.info('Install at least one agent to continue:');
      _logger.info('  Claude Code: https://claude.ai/download');
      _logger.info('  Cursor:      https://cursor.com/cli');
      _logger.info(
        '  Gemini CLI:  https://github.com/google-gemini/gemini-cli',
      );
      _logger.info('  Codex CLI:   npm install -g @openai/codex');
      return ExitCode.software.code;
    }

    // Resolve repo root
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

    // Install to each agent
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
        '${_installSummary(result)}',
      );
    }

    // ── Summary ─────────────────────────────────────────────────────
    _logger.info('');
    _logger.success(
      'Setup complete! Installed $totalSkills skills '
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

  String _installSummary(InstallResult result) {
    final parts = <String>[];
    parts.add(
      '${result.skillCount} ${result.skillCount == 1 ? 'skill' : 'skills'}',
    );
    if (result.skippedCount > 0) {
      parts.add('${result.skippedCount} skipped');
    }
    return parts.join(', ');
  }
}
