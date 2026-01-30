# NestJS Project Health Audit

Complete auditing system for NestJS/Node.js projects that provides automated analysis, standardized reports, and improvement recommendations to maintain high-quality backend applications.

## 🚀 Overview

This tool analyzes NestJS/Node.js projects and generates comprehensive reports on project health. It includes automated analysis of multiple categories, support for monorepo structures, and generation of Google Docs-ready reports.

## 📁 Tool Structure

```
nestjs_project_health_audit/
├── env/                    # Environment configuration (templates)
├── cursor_rules/           # Cursor IDE rules for automated analysis
│   ├── templates/          # Report templates and examples
│   └── *.yaml              # Individual analysis rules
├── plan/                   # Project planning and documentation
├── prompts/                # AI prompts for analysis
│   └── nestjs_health_prompt.txt  # ChatGPT prompt
└── README.md               # This file
```

## 🛠️ Main Features

### NestJS/Node.js Auditing System

- **Monorepo Support**: Handles single-app and multi-app repository structures
- **Automated Analysis**: 9 different analysis categories with scoring
- **Tool Auto-Installation**: Automatic setup of Node.js, nvm, and required CLI tools
- **Test Coverage Analysis**: Test coverage execution and aggregation
- **Standardized Reporting**: Structured 16-section reports
- **CI/CD Integration**: GitHub Actions workflow analysis

### Analysis Categories

1. **Tech Stack** (18%) - Node.js/NestJS versions, TypeScript, dependencies, package manager
2. **Architecture** (18%) - Module organization, layered architecture, dependency injection
3. **API Design** (18%) - REST/GraphQL design, DTOs, validation, documentation
4. **Data Layer** (10%) - ORM/query builder, migrations, repository patterns
5. **Testing** (10%) - Unit, integration, E2E tests, coverage
6. **Code Quality** (10%) - ESLint, Prettier, TypeScript strict mode
7. **Security** (10%) - Authentication, authorization, secrets management, OWASP
8. **Documentation & Operations** (3%) - README, API docs, environment setup
9. **CI/CD** (3%) - GitHub Actions, Docker, deployment automation

### Supported Repository Structures

- **Single App**: Standard NestJS application structure
- **Monorepo**: Multiple apps with shared libraries (nx, turborepo, lerna)
- **Microservices**: Multiple NestJS services

## 🎯 Key Features

### Comprehensive Analysis
- **Automated Detection**: Repository structure and configuration analysis
- **Multi-App Support**: Monorepo and microservices architecture
- **Version Management**: nvm integration
- **Dependency Analysis**: Package security scanning and outdated detection
- **API Documentation**: OpenAPI/Swagger validation

### Standardized Reporting
- **16-Section Format**: Consistent, Google Docs-ready reports
- **Scoring System**: 0-100 integer scores with weighted overall calculation
- **Evidence-Based**: File paths and configuration references
- **Actionable Recommendations**: Prioritized improvement suggestions

### Testing & Coverage
- **Multi-Component Testing**: Apps, libraries, and shared modules
- **Coverage Aggregation**: Overall project coverage calculation
- **Quality Metrics**: Test distribution and quality assessment
- **CI/CD Integration**: Automated testing recommendations

## 📋 Usage

### Prerequisites
- Node.js (v18+ recommended)
- npm or yarn or pnpm
- nvm (recommended for version management)
- Git repository with NestJS project

### Quick Start

1. **Clone the repository**:
   ```bash
   git clone https://github.com/somnio-software/technology-tools.git
   cd technology-tools/nestjs_project_health_audit
   ```

2. **Setup Environment**:
   - Create the environment file from the template:
     ```bash
     cp env/copy.env env/.env
     ```

3. **Use Cursor IDE rules**:
   - Copy `cursor_rules/` to your project
   - Use `@rule_name` in Cursor to run specific analyses

4. **Run NestJS Health Audit**:
   ```bash
   # Follow the execution order in cursor_rules/README.md
   @nestjs_tool_installer
   @nestjs_version_alignment
   @nestjs_repository_inventory
   @nestjs_config_analysis
   # ... (see full list in cursor_rules/README.md)
   @nestjs_report_generator
   ```

