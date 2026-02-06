import 'dart:convert';
import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;

/// Runs deterministic pre-flight checks before AI steps.
///
/// Pre-flight handles expensive shell operations (version management,
/// dependency installation, test coverage) so that AI steps complete
/// faster — the work is already done when they run.
///
/// If any pre-flight step fails, it logs a warning and continues.
/// The AI steps will handle whatever is left.
class PreflightRunner {
  PreflightRunner({required this.logger});

  final Logger logger;

  /// Runs pre-flight for the given technology.
  ///
  /// Returns `true` if pre-flight completed (even partially).
  /// Unknown technologies skip pre-flight silently.
  Future<bool> run(String techPrefix, String cwd) async {
    switch (techPrefix) {
      case 'flutter':
        return _runFlutterPreflight(cwd);
      case 'nestjs':
        return _runNestjsPreflight(cwd);
      default:
        return true;
    }
  }

  // ---------------------------------------------------------------------------
  // Flutter Pre-flight
  // ---------------------------------------------------------------------------

  Future<bool> _runFlutterPreflight(String cwd) async {
    logger.info('');
    logger.info('Pre-flight checks');
    logger.info('${'—' * 17}');

    // 1. Check FVM
    final fvmInstalled = await _checkFvm();
    if (!fvmInstalled) return true;

    // 2. Read required Flutter version
    final requiredVersion = _readFlutterVersion(cwd);
    if (requiredVersion == null) {
      logger.warn('  No .fvmrc or .fvm/fvm_config.json found. Skipping '
          'version alignment.');
    } else {
      logger.info(
        '  ${lightGreen.wrap('OK')} Flutter version: $requiredVersion',
      );

      // 3. Set global version
      await _fvmGlobal(requiredVersion, cwd);
    }

    // 4. Clean + pub get
    await _flutterPubGet(cwd);

    // 5. Monorepo pub get
    await _flutterMonorepoPubGet(cwd);

    // 6. Build runner
    await _flutterBuildRunner(cwd);

    // 7. Test coverage
    await _flutterTestCoverage(cwd);

    logger.info('');
    return true;
  }

  Future<bool> _checkFvm() async {
    final result = await Process.run('which', ['fvm']);
    if (result.exitCode == 0) {
      final versionResult = await Process.run('fvm', ['--version']);
      final version = (versionResult.stdout as String).trim();
      logger.info('  ${lightGreen.wrap('OK')} FVM installed ($version)');
      return true;
    }

    // Try to install FVM
    logger.info('  FVM not found. Installing...');
    final install = await Process.run(
      'dart',
      ['pub', 'global', 'activate', 'fvm'],
    );
    if (install.exitCode == 0) {
      logger.info('  ${lightGreen.wrap('OK')} FVM installed');
      return true;
    }
    logger.warn('  Could not install FVM. AI steps will handle this.');
    return false;
  }

  String? _readFlutterVersion(String cwd) {
    // Try .fvmrc (JSON: {"flutter": "3.29.3"})
    final fvmrc = File(p.join(cwd, '.fvmrc'));
    if (fvmrc.existsSync()) {
      try {
        final content = fvmrc.readAsStringSync();
        final json = jsonDecode(content) as Map<String, dynamic>;
        final version = json['flutter'] as String?;
        if (version != null && version.isNotEmpty) return version;
      } catch (_) {
        // Fall through to next method
      }
    }

    // Try .fvm/fvm_config.json
    final fvmConfig = File(p.join(cwd, '.fvm', 'fvm_config.json'));
    if (fvmConfig.existsSync()) {
      try {
        final content = fvmConfig.readAsStringSync();
        final json = jsonDecode(content) as Map<String, dynamic>;
        // Could be "flutter" or "flutterSdkVersion"
        final version = (json['flutter'] ?? json['flutterSdkVersion']) as String?;
        if (version != null && version.isNotEmpty) return version;
      } catch (_) {
        // Fall through
      }
    }

    return null;
  }

