import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

import 'commands/add_command.dart';
import 'commands/antigravity_command.dart';
import 'commands/claude_command.dart';
import 'commands/cursor_command.dart';
import 'commands/init_command.dart';
import 'commands/status_command.dart';
import 'commands/uninstall_command.dart';
import 'commands/update_command.dart';

/// The main CLI runner for the Somnio tool.
class SomnioCliRunner extends CommandRunner<int> {
  SomnioCliRunner({Logger? logger})
      : _logger = logger ?? Logger(),
        super(
          'somnio',
          'Install Somnio AI agent skills from technology-tools.',
        ) {
    argParser.addFlag(
      'version',
      abbr: 'v',
      negatable: false,
      help: 'Print the current version.',
    );

    addCommand(AddCommand(logger: _logger));
    addCommand(InitCommand(logger: _logger));
    addCommand(UpdateCommand(logger: _logger));
    addCommand(ClaudeCommand(logger: _logger));
    addCommand(CursorCommand(logger: _logger));
    addCommand(AntigravityCommand(logger: _logger));
    addCommand(StatusCommand(logger: _logger));
    addCommand(UninstallCommand(logger: _logger));
  }

  final Logger _logger;

  static const version = '1.0.0';

  @override
  Future<int> run(Iterable<String> args) async {
    try {
      final topLevelResults = parse(args);
      return await runCommand(topLevelResults) ?? ExitCode.success.code;
    } on FormatException catch (e) {
      _logger
        ..err(e.message)
        ..info('')
        ..info(usage);
      return ExitCode.usage.code;
    } on UsageException catch (e) {
      _logger
        ..err(e.message)
        ..info('')
        ..info(e.usage);
      return ExitCode.usage.code;
    } catch (e) {
      _logger.err('$e');
      return ExitCode.software.code;
    }
  }

  @override
  Future<int?> runCommand(ArgResults topLevelResults) async {
    if (topLevelResults['version'] as bool) {
      _logger.info('somnio v$version');
      return ExitCode.success.code;
    }
    return super.runCommand(topLevelResults);
  }
}
