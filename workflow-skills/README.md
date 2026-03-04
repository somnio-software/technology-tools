# Somnio Workflow Skills

Custom, repeatable task pipelines where each step can use a different AI model. The orchestrator stays context-light, spawning a fresh AI process per step. Works with any of the 17 supported agents.

## How It Works

A **workflow** is a directory containing a manifest (`context.md`), numbered step files, a model config, and runtime state. You create it once, then run it whenever you need — across projects or globally.

```
.somnio/workflows/dependency-cleanup/
  context.md                     # Manifest: steps, tags, metadata
  config.<agent>.json              # Model assignments (per agent)
  01-analyze-dependencies.md      # Step 1 prompt
  02-plan-updates.md              # Step 2 prompt
  03-execute-updates.md           # Step 3 prompt
  04-verify-build.md              # Step 4 prompt
  progress.json                   # Runtime: tracks execution state
  outputs/                        # Runtime: step output artifacts
    01-analyze-dependencies-output.md
    02-plan-updates-output.md
    ...
```

Each step is tagged with a **role** — `research`, `planning`, or `execution` — that maps to a model tier:

| Tag | Default Model | Purpose |
|-----|--------------|---------|
| `research` | haiku | Fast analysis, scanning, reading |
| `planning` | opus | Strategy, decisions, architecture |
| `execution` | sonnet | Making changes, running commands |

You can override these defaults per-role or per-step via the config file.

---

## Two Ways to Use Workflows

### 1. CLI (`somnio workflow`)

The Somnio CLI orchestrates workflows by spawning a fresh AI CLI process per step. Works with any supported CLI agent: Claude Code, Cursor, Gemini, Antigravity, Codex, Augment Code, Amp, Aider, Cline, OpenCode, CodeBuddy, and Qwen.

### 2. IDE Skills (`/workflow:plan`, `/workflow:run`)

IDEs that support subagent spawning (Claude Code, Cursor, Antigravity, and others) can run workflows natively via installed skills. The agent orchestrator launches a subagent per step with the configured model — no need to leave your IDE session. Install skills with `somnio install --agent <id>`.

For agents without subagent support, use the CLI path (`somnio workflow run`) instead.

---

## CLI Usage

### Create a Workflow

```bash
somnio workflow plan <name>
```

The planner launches an AI session that asks you what the workflow should do, breaks it into steps, and writes all the files.

```bash
# Example: create a workflow to clean up dependencies
somnio workflow plan dependency-cleanup

# You'll be prompted:
#   Where should this workflow be created? (project / global)
#
# The AI then asks about your workflow goal and generates:
#   .somnio/workflows/dependency-cleanup/
#     context.md
#     01-analyze-dependencies.md
#     02-plan-updates.md
#     03-execute-updates.md
#     04-verify-build.md
```

Workflow names must be **kebab-case** (e.g., `my-workflow`, `api-migration`).

**Scope:**
- **Project** (default) — stored in `.somnio/workflows/` at project root, committable to git
- **Global** — stored in `~/.somnio/workflows/`, available across all projects

### Configure Models

```bash
somnio workflow config <name>
```

Interactive wizard that maps step tags to models and optionally overrides specific steps.

```bash
somnio workflow config dependency-cleanup

# Output:
#   Workflow: dependency-cleanup
#   Agent:    claude
#
#   Steps:
#     1. 01-analyze-dependencies.md (research)
#     2. 02-plan-updates.md (planning)
#     3. 03-execute-updates.md (execution) [MANDATORY]
#     4. 04-verify-build.md (execution) [MANDATORY]
#
#   Model mapping strategy: (defaults / customize)
#   > defaults
#   Using defaults: research=haiku, planning=opus, execution=sonnet
#
#   Config saved to: .somnio/workflows/dependency-cleanup/config.claudecode.json
```

To configure for a specific agent:

```bash
somnio workflow config dependency-cleanup --agent gemini
```

### Run a Workflow

```bash
somnio workflow run <name>
```

Executes each step in order, spawning a fresh AI process per step with the configured model.

```bash
somnio workflow run dependency-cleanup

# Output:
#   Workflow: dependency-cleanup
#   Agent:    claude
#   Steps:    4
#   Scope:    project
#
#   Step 1/4: Analyze Dependencies (haiku) ... (42s)
#   Step 2/4: Plan Updates (opus) ... (68s)
#   Step 3/4: Execute Updates (sonnet) ... (95s)
#   Step 4/4: Verify Build (sonnet) ... (31s)
#
#   Workflow completed! 4 steps in 236s
#   Outputs: .somnio/workflows/dependency-cleanup/outputs/
```

