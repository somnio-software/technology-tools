import 'dart:io';

import 'package:path/path.dart' as p;

import '../utils/platform_utils.dart';
import 'run_config.dart';

/// Resolves the AI CLI agent and verifies skill installation paths.
class AgentResolver {
  /// Auto-detects available AI CLI, preferring Claude over Gemini.
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

    // Auto-detect: try claude first, then gemini
    if (await PlatformUtils.whichBinary('claude') != null) {
      return RunAgent.claude;
    }
    if (await PlatformUtils.whichBinary('gemini') != null) {
      return RunAgent.gemini;
    }
    return null;
  }

  /// Returns the base path where rule files are installed for the given agent.
  ///
  /// - Claude: `~/.claude/skills/{bundleName}/rules/`
  /// - Gemini: `~/.gemini/antigravity/somnio_rules/{planSubDir}/cursor_rules/`
  String ruleBasePath(RunAgent agent, String bundleName, String planSubDir) {
    switch (agent) {
      case RunAgent.claude:
        return p.join(
          PlatformUtils.claudeGlobalSkillsDir,
          bundleName,
          'rules',
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
      final agentName = agent == RunAgent.claude ? 'Claude' : 'Antigravity';
      final installCmd =
          agent == RunAgent.claude ? 'somnio claude' : 'somnio antigravity';
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
  /// Claude rules are `.md` (transformed from YAML by ClaudeTransformer).
  /// Gemini rules are `.yaml` (copied as-is by AntigravityInstaller).
  String ruleExtension(RunAgent agent) => _ruleExtension(agent);

  String _ruleExtension(RunAgent agent) {
    switch (agent) {
      case RunAgent.claude:
        return '.md';
      case RunAgent.gemini:
        return '.yaml';
    }
  }

  String _binaryName(RunAgent agent) {
    switch (agent) {
      case RunAgent.claude:
        return 'claude';
      case RunAgent.gemini:
        return 'gemini';
    }
  }
}
