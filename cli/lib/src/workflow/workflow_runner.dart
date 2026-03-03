import 'package:mason_logger/mason_logger.dart';

import '../agents/agent_config.dart';
import 'workflow_config.dart';
import 'workflow_context.dart';
import 'workflow_locator.dart';
import 'workflow_progress.dart';
import 'workflow_step.dart';
import 'workflow_step_executor.dart';

/// Orchestrates the execution of a workflow's steps in sequence.
///
/// For each pending step:
/// 1. Parses the step file
/// 2. Resolves the model (by_step → by_role → agent default)
/// 3. Resolves placeholders in the step body
/// 4. Spawns an AI process
/// 5. Updates progress.json
///
/// Supports resumption from the last incomplete step.
class WorkflowRunner {
  WorkflowRunner({
    required this.location,
    required this.context,
    required this.config,
    required this.agentConfig,
    required this.logger,
  });

  final WorkflowLocation location;
  final WorkflowContext context;
  final WorkflowConfig config;
  final AgentConfig agentConfig;
  final Logger logger;

  /// Runs all pending steps in the workflow.
  ///
  /// If [startFromIndex] is provided, skips to that step index (0-based).
  /// Returns the overall success status.
  Future<WorkflowRunResult> run({int startFromIndex = 0}) async {
    final executor = WorkflowStepExecutor(
      agentConfig: agentConfig,
      logger: logger,
    );

    // Initialize or load progress
    var progress = WorkflowProgress.loadFrom(location.progressPath);
    if (progress == null || startFromIndex == 0) {
      progress = WorkflowProgress(
        workflow: context.name,
        agent: agentConfig.id,
        steps: context.steps
            .map((s) => StepProgress(file: s.file))
            .toList(),
      );
      progress.saveTo(location.progressPath);
    }

    final results = <WorkflowStepResult>[];
    final totalSteps = context.steps.length;

    for (var i = startFromIndex; i < totalSteps; i++) {
      final stepEntry = context.steps[i];
      final stepIndex = i + 1; // 1-based for display

      // Parse step file
      final stepPath = location.stepPath(stepEntry.file);
      final step = WorkflowStep.loadFrom(stepPath);
      if (step == null) {
        logger.err('  Step file not found: $stepPath');
        if (stepEntry.mandatory) {
          return WorkflowRunResult(
            success: false,
            results: results,
            failedStep: stepEntry.file,
            errorMessage: 'Mandatory step file not found: ${stepEntry.file}',
          );
        }
        logger.warn('  Skipping optional step ${stepEntry.file}');
        progress.steps[i].status = StepStatus.completed;
        progress.saveTo(location.progressPath);
        continue;
      }

      // Resolve model
      final model = config.resolveModel(stepIndex, stepEntry.tag) ??
          agentConfig.defaultModel;

      // Resolve placeholders
      final outputPath = location.outputPath(stepEntry.file);
      String? previousOutputPath;
      if (stepEntry.needsPrevious && i > 0) {
        previousOutputPath = location.outputPath(context.steps[i - 1].file);
      }

      final resolvedBody = step.resolveBody(
        workflowDir: location.path,
        outputsDir: location.outputsDir,
        outputPath: outputPath,
        previousOutputPath: previousOutputPath,
      );

      // Update progress to running
      progress.steps[i].status = StepStatus.running;
      progress.steps[i].model = model;
      progress.saveTo(location.progressPath);

      // Log step start
      final modelLabel = model != null ? ' ($model)' : '';
      final progressMsg =
          'Step $stepIndex/$totalSteps: ${step.name}$modelLabel';
      final stepProgress = logger.progress(progressMsg);

      // Execute
      final result = await executor.execute(
        step: step,
        stepFile: stepEntry.file,
        resolvedBody: resolvedBody,
        outputPath: outputPath,
        model: model,
      );

      results.add(result);

      if (result.success) {
        progress.steps[i].status = StepStatus.completed;
        progress.steps[i].durationSeconds = result.durationSeconds;
        progress.saveTo(location.progressPath);
        stepProgress.complete(
          '$progressMsg (${result.durationSeconds}s)',
        );
      } else {
        progress.steps[i].status = StepStatus.failed;
        progress.steps[i].durationSeconds = result.durationSeconds;
        progress.saveTo(location.progressPath);
        stepProgress.fail(
          '$progressMsg - FAILED',
        );

        if (result.errorMessage != null) {
          logger.err('  ${result.errorMessage}');
        }

        if (stepEntry.mandatory) {
          return WorkflowRunResult(
            success: false,
            results: results,
            failedStep: stepEntry.file,
            errorMessage:
                'Mandatory step failed: ${stepEntry.file}'
                '${result.errorMessage != null ? " - ${result.errorMessage}" : ""}',
          );
        }
        logger.warn('  Non-mandatory step failed, continuing...');
      }
    }

    return WorkflowRunResult(
      success: true,
      results: results,
    );
  }
}

/// Overall result of a workflow run.
class WorkflowRunResult {
  const WorkflowRunResult({
    required this.success,
    required this.results,
    this.failedStep,
    this.errorMessage,
  });

  final bool success;
  final List<WorkflowStepResult> results;
  final String? failedStep;
  final String? errorMessage;

  int get totalDurationSeconds =>
      results.fold(0, (sum, r) => sum + r.durationSeconds);

  int get completedCount => results.where((r) => r.success).length;
}
