import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import 'skill_bundle.dart';

/// Parsed rule data from a YAML cursor rule file.
class ParsedRule {
  const ParsedRule({
    required this.name,
    required this.description,
    required this.match,
    required this.prompt,
    required this.fileName,
  });

  final String name;
  final String description;
  final String match;
  final String prompt;

  /// Original file name without extension (e.g., 'flutter_tool_installer').
  final String fileName;
}

/// Loads and parses content from the flutter-plans/ directory.
class ContentLoader {
  const ContentLoader(this.repoRoot);

  /// Absolute path to the technology-tools repo root.
  final String repoRoot;

  /// Reads the plan.md file for a skill bundle.
  ///
  /// Strips the HTML comment UUID line (first line) if present.
  String loadPlan(SkillBundle bundle) {
    final planPath = p.join(repoRoot, bundle.planRelativePath);
    final file = File(planPath);
    if (!file.existsSync()) {
      throw FileSystemException(
        'Plan file not found',
        planPath,
      );
    }
    var content = file.readAsStringSync();

    // Strip HTML comment UUID line if present (first line)
    if (content.startsWith('<!--')) {
      final newlineIndex = content.indexOf('\n');
      if (newlineIndex != -1) {
        content = content.substring(newlineIndex + 1);
      }
    }

    return content.trimLeft();
  }

  /// Parses all YAML rule files from the cursor_rules directory of a bundle.
  ///
  /// Returns parsed rules. Skips the `templates/` subdirectory.
  List<ParsedRule> loadRules(SkillBundle bundle) {
    final rulesDir = Directory(p.join(repoRoot, bundle.rulesDirectory));
    if (!rulesDir.existsSync()) {
      throw FileSystemException(
        'Rules directory not found',
        rulesDir.path,
      );
    }

    final rules = <ParsedRule>[];
    final yamlFiles = rulesDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.yaml'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

    for (final file in yamlFiles) {
      final parsed = _parseYamlRule(file);
      if (parsed != null) rules.add(parsed);
    }

    return rules;
  }

  /// Loads the template file for a skill bundle, if it exists.
  String? loadTemplate(SkillBundle bundle) {
    if (bundle.templatePath == null) return null;
    final file = File(p.join(repoRoot, bundle.templatePath!));
    if (!file.existsSync()) return null;
    return file.readAsStringSync();
  }

  /// Loads the Antigravity workflow file for a skill bundle, if it exists.
  String? loadWorkflow(SkillBundle bundle) {
    if (bundle.workflowPath == null) return null;
    final file = File(p.join(repoRoot, bundle.workflowPath!));
    if (!file.existsSync()) return null;
    return file.readAsStringSync();
  }

  /// Lists all files in the rules directory including templates subdirectory.
  ///
  /// Returns paths relative to the rules directory.
  List<String> listAllRuleFiles(SkillBundle bundle) {
    final rulesDir = Directory(p.join(repoRoot, bundle.rulesDirectory));
    if (!rulesDir.existsSync()) return [];

    final files = <String>[];
    for (final entity in rulesDir.listSync(recursive: true)) {
      if (entity is File) {
        files.add(p.relative(entity.path, from: rulesDir.path));
      }
    }
    files.sort();
    return files;
  }

  /// Returns the absolute path of a file within the rules directory.
  String rulesFilePath(SkillBundle bundle, String relativePath) {
    return p.join(repoRoot, bundle.rulesDirectory, relativePath);
  }

  ParsedRule? _parseYamlRule(File file) {
    try {
      final content = file.readAsStringSync();
      final doc = loadYaml(content) as YamlMap;
      final rules = doc['rules'] as YamlList;
      if (rules.isEmpty) return null;

      final rule = rules.first as YamlMap;
      final name = rule['name'] as String;
      final description = (rule['description'] as String).trim();
      final match = rule['match'] as String;
      final prompt = (rule['prompt'] as String).trimRight();

      final fileName = p.basenameWithoutExtension(file.path);

      return ParsedRule(
        name: name,
        description: description,
        match: match,
        prompt: prompt,
        fileName: fileName,
      );
    } catch (e) {
      // Skip files that can't be parsed
      return null;
    }
  }
}
