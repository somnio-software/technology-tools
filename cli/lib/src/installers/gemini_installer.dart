import 'dart:io';

import 'package:path/path.dart' as p;

import '../content/skill_bundle.dart';
import '../transformers/gemini_transformer.dart';
import '../utils/platform_utils.dart';
import 'installer.dart';

/// Installs skills into Gemini CLI's global skill directory.
///
/// Location: `~/.gemini/skills/<skill-name>/`
class GeminiInstaller extends Installer {
  GeminiInstaller({required super.logger, required super.loader});

  final _transformer = GeminiTransformer();

  @override
  Future<InstallResult> install({
    required List<SkillBundle> bundles,
    bool force = false,
  }) async {
    final baseDir = PlatformUtils.geminiGlobalSkillsDir;

    var skillCount = 0;
    var ruleCount = 0;

    // Check for existing skills upfront — ask once for all
    if (!force && Directory(baseDir).existsSync()) {
      final existing = Directory(baseDir)
          .listSync()
          .whereType<Directory>()
          .where((d) => p.basename(d.path).startsWith('somnio-'))
          .toList();

      if (existing.isNotEmpty) {
        final overwrite = logger.confirm(
          'Found ${existing.length} existing Somnio skills '
          'in Gemini CLI. Overwrite?',
        );
        if (!overwrite) {
          logger.info('Skipped Gemini CLI installation.');
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
        'Installing ${bundle.name} (Gemini CLI)',
      );

      try {
        final output = _transformer.transform(bundle, loader);

        // Create skill directory
        final skillDir = p.join(baseDir, bundle.name);

        // Write SKILL.md
        _writeFile(p.join(skillDir, 'SKILL.md'), output.skillMd);

        // Write rule files
        final rulesDir = p.join(skillDir, 'rules');
        for (final entry in output.ruleFiles.entries) {
          _writeFile(p.join(rulesDir, entry.key), entry.value);
          ruleCount++;
        }

        // Write template if available
        if (output.templateContent != null &&
            output.templateFileName != null) {
          _writeFile(
            p.join(skillDir, 'templates', output.templateFileName!),
            output.templateContent!,
          );
        }

        skillCount++;
        progress.complete('Installed /${bundle.name} (Gemini CLI)');
      } catch (e) {
        progress.fail('Failed to install ${bundle.name}: $e');
      }
    }

    return InstallResult(
      skillCount: skillCount,
      ruleCount: ruleCount,
      targetDirectory: baseDir,
    );
  }

  @override
  bool isInstalled() {
    final dir = Directory(PlatformUtils.geminiGlobalSkillsDir);
    if (!dir.existsSync()) return false;

    return dir
        .listSync()
        .whereType<Directory>()
        .any((d) => p.basename(d.path).startsWith('somnio-'));
  }

  @override
  int installedCount() {
    final dir = Directory(PlatformUtils.geminiGlobalSkillsDir);
    if (!dir.existsSync()) return 0;

    return dir
        .listSync()
        .whereType<Directory>()
        .where((d) => p.basename(d.path).startsWith('somnio-'))
        .length;
  }

  void _writeFile(String path, String content) {
    final file = File(path);
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(content);
  }
}
