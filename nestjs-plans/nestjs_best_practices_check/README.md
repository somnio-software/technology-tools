# NestJS Best Practices Check

A micro-level code quality audit tool for NestJS applications. This tool analyzes individual functions, classes, and test files against Somnio Software's established best practices and coding standards.

## Overview

The NestJS Best Practices Check performs deep analysis of code quality at the implementation level, complementing the macro-level [NestJS Project Health Audit](../nestjs_project_health_audit/README.md).

**Scope**: Code-level analysis including:
- Testing quality and coverage
- Architecture compliance
- TypeScript/NestJS coding standards
- DTO validation patterns
- Error handling consistency

## Tool Structure

```
nestjs_best_practices_check/
├── cursor_rules/
│   ├── testing_quality.yaml           # Test file analysis
│   ├── architecture_compliance.yaml   # Layer separation validation
│   ├── code_standards.yaml            # TypeScript/NestJS patterns
│   ├── dto_validation.yaml            # DTO structure analysis
│   ├── error_handling.yaml            # Exception handling review
│   ├── best_practices_format_enforcer.yaml  # Report format rules
│   ├── best_practices_generator.yaml  # Final report aggregation
│   └── templates/
│       └── best_practices_report_template.txt
├── plan/
│   └── best_practices.plan.md         # Execution plan
└── README.md
```

## Analysis Categories

### 1. Testing Quality
Evaluates unit and integration test patterns:
- Test naming conventions
- Assertion quality and coverage
- Mock setup and cleanup
- Arrange-Act-Assert structure
- Database test isolation

### 2. Architecture Compliance
Validates layered architecture adherence:
- Controller → Service → Repository boundaries
- Dependency injection patterns
- Module organization
- Abstract repository pattern
- Single responsibility principle

### 3. Code Standards
Analyzes TypeScript and NestJS patterns:
- Type safety and strict mode
- Naming conventions (PascalCase, camelCase, kebab-case)
- Function design (size, RO-RO pattern, early returns)
- NestJS decorators and providers

### 4. DTO Validation
Reviews DTO implementation quality:
- class-validator decorator coverage
- class-transformer patterns
- Swagger documentation completeness
- Response DTO security (no sensitive data)

### 5. Error Handling
Assesses error handling consistency:
- NestJS exception usage
- Error enums and message maps
- Exception filter implementation
- Logging practices

## Usage

### Prerequisites
- NestJS project with TypeScript
- Cursor IDE with rules enabled

### Quick Start

1. Open your NestJS project in Cursor
2. Reference the plan file: `@nestjs_best_practices_check/plan/best_practices.plan.md`
3. Execute the analysis steps sequentially
4. Review the generated plain-text report

### Execution Order

```
1. @testing_quality.yaml
2. @architecture_compliance.yaml
3. @code_standards.yaml
4. @dto_validation.yaml
5. @error_handling.yaml
6. @best_practices_format_enforcer.yaml
7. @best_practices_generator.yaml
```

## Standards Source

All analysis rules validate against live standards from:
`https://github.com/somnio-software/cursor-rules/tree/main/.cursor/rules/nestjs/`

| Standard | Purpose |
|----------|---------|
| `nestjs-dto-validation.mdc` | DTO structure and validation |
| `nestjs-service-patterns.mdc` | Service layer patterns |
| `nestjs-controller-patterns.mdc` | Controller decorators and guards |
| `nestjs-repository-patterns.mdc` | Repository pattern implementation |
| `nestjs-testing-unit.mdc` | Unit test patterns |
| `nestjs-testing-integration.mdc` | Integration test patterns |
| `nestjs-error-handling.mdc` | Exception handling |
| `nestjs-module-structure.mdc` | Module organization |
| `nestjs-typescript.mdc` | TypeScript standards |

## Scoring System

Each category is scored 0-100 with labels:
- **Strong**: 85-100
- **Fair**: 70-84
- **Weak**: 0-69

**Weighted Overall Score**:
- Testing Quality: 20%
- Architecture Compliance: 25%
- Code Standards: 20%
- DTO Validation: 15%
- Error Handling: 20%

## Report Format

Reports use **plain text only** for copy-paste compatibility with Google Docs:
- No markdown syntax
- Consistent section structure
- File path references with line numbers
- Prioritized recommendations

## Related Tools

- [NestJS Project Health Audit](../nestjs_project_health_audit/README.md) - Macro-level infrastructure analysis
- [Flutter Best Practices Check](../../flutter-plans/flutter_best_practices_check/README.md) - Flutter equivalent

## Contributing

To contribute standards or rules:
1. Update `.mdc` files in the cursor-rules repository
2. Ensure YAML rules reference the latest standards
3. Test against a sample NestJS project
4. Submit PR with evidence of testing

## Support

For questions or issues:
- GitHub Issues: [technology-tools repository]
- Standards Updates: [cursor-rules repository]
