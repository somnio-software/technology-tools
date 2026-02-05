# NestJS Report Templates

This directory contains template files used by the NestJS Project Health
Audit rules.

## Files

### nestjs_report_template.txt
Template showing exact format structure for NestJS audit reports. This
template is used by:
- `@nestjs_report_generator` - Main report generation rule
- `@nestjs_report_format_enforcer` - Format enforcement rule

The template defines the standardized 16-section structure that all
reports must follow.

## Usage

These templates are automatically referenced by the report generation
rules. You don't need to use them directly.

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

## Scoring System

### Weighted Overall Score
- **Level 1 (54%)**: Tech Stack (18%), Architecture (18%), API Design (18%)
- **Level 2 (40%)**: Data Layer (10%), Testing (10%), Code Quality (10%),
  Security (10%)
- **Level 3 (6%)**: Documentation (3%), CI/CD (3%)

### Score Labels
- **Strong**: 85-100
- **Fair**: 70-84
- **Weak**: 0-69

## NestJS-Specific Metrics

The Additional Metrics section includes NestJS-specific information:
- Node.js version
- NestJS version
- TypeScript version
- Package manager (npm/yarn/pnpm)
- Monorepo tool (nx/turborepo/lerna/none)
- Total modules count
- Total controllers count
- Total services count
- Total DTOs count
- API type (REST/GraphQL/Hybrid)
- OpenAPI/Swagger status
- Database ORM
- Authentication method