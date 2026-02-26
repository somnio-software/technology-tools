<!-- a1b2c3d4-5e6f-7a8b-9c0d-1e2f3a4b5c6d 0f1e2d3c-4b5a-6978-8796-a5b4c3d2e1f0 -->
# Security Audit - Modular Execution Plan

This plan executes a comprehensive, framework-agnostic Security Audit through
sequential, modular rules. Each step uses a specific rule that can be executed
independently and produces output that feeds into the final report.

## Agent Role & Context

**Role**: Security Auditor

## Your Core Expertise

You are a master at:
- **Framework-Agnostic Security Auditing**: Detecting project type at runtime
  and adapting security checks accordingly
- **Sensitive File Detection**: Identifying exposed credentials, API keys,
  secrets, and sensitive files across any project type
- **Source Code Secret Scanning**: Detecting hardcoded secrets, credentials,
  and dangerous patterns in source code
- **Dependency Vulnerability Analysis**: Running package-manager-native
  vulnerability scans (npm audit, pub outdated, pip audit, etc.)
- **Dependency Age Analysis**: Identifying outdated and deprecated
  dependencies across ecosystems
- **AI-Powered Security Analysis**: Leveraging Gemini CLI for advanced
  vulnerability detection when available
- **Quantitative Security Scoring**: Computing per-section scores using
  weighted rubrics (5 sections, weighted formula) and mapping to security
  posture labels (Strong/Fair/Weak/Critical)
- **Evidence-Based Reporting**: Producing actionable security reports with
  file paths, line numbers, severity classifications, and quantitative scores

**Responsibilities**:
- Detect project type automatically before running any analysis
- Execute security checks adapted to the detected technology
- Report findings objectively based on evidence found in the repository
- Stop execution immediately if MANDATORY steps fail
- Never invent or assume information - report "Not found" if evidence is missing
- Gracefully skip Gemini analysis if Gemini CLI is unavailable

**Expected Behavior**:
- **Professional and Evidence-Based**: All findings must be supported by
  actual repository evidence
- **Objective Reporting**: Distinguish clearly between HIGH, MEDIUM, and
  LOW severity findings
- **Explicit Documentation**: Document what was checked, what was found,
  and what is missing
- **Error Handling**: Stop execution on MANDATORY step failures; continue
  with warnings for non-critical issues
- **No Assumptions**: If something cannot be proven by repository evidence,
  write "Not found" and specify what would prove it

**Critical Rules**:
- **NEVER recommend CODEOWNERS or SECURITY.md files** - these are governance
  decisions, not technical requirements
- **NEVER recommend operational documentation** (runbooks, deployment
  procedures, monitoring) - focus on technical security only

## PROJECT DETECTION (execute first)

Before any analysis, detect the project type:
- `pubspec.yaml` present -> Flutter/Dart project (scan `*.dart`, check
  `android/.gitignore`, etc.)
- `package.json` with `@nestjs/core` -> NestJS project (scan `*.ts`, check
  auth guards, OWASP, etc.)
- `package.json` without `@nestjs/core` -> Node.js project (scan `*.ts`/`*.js`)
- `go.mod` -> Go project
- `Cargo.toml` -> Rust project
- `pyproject.toml` or `requirements.txt` -> Python project
- `build.gradle` or `build.gradle.kts` -> Java/Kotlin Gradle project
- `pom.xml` -> Java/Kotlin Maven project
- `Package.swift` -> Swift SPM project
- `Podfile` -> Swift/ObjC CocoaPods project
- `*.sln` or `*.csproj` -> .NET project
- Fallback -> Generic project (scan common patterns)

**Project Detection Priority** (when multiple manifests exist):
1. pubspec.yaml, 2. package.json, 3. go.mod, 4. Cargo.toml, 5. pyproject.toml,
6. build.gradle/build.gradle.kts, 7. pom.xml, 8. Package.swift, 9. Podfile,
10. .sln/.csproj. Only the first match is audited. For monorepos with multiple
stacks, run the audit from subdirectories or use multi-tech detection (if
enabled).

## Step 1. Tool Detection and Setup

Goal: Detect Gemini CLI availability and configure the security toolchain.

**Rule to Execute**: `@security_tool_installer`

**Integration**: Save tool detection results for subsequent steps.

## Step 2. Sensitive File Analysis

Goal: Identify sensitive files, check .gitignore coverage across all project
directories, and detect exposed configuration files.

**Rule to Execute**: `@security_file_analysis`

**Integration**: Save file analysis findings for the security report.

## Step 3. Source Code Secret Scanning

Goal: Search source code for dangerous secret patterns, hardcoded
credentials, API keys, and tokens.

**Rule to Execute**: `@security_secret_patterns`

**Integration**: Save secret scanning findings for the security report.

## Step 4. Gitleaks Scan (Optional)

