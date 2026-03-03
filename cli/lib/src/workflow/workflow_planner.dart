import 'dart:io';

import 'package:mason_logger/mason_logger.dart';

import '../agents/agent_config.dart';

/// Plans a workflow by invoking an AI process with a meta-prompt.
///
/// The AI interacts with the user to understand the workflow goal,
/// then generates `context.md` and step files in the workflow directory.
class WorkflowPlanner {
  WorkflowPlanner({
    required this.agentConfig,
    required this.logger,
  });

  final AgentConfig agentConfig;
  final Logger logger;

  /// Invokes the AI to create the workflow.
  ///
  /// Returns `true` if the planner executed successfully.
  Future<bool> plan({
    required String workflowName,
    required String workflowDir,
  }) async {
    final metaPrompt = _buildMetaPrompt(workflowName, workflowDir);

    // Use the best available model for planning
    final model = agentConfig.models.isNotEmpty
        ? agentConfig.models.last // Last model is typically the best
        : null;

    try {
      final args = agentConfig.buildArgs(metaPrompt, model: model);
      final result = await Process.run(
        agentConfig.binary!,
        args,
        workingDirectory: Directory.current.path,
      );

      if (result.exitCode != 0) {
        final stderr = (result.stderr as String? ?? '').trim();
        if (stderr.isNotEmpty) {
          logger.err(stderr);
        }
        return false;
      }

      return true;
    } catch (e) {
      logger.err('Failed to launch ${agentConfig.displayName}: $e');
      return false;
    }
  }

  String _buildMetaPrompt(String workflowName, String workflowDir) {
    return '''
You are a workflow planner. Your job is to create a structured workflow for the user.

## Your Task

1. Ask the user what task this workflow should accomplish
2. Break it down into sequential steps (3-8 steps typically)
3. For each step, determine:
   - A descriptive name
   - The appropriate tag: "research" (analysis/reading), "planning" (strategy/decisions), or "execution" (making changes)
   - Whether it's mandatory (must succeed to continue)
   - Whether it needs the previous step's output (needs_previous)
4. Write all files to: $workflowDir

## Output Files

### context.md
Write this file with YAML frontmatter:

```
---
name: $workflowName
description: <one-line description>
created: ${DateTime.now().toUtc().toIso8601String()}
version: 1
steps:
  - file: 01-<step-name>.md
    tag: <research|planning|execution>
    mandatory: <true|false>
  - file: 02-<step-name>.md
    tag: <research|planning|execution>
    mandatory: <true|false>
    needs_previous: <true|false>
---

# $workflowName

<Description of what this workflow does>

## Steps
1. **Step Name** (tag) - Brief description
...
```

### Step Files (01-<name>.md, 02-<name>.md, ...)
Each step file has YAML frontmatter + a prompt body:

```
---
name: <Step Name>
tag: <research|planning|execution>
index: <1-based>
mandatory: <true|false>
needs_previous: <true|false>
---

# <Step Name>

## Objective
<What this step should accomplish>

## Instructions
<Detailed instructions for the AI executing this step>

## Output
Save your output to: {output_path}

Include:
- <what to include in the output>
```

## Placeholder Rules

Step prompts can use these placeholders (resolved at runtime):
- `{output_path}` - Where this step should save its output
- `{previous_output}` - Path to the previous step's output (only use when needs_previous is true)
- `{outputs_dir}` - The outputs directory
- `{workflow_dir}` - The workflow root directory

## Rules

1. Only set `needs_previous: true` when a step genuinely needs the prior step's output to function
2. Research steps typically don't need previous output
3. Execution steps that implement a plan should reference the planning step's output
4. Use kebab-case for step filenames
5. Number step files with zero-padded indices (01-, 02-, etc.)
6. Each step should be self-contained enough to run in a fresh AI context
7. Step prompts should be clear and specific about what to analyze/do

## Important

Write all files directly. Do not ask for confirmation — the user will review the files after creation.
Create the files in: $workflowDir
''';
  }
}
