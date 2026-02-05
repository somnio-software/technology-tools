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
}