**Flags:**

| Flag | Description |
|------|-------------|
| `--agent`, `-a` | Force a specific AI CLI (e.g., `--agent gemini`) |
| `--restart` | Ignore saved progress and start from step 1 |

**Resume on failure:** If a step fails, progress is saved. Running the same command again prompts you to resume, restart, or cancel.

```bash
somnio workflow run dependency-cleanup

# Previous run found (2/4 steps). Resume?
#   > resume / restart / cancel
```

### List Workflows

```bash
somnio workflow list

# Workflows:
#
#   dependency-cleanup  (4 steps, project, completed)
#     Analyze and clean up project dependencies
#   api-migration       (6 steps, global, 3/6 steps)
#     Migrate REST API to GraphQL
```

Shows all workflows from both project and global scopes, with step count and last run status.

---

## IDE Skills Usage

After installing skills with `somnio install --agent <id>`, two workflow skills are available as slash commands inside any IDE session that supports them (Claude Code, Cursor, Antigravity, and others).

### `/workflow:plan` — Create a Workflow

```
/workflow:plan
```

The agent will:
1. Ask you for a workflow name and description
2. Break your task into steps with appropriate tags
3. Create `context.md` and all step files in `.somnio/workflows/<name>/`
4. Apply `needs_previous` only where genuinely needed

### `/workflow:run <name>` — Run a Workflow

```
/workflow:run dependency-cleanup
```

The agent will:
1. Locate the workflow in `.somnio/workflows/` or `~/.somnio/workflows/`
2. Read the agent's config file for model assignments (or use defaults)
3. Check `progress.json` for resume capability
4. For each step: spawn a **subagent** with the step's model and prompt
5. Track progress in `progress.json` after each step
6. Halt on mandatory step failure

Each step runs in a **separate subagent context**, keeping the orchestrator lightweight.

### CLI vs IDE Skills

| | `somnio workflow run` (CLI) | `/workflow:run` (IDE Skill) |
|---|---|---|
| **How it works** | Somnio spawns a fresh AI CLI process per step | The IDE agent spawns subagents natively |
| **Requires** | `somnio` installed globally | Skills installed via `somnio install` |
| **Context** | Each step is a separate OS process | Each step is a separate subagent |
| **Best for** | Any CLI agent, headless/CI use | IDE users with subagent support |

Both paths read the same workflow files and produce the same outputs.

---

## File Formats

### context.md

The workflow manifest with YAML frontmatter:

```markdown
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

Workflow that analyzes project dependencies, plans updates,
executes them safely, and verifies the build passes.

## Steps
1. **Analyze Dependencies** (research) - Scan and catalog all deps
2. **Plan Updates** (planning) - Create prioritized update strategy
3. **Execute Updates** (execution) - Apply updates using prior plan
4. **Verify Build** (execution) - Run tests and verify nothing broke
```

**Step entry fields:**

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `file` | string | required | Step filename (e.g., `01-analyze.md`) |
| `tag` | string | `execution` | `research`, `planning`, or `execution` |
| `mandatory` | bool | `false` | If true, workflow halts on step failure |
| `needs_previous` | bool | `false` | If true, previous step's output path is injected |

### Step File

Each step file has YAML frontmatter and a markdown prompt body:

```markdown
---
name: Execute Updates
tag: execution
index: 3
mandatory: true
needs_previous: true
---

# Execute Updates

## Objective
Apply the update strategy from the previous step.

## Instructions
1. Read the update plan from: {previous_output}
2. For each dependency marked for update:
   - Run the appropriate update command
   - Verify the package resolves
3. Commit changes incrementally

## Output
Save your execution log to: {output_path}

Include:
- List of updated packages with old -> new versions
- Any packages that failed to update (with errors)
- Summary of changes made
```

**Placeholders** (resolved at runtime by the orchestrator):

| Placeholder | Resolves to | When |
|-------------|------------|------|
| `{output_path}` | `outputs/<step-name>-output.md` | Always |
| `{previous_output}` | Previous step's output path | Only when `needs_previous: true` |
| `{outputs_dir}` | `outputs/` directory path | Always |
| `{workflow_dir}` | Workflow root directory path | Always |

