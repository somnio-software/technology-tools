import 'dart:io';

import 'package:path/path.dart' as p;

import '../utils/platform_utils.dart';

/// Where a workflow was found.
enum WorkflowScope { project, global }

/// A resolved workflow location.
class WorkflowLocation {
  const WorkflowLocation({
    required this.path,
    required this.scope,
    required this.name,
  });

  /// Full path to the workflow directory.
  final String path;

  /// Whether this is a project-level or global workflow.
  final WorkflowScope scope;

  /// Workflow name.
  final String name;

  String get contextPath => p.join(path, 'context.md');
  String get progressPath => p.join(path, 'progress.json');
  String get outputsDir => p.join(path, 'outputs');

  /// Returns the config file path for a given agent.
  String configPath(String agentId) {
    final fileName = _configFileName(agentId);
    return p.join(path, fileName);
  }

  /// Returns the path to a step file.
  String stepPath(String fileName) => p.join(path, fileName);

  /// Returns the output path for a step file.
  String outputPath(String stepFileName) {
    final base = p.basenameWithoutExtension(stepFileName);
    return p.join(outputsDir, '$base-output.md');
  }

  static String _configFileName(String agentId) {
    const mapping = {
      'claude': 'config.claudecode.json',
      'cursor': 'config.cursor.json',
      'gemini': 'config.gemini.json',
      'antigravity': 'config.gemini.json',
      'codex': 'config.codex.json',
    };
    return mapping[agentId] ?? 'config.$agentId.json';
  }
}

/// Resolves workflow paths across project and global scopes.
class WorkflowLocator {
  /// Finds a workflow by name.
  ///
  /// Checks project-level `.somnio/workflows/<name>/` first,
  /// then falls back to global `~/.somnio/workflows/<name>/`.
  WorkflowLocation? find(String name) {
    // Project-level
    final projectPath = projectWorkflowPath(name);
    if (Directory(projectPath).existsSync() &&
        File(p.join(projectPath, 'context.md')).existsSync()) {
      return WorkflowLocation(
        path: projectPath,
        scope: WorkflowScope.project,
        name: name,
      );
    }

    // Global
    final globalPath = globalWorkflowPath(name);
    if (Directory(globalPath).existsSync() &&
        File(p.join(globalPath, 'context.md')).existsSync()) {
      return WorkflowLocation(
        path: globalPath,
        scope: WorkflowScope.global,
        name: name,
      );
    }

    return null;
  }

  /// Returns the project-level workflow directory path.
  String projectWorkflowPath(String name) {
    return p.join(Directory.current.path, '.somnio', 'workflows', name);
  }

  /// Returns the global workflow directory path.
  String globalWorkflowPath(String name) {
    return p.join(PlatformUtils.homeDirectory, '.somnio', 'workflows', name);
  }

  /// Creates the workflow directory at the specified scope.
  String createWorkflowDir(String name, {required WorkflowScope scope}) {
    final path = scope == WorkflowScope.project
        ? projectWorkflowPath(name)
        : globalWorkflowPath(name);
    Directory(path).createSync(recursive: true);
    return path;
  }

  /// Lists all workflows across both scopes.
  ///
  /// Returns a list of [WorkflowLocation] objects, with project-level
  /// workflows listed first. If a workflow exists in both scopes,
  /// only the project-level one is returned.
  List<WorkflowLocation> listAll() {
    final results = <WorkflowLocation>[];
    final seen = <String>{};

    // Project-level workflows
    final projectDir = p.join(
      Directory.current.path,
      '.somnio',
      'workflows',
    );
    _scanDir(projectDir, WorkflowScope.project, results, seen);

    // Global workflows
    final globalDir = p.join(
      PlatformUtils.homeDirectory,
      '.somnio',
      'workflows',
    );
    _scanDir(globalDir, WorkflowScope.global, results, seen);

    return results;
  }

  void _scanDir(
    String dirPath,
    WorkflowScope scope,
    List<WorkflowLocation> results,
    Set<String> seen,
  ) {
    final dir = Directory(dirPath);
    if (!dir.existsSync()) return;

    for (final entity in dir.listSync()) {
      if (entity is! Directory) continue;
      final name = p.basename(entity.path);
      if (seen.contains(name)) continue;

      final contextFile = File(p.join(entity.path, 'context.md'));
      if (contextFile.existsSync()) {
        seen.add(name);
        results.add(WorkflowLocation(
          path: entity.path,
          scope: scope,
          name: name,
        ));
      }
    }
  }

  /// Validates that a workflow name is valid (kebab-case).
  static bool isValidName(String name) {
    return RegExp(r'^[a-z][a-z0-9]*(-[a-z0-9]+)*$').hasMatch(name);
  }
}
