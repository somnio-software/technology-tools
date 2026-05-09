import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;

import '../agents/agent_config.dart';
import '../agents/agent_registry.dart';
import '../content/content_loader.dart';
import '../content/skill_registry.dart';
import '../installers/agent_installer.dart';
import '../utils/command_helpers.dart';
import '../utils/platform_utils.dart';

/// Installs skills to a specific agent or all detected agents.
///
/// Usage:
///   somnio install --agent claude
///   somnio install --agent copilot
///   somnio install --all
class InstallCommand extends Command<int> {
  InstallCommand({required Logger logger}) : _logger = logger {
    argParser.addOption(
      'agent',
      abbr: 'a',
      help: 'Target agent to install to.',
      allowed: AgentRegistry.installableAgents.map((a) => a.id).toList(),
    );
    argParser.addFlag(
      'all',
      help: 'Install to all detected agents.',
    );
    argParser.addFlag(
      'force',
      abbr: 'f',
      help: 'Force reinstall of all skills.',
    );
    argParser.addFlag(
      'all-configs',
      help: 'Claude only: install to every ~/.claude* directory found. '
          'Overrides CLAUDE_CONFIG_DIR.',
    );
  }

  final Logger _logger;

  @override
  String get name => 'install';

  @override
  String get description =>
      'Install skills to a specific agent or all detected agents.';

  @override
  Future<int> run() async {
    final agentId = argResults!['agent'] as String?;
    final installAll = argResults!['all'] as bool;
    final force = argResults!['force'] as bool;
    final allConfigs = argResults!['all-configs'] as bool;

    if (agentId == null && !installAll) {
      _logger.err('Specify --agent <name> or --all.');
      _logger.info('');
      _logger.info('Available agents:');
      for (final agent in AgentRegistry.installableAgents) {
        _logger.info('  ${agent.id.padRight(12)} ${agent.displayName}');
      }
      return ExitCode.usage.code;
    }

    if (allConfigs && installAll) {
      _logger.err('Use either --all or --all-configs, not both.');
      return ExitCode.usage.code;
    }

    if (allConfigs && agentId != 'claude') {
      _logger.err('--all-configs is only valid with --agent claude.');
      return ExitCode.usage.code;
    }

    // Resolve repo root
    final ResolvedContent content;
    try {
      content = await CommandHelpers.resolveContent();
    } catch (e) {
      _logger.err('$e');
      return ExitCode.software.code;
    }

    if (installAll) {
      return _installToAll(content.loader, content.bundles, force);
    }

    final agent = AgentRegistry.findById(agentId!);
    if (agent == null) {
      _logger.err('Unknown agent: $agentId');
      return ExitCode.usage.code;
    }

    return _installToAgent(
      agent,
      content.loader,
      content.bundles,
      force,
      allConfigs: allConfigs,
    );
  }

