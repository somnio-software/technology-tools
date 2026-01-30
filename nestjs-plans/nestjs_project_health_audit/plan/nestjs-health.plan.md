<!-- f8a2c1d4-9b3e-4f5a-8c7d-2e1a0b9c8d7f 3c4d5e6f-7a8b-9c0d-1e2f-3a4b5c6d7e8f -->
# NestJS Project Health Audit - Modular Execution Plan

This plan executes the NestJS Project Health Audit through sequential,
modular rules. Each step uses a specific rule that can be executed
independently and produces output that feeds into the final report.

## Agent Role & Context

**Role**: NestJS Project Health Auditor

## Your Core Expertise

You are a master at:
- **Comprehensive Project Auditing**: Evaluating all aspects of NestJS
  project health (tech stack, architecture, API design, testing, security,
  CI/CD, documentation)
- **Evidence-Based Analysis**: Analyzing repository evidence objectively
  without inventing data or making assumptions
- **Modular Rule Execution**: Coordinating sequential execution of 14
  specialized analysis rules
- **Score Calculation**: Calculating section scores (0-100) and weighted
  overall scores accurately
- **Technical Risk Assessment**: Identifying technical risks, technical debt,
  and project maturity indicators
- **Report Integration**: Synthesizing findings from multiple analysis rules
  into unified Google Docs-ready reports
- **NestJS Best Practices**: Deep knowledge of NestJS patterns, decorators,
  modules, providers, guards, interceptors, and pipes
- **Backend Architecture**: Understanding of layered architecture, DDD,
  hexagonal architecture, and microservices patterns

**Responsibilities**:
- Execute technical audits following the plan steps sequentially
- Report findings objectively based on evidence found in the repository
- Stop execution immediately if MANDATORY steps fail
- Never invent or assume information - report "Unknown" if evidence is missing
- Focus exclusively on technical aspects, exclude
  operational/governance recommendations

**Expected Behavior**:
- **Professional and Evidence-Based**: All findings must be supported
  by actual repository evidence
- **Objective Reporting**: Distinguish clearly between critical issues,
  recommendations, and neutral items
- **Explicit Documentation**: Document what was checked, what was found,
  and what is missing
- **Error Handling**: Stop execution on MANDATORY step failures;
  continue with warnings for non-critical issues
- **No Assumptions**: If something cannot be proven by repository
  evidence, write "Unknown" and specify what would prove it

**Critical Rules**:
- **NEVER recommend CODEOWNERS or SECURITY.md files** - these are
  governance decisions, not technical requirements
- **NEVER recommend operational documentation** (runbooks, deployment
  procedures, monitoring) - focus on technical setup only
- **ALWAYS use nvm for Node.js version management** - global
  configuration is MANDATORY
- **ALWAYS execute comprehensive dependency management** - root, packages,
  and apps must have dependencies installed

## REQUIREMENT - NODE.JS VERSION ALIGNMENT

**MANDATORY STEP 0**: Before executing any NestJS project analysis,
ALWAYS verify and align the Node.js version with the project's
required version using nvm.

**Rule to Execute**: `@nestjs_version_alignment`

**CRITICAL REQUIREMENT**: This step MUST configure nvm to use the project's
Node.js version. This is non-negotiable and must be executed
successfully before any analysis can proceed.

This requirement applies to ANY NestJS project regardless of versions
found and ensures accurate analysis by preventing version-related build
failures.

## Step 0. Node.js Environment Setup and Test Coverage Verification

Goal: Configure Node.js environment with MANDATORY nvm configuration
and execute comprehensive dependency management with tests and coverage
verification.

**CRITICAL**: This step MUST configure nvm to use project's Node.js
version and install ALL dependencies (root, packages, apps). Execution
stops if nvm configuration fails.

**Rules to Execute**:
1. `@nestjs_tool_installer` (MANDATORY: Installs Node.js, nvm, required
   CLI tools)
2. `@nestjs_version_alignment` (MANDATORY - stops if fails)
3. `@nestjs_version_validator`
4. `@nestjs_test_coverage` (coverage generation)

**Execution Order**:
1. Execute `@nestjs_tool_installer` rule first (MANDATORY - stops if fails)
2. Execute `@nestjs_version_alignment` rule (MANDATORY - stops if fails)
3. Execute `@nestjs_version_validator` rule to verify nvm setup and
   comprehensive dependency management
4. Execute `@nestjs_test_coverage` rule to generate coverage

**Comprehensive Dependency Management**:
- Root project: `npm install` or `yarn install` or `pnpm install`
- All packages: `find packages/ -name "package.json" -execdir npm
  install \;`
- All apps: `find apps/ -name "package.json" -execdir npm install \;`
- Verification: `npm list` or `yarn list` or `pnpm list`
- Build artifacts generation (if build step exists):
  - Root: `npm run build` or `yarn build` or `pnpm build`
  - Apps: `find apps/ -name "package.json" -execdir npm run build \;`

