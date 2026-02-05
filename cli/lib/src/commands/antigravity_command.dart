import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

import '../content/content_loader.dart';
import '../content/skill_registry.dart';
import '../installers/antigravity_installer.dart';
import '../utils/package_resolver.dart';

/// Installs workflows into Antigravity.
class AntigravityCommand extends Command<int> {
  AntigravityCommand({required Logger logger}) : _logger = logger {
    argParser
      ..addFlag(
        'project',
        help: 'Install to .agent/ in current directory (default).',
        defaultsTo: true,
      )
      ..addFlag(
        'force',
        abbr: 'f',
        help: 'Overwrite existing workflows without prompting.',
      );
  }

  final Logger _logger;

  @override
  String get name => 'antigravity';

  @override
  String get description => 'Install workflows into Antigravity.';

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
      projectPath: Directory.current.path,
      force: force,
    );

    if (result.skillCount > 0 || result.ruleCount > 0) {
      _logger.success(
        '\nInstalled ${result.skillCount} workflows and '
        '${result.ruleCount} rule files to Antigravity.',
      );
      _logger.info('Location: ${result.targetDirectory}');
    }

    return ExitCode.success.code;
  }
}
