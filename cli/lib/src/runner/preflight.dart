import 'dart:convert';
import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;

/// Result of a single pre-flight phase.
class _PhaseResult {
  _PhaseResult(this.label);

  final String label;
  bool passed = true;
  final _lines = <String>[];

  void ok(String msg) => _lines.add('- $msg: PASSED');
  void info(String msg) => _lines.add('- $msg');
  void fail(String msg) {
    _lines.add('- $msg: FAILED');
    passed = false;
  }

  String toMarkdown() => _lines.join('\n');
}

/// Result of the pre-flight execution.
///
/// Contains artifact markdown content keyed by rule name. The step
/// executor uses this to skip AI invocation for pre-flight steps and
/// write the artifact directly.
class PreflightResult {
  PreflightResult();

  /// Rule name → artifact markdown content.
  final Map<String, String> artifacts = {};

  /// Whether any pre-flight step ran.
  bool get hasArtifacts => artifacts.isNotEmpty;
}

/// Runs deterministic pre-flight checks and produces artifacts that
/// replace AI steps for tool installation, version alignment, version
/// validation, and test coverage.
///
/// When running via CLI (`somnio run`), these steps are handled directly
/// by the CLI — the AI only runs the analysis steps. When running as a
/// skill in an IDE (`/somnio-fh`), all steps run via AI as before.
class PreflightRunner {
  PreflightRunner({required this.logger});

  final Logger logger;

  /// Runs pre-flight for the given technology.
  ///
  /// Returns a [PreflightResult] with artifact content per rule name.
  /// The step executor skips rules present in the result.
  /// Unknown technologies return an empty result (all steps go to AI).
  Future<PreflightResult> run(String techPrefix, String cwd) async {
    switch (techPrefix) {
      case 'flutter':
        return _runFlutterPreflight(techPrefix, cwd);
      case 'nestjs':
        return _runNestjsPreflight(techPrefix, cwd);
      default:
        return PreflightResult();
    }
  }

  // ---------------------------------------------------------------------------
  // Flutter Pre-flight
  // ---------------------------------------------------------------------------

