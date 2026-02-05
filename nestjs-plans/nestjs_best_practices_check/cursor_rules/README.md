# NestJS Best Practices Check - Cursor Rules

This directory contains YAML rule files for the NestJS Best Practices Check tool.

## Rules Index

| Rule File | Match Pattern | Purpose |
|-----------|---------------|---------|
| `testing_quality.yaml` | `**/*.spec.ts` | Analyze test naming, assertions, mocking, structure |
| `architecture_compliance.yaml` | `**/*.ts` | Validate layer boundaries, DI patterns, module organization |
| `code_standards.yaml` | `**/*.ts` | Check TypeScript patterns, naming conventions, NestJS best practices |
| `dto_validation.yaml` | `**/*.dto.ts` | Review validation decorators, Swagger docs, transformation patterns |
| `error_handling.yaml` | `**/*.ts` | Assess exception usage, error enums, logging practices |
| `best_practices_format_enforcer.yaml` | `*` | Enforce plain-text report format |
| `best_practices_generator.yaml` | `**/*_audit.txt` | Consolidate findings into final report |

## Standards References

Each rule validates against live standards from the cursor-rules repository:

```
https://github.com/somnio-software/cursor-rules/tree/main/.cursor/rules/nestjs/
```

| Standard File | Referenced By |
|---------------|---------------|
| `nestjs-testing-unit.mdc` | `testing_quality.yaml` |
| `nestjs-testing-integration.mdc` | `testing_quality.yaml` |
| `nestjs-module-structure.mdc` | `architecture_compliance.yaml` |
| `nestjs-service-patterns.mdc` | `architecture_compliance.yaml` |
| `nestjs-repository-patterns.mdc` | `architecture_compliance.yaml` |
| `nestjs-typescript.mdc` | `code_standards.yaml` |
| `nestjs-dto-validation.mdc` | `dto_validation.yaml` |
| `nestjs-error-handling.mdc` | `error_handling.yaml` |

## Templates

The `templates/` directory contains:

- `best_practices_report_template.txt` - Plain-text report template for final output

## Usage

Reference rules in Cursor using the `@` syntax:

```
@testing_quality.yaml
@architecture_compliance.yaml
@code_standards.yaml
@dto_validation.yaml
@error_handling.yaml
```

Follow the execution plan at `../plan/best_practices.plan.md` for proper sequencing.
