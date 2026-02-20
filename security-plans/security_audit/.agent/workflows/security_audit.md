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
   Read `security_audit/cursor_rules/security_report_generator.yaml` and follow ALL instructions in the prompt field. Read ALL artifact files from `reports/.artifacts/` and the template at `security_audit/cursor_rules/templates/security_report_template.txt`. You MUST compute all 5 section scores using the scoring rubrics BEFORE writing any report content. A report without computed scores is INVALID. The report MUST include all 13 sections: Section 1 (Security Scoring Breakdown with 5 scores + weights + formula + posture), Section 2 (Executive Summary), scored Sections 3-7 (ordered by score ascending — lowest first), and supporting Sections 8-13. Every scored section MUST include Score, Score Breakdown, Key Findings, Evidence, Risks, and Recommendations.

7. **Validate and Export Report**
   Read `security_audit/cursor_rules/security_report_format_enforcer.yaml` and follow ALL instructions in the prompt field. Validate the generated report against ALL structural checks: exactly 13 sections, Section 1 has 5 scored lines with weights + Overall + Formula + Posture, Sections 3-7 each have Score lines with [Score]/100 ([Label]) format, Sections 3-7 are ordered by score ascending, score labels match score ranges (85-100=Strong, 70-84=Fair, 50-69=Weak, 0-49=Critical), no markdown syntax. If validation fails, fix the issues in-place. If scores are missing entirely, re-run step 6 before exporting. Save the final report to `reports/security_audit.txt`.
   ```bash
   mkdir -p reports
   ```
