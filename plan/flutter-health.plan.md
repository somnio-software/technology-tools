<!-- 0b328ebf-1ad3-42f2-a0b4-28745c29c2f4 a910fd82-04ff-43e3-af54-da4e59d4dee0 -->
# Flutter Project Health Audit - Auto-Executable Plan

This plan executes the "Flutter Project Health Audit (MVP)" rule through sequential, actionable steps.

## Step 1. Repository Inventory

Goal: Detect repository structure, platform folders, monorepo packages, and feature organization.

Prompt:
```
List the following and provide counts:
- Platform folders present in app/ (android/, ios/, web/, macos/, windows/, linux/)
- All packages in app/packages/ directory (list names)
- All feature folders in app/lib/ (count directories, exclude gen/, l10n/, utils/, extensions/, constants/)
- Presence of .fvm/ directory or .fvm/fvm_config.json
```

## Step 2. Core Configuration Files

Goal: Read and analyze Flutter/Dart configuration files for version info, dependencies, and linter setup.

Prompt:
```
Read completely and analyze:
- app/pubspec.yaml (Flutter version, Dart SDK, dependencies, dev_dependencies, especially very_good_analysis)
- app/analysis_options.yaml (includes, exclusions, rule overrides)
- Check for .fvm/fvm_config.json or .fvmrc (Flutter version management)
- Note presence of app/coverage_badge.svg
```

## Step 3. CI/CD Workflows Analysis

Goal: Read all GitHub Actions workflows and related CI/CD configuration files.

Prompt:
```
Read and analyze ALL files in .github/:
- List all .github/workflows/*.yaml and .github/workflows/*.yml files
- Read each workflow file completely (main.yaml and all package-specific workflows)
- Read .github/dependabot.yaml
- Read .github/cspell.json
- Read .github/PULL_REQUEST_TEMPLATE.md
- For each workflow, identify: format checks, analyze steps, test steps, coverage thresholds, spell-check, release automation
- Verify monorepo naming: for each package in app/packages/<name>/, confirm .github/workflows/<name>.yaml exists
```

## Step 4. Testing Infrastructure

Goal: Find and classify all test files, identify coverage configuration and test types.

Prompt:
```
Search and classify testing setup:
- Find all *_test.dart files in app/test/ and app/packages/*/test/
- Count total test files
- Classify by type based on imports: bloc_test (uses bloc_test package), widget tests (uses testWidgets), unit tests (other)
- Search workflows for coverage enforcement (lcov, coverage threshold, --coverage flag)
- Look for test/ directory structure in main app and each package
```

## Step 5. Code Quality and Linter

Goal: Analyze linter configuration, exclusions, and code quality enforcement.

Prompt:
```
Analyze code quality setup:
- Confirm very_good_analysis version in app/pubspec.yaml dev_dependencies
- Review app/analysis_options.yaml: included package, exclusions list, rule overrides
- Search workflows for "flutter analyze" or "dart analyze" with fatal-infos or fatal-warnings flags
- Search workflows for "flutter format" or "dart format --set-exit-if-changed"
- Identify any stored analyzer output or linter warnings (if absent, mark as neutral)
```

## Step 6. Security Analysis

Goal: Identify sensitive files, check .gitignore coverage, find security policies and dependency scanning.

Prompt:
```
Review security configuration:
- Read app/.gitignore completely
- List sensitive files present in repo: google-services.json, firebase_app_id_file.json, *.keystore, *.jks, any API keys
- For each sensitive file, check if it's in .gitignore (ignored = safe, not ignored = risk)
- Identify files with "copy" in name containing keys (mark as warning only)
- Search for SECURITY.md file
- Search for CODEOWNERS file
- Check .github/dependabot.yaml for dependency automation
- Search workflows for secret scanning or deny-list patterns
```

## Step 7. Documentation and Operations

Goal: Review project documentation, build instructions, environment setup, and operational files.

Prompt:
```
Analyze documentation and operational setup:
- Read app/README.md completely
- Check README for build instructions and --dart-define usage for environment variables
- Check for app/sample.env.jsonc or .env.example
- Search for CHANGELOG.md or CHANGELOG
- Verify CODEOWNERS presence
- Check for onboarding documentation in any README files
- Look for l10n.yaml (internationalization config)
```

## Step 8. Run Flutter Project Health Audit

Goal: Execute the "Flutter Project Health Audit (MVP)" rule over all collected evidence.

Prompt:
```
Apply the rule "Flutter Project Health Audit (MVP)" to generate the full report with:
- 9 section scores (0-100 integer): Tech Stack, Architecture, State Management, Repositories & Data Layer, Testing, Code Quality, Security, Documentation & Operations, CI/CD
- Weighted overall score using: CI/CD 0.22, Testing 0.22, Code Quality 0.18, Security 0.18, Architecture 0.10, Documentation 0.10
- Labels: 85-100=Strong, 70-84=Fair, 0-69=Weak
- Plain-text format ready for Google Docs (NO markdown syntax)
- All sections with: Description, Score, Key Findings, Evidence, Risks, Recommendations, Counts & Metrics
```

## Step 9. Resolve Unknowns and Finalize

Goal: Address any "Unknown" items by opening missing files, then regenerate affected sections if needed.

Prompt:
```
Review the generated report for any "Unknown" entries:
- If any section lists "Unknown" due to missing file/artifact, open that file
- Re-run the audit for affected sections
- Ensure all scores are integer values (0-100)
- Verify the overall weighted score calculation
- Confirm plain-text format with no markdown headings (use plain numbered/bulleted lists)
```

## Step 10. Export Final Report

Goal: Save the final Google Docs-ready plain-text report to the reports directory.

Prompt:
```
Save the final Flutter Project Health Audit report to:
/Users/aclaveri/Development/daily-word/reports/flutter_audit.txt

The report must include:
- Executive Summary with overall score
- At-a-Glance Scorecard with all 9 section scores
- All 9 detailed sections
- Additional Metrics
- Quality Index
- Risks & Opportunities (5-8 bullets)
- Recommendations (6-10 prioritized actions)
- Appendix: Evidence Index

Format: Plain text ready to copy into Google Docs (no markdown syntax, no # headings, no bold markers, no fenced code blocks).
```

