# Workflow Runner

Execute a custom workflow step by step, spawning a subagent for each step with the appropriate model. Independent steps run in parallel waves for faster execution.

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
- Ordered list of steps with their tags, mandatory flags, and dependencies (`needs`)

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

### Step 5: Plan Execution Waves

Group steps into parallel waves based on their `needs` dependencies:

- **Wave 1**: all steps with no dependencies (run concurrently)
- **Wave 2**: steps whose dependencies are all in wave 1 (run concurrently)
- And so on...

Example for a 6-step workflow:
```
Step 1: no deps       → Wave 1
Step 2: needs [1]     → Wave 2
Step 3: no deps       → Wave 1
Step 4: no deps       → Wave 1
Step 5: no deps       → Wave 1
Step 6: needs all     → Wave 2
```
Result: 2 waves instead of 6 sequential steps.

### Step 6: Execute Waves

For each wave:
1. **Launch all steps concurrently** using the Agent tool
2. For each step in the wave:
   - Read the step file
   - Resolve the model: `by_step[index]` → `by_role[tag]` → default
   - Resolve placeholders in the step body
   - Spawn a subagent with the resolved prompt and model
3. **Wait for all steps to complete**
4. **Update progress.json** (once per wave)
5. **Check mandatory failures** → abort before next wave if any mandatory step failed

### Step 7: Resolve Placeholders

Step prompts support these placeholders:
- `{output_path}` → `outputs/<step-name>-output.md`
- `{previous_output}` → previous step's output path
- `{step_N_output}` → step N's output path (1-based)
- `{outputs_dir}` → `outputs/`
- `{workflow_dir}` → workflow directory path

The `{step_N_output}` placeholder allows a step to reference any specific dependency's output:
```
Read findings from: {step_1_output}
Read scan results from: {step_3_output}
```

### Step 8: Handle Failures

- If a **mandatory** step fails → halt execution after the current wave completes
- If a **non-mandatory** step fails → log warning, continue
- On any failure, save progress so the user can resume later

### Step 9: Report Results

After all waves complete (or on failure), report:
- Steps completed / total
- Wall-clock time vs compute time (shows parallelism savings)
- Output file locations
- Any warnings or errors

Example output:
```
Workflow completed! 6 steps in 250s (646s compute)
```

## Progress Tracking

Update `progress.json` after each wave:

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
- Independent steps within a wave run **in parallel**
- Steps should be self-contained with clear instructions
- Use `{step_N_output}` to reference specific dependency outputs
- Always save progress after each wave for resumability