  Future<PreflightResult> _runFlutterPreflight(
    String techPrefix,
    String cwd,
  ) async {
    final result = PreflightResult();

    logger.info('');
    logger.info('Pre-flight');
    logger.info('${'—' * 10}');

    // Phase 1: Tool Installer
    final toolPhase = _PhaseResult('Tool Installation');
    String? fvmVersion;

    final fvmWhich = await Process.run('which', ['fvm']);
    if (fvmWhich.exitCode == 0) {
      final vr = await Process.run('fvm', ['--version']);
      fvmVersion = (vr.stdout as String).trim();
      toolPhase.ok('FVM installed ($fvmVersion)');
      logger.info('  ${lightGreen.wrap('OK')} FVM ($fvmVersion)');
    } else {
      logger.info('  FVM not found. Installing...');
      final install = await Process.run(
        'dart',
        ['pub', 'global', 'activate', 'fvm'],
      );
      if (install.exitCode == 0) {
        final vr = await Process.run('fvm', ['--version']);
        fvmVersion = (vr.stdout as String).trim();
        toolPhase.ok('FVM installed ($fvmVersion)');
        logger.info('  ${lightGreen.wrap('OK')} FVM installed');
      } else {
        toolPhase.fail('FVM installation failed');
        logger.err('  FVM installation failed');
      }
    }

    final flutterVr = await Process.run('fvm', ['flutter', '--version']);
    final flutterVersionOutput = (flutterVr.stdout as String).trim();
    final flutterFirstLine = flutterVersionOutput.split('\n').first;
    toolPhase.info('Flutter SDK: $flutterFirstLine');

    result.artifacts['${techPrefix}_tool_installer'] =
        _buildArtifact('Tool Installer', toolPhase);

    // Phase 2: Version Alignment
    final alignPhase = _PhaseResult('Version Alignment');
    final requiredVersion = _readFlutterVersion(cwd);

    if (requiredVersion != null) {
      alignPhase.info('Required version: $requiredVersion (from .fvmrc)');
      logger.info(
        '  ${lightGreen.wrap('OK')} Required: $requiredVersion',
      );

      // Install version
      final installProgress = logger.progress(
        '  fvm install $requiredVersion',
      );
      final install = await Process.run(
        'fvm',
        ['install', requiredVersion],
        workingDirectory: cwd,
      );
      if (install.exitCode == 0) {
        installProgress.complete('  fvm install $requiredVersion');
        alignPhase.ok('fvm install $requiredVersion');
      } else {
        installProgress.fail('  fvm install $requiredVersion');
        alignPhase.fail('fvm install $requiredVersion');
      }

      // Set global
      final globalProgress = logger.progress(
        '  fvm global $requiredVersion',
      );
      final global = await Process.run(
        'fvm',
        ['global', requiredVersion],
        workingDirectory: cwd,
      );
      if (global.exitCode == 0) {
        globalProgress.complete('  fvm global $requiredVersion');
        alignPhase.ok('fvm global $requiredVersion');
      } else {
        globalProgress.fail('  fvm global $requiredVersion');
        alignPhase.fail('fvm global $requiredVersion');
      }
    } else {
      alignPhase.info('No .fvmrc or .fvm/fvm_config.json found');
      logger.warn('  No .fvmrc found — skipping version alignment');
    }

    // Pub get (root)
    final pubProgress = logger.progress('  flutter pub get');
    final pubResult = await Process.run(
      'fvm',
      ['flutter', 'pub', 'get'],
      workingDirectory: cwd,
    );
    if (pubResult.exitCode == 0) {
      pubProgress.complete('  flutter pub get');
      alignPhase.ok('flutter pub get (root)');
    } else {
      pubProgress.fail('  flutter pub get');
      alignPhase.fail('flutter pub get (root)');
    }

    // Monorepo pub get
    final monoDirs = _findMonorepoDirs(cwd, 'pubspec.yaml');
    for (final dir in monoDirs) {
      final label = _monoLabel(dir);
      final mp = logger.progress('  flutter pub get ($label)');
      final mr = await Process.run(
        'fvm',
        ['flutter', 'pub', 'get'],
        workingDirectory: dir,
      );
      if (mr.exitCode == 0) {
        mp.complete('  flutter pub get ($label)');
        alignPhase.ok('flutter pub get ($label)');
      } else {
        mp.fail('  flutter pub get ($label)');
        alignPhase.fail('flutter pub get ($label)');
      }
    }

    // Build runner
    final brDirs = _findBuildRunnerDirs(cwd);
    for (final dir in brDirs) {
      final label = dir == cwd ? 'root' : p.basename(dir);
      final bp = logger.progress('  build_runner ($label)');
      final br = await Process.run(
        'fvm',
        [
          'dart',
          'run',
          'build_runner',
          'build',
          '--delete-conflicting-outputs',
        ],
        workingDirectory: dir,
      );
      if (br.exitCode == 0) {
        bp.complete('  build_runner ($label)');
        alignPhase.ok('build_runner ($label)');
      } else {
        bp.fail('  build_runner ($label)');
        alignPhase.fail('build_runner ($label)');
      }
    }

    result.artifacts['${techPrefix}_version_alignment'] =
        _buildArtifact('Version Alignment', alignPhase);

    // Phase 3: Version Validator
    final validPhase = _PhaseResult('Version Validation');

    final checkVersion = await Process.run(
      'fvm',
      ['flutter', '--version'],
      workingDirectory: cwd,
    );
    final currentVersion = (checkVersion.stdout as String).trim().split('\n').first;
    validPhase.info('Current Flutter version: $currentVersion');

    if (requiredVersion != null) {
      if (currentVersion.contains(requiredVersion)) {
        validPhase.ok('Version matches required ($requiredVersion)');
        logger.info(
          '  ${lightGreen.wrap('OK')} Version verified: $requiredVersion',
        );
      } else {
        validPhase.fail(
          'Version mismatch — expected $requiredVersion, got $currentVersion',
        );
        logger.warn('  Version mismatch: $currentVersion');
      }
    }

    // Check deps resolve
    final depsResult = await Process.run(
      'fvm',
      ['flutter', 'pub', 'deps', '--style=compact'],
      workingDirectory: cwd,
    );
    if (depsResult.exitCode == 0) {
      validPhase.ok('Dependencies resolved');
    } else {
      validPhase.fail('Dependencies failed to resolve');
    }

    result.artifacts['${techPrefix}_version_validator'] =
        _buildArtifact('Version Validator', validPhase);

    // Phase 4: Test Coverage
    final coveragePhase = _PhaseResult('Test Coverage');
    final tcProgress = logger.progress('  flutter test --coverage');
    final tcResult = await Process.run(
      'fvm',
      ['flutter', 'test', '--coverage'],
      workingDirectory: cwd,
    );
    if (tcResult.exitCode == 0) {
      tcProgress.complete('  flutter test --coverage');
      coveragePhase.ok('flutter test --coverage');
    } else {
      tcProgress.fail('  flutter test --coverage');
      coveragePhase.fail('flutter test --coverage');
      final stderr = (tcResult.stderr as String).trim();
      if (stderr.isNotEmpty) {
        final lastLines = stderr.split('\n').take(10).join('\n');
        coveragePhase.info('Output:\n```\n$lastLines\n```');
      }
    }

    // Check coverage file
    final lcov = File(p.join(cwd, 'coverage', 'lcov.info'));
    if (lcov.existsSync()) {
      coveragePhase.ok('coverage/lcov.info generated');
    } else {
      coveragePhase.info('coverage/lcov.info not found');
    }

    result.artifacts['${techPrefix}_test_coverage'] =
        _buildArtifact('Test Coverage', coveragePhase);

    logger.info('');
    return result;
  }

