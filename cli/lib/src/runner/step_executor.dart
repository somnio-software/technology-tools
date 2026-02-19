import 'dart:convert';
import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;

import 'run_config.dart';

/// Token usage statistics from an AI CLI invocation.
class TokenUsage {
  const TokenUsage({
    required this.inputTokens,
    required this.outputTokens,
    this.cacheReadTokens = 0,
    this.cacheCreationTokens = 0,
    this.costUsd,
  });

  final int inputTokens;
  final int outputTokens;
  final int cacheReadTokens;
  final int cacheCreationTokens;
  final double? costUsd;

  /// Total input tokens including cache.
  int get totalInputTokens =>
      inputTokens + cacheReadTokens + cacheCreationTokens;
}

/// Result of executing a single step.
class StepResult {
  const StepResult({
    required this.step,
    required this.success,
    required this.artifactPath,
    required this.durationSeconds,
    this.errorMessage,
    this.tokenUsage,
  });

  final ExecutionStep step;
  final bool success;
  final String artifactPath;
  final int durationSeconds;
  final String? errorMessage;
  final TokenUsage? tokenUsage;
}

/// Executes individual plan steps by invoking an AI CLI in a fresh context.
///
/// Each step spawns a separate process (`claude -p` or `gemini -p`),
/// which ensures a fresh context window per step. The AI reads the
/// rule file and saves findings as an artifact on disk.
class StepExecutor {
  StepExecutor({
    required this.config,
    required this.logger,
  });

  final RunConfig config;
  final Logger logger;

  /// Fallback model to use when the primary model hits quota limits.
  ///
  /// Set by the caller (RunCommand) based on the agent's cheapest model.
  String? fallbackModel;

  /// Executes a single standard step.
  ///
  /// The AI CLI reads the rule file and saves findings as an artifact.
  Future<StepResult> execute(ExecutionStep step) async {
    final stopwatch = Stopwatch()..start();
    final artifactPath = _artifactPath(step);

    // Verify rule file exists before spawning process
    final ruleFile = _ruleFilePath(step.ruleName);
    if (!File(ruleFile).existsSync()) {
      stopwatch.stop();
      return StepResult(
        step: step,
        success: false,
        artifactPath: artifactPath,
        durationSeconds: stopwatch.elapsed.inSeconds,
        errorMessage: 'Rule file not found: $ruleFile',
      );
    }

    final prompt = _buildStepPrompt(step, ruleFile, artifactPath);

    try {
      var result = await _runProcess(prompt);

      // Fallback: retry with cheapest model on quota/capacity errors
      if (result.exitCode != 0 &&
          fallbackModel != null &&
          fallbackModel != config.model &&
          _isQuotaError(result)) {
        logger.info(
          '  Quota exceeded for "${config.model}", '
          'retrying with "$fallbackModel"...',
        );
        result = await _runProcess(prompt, modelOverride: fallbackModel);
      }

      stopwatch.stop();

      final artifactExists = File(artifactPath).existsSync();
      final usage = _parseTokenUsage(result.stdout as String);

      return StepResult(
        step: step,
        success: result.exitCode == 0 && artifactExists,
        artifactPath: artifactPath,
        durationSeconds: stopwatch.elapsed.inSeconds,
        tokenUsage: usage,
        errorMessage: result.exitCode != 0
            ? _describeProcessError(result)
            : (!artifactExists
                ? 'Artifact not created: $artifactPath'
                : null),
      );
    } catch (e) {
      stopwatch.stop();
      return StepResult(
        step: step,
        success: false,
        artifactPath: artifactPath,
        durationSeconds: stopwatch.elapsed.inSeconds,
        errorMessage: 'Process error: $e',
      );
    }
  }

  /// Writes a pre-flight artifact directly to disk, skipping AI invocation.
  ///
  /// Used when the CLI pre-flight already completed this step's work
  /// (e.g., tool installation, version alignment, test coverage).
  Future<StepResult> writePreflightArtifact(
    ExecutionStep step,
    String content,
  ) async {
    final artifactPath = _artifactPath(step);
    try {
      File(artifactPath).writeAsStringSync(content);
      return StepResult(
        step: step,
        success: true,
        artifactPath: artifactPath,
        durationSeconds: 0,
      );
    } catch (e) {
      return StepResult(
        step: step,
        success: false,
        artifactPath: artifactPath,
        durationSeconds: 0,
        errorMessage: 'Failed to write pre-flight artifact: $e',
      );
    }
  }

