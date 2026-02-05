import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

/// Result of detecting a single skill bundle in a technology directory.
class BundleDetectionResult {
  const BundleDetectionResult({
    required this.bundleType,
    required this.subdirectory,
    this.planFile,
    this.rulesDirectory,
    this.ruleCount = 0,
    this.validRuleCount = 0,
    this.templatePath,
    this.workflowPath,
    this.errors = const [],
  });

  /// Bundle type: 'health_audit' or 'best_practices'.
  final String bundleType;

  /// Name of the subdirectory (e.g., 'react_project_health_audit').
  final String subdirectory;

  /// Path to the plan file, relative to repo root, or null if not found.
  final String? planFile;

  /// Path to the rules directory, relative to repo root, or null.
  final String? rulesDirectory;

  /// Total number of .yaml files found in cursor_rules/.
  final int ruleCount;

  /// Number of YAML files that parse successfully.
  final int validRuleCount;

  /// Path to the template file, relative to repo root, or null.
  final String? templatePath;

  /// Path to the workflow file, relative to repo root, or null.
  final String? workflowPath;

  /// Validation errors found during detection.
  final List<String> errors;

  /// Whether this bundle has enough content to be registered.
  bool get isRegistrable => planFile != null && validRuleCount > 0;
}

/// Scans an existing {tech}-plans/ directory for skill bundles and
/// validates their content.
class BundleDetector {
  BundleDetector({required this.repoRoot, required Logger logger})
      : _logger = logger;

  final String repoRoot;
  final Logger _logger;

  /// Scans {tech}-plans/ for recognizable skill bundle subdirectories.
  Future<List<BundleDetectionResult>> detectBundles(String tech) async {
    final techPlansDir = Directory(p.join(repoRoot, '$tech-plans'));
    if (!techPlansDir.existsSync()) return [];

    final results = <BundleDetectionResult>[];

    final subdirs = techPlansDir
        .listSync()
        .whereType<Directory>()
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

    for (final subdir in subdirs) {
      final dirName = p.basename(subdir.path);
      final bundleType = _classifyBundleType(dirName);
      if (bundleType == null) continue;

      results.add(await _detectBundle(tech, dirName, bundleType));
    }

    return results;
  }

  /// Classifies a subdirectory name into a bundle type.
  String? _classifyBundleType(String dirName) {
    if (dirName.contains('project_health_audit') ||
        dirName.contains('health_audit')) {
      return 'health_audit';
    }
    if (dirName.contains('best_practices_check') ||
        dirName.contains('best_practices')) {
      return 'best_practices';
    }
    return null;
  }

  /// Detects a single bundle from a subdirectory.
  Future<BundleDetectionResult> _detectBundle(
    String tech,
    String subdirectory,
    String bundleType,
  ) async {
    final baseDir = p.join(repoRoot, '$tech-plans', subdirectory);
    final errors = <String>[];

    // Detect plan file
    final planFile = _findPlanFile(baseDir, bundleType);
    if (planFile == null) {
      errors.add('No .plan.md file found in plan/ directory');
    }

    // Detect cursor_rules directory
    final rulesDir = p.join(baseDir, 'cursor_rules');
    String? rulesRelPath;
    var ruleCount = 0;
    var validRuleCount = 0;

    if (Directory(rulesDir).existsSync()) {
      rulesRelPath = p.relative(rulesDir, from: repoRoot);
      final ruleValidation = await _validateRules(rulesDir);
      ruleCount = ruleValidation.total;
      validRuleCount = ruleValidation.valid;

      if (ruleCount == 0) {
        errors.add('No .yaml rule files found in cursor_rules/');
      } else if (validRuleCount < ruleCount) {
        final invalid = ruleCount - validRuleCount;
        errors.add('$invalid/$ruleCount YAML files failed validation');
      }
    } else {
      errors.add('cursor_rules/ directory not found');
    }

    // Detect template
    final templatePath = _findTemplate(baseDir, tech, bundleType);

    // Detect workflow
    final workflowPath = _findWorkflow(baseDir);

    return BundleDetectionResult(
      bundleType: bundleType,
      subdirectory: subdirectory,
      planFile: planFile != null
          ? p.relative(planFile, from: repoRoot)
          : null,
      rulesDirectory: rulesRelPath,
      ruleCount: ruleCount,
      validRuleCount: validRuleCount,
      templatePath: templatePath != null
          ? p.relative(templatePath, from: repoRoot)
          : null,
      workflowPath: workflowPath != null
          ? p.relative(workflowPath, from: repoRoot)
          : null,
      errors: errors,
    );
  }

