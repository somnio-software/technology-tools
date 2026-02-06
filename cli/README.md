# Somnio CLI

CLI tool that installs AI agent skills from the technology-tools repository into Claude Code, Cursor, and Antigravity.

## Installation

```bash
dart pub global activate --source git https://github.com/somnio-software/technology-tools --git-path cli
```

## Quick Start

```bash
# Auto-detect agents and install all skills
somnio init
```

This detects which agents (Claude Code, Cursor, Antigravity) are available and installs skills to each.

## Commands

### `somnio init`

Auto-detect agents, select targets, and install skills.

```bash
somnio init          # Interactive agent selection
somnio init --force  # Overwrite existing skills
```

| Flag | Short | Description |
|------|-------|-------------|
| `--force` | `-f` | Overwrite existing skills without prompting |

### `somnio claude`

Install skills into Claude Code as slash commands in `~/.claude/skills/`.

```bash
somnio claude              # Install globally
somnio claude --project    # Install to .claude/skills/ in current directory
somnio claude --force      # Overwrite existing
```

| Flag | Short | Description |
|------|-------|-------------|
| `--project` | | Install to project-level `.claude/skills/` instead of global |
| `--force` | `-f` | Overwrite existing skills without prompting |

### `somnio cursor`

Install commands into Cursor as `.md` files in `.cursor/commands/`.

```bash
somnio cursor
somnio cursor --force
```

| Flag | Short | Description |
|------|-------|-------------|
| `--project` | | Install to project-level directory (default: true) |
| `--force` | `-f` | Overwrite existing commands without prompting |

### `somnio antigravity`

Install workflows into Antigravity in `.agent/workflows/` and `.agent/somnio_rules/`.

```bash
somnio antigravity
somnio antigravity --force
```

| Flag | Short | Description |
|------|-------|-------------|
| `--project` | | Install to project-level directory (default: true) |
| `--force` | `-f` | Overwrite existing workflows without prompting |

Skills without Antigravity workflow support are skipped with a message.

### `somnio update`

Update the CLI to the latest version and reinstall all skills to previously configured agents.

```bash
somnio update
```

Runs `dart pub global activate` under the hood, then force-reinstalls skills to any agents that were previously set up.

### `somnio status`

Show what skills are installed and where.

```bash
somnio status
```

Displays a table of all three agents with their installation status and installed skill names.

### `somnio uninstall`

Remove all Somnio skills, commands, and workflows from all agents.

```bash
somnio uninstall
```

### `somnio run`

Execute a health audit step-by-step from the target project's terminal. Each rule runs in a fresh AI context (Claude or Gemini), saving findings as artifacts and generating a final report.

**Must be run from the project root** (e.g., inside a Flutter or NestJS repo).

```bash
# From a Flutter project root
somnio run fh

# From a NestJS project root
somnio run nh

# Force a specific AI CLI
somnio run fh --agent gemini

# Skip project type validation
somnio run fh --skip-validation

# Skip CLI pre-flight (send all steps to AI)
somnio run fh --no-preflight
```

| Flag | Short | Description |
|------|-------|-------------|
| `--agent` | `-a` | AI CLI to use: `claude` or `gemini` (auto-detected if omitted, prefers Claude) |
| `--skip-validation` | | Skip project type check (e.g., pubspec.yaml for Flutter) |
| `--no-preflight` | | Skip CLI pre-flight and send all steps to AI |

**Available codes** are derived from the skill registry — any health audit bundle registered via `somnio add` is automatically available:

| Code | Audit | Technology |
|------|-------|------------|
| `fh` | Flutter Project Health Audit | Flutter |
| `nh` | NestJS Project Health Audit | NestJS |

**How it works:**

1. **Validates** the current directory is the correct project type
2. **Pre-flight** — the CLI handles tool installation, version alignment, version validation, and test coverage directly (no AI needed). These steps complete in seconds instead of minutes
3. **AI steps** — analysis rules (architecture, security, code quality, etc.) each run in a fresh AI context
4. **Report** — the final step reads all artifacts and generates a Google Docs-ready audit report

Pre-flight artifacts and the previous report are automatically cleaned before each run. Use `--no-preflight` to send all steps to AI (useful for debugging or when running as a skill in an IDE).

**Token usage tracking:**

Each AI step displays real-time token consumption and cost when it completes:

```
✓ Step  5/13: flutter_architecture_analyzer  IT: 38.2K  OT: 4.1K  Time: 3m 12s  Cost: $0.28
✓ Step  6/13: flutter_state_management       IT: 35.7K  OT: 3.8K  Time: 2m 45s  Cost: $0.25
```

- **IT** — Input tokens (includes cache)
- **OT** — Output tokens
- **Cost** — USD cost (Claude only; Gemini does not report cost)

A summary is printed at the end of the run:

```
────────────────────────────────────────────────────
Total tokens  ─  Input: 317.3K  Output: 35.1K
Total cost    ─  $2.31
Total time    ─  25m 55s  (AI: 25m 55s | Pre-flight: ~12s)
────────────────────────────────────────────────────
```

Output is saved to `./reports/`:
- `./reports/.artifacts/` — per-step findings
- `./reports/{tech}_audit.txt` — final report

### `somnio quote`

Display the Somnio banner with a random team quote.

```bash
somnio quote   # or: somnio q
```

### `somnio add`

Add a new technology skill bundle to the repository.

```bash
somnio add react          # Scaffold new react-plans/ directory (wizard mode)
somnio add django          # Same, for django
somnio add flutter --force # Auto-detect existing flutter-plans/ bundles
```

| Flag | Short | Description |
|------|-------|-------------|
| `--force` | `-f` | Skip confirmation prompts |

**Two modes:**

- **Wizard mode** — When `{tech}-plans/` doesn't exist, scaffolds a new skill bundle directory with README, plan, sample YAML rule, report template, and workflow.
- **Auto-detect mode** — When `{tech}-plans/` already exists, scans for `{tech}_project_health_audit/` and `{tech}_best_practices_check/` subdirectories, validates them, and registers valid bundles in the skill registry.

The technology name must be lowercase alphanumeric, start with a letter, and be at least 2 characters.

## Installed Skills

| Short Name | ID | Description | Technology |
|------------|----|-------------|------------|
| `somnio-fh` | `flutter_health` | Flutter Project Health Audit | Flutter |
| `somnio-fp` | `flutter_plan` | Flutter Best Practices Check | Flutter |
| `somnio-nh` | `nestjs_health` | NestJS Project Health Audit | NestJS |
| `somnio-np` | `nestjs_plan` | NestJS Best Practices Check | NestJS |

After installation, invoke skills as slash commands:

- **Claude Code**: `/somnio-fh`, `/somnio-fp`, `/somnio-nh`, `/somnio-np`
- **Cursor**: Available as commands in the command palette
- **Antigravity**: Available as workflows

## Adding New Technologies

1. Create a `{tech}-plans/` directory at the repository root with your plans and YAML rules.
2. Run `somnio add {tech}` — the CLI will detect your bundles and register them.
3. Run `somnio init` to install the new skills.

See `somnio add --help` for the full wizard flow if starting from scratch.

## Development

```bash
# Clone the repo
git clone https://github.com/somnio-software/technology-tools
cd technology-tools/cli

# Get dependencies
dart pub get

# Run locally
dart run bin/somnio.dart --help

# Run tests
dart test

# Install your local version globally
dart pub global activate --source path .
```

The CLI entry point is `bin/somnio.dart`. Commands live in `lib/src/commands/`, installers in `lib/src/installers/`, and transformers in `lib/src/transformers/`.
