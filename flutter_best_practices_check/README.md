# Flutter Best Practices Check

A specialized analysis tool for evaluating codebase quality, testing standards, and architecture compliance against strict development guidelines.

## 🚀 Overview

This tool performs a **micro-level** inspection of Flutter code, focusing on the *content* and *quality* of the implementation rather than just project infrastructure. It validates adherence to specific standards for:
- **Testing**: Structure, naming, and assertion quality.
- **Architecture**: Layer separation and dependency injection.
- **Code Standards**: Model structure, JSON serialization, and coding best practices.

## 📁 Tool Structure

```
flutter_best_practices_check/
├── cursor_rules/            # Analysis rules (.yaml)
│   ├── templates/           # Report templates (.txt)
│   ├── testing_quality.yaml
│   ├── architecture_compliance.yaml
│   ├── code_standards.yaml
│   └── best_practices_generator.yaml
├── plan/                    # Execution plan (.md)
│   └── best_practices.plan.md
└── README.md                # This file
```

## 🛠️ Main Features

### Micro-Clarity Analysis
- **Live Standards Validation**: Validates code against live `.mdc` standards from GitHub
- **Granular Inspection**: Analyzes individual functions, classes, and tests
- **Pattern Recognition**: Identifies architectural violations (e.g., Logic in UI, Data in BLoC)
- **Formatting Enforcement**: Strict plain-text reporting optimized for Google Docs

### Analysis Categories

1.  **Testing Best Practices**
    - **Standards**: `flutter-testing.mdc`, `bloc-test.mdc`
    - **Focus**: Naming conventions, assertion specificity, atomic structure, BLoC testing patterns.

2.  **Architecture Compliance**
    - **Standards**: `flutter-architecture.mdc`, `flutter-ai-rules.mdc`
    - **Focus**: Layer boundaries, dependency injection, Repository pattern usage.

3.  **Code Standards & Models**
    - **Standards**: `dart-model-from-json.mdc`, `flutter-ai-rules.mdc`
    - **Focus**: JSON formatting, immutability, error handling, general styling.

## 📋 Usage

### Prerequisites
- Flutter SDK
- Dart SDK
- Cursor IDE (for running rules)
- Active Internet Connection (for fetching live standards)

### Quick Start

1.  **Navigate to the tool directory**:
    ```bash
    cd technology-tools/flutter_best_practices_check
    ```

2.  **Execute the Audit Plan**:
    Run the entire audit sequence using the predefined plan:
    ```bash
    # Execute via Antigravity or Cursor
    @plan/best_practices.plan.md
    ```

### Execution Order
The plan `@best_practices.plan.md` orchestrates the following sequence:

1.  `@testing_quality.yaml`
2.  `@architecture_compliance.yaml`
3.  `@code_standards.yaml`
4.  `@best_practices_format_enforcer.yaml` (Background validation)
5.  `@best_practices_generator.yaml`

## 📊 Report Format

The tool generates a **Plain Text** report optimized for Google Docs copying.

**Template**: `cursor_rules/templates/best_practices_report_template.txt`

### Sections
1.  **Executive Summary**: High-level health overview.
2.  **Detailed Sections**: Findings, violations, and recommendations for each category.
3.  **Prioritized Action Plan**: Concrete next steps.

### Formatting Rules
- **No Markdown**: Pure text output.
- **Scores**: Integers 0-10.
- **Labels**: Strong (9-10), Fair (7-8), Weak (0-6).

## 🔧 Configuration

### Standards Source
The tool is configured to fetch the latest standards directly from the Somnio Software GitHub repository:
- `https://github.com/somnio-software/cursor-rules`

This ensures that every audit is performed against the most up-to-date guidelines without requiring local updates.

## 🤝 Contributing

1.  Fork the repository
2.  Create feature branch
3.  Commit changes
4.  Push to branch
5.  Open Pull Request

### Development Guidelines
- Follow existing code structure
- Update documentation for new features
- Test with both single-app and multi-app repositories
- Maintain backward compatibility

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](../LICENSE) file for details.

## 🆘 Support

For questions, issues, or contributions:
- **Issues**: [GitHub Issues](https://github.com/somnio-software/technology-tools/issues)
- **Discussions**: [GitHub Discussions](https://github.com/somnio-software/technology-tools/discussions)
- **Pull Requests**: [GitHub Pull Requests](https://github.com/somnio-software/technology-tools/pulls)

## 🏢 About Somnio Software

This project is maintained by [Somnio Software](https://github.com/somnio-software), a company focused on delivering high-quality software solutions and development tools.

---

**Made with ❤️ by the Somnio Software team**
