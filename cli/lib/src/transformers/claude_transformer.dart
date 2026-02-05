import '../content/content_loader.dart';
import '../content/skill_bundle.dart';
import '../content/skill_registry.dart';

/// Result of transforming content for Claude Code.
class ClaudeSkillOutput {
  const ClaudeSkillOutput({
    required this.skillMd,
    required this.ruleFiles,
    this.templateContent,
    this.templateFileName,
  });

  /// The SKILL.md content with frontmatter and transformed plan.
  final String skillMd;

  /// Map of file name (e.g., 'flutter_tool_installer.md') to content.
  final Map<String, String> ruleFiles;

  /// Template file content, if available.
  final String? templateContent;

  /// Template file name (e.g., 'flutter_report_template.txt').
  final String? templateFileName;
}

/// Transforms plan.md + YAML rules into Claude Code skill format.
///
/// Claude Code skills are stored as directories containing:
/// - SKILL.md (orchestration plan with frontmatter)
/// - rules/ (individual rule files as markdown)
/// - templates/ (report templates, copied as-is)
class ClaudeTransformer {
  /// Transforms a skill bundle into Claude Code format.
  ClaudeSkillOutput transform(SkillBundle bundle, ContentLoader loader) {
    final plan = loader.loadPlan(bundle);
    final rules = loader.loadRules(bundle);
    final template = loader.loadTemplate(bundle);

    // Generate SKILL.md
    final skillMd = _generateSkillMd(bundle, plan);

    // Generate rule markdown files
    final ruleFiles = <String, String>{};
    for (final rule in rules) {
      ruleFiles['${rule.fileName}.md'] = _ruleToMarkdown(rule);
    }

    // Determine template file name
    String? templateFileName;
    if (bundle.templatePath != null) {
      templateFileName = bundle.templatePath!.split('/').last;
    }

    return ClaudeSkillOutput(
      skillMd: skillMd,
      ruleFiles: ruleFiles,
      templateContent: template,
      templateFileName: templateFileName,
    );
  }

  String _generateSkillMd(SkillBundle bundle, String planContent) {
    final frontmatter = '---\n'
        'name: ${bundle.name}\n'
        'description: >-\n'
        '  ${bundle.description}\n'
        'allowed-tools: Read, Edit, Write, Grep, Glob, Bash, WebFetch\n'
        'user-invocable: true\n'
        '---\n\n';

    var content = planContent;

    // Transform @rule_name references to file references
    // Matches: `@rule_name` (with backticks)
    content = content.replaceAllMapped(
      RegExp(r'`@(\w+)`'),
      (match) {
        final ruleName = match.group(1)!;
        return 'Read and follow the instructions in '
            '`rules/$ruleName.md`';
      },
    );

    // Transform cross-skill plan references
    // Pattern: @flutter_best_practices_check/plan/best_practices.plan.md
    content = content.replaceAllMapped(
      RegExp(r'@flutter_best_practices_check/plan/best_practices\.plan\.md'),
      (match) {
        final targetSkill = SkillRegistry.findById('flutter_plan');
        if (targetSkill != null) {
          return '`/${targetSkill.name}`';
        }
        return match.group(0)!;
      },
    );

    // Transform remaining @rule.yaml references in execution summaries
    // Pattern: `@rule_name.yaml`
    content = content.replaceAllMapped(
      RegExp(r'`@(\w+)\.yaml`'),
      (match) {
        final ruleName = match.group(1)!;
        return 'Read and follow the instructions in '
            '`rules/$ruleName.md`';
      },
    );

    // Transform bare @best_practices.plan.md references
    content = content.replaceAllMapped(
      RegExp(r'`@best_practices\.plan\.md`'),
      (match) {
        final targetSkill = SkillRegistry.findById('flutter_plan');
        return '`/${targetSkill?.name ?? 'somnio-fp'}`';
      },
    );

    // Transform workflow references for Antigravity cross-refs
    content = content.replaceAllMapped(
      RegExp(
        r'`flutter_best_practices_check/\.agent/workflows/flutter_best_practices\.md`',
      ),
      (match) {
        final targetSkill = SkillRegistry.findById('flutter_plan');
        return '`/${targetSkill?.name ?? 'somnio-fp'}`';
      },
    );

    // Transform plan step rule references
    // Pattern: `flutter_best_practices_check/cursor_rules/rule_name.yaml`
    content = content.replaceAllMapped(
      RegExp(
        r'`flutter_best_practices_check/cursor_rules/(\w+)\.yaml`',
      ),
      (match) {
        final ruleName = match.group(1)!;
        final targetSkill = SkillRegistry.findById('flutter_plan');
        return '`rules/$ruleName.md` (from `/${targetSkill?.name ?? 'somnio-fp'}`)';
      },
    );

    return frontmatter + content;
  }

  String _ruleToMarkdown(ParsedRule rule) {
    final buffer = StringBuffer();
    buffer.writeln('# ${rule.name}');
    buffer.writeln();
    buffer.writeln('> ${rule.description}');
    buffer.writeln();
    buffer.writeln('**File pattern**: `${rule.match}`');
    buffer.writeln();
    buffer.writeln('---');
    buffer.writeln();
    buffer.write(rule.prompt);
    if (!rule.prompt.endsWith('\n')) {
      buffer.writeln();
    }
    return buffer.toString();
  }
}
