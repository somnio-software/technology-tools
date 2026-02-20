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
   Read `security_audit/cursor_rules/security_report_generator.yaml` and execute the instructions to generate the final security report. The report MUST include all 14 sections with quantitative scores computed from step artifacts. Verify the report contains Section 2 (At-a-Glance Scorecard), scored Sections 4-8 with Score Breakdowns, and Section 12 (Security Score Index) before proceeding.

7. **Validate and Export Report**
   Read `security_audit/cursor_rules/security_report_format_enforcer.yaml` and validate structural completeness first, then enforce formatting compliance. If the enforcer rejects the report due to missing scores or sections, re-run step 6 before attempting export again. Save the final report to `reports/security_audit.txt`.
   ```bash
   mkdir -p reports
   ```
