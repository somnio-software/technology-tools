---
description: Framework-Agnostic Security Audit
---

# Security Audit Workflow

// turbo-all

1. **Tool Detection**
   Read `security_audit/cursor_rules/security_tool_installer.yaml` and execute the instructions to detect tools and project type.

2. **Sensitive File Analysis**
   Read `security_audit/cursor_rules/security_file_analysis.yaml` and execute the instructions to analyze sensitive files and .gitignore coverage.

3. **Secret Pattern Scanning**
   Read `security_audit/cursor_rules/security_secret_patterns.yaml` and execute the instructions to scan source code for secret patterns.

4. **Dependency Vulnerability Audit**
   Read `security_audit/cursor_rules/security_dependency_audit.yaml` and execute the instructions to audit dependency vulnerabilities.

5. **Gemini AI Analysis (Optional)**
   Read `security_audit/cursor_rules/security_gemini_analysis.yaml` and execute the instructions to perform AI-powered security analysis. Skip if Gemini CLI is unavailable.

6. **Generate Security Report**
   Read `security_audit/cursor_rules/security_report_generator.yaml` and execute the instructions to generate the final security report.

7. **Export Report**
   Read `security_audit/cursor_rules/security_report_format_enforcer.yaml` and ensure formatting compliance. Save the final report to `reports/security_audit.txt`.
   ```bash
   mkdir -p reports
   ```
