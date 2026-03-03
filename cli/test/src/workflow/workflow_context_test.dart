import 'package:somnio/src/workflow/workflow_context.dart';
import 'package:test/test.dart';

void main() {
  group('WorkflowContext', () {
    group('parse', () {
      test('parses full context.md with all fields', () {
        const content = '''
---
name: dependency-cleanup
description: Analyze and clean up project dependencies
created: 2026-03-03T14:30:00Z
version: 1
steps:
  - file: 01-analyze-dependencies.md
    tag: research
    mandatory: false
  - file: 02-plan-updates.md
    tag: planning
    mandatory: false
    needs_previous: false
  - file: 03-execute-updates.md
    tag: execution
    mandatory: true
    needs_previous: true
  - file: 04-verify-build.md
    tag: execution
    mandatory: true
    needs_previous: false
---

# dependency-cleanup

Some description text here.
''';

        final context = WorkflowContext.parse(content);

        expect(context.name, 'dependency-cleanup');
        expect(context.description, 'Analyze and clean up project dependencies');
        expect(context.version, 1);
        expect(context.created, DateTime.utc(2026, 3, 3, 14, 30));
        expect(context.steps, hasLength(4));

        expect(context.steps[0].file, '01-analyze-dependencies.md');
        expect(context.steps[0].tag, 'research');
        expect(context.steps[0].mandatory, isFalse);
        expect(context.steps[0].needsPrevious, isFalse);

        expect(context.steps[2].file, '03-execute-updates.md');
        expect(context.steps[2].tag, 'execution');
        expect(context.steps[2].mandatory, isTrue);
        expect(context.steps[2].needsPrevious, isTrue);

        expect(context.steps[3].needsPrevious, isFalse);
      });

      test('parses minimal context.md', () {
        const content = '''
---
name: simple-task
description: A simple task
steps:
  - file: 01-do-it.md
    tag: execution
---
''';

        final context = WorkflowContext.parse(content);

        expect(context.name, 'simple-task');
        expect(context.version, 1);
        expect(context.created, isNull);
        expect(context.steps, hasLength(1));
      });

      test('defaults tag to execution when missing', () {
        const content = '''
---
name: test
description: test
steps:
  - file: 01-step.md
---
''';

        final context = WorkflowContext.parse(content);
        expect(context.steps[0].tag, 'execution');
      });

      test('defaults mandatory and needs_previous to false', () {
        const content = '''
---
name: test
description: test
steps:
  - file: 01-step.md
    tag: research
---
''';

        final context = WorkflowContext.parse(content);
        expect(context.steps[0].mandatory, isFalse);
        expect(context.steps[0].needsPrevious, isFalse);
      });

      test('throws on missing frontmatter', () {
        const content = '# No frontmatter here';

        expect(
          () => WorkflowContext.parse(content),
          throwsA(isA<FormatException>()),
        );
      });

      test('throws on unclosed frontmatter', () {
        const content = '''
---
name: broken
''';

        expect(
          () => WorkflowContext.parse(content),
          throwsA(isA<FormatException>()),
        );
      });

      test('handles empty steps list', () {
        const content = '''
---
name: empty
description: no steps
steps: []
---
''';

        final context = WorkflowContext.parse(content);
        expect(context.steps, isEmpty);
      });
    });
  });

  group('WorkflowStepEntry', () {
    test('toYaml produces correct map', () {
      const entry = WorkflowStepEntry(
        file: '01-analyze.md',
        tag: 'research',
        mandatory: true,
        needsPrevious: false,
      );

      final yaml = entry.toYaml();

      expect(yaml['file'], '01-analyze.md');
      expect(yaml['tag'], 'research');
      expect(yaml['mandatory'], isTrue);
      expect(yaml['needs_previous'], isFalse);
    });
  });
}