  Future<void> _fvmGlobal(String version, String cwd) async {
    // Install the version if not already installed
    final installProgress = logger.progress('  Installing Flutter $version');
    final install = await Process.run(
      'fvm',
      ['install', version],
      workingDirectory: cwd,
    );

    if (install.exitCode != 0) {
      installProgress.fail('  Failed to install Flutter $version');
      return;
    }
    installProgress.complete('  Flutter $version installed');

    // Set global
    final globalProgress = logger.progress('  Setting fvm global $version');
    final global = await Process.run(
      'fvm',
      ['global', version],
      workingDirectory: cwd,
    );

    if (global.exitCode == 0) {
      globalProgress.complete('  fvm global $version');
    } else {
      globalProgress.fail('  Failed to set fvm global $version');
    }
  }

  Future<void> _flutterPubGet(String cwd) async {
    final progress = logger.progress('  flutter pub get (root)');
    final result = await Process.run(
      'fvm',
      ['flutter', 'pub', 'get'],
      workingDirectory: cwd,
    );
    if (result.exitCode == 0) {
      progress.complete('  flutter pub get (root)');
    } else {
      progress.fail('  flutter pub get failed (root)');
    }
  }

  Future<void> _flutterMonorepoPubGet(String cwd) async {
    final dirs = <String>[];

    // Collect all packages/ and apps/ subdirectories with pubspec.yaml
    for (final parent in ['packages', 'apps']) {
      final parentDir = Directory(p.join(cwd, parent));
      if (!parentDir.existsSync()) continue;

      for (final entity in parentDir.listSync()) {
        if (entity is Directory) {
          final pubspec = File(p.join(entity.path, 'pubspec.yaml'));
          if (pubspec.existsSync()) {
            dirs.add(entity.path);
          }
        }
      }
    }

    if (dirs.isEmpty) return;

    for (final dir in dirs) {
      final name = p.basename(dir);
      final parentName = p.basename(p.dirname(dir));
      final label = '$parentName/$name';
      final progress = logger.progress('  flutter pub get ($label)');
      final result = await Process.run(
        'fvm',
        ['flutter', 'pub', 'get'],
        workingDirectory: dir,
      );
      if (result.exitCode == 0) {
        progress.complete('  flutter pub get ($label)');
      } else {
        progress.fail('  flutter pub get failed ($label)');
      }
    }
  }

  Future<void> _flutterBuildRunner(String cwd) async {
    // Check root pubspec for build_runner
    final dirs = <String>[cwd];

    // Also check monorepo subdirs
    for (final parent in ['packages', 'apps']) {
      final parentDir = Directory(p.join(cwd, parent));
      if (!parentDir.existsSync()) continue;
      for (final entity in parentDir.listSync()) {
        if (entity is Directory) {
          dirs.add(entity.path);
        }
      }
    }

    for (final dir in dirs) {
      final pubspec = File(p.join(dir, 'pubspec.yaml'));
      if (!pubspec.existsSync()) continue;

      final content = pubspec.readAsStringSync();
      if (!content.contains('build_runner')) continue;

      final name = dir == cwd ? 'root' : p.basename(dir);
      final progress = logger.progress('  build_runner ($name)');
      final result = await Process.run(
        'fvm',
        ['dart', 'run', 'build_runner', 'build', '--delete-conflicting-outputs'],
        workingDirectory: dir,
      );
      if (result.exitCode == 0) {
        progress.complete('  build_runner ($name)');
      } else {
        progress.fail('  build_runner ($name) failed');
      }
    }
  }

  Future<void> _flutterTestCoverage(String cwd) async {
    final progress = logger.progress('  flutter test --coverage');
    final result = await Process.run(
      'fvm',
      ['flutter', 'test', '--coverage'],
      workingDirectory: cwd,
    );
    if (result.exitCode == 0) {
      progress.complete('  flutter test --coverage');
    } else {
      progress.fail('  flutter test --coverage (tests may have failures)');
    }
  }

  // ---------------------------------------------------------------------------
  // NestJS Pre-flight
  // ---------------------------------------------------------------------------

  Future<bool> _runNestjsPreflight(String cwd) async {
    logger.info('');
    logger.info('Pre-flight checks');
    logger.info('${'—' * 17}');

    // 1. Check Node.js
    await _checkNode();

    // 2. Read required version and set via nvm
    final requiredVersion = _readNodeVersion(cwd);
    if (requiredVersion != null) {
      logger.info(
        '  ${lightGreen.wrap('OK')} Node version: $requiredVersion',
      );
      await _nvmUse(requiredVersion, cwd);
    }

    // 3. Detect package manager and install
    final pm = _detectPackageManager(cwd);
    await _npmInstall(pm, cwd);

    // 4. Monorepo install
    await _nestjsMonorepoInstall(pm, cwd);

    // 5. Test coverage
    await _nestjsTestCoverage(pm, cwd);

    logger.info('');
    return true;
  }