  /// Executes the report generator step (special handling).
  ///
  /// This step reads all previous artifacts and the report template,
  /// then generates the final audit report.
  Future<StepResult> executeReportGenerator(ExecutionStep step) async {
    final stopwatch = Stopwatch()..start();
    final reportPath = config.reportPath;

    // Verify rule file exists
    final ruleFile = _ruleFilePath(step.ruleName);
    if (!File(ruleFile).existsSync()) {
      stopwatch.stop();
      return StepResult(
        step: step,
        success: false,
        artifactPath: reportPath,
        durationSeconds: stopwatch.elapsed.inSeconds,
        errorMessage: 'Rule file not found: $ruleFile',
      );
    }

    final prompt = _buildReportPrompt(step, ruleFile, reportPath);

    try {
      var result = await _runProcess(prompt);

      // Fallback: retry with cheapest model on quota/capacity errors
      if (result.exitCode != 0 &&
          fallbackModel != null &&
          fallbackModel != config.model &&
          _isQuotaError(result)) {
        logger.info(
          '  Quota exceeded for "${config.model}", '
          'retrying with "$fallbackModel"...',
        );
        result = await _runProcess(prompt, modelOverride: fallbackModel);
      }

      stopwatch.stop();

      final reportExists = File(reportPath).existsSync();
      final usage = _parseTokenUsage(result.stdout as String);

      return StepResult(
        step: step,
        success: result.exitCode == 0 && reportExists,
        artifactPath: reportPath,
        durationSeconds: stopwatch.elapsed.inSeconds,
        tokenUsage: usage,
        errorMessage: result.exitCode != 0
            ? _describeProcessError(result)
            : (!reportExists
                ? 'Report not created: $reportPath'
                : null),
      );
    } catch (e) {
      stopwatch.stop();
      return StepResult(
        step: step,
        success: false,
        artifactPath: reportPath,
        durationSeconds: stopwatch.elapsed.inSeconds,
        errorMessage: 'Process error: $e',
      );
    }
  }

  // --- Private helpers ---

  /// Produces a human-readable error message from a failed AI CLI process.
  ///
  /// Inspects stderr for known patterns (model not found, capacity exhausted,
  /// auth failures) and returns a targeted message instead of a generic
  /// "Process exited with code N".
  String _describeProcessError(ProcessResult result) {
    final stderr = (result.stderr as String? ?? '').toLowerCase();
    final stdout = (result.stdout as String? ?? '').toLowerCase();
    final combined = '$stderr $stdout';

    if (combined.contains('not_found') ||
        combined.contains('model not found') ||
        combined.contains('requested entity was not found')) {
      return 'Model "${config.model}" not found. '
          'Verify the model name is correct or try a different model.';
    }

    if (combined.contains('capacity') ||
        combined.contains('resource_exhausted') ||
        combined.contains('rate_limit') ||
        combined.contains('429')) {
      return 'No capacity available for model "${config.model}". '
          'You may not have an active subscription or sufficient quota '
          'for this model. Try a different model.';
    }

    if (combined.contains('unauthenticated') ||
        combined.contains('permission_denied') ||
        combined.contains('401') ||
        combined.contains('403')) {
      return 'Authentication failed. '
          'Verify you are logged in to the ${config.agent.name} CLI.';
    }

    return 'Process exited with code ${result.exitCode}';
  }

  /// Returns `true` if the process failed due to quota or capacity limits.
  bool _isQuotaError(ProcessResult result) {
    final combined =
        '${(result.stderr as String? ?? '')} ${(result.stdout as String? ?? '')}'
            .toLowerCase();
    return combined.contains('capacity') ||
        combined.contains('resource_exhausted') ||
        combined.contains('rate_limit') ||
        combined.contains('not_found') ||
        combined.contains('requested entity was not found') ||
        combined.contains('429');
  }

  String _ruleFilePath(String ruleName) {
    final ext = config.agent == RunAgent.gemini ? '.yaml' : '.md';
    return p.join(config.ruleBasePath, '$ruleName$ext');
  }


  String _artifactPath(ExecutionStep step) {
    final paddedIndex = step.index.toString().padLeft(2, '0');
    return p.join(
      config.artifactsDir,
      'step_${paddedIndex}_${step.ruleName}.md',
    );
  }