### Config File

Per-agent model assignment configuration (e.g., `config.claudecode.json`):

```json
{
  "ide": "claudecode",
  "model_assignments": {
    "by_role": {
      "research": "haiku",
      "planning": "opus",
      "execution": "sonnet"
    },
    "by_step": {
      "3": "opus",
      "4": "haiku"
    }
  }
}
```

`by_step` overrides take precedence over `by_role`. Both are optional.

**Config filenames by agent:**

| Agent | Config file |
|-------|------------|
| Claude Code | `config.claudecode.json` |
| Cursor | `config.cursor.json` |
| Gemini / Antigravity | `config.gemini.json` |
| Codex | `config.codex.json` |

Note: Some agents may not support per-step model switching from the CLI. The config stores preferences, but inside the IDE the current chat model may be used instead. Use `somnio workflow run` for per-step model control when needed.

### progress.json

Tracks execution state for resume capability:

```json
{
  "workflow": "dependency-cleanup",
  "agent": "claude",
  "started_at": "2026-03-03T14:35:00Z",
  "steps": [
    { "file": "01-analyze-dependencies.md", "status": "completed", "model": "haiku", "duration_s": 42 },
    { "file": "02-plan-updates.md", "status": "completed", "model": "opus", "duration_s": 68 },
    { "file": "03-execute-updates.md", "status": "pending" },
    { "file": "04-verify-build.md", "status": "pending" }
  ]
}
```

Valid step statuses: `pending`, `running`, `completed`, `failed`.

---

## Model Resolution Order

For a step with tag `execution` at index `3`:

1. `config.<agent>.json` -> `by_step["3"]` (most specific)
2. `config.<agent>.json` -> `by_role["execution"]` (tag-based)
3. Agent's default model (fallback)

---

## Workflow Resolution Order

When running a workflow, the locator checks in order:

1. **Project-level**: `.somnio/workflows/<name>/` (in current directory)
2. **Global**: `~/.somnio/workflows/<name>/` (in home directory)

If the same workflow name exists in both scopes, the project-level version takes precedence.

---

## End-to-End Example

### Scenario: Automate a dependency cleanup pipeline

**Step 1 — Create the workflow:**

```bash
somnio workflow plan dependency-cleanup
# Choose: project
# AI generates 4 step files
```

**Step 2 — Review the generated files:**

```
.somnio/workflows/dependency-cleanup/
  context.md
  01-analyze-dependencies.md    # research: scan pubspec/package.json
  02-plan-updates.md            # planning: prioritize what to update
  03-execute-updates.md         # execution: run updates using the plan
  04-verify-build.md            # execution: run tests, check build
```

Edit any step files to refine the prompts.

**Step 3 — Configure models:**

```bash
somnio workflow config dependency-cleanup
# Use defaults: research=haiku, planning=opus, execution=sonnet
```

**Step 4 — Run it via CLI:**

```bash
somnio workflow run dependency-cleanup
# Each step runs with its assigned model
# Outputs saved to outputs/ directory
# Progress tracked in progress.json
```

**Or run it via IDE skill (if installed):**

```
/workflow:run dependency-cleanup
```

The agent reads the same workflow files and executes each step as a subagent.

**Step 5 — Re-run anytime:**

```bash
# On the same project or any project (if global)
somnio workflow run dependency-cleanup

# Or with a different agent
somnio workflow run dependency-cleanup --agent gemini
```

---

## Writing Good Step Prompts

1. **Be specific** — Each step runs in a fresh context with no memory of previous steps (unless `needs_previous: true` injects the prior output)
2. **Always use `{output_path}`** — The orchestrator checks this file to confirm step success
3. **Use `needs_previous` sparingly** — Only when a step genuinely can't work without the prior output
4. **Keep steps independent** — A step should make sense on its own when read in isolation
5. **Include output format** — Tell the AI what structure the output should have

---

## Directory Structure

```
workflow-skills/
  README.md                                          # This file
  workflow_plan/
    plan/
      workflow-plan.skill.md                         # /workflow:plan skill content
  workflow_run/
    plan/
      workflow-run.skill.md                          # /workflow:run skill content
```

These skill files are installed to the agent's skill directory when you run `somnio install --agent <id>` (e.g., `~/.claude/skills/` for Claude Code, `~/.cursor/commands/` for Cursor, etc.).
