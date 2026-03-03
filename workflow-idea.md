# Feature Request: /workflow Command System

## Overview

Implement a `/workflow` command type for **static, repeatable task pipelines** — sequences that
don't change over time and must execute deterministically, step by step, with the main model
acting as a lightweight orchestrator.

---

## Core Concepts

### What is a Workflow?
A workflow is a pre-defined sequence of steps where:
- Each step is **self-contained** (its own context, model, and instructions)
- The orchestrator has **minimal context** — it only tracks step completion and triggers the next
- Each step is tagged as one of: `research`, `planning`, or `execution`
- Steps are stored as individual `.md` files: `01-step-name.md`, `02-step-name.md`, etc.

### Model Assignment per Step
Different steps may require different models. The system must support:
- **Role-based assignment**: `researcher → haiku`, `planner → opus`, `executor → sonnet`
- **Phase-based assignment**: haiku on steps 1,5,9 — sonnet on 2,4,8 — opus on the rest
- **IDE-aware configuration**: Claude Code exposes haiku/sonnet/opus natively; Cursor requires
  the user to manually pre-configure all model choices

---

## Commands

### `/workflow:plan`
Uses **Opus** to interactively generate a new workflow:

1. Ask the user for a **workflow name**
2. Ask what the workflow should accomplish
3. Generate a structured plan with named steps
4. Create a folder: `.somnio/workflows/<workflow-name>/`
5. Inside the folder, generate:
   - `context.md` — index of all steps, their tags, and assigned models
   - `01-<step-name>.md`, `02-<step-name>.md`, ... — one file per step

Each step `.md` file contains:
- **Tag**: `research` | `planning` | `execution`
- **Assigned model**: (from user config or defaults)
- **Task instructions**: what the subagent must do
- **Output format**: how to report back or what file to save on completion

---

### `/workflow:config <workflow-name>` *(first run or re-config)*
Triggered automatically on first `/workflow:run` if no config exists for the current IDE.

Prompts the user to assign models to:
- Specific **step numbers** (e.g., steps 1,5,9 → haiku)
- Or **role types** (research/planning/execution → model)

Config is saved at: `.somnio/workflows/<workflow-name>/config.<ide>.json`

Example config structure:
```json
{
  "ide": "cursor",
  "model_assignments": {
    "by_phase": {
      "1,5,9": "haiku",
      "2,4,8": "sonnet",
      "default": "opus"
    }
  }
}
```

---

### `/workflow:run <workflow-name>`
Executes the workflow. The orchestrator:

1. Loads `context.md` to get the full step list and model assignments
2. For each step (in order):
   - Reads the step `.md` file
   - Triggers a **subagent** with only that step's content (no other context)
   - The subagent executes and either:
     - Reports completion back to the orchestrator, OR
     - Saves a `<step-name>-output.md` progress file
   - Orchestrator validates success/failure
   - On success → moves to next step
   - On failure → halts and reports which step failed and why
3. Workflow completes when all steps are marked done

**Key constraint**: The orchestrator must stay **context-free** — it only reads completion
signals, not the full output of each subagent.

---

## File Structure

```
.somnio/
└── workflows/
    └── <workflow-name>/
        ├── context.md              # Master index: steps, tags, model assignments
        ├── config.claudecode.json  # Model config for Claude Code
        ├── config.cursor.json      # Model config for Cursor
        ├── 01-<step-name>.md       # Step 1: self-contained agent+skill instructions
        ├── 02-<step-name>.md       # Step 2
        ├── ...
        └── outputs/
            ├── 01-<step-name>-output.md
            └── 02-<step-name>-output.md
```

---

## Open Questions to Resolve Before Implementation

1. **Failure handling**: Should a failed step retry automatically (with a max attempt count),
   prompt the user for intervention, or halt entirely?

2. **Step dependencies**: Can a step receive output from a previous step as input, or must each
   step be 100% independent?

3. **Workflow versioning**: If the workflow `.md` files are edited after partial execution, how
   should the system handle resume vs restart?

4. **IDE detection**: How does the system detect which IDE is running to load the correct config?
   (env variable? CLI flag? auto-detect from process?)

5. **Shared workflows**: Should workflows in `.somnio/` be committed to the repo (team-shared) or
   gitignored (user-local)?

6. **Model availability fallback**: If a configured model is unavailable in the current IDE,
   should it fallback to the next available model or halt with an error?