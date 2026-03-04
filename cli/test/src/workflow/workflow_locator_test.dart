import 'package:somnio/src/workflow/workflow_locator.dart';
import 'package:test/test.dart';

void main() {
  group('WorkflowLocator', () {
    group('isValidName', () {
      test('accepts valid kebab-case names', () {
        expect(WorkflowLocator.isValidName('my-workflow'), isTrue);
        expect(WorkflowLocator.isValidName('dependency-cleanup'), isTrue);
        expect(WorkflowLocator.isValidName('test'), isTrue);
        expect(WorkflowLocator.isValidName('a'), isTrue);
        expect(WorkflowLocator.isValidName('test123'), isTrue);
        expect(WorkflowLocator.isValidName('my-test-3'), isTrue);
      });

      test('rejects invalid names', () {
        expect(WorkflowLocator.isValidName('My-Workflow'), isFalse);
        expect(WorkflowLocator.isValidName('my_workflow'), isFalse);
        expect(WorkflowLocator.isValidName('my workflow'), isFalse);
        expect(WorkflowLocator.isValidName(''), isFalse);
        expect(WorkflowLocator.isValidName('123-abc'), isFalse);
        expect(WorkflowLocator.isValidName('-start'), isFalse);
        expect(WorkflowLocator.isValidName('end-'), isFalse);
        expect(WorkflowLocator.isValidName('double--dash'), isFalse);
      });
    });
  });

  group('WorkflowLocation', () {
    test('contextPath joins correctly', () {
      const loc = WorkflowLocation(
        path: '/test/workflows/my-wf',
        scope: WorkflowScope.project,
        name: 'my-wf',
      );
      expect(loc.contextPath, '/test/workflows/my-wf/context.md');
    });

    test('progressPath joins correctly', () {
      const loc = WorkflowLocation(
        path: '/test/workflows/my-wf',
        scope: WorkflowScope.project,
        name: 'my-wf',
      );
      expect(loc.progressPath, '/test/workflows/my-wf/progress.json');
    });

    test('outputsDir joins correctly', () {
      const loc = WorkflowLocation(
        path: '/test/workflows/my-wf',
        scope: WorkflowScope.project,
        name: 'my-wf',
      );
      expect(loc.outputsDir, '/test/workflows/my-wf/outputs');
    });

    test('configPath maps agent correctly', () {
      const loc = WorkflowLocation(
        path: '/test/workflows/my-wf',
        scope: WorkflowScope.project,
        name: 'my-wf',
      );
      expect(
        loc.configPath('claude'),
        '/test/workflows/my-wf/config.claudecode.json',
      );
      expect(
        loc.configPath('cursor'),
        '/test/workflows/my-wf/config.cursor.json',
      );
    });

    test('outputPath generates correct output file path', () {
      const loc = WorkflowLocation(
        path: '/test/workflows/my-wf',
        scope: WorkflowScope.project,
        name: 'my-wf',
      );
      expect(
        loc.outputPath('01-analyze-deps.md'),
        '/test/workflows/my-wf/outputs/01-analyze-deps-output.md',
      );
    });
  });
}
