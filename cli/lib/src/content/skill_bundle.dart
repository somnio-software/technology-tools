/// Data model for a skill bundle - a collection of related rules and
/// plans that can be installed as a single skill/command into an agent.
class SkillBundle {
  const SkillBundle({
    required this.id,
    required this.name,
    required this.displayName,
    required this.description,
    required this.planRelativePath,
    required this.rulesDirectory,
    this.workflowPath,
    this.templatePath,
  });

  /// Internal identifier (e.g., 'flutter_health').
  final String id;

  /// Skill name used as slash command (e.g., 'somnio-fh').
  final String name;

  /// Human-readable name (e.g., 'Flutter Project Health Audit').
  final String displayName;

  /// Description for SKILL.md frontmatter.
  final String description;

  /// Path to the plan.md file, relative to repo root.
  final String planRelativePath;

  /// Path to the cursor_rules/ directory, relative to repo root.
  final String rulesDirectory;

  /// Path to the Antigravity workflow file, relative to repo root.
  final String? workflowPath;

  /// Path to the report template file, relative to repo root.
  final String? templatePath;

  /// Technology prefix derived from the bundle [id].
  ///
  /// `flutter_health` → `flutter`, `nestjs_plan` → `nestjs`.
  String get techPrefix => id.replaceAll(RegExp(r'_(?:health|plan)$'), '');

  /// Human-readable technology name derived from [displayName].
  ///
  /// `Flutter Project Health Audit` → `Flutter`.
  String get techDisplayName => displayName.split(' ').first;

  /// Plan subdirectory name derived from [planRelativePath].
  ///
  /// `flutter-plans/flutter_project_health_audit/plan/...`
  /// → `flutter_project_health_audit`.
  String get planSubDir {
    final parts = planRelativePath.split('/');
    return parts.length >= 2 ? parts[1] : id;
  }
}