  /// Finds a .plan.md file in the plan/ subdirectory.
  String? _findPlanFile(String baseDir, String bundleType) {
    final planDir = Directory(p.join(baseDir, 'plan'));
    if (!planDir.existsSync()) return null;

    final planFiles = planDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.plan.md'))
        .toList();

    if (planFiles.isEmpty) return null;
    return planFiles.first.path;
  }

  /// Validates YAML rule files and returns counts.
  Future<_RuleValidation> _validateRules(String rulesDir) async {
    final dir = Directory(rulesDir);
    final yamlFiles = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.yaml'))
        .toList();

    var valid = 0;
    for (final file in yamlFiles) {
      if (await _isValidRule(file)) {
        valid++;
      } else {
        _logger.detail(
          '  Invalid YAML: ${p.basename(file.path)}',
        );
      }
    }

    return _RuleValidation(total: yamlFiles.length, valid: valid);
  }

  /// Checks if a YAML file has the expected rule structure.
  Future<bool> _isValidRule(File file) async {
    try {
      final content = file.readAsStringSync();
      final doc = loadYaml(content);
      if (doc is! YamlMap) return false;
      if (!doc.containsKey('rules')) return false;

      final rules = doc['rules'];
      if (rules is! YamlList || rules.isEmpty) return false;

      final rule = rules.first;
      if (rule is! YamlMap) return false;

      // Check required fields
      for (final field in ['name', 'description', 'match', 'prompt']) {
        if (!rule.containsKey(field)) return false;
        final value = rule[field];
        if (value is! String || value.isEmpty) return false;
      }

      return true;
    } catch (_) {
      return false;
    }
  }

  /// Finds a report template file.
  String? _findTemplate(
    String baseDir,
    String tech,
    String bundleType,
  ) {
    final templatesDir = p.join(baseDir, 'cursor_rules', 'templates');
    if (!Directory(templatesDir).existsSync()) return null;

    final templates = Directory(templatesDir)
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.txt'))
        .toList();

    if (templates.isEmpty) return null;
    return templates.first.path;
  }

  /// Finds an Antigravity workflow file.
  String? _findWorkflow(String baseDir) {
    final workflowDir = p.join(baseDir, '.agent', 'workflows');
    if (!Directory(workflowDir).existsSync()) return null;

    final workflows = Directory(workflowDir)
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.md'))
        .toList();

    if (workflows.isEmpty) return null;
    return workflows.first.path;
  }

  /// Prints a detection report for the given results.
  void printReport(List<BundleDetectionResult> results) {
    for (final result in results) {
      final typeLabel = result.bundleType == 'health_audit'
          ? 'Health Audit'
          : 'Best Practices';
      _logger.info('');
      _logger.info('  $typeLabel (${result.subdirectory}):');

      // Plan file
      if (result.planFile != null) {
        _logger.info(
          '    ${lightGreen.wrap('[x]')} Plan file: '
          '${p.basename(result.planFile!)}',
        );
      } else {
        _logger.info(
          '    ${lightRed.wrap('[ ]')} Plan file: not found',
        );
      }

      // Rules
      if (result.rulesDirectory != null && result.ruleCount > 0) {
        final validLabel = result.validRuleCount == result.ruleCount
            ? '${result.ruleCount} rules'
            : '${result.validRuleCount}/${result.ruleCount} valid';
        _logger.info(
          '    ${lightGreen.wrap('[x]')} Rules: '
          'cursor_rules/ ($validLabel)',
        );
      } else {
        _logger.info(
          '    ${lightRed.wrap('[ ]')} Rules: no YAML rules found',
        );
      }

      // Template
      if (result.templatePath != null) {
        _logger.info(
          '    ${lightGreen.wrap('[x]')} Template: '
          '${p.basename(result.templatePath!)}',
        );
      } else {
        _logger.info(
          '    ${lightYellow.wrap('[-]')} Template: not found '
          '(optional)',
        );
      }

      // Workflow
      if (result.workflowPath != null) {
        _logger.info(
          '    ${lightGreen.wrap('[x]')} Workflow: '
          '${p.basename(result.workflowPath!)}',
        );
      } else {
        _logger.info(
          '    ${lightYellow.wrap('[-]')} Workflow: not found '
          '(Antigravity will be skipped)',
        );
      }

      // Status
      if (result.isRegistrable) {
        _logger.info(
          '    Status: ${lightGreen.wrap('Ready to register')}',
        );
      } else {
        _logger.info(
          '    Status: ${lightRed.wrap('Cannot register')} '
          '- missing required components',
        );
        for (final error in result.errors) {
          _logger.info('      - $error');
        }
      }
    }
  }
}

class _RuleValidation {
  const _RuleValidation({required this.total, required this.valid});
  final int total;
  final int valid;
}
