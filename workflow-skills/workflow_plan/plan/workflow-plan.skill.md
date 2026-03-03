# Workflow Planner

Create a custom, repeatable workflow with multiple steps that can each use different AI models.

## What You'll Create

A workflow is a directory at `.somnio/workflows/<name>/` containing:
- `context.md` — manifest with step list, tags, and metadata
- Step files (`01-<name>.md`, `02-<name>.md`, ...) — individual step prompts
- Config files — model assignments per IDE

## Instructions

### Step 1: Gather Requirements

Ask the user:
1. What should this workflow accomplish?
2. What name should it have? (kebab-case, e.g., `dependency-cleanup`)
3. Should it be project-level (`.somnio/workflows/`) or global (`~/.somnio/workflows/`)?

### Step 2: Design Steps

Break the task into 3-8 sequential steps. For each step determine:

- **Name**: descriptive, action-oriented
- **Tag**: one of:
  - `research` — analysis, reading, scanning (typically uses a fast/cheap model)
  - `planning` — strategy, decisions, prioritization (typically uses the best model)
  - `execution` — making changes, running commands (typically uses a balanced model)
- **Mandatory**: must succeed for the workflow to continue? (default: false)
- **needs_previous**: does this step genuinely need the prior step's output? (default: false)

### Step 3: Create Files

#### context.md

Create the manifest file with YAML frontmatter:

```markdown
---
name: <workflow-name>
description: <one-line description>
created: <ISO 8601 timestamp>
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

# <workflow-name>

<Description of what this workflow does>

## Steps
1. **Step Name** (tag) - Brief description
2. ...
```

#### Step Files

Each step file uses YAML frontmatter + markdown body:

```markdown
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
- <what to include>
```

### Step 4: Placeholders

Step prompts support these placeholders (resolved at runtime):

| Placeholder | Resolves to |
|---|---|
| `{output_path}` | Where this step saves its output |
| `{previous_output}` | Previous step's output path (only when `needs_previous: true`) |
| `{outputs_dir}` | The outputs directory |
| `{workflow_dir}` | The workflow root directory |

### Step 5: Validate

After creating all files, verify:
- [ ] `context.md` has valid YAML frontmatter
- [ ] All step files listed in context.md exist
- [ ] Step indices are sequential (1, 2, 3, ...)
- [ ] `needs_previous: true` is only set when genuinely needed
- [ ] Each step has clear instructions and uses `{output_path}`

## Rules

1. Only set `needs_previous: true` when a step genuinely requires the prior step's output
2. Research steps typically don't need previous output
3. Execution steps implementing a plan should reference `{previous_output}`
4. Use kebab-case for step filenames
5. Number files with zero-padded indices (01-, 02-, etc.)
6. Each step should be self-contained enough to run in a fresh AI context
7. Step prompts should be specific about what to analyze or do

## Next Steps

After creating the workflow, tell the user:
1. Review the generated files
2. Configure models: `somnio workflow config <name>`
3. Run the workflow: `somnio workflow run <name>`