  Future<int> _installToAgent(
    AgentConfig agent,
    ContentLoader loader,
    List<dynamic> bundles,
    bool force, {
    bool allConfigs = false,
  }) async {
    // Check binary availability for CLI agents
    if (agent.binary != null) {
      final path = await PlatformUtils.whichBinary(agent.binary!);
      if (path == null) {
        _logger.warn(
          '${agent.displayName} CLI (${agent.binary}) not found in PATH.',
        );
        final proceed = _logger.confirm('Install skills anyway?');
        if (!proceed) return ExitCode.success.code;
      }
    }

    // Claude: resolve target dir(s) honoring CLAUDE_CONFIG_DIR or scanning
    // ~/.claude* when --all-configs is set. Other agents use the default
    // path resolution (no override).
    final targetDirs = _resolveTargetDirs(agent, allConfigs: allConfigs);

    var totalSkipped = 0;
    final locations = <String>[];

    for (final targetDir in targetDirs) {
      final progress = _logger.progress(
        targetDirs.length == 1
            ? agent.displayName
            : '${agent.displayName} (${p.basename(p.dirname(targetDir))})',
      );

      final installer = AgentInstaller(
        logger: _logger,
        loader: loader,
        agentConfig: agent,
        installDirOverride: targetDir,
      );

      final result = await installer.install(
        bundles: SkillRegistry.skills,
        force: force,
      );

      final wfCount = installer.installWorkflowSkills(
        SkillRegistry.workflowSkills,
      );
      final installed = result.skillCount + wfCount;
      totalSkipped += result.skippedCount;
      locations.add(result.targetDirectory);

      final label = agent.contentLabel;
      final plural = installed == 1 ? label : '${label}s';
      progress.complete(
        '${agent.displayName}  '
        '$installed $plural installed',
      );
    }

    if (totalSkipped > 0) {
      _logger.info(
        '  $totalSkipped '
        '${totalSkipped == 1 ? 'skill' : 'skills'} '
        'skipped (not yet supported)',
      );
    }

    _logger.info('');
    if (locations.length == 1) {
      _logger.info('Location: ${locations.first}');
    } else {
      _logger.info('Locations:');
      for (final loc in locations) {
        _logger.info('  $loc');
      }
    }

    return ExitCode.success.code;
  }

  /// Computes the install target directories for [agent].
  ///
  /// For Claude, honors [allConfigs] (scan `~/.claude*`) or falls back to the
  /// env-aware [PlatformUtils.claudeConfigDir]. For every other agent, returns
  /// an empty list so the installer uses its default `resolvedInstallPath`.
  List<String> _resolveTargetDirs(
    AgentConfig agent, {
    bool allConfigs = false,
  }) {
    if (agent.id == 'claude') {
      final bases = allConfigs
          ? PlatformUtils.discoverClaudeConfigDirs()
          : [PlatformUtils.claudeConfigDir];
      return bases.map((dir) => p.join(dir, 'skills')).toList();
    }
    // Non-Claude: defer to the agent's own resolvedInstallPath via the
    // installer, which we trigger by passing a single null override.
    return [agent.resolvedInstallPath(home: PlatformUtils.homeDirectory)];
  }

  Future<int> _installToAll(
    ContentLoader loader,
    List<dynamic> bundles,
    bool force,
  ) async {
    var totalSkills = 0;
    var agentCount = 0;

    for (final agent in AgentRegistry.installableAgents) {
      // Only auto-install to agents that are detected
      if (agent.binary != null) {
        final path = await PlatformUtils.whichBinary(agent.binary!);
        if (path == null) continue;
      }

      final progress = _logger.progress(agent.displayName);

      // For Claude this honors CLAUDE_CONFIG_DIR; for every other agent it
      // resolves the same path the installer would compute internally.
      // Multi-dir behavior (--all-configs) is intentionally not applied here.
      final targetDir = _resolveTargetDirs(agent).first;

      final installer = AgentInstaller(
        logger: _logger,
        loader: loader,
        agentConfig: agent,
        installDirOverride: targetDir,
      );

      final result = await installer.install(
        bundles: SkillRegistry.skills,
        force: force,
      );

      // Install workflow skills
      final wfCount = installer.installWorkflowSkills(
        SkillRegistry.workflowSkills,
      );
      final agentTotal = result.skillCount + wfCount;

      totalSkills += agentTotal;
      if (agentTotal > 0) agentCount++;

      final label = agent.contentLabel;
      final plural = agentTotal == 1 ? label : '${label}s';
      final parts = <String>['$agentTotal $plural'];
      if (result.skippedCount > 0) {
        parts.add('${result.skippedCount} skipped');
      }
      progress.complete(
        '${agent.displayName}  ${parts.join(', ')}',
      );
    }

    _logger.info('');
    if (agentCount > 0) {
      _logger.success(
        'Installed $totalSkills skills across $agentCount agents.',
      );
    } else {
      _logger.info('No agents detected. Run "somnio setup" for guided setup.');
    }

    return ExitCode.success.code;
  }
}