  String _buildStepPrompt(
    ExecutionStep step,
    String ruleFile,
    String artifactPath,
  ) {
    final readInstruction = config.agent == RunAgent.gemini
        ? 'Read $ruleFile and follow ALL instructions in the prompt field'
        : 'Read and follow ALL instructions in $ruleFile';

    return 'You are executing step ${step.index} of ${config.steps.length} '
        'in the ${config.displayName}.\n\n'
        '$readInstruction\n\n'
        'Save your complete findings to: $artifactPath\n'
        'Include: status, key findings, evidence (file paths and line numbers), '
        'and any scores.\n\n'
        'Create the directory if it does not exist:\n'
        'mkdir -p ${config.artifactsDir}\n\n'
        'IMPORTANT: You MUST write your findings to the artifact file above.';
  }

  String _buildReportPrompt(
    ExecutionStep step,
    String ruleFile,
    String reportPath,
  ) {
    final readInstruction = config.agent == RunAgent.gemini
        ? 'Read $ruleFile and follow the instructions in the prompt field '
            'for report generation.'
        : 'Read $ruleFile for report generation instructions.';

    final reportDir = p.dirname(reportPath);

    return 'You are generating the final audit report for the '
        '${config.displayName}.\n\n'
        'Read ALL files in ${config.artifactsDir}/ to gather findings '
        'from all previous analysis steps.\n\n'
        '$readInstruction\n\n'
        'Read ${config.templatePath} for the report format template.\n\n'
        'Save the final report to: $reportPath\n'
        'The report MUST be in plain text format suitable for Google Docs.\n\n'
        'Create the directory if it does not exist:\n'
        'mkdir -p $reportDir\n\n'
        'IMPORTANT: You MUST write the complete report to the file above.';
  }

  Future<ProcessResult> _runProcess(String prompt, {String? modelOverride}) {
    final model = modelOverride ?? config.model;
    switch (config.agent) {
      case RunAgent.claude:
        return Process.run(
          'claude',
          [
            '-p',
            prompt,
            '--allowedTools',
            'Read,Bash,Glob,Grep,Write',
            '--output-format',
            'json',
            if (model != null) ...['--model', model],
          ],
          workingDirectory: Directory.current.path,
        );
      case RunAgent.cursor:
        return Process.run(
          'agent',
          [
            '--print',
            '--output-format',
            'json',
            '--force',
            if (model != null) ...['--model', model],
            prompt,
          ],
          workingDirectory: Directory.current.path,
        );
      case RunAgent.gemini:
        return Process.run(
          'gemini',
          [
            '-p',
            prompt,
            '--yolo',
            '-o',
            'json',
            if (model != null) ...['--model', model],
          ],
          workingDirectory: Directory.current.path,
        );
    }
  }

  /// Parses token usage from the JSON stdout of an AI CLI invocation.
  ///
  /// Returns `null` if parsing fails or the agent doesn't expose token data
  /// (e.g., Cursor CLI).
  TokenUsage? _parseTokenUsage(String stdout) {
    try {
      final json = jsonDecode(stdout) as Map<String, dynamic>;

      switch (config.agent) {
        case RunAgent.claude:
          return _parseClaudeUsage(json);
        case RunAgent.cursor:
          // Cursor CLI does not expose token usage in its JSON output.
          return null;
        case RunAgent.gemini:
          return _parseGeminiUsage(json);
      }
    } catch (_) {
      return null;
    }
  }

  TokenUsage _parseClaudeUsage(Map<String, dynamic> json) {
    final usage = json['usage'] as Map<String, dynamic>? ?? {};
    return TokenUsage(
      inputTokens: (usage['input_tokens'] as num?)?.toInt() ?? 0,
      outputTokens: (usage['output_tokens'] as num?)?.toInt() ?? 0,
      cacheReadTokens:
          (usage['cache_read_input_tokens'] as num?)?.toInt() ?? 0,
      cacheCreationTokens:
          (usage['cache_creation_input_tokens'] as num?)?.toInt() ?? 0,
      costUsd: (json['total_cost_usd'] as num?)?.toDouble(),
    );
  }

  TokenUsage _parseGeminiUsage(Map<String, dynamic> json) {
    final stats = json['stats'] as Map<String, dynamic>? ?? {};
    final models = stats['models'] as Map<String, dynamic>? ?? {};

    var promptTokens = 0;
    var candidateTokens = 0;

    for (final model in models.values) {
      if (model is Map<String, dynamic>) {
        final tokens = model['tokens'] as Map<String, dynamic>? ?? {};
        promptTokens += (tokens['prompt'] as num?)?.toInt() ?? 0;
        candidateTokens += (tokens['candidates'] as num?)?.toInt() ?? 0;
      }
    }

    return TokenUsage(
      inputTokens: promptTokens,
      outputTokens: candidateTokens,
    );
  }
}