### 🎯 Execution Instructions

**IMPORTANT**: Always execute the plan `@nestjs-health.plan.md` from step 0 without adding extra analysis not detailed in the plan and rules.

To always run `@nestjs-health.plan.md` (stored in `plan/nestjs-health.plan.md`):
- Execute each step sequentially as defined in the plan
- Use only the specified rules for each step
- Do not add additional analysis beyond what's detailed in the plan
- Follow the exact execution order without modifications
- Save outputs as specified for integration into the final report

### Execution Order

1. `@nestjs_tool_installer` (MANDATORY - Step 0)
2. `@nestjs_version_alignment` (MANDATORY - Step 0)
3. `@nestjs_version_validator`
4. `@nestjs_test_coverage`
5. `@nestjs_repository_inventory`
6. `@nestjs_config_analysis`
7. `@nestjs_cicd_analysis`
8. `@nestjs_testing_analysis`
9. `@nestjs_code_quality`
10. `@nestjs_security_analysis`
11. `@nestjs_api_design_analysis`
12. `@nestjs_documentation_analysis`
13. `@nestjs_report_generator` (Uses `@nestjs_report_format_enforcer` internally)

## 🤖 ChatGPT Integration

### Executive Summary Prompt

The file `prompts/nestjs_health_prompt.txt` contains a specialized prompt for use with ChatGPT that generates an executive summary from the audit plan output.

**Usage**:
1. Execute the complete plan `@nestjs-health.plan.md` following all steps
2. Copy the complete generated report output
3. Use the prompt in ChatGPT along with the output to generate an executive summary

**Prompt features**:
- Generates executive summary of maximum one A4 page (~600 words)
- Analyzes Node.js/NestJS versions and recommends updates if necessary
- Estimates work time for each improvement (XS=1-2h, S=8h, M=16h, L=24h, XL=40h)
- Breaks down large tasks into manageable subtasks
- Ready-to-copy/paste format for executive documents

**Location**: `prompts/nestjs_health_prompt.txt`

## 📊 Report Format

All reports follow a standardized 16-section structure:

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

### Important Exclusions

The audit system will NEVER recommend:
- **Governance Files**: CODEOWNERS or SECURITY.md files (governance decisions, not technical requirements)
- **Deployment-Specific Workflows**: Environment-specific deployment scripts (deployment decisions, not technical requirements)

## 🔧 Configuration

### Node.js Version Management
- Supports nvm configuration (`.nvmrc`)
- Automatic Node.js version detection and alignment
- Multi-app version consistency checking

### Coverage Analysis
- **Single App**: Tests in root + all libraries
- **Monorepo**: Tests in each app + app-specific libraries + shared libraries
- **Aggregation**: Overall project coverage calculation
- **Thresholds**: Configurable coverage targets per component type

## 📈 Scoring System

### Weighted Overall Score
- **Level 1 (54%)**: Tech Stack, Architecture, API Design
- **Level 2 (40%)**: Data Layer, Testing, Code Quality, Security
- **Level 3 (6%)**: Documentation, CI/CD

### Score Labels
- **Strong**: 85-100
- **Fair**: 70-84
- **Weak**: 0-69

## 🤝 Contributing

1. Fork the repository
2. Create feature branch: `git checkout -b feature/amazing-feature`
3. Commit changes: `git commit -m 'feat: add amazing feature'`
4. Push to branch: `git push origin feature/amazing-feature`
5. Open Pull Request

### Development Guidelines
- Follow existing code structure
- Update documentation for new features
- Test with both single-app and monorepo repositories
- Maintain backward compatibility

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

For questions, issues, or contributions:
- **Issues**: [GitHub Issues](https://github.com/somnio-software/technology-tools/issues)
- **Discussions**: [GitHub Discussions](https://github.com/somnio-software/technology-tools/discussions)
- **Pull Requests**: [GitHub Pull Requests](https://github.com/somnio-software/technology-tools/pulls)

## 🏢 About Somnio Software

This project is maintained by [Somnio Software](https://github.com/somnio-software), a company focused on delivering high-quality software solutions and development tools.

---

**Made with ❤️ by the Somnio Software team**


