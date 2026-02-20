import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

import '../content/content_loader.dart';
import '../content/skill_registry.dart';
import '../installers/antigravity_installer.dart';
import '../installers/gemini_installer.dart';
import '../utils/package_resolver.dart';

/// Installs workflows into Antigravity.
class AntigravityCommand extends Command<int> {
  AntigravityCommand({required Logger logger}) : _logger = logger {
    argParser.addFlag(
      'force',
      abbr: 'f',
      help: 'Overwrite existing workflows without prompting.',
    );
  }

  final Logger _logger;

  @override
  String get name => 'antigravity';

  @override
  String get description =>
      'Install workflows into Antigravity and skills into Gemini CLI.';

  @override
  Future<int> run() async {
    final force = argResults!['force'] as bool;

    final resolver = PackageResolver();
    final String repoRoot;
    try {
      repoRoot = await resolver.resolveRepoRoot();
    } catch (e) {
      _logger.err('$e');
      return ExitCode.software.code;
    }

    final loader = ContentLoader(repoRoot);
    final installer = AntigravityInstaller(
      logger: _logger,
      loader: loader,
    );

    final result = await installer.install(
      bundles: SkillRegistry.skills,
      force: force,
    );

    if (result.skillCount > 0 || result.ruleCount > 0) {
      _logger.success(
        '\nInstalled ${result.skillCount} workflows and '
        '${result.ruleCount} rule files to Antigravity.',
      );
      _logger.info('Location: ${result.targetDirectory}');
    }

    if (result.skippedCount > 0) {
      _logger.info(
        'Skipped ${result.skippedCount} '
        '${result.skippedCount == 1 ? 'skill' : 'skills'} '
        '(workflow not yet available).',
      );
    }

    // Also install to Gemini CLI
    _logger.info('');
    final geminiInstaller = GeminiInstaller(
      logger: _logger,
      loader: loader,
    );
    final geminiResult = await geminiInstaller.install(
      bundles: SkillRegistry.skills,
      force: force,
    );

    if (geminiResult.skillCount > 0) {
      _logger.success(
        'Installed ${geminiResult.skillCount} skills to Gemini CLI.',
      );
      _logger.info('Location: ${geminiResult.targetDirectory}');
    }

    return ExitCode.success.code;
  }
}
