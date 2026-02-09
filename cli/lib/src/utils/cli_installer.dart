import 'dart:io';

import 'package:mason_logger/mason_logger.dart';

import 'platform_utils.dart';

/// Information about a CLI tool that can be detected and installed.
class CliInfo {
  const CliInfo({
    required this.displayName,
    required this.binary,
    this.npmPackage,
    this.installUrl,
    this.installInstructions,
  });

  /// Human-readable name (e.g., 'Claude Code').
  final String displayName;

  /// Binary name to check on PATH (e.g., 'claude').
  final String binary;

  /// npm package name, if installable via npm.
  final String? npmPackage;

  /// URL for manual installation.
  final String? installUrl;

  /// Multi-line instructions for manual installation.
  final String? installInstructions;
}

/// Result of checking a CLI's availability.
class CliCheck {
  const CliCheck({
    required this.cli,
    required this.installed,
    this.path,
  });

  final CliInfo cli;
  final bool installed;
  final String? path;
}

/// Handles detection and installation of AI CLI tools.
class CliInstaller {
  CliInstaller({required Logger logger}) : _logger = logger;

  final Logger _logger;

  /// All known CLI tools.
  static const List<CliInfo> knownClis = [
    CliInfo(
      displayName: 'Claude Code',
      binary: 'claude',
      npmPackage: '@anthropic-ai/claude-code',
      installUrl: 'https://claude.ai/download',
    ),
    CliInfo(
      displayName: 'Cursor CLI',
      binary: 'agent',
      installUrl: 'https://cursor.com',
      installInstructions:
          '  1. Download Cursor from https://cursor.com\n'
          '  2. Open Cursor and enable the CLI:\n'
          '     Settings > General > Enable "agent" CLI command',
    ),
    CliInfo(
      displayName: 'Gemini CLI',
      binary: 'gemini',
      npmPackage: '@google/gemini-cli',
      installUrl: 'https://github.com/google-gemini/gemini-cli',
    ),
  ];

  /// Detect all known CLIs.
  Future<List<CliCheck>> detectAll() async {
    final results = <CliCheck>[];
    for (final cli in knownClis) {
      final path = await PlatformUtils.whichBinary(cli.binary);
      results.add(CliCheck(
        cli: cli,
        installed: path != null,
        path: path,
      ));
    }
    return results;
  }

  /// Check if npm is available on the system.
  Future<bool> isNpmAvailable() async {
    try {
      final result = await Process.run('npm', ['--version']);
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  /// Attempt to install a CLI via npm.
  ///
  /// Returns true if installation succeeded.
  Future<bool> installViaNpm(CliInfo cli) async {
    if (cli.npmPackage == null) return false;

    final progress = _logger.progress(
      'Installing ${cli.displayName} via npm',
    );

    try {
      final result = await Process.run(
        'npm',
        ['install', '-g', cli.npmPackage!],
        runInShell: true,
      );

      if (result.exitCode == 0) {
        progress.complete('${cli.displayName} installed');
        return true;
      } else {
        progress.fail('${cli.displayName} installation failed');
        final stderr = (result.stderr as String).trim();
        if (stderr.isNotEmpty) {
          _logger.warn(stderr);
        }
        return false;
      }
    } catch (e) {
      progress.fail('${cli.displayName} installation failed: $e');
      return false;
    }
  }

  /// Show manual installation instructions for a CLI.
  void showManualInstructions(CliInfo cli) {
    _logger.info('');
    _logger.info('  ${cli.displayName}:');
    if (cli.installInstructions != null) {
      _logger.info(cli.installInstructions!);
    } else {
      if (cli.npmPackage != null) {
        _logger.info('  npm install -g ${cli.npmPackage}');
      }
      if (cli.installUrl != null) {
        _logger.info('  Or visit: ${cli.installUrl}');
      }
    }
  }
}
