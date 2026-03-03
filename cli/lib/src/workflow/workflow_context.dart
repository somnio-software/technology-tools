import 'dart:io';

import 'package:yaml/yaml.dart';

/// A step entry from the context.md frontmatter.
class WorkflowStepEntry {
  const WorkflowStepEntry({
    required this.file,
    required this.tag,
    this.mandatory = false,
    this.needsPrevious = false,
  });

  /// Step filename (e.g., '01-analyze-dependencies.md').
  final String file;

  /// Step tag: 'research', 'planning', or 'execution'.
  final String tag;

  /// Whether this step must succeed for the workflow to continue.
  final bool mandatory;

  /// Whether this step needs the previous step's output injected.
  final bool needsPrevious;

  factory WorkflowStepEntry.fromYaml(dynamic yaml) {
    final map = yaml as YamlMap;
    return WorkflowStepEntry(
      file: map['file'] as String,
      tag: map['tag'] as String? ?? 'execution',
      mandatory: map['mandatory'] as bool? ?? false,
      needsPrevious: map['needs_previous'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toYaml() => {
        'file': file,
        'tag': tag,
        'mandatory': mandatory,
        'needs_previous': needsPrevious,
      };
}

/// Parsed context.md manifest for a workflow.
///
/// Contains metadata (name, description, version) and the ordered step list.
class WorkflowContext {
  const WorkflowContext({
    required this.name,
    required this.description,
    required this.steps,
    this.created,
    this.version = 1,
  });

  /// Workflow name (kebab-case).
  final String name;

  /// Human-readable description.
  final String description;

  /// When the workflow was created.
  final DateTime? created;

  /// Schema version.
  final int version;

  /// Ordered list of step entries.
  final List<WorkflowStepEntry> steps;

  // ── Parsing ────────────────────────────────────────────────────────

  /// Parses a context.md file with YAML frontmatter.
  ///
  /// Expects the file to start with `---`, contain YAML, then `---`.
  factory WorkflowContext.parse(String content) {
    final frontmatter = _extractFrontmatter(content);
    if (frontmatter == null) {
      throw const FormatException(
        'context.md must start with YAML frontmatter (---)',
      );
    }

    final yaml = loadYaml(frontmatter) as YamlMap;

    final name = yaml['name'] as String? ?? '';
    final description = yaml['description'] as String? ?? '';
    final version = yaml['version'] as int? ?? 1;

    DateTime? created;
    if (yaml['created'] != null) {
      created = DateTime.tryParse(yaml['created'].toString());
    }

    final stepsYaml = yaml['steps'] as YamlList? ?? YamlList();
    final steps = stepsYaml.map(WorkflowStepEntry.fromYaml).toList();

    return WorkflowContext(
      name: name,
      description: description,
      created: created,
      version: version,
      steps: steps,
    );
  }

  /// Loads and parses a context.md file from disk.
  static WorkflowContext? loadFrom(String path) {
    final file = File(path);
    if (!file.existsSync()) return null;
    return WorkflowContext.parse(file.readAsStringSync());
  }

  // ── Private ────────────────────────────────────────────────────────

  /// Extracts YAML frontmatter between `---` delimiters.
  static String? _extractFrontmatter(String content) {
    final trimmed = content.trimLeft();
    if (!trimmed.startsWith('---')) return null;

    final endIndex = trimmed.indexOf('---', 3);
    if (endIndex == -1) return null;

    return trimmed.substring(3, endIndex).trim();
  }
}
