import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

import '../content/content_loader.dart';
import '../content/skill_registry.dart';
import '../installers/antigravity_installer.dart';
import '../installers/claude_installer.dart';
import '../installers/cursor_installer.dart';
import '../utils/package_resolver.dart';

/// Updates the CLI and reinstalls all skills.
class UpdateCommand extends Command<int> {
  UpdateCommand({required Logger logger}) : _logger = logger;

  final Logger _logger;

  static const _repoUrl =
      'https://github.com/somnio-software/technology-tools';

  @override
  String get name => 'update';

  @override
  String get description =>
      'Update CLI to latest version and reinstall all skills.';

  @override
  Future<int> run() async {
    // Step 1: Update CLI from git
    final updateProgress = _logger.progress('Updating somnio CLI');
    try {
      final result = await Process.run('dart', [
        'pub',
        'global',
        'activate',
        '-sgit',
        _repoUrl,
        '--path',
        'cli',
      ]);
      if (result.exitCode != 0) {
        updateProgress.fail('Failed to update CLI');
        _logger.err(result.stderr as String);
        _logger.info('');
        _logger.info(
          'You can update manually:\n'
          '  dart pub global activate -sgit $_repoUrl --path cli',
        );
        return ExitCode.software.code;
      }
      updateProgress.complete('CLI updated');
    } catch (e) {
      updateProgress.fail('Failed to update CLI: $e');
      return ExitCode.software.code;
    }

    // Step 2: Resolve repo root
    final resolver = PackageResolver();
    final String repoRoot;
    try {
      repoRoot = await resolver.resolveRepoRoot();
    } catch (e) {
      _logger.err('$e');
      return ExitCode.software.code;
    }

    final loader = ContentLoader(repoRoot);
    final bundles = SkillRegistry.skills;

    _logger.info('');
    _logger.info('Reinstalling skills...');

    // Step 3: Detect previously installed agents and reinstall
    var updated = 0;

    // Check Claude
    final claudeInstaller = ClaudeInstaller(
      logger: _logger,
      loader: loader,
    );
    if (claudeInstaller.isInstalled()) {
      final result = await claudeInstaller.install(
        bundles: bundles,
        force: true,
      );
      _logger.info(
        '  Claude Code: ${result.skillCount} skills updated',
      );
      updated++;
    }

    // Check Cursor
    final cursorInstaller = CursorInstaller(
      logger: _logger,
      loader: loader,
    );
    if (cursorInstaller.isInstalled()) {
      final result = await cursorInstaller.install(
        bundles: bundles,
        force: true,
      );
      _logger.info(
        '  Cursor: ${result.skillCount} commands updated',
      );
      updated++;
    }

    // Check Antigravity
    final antigravityInstaller = AntigravityInstaller(
      logger: _logger,
      loader: loader,
    );
    if (antigravityInstaller.isInstalled()) {
      final result = await antigravityInstaller.install(
        bundles: bundles,
        force: true,
      );
      _logger.info(
        '  Antigravity: ${result.skillCount} workflows, '
        '${result.ruleCount} rules updated',
      );
      updated++;
    }

    if (updated == 0) {
      _logger.info(
        '  No previously installed agents found. '
        'Run "somnio init" to install.',
      );
    }

    _logger.info('');
    _logger.success('All up to date!');

    return ExitCode.success.code;
  }
}
