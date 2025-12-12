# Flutter Project Health Audit - Rules Index

This directory contains all the individual rules for the Flutter Project Health Audit system, supporting both single-app and multi-app monorepo structures.

## Location Note

These rules were moved to `flutter_project_health_audit/cursor_rules/`.

## Templates Directory

The `templates/` directory contains template files used by the rules:
- **`templates/flutter_report_template.txt`** - Template showing exact format structure for reports
- **`templates/README.md`** - Documentation for template files

## Prompts Directory

The `prompts/` directory contains AI prompts for enhanced analysis:
- **`prompts/flutter_health_prompt.txt`** - ChatGPT prompt for generating executive summaries from audit outputs

## Core Rules (Required for every audit)

### 1. Flutter Version Alignment
- **File**: `flutter_version_alignment.yaml`
- **Purpose**: Mandatory Flutter version alignment before any analysis
- **Usage**: `@flutter_version_alignment`
- **Dependencies**: None (must run first)

### 2. Flutter Version Validator
- **File**: `flutter_version_validator.yaml` (existing)
- **Purpose**: Verify FVM installation and Flutter environment setup
- **Usage**: `@flutter_version_validator`
- **Dependencies**: `@flutter_version_alignment`

### 3. Flutter Test Coverage
- **File**: `flutter_test_coverage.yaml` (existing)
- **Purpose**: Generate test coverage reports and validate `min_coverage >= 70%`
- **Usage**: `@flutter_test_coverage`
- **Dependencies**: `@flutter_version_alignment`

## Analysis Rules (Execute in order)

### 4. Repository Inventory
- **File**: `flutter_repository_inventory.yaml`
- **Purpose**: Detect repository structure and organization
- **Usage**: `@flutter_repository_inventory`
- **Dependencies**: None

### 5. Configuration Analysis
- **File**: `flutter_config_analysis.yaml`
- **Purpose**: Analyze Flutter/Dart configuration files
- **Usage**: `@flutter_config_analysis`
- **Dependencies**: None

### 6. CI/CD Analysis
- **File**: `flutter_cicd_analysis.yaml`
- **Purpose**: Analyze GitHub Actions workflows, CI/CD configs, and coverage enforcement
- **Usage**: `@flutter_cicd_analysis`
- **Dependencies**: None

### 7. Testing Analysis
- **File**: `flutter_testing_analysis.yaml`
- **Purpose**: Find and classify test files and coverage config
- **Usage**: `@flutter_testing_analysis`
- **Dependencies**: `@flutter_test_coverage` (for coverage integration)

### 8. Code Quality Analysis
- **File**: `flutter_code_quality.yaml`
- **Purpose**: Analyze linter configuration and code quality
- **Usage**: `@flutter_code_quality`
- **Dependencies**: None

### 9. Security Analysis
- **File**: `flutter_security_analysis.yaml`
- **Purpose**: Identify sensitive files and security configurations
- **Usage**: `@flutter_security_analysis`
- **Dependencies**: None

### 10. Documentation Analysis
- **File**: `flutter_documentation_analysis.yaml`
- **Purpose**: Review documentation and operational files
- **Usage**: `@flutter_documentation_analysis`
- **Dependencies**: None

## Report Generation

### 11. Report Generator
- **File**: `flutter_report_generator.yaml`
- **Purpose**: Generate final audit report integrating all analysis results using standardized format
- **Usage**: `@flutter_report_generator`
- **Dependencies**: All previous rules
- **Template**: Uses `templates/flutter_report_template.txt`

### 12. Report Format Enforcer
- **File**: `flutter_report_format_enforcer.yaml`
- **Purpose**: Enforce consistent report format structure
- **Usage**: `@flutter_report_format_enforcer`
- **Dependencies**: Used by report generation rules
- **Template**: References `templates/flutter_report_template.txt`

### 13. Flutter Project Health Audit
- **File**: `flutter_project_health_audit.yaml` (existing)
- **Purpose**: Main audit rule with scoring logic and standardized format
- **Usage**: `@flutter_project_health_audit`
- **Dependencies**: Used by `@flutter_report_generator`
- **Template**: Follows `templates/flutter_report_template.txt` structure

## Execution Order

1. `@flutter_version_alignment` (MANDATORY)
2. `@flutter_version_validator` (existing)
3. `@flutter_test_coverage` (existing)
4. `@flutter_repository_inventory`
5. `@flutter_config_analysis`
6. `@flutter_cicd_analysis`
7. `@flutter_testing_analysis`
8. `@flutter_code_quality`
9. `@flutter_security_analysis`
10. `@flutter_documentation_analysis`
11. `@flutter_report_generator`

## Standardized Report Format

All reports follow a consistent 16-section structure defined in `templates/flutter_report_template.txt`:

1. Executive Summary
2. At-a-Glance Scorecard
3. Tech Stack
4. Architecture
5. State Management
6. Repositories & Data Layer
7. Testing
8. Code Quality (Linter & Warnings)
9. Security
10. Documentation & Operations
11. CI/CD (Configs Found in Repo)
12. Additional Metrics
13. Quality Index
14. Risks & Opportunities
15. Recommendations
16. Appendix: Evidence Index

### Format Rules
- **Plain Text**: No markdown syntax
- **Consistent Structure**: All sections follow the same format
- **Google Docs Ready**: Copy-paste friendly
- **Multi-App Support**: Handles single-app and multi-app repositories

### Important Exclusions
The audit system will NEVER recommend:
- **Internationalization Expansion**: Adding new languages or translations
- **Governance Files**: CODEOWNERS or SECURITY.md files (governance decisions, not technical requirements)
- **Platform-Specific Workflows**: Android/iOS build workflows (deployment decisions, not technical requirements)

## ChatGPT Integration

### Executive Summary Generation

After completing the full audit using the execution plan, you can use the ChatGPT prompt to generate an executive summary:

**Process**:
1. Execute the complete `@flutter-health.plan.md` following all steps
2. Copy the complete audit report output
3. Use `prompts/flutter_health_prompt.txt` with ChatGPT
4. Paste the audit output as input to generate an executive summary

**Benefits**:
- Generates executive-ready summaries (max 1 A4 page, ~600 words)
- Analyzes Flutter version and provides update recommendations
- Estimates work time for each improvement (XS=1-2h, S=8h, M=16h, L=24h, XL=40h)
- Breaks down large tasks into manageable subtasks
- Ready-to-copy format for executive documents

## Benefits of Modular Approach

- **Independent Execution**: Each rule can be run separately
- **Reusable Outputs**: Results can be saved and reused
- **Easier Debugging**: Issues can be isolated to specific rules
- **Parallel Execution**: Some rules can run simultaneously
- **Clear Separation**: Each rule has a single responsibility
- **Maintainable**: Easier to update individual components
