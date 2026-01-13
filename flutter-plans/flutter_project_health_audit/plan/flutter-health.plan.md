<!-- 0b328ebf-1ad3-42f2-a0b4-28745c29c2f4 a910fd82-04ff-43e3-af54-da4e59d4dee0 -->
# Flutter Project Health Audit - Modular Execution Plan

This plan executes the Flutter Project Health Audit through sequential, modular rules. Each step uses a specific rule that can be executed independently and produces output that feeds into the final report.

## REQUIREMENT - FLUTTER VERSION ALIGNMENT

**MANDATORY STEP 0**: Before executing any Flutter project analysis, ALWAYS verify and align the global Flutter version with the project's required version using FVM.

**Rule to Execute**: `@flutter_version_alignment`

**CRITICAL REQUIREMENT**: This step MUST configure FVM global version to match project requirements. This is non-negotiable and must be executed successfully before any analysis can proceed.

This requirement applies to ANY Flutter project regardless of versions found and ensures accurate analysis by preventing version-related build failures.

## Step 0. Flutter Environment Setup and Test Coverage Verification

Goal: Configure Flutter environment with MANDATORY FVM global configuration and execute comprehensive dependency management with tests and coverage verification.

**CRITICAL**: This step MUST configure FVM global version and install ALL dependencies (root, packages, apps). Execution stops if FVM global configuration fails.

**Rules to Execute**:
1. `@flutter_tool_installer` (MANDATORY: Installs Node.js, FVM, Gemini CLI, Security Extension)
2. `@flutter_version_alignment` (MANDATORY - stops if fails)
3. `@flutter_version_validator`
4. `@flutter_test_coverage` (coverage generation)

**Execution Order**:
1. Execute `@flutter_tool_installer` rule first (MANDATORY - stops if fails)
2. Execute `@flutter_version_alignment` rule (MANDATORY - stops if fails)
3. Execute `@flutter_version_validator` rule to verify FVM global setup and comprehensive dependency management
4. Execute `@flutter_test_coverage` rule to generate coverage

**Comprehensive Dependency Management**:
- Root project: `fvm flutter pub get`
- All packages: `find packages/ -name "pubspec.yaml" -execdir fvm flutter pub get \;`
- All apps: `find apps/ -name "pubspec.yaml" -execdir fvm flutter pub get \;`
- Verification: `fvm flutter pub deps`
- Build artifacts generation (only where build_runner is declared):
  - Root: `fvm dart run build_runner build --delete-conflicting-output`
  - Packages: `find packages/ -name "pubspec.yaml" -execdir sh -c 'if grep -q "build_runner" pubspec.yaml 2>/dev/null; then fvm dart run build_runner build --delete-conflicting-output; fi' \;`
  - Apps: `find apps/ -name "pubspec.yaml" -execdir sh -c 'if grep -q "build_runner" pubspec.yaml 2>/dev/null; then fvm dart run build_runner build --delete-conflicting-output; fi' \;`

**Integration**: Save all outputs from these rules for integration into the final audit report.

**Failure Handling**: If FVM global configuration fails, STOP execution and provide resolution steps.

## Step 1. Repository Inventory

Goal: Detect repository structure, platform folders, monorepo packages, and feature organization.

**Rule to Execute**: `@flutter_repository_inventory`

**Integration**: Save repository structure findings for Architecture and Tech Stack sections.

## Step 2. Core Configuration Files and Internationalization

Goal: Read and analyze Flutter/Dart configuration files for version info, dependencies, linter setup, and internationalization configuration.

**Rule to Execute**: `@flutter_config_analysis`

**Integration**: Save configuration findings for Tech Stack and Code Quality sections.

## Step 3. CI/CD Workflows Analysis

Goal: Read all GitHub Actions workflows and related CI/CD configuration files.

**Rule to Execute**: `@flutter_cicd_analysis`

**Integration**: Save CI/CD findings for CI/CD section scoring.

## Step 4. Testing Infrastructure

Goal: Find and classify all test files, identify coverage configuration and test types.

**Rule to Execute**: `@flutter_testing_analysis`

**Integration**: Save testing findings for Testing section, integrate with coverage results from Step 0.

## Step 5. Code Quality and Linter

Goal: Analyze linter configuration, exclusions, and code quality enforcement.

**Rule to Execute**: `@flutter_code_quality`

**Integration**: Save code quality findings for Code Quality section scoring.

## Step 6. Security Analysis

Goal: Identify sensitive files, check .gitignore coverage across all project directories, find dependency scanning configuration.

**Rule to Execute**: `@flutter_security_analysis`