  // ---------------------------------------------------------------------------
  // NestJS Pre-flight
  // ---------------------------------------------------------------------------

  Future<PreflightResult> _runNestjsPreflight(
    String techPrefix,
    String cwd,
  ) async {
    final result = PreflightResult();

    logger.info('');
    logger.info('Pre-flight');
    logger.info('${'—' * 10}');

    // Phase 1: Tool Installer
    final toolPhase = _PhaseResult('Tool Installation');

    final nodeResult = await Process.run('node', ['--version']);
    if (nodeResult.exitCode == 0) {
      final nodeVer = (nodeResult.stdout as String).trim();
      toolPhase.ok('Node.js installed ($nodeVer)');
      logger.info('  ${lightGreen.wrap('OK')} Node.js ($nodeVer)');
    } else {
      toolPhase.fail('Node.js not found');
      logger.err('  Node.js not found');
    }

    final npmResult = await Process.run('npm', ['--version']);
    if (npmResult.exitCode == 0) {
      toolPhase.ok('npm installed (${(npmResult.stdout as String).trim()})');
    }

    for (final pm in ['yarn', 'pnpm']) {
      final r = await Process.run('which', [pm]);
      if (r.exitCode == 0) {
        final vr = await Process.run(pm, ['--version']);
        toolPhase.ok('$pm installed (${(vr.stdout as String).trim()})');
      }
    }

    result.artifacts['${techPrefix}_tool_installer'] =
        _buildArtifact('Tool Installer', toolPhase);

    // Phase 2: Version Alignment
    final alignPhase = _PhaseResult('Version Alignment');
    final requiredVersion = _readNodeVersion(cwd);
    final pm = _detectPackageManager(cwd);
    alignPhase.info('Package manager: $pm');

    if (requiredVersion != null) {
      alignPhase.info('Required Node version: $requiredVersion');
      logger.info('  ${lightGreen.wrap('OK')} Required: $requiredVersion');

      final nvmProgress = logger.progress('  nvm use $requiredVersion');
      final nvmResult = await Process.run(
        'bash',
        [
          '-c',
          'export NVM_DIR="\$HOME/.nvm" && '
              '[ -s "\$NVM_DIR/nvm.sh" ] && . "\$NVM_DIR/nvm.sh" && '
              'nvm use $requiredVersion',
        ],
        workingDirectory: cwd,
      );
      if (nvmResult.exitCode == 0) {
        nvmProgress.complete('  nvm use $requiredVersion');
        alignPhase.ok('nvm use $requiredVersion');
      } else {
        nvmProgress.fail('  nvm use $requiredVersion');
        alignPhase.fail('nvm use $requiredVersion');
      }
    }

    // Install deps
    final installProgress = logger.progress('  $pm install');
    final installResult = await Process.run(
      pm,
      ['install'],
      workingDirectory: cwd,
    );
    if (installResult.exitCode == 0) {
      installProgress.complete('  $pm install');
      alignPhase.ok('$pm install (root)');
    } else {
      installProgress.fail('  $pm install');
      alignPhase.fail('$pm install (root)');
    }

    // Monorepo
    final monoDirs = _findMonorepoDirs(cwd, 'package.json',
        parents: ['apps', 'packages', 'libs']);
    for (final dir in monoDirs) {
      final label = _monoLabel(dir);
      final mp = logger.progress('  $pm install ($label)');
      final mr = await Process.run(pm, ['install'], workingDirectory: dir);
      if (mr.exitCode == 0) {
        mp.complete('  $pm install ($label)');
        alignPhase.ok('$pm install ($label)');
      } else {
        mp.fail('  $pm install ($label)');
        alignPhase.fail('$pm install ($label)');
      }
    }

    result.artifacts['${techPrefix}_version_alignment'] =
        _buildArtifact('Version Alignment', alignPhase);

    // Phase 3: Version Validator
    final validPhase = _PhaseResult('Version Validation');

    final currentNode = await Process.run('node', ['--version']);
    final currentNodeVer = (currentNode.stdout as String).trim();
    validPhase.info('Current Node.js version: $currentNodeVer');

    if (requiredVersion != null) {
      if (currentNodeVer.contains(requiredVersion.replaceAll('v', ''))) {
        validPhase.ok('Version matches required ($requiredVersion)');
        logger.info(
          '  ${lightGreen.wrap('OK')} Version verified: $currentNodeVer',
        );
      } else {
        validPhase.fail(
          'Version mismatch — expected $requiredVersion, got $currentNodeVer',
        );
      }
    }

    final nodeModules = Directory(p.join(cwd, 'node_modules'));
    if (nodeModules.existsSync()) {
      validPhase.ok('node_modules exists');
    } else {
      validPhase.fail('node_modules not found');
    }

    final nestCheck = File(p.join(cwd, 'package.json'));
    if (nestCheck.existsSync()) {
      final content = nestCheck.readAsStringSync();
      if (content.contains('@nestjs/core')) {
        validPhase.ok('@nestjs/core found in dependencies');
      } else {
        validPhase.fail('@nestjs/core not found in dependencies');
      }
    }

    result.artifacts['${techPrefix}_version_validator'] =
        _buildArtifact('Version Validator', validPhase);

    // Phase 4: Test Coverage
    final coveragePhase = _PhaseResult('Test Coverage');
    final pkgJson = File(p.join(cwd, 'package.json'));
    final hasTestCov = pkgJson.existsSync() &&
        pkgJson.readAsStringSync().contains('"test:cov"');

    if (hasTestCov) {
      final tcProgress = logger.progress('  $pm run test:cov');
      final tcResult = await Process.run(
        pm,
        ['run', 'test:cov'],
        workingDirectory: cwd,
      );
      if (tcResult.exitCode == 0) {
        tcProgress.complete('  $pm run test:cov');
        coveragePhase.ok('$pm run test:cov');
      } else {
        tcProgress.fail('  $pm run test:cov');
        coveragePhase.fail('$pm run test:cov');
      }
    } else {
      coveragePhase.info('No test:cov script found in package.json');
    }

    final coverageDir = Directory(p.join(cwd, 'coverage'));
    if (coverageDir.existsSync()) {
      coveragePhase.ok('coverage/ directory exists');
    }

    result.artifacts['${techPrefix}_test_coverage'] =
        _buildArtifact('Test Coverage', coveragePhase);

    logger.info('');
    return result;
  }

