/// A workflow skill bundle — a standalone SKILL.md for IDE installation.
///
/// Unlike [SkillBundle] (audit bundles with YAML rules), workflow skills
/// are self-contained markdown files installed directly as skills.
/// They are only supported by Claude Code (skillDir format).
class WorkflowSkill {
  const WorkflowSkill({
    required this.id,
    required this.name,
    required this.displayName,
    required this.description,
    required this.planRelativePath,
  });

  /// Internal identifier.
  final String id;

  /// Skill name used as slash command (e.g., 'workflow-plan').
  final String name;

  /// Human-readable name.
  final String displayName;

  /// Description for SKILL.md frontmatter.
  final String description;

  /// Path to the skill markdown file, relative to repo root.
  final String planRelativePath;
}
