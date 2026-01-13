# Flutter Project Health Audit - Workflows Index

This directory contains automated **Workflows** for the Flutter Project Health Audit system.

## Installation Note

> [!IMPORTANT]
> **Action Required**: Before running any workflows, you MUST copy the entire `.agent` directory to the **root** of the target project you wish to audit.
>
> **Why?** Antigravity workflows execute relative to the project root. Moving the folder ensures all paths and commands function correctly within your specific project environment.

## Turbo Mode

> [!TIP]
> **Automated Execution**: Workflows with the `// turbo-all` annotation authorize Antigravity to execute all contained commands automatically without requiring manual confirmation. This allows for seamless, uninterrupted audits.

## Core Workflows

### 1. Flutter Project Health Audit
- **File**: `flutter_health_audit.md`
- **Purpose**: Automated end-to-end execution of the complete Flutter Project Health Audit.
- **Steps**:
  1. Environment Setup & Version Alignment
  2. Test Coverage Generation
  3. Repository, Config, CI/CD, Testing, Quality, Security, and Docs Analysis
  4. Final Report Generation & Export
- **Usage**: "Run the health audit workflow"

## Usage

To execute a workflow:

1. Ensure the `.agent` folder is in your project root.
2. Ask Antigravity: "Run the health audit workflow" or use the slash command if configured.
