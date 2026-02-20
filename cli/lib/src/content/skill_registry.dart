import 'skill_bundle.dart';

/// Static registry of all available skill bundles.
///
/// Each bundle maps to a set of source files in `flutter-plans/`,
/// `nestjs-plans/`, or `security-plans/` and defines how they are
/// installed into each agent.
class SkillRegistry {
  SkillRegistry._();

  /// All registered skill bundles.
  static const List<SkillBundle> skills = [
    SkillBundle(
      id: 'flutter_health',
      name: 'somnio-fh',
      displayName: 'Flutter Project Health Audit',
      description:
          'Execute a comprehensive Flutter Project Health Audit. '
          'Analyzes tech stack, architecture, state management, testing, '
          'code quality, CI/CD, and documentation. Produces a '
          'Google Docs-ready report with section scores and weighted '
          'overall score.',
      planRelativePath:
          'flutter-plans/flutter_project_health_audit/plan/flutter-health.plan.md',
      rulesDirectory:
          'flutter-plans/flutter_project_health_audit/cursor_rules',
      workflowPath:
          'flutter-plans/flutter_project_health_audit/.agent/workflows/flutter_health_audit.md',
      templatePath:
          'flutter-plans/flutter_project_health_audit/cursor_rules/templates/flutter_report_template.txt',
    ),
    SkillBundle(
      id: 'flutter_plan',
      name: 'somnio-fp',
      displayName: 'Flutter Best Practices Check',
      description:
          'Execute a micro-level Flutter code quality audit. '
          'Validates code against live GitHub standards for testing, '
          'architecture, and code implementation. Produces a detailed '
          'violations report with prioritized action plan.',
      planRelativePath:
          'flutter-plans/flutter_best_practices_check/plan/best_practices.plan.md',
      rulesDirectory:
          'flutter-plans/flutter_best_practices_check/cursor_rules',
      workflowPath:
          'flutter-plans/flutter_best_practices_check/.agent/workflows/flutter_best_practices.md',
      templatePath:
          'flutter-plans/flutter_best_practices_check/cursor_rules/templates/best_practices_report_template.txt',
    ),
    SkillBundle(
      id: 'nestjs_health',
      name: 'somnio-nh',
      displayName: 'NestJS Project Health Audit',
      description:
          'Execute a comprehensive NestJS Project Health Audit. '
          'Analyzes tech stack, architecture, API design, data layer, '
          'testing, code quality, CI/CD, and documentation. '
          'Produces a Google Docs-ready report with section scores and '
          'weighted overall score.',
      planRelativePath:
          'nestjs-plans/nestjs_project_health_audit/plan/nestjs-health.plan.md',
      rulesDirectory:
          'nestjs-plans/nestjs_project_health_audit/cursor_rules',
      workflowPath:
          'nestjs-plans/nestjs_project_health_audit/.agent/workflows/nestjs_health_audit.md',
      templatePath:
          'nestjs-plans/nestjs_project_health_audit/cursor_rules/templates/nestjs_report_template.txt',
    ),
    SkillBundle(
      id: 'nestjs_plan',
      name: 'somnio-np',
      displayName: 'NestJS Best Practices Check',
      description:
          'Execute a micro-level NestJS code quality audit. '
          'Validates code against live GitHub standards for testing, '
          'architecture, DTO validation, error handling, and code '
          'implementation. Produces a detailed violations report with '
          'prioritized action plan.',
      planRelativePath:
          'nestjs-plans/nestjs_best_practices_check/plan/best_practices.plan.md',
      rulesDirectory:
          'nestjs-plans/nestjs_best_practices_check/cursor_rules',
      workflowPath:
          'nestjs-plans/nestjs_best_practices_check/.agent/workflows/nestjs_best_practices.md',
      templatePath:
          'nestjs-plans/nestjs_best_practices_check/cursor_rules/templates/best_practices_report_template.txt',
    ),
    SkillBundle(
      id: 'security_audit',
      name: 'somnio-sa',
      displayName: 'Security Audit',
      description:
          'Execute a comprehensive, framework-agnostic Security Audit. '
          'Detects project type at runtime and adapts security checks '
          'accordingly. Analyzes sensitive files, source code secrets, '
          'dependency vulnerabilities, and optionally uses Gemini AI '
          'for advanced analysis. Produces a severity-classified report.',
      planRelativePath:
          'security-plans/security_audit/plan/security.plan.md',
      rulesDirectory:
          'security-plans/security_audit/cursor_rules',
      workflowPath:
          'security-plans/security_audit/.agent/workflows/security_audit.md',
      templatePath:
          'security-plans/security_audit/cursor_rules/templates/security_report_template.txt',
    ),
  ];

  /// Find a skill bundle by its ID.
  static SkillBundle? findById(String id) {
    for (final skill in skills) {
      if (skill.id == id) return skill;
    }
    return null;
  }

  /// Find a skill bundle by its name.
  static SkillBundle? findByName(String name) {
    for (final skill in skills) {
      if (skill.name == name) return skill;
    }
    return null;
  }

  /// Returns unique technology display names derived from registered bundles.
  ///
  /// Driven entirely by [SkillBundle.techDisplayName], so adding a new
  /// tech via `somnio add` automatically surfaces it.
  static List<String> get technologies {
    final techs = <String>{};
    for (final skill in skills) {
      techs.add(skill.techDisplayName);
    }
    return techs.toList()..sort();
  }

  /// Returns bundles matching the given technology display names.
  static List<SkillBundle> byTechnologies(List<String> techNames) {
    return skills
        .where((s) => techNames.contains(s.techDisplayName))
        .toList();
  }
}
