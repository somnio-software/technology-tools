import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;

import '../utils/platform_utils.dart';

/// Removes all Somnio-installed skills, commands, and workflows.
class UninstallCommand extends Command<int> {
  UninstallCommand({required Logger logger}) : _logger = logger;

  final Logger _logger;

  @override
  String get name => 'uninstall';

  @override
  String get description =>
      'Remove all Somnio skills, commands, and workflows.';

  @override
  Future<int> run() async {
    _logger.info('');

    var removedAnything = false;

    // Claude Code: ~/.claude/skills/somnio-*
    final claudeRemoved = _removeClaude();
    removedAnything |= claudeRemoved;

    // Cursor: .cursor/commands/somnio-*.md
    final cursorRemoved = _removeCursor();
    removedAnything |= cursorRemoved;

    // Antigravity: .agent/workflows/somnio_* + .agent/somnio_rules/
    final antigravityRemoved = _removeAntigravity();
    removedAnything |= antigravityRemoved;

    _logger.info('');
    if (removedAnything) {
      _logger.success('Uninstall complete.');
    } else {
      _logger.info('Nothing to uninstall.');
    }

    return ExitCode.success.code;
  }

  bool _removeClaude() {
    final globalDir = Directory(PlatformUtils.claudeGlobalSkillsDir);
    if (!globalDir.existsSync()) return false;

    final dirs = globalDir
        .listSync()
        .whereType<Directory>()
        .where((d) => p.basename(d.path).startsWith('somnio-'))
        .toList();

    if (dirs.isEmpty) return false;

    for (final dir in dirs) {
      final name = p.basename(dir.path);
      dir.deleteSync(recursive: true);
      _logger.info('  Removed Claude skill: $name');
    }
    return true;
  }

  bool _removeCursor() {
    final cwd = Directory.current.path;
    final commandsDir = Directory(p.join(cwd, '.cursor', 'commands'));
    if (!commandsDir.existsSync()) return false;

    final files = commandsDir
        .listSync()
        .whereType<File>()
        .where((f) =>
            f.path.endsWith('.md') &&
            p.basename(f.path).startsWith('somnio-'))
        .toList();

    if (files.isEmpty) return false;

    for (final file in files) {
      final name = p.basename(file.path);
      file.deleteSync();
      _logger.info('  Removed Cursor command: $name');
    }
    return true;
  }

  bool _removeAntigravity() {
    final cwd = Directory.current.path;
    var removed = false;

    // Remove workflow files
    final workflowsDir = Directory(p.join(cwd, '.agent', 'workflows'));
    if (workflowsDir.existsSync()) {
      final files = workflowsDir
          .listSync()
          .whereType<File>()
          .where((f) => p.basename(f.path).startsWith('somnio_'))
          .toList();

      for (final file in files) {
        final name = p.basename(file.path);
        file.deleteSync();
        _logger.info('  Removed Antigravity workflow: $name');
        removed = true;
      }
    }

    // Remove somnio_rules directory
    final rulesDir = Directory(p.join(cwd, '.agent', 'somnio_rules'));
    if (rulesDir.existsSync()) {
      rulesDir.deleteSync(recursive: true);
      _logger.info('  Removed Antigravity rules: .agent/somnio_rules/');
      removed = true;
    }

    return removed;
  }
}