  Future<void> _checkNode() async {
    final result = await Process.run('node', ['--version']);
    if (result.exitCode == 0) {
      final version = (result.stdout as String).trim();
      logger.info('  ${lightGreen.wrap('OK')} Node.js $version');
    } else {
      logger.warn('  Node.js not found. AI steps will handle this.');
    }
  }

  String? _readNodeVersion(String cwd) {
    // Try .nvmrc
    final nvmrc = File(p.join(cwd, '.nvmrc'));
    if (nvmrc.existsSync()) {
      final version = nvmrc.readAsStringSync().trim();
      if (version.isNotEmpty) return version;
    }

    // Try .node-version
    final nodeVersion = File(p.join(cwd, '.node-version'));
    if (nodeVersion.existsSync()) {
      final version = nodeVersion.readAsStringSync().trim();
      if (version.isNotEmpty) return version;
    }

    return null;
  }

  Future<void> _nvmUse(String version, String cwd) async {
    // nvm is a shell function, must be sourced
    final progress = logger.progress('  nvm use $version');
    final result = await Process.run(
      'bash',
      [
        '-c',
        'export NVM_DIR="\$HOME/.nvm" && '
            '[ -s "\$NVM_DIR/nvm.sh" ] && . "\$NVM_DIR/nvm.sh" && '
            'nvm use $version',
      ],
      workingDirectory: cwd,
    );
    if (result.exitCode == 0) {
      progress.complete('  nvm use $version');
    } else {
      progress.fail('  nvm use $version failed');
    }
  }

  String _detectPackageManager(String cwd) {
    if (File(p.join(cwd, 'pnpm-lock.yaml')).existsSync()) return 'pnpm';
    if (File(p.join(cwd, 'yarn.lock')).existsSync()) return 'yarn';
    return 'npm';
  }

  Future<void> _npmInstall(String pm, String cwd) async {
    final progress = logger.progress('  $pm install (root)');
    final result = await Process.run(
      pm,
      ['install'],
      workingDirectory: cwd,
    );
    if (result.exitCode == 0) {
      progress.complete('  $pm install (root)');
    } else {
      progress.fail('  $pm install failed (root)');
    }
  }

  Future<void> _nestjsMonorepoInstall(String pm, String cwd) async {
    final dirs = <String>[];

    for (final parent in ['apps', 'packages', 'libs']) {
      final parentDir = Directory(p.join(cwd, parent));
      if (!parentDir.existsSync()) continue;

      for (final entity in parentDir.listSync()) {
        if (entity is Directory) {
          final packageJson = File(p.join(entity.path, 'package.json'));
          if (packageJson.existsSync()) {
            dirs.add(entity.path);
          }
        }
      }
    }

    if (dirs.isEmpty) return;

    for (final dir in dirs) {
      final name = p.basename(dir);
      final parentName = p.basename(p.dirname(dir));
      final label = '$parentName/$name';
      final progress = logger.progress('  $pm install ($label)');
      final result = await Process.run(
        pm,
        ['install'],
        workingDirectory: dir,
      );
      if (result.exitCode == 0) {
        progress.complete('  $pm install ($label)');
      } else {
        progress.fail('  $pm install failed ($label)');
      }
    }
  }

  Future<void> _nestjsTestCoverage(String pm, String cwd) async {
    // Check if test:cov script exists
    final packageJson = File(p.join(cwd, 'package.json'));
    if (!packageJson.existsSync()) return;
    final content = packageJson.readAsStringSync();
    if (!content.contains('"test:cov"')) return;

    final progress = logger.progress('  $pm run test:cov');
    final result = await Process.run(
      pm,
      ['run', 'test:cov'],
      workingDirectory: cwd,
    );
    if (result.exitCode == 0) {
      progress.complete('  $pm run test:cov');
    } else {
      progress.fail('  $pm run test:cov (tests may have failures)');
    }
  }
}
