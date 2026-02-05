import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;

import '../utils/platform_utils.dart';

/// Shows the current installation status of all agents.
class StatusCommand extends Command<int> {
  StatusCommand({required Logger logger}) : _logger = logger;

  final Logger _logger;

  @override
  String get name => 'status';

  @override
  String get description => 'Show what skills are installed and where.';

  @override
  Future<int> run() async {
    _logger.info('');
    _logger.info('Somnio Skills Status:');
    _logger.info('');

    // Table header
    _logger.info(
      'Agent         | Status    | Location'
      '                        | Skills',
    );
    _logger.info(
      '------------- | --------- | ------'
      '------------------------ | ------',
    );

    // Claude Code
    _printClaudeStatus();

    // Cursor
    _printCursorStatus();

    // Antigravity
    _printAntigravityStatus();

    _logger.info('');
    return ExitCode.success.code;
  }

  void _printClaudeStatus() {
    final globalDir = PlatformUtils.claudeGlobalSkillsDir;
    final dir = Directory(globalDir);
    final skills = <String>[];

    if (dir.existsSync()) {
      for (final entity in dir.listSync()) {
        if (entity is Directory &&
            p.basename(entity.path).startsWith('somnio-')) {
          skills.add(p.basename(entity.path));
        }
      }
    }

    if (skills.isNotEmpty) {
      _logger.info(
        'Claude Code   | ${lightGreen.wrap('Installed')} '
        '| ~/.claude/skills/'
        '               | ${skills.join(', ')}',
      );
    } else {
      _logger.info(
        'Claude Code   | ${lightRed.wrap('Not found')} '
        '| -'
        '                              | -',
      );
    }
  }

  void _printCursorStatus() {
    final cwd = Directory.current.path;
    final commandsDir = Directory(p.join(cwd, '.cursor', 'commands'));
    final commands = <String>[];

    if (commandsDir.existsSync()) {
      for (final entity in commandsDir.listSync()) {
        if (entity is File &&
            entity.path.endsWith('.md') &&
            p.basename(entity.path).startsWith('somnio-')) {
          commands.add(
            p.basenameWithoutExtension(entity.path),
          );
        }
      }
    }

    if (commands.isNotEmpty) {
      _logger.info(
        'Cursor        | ${lightGreen.wrap('Installed')} '
        '| .cursor/commands/'
        '               | ${commands.join(', ')}',
      );
    } else {
      _logger.info(
        'Cursor        | ${lightRed.wrap('Not found')} '
        '| -'
        '                              | -',
      );
    }
  }

  void _printAntigravityStatus() {
    final cwd = Directory.current.path;
    final workflowsDir = Directory(p.join(cwd, '.agent', 'workflows'));
    var count = 0;

    if (workflowsDir.existsSync()) {
      count = workflowsDir
          .listSync()
          .whereType<File>()
          .where((f) => p.basename(f.path).startsWith('somnio_'))
          .length;
    }

    if (count > 0) {
      _logger.info(
        'Antigravity   | ${lightGreen.wrap('Installed')} '
        '| .agent/workflows/'
        '               | $count workflows',
      );
    } else {
      _logger.info(
        'Antigravity   | ${lightRed.wrap('Not found')} '
        '| -'
        '                              | -',
      );
    }
  }
}
