# Flutter Project Health Audit

Complete auditing system for Flutter/Dart projects that provides automated analysis, standardized reports, and improvement recommendations to maintain high-quality projects.

## 🚀 Overview

This tool is designed to analyze Flutter/Dart projects and generate comprehensive reports on project health. It includes automated analysis of multiple categories, support for monorepo structures, and generation of Google Docs-ready reports.

## 📁 Tool Structure

```
flutter_project_health_audit/
├── cursor_rules/           # Cursor IDE rules for automated analysis
│   ├── templates/          # Report templates and examples
│   └── *.yaml              # Individual analysis rules
├── plan/                   # Project planning and documentation
├── prompts/                # AI prompts for analysis
│   └── flutter_health_prompt.txt  # ChatGPT prompt
└── README.md               # This file
```

## 🛠️ Main Features

### Flutter/Dart Auditing System

- **Multi-App Monorepo Support**: Handles simple and multi-app repository structures
- **Automated Analysis**: 10 different analysis categories with scoring
- **Tool Auto-Installation**: Automatic setup of Node.js, FVM, and Gemini CLI
- **Coverage Analysis**: Test coverage execution and aggregation
- **Standardized Reporting**: Structured 16-section reports
- **CI/CD Integration**: GitHub Actions workflow analysis

### Analysis Categories

1. **Tech Stack** (18%) - Flutter/Dart versions, dependencies, tooling
2. **Architecture** (18%) - Project structure, separation of concerns
3. **State Management** (18%) - BLoC, Riverpod, Provider patterns
4. **Repositories & Data Layer** (10%) - Data abstraction and error handling
5. **Testing** (10%) - Test coverage, quality, and infrastructure
6. **Code Quality** (10%) - Linting, formatting, analysis rules
7. **Security** (10%) - Sensitive files, .gitignore coverage
8. **Gemini Security Audit** (Integrated) - Advanced AI-powered security analysis
9. **Documentation & Operations** (3%) - README, CHANGELOG, onboarding
10. **CI/CD** (3%) - GitHub Actions, automation, workflows

### Supported Repository Structures

- **Single App**: `app/` directory structure
- **Multi-App Monorepo**: `apps/app1/`, `apps/app2/`, etc.
- **Package Support**: `packages/` directories (shared and app-specific)

## 🎯 Key Features

### Comprehensive Analysis
- **Automated Detection**: Repository structure and configuration analysis
- **Multi-Platform Support**: Android, iOS, Web, Desktop platforms
- **Version Management**: FVM (Flutter Version Management) integration
- **Dependency Analysis**: Package management and security scanning

### Standardized Reporting
- **16-Section Format**: Consistent, Google Docs-ready reports
- **Scoring System**: 0-100 integer scores with weighted overall calculation
- **Evidence-Based**: File paths and configuration references
- **Actionable Recommendations**: Prioritized improvement suggestions

### Testing & Coverage
- **Multi-Component Testing**: Apps, packages, and shared components
- **Coverage Aggregation**: Overall project coverage calculation
- **Quality Metrics**: Test distribution and quality assessment
- **CI/CD Integration**: Automated testing recommendations

## 📋 Usage