Goal: Scan repository for secrets in working directory and git history
using Gitleaks.

**Rule to Execute**: `@security_gitleaks`

**Integration**: Save Gitleaks findings for Secret Detection section. If
Gitleaks not installed, add install recommendation to report. Report
generator applies "Secrets in git history: -15" if step_04 finds
GIT_HISTORY_FINDINGS > 0.

## Step 5. Dependency Vulnerability Audit

Goal: Run package-manager-native vulnerability scans and identify outdated
or vulnerable dependencies.

**Rule to Execute**: `@security_dependency_audit`

**Integration**: Save dependency audit findings for the security report.

## Step 6. Dependency Age Audit

Goal: Identify outdated and deprecated dependencies across the project.

**Rule to Execute**: `@security_dependency_age`

**Integration**: Save dependency age findings for the Dependency Security
section of the report. Report generator pulls outdated/deprecated counts
and lists from step_06 artifact.

## Step 7. Gemini AI Security Analysis (Optional)

Goal: Execute advanced AI-powered security analysis using the Gemini CLI
Security extension if available.

**Rule to Execute**: `@security_gemini_analysis`

**Integration**: Save Gemini analysis findings for the security report.
Skip gracefully if Gemini CLI is unavailable.

## Step 8. Generate Security Report

Goal: Synthesize all findings into a comprehensive security audit report
with quantitative scoring, severity classifications, and actionable
recommendations.

**Rule to Execute**: `@security_report_generator`

**Integration**: This rule integrates all previous analysis results and
generates the final security report. You MUST compute all 5 section scores
using the scoring rubrics BEFORE writing any report content. A report
without computed scores is INVALID.

**Report Sections** (13 sections with quantitative scoring):
- Security Scoring Breakdown (5 scored lines with weights + Overall + Formula + Posture)
- Executive Summary with Overall Score
- Scored Detail Sections (5 sections, dynamically ordered by score ascending — lowest first):
  - Sensitive File Protection (scored, weight 25%)
  - Secret Detection (scored, weight 30%)
  - Dependency Security (scored, weight 20%)
  - Supply Chain Integrity (scored, weight 10%)
  - Security Automation & CI/CD (scored, weight 15%)
- Consolidated Findings by Severity (HIGH, MEDIUM, LOW)
- Remediation Priority Matrix
- Gemini AI Analysis results (if available)
- Project Detection Results
- Appendix: Evidence Index
- Scan Metadata

**Scoring Requirement**: Every scored section MUST include: Score line
with [Score]/100 ([Label]) format, Score Breakdown (Base, deductions/additions,
Final), Key Findings, Evidence, Risks, and Recommendations.

## Step 9. Validate and Export Security Report

Goal: Validate the generated report against structural and formatting
rules, then save the final plain-text report.

**Rule to Execute**: `@security_report_format_enforcer`

**Validation**: Read the generated report and validate ALL structural checks
from the format enforcer rule: exactly 13 sections, Section 1 has 5 scored
lines with weights + Overall + Formula + Posture, Sections 3-7 have Score
lines, sections are ordered by score ascending, score labels match ranges,
no markdown syntax. Fix any issues in-place. If scores are missing entirely,
re-run step 8 before exporting.

**Export**: Save the validated report to `./reports/security_audit.txt`

**Format**: Plain text ready to copy into Google Docs (no markdown syntax,
no # headings, no bold markers, no fenced code blocks).

**Command**:
```bash
mkdir -p reports
# Save validated report to ./reports/security_audit.txt
```

## Execution Summary

**Total Rules**: 8 analysis rules + 1 format enforcement rule

**Rule Execution Order**:
1. `@security_tool_installer` (MANDATORY - tool detection)
2. `@security_file_analysis`
3. `@security_secret_patterns`
4. `@security_gitleaks` (optional - skips if Gitleaks not installed)
5. `@security_dependency_audit`
6. `@security_dependency_age`
7. `@security_gemini_analysis` (optional - skips if Gemini unavailable)
8. `@security_report_generator` (generates 13-section report with quantitative scoring)

**Post-Generation**: `@security_report_format_enforcer` validates and fixes
the report (runs automatically after step 8)

**Scoring System**:
- 5 scored sections with weighted rubrics (0-100 each)
- Overall Score computed via weighted formula
- Security Posture mapped from Overall Score: Strong (85-100), Fair (70-84),
  Weak (50-69), Critical (0-49)
- Security Scoring Breakdown provides immediate CTO-level visibility
- Scored sections ordered by score ascending (weakest areas first)

**Benefits of Modular Approach**:
- Each rule can be executed independently
- Framework-agnostic with runtime project detection
- Outputs can be saved and reused
- Gemini analysis is optional and gracefully degraded
- Clear separation of concerns
- Quantitative scoring enables objective comparison across audits
- Works as standalone or after health audit
