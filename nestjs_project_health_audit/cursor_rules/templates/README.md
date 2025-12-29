# NestJS Report Templates

This directory contains template files used by the NestJS Project Health Audit rules.

## Files

### nestjs_report_template.txt
Template showing exact format structure for NestJS audit reports. This template is used by:
- `@nestjs_report_generator` - Main report generation rule
- `@nestjs_report_format_enforcer` - Format enforcement rule

The template defines the standardized 16-section structure that all reports must follow.

## Usage

These templates are automatically referenced by the report generation rules. You don't need to use them directly.

## Format Rules

- **Plain Text**: No markdown syntax
- **Consistent Structure**: All sections follow the same format
- **Google Docs Ready**: Copy-paste friendly
- **Monorepo Support**: Handles single-app and monorepo repositories

## Template Structure

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