### Prerequisites
- Flutter SDK
- Dart SDK
- FVM (recommended)
- Git repository with Flutter project
- **Gemini API Key**: `GEMINI_API_KEY` or `GOOGLE_API_KEY` environment variable (Get one at [Google AI Studio](https://aistudio.google.com/))

### Quick Start

1. **Clone the repository**:
   ```bash
   git clone https://github.com/somnio-software/technology-tools.git
   cd technology-tools/flutter_project_health_audit
   ```

2. **Use Cursor IDE rules**:
   - Copy `cursor_rules/` to your project
   - Use `@rule_name` in Cursor to run specific analyses

3. **Run Flutter Health Audit**:
   ```bash
   # Follow the execution order in cursor_rules/README.md
   @flutter_tool_installer
   @flutter_version_alignment
   @flutter_repository_inventory
   @flutter_config_analysis
   # ... (see full list in cursor_rules/README.md)
   @flutter_report_generator
   ```

### 🎯 Execution Instructions

**IMPORTANT**: Always execute the plan `@flutter-health.plan.md` from step 0 without adding extra analysis not detailed in the plan and rules. Do not invent information and follow the instructions as indicated.

To always run `@flutter-health.plan.md` (stored in `plan/flutter-health.plan.md`):
- Execute each step sequentially as defined in the plan
- Use only the specified rules for each step
- Do not add additional analysis beyond what's detailed in the plan
- Follow the exact execution order without modifications
- Save outputs as specified for integration into the final report

### Execution Order

1. `@flutter_tool_installer` (MANDATORY - Step 0)
2. `@flutter_version_alignment` (MANDATORY - Step 0)
2. `@flutter_version_validator`
3. `@flutter_test_coverage`
4. `@flutter_repository_inventory`
5. `@flutter_config_analysis`
6. `@flutter_cicd_analysis`
7. `@flutter_testing_analysis`
8. `@flutter_code_quality`
9. `@flutter_security_analysis`
10. `@flutter_gemini_security_audit`
11. `@flutter_documentation_analysis`
12. `@flutter_report_generator` (Uses `@flutter_report_format_enforcer` internally)

## 🤖 ChatGPT Integration

### Executive Summary Prompt

The file `prompts/flutter_health_prompt.txt` contains a specialized prompt for use with ChatGPT that generates an executive summary from the audit plan output.

**Usage**:
1. Execute the complete plan `@flutter-health.plan.md` following all steps
2. Copy the complete generated report output
3. Use the prompt in ChatGPT along with the output to generate an executive summary

**Prompt features**:
- Generates executive summary of maximum one A4 page (~600 words)
- Analyzes Flutter version and recommends updates if necessary
- Estimates work time for each improvement (XS=1-2h, S=8h, M=16h, L=24h, XL=40h)
- Breaks down large tasks into manageable subtasks
- Ready-to-copy/paste format for executive documents

**Location**: `prompts/flutter_health_prompt.txt`

## 📊 Report Format

All reports follow a standardized 16-section structure:

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

### Important Exclusions

The audit system will NEVER recommend:
- **Internationalization Expansion**: Adding new languages or translations
- **Governance Files**: CODEOWNERS or SECURITY.md files (governance decisions, not technical requirements)
- **Platform-Specific Workflows**: Android/iOS build workflows (deployment decisions, not technical requirements)

## 🔧 Configuration

### Flutter Version Management
- Supports FVM configuration (`.fvm/fvm_config.json`, `.fvmrc`)
- Automatic Flutter version detection and alignment
- Multi-app version consistency checking

### Coverage Analysis
- **Single App**: Tests in root + all packages
- **Multi-App**: Tests in each app + app-specific packages + shared packages
- **Aggregation**: Overall project coverage calculation
- **Thresholds**: Configurable coverage targets per component type

### Gemini Security Audit
- **Requirement**: `GEMINI_API_KEY` or `GOOGLE_API_KEY` environment variable
- **Setup**:
  ```bash
  # macOS/Linux (Add to ~/.zshrc or ~/.bashrc)
  export GEMINI_API_KEY=your_api_key_here

  # Windows (PowerShell)
  $env:GEMINI_API_KEY="your_api_key_here"
  ```
- **Get Key**: [Google AI Studio](https://aistudio.google.com/)
- **Repository**: [gemini-cli-extensions/security](https://github.com/gemini-cli-extensions/security)
  > This extension uses Gemini to analyze code for security vulnerabilities, providing detailed reports and recommendations.

## 📈 Scoring System

### Weighted Overall Score
- **Level 1 (54%)**: Tech Stack, Architecture, State Management
- **Level 2 (40%)**: Repositories, Testing, Code Quality, Security
- **Level 3 (6%)**: Documentation, CI/CD

### Score Labels
- **Strong**: 85-100
- **Fair**: 70-84
- **Weak**: 0-69

## 🤝 Contributing

1. Fork the repository
2. Create feature branch: `git checkout -b feature/amazing-feature`
3. Commit changes: `git commit -m 'Add amazing feature'`
4. Push to branch: `git push origin feature/amazing-feature`
5. Open Pull Request

### Development Guidelines
- Follow existing code structure
- Update documentation for new features
- Test with both single-app and multi-app repositories
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