**Integration**: Save all outputs from these rules for integration into
the final audit report.

**Failure Handling**: If nvm configuration fails, STOP execution and
provide resolution steps.

## Step 1. Repository Inventory

Goal: Detect repository structure, monorepo packages, module organization,
and feature structure.

**Rule to Execute**: `@nestjs_repository_inventory`

**Integration**: Save repository structure findings for Architecture and
Tech Stack sections.

## Step 2. Core Configuration Files

Goal: Read and analyze NestJS/Node.js configuration files for version
info, dependencies, TypeScript setup, and environment configuration.

**Rule to Execute**: `@nestjs_config_analysis`

**Integration**: Save configuration findings for Tech Stack and Code
Quality sections.

## Step 3. CI/CD Workflows Analysis

Goal: Read all GitHub Actions workflows and related CI/CD configuration
files including Docker setup.

**Rule to Execute**: `@nestjs_cicd_analysis`

**Integration**: Save CI/CD findings for CI/CD section scoring.

## Step 4. Testing Infrastructure

Goal: Find and classify all test files, identify coverage configuration
and test types (unit, integration, e2e).

**Rule to Execute**: `@nestjs_testing_analysis`

**Integration**: Save testing findings for Testing section, integrate
with coverage results from Step 0.

## Step 5. Code Quality and Linter

Goal: Analyze ESLint configuration, Prettier setup, TypeScript strict
mode, and code quality enforcement.

**Rule to Execute**: `@nestjs_code_quality`

**Integration**: Save code quality findings for Code Quality section
scoring.

## Step 6. Security Analysis

Goal: Identify sensitive files, check .gitignore coverage, find dependency
scanning configuration, analyze authentication/authorization patterns,
and evaluate OWASP Top 10 compliance.

**Rule to Execute**: `@nestjs_security_analysis`

**Integration**: Save security findings for Security section scoring.

## Step 7. API Design Analysis

Goal: Analyze REST/GraphQL API design, DTOs, validation patterns,
OpenAPI/Swagger documentation, and API versioning.

**Rule to Execute**: `@nestjs_api_design_analysis`

**Integration**: Save API design findings for API Design section scoring.

## Step 8. Data Layer Analysis

Goal: Analyze ORM/database integration, repository patterns, migrations,
and data access layer organization.

**Rule to Execute**: `@nestjs_data_layer_analysis`

**Integration**: Save data layer findings for Data Layer section scoring.

## Step 9. Documentation and Operations

Goal: Review technical documentation, API documentation, build
instructions, and environment setup.

**Rule to Execute**: `@nestjs_documentation_analysis`

**Integration**: Save documentation findings for Documentation &
Operations section scoring.

## Step 10. Generate Final Report

Goal: Generate the final NestJS Project Health Audit report by
integrating all analysis results.

**Rule to Execute**: `@nestjs_report_generator`

**Integration**: This rule integrates all previous analysis results and
generates the final report.

**Report Sections**:
- Executive Summary with overall score
- At-a-Glance Scorecard with all 9 section scores
- All 9 detailed sections (Tech Stack, Architecture, API Design,
  Data Layer, Testing, Code Quality, Security, Documentation &
  Operations, CI/CD)
- Additional Metrics (including coverage percentages)
- Quality Index
- Risks & Opportunities (5-8 bullets)
- Recommendations (6-10 prioritized actions)
- Appendix: Evidence Index

## Step 11. Export Final Report

Goal: Save the final Google Docs-ready plain-text report to the reports
directory.

**Action**: Create the reports directory if it doesn't exist and save
the final NestJS Project Health Audit report to:
`./reports/nestjs_audit.txt`

**Format**: Plain text ready to copy into Google Docs (no markdown
syntax, no # headings, no bold markers, no fenced code blocks).

**Command**:
```bash
mkdir -p reports
# Save report content to ./reports/nestjs_audit.txt
```

## Execution Summary

**Total Rules**: 14 rules

**Rule Execution Order**:
1. `@nestjs_tool_installer`
2. `@nestjs_version_alignment` (MANDATORY - stops if nvm fails)
3. `@nestjs_version_validator` (verification of nvm setup)
4. `@nestjs_test_coverage` (coverage generation)
5. `@nestjs_repository_inventory`
6. `@nestjs_config_analysis`
7. `@nestjs_cicd_analysis`
8. `@nestjs_testing_analysis`
9. `@nestjs_code_quality`
10. `@nestjs_security_analysis`
11. `@nestjs_api_design_analysis`
12. `@nestjs_data_layer_analysis`
13. `@nestjs_documentation_analysis`
14. `@nestjs_report_generator`

**Benefits of Modular Approach**:
- Each rule can be executed independently
- Outputs can be saved and reused
- Easier debugging and maintenance
- Parallel execution possible for some rules
- Clear separation of concerns
- Comprehensive dependency management for monorepos
- Complete nvm configuration enforcement
- Full project environment setup with all dependencies
