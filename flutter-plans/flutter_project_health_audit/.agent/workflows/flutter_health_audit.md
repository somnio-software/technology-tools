---
description: Automated Flutter Project Health Audit
---

# Flutter Project Health Audit Workflow

// turbo-all

1. **Environment Setup**
   Read `flutter_project_health_audit/cursor_rules/flutter_tool_installer.yaml` and execute the instructions to install necessary tools.

2. **Version Alignment**
   Read `flutter_project_health_audit/cursor_rules/flutter_version_alignment.yaml` and execute the instructions to align Flutter versions.

3. **Version Validation**
   Read `flutter_project_health_audit/cursor_rules/flutter_version_validator.yaml` and execute the instructions to validate the setup.

4. **Test Coverage**
   Read `flutter_project_health_audit/cursor_rules/flutter_test_coverage.yaml` and execute the instructions to generate test coverage.

5. **Repository Inventory**
   Read `flutter_project_health_audit/cursor_rules/flutter_repository_inventory.yaml` and execute the instructions to analyze the repository structure.

6. **Config Analysis**
   Read `flutter_project_health_audit/cursor_rules/flutter_config_analysis.yaml` and execute the instructions to analyze configuration files.

7. **CI/CD Analysis**
   Read `flutter_project_health_audit/cursor_rules/flutter_cicd_analysis.yaml` and execute the instructions to analyze CI/CD workflows.

8. **Testing Analysis**
   Read `flutter_project_health_audit/cursor_rules/flutter_testing_analysis.yaml` and execute the instructions to analyze testing infrastructure.

9. **Code Quality**
   Read `flutter_project_health_audit/cursor_rules/flutter_code_quality.yaml` and execute the instructions to analyze code quality.

10. **Documentation Analysis**
    Read `flutter_project_health_audit/cursor_rules/flutter_documentation_analysis.yaml` and execute the instructions to analyze documentation.

11. **Generate Report**
    Read `flutter_project_health_audit/cursor_rules/flutter_report_generator.yaml` and execute the instructions to generate the final report.

12. **Export Report**
    Ensure the final report generated in the previous step is saved to `reports/flutter_audit.txt`.
    ```bash
    mkdir -p reports
    ```

13. **Optional Best Practices Check**
    Ask the user if they want to execute the Best Practices Check.

    Workflow: `flutter_best_practices_check/.agent/workflows/flutter_best_practices.md`

    **CRITICAL**: NEVER execute this automatically. MUST wait for user confirmation.
