import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

import '../agents/agent_config.dart';
import '../content/content_loader.dart';
import '../content/skill_registry.dart';
import '../installers/agent_installer.dart';
import '../utils/agent_detector.dart';
import '../utils/package_resolver.dart';

/// First-time setup command.
///
/// Detects installed agents, lets the user choose which to target,
/// and installs all skills.
class InitCommand extends Command<int> {
  InitCommand({required Logger logger}) : _logger = logger {
    argParser.addFlag(
      'force',
      abbr: 'f',
      help: 'Overwrite existing skills without prompting.',
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

    // Detect agents
    final detectProgress = _logger.progress('Detecting installed AI agents');
    final detector = AgentDetector();
    final agents = await detector.detect();
    detectProgress.complete('Agent detection complete');

    _logger.info('');

    // Display detection results
    for (final entry in agents.entries) {
      final agent = entry.key;
      final info = entry.value;
      if (info.installed) {
        _logger.info(
          '  ${lightGreen.wrap('[x]')} ${agent.displayName} '
          '(${info.path ?? 'found'})',
        );
      } else {
        // Only show CLI agents as "not found"
        if (agent.canExecute) {
          _logger.info(
            '  ${lightRed.wrap('[ ]')} ${agent.displayName} (not found)',
          );
        }
      }
    }
    _logger.info('');

    // Check if any agents are installed
    final installedAgents = agents.entries
        .where((e) => e.value.installed)
        .map((e) => e.key)
        .toList();

    if (installedAgents.isEmpty) {
      _logger.err('No AI agents detected.');
      _logger.info('');
      _logger.info('Install one of the following:');
      _logger.info('  Claude Code: https://claude.ai/download');
      _logger.info('  Cursor: https://cursor.com');
      _logger.info('  Gemini CLI: https://github.com/google-gemini/gemini-cli');
      _logger.info('  Codex CLI: npm install -g @openai/codex');
      return ExitCode.software.code;
    }

    // Select agents
    List<AgentConfig> selectedAgents;
    if (installedAgents.length == 1) {
      final agentName = installedAgents.first.displayName;
      final confirm = _logger.confirm(
        'Install skills to $agentName?',
      );
      if (!confirm) return ExitCode.success.code;
      selectedAgents = installedAgents;
    } else {
      selectedAgents = <AgentConfig>[];
      for (final agent in installedAgents) {
        final install = _logger.confirm(
          'Install skills to ${agent.displayName}?',
          defaultValue: true,
        );
        if (install) selectedAgents.add(agent);
      }

      if (selectedAgents.isEmpty) {
        _logger.info('No agents selected.');
        return ExitCode.success.code;
      }
    }

    // Select technologies
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

    _logger.info('');
    _logger.info('Installing skills...');
    _logger.info('');

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

    // Install to each selected agent
    var totalSkills = 0;
    var totalRules = 0;

    for (final agentConfig in selectedAgents) {
      _logger.info('  ${agentConfig.displayName}:');

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
      totalRules += result.ruleCount;

      _logger.info('');
    }

    // Print summary
    final parts = <String>[];
    if (totalSkills > 0) parts.add('$totalSkills commands');
    if (totalRules > 0) parts.add('$totalRules rules');
    _logger.success('Done! Installed ${parts.join(', ')}.');
    _logger.info('');

    // Usage hints
    _logger.info('Usage:');
    for (final skill in bundles) {
      final hasClaudeOrCursor = selectedAgents.any(
        (a) => a.id == 'claude' || a.id == 'cursor',
      );
      if (hasClaudeOrCursor) {
        _logger.info('  /${skill.name}');
      }
    }

    return ExitCode.success.code;
  }
}
