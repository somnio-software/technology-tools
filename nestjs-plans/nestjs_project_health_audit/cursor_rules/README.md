# NestJS Project Health Audit - Rules Index

This directory contains all the individual rules for the NestJS Project
Health Audit system, supporting both single-app and monorepo structures
(nx, turborepo, lerna, custom).

## Location Note

These rules are located in `nestjs_project_health_audit/cursor_rules/`.

## Templates Directory

The `templates/` directory contains template files used by the rules:
- **`templates/nestjs_report_template.txt`** - Template showing exact
  format structure for reports
- **`templates/README.md`** - Documentation for template files

## Prompts Directory

The `prompts/` directory contains AI prompts for enhanced analysis:
- **`prompts/nestjs_health_prompt.txt`** - ChatGPT prompt for generating
  executive summaries from audit outputs

## Core Rules (Required for every audit)

### 1. NestJS Tool Installer
- **File**: `nestjs_tool_installer.yaml`
- **Purpose**: Centralized installer for all required tools (Node.js,
  nvm, npm/yarn/pnpm)
- **Usage**: `@nestjs_tool_installer`
- **Dependencies**: None (must run first)

### 2. NestJS Version Alignment
- **File**: `nestjs_version_alignment.yaml`
- **Purpose**: Mandatory Node.js version alignment before any analysis
- **Usage**: `@nestjs_version_alignment`
- **Dependencies**: `@nestjs_tool_installer`

### 3. NestJS Version Validator
- **File**: `nestjs_version_validator.yaml`
- **Purpose**: Verify nvm installation and Node.js environment setup
- **Usage**: `@nestjs_version_validator`
- **Dependencies**: `@nestjs_version_alignment`

### 4. NestJS Test Coverage
- **File**: `nestjs_test_coverage.yaml`
- **Purpose**: Generate test coverage reports and validate
  `coverage >= 70%`
- **Usage**: `@nestjs_test_coverage`
- **Dependencies**: `@nestjs_version_alignment`

## Analysis Rules (Execute in order)

### 5. Repository Inventory
- **File**: `nestjs_repository_inventory.yaml`
- **Purpose**: Detect repository structure, module organization, and
  monorepo packages
- **Usage**: `@nestjs_repository_inventory`
- **Dependencies**: None

### 6. Configuration Analysis
- **File**: `nestjs_config_analysis.yaml`
- **Purpose**: Analyze NestJS/Node.js configuration files, TypeScript
  setup, dependencies
- **Usage**: `@nestjs_config_analysis`
- **Dependencies**: None

### 7. CI/CD Analysis
- **File**: `nestjs_cicd_analysis.yaml`
- **Purpose**: Analyze GitHub Actions workflows, Docker setup, and
  coverage enforcement
- **Usage**: `@nestjs_cicd_analysis`
- **Dependencies**: None

### 8. Testing Analysis
- **File**: `nestjs_testing_analysis.yaml`
- **Purpose**: Find and classify test files (unit, integration, e2e)
  and coverage config
- **Usage**: `@nestjs_testing_analysis`
- **Dependencies**: `@nestjs_test_coverage` (for coverage integration)

### 9. Code Quality Analysis
- **File**: `nestjs_code_quality.yaml`
- **Purpose**: Analyze ESLint, Prettier, TypeScript strict mode, and
  code quality
- **Usage**: `@nestjs_code_quality`
- **Dependencies**: None

### 10. Security Analysis
- **File**: `nestjs_security_analysis.yaml`
- **Purpose**: Identify sensitive files, analyze authentication/
  authorization, security best practices, OWASP Top 10
- **Usage**: `@nestjs_security_analysis`
- **Dependencies**: None

### 11. API Design Analysis
- **File**: `nestjs_api_design_analysis.yaml`
- **Purpose**: Analyze REST/GraphQL API design, DTOs, validation,
  OpenAPI/Swagger documentation, API versioning
- **Usage**: `@nestjs_api_design_analysis`
- **Dependencies**: None

### 12. Data Layer Analysis
- **File**: `nestjs_data_layer_analysis.yaml`
- **Purpose**: Analyze ORM/database integration, repository patterns,
  migrations, and data access layer organization
- **Usage**: `@nestjs_data_layer_analysis`
- **Dependencies**: None

### 13. Documentation Analysis
- **File**: `nestjs_documentation_analysis.yaml`
- **Purpose**: Review technical documentation, API docs, and
  environment setup
- **Usage**: `@nestjs_documentation_analysis`
- **Dependencies**: None

## Report Generation

### 14. Report Generator
- **File**: `nestjs_report_generator.yaml`
- **Purpose**: Generate final audit report integrating all analysis
  results using standardized format
- **Usage**: `@nestjs_report_generator`
- **Dependencies**: All previous rules
- **Template**: Uses `templates/nestjs_report_template.txt`

### 15. Report Format Enforcer
- **File**: `nestjs_report_format_enforcer.yaml`
- **Purpose**: Enforce consistent report format structure
- **Usage**: `@nestjs_report_format_enforcer`
- **Dependencies**: Used by report generation rules
- **Template**: References `templates/nestjs_report_template.txt`

## Execution Order

1. `@nestjs_tool_installer` (MANDATORY)
2. `@nestjs_version_alignment` (MANDATORY)
3. `@nestjs_version_validator`
4. `@nestjs_test_coverage`
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

## Standardized Report Format

All reports follow a consistent 16-section structure defined in
`templates/nestjs_report_template.txt`:

1. Executive Summary
2. At-a-Glance Scorecard
3. Tech Stack
4. Architecture
5. API Design
6. Data Layer
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
- **Monorepo Support**: Handles single-app and monorepo repositories

### Important Exclusions
The audit system will NEVER recommend:
- **Governance Files**: CODEOWNERS or SECURITY.md files (governance
  decisions, not technical requirements)
- **Deployment-Specific Workflows**: Environment-specific deployment
  scripts (deployment decisions, not technical requirements)

## ChatGPT Integration

### Executive Summary Generation

After completing the full audit using the execution plan, you can use
the ChatGPT prompt to generate an executive summary:

**Process**:
1. Execute the complete `@nestjs-health.plan.md` following all steps
2. Copy the complete audit report output
3. Use `prompts/nestjs_health_prompt.txt` with ChatGPT
4. Paste the audit output as input to generate an executive summary

**Benefits**:
- Generates executive-ready summaries (max 1 A4 page, ~600 words)
- Analyzes Node.js/NestJS versions and provides update recommendations
- Estimates work time for each improvement (XS=1-2h, S=8h, M=16h,
  L=24h, XL=40h)
- Breaks down large tasks into manageable subtasks
- Ready-to-copy format for executive documents
- Spanish language output for leadership communication

## Benefits of Modular Approach

- **Independent Execution**: Each rule can be run separately
- **Reusable Outputs**: Results can be saved and reused
- **Easier Debugging**: Issues can be isolated to specific rules
- **Parallel Execution**: Some rules can run simultaneously
- **Clear Separation**: Each rule has a single responsibility
- **Maintainable**: Easier to update individual components
- **Comprehensive**: Covers all aspects of NestJS project health
