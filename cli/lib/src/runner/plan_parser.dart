import 'run_config.dart';

/// Parses the "Rule Execution Order" section from a plan.md file
/// to extract ordered execution steps.
class PlanParser {
  /// Parses plan content and returns ordered execution steps.
  ///
  /// Expects a section like:
  /// ```
  /// **Rule Execution Order**:
  /// 1. `@flutter_tool_installer`
  /// 2. `@flutter_version_alignment` (MANDATORY - stops if FVM global fails)
  /// ```
  ///
  /// Returns an empty list if no "Rule Execution Order" section is found.
  List<ExecutionStep> parse(String planContent) {
    // Find the "Rule Execution Order" section
    final sectionPattern = RegExp(
      r'\*?\*?Rule Execution Order\*?\*?\s*:',
    );
    final sectionMatch = sectionPattern.firstMatch(planContent);
    if (sectionMatch == null) return [];

    // Get content after the section header
    final afterSection = planContent.substring(sectionMatch.end);
    final lines = afterSection.split('\n');

    // Parse numbered step lines
    final stepPattern = RegExp(
      r'^\s*(\d+)\.\s+`@(\w+)`\s*(.*?)$',
    );

    final steps = <ExecutionStep>[];
    var foundFirstStep = false;

    for (final line in lines) {
      final match = stepPattern.firstMatch(line);
      if (match != null) {
        foundFirstStep = true;
        final index = int.parse(match.group(1)!);
        final ruleName = match.group(2)!;
        final remainder = match.group(3)?.trim() ?? '';

        // Check for MANDATORY annotation
        final isMandatory = remainder.toUpperCase().contains('MANDATORY');

        // Extract annotation from parentheses
        String? annotation;
        final annotationMatch = RegExp(r'\((.+)\)').firstMatch(remainder);
        if (annotationMatch != null) {
          annotation = annotationMatch.group(1)!.trim();
        }

        steps.add(ExecutionStep(
          index: index,
          ruleName: ruleName,
          isMandatory: isMandatory,
          annotation: annotation,
        ));
      } else if (foundFirstStep && line.trim().isEmpty) {
        // Stop at first blank line after the list starts
        break;
      } else if (foundFirstStep && _isNewSection(line)) {
        // Stop at new section header (not a continuation line)
        break;
      }
      // Otherwise: continuation line (e.g., wrapped annotation) — skip it
    }

    return steps;
  }

  /// Checks if a line starts a new markdown section (not a continuation).
  ///
  /// Continuation lines are indented text from wrapped annotations.
  /// New sections start with `**`, `#`, `-`, or other markdown markers.
  bool _isNewSection(String line) {
    final trimmed = line.trimLeft();
    return trimmed.startsWith('**') ||
        trimmed.startsWith('#') ||
        trimmed.startsWith('- ');
  }
}
