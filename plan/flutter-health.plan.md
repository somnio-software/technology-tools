<!-- 0b328ebf-1ad3-42f2-a0b4-28745c29c2f4 a910fd82-04ff-43e3-af54-da4e59d4dee0 -->
# Flutter Project Health Audit - Modular Execution Plan

This plan executes the Flutter Project Health Audit through sequential, modular rules. Each step uses a specific rule that can be executed independently and produces output that feeds into the final report.

## REQUIREMENT - FLUTTER VERSION ALIGNMENT

**MANDATORY STEP**: Before executing any Flutter project analysis, ALWAYS verify and align the global Flutter version with the project's required version.

**Rule to Execute**: `@flutter_version_alignment`

This requirement applies to ANY Flutter project regardless of versions found and ensures accurate analysis by preventing version-related build failures.

## Step 0. Flutter Environment Setup and Test Coverage Verification

Goal: Configure Flutter environment and execute tests with coverage verification. Continue execution even if setup fails.

**Rule to Execute**: `@flutter_version_alignment`

**Additional Rules**:
- `@flutter_version_validator` (existing rule)
- `@flutter_test_coverage` (existing rule)

**Execution Order**:
1. Execute `@flutter_version_alignment` rule first (MANDATORY)
2. Execute `@flutter_version_validator` rule to verify setup
3. Execute `@flutter_test_coverage` rule to generate coverage

**Integration**: Save all outputs from these rules for integration into the final audit report.

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

## Step 7. Documentation and Operations

Goal: Review project documentation, build instructions, environment setup, and operational files.

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

## Execution Summary

**Total Rules**: 9 individual rules + 3 existing rules

**Rule Execution Order**:
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

**Benefits of Modular Approach**:
- Each rule can be executed independently
- Outputs can be saved and reused
- Easier debugging and maintenance
- Parallel execution possible for some rules
- Clear separation of concerns


