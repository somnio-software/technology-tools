# Somnio CLI - Complete Technical Plan

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Problem Statement](#2-problem-statement)
3. [Architecture Overview](#3-architecture-overview)
4. [Project Structure](#4-project-structure)
5. [Dependencies](#5-dependencies)
6. [Skill Registry](#6-skill-registry)
7. [CLI Commands](#7-cli-commands)
8. [Content Transformation Per Agent](#8-content-transformation-per-agent)
9. [Agent Detection](#9-agent-detection)
10. [Package Root Resolution](#10-package-root-resolution)
11. [Generated Output Examples](#11-generated-output-examples)
12. [Implementation Phases](#12-implementation-phases)
13. [Edge Cases & Platform Support](#13-edge-cases--platform-support)
14. [Verification Plan](#14-verification-plan)
15. [Future Extensibility](#15-future-extensibility)
16. [File Inventory](#16-file-inventory)

---

## 1. Executive Summary

**Somnio** is a Dart CLI tool that reads existing Flutter audit plans and rules from the `flutter-plans/` directory and installs them as native slash commands into AI coding agents (Claude Code, Cursor, Antigravity).

**Installation**: `dart pub global activate -sgit https://github.com/<org>/technology-tools --path cli`

**Core commands**:
- `somnio init` - Auto-detect agents, select targets, install skills
- `somnio update` - Update CLI + reinstall all skills with latest content
- `somnio claude` / `somnio cursor` / `somnio antigravity` - Install to specific agent
- `somnio status` - Show what's installed where
- `somnio uninstall` - Remove all Somnio-installed skills, commands, and workflows

**Install scope**: Global by default, per-project with `--project` flag.

**Slash commands installed** (2 total):
| Command | Description |
|---------|-------------|
| `/somnio-fh` | Flutter Project Health Audit (macro-level, 15 rules) |
| `/somnio-fp` | Flutter Best Practices Check (micro-level, 5 rules) |

> **Naming convention**: Short, consistent names across all agents. Claude Code skills, Cursor commands, and Antigravity workflows all use the same `/somnio-fh` and `/somnio-fp` naming.

---

## 2. Problem Statement

The `technology-tools` repository contains powerful Flutter auditing tools structured as:
- **Plan files** (`.plan.md`) - orchestration documents defining sequential execution steps
- **Cursor rules** (`.yaml`) - individual analysis prompts with file matching patterns
- **Workflow files** (`.agent/workflows/*.md`) - Antigravity-specific execution workflows
- **Templates** (`.txt`) - report output templates

Currently, using these tools requires manually copying files into the right agent-specific directories. This CLI automates that process by:
1. Reading from the existing `flutter-plans/` directory (single source of truth)
2. Transforming content into each agent's native format
3. Writing to the correct locations for each agent
4. Providing simple update and management commands

---

## 3. Architecture Overview

```
                   +-----------------+
                   |   somnio init   |
                   +--------+--------+
                            |
                   +--------v--------+
                   | Agent Detector  |
                   | (claude/cursor/ |
                   |  antigravity)   |
                   +--------+--------+
                            |
              +-------------+-------------+
              |             |             |
     +--------v---+  +------v-----+  +----v----------+
     | Claude     |  | Cursor     |  | Antigravity   |
     | Installer  |  | Installer  |  | Installer     |
     +--------+---+  +------+-----+  +----+----------+
              |             |             |
     +--------v---+  +------v-----+  +----v----------+
     | Claude     |  | Cursor     |  | Antigravity   |
     | Transformer|  | Transformer|  | Transformer   |
     +--------+---+  +------+-----+  +----+----------+
              |             |             |
     +--------v---+  +------v-----+  +----v----------+
     | Content    |  | Content    |  | Content       |
     | Loader     |  | Loader     |  | Loader        |
     +--------+---+  +------+-----+  +----+----------+
              |             |             |
              +-------------+-------------+
                            |
                   +--------v--------+
                   |  flutter-plans/  |
                   |  (read-only     |
                   |   source of     |
                   |   truth)        |
                   +-----------------+
```

**Data flow**:
1. CLI resolves the repo root at runtime (the package is installed from git)
2. Content Loader reads YAML rules and plan.md files from `flutter-plans/`
3. Transformer converts content to agent-specific format
4. Installer writes files to the correct agent location

---

## 4. Project Structure

The CLI lives in `cli/` subdirectory to coexist with existing content:

```
technology-tools/                        # Existing repo (unchanged)
  cli/                                   # NEW - Dart CLI package
    pubspec.yaml                         # Package definition
    analysis_options.yaml                # Lint rules
    bin/
      somnio.dart                        # Entry point (main)
    lib/
      somnio.dart                        # Library barrel export
      src/
        cli_runner.dart                  # CommandRunner configuration
        commands/
          init_command.dart              # somnio init
          update_command.dart            # somnio update
          claude_command.dart            # somnio claude [--project] [--force]
          cursor_command.dart            # somnio cursor [--project] [--force]
          antigravity_command.dart       # somnio antigravity [--project] [--force]
          status_command.dart            # somnio status
          uninstall_command.dart         # somnio uninstall
        installers/
          installer.dart                 # Abstract base class
          claude_installer.dart          # Write to ~/.claude/skills/
          cursor_installer.dart          # Write to .cursor/rules/
          antigravity_installer.dart     # Write to .agent/workflows/
        content/
          content_loader.dart            # Read & parse YAML/MD from flutter-plans/
          skill_registry.dart            # Registry of available skill bundles
          skill_bundle.dart              # Data model for a skill bundle
        transformers/
          claude_transformer.dart        # plan.md + YAML -> SKILL.md + references/
          cursor_transformer.dart        # plan + YAML -> command .md
          antigravity_transformer.dart   # Workflow copy + path rewrite
        utils/
          agent_detector.dart            # Detect installed AI agents
          package_resolver.dart          # Find repo root at runtime
          platform_utils.dart            # Cross-platform paths & home directory
    test/
      src/
        commands/
          init_command_test.dart
          claude_command_test.dart
          cursor_command_test.dart
          antigravity_command_test.dart
        content/
          content_loader_test.dart
          skill_registry_test.dart
        transformers/
          claude_transformer_test.dart
          cursor_transformer_test.dart
          antigravity_transformer_test.dart
        utils/
          agent_detector_test.dart
          package_resolver_test.dart
  flutter-plans/                         # UNTOUCHED - read-only source of truth
  nestjs-plans/                          # UNTOUCHED
  README.md                              # UNTOUCHED
```

**Why `cli/` subdirectory?**
- Keeps the Dart package separate from the content files
- `dart pub global activate -sgit <url> --path cli` points to the package subdirectory
- The CLI navigates up one level from its package root to access `flutter-plans/`
- Clean separation: content creators edit `flutter-plans/`, CLI developers edit `cli/`

---

## 5. Dependencies

### `cli/pubspec.yaml`

```yaml
name: somnio
description: >-
  CLI tool for installing Somnio AI agent skills.
  Reads Flutter audit plans and rules from technology-tools and installs
  them as native slash commands into Claude Code, Cursor, and Antigravity.
version: 1.0.0
publish_to: none

environment:
  sdk: ^3.0.0

executables:
  somnio: somnio

dependencies:
  args: ^2.4.0
  yaml: ^3.1.0
  mason_logger: ^0.3.0
  path: ^1.9.0
  pub_updater: ^0.4.0

dev_dependencies:
  test: ^1.25.0
  mocktail: ^1.0.0
```

### Dependency Rationale

| Package | Version | Purpose |
|---------|---------|---------|
| `args` | ^2.4.0 | `CommandRunner` + `Command` classes for subcommand architecture (`somnio init`, `somnio claude`, etc.) |
| `yaml` | ^3.1.0 | Parse the cursor_rules YAML files to extract `name`, `description`, `match`, `prompt` fields |
| `mason_logger` | ^0.3.0 | Colored terminal output, progress spinners, multi-select prompts (for `init` agent selection), confirmation dialogs. Used by VeryGoodCLI and FlutterFire CLI |
| `path` | ^1.9.0 | Cross-platform path joining (`/` on macOS/Linux, `\` on Windows) |
| `pub_updater` | ^0.4.0 | Check if newer CLI version is available, auto-update support for `somnio update` |
| `test` | ^1.25.0 | Unit testing framework |
| `mocktail` | ^1.0.0 | Mocking for tests (mock file system, process calls) |

---

## 6. Skill Registry

The registry maps skill identifiers to their source files in `flutter-plans/`. It's defined in code as a static configuration.

### Data Model

```dart
// skill_bundle.dart
class SkillBundle {
  final String id;                  // e.g., 'flutter_health'
  final String name;                // e.g., 'somnio-fh'
  final String displayName;         // e.g., 'Flutter Project Health Audit'
  final String description;         // Brief description for SKILL.md frontmatter
  final String planRelativePath;    // Relative to repo root
  final String rulesDirectory;      // Relative path to cursor_rules/ directory
  final String? workflowPath;       // .agent workflow file path
  final String? templatePath;       // Report template file path
}
```

### Registry Content

```dart
// skill_registry.dart
final skills = [
  SkillBundle(
    id: 'flutter_health',
    name: 'somnio-fh',
    displayName: 'Flutter Project Health Audit',
    description: 'Execute a comprehensive Flutter Project Health Audit. '
        'Analyzes tech stack, architecture, state management, testing, '
        'code quality, security, CI/CD, and documentation. Produces a '
        'Google Docs-ready report with section scores and weighted '
        'overall score.',
    planRelativePath:
        'flutter-plans/flutter_project_health_audit/plan/flutter-health.plan.md',
    rulesDirectory:
        'flutter-plans/flutter_project_health_audit/cursor_rules',
    workflowPath:
        'flutter-plans/flutter_project_health_audit/.agent/workflows/flutter_health_audit.md',
    templatePath:
        'flutter-plans/flutter_project_health_audit/cursor_rules/templates/flutter_report_template.txt',
  ),
  SkillBundle(
    id: 'flutter_plan',
    name: 'somnio-fp',
    displayName: 'Flutter Best Practices Check',
    description: 'Execute a micro-level Flutter code quality audit. '
        'Validates code against live GitHub standards for testing, '
        'architecture, and code implementation. Produces a detailed '
        'violations report with prioritized action plan.',
    planRelativePath:
        'flutter-plans/flutter_best_practices_check/plan/best_practices.plan.md',
    rulesDirectory:
        'flutter-plans/flutter_best_practices_check/cursor_rules',
    workflowPath:
        'flutter-plans/flutter_best_practices_check/.agent/workflows/flutter_best_practices.md',
    templatePath:
        'flutter-plans/flutter_best_practices_check/cursor_rules/templates/best_practices_report_template.txt',
  ),
];
```

### Source File Inventory

**Flutter Health Audit** (15 YAML rules):
1. `flutter_tool_installer.yaml` - Install Node.js, FVM, Gemini CLI
2. `flutter_version_alignment.yaml` - FVM global configuration (MANDATORY)
3. `flutter_version_validator.yaml` - Verify FVM setup
4. `flutter_test_coverage.yaml` - Generate coverage reports
5. `flutter_repository_inventory.yaml` - Detect repo structure
6. `flutter_config_analysis.yaml` - Analyze config files
7. `flutter_cicd_analysis.yaml` - Analyze GitHub Actions
8. `flutter_testing_analysis.yaml` - Classify test files
9. `flutter_code_quality.yaml` - Analyze linter config
10. `flutter_security_analysis.yaml` - Identify sensitive files
11. `flutter_gemini_security_audit.yaml` - AI security analysis
12. `flutter_documentation_analysis.yaml` - Review docs
13. `flutter_report_generator.yaml` - Generate final report
14. `flutter_report_format_enforcer.yaml` - Enforce format
15. `flutter_project_health_audit.yaml` - Main scoring logic

**Flutter Best Practices** (5 YAML rules):
1. `testing_quality.yaml` - Test quality analysis
2. `architecture_compliance.yaml` - Architecture validation
3. `code_standards.yaml` - Code standards check
4. `best_practices_format_enforcer.yaml` - Report format
5. `best_practices_generator.yaml` - Report generation

---

## 7. CLI Commands

### 7.1 `somnio init`

**Purpose**: First-time setup. Detect installed agents, let user choose, install skills.

**Flow**:
```
$ somnio init

  ____                        _
 / ___|  ___  _ __ ___  _ __ (_) ___
 \___ \ / _ \| '_ ` _ \| '_ \| |/ _ \
  ___) | (_) | | | | | | | | | | (_) |
 |____/ \___/|_| |_| |_|_| |_|_|\___/  v1.0.0

Detecting installed AI agents...

  [x] Claude Code (claude found at /usr/local/bin/claude)
  [x] Cursor (found at /Applications/Cursor.app)
  [ ] Antigravity (not found)

? Which agents would you like to install skills into?
  > [x] Claude Code
  > [x] Cursor
  > [ ] Antigravity (not installed)

Installing skills...

  Claude Code:
    [x] /somnio-fh -> ~/.claude/skills/somnio-fh/
    [x] /somnio-fp -> ~/.claude/skills/somnio-fp/

  Cursor:
    [x] /somnio-fh -> .cursor/commands/somnio-fh.md
    [x] /somnio-fp -> .cursor/commands/somnio-fp.md

Done! Installed 4 commands.

Usage:
  Claude Code: /somnio-fh, /somnio-fp
  Cursor:      /somnio-fh, /somnio-fp
```

**Flags**:
- `--force` - Overwrite existing skills without prompting

**Logic**:
1. Print banner with version
2. Run agent detection (see Section 9)
3. If 0 agents found: print error with install links, exit
4. If 1 agent found: auto-select, confirm with user
5. If 2+ agents found: show multi-select prompt
6. For each selected agent: run corresponding installer
7. Print summary with usage hints

### 7.2 `somnio update`

**Purpose**: Update CLI to latest version and reinstall all skills.

**Flow**:
```
$ somnio update

Updating somnio CLI...
  Running: dart pub global activate -sgit <repo-url> --path cli
  Updated to v1.1.0

Reinstalling skills...
  [x] Claude Code: 4 skills updated
  [x] Cursor: 22 rules updated

All up to date!
```

**Logic**:
1. Run `dart pub global activate -sgit <repo-url> --path cli` to pull latest
2. Detect previously installed agents by scanning known locations:
   - Claude: check `~/.claude/skills/somnio-*`
   - Cursor: check `<cwd>/.cursor/rules/` for somnio files
   - Antigravity: check `<cwd>/.agent/workflows/somnio_*`
3. Re-run installers for each detected agent
4. Print update summary

### 7.3 `somnio claude [--project] [--force]`

**Purpose**: Install/reinstall skills into Claude Code only.

**Flags**:
- `--project` - Install to `.claude/skills/` in current directory instead of `~/.claude/skills/`
- `--force` - Overwrite without prompting

**Logic**:
1. Resolve repo root (Section 10)
2. Load all skill bundles from registry
3. For each bundle:
   a. Run Claude transformer (plan.md + YAML -> SKILL.md + references/)
   b. Create alias skill for short name
4. Write to target directory
5. Print installed commands

### 7.4 `somnio cursor [--project] [--force]`

**Purpose**: Install/reinstall commands into Cursor only.

**Flags**:
- `--project` - Install to `<cwd>/.cursor/commands/` (this is the default)
- `--force` - Overwrite without prompting

**Logic**:
1. Resolve repo root
2. Load all skill bundles
3. For each bundle:
   a. Run Cursor transformer (plan + YAML -> single command .md)
4. Write to `.cursor/commands/`
5. Print summary

### 7.5 `somnio antigravity [--project] [--force]`

**Purpose**: Install/reinstall workflows into Antigravity only.

**Flags**:
- `--project` - Install to `<cwd>/.agent/` (this is the default)
- `--force` - Overwrite without prompting

**Logic**:
1. Resolve repo root
2. Load all skill bundles
3. For each bundle:
   a. Run Antigravity transformer (copy + path rewrite)
4. Write to `.agent/workflows/` and `.agent/somnio_rules/`
5. Print summary

### 7.6 `somnio status`

**Purpose**: Show what's currently installed and where.

**Output**:
```
$ somnio status

Somnio Skills Status:

Agent         | Status    | Location                        | Skills
------------- | --------- | ------------------------------- | ------
Claude Code   | Installed | ~/.claude/skills/               | somnio-fh, somnio-fp
Cursor        | Installed | .cursor/commands/               | somnio-fh, somnio-fp
Antigravity   | Not found | -                               | -
```

### 7.7 `somnio uninstall`

**Purpose**: Remove all Somnio-installed skills, commands, and workflows from all agents.

**Output**:
```
$ somnio uninstall

  Removed Claude skill: somnio-fh
  Removed Claude skill: somnio-fp
  Removed Cursor command: somnio-fh.md
  Removed Cursor command: somnio-fp.md
  Removed Antigravity workflow: somnio_flutter_best_practices.md
  Removed Antigravity workflow: somnio_flutter_health_audit.md
  Removed Antigravity rules: .agent/somnio_rules/

Uninstall complete.
```

**Logic**:
1. Scan `~/.claude/skills/` for directories starting with `somnio-`, delete each
2. Scan `<cwd>/.cursor/commands/` for `.md` files starting with `somnio-`, delete each
3. Scan `<cwd>/.agent/workflows/` for files starting with `somnio_`, delete each
4. Delete `<cwd>/.agent/somnio_rules/` directory recursively if it exists
5. Print summary or "Nothing to uninstall" if nothing was found

**Notes**:
- Does not require confirmation (no `--force` flag) - the operation is safe since it only removes Somnio-prefixed files
- Does not remove the parent directories (`.claude/skills/`, `.cursor/commands/`, `.agent/`) even if empty
- Claude skills are removed globally; Cursor and Antigravity are removed from the current working directory

---

## 8. Content Transformation Per Agent

### 8.1 Claude Code Transformer

**Input**: Plan.md + YAML rule files + templates
**Output**: Skill directory with SKILL.md + references/

#### Generated Directory Structure

```
~/.claude/skills/somnio-fh/
  SKILL.md                                # Orchestration plan
  rules/
    flutter_tool_installer.md             # Extracted from YAML
    flutter_version_alignment.md
    flutter_version_validator.md
    flutter_test_coverage.md
    flutter_repository_inventory.md
    flutter_config_analysis.md
    flutter_cicd_analysis.md
    flutter_testing_analysis.md
    flutter_code_quality.md
    flutter_security_analysis.md
    flutter_gemini_security_audit.md
    flutter_documentation_analysis.md
    flutter_report_generator.md
    flutter_report_format_enforcer.md
    flutter_project_health_audit.md
  templates/
    flutter_report_template.txt           # Copied as-is
```

#### SKILL.md Generation Steps

1. **Parse plan.md**: Read the entire file, strip the HTML comment UUID line (line 1)

2. **Generate YAML frontmatter**:
   ```yaml
   ---
   name: somnio-fh
   description: >-
     Execute a comprehensive Flutter Project Health Audit. Analyzes tech stack,
     architecture, state management, testing, code quality, security, CI/CD,
     and documentation. Produces a Google Docs-ready report with scores.
   allowed-tools: Read, Edit, Write, Grep, Glob, Bash, WebFetch
   user-invocable: true
   ---
   ```

3. **Transform `@rule_name` references**: Replace Cursor-specific `@rule_name` syntax with Claude-compatible file references:
   - Pattern: `` `@flutter_version_alignment` ``
   - Becomes: "Read and follow the instructions in `rules/flutter_version_alignment.md`"

4. **Transform cross-skill references**: Replace plan-to-plan references:
   - Pattern: `@flutter_best_practices_check/plan/best_practices.plan.md`
   - Becomes: "Execute `/somnio-fp`"

5. **Keep everything else**: All plan content (role, expertise, steps, rules, critical requirements) remains intact

#### Rule File Generation (YAML -> Markdown)

For each `*.yaml` file in `cursor_rules/`:

1. Parse YAML structure:
   ```yaml
   rules:
     - name: Flutter Tool Installer
       description: >
         Centralized installer for all required tools...
       match: "*"
       prompt: |
         You are an elite tool installation specialist...
   ```

2. Generate markdown file:
   ```markdown
   # Flutter Tool Installer

   > Centralized installer for all required tools...

   **File pattern**: `*`

   ---

   You are an elite tool installation specialist...
   (full prompt content preserved as-is)
   ```

### 8.2 Cursor Transformer

**Input**: Plan.md + YAML rule files
**Output**: `.md` command files for `.cursor/commands/`

Cursor commands (beta) are plain Markdown files stored in `.cursor/commands/`. Each skill becomes a single self-contained command file that embeds both the plan and all rule prompts.

#### Generated Files

```
.cursor/commands/
  somnio-fh.md                            # Health audit command (plan + 15 rules)
  somnio-fp.md                            # Best practices command (plan + 5 rules)
```

#### Command File Structure

Each command `.md` file contains:
1. The full plan content (orchestration steps)
2. A `---` separator
3. A `# Rule Reference` section with all rules embedded as `## Rule Name` subsections

This makes each command fully self-contained - the agent has both the execution plan and all rule prompts in a single file.

#### Triggering

Users type `/somnio-fh` or `/somnio-fp` in Cursor chat to trigger the command.

### 8.3 Antigravity Transformer

**Input**: Workflow .md files + YAML rules + plan files
**Output**: Workflow files + supporting rule files in `.agent/`

#### Generated Structure

```
.agent/
  workflows/
    somnio_flutter_health_audit.md         # Copied + paths rewritten
    somnio_flutter_best_practices.md       # Copied + paths rewritten
  somnio_rules/
    flutter_project_health_audit/
      cursor_rules/
        flutter_tool_installer.yaml        # All 15 YAML files copied
        flutter_version_alignment.yaml
        ... (all YAML files)
        templates/
          flutter_report_template.txt
      plan/
        flutter-health.plan.md
    flutter_best_practices_check/
      cursor_rules/
        testing_quality.yaml               # All 5 YAML files copied
        ... (all YAML files)
        templates/
          best_practices_report_template.txt
      plan/
        best_practices.plan.md
```

#### Path Rewriting

The source workflow files reference rules by relative paths:
```
Read `flutter_project_health_audit/cursor_rules/flutter_tool_installer.yaml` and execute...
```

After transformation, paths become:
```
Read `.agent/somnio_rules/flutter_project_health_audit/cursor_rules/flutter_tool_installer.yaml` and execute...
```

**Regex pattern for path rewrite**:
```dart
final pathPattern = RegExp(
  r'`(flutter_(?:project_health_audit|best_practices_check)/[^`]+)`',
);
content = content.replaceAllMapped(pathPattern, (match) {
  return '`.agent/somnio_rules/${match.group(1)}`';
});
```

---

## 9. Agent Detection

### Detection Strategy

```dart
enum AgentType { claude, cursor, antigravity }

class AgentDetector {
  Future<Map<AgentType, AgentInfo>> detect() async {
    return {
      AgentType.claude: await _detectClaude(),
      AgentType.cursor: await _detectCursor(),
      AgentType.antigravity: await _detectAntigravity(),
    };
  }
}

class AgentInfo {
  final bool installed;
  final String? path;    // Binary or app path
  final String? version; // If detectable
}
```

### Claude Code Detection

```dart
Future<AgentInfo> _detectClaude() async {
  // 1. Check PATH for 'claude' binary
  final path = await _whichBinary('claude');
  if (path != null) {
    return AgentInfo(installed: true, path: path);
  }

  // 2. Check common install locations
  final locations = [
    if (Platform.isMacOS) '/usr/local/bin/claude',
    if (Platform.isLinux) '/usr/local/bin/claude',
  ];
  for (final loc in locations) {
    if (File(loc).existsSync()) {
      return AgentInfo(installed: true, path: loc);
    }
  }

  // 3. Check if ~/.claude/ directory exists (installed but not in PATH)
  final homeDir = _getHomeDirectory();
  if (Directory(join(homeDir, '.claude')).existsSync()) {
    return AgentInfo(installed: true, path: '~/.claude');
  }

  return AgentInfo(installed: false);
}
```

### Cursor Detection

```dart
Future<AgentInfo> _detectCursor() async {
  // 1. Check PATH for 'cursor' binary
  final path = await _whichBinary('cursor');
  if (path != null) {
    return AgentInfo(installed: true, path: path);
  }

  // 2. Check application directories
  if (Platform.isMacOS) {
    if (Directory('/Applications/Cursor.app').existsSync()) {
      return AgentInfo(installed: true, path: '/Applications/Cursor.app');
    }
  }
  if (Platform.isLinux) {
    final linuxPaths = ['/usr/bin/cursor', '/usr/local/bin/cursor'];
    for (final p in linuxPaths) {
      if (File(p).existsSync()) return AgentInfo(installed: true, path: p);
    }
  }
  if (Platform.isWindows) {
    final appData = Platform.environment['APPDATA'];
    if (appData != null) {
      final cursorPath = join(appData, 'Cursor', 'Cursor.exe');
      if (File(cursorPath).existsSync()) {
        return AgentInfo(installed: true, path: cursorPath);
      }
    }
  }

  return AgentInfo(installed: false);
}
```

### Antigravity Detection

```dart
Future<AgentInfo> _detectAntigravity() async {
  // Check multiple possible binary names
  for (final cmd in ['agy', 'antigravity']) {
    final path = await _whichBinary(cmd);
    if (path != null) {
      return AgentInfo(installed: true, path: path);
    }
  }

  // Check global settings directory
  final homeDir = _getHomeDirectory();
  if (Directory(join(homeDir, '.gemini', 'antigravity')).existsSync()) {
    return AgentInfo(installed: true, path: '~/.gemini/antigravity');
  }

  return AgentInfo(installed: false);
}
```

### Helper: `which` / `where`

```dart
Future<String?> _whichBinary(String binary) async {
  try {
    final cmd = Platform.isWindows ? 'where' : 'which';
    final result = await Process.run(cmd, [binary]);
    if (result.exitCode == 0) {
      return (result.stdout as String).trim().split('\n').first;
    }
  } catch (_) {}
  return null;
}

String _getHomeDirectory() {
  if (Platform.isWindows) {
    return Platform.environment['USERPROFILE'] ?? '';
  }
  return Platform.environment['HOME'] ?? '';
}
```

---

## 10. Package Root Resolution

When installed via `dart pub global activate -sgit`, the repo is cached at `~/.pub-cache/git/technology-tools-<hash>/`. The CLI needs to find the repo root at runtime to access `flutter-plans/`.

### Resolution Strategy

```dart
// package_resolver.dart
import 'dart:isolate';

class PackageResolver {
  /// Resolves the technology-tools repo root directory.
  /// The CLI package lives at <repo-root>/cli/, so we go up one level.
  Future<String> resolveRepoRoot() async {
    // Strategy 1: Isolate.resolvePackageUri
    try {
      final packageUri = Uri.parse('package:somnio/somnio.dart');
      final resolved = await Isolate.resolvePackageUri(packageUri);
      if (resolved != null) {
        // resolved = <repo-root>/cli/lib/somnio.dart
        // Go up: lib/ -> cli/ -> technology-tools/
        final repoRoot = resolved.resolve('../../').toFilePath();
        if (_validateRepoRoot(repoRoot)) return repoRoot;
      }
    } catch (_) {}

    // Strategy 2: SOMNIO_ROOT environment variable
    final envRoot = Platform.environment['SOMNIO_ROOT'];
    if (envRoot != null && _validateRepoRoot(envRoot)) return envRoot;

    // Strategy 3: Relative to executable
    final execDir = File(Platform.resolvedExecutable).parent.path;
    // Navigate up from the executable to find the repo
    for (var dir = execDir; dir != dirname(dir); dir = dirname(dir)) {
      if (_validateRepoRoot(dir)) return dir;
    }

    throw StateError(
      'Cannot find technology-tools repo root.\n'
      'Set the SOMNIO_ROOT environment variable to the repo path, or\n'
      'reinstall with: dart pub global activate -sgit <repo-url> --path cli',
    );
  }

  bool _validateRepoRoot(String path) {
    return Directory(join(path, 'flutter-plans')).existsSync();
  }
}
```

---

## 11. Generated Output Examples

### 11.1 Claude Code SKILL.md (Flutter Health)

```yaml
---
name: somnio-fh
description: >-
  Execute a comprehensive Flutter Project Health Audit. Analyzes tech stack,
  architecture, state management, testing, code quality, security, CI/CD,
  and documentation. Produces a Google Docs-ready report with section scores
  and weighted overall score.
allowed-tools: Read, Edit, Write, Grep, Glob, Bash, WebFetch
user-invocable: true
---

# Flutter Project Health Audit - Modular Execution Plan

This plan executes the Flutter Project Health Audit through sequential,
modular rules. Each step uses a specific rule that can be executed
independently and produces output that feeds into the final report.

## Agent Role & Context

**Role**: Flutter Project Health Auditor

## Your Core Expertise

You are a master at:
- **Comprehensive Project Auditing**: Evaluating all aspects of Flutter
  project health (tech stack, architecture, testing, security, CI/CD,
  documentation)
- **Evidence-Based Analysis**: Analyzing repository evidence objectively
  without inventing data or making assumptions
- **Modular Rule Execution**: Coordinating sequential execution of 13
  specialized analysis rules
...

## REQUIREMENT - FLUTTER VERSION ALIGNMENT

**MANDATORY STEP 0**: Before executing any Flutter project analysis,
ALWAYS verify and align the global Flutter version with the project's
required version using FVM.

**Rule to Execute**: Read and follow the instructions in `rules/flutter_version_alignment.md`

...

## Step 10. Optional Best Practices Check Prompt

**CRITICAL**: After completing Step 9, you MUST ask the user if they
want to execute the Best Practices Check plan. **NEVER execute it
automatically**.

**Action**: If user confirms, execute `/somnio-fp`
```

### 11.2 Claude Code Rule Reference File

```markdown
# Flutter Tool Installer

> Centralized installer for all required tools (Node.js, FVM, Gemini CLI,
> Security Extension) for the Flutter Project Health Audit.

**File pattern**: `*`

---

You are an elite tool installation specialist with deep expertise in
development environment setup, package management systems, and
toolchain configuration for Flutter projects...

## Your Core Expertise

You are a master at:
- **Tool Detection**: Identifying missing tools and dependencies...
...

(full prompt content from YAML, preserved as-is)
```

### 11.3 Cursor Command File (somnio-fh.md)

```markdown
# Flutter Project Health Audit - Modular Execution Plan

(full plan content with orchestration steps...)

---

# Rule Reference

## Flutter Tool Installer

> Centralized installer for all required tools...

**File pattern**: `*`

You are an elite tool installation specialist with deep expertise in
development environment setup, package management systems, and
toolchain configuration for Flutter projects...

## Flutter Version Alignment

(next rule...)
```

### 11.4 Antigravity Workflow (Rewritten)

```markdown
---
description: Automated Flutter Project Health Audit
---

# Flutter Project Health Audit Workflow

// turbo-all

1. **Environment Setup**
   Read `.agent/somnio_rules/flutter_project_health_audit/cursor_rules/flutter_tool_installer.yaml` and execute the instructions to install necessary tools.

2. **Version Alignment**
   Read `.agent/somnio_rules/flutter_project_health_audit/cursor_rules/flutter_version_alignment.yaml` and execute the instructions to align Flutter versions.

...
```

---

## 12. Implementation Phases

### Phase 1: Scaffolding (Priority: CRITICAL)
**Files to create**:
- `cli/pubspec.yaml`
- `cli/analysis_options.yaml`
- `cli/bin/somnio.dart`
- `cli/lib/somnio.dart`
- `cli/lib/src/cli_runner.dart`
- Stub files for all 6 commands
- `cli/lib/src/utils/package_resolver.dart`
- `cli/lib/src/utils/agent_detector.dart`
- `cli/lib/src/utils/platform_utils.dart`

**Deliverable**: `somnio --help` works and shows all subcommands.

### Phase 2: Content Loading (Priority: HIGH)
**Files to create**:
- `cli/lib/src/content/skill_bundle.dart`
- `cli/lib/src/content/skill_registry.dart`
- `cli/lib/src/content/content_loader.dart`

**Deliverable**: CLI can parse all 20 YAML files and 2 plan.md files.

### Phase 3: Claude Code Installer (Priority: HIGH)
**Files to create**:
- `cli/lib/src/transformers/claude_transformer.dart`
- `cli/lib/src/installers/installer.dart`
- `cli/lib/src/installers/claude_installer.dart`

**Deliverable**: `somnio claude` creates working skills at `~/.claude/skills/`. `/somnio-flutter-health` and `/somnio-fh` work in Claude Code.

### Phase 4: Cursor Installer (Priority: HIGH)
**Files to create**:
- `cli/lib/src/transformers/cursor_transformer.dart`
- `cli/lib/src/installers/cursor_installer.dart`

**Deliverable**: `somnio cursor` creates `.mdc` files in `.cursor/rules/`.

### Phase 5: Antigravity Installer (Priority: MEDIUM)
**Files to create**:
- `cli/lib/src/transformers/antigravity_transformer.dart`
- `cli/lib/src/installers/antigravity_installer.dart`

**Deliverable**: `somnio antigravity` creates workflow files in `.agent/`.

### Phase 6: Init, Update, Status & Uninstall (Priority: HIGH)
**Wire up**:
- `somnio init` - orchestration with multi-select
- `somnio update` - re-activate + reinstall
- `somnio status` - scan and report
- `somnio uninstall` - remove all Somnio files from all agents

**Deliverable**: Full CLI workflow works end-to-end.

### Phase 7: Polish (Priority: MEDIUM)
- Colored output with `mason_logger`
- Progress spinners during installation
- Error messages with actionable hints
- `--force`, `--project` flags
- `.gitignore` for Dart build artifacts
- Unit tests for transformers and loaders

---

## 13. Edge Cases & Platform Support

### No Dart SDK
The CLI requires Dart >= 3.0 (included with Flutter SDK). Error message:
```
Error: Dart SDK not found.
Install Dart SDK (https://dart.dev/get-dart) or Flutter SDK (https://flutter.dev/docs/get-started/install).
```

### Package Root Not Found
If `Isolate.resolvePackageUri` fails and `SOMNIO_ROOT` is not set:
```
Error: Cannot find technology-tools repository root.
The flutter-plans/ directory was not found at the expected location.

Solutions:
  1. Set SOMNIO_ROOT environment variable:
     export SOMNIO_ROOT=/path/to/technology-tools

  2. Reinstall the CLI:
     dart pub global activate -sgit <repo-url> --path cli
```

### Existing Skills Conflict
When target files already exist:
- Default: prompt "Skills already exist at X. Overwrite? (y/n)"
- With `--force`: overwrite silently
- The overwrite replaces the entire skill directory (clean install)

### Windows Support
- Use `path` package for all file operations (handles `\` vs `/`)
- Use `where` instead of `which` for binary detection
- Use `USERPROFILE` instead of `HOME` for home directory
- Claude skills: `%USERPROFILE%\.claude\skills\`
- Write files with `\n` line endings (all formats are Markdown)

### Cursor Global Install Limitations
Cursor's global rules are configured through the UI (Settings > Rules for AI) or by editing `~/Library/Application Support/Cursor/User/settings.json`. The CLI warns:
```
Note: Cursor global rules are limited. For full functionality,
use project-level install: somnio cursor --project
```

### Agent Updated After Init
User installs a new agent after running `somnio init`:
```
$ somnio claude    # Install to Claude Code only
$ somnio cursor    # Install to Cursor only
```

### Content Changes in flutter-plans/
When flutter-plans/ content is updated (new rules, modified plans):
1. Developer pushes changes to the repo
2. Users run `somnio update` to pull latest + reinstall
3. All agent-specific files are regenerated from the updated source

---

## 14. Verification Plan

### Manual Testing Checklist

1. **Build & Install**
   ```bash
   cd cli
   dart pub get
   dart pub global activate --source path .
   somnio --help
   ```
   Expected: Help text shows all 6 subcommands.

2. **Agent Detection**
   ```bash
   somnio init
   ```
   Expected: Correctly detects Claude Code, Cursor, Antigravity.

3. **Claude Code Installation**
   ```bash
   somnio claude
   ls ~/.claude/skills/somnio-*
   ```
   Expected: 4 skill directories created (flutter-health, fh, flutter-plan, fp).

4. **Claude Code Skill Test**
   Open Claude Code in a Flutter project, type `/somnio-flutter-health`.
   Expected: Skill loads and starts the health audit.

5. **Claude Code Alias Test**
   Type `/somnio-fh` in Claude Code.
   Expected: Redirects to `/somnio-flutter-health`.

6. **Cursor Installation**
   ```bash
   cd /path/to/flutter/project
   somnio cursor --project
   ls .cursor/rules/*.mdc
   ```
   Expected: 22 .mdc files created with correct frontmatter.

7. **Antigravity Installation**
   ```bash
   cd /path/to/flutter/project
   somnio antigravity
   ls .agent/workflows/somnio_*
   ls .agent/somnio_rules/
   ```
   Expected: Workflow files + rule directories created.

8. **Update**
   ```bash
   somnio update
   ```
   Expected: CLI re-activates from git, skills reinstalled.

9. **Status**
   ```bash
   somnio status
   ```
   Expected: Table showing installed agents and skill counts.

10. **Force Overwrite**
    ```bash
    somnio claude --force
    ```
    Expected: Overwrites without prompting.

11. **Uninstall**
    ```bash
    somnio claude --force && somnio cursor --force && somnio antigravity --force
    somnio uninstall
    somnio status
    ```
    Expected: All Somnio files removed. Status shows "Not found" for all agents.

12. **Uninstall (nothing installed)**
    ```bash
    somnio uninstall
    ```
    Expected: Prints "Nothing to uninstall."

### Automated Tests

- `content_loader_test.dart` - Verify YAML parsing for all 20 rule files
- `claude_transformer_test.dart` - Verify @rule_name replacement, SKILL.md generation
- `cursor_transformer_test.dart` - Verify YAML -> .mdc conversion
- `antigravity_transformer_test.dart` - Verify path rewriting
- `agent_detector_test.dart` - Mock Process.run for binary detection
- `package_resolver_test.dart` - Mock Isolate.resolvePackageUri

---

## 15. Future Extensibility

### Adding New Technologies (e.g., NestJS, React)

When `nestjs-plans/` is ready:

1. Add new `SkillBundle` entries to `skill_registry.dart`:
   ```dart
   SkillBundle(
     id: 'nestjs_health',
     longName: 'somnio-nestjs-health',
     shortAlias: 'somnio-nh',
     ...
   ),
   ```

2. The existing transformers handle the conversion automatically (same YAML/MD format)

3. No CLI code changes needed beyond the registry entry

### Adding New Agents

To support a new AI agent (e.g., Windsurf, GitHub Copilot):

1. Create `windsurf_transformer.dart` implementing the `Transformer` interface
2. Create `windsurf_installer.dart` implementing the `Installer` interface
3. Add detection logic to `agent_detector.dart`
4. Create `windsurf_command.dart`
5. Register in `cli_runner.dart`

### Adding Custom User Skills

Future feature: allow users to create their own skill bundles in a `custom-plans/` directory following the same YAML/MD format.

---

## 16. File Inventory

### New Files to Create (25 files)

| File | Purpose |
|------|---------|
| `cli/pubspec.yaml` | Package definition with dependencies |
| `cli/analysis_options.yaml` | Dart lint rules |
| `cli/bin/somnio.dart` | CLI entry point |
| `cli/lib/somnio.dart` | Library barrel export |
| `cli/lib/src/cli_runner.dart` | CommandRunner with all subcommands |
| `cli/lib/src/commands/init_command.dart` | `somnio init` |
| `cli/lib/src/commands/update_command.dart` | `somnio update` |
| `cli/lib/src/commands/claude_command.dart` | `somnio claude` |
| `cli/lib/src/commands/cursor_command.dart` | `somnio cursor` |
| `cli/lib/src/commands/antigravity_command.dart` | `somnio antigravity` |
| `cli/lib/src/commands/status_command.dart` | `somnio status` |
| `cli/lib/src/commands/uninstall_command.dart` | `somnio uninstall` |
| `cli/lib/src/installers/installer.dart` | Abstract base installer |
| `cli/lib/src/installers/claude_installer.dart` | Claude Code file writer |
| `cli/lib/src/installers/cursor_installer.dart` | Cursor file writer |
| `cli/lib/src/installers/antigravity_installer.dart` | Antigravity file writer |
| `cli/lib/src/content/skill_bundle.dart` | Data model |
| `cli/lib/src/content/skill_registry.dart` | Static registry |
| `cli/lib/src/content/content_loader.dart` | YAML/MD parser |
| `cli/lib/src/transformers/claude_transformer.dart` | Plan + YAML -> SKILL.md |
| `cli/lib/src/transformers/cursor_transformer.dart` | YAML -> .mdc |
| `cli/lib/src/transformers/antigravity_transformer.dart` | Copy + rewrite |
| `cli/lib/src/utils/agent_detector.dart` | Binary/app detection |
| `cli/lib/src/utils/package_resolver.dart` | Repo root resolution |
| `cli/lib/src/utils/platform_utils.dart` | Cross-platform helpers |

### Existing Files Read (NOT Modified)

| File | Count | Purpose |
|------|-------|---------|
| `flutter-plans/flutter_project_health_audit/plan/flutter-health.plan.md` | 1 | Health audit plan |
| `flutter-plans/flutter_project_health_audit/cursor_rules/*.yaml` | 15 | Health audit rules |
| `flutter-plans/flutter_project_health_audit/.agent/workflows/flutter_health_audit.md` | 1 | Antigravity workflow |
| `flutter-plans/flutter_project_health_audit/cursor_rules/templates/flutter_report_template.txt` | 1 | Report template |
| `flutter-plans/flutter_best_practices_check/plan/best_practices.plan.md` | 1 | Best practices plan |
| `flutter-plans/flutter_best_practices_check/cursor_rules/*.yaml` | 5 | Best practices rules |
| `flutter-plans/flutter_best_practices_check/.agent/workflows/flutter_best_practices.md` | 1 | Antigravity workflow |
| `flutter-plans/flutter_best_practices_check/cursor_rules/templates/best_practices_report_template.txt` | 1 | Report template |
| **Total** | **26** | |
