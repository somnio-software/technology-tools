import 'dart:io';

import 'package:path/path.dart' as p;

import '../content/skill_bundle.dart';
import '../transformers/antigravity_transformer.dart';
import '../utils/platform_utils.dart';
import 'installer.dart';

/// Installs workflows and rules into Antigravity's .agent/ directory.
///
/// Antigravity uses `.agent/workflows/` for workflow files and
/// `.agent/somnio_rules/` for supporting rule files.
class AntigravityInstaller extends Installer {
  AntigravityInstaller({required super.logger, required super.loader});

  final _transformer = AntigravityTransformer();

  @override
  Future<InstallResult> install({
    required List<SkillBundle> bundles,
    String? projectPath,
    bool force = false,
  }) async {
    final baseDir = PlatformUtils.antigravityProjectDir(
      projectPath ?? Directory.current.path,
    );
    final workflowsDir = p.join(baseDir, 'workflows');
    final rulesDir = p.join(baseDir, 'somnio_rules');

    var skillCount = 0;
    var ruleCount = 0;

    // Check for existing workflows
    if (!force && Directory(workflowsDir).existsSync()) {
      final existing = Directory(workflowsDir)
          .listSync()
          .whereType<File>()
          .where((f) => p.basename(f.path).startsWith('somnio_'))
          .toList();

      if (existing.isNotEmpty) {
        final overwrite = logger.confirm(
          'Found ${existing.length} existing Somnio workflows. Overwrite?',
        );
        if (!overwrite) {
          logger.info('Skipped Antigravity installation.');
          return InstallResult(
            skillCount: 0,
            ruleCount: 0,
            targetDirectory: baseDir,
          );
        }
      }
    }

    for (final bundle in bundles) {
      final progress = logger.progress(
        'Installing ${bundle.displayName} workflow',
      );

      try {
        final output = _transformer.transform(bundle, loader);

        // Write workflow file
        _writeFile(
          p.join(workflowsDir, output.workflowFileName),
          output.workflowContent,
        );
        skillCount++;

        // Write rule files
        for (final entry in output.ruleFiles.entries) {
          _writeFile(p.join(rulesDir, entry.key), entry.value);
          ruleCount++;
        }

        // Write plan file
        if (output.planContent != null &&
            output.planRelativePath != null) {
          _writeFile(
            p.join(rulesDir, output.planRelativePath!),
            output.planContent!,
          );
          ruleCount++;
        }

        progress.complete(
          'Installed ${bundle.displayName} workflow + '
          '${output.ruleFiles.length} rule files',
        );
      } catch (e) {
        progress.fail('Failed to install ${bundle.displayName}: $e');
      }
    }

    return InstallResult(
      skillCount: skillCount,
      ruleCount: ruleCount,
      targetDirectory: baseDir,
    );
  }

  @override
  bool isInstalled({String? projectPath}) {
    final baseDir = PlatformUtils.antigravityProjectDir(
      projectPath ?? Directory.current.path,
    );
    final workflowsDir = Directory(p.join(baseDir, 'workflows'));
    if (!workflowsDir.existsSync()) return false;

    return workflowsDir
        .listSync()
        .whereType<File>()
        .any((f) => p.basename(f.path).startsWith('somnio_'));
  }

  @override
  int installedCount({String? projectPath}) {
    final baseDir = PlatformUtils.antigravityProjectDir(
      projectPath ?? Directory.current.path,
    );
    final workflowsDir = Directory(p.join(baseDir, 'workflows'));
    if (!workflowsDir.existsSync()) return 0;

    return workflowsDir
        .listSync()
        .whereType<File>()
        .where((f) => p.basename(f.path).startsWith('somnio_'))
        .length;
  }

  void _writeFile(String path, String content) {
    final file = File(path);
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(content);
  }
}