  // ---------------------------------------------------------------------------
  // Shared helpers
  // ---------------------------------------------------------------------------

  String? _readFlutterVersion(String cwd) {
    final fvmrc = File(p.join(cwd, '.fvmrc'));
    if (fvmrc.existsSync()) {
      try {
        final content = fvmrc.readAsStringSync();
        final json = jsonDecode(content) as Map<String, dynamic>;
        final version = json['flutter'] as String?;
        if (version != null && version.isNotEmpty) return version;
      } catch (_) {}
    }

    final fvmConfig = File(p.join(cwd, '.fvm', 'fvm_config.json'));
    if (fvmConfig.existsSync()) {
      try {
        final content = fvmConfig.readAsStringSync();
        final json = jsonDecode(content) as Map<String, dynamic>;
        final version =
            (json['flutter'] ?? json['flutterSdkVersion']) as String?;
        if (version != null && version.isNotEmpty) return version;
      } catch (_) {}
    }

    return null;
  }

  String? _readNodeVersion(String cwd) {
    for (final name in ['.nvmrc', '.node-version']) {
      final file = File(p.join(cwd, name));
      if (file.existsSync()) {
        final version = file.readAsStringSync().trim();
        if (version.isNotEmpty) return version;
      }
    }
    return null;
  }

  String _detectPackageManager(String cwd) {
    if (File(p.join(cwd, 'pnpm-lock.yaml')).existsSync()) return 'pnpm';
    if (File(p.join(cwd, 'yarn.lock')).existsSync()) return 'yarn';
    return 'npm';
  }

