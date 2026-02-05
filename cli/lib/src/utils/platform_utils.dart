import 'dart:io';

import 'package:path/path.dart' as p;

/// Cross-platform utility helpers.
class PlatformUtils {
  /// Returns the user's home directory.
  static String get homeDirectory {
    if (Platform.isWindows) {
      return Platform.environment['USERPROFILE'] ?? '';
    }
    return Platform.environment['HOME'] ?? '';
  }

  /// Returns the path to Claude Code's global skills directory.
  static String get claudeGlobalSkillsDir =>
      p.join(homeDirectory, '.claude', 'skills');

  /// Returns the path to Cursor's global commands directory.
  static String get cursorGlobalCommandsDir =>
      p.join(homeDirectory, '.cursor', 'commands');

  /// Returns the path to Antigravity's global directory.
  static String get antigravityGlobalDir =>
      p.join(homeDirectory, '.gemini', 'antigravity');

  /// Runs `which` (Unix) or `where` (Windows) to find a binary.
  static Future<String?> whichBinary(String binary) async {
    try {
      final cmd = Platform.isWindows ? 'where' : 'which';
      final result = await Process.run(cmd, [binary]);
      if (result.exitCode == 0) {
        return (result.stdout as String).trim().split('\n').first;
      }
    } catch (_) {}
    return null;
  }
}
