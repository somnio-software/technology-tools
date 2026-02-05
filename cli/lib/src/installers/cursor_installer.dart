import 'dart:io';

import 'package:path/path.dart' as p;

import '../content/skill_bundle.dart';
import '../transformers/cursor_transformer.dart';
import '../utils/platform_utils.dart';
import 'installer.dart';

/// Installs commands into Cursor's global commands directory.
///
/// Cursor commands are plain `.md` files triggered via `/command-name`
/// in chat. Each skill becomes a single command file.
///
/// Location: `~/.cursor/commands/`
class CursorInstaller extends Installer {
  CursorInstaller({required super.logger, required super.loader});

  final _transformer = CursorTransformer();

  @override
  Future<InstallResult> install({
    required List<SkillBundle> bundles,
    bool force = false,
  }) async {
    final targetDir = PlatformUtils.cursorGlobalCommandsDir;

    var commandCount = 0;

    // Check for existing files
    if (!force && Directory(targetDir).existsSync()) {
      final existing = Directory(targetDir)
          .listSync()
          .whereType<File>()
          .where((f) =>
              f.path.endsWith('.md') &&
              p.basename(f.path).startsWith('somnio-'))
          .toList();

      if (existing.isNotEmpty) {
        final overwrite = logger.confirm(
          'Found ${existing.length} existing Somnio commands. Overwrite?',
        );
        if (!overwrite) {
          logger.info('Skipped Cursor installation.');
          return InstallResult(
            skillCount: 0,
            ruleCount: 0,
            targetDirectory: targetDir,
          );
        }
      }
    }

    for (final bundle in bundles) {
      final progress = logger.progress(
        'Installing /${bundle.name} command',
      );

      try {
        final output = _transformer.transform(bundle, loader);

        for (final entry in output.commandFiles.entries) {
          _writeFile(p.join(targetDir, entry.key), entry.value);
          commandCount++;
        }

        progress.complete(
          'Installed /${bundle.name} command',
        );
      } catch (e) {
        progress.fail('Failed to install ${bundle.name}: $e');
      }
    }

    return InstallResult(
      skillCount: commandCount,
      ruleCount: 0,
      targetDirectory: targetDir,
    );
  }

  @override
  bool isInstalled() {
    final dir = Directory(PlatformUtils.cursorGlobalCommandsDir);
    if (!dir.existsSync()) return false;

    return dir
        .listSync()
        .whereType<File>()
        .any((f) =>
            f.path.endsWith('.md') &&
            p.basename(f.path).startsWith('somnio-'));
  }

  @override
  int installedCount() {
    final dir = Directory(PlatformUtils.cursorGlobalCommandsDir);
    if (!dir.existsSync()) return 0;

    return dir
        .listSync()
        .whereType<File>()
        .where((f) =>
            f.path.endsWith('.md') &&
            p.basename(f.path).startsWith('somnio-'))
        .length;
  }

  void _writeFile(String path, String content) {
    final file = File(path);
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(content);
  }
}
