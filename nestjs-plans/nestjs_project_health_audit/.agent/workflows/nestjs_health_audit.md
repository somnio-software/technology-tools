---
description: Automated NestJS Project Health Audit
---

# NestJS Project Health Audit Workflow

// turbo-all

1. **Environment Setup**
   Read `nestjs_project_health_audit/cursor_rules/nestjs_tool_installer.yaml` and execute the instructions to install necessary tools.

2. **Version Alignment**
   Read `nestjs_project_health_audit/cursor_rules/nestjs_version_alignment.yaml` and execute the instructions to align Node.js versions.

3. **Version Validation**
   Read `nestjs_project_health_audit/cursor_rules/nestjs_version_validator.yaml` and execute the instructions to validate the setup.

4. **Test Coverage**
   Read `nestjs_project_health_audit/cursor_rules/nestjs_test_coverage.yaml` and execute the instructions to generate test coverage.

5. **Repository Inventory**
   Read `nestjs_project_health_audit/cursor_rules/nestjs_repository_inventory.yaml` and execute the instructions to analyze the repository structure.

6. **Config Analysis**
   Read `nestjs_project_health_audit/cursor_rules/nestjs_config_analysis.yaml` and execute the instructions to analyze configuration files.

7. **CI/CD Analysis**
   Read `nestjs_project_health_audit/cursor_rules/nestjs_cicd_analysis.yaml` and execute the instructions to analyze CI/CD workflows.

8. **Testing Analysis**
   Read `nestjs_project_health_audit/cursor_rules/nestjs_testing_analysis.yaml` and execute the instructions to analyze testing infrastructure.

9. **Code Quality**
   Read `nestjs_project_health_audit/cursor_rules/nestjs_code_quality.yaml` and execute the instructions to analyze code quality.

10. **Security Analysis**
    Read `nestjs_project_health_audit/cursor_rules/nestjs_security_analysis.yaml` and execute the instructions to analyze security.

11. **API Design Analysis**
    Read `nestjs_project_health_audit/cursor_rules/nestjs_api_design_analysis.yaml` and execute the instructions to analyze API design.

12. **Data Layer Analysis**
    Read `nestjs_project_health_audit/cursor_rules/nestjs_data_layer_analysis.yaml` and execute the instructions to analyze the data layer.

13. **Documentation Analysis**
    Read `nestjs_project_health_audit/cursor_rules/nestjs_documentation_analysis.yaml` and execute the instructions to analyze documentation.

14. **Generate Report**
    Read `nestjs_project_health_audit/cursor_rules/nestjs_report_generator.yaml` and execute the instructions to generate the final report.

15. **Export Report**
    Ensure the final report generated in the previous step is saved to `reports/nestjs_audit.txt`.
    ```bash
    mkdir -p reports
    ```

16. **Optional Best Practices Check**
    Ask the user if they want to execute the Best Practices Check.

    Workflow: `nestjs_best_practices_check/.agent/workflows/nestjs_best_practices.md`

    **CRITICAL**: NEVER execute this automatically. MUST wait for user confirmation.