**Integration**: Save security findings for Security section scoring.

## Step 6.5. Gemini Security Audit (Advanced)

Goal: Execute advanced security analysis using the Gemini CLI Security extension to identify vulnerabilities and risks in code changes.

**Rule to Execute**: `@flutter_gemini_security_audit`

**Integration**: Save Gemini security findings for the Security section of the final report.


## Step 7. Documentation and Operations

Goal: Review technical documentation, build instructions, and environment setup (no operational/runbook content).

**Rule to Execute**: `@flutter_documentation_analysis`

**Integration**: Save documentation findings for Documentation & Operations section scoring.

## Step 8. Generate Final Report

Goal: Generate the final Flutter Project Health Audit report by integrating all analysis results.

**Rule to Execute**: `@flutter_report_generator`

**Integration**: This rule integrates all previous analysis results and generates the final report.

**Report Sections**:
- Executive Summary with overall score
- At-a-Glance Scorecard with all 9 section scores
- All 9 detailed sections (Tech Stack, Architecture, State Management, Repositories & Data Layer, Testing, Code Quality, Security, Documentation & Operations, CI/CD)
- Additional Metrics (including coverage percentages)
- Quality Index
- Risks & Opportunities (5-8 bullets)
- Recommendations (6-10 prioritized actions)
- Appendix: Evidence Index

## Step 9. Export Final Report

Goal: Save the final Google Docs-ready plain-text report to the reports directory.

**Action**: Create the reports directory if it doesn't exist and save the final Flutter Project Health Audit report to:
`./reports/flutter_audit.txt`

**Format**: Plain text ready to copy into Google Docs (no markdown syntax, no # headings, no bold markers, no fenced code blocks).

**Command**:
```bash
mkdir -p reports
# Save report content to ./reports/flutter_audit.txt
```

## Step 10. Optional Best Practices Check Prompt

**CRITICAL**: After completing Step 9, you MUST ask the user if they want to execute the Best Practices Check plan. **NEVER execute it automatically**.

**Action**: Prompt the user with the following question:

```
Flutter Project Health Audit completed successfully!

Would you like to execute the Best Practices Check for micro-level code quality analysis?
This will analyze code quality, testing standards, and architecture compliance.

Plan: @flutter_best_practices_check/plan/best_practices.plan.md

Type 'yes' or 'y' to proceed, or 'no' or 'n' to skip.
```

**Rules**:
- **NEVER execute `@best_practices.plan.md` automatically**
- **ALWAYS wait for explicit user confirmation**
- If user confirms, execute `@flutter_best_practices_check/plan/best_practices.plan.md`
- If user declines or doesn't respond, end execution here

**Best Practices Plan Details** (only if user confirms):
- Plan: `@flutter_best_practices_check/plan/best_practices.plan.md`
- Steps:
  1. `@testing_quality.yaml`
  2. `@architecture_compliance.yaml`
  3. `@code_standards.yaml`
  4. `@best_practices_format_enforcer.yaml`
  5. `@best_practices_generator.yaml`

**Benefits of Combined Execution** (informational only):
- **Macro-level analysis** (Health Audit): Project infrastructure, CI/CD, security, documentation
- **Micro-level analysis** (Best Practices): Code quality, testing standards, architecture compliance
- **Comprehensive coverage**: Both infrastructure and code implementation quality
- **Separate reports**: Each plan generates its own report for focused analysis

**Report Outputs**:
- Health Audit: `./reports/flutter_audit.txt`
- Best Practices: Generated by `@best_practices_generator.yaml` (see plan for output location)

## Execution Summary

**Total Rules**: 13 rules

**Rule Execution Order**:
1. `@flutter_tool_installer`
2. `@flutter_version_alignment` (MANDATORY - stops if FVM global fails)
3. `@flutter_version_validator` (verification of FVM global setup)
4. `@flutter_test_coverage` (coverage generation)
5. `@flutter_repository_inventory`
6. `@flutter_config_analysis`
7. `@flutter_cicd_analysis`
8. `@flutter_testing_analysis`
9. `@flutter_code_quality`
10. `@flutter_security_analysis`
11. `@flutter_gemini_security_audit`
12. `@flutter_documentation_analysis`
13. `@flutter_report_generator`

**Benefits of Modular Approach**:
- Each rule can be executed independently
- Outputs can be saved and reused
- Easier debugging and maintenance
- Parallel execution possible for some rules
- Clear separation of concerns
- Comprehensive dependency management for monorepos
- Complete FVM global configuration enforcement
- Full project environment setup with all dependencies


