import 'dart:io';

import 'package:path/path.dart' as p;

import '../utils/platform_utils.dart';
import 'run_config.dart';

/// Resolves the AI CLI agent and verifies skill installation paths.
class AgentResolver {
  /// Auto-detects available AI CLI, preferring Claude > Cursor > Gemini.
  ///
  /// If [preferred] is provided, only checks for that specific agent.
  /// Returns the resolved [RunAgent], or `null` if none found.
  Future<RunAgent?> resolve({RunAgent? preferred}) async {
    if (preferred != null) {
      final binary = _binaryName(preferred);
      final path = await PlatformUtils.whichBinary(binary);
      if (path != null) return preferred;
      return null;
    }

    // Auto-detect: try claude first, then cursor, then gemini
    if (await PlatformUtils.whichBinary('claude') != null) {
      return RunAgent.claude;
    }
    if (await PlatformUtils.whichBinary('agent') != null) {
      return RunAgent.cursor;
    }
    if (await PlatformUtils.whichBinary('gemini') != null) {
      return RunAgent.gemini;
    }
    return null;
  }

  /// Returns the base path where rule files are installed for the given agent.
  ///
  /// - Claude: `~/.claude/skills/{bundleName}/rules/`
  /// - Cursor: `~/.cursor/somnio_rules/{planSubDir}/cursor_rules/`
  /// - Gemini: `~/.gemini/antigravity/somnio_rules/{planSubDir}/cursor_rules/`
  String ruleBasePath(RunAgent agent, String bundleName, String planSubDir) {
    switch (agent) {
      case RunAgent.claude:
        return p.join(
          PlatformUtils.claudeGlobalSkillsDir,
          bundleName,
          'rules',
        );
      case RunAgent.cursor:
        return p.join(
          PlatformUtils.cursorGlobalRulesDir,
          planSubDir,
          'cursor_rules',
        );
      case RunAgent.gemini:
        return p.join(
          PlatformUtils.antigravityGlobalDir,
          'somnio_rules',
          planSubDir,
          'cursor_rules',
        );
    }
  }

  /// Returns the template file path for the given agent and bundle.
  ///
  /// - Claude: `~/.claude/skills/{bundleName}/templates/{templateFile}`
  /// - Cursor: `~/.cursor/somnio_rules/{planSubDir}/cursor_rules/templates/{templateFile}`
  /// - Gemini: `~/.gemini/antigravity/somnio_rules/{planSubDir}/cursor_rules/templates/{templateFile}`
  String templatePath(
    RunAgent agent,
    String bundleName,
    String planSubDir,
    String templateFile,
  ) {
    switch (agent) {
      case RunAgent.claude:
        return p.join(
          PlatformUtils.claudeGlobalSkillsDir,
          bundleName,
          'templates',
          templateFile,
        );
      case RunAgent.cursor:
        return p.join(
          PlatformUtils.cursorGlobalRulesDir,
          planSubDir,
          'cursor_rules',
          'templates',
          templateFile,
        );
      case RunAgent.gemini:
        return p.join(
          PlatformUtils.antigravityGlobalDir,
          'somnio_rules',
          planSubDir,
          'cursor_rules',
          'templates',
          templateFile,
        );
    }
  }

  /// Verifies that the rule files exist at the expected location.
  ///
  /// Returns `null` if OK, or an error message describing the issue.
  String? verifyInstallation(
    RunAgent agent,
    String ruleBasePath,
    List<String> ruleNames,
  ) {
    final dir = Directory(ruleBasePath);
    if (!dir.existsSync()) {
      final String agentName;
      final String installCmd;
      switch (agent) {
        case RunAgent.claude:
          agentName = 'Claude';
          installCmd = 'somnio claude';
        case RunAgent.cursor:
          agentName = 'Cursor CLI';
          installCmd = 'somnio cursor';
        case RunAgent.gemini:
          agentName = 'Antigravity';
          installCmd = 'somnio antigravity';
      }
      return 'Skills not found at: $ruleBasePath\n'
          'Run "$installCmd" first to install skills for $agentName.';
    }

    // Check that the first rule file exists
    final extension = _ruleExtension(agent);
    final firstRule = File(p.join(ruleBasePath, '${ruleNames.first}$extension'));
    if (!firstRule.existsSync()) {
      return 'Rule file not found: ${firstRule.path}\n'
          'Skills may be outdated. Run "somnio update" to reinstall.';
    }

    return null;
  }

  /// Returns the file extension for rule files per agent.
  ///
  /// Claude and Cursor rules are `.md` (transformed from YAML).
  /// Gemini rules are `.yaml` (copied as-is).
  String ruleExtension(RunAgent agent) => _ruleExtension(agent);

  String _ruleExtension(RunAgent agent) {
    switch (agent) {
      case RunAgent.claude:
      case RunAgent.cursor:
        return '.md';
      case RunAgent.gemini:
        return '.yaml';
    }
  }

  /// Returns all AI CLIs found in PATH.
  Future<List<RunAgent>> detectAll() async {
    final available = <RunAgent>[];
    if (await PlatformUtils.whichBinary('claude') != null) {
      available.add(RunAgent.claude);
    }
    if (await PlatformUtils.whichBinary('agent') != null) {
      available.add(RunAgent.cursor);
    }
    if (await PlatformUtils.whichBinary('gemini') != null) {
      available.add(RunAgent.gemini);
    }
    return available;
  }

  /// Returns a human-readable display name for the given agent.
  String agentDisplayName(RunAgent agent) {
    switch (agent) {
      case RunAgent.claude:
        return 'Claude';
      case RunAgent.cursor:
        return 'Cursor';
      case RunAgent.gemini:
        return 'Gemini';
    }
  }

  String _binaryName(RunAgent agent) {
    switch (agent) {
      case RunAgent.claude:
        return 'claude';
      case RunAgent.cursor:
        return 'agent';
      case RunAgent.gemini:
        return 'gemini';
    }
  }
}
