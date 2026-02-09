import 'dart:io';

import 'package:path/path.dart' as p;

import 'platform_utils.dart';

/// Supported AI coding agents.
enum AgentType { claude, cursor, antigravity }

/// Information about a detected agent.
class AgentInfo {
  const AgentInfo({required this.installed, this.path, this.version});

  final bool installed;
  final String? path;
  final String? version;

  @override
  String toString() => installed
      ? 'AgentInfo(installed, path: $path)'
      : 'AgentInfo(not installed)';
}

/// Detects which AI coding agents are installed on the system.
class AgentDetector {
  /// Detects all supported agents and returns their status.
  Future<Map<AgentType, AgentInfo>> detect() async {
    final results = await Future.wait([
      _detectClaude(),
      _detectCursor(),
      _detectAntigravity(),
    ]);
    return {
      AgentType.claude: results[0],
      AgentType.cursor: results[1],
      AgentType.antigravity: results[2],
    };
  }

  Future<AgentInfo> _detectClaude() async {
    // Check PATH for 'claude' binary
    final binPath = await PlatformUtils.whichBinary('claude');
    if (binPath != null) {
      return AgentInfo(installed: true, path: binPath);
    }

    // Check common install locations
    final locations = [
      if (Platform.isMacOS) '/usr/local/bin/claude',
      if (Platform.isLinux) '/usr/local/bin/claude',
    ];
    for (final loc in locations) {
      if (File(loc).existsSync()) {
        return AgentInfo(installed: true, path: loc);
      }
    }

    // Check if ~/.claude/ directory exists (installed but not in PATH)
    final home = PlatformUtils.homeDirectory;
    if (Directory(p.join(home, '.claude')).existsSync()) {
      return AgentInfo(installed: true, path: p.join(home, '.claude'));
    }

    return const AgentInfo(installed: false);
  }

  Future<AgentInfo> _detectCursor() async {
    // Check PATH for 'cursor' binary
    final binPath = await PlatformUtils.whichBinary('cursor');
    if (binPath != null) {
      return AgentInfo(installed: true, path: binPath);
    }

    // Check application directories
    if (Platform.isMacOS) {
      if (Directory('/Applications/Cursor.app').existsSync()) {
        return const AgentInfo(
          installed: true,
          path: '/Applications/Cursor.app',
        );
      }
    }
    if (Platform.isLinux) {
      for (final p in ['/usr/bin/cursor', '/usr/local/bin/cursor']) {
        if (File(p).existsSync()) {
          return AgentInfo(installed: true, path: p);
        }
      }
    }
    if (Platform.isWindows) {
      final appData = Platform.environment['APPDATA'];
      if (appData != null) {
        final cursorPath = p.join(appData, 'Cursor', 'Cursor.exe');
        if (File(cursorPath).existsSync()) {
          return AgentInfo(installed: true, path: cursorPath);
        }
      }
    }

    return const AgentInfo(installed: false);
  }

  Future<AgentInfo> _detectAntigravity() async {
    // Check multiple possible binary names
    for (final cmd in ['agy', 'antigravity', 'gemini']) {
      final binPath = await PlatformUtils.whichBinary(cmd);
      if (binPath != null) {
        return AgentInfo(installed: true, path: binPath);
      }
    }

    // Check global settings directory
    final home = PlatformUtils.homeDirectory;
    if (Directory(p.join(home, '.gemini', 'antigravity')).existsSync()) {
      return AgentInfo(
        installed: true,
        path: p.join(home, '.gemini', 'antigravity'),
      );
    }

    return const AgentInfo(installed: false);
  }

  /// Returns a display name for an agent type.
  static String displayName(AgentType type) {
    switch (type) {
      case AgentType.claude:
        return 'Claude Code';
      case AgentType.cursor:
        return 'Cursor';
      case AgentType.antigravity:
        return 'Antigravity';
    }
  }
}