  List<String> _findMonorepoDirs(
    String cwd,
    String marker, {
    List<String> parents = const ['packages', 'apps'],
  }) {
    final dirs = <String>[];
    for (final parent in parents) {
      final parentDir = Directory(p.join(cwd, parent));
      if (!parentDir.existsSync()) continue;
      for (final entity in parentDir.listSync()) {
        if (entity is Directory) {
          final file = File(p.join(entity.path, marker));
          if (file.existsSync()) dirs.add(entity.path);
        }
      }
    }
    return dirs;
  }

  List<String> _findBuildRunnerDirs(String cwd) {
    final dirs = <String>[];
    final candidates = [cwd, ..._findMonorepoDirs(cwd, 'pubspec.yaml')];
    for (final dir in candidates) {
      final pubspec = File(p.join(dir, 'pubspec.yaml'));
      if (pubspec.existsSync() &&
          pubspec.readAsStringSync().contains('build_runner')) {
        dirs.add(dir);
      }
    }
    return dirs;
  }

  String _monoLabel(String dir) {
    final name = p.basename(dir);
    final parentName = p.basename(p.dirname(dir));
    return '$parentName/$name';
  }

  String _buildArtifact(String title, _PhaseResult phase) {
    final status = phase.passed ? 'PASSED' : 'FAILED';
    return '# $title — Pre-flight Results\n'
        '\n'
        '## Status: $status\n'
        '\n'
        '## Results\n'
        '${phase.toMarkdown()}\n'
        '\n'
        '> Generated by Somnio CLI pre-flight (not AI).\n';
  }
}
