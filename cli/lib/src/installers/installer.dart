import 'package:mason_logger/mason_logger.dart';

import '../content/content_loader.dart';
import '../content/skill_bundle.dart';

/// Result of an installation operation.
class InstallResult {
  const InstallResult({
    required this.skillCount,
    required this.ruleCount,
    required this.targetDirectory,
    this.skippedCount = 0,
  });

  final int skillCount;
  final int ruleCount;
  final String targetDirectory;

  /// Number of bundles skipped (e.g., missing workflow files).
  final int skippedCount;
}

/// Abstract base class for agent-specific installers.
abstract class Installer {
  const Installer({required this.logger, required this.loader});

  final Logger logger;
  final ContentLoader loader;

  /// Installs all skill bundles to the target agent.
  ///
  /// [bundles] - The skill bundles to install.
  /// [projectPath] - If provided, install to project-level directory.
  /// [force] - If true, overwrite existing files without prompting.
  Future<InstallResult> install({
    required List<SkillBundle> bundles,
    String? projectPath,
    bool force = false,
  });

  /// Checks if skills are already installed at the target location.
  bool isInstalled({String? projectPath});

  /// Returns the count of installed items.
  int installedCount({String? projectPath});
}
