# Workflow Runner

Execute a custom workflow step by step, spawning a subagent for each step with the appropriate model.

## Usage

```
/workflow:run <name>
```

Where `<name>` is the workflow name (e.g., `dependency-cleanup`).

## Instructions

### Step 1: Locate Workflow

Search for the workflow directory in order:
1. `.somnio/workflows/<name>/` (project-level)
2. `~/.somnio/workflows/<name>/` (global)

If not found, inform the user and suggest `somnio workflow plan <name>` to create one.

### Step 2: Read Manifest

Read `context.md` and parse the YAML frontmatter to get:
- Workflow name and description
- Ordered list of steps with their tags, mandatory flags, and needs_previous flags

### Step 3: Load Config

Read `config.claudecode.json` for model assignments:
- `by_role` maps tags to models (e.g., `research` → `haiku`)
- `by_step` overrides specific steps (takes precedence over by_role)

If no config file exists, use defaults:
- `research` → `haiku`
- `planning` → `opus`
- `execution` → `sonnet`

### Step 4: Check Progress

Read `progress.json` if it exists:
- If a previous run was interrupted, ask the user: "Resume from step N?" or "Restart?"
- If all steps completed, ask if they want to re-run

### Step 5: Execute Steps

For each pending step:

1. **Read the step file** (e.g., `01-analyze-dependencies.md`)
2. **Resolve the model**: `by_step[index]` → `by_role[tag]` → default
3. **Resolve placeholders** in the step body:
   - `{output_path}` → `outputs/<step-name>-output.md`
   - `{previous_output}` → previous step's output path (only if `needs_previous: true`)
   - `{outputs_dir}` → `outputs/`
   - `{workflow_dir}` → workflow directory path
4. **Create the outputs directory** if it doesn't exist
5. **Spawn a subagent** using the Agent tool with:
   - The resolved step prompt as the task
   - The resolved model
6. **Verify output** was created at the expected path
7. **Update progress.json** with status, model used, and duration

### Step 6: Handle Failures

- If a **mandatory** step fails → halt execution, report the error
- If a **non-mandatory** step fails → log warning, continue to next step
- On any failure, save progress so the user can resume later

### Step 7: Report Results

After all steps complete (or on failure), report:
- Steps completed / total
- Total duration
- Output file locations
- Any warnings or errors

## Progress Tracking

Update `progress.json` after each step:

```json
{
  "workflow": "<name>",
  "agent": "claude",
  "started_at": "<ISO 8601>",
  "steps": [
    {
      "file": "01-analyze.md",
      "status": "completed",
      "model": "haiku",
      "duration_s": 42
    },
    {
      "file": "02-plan.md",
      "status": "pending"
    }
  ]
}
```

Valid status values: `pending`, `running`, `completed`, `failed`

## Model Resolution

For a step with tag `execution` and index `3`:
1. Check `by_step["3"]` in config → most specific
2. Check `by_role["execution"]` in config → tag-based default
3. Fall back to agent default

## Important

- Each step runs in a **fresh context** (separate subagent)
- Steps should be self-contained with clear instructions
- Only inject `{previous_output}` when `needs_previous: true`
- Always save progress after each step for resumability
