<!-- 0b328ebf-1ad3-42f2-a0b4-28745c29c2f4 a910fd82-04ff-43e3-af54-da4e59d4dee0 -->
# Flutter Project Health Audit - Auto-Executable Plan

This plan executes the "Flutter Project Health Audit (MVP)" rule through sequential, actionable steps.

## Step 0. Flutter Environment Setup and Test Coverage Verification

Goal: Configure Flutter environment and execute tests with coverage verification.

Prompt:
```
First, execute the "Flutter Version Validator" rule to:
- Extract Flutter version from pubspec.yaml
- Verify FVM installation and setup
- Check current global Flutter version against project requirement
- Verify Flutter version availability via FVM
- Configure Flutter version globally (only if versions don't match)
- Clean project and install dependencies

CRITICAL: If any error occurs during Flutter version verification or installation:
- STOP execution immediately
- Display clear error message with specific actions to resolve the issue
- Provide exact commands needed to fix the problem
- Do not proceed to subsequent steps until Flutter environment is properly configured

Then, execute the "Flutter Test Coverage Runner" rule to:
- Run Flutter tests with coverage collection
- Generate coverage report (coverage/lcov.info)
- Calculate overall coverage percentage
- Verify if coverage meets 70% threshold

Save the coverage percentage and threshold verification for integration into the final audit report.
```

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

## Step 2. Core Configuration Files and Internationalization

Goal: Read and analyze Flutter/Dart configuration files for version info, dependencies, linter setup, and internationalization configuration.

Prompt:
```
Read completely and analyze:
- app/pubspec.yaml (Flutter version, Dart SDK, dependencies, dev_dependencies, especially very_good_analysis, flutter_localizations)
- app/analysis_options.yaml (includes, exclusions, rule overrides)
- Check for .fvm/fvm_config.json or .fvmrc (Flutter version management)
- Note presence of app/coverage_badge.svg
- Check for i18n configuration: app/l10n.yaml, app/lib/l10n/*.arb files
- Verify flutter_localizations dependency in pubspec.yaml
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
- Integrate coverage results from Step 0 (Flutter Test Coverage Verification)
- Include coverage percentage and threshold verification
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

Goal: Identify sensitive files, check .gitignore coverage across all project directories, find dependency scanning configuration.


Prompt:
```
Review security configuration:
- Find and read ALL .gitignore files in the project:
  * Root .gitignore (app/.gitignore)
  * Platform-specific .gitignore files:
    - android/.gitignore (specifically check for key.properties, **/*.keystore, **/*.jks patterns)
    - ios/.gitignore
    - web/.gitignore
    - windows/.gitignore
    - linux/.gitignore
    - macos/.gitignore
  * Package-specific .gitignore files:
    - packages/*/.gitignore (for each package directory)
  * Any other .gitignore files found in subdirectories
- List sensitive files present in repo: google-services.json, firebase_app_id_file.json, *.keystore, *.jks, any API keys
- For each sensitive file found, check if it's properly ignored across ALL .gitignore files:
  * Check exact filename patterns in all .gitignore files
  * Check file extension patterns (e.g., *.keystore, *.jks, *.json)
  * Check directory patterns (e.g., android/app/, ios/Runner/)
  * Check platform-specific patterns (e.g., android/keystore.properties, ios/Runner/GoogleService-Info.plist)
  * Specifically verify android/.gitignore contains the security block:
    - key.properties
    - **/*.keystore
    - **/*.jks
  * If *.keystore or *.jks files are found AND the security block exists in android/.gitignore = NO RISK (files are properly ignored)
  * If *.keystore or *.jks files are found BUT the security block is missing from android/.gitignore = SECURITY RISK
  * Files properly ignored in any relevant .gitignore = safe (not a risk)
  * Files not ignored in any relevant .gitignore = security risk
- Identify files with "copy" in name containing keys (mark as warning only, not risk)
- Check .github/dependabot.yaml for dependency automation
- Search workflows for secret scanning or deny-list patterns
- Only report as risks those sensitive files that are NOT properly covered by any relevant .gitignore patterns
- Document which .gitignore files were found and analyzed
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
- Check for onboarding documentation in any README files
- Look for l10n.yaml (internationalization config)
- Important: Do NOT recommend adding new languages or translations
```

## Step 8. Run Flutter Project Health Audit

Goal: Execute the "Flutter Project Health Audit (MVP)" rule over all collected evidence.

Prompt:
```
Apply the rule "Flutter Project Health Audit (MVP)" to generate the full report with:
- 9 section scores (0-100 integer): Tech Stack, Architecture, State Management, Repositories & Data Layer, Testing, Code Quality, Security, Documentation & Operations, CI/CD
- Weighted overall score using: CI/CD 0.22, Testing 0.22, Code Quality 0.18, Security 0.18, Architecture 0.10, Documentation 0.10
- ROUNDING RULE: Use standard mathematical rounding (0.5 rounds up). Do NOT apply subjective adjustments.
- Labels: 85-100=Strong, 70-84=Fair, 0-69=Weak
- Plain-text format ready for Google Docs (NO markdown syntax)
- All sections with: Description, Score, Key Findings, Evidence, Risks, Recommendations, Counts & Metrics
```

## Step 9. Overall Score Verification and Correction

Goal: Verify the Overall Score calculation and correct it if necessary before finalizing the report.

Prompt:
```
Verify the Overall Score calculation in the generated report:
- Check that the Overall Score uses the correct weighted formula: CI/CD 0.22, Testing 0.22, Code Quality 0.18, Security 0.18, Architecture 0.10, Documentation 0.10
- Calculate: overall_score = round( Σ(section_score × weight) )
- If the calculated Overall Score differs from the reported score, correct it
- Ensure the Overall Score is an integer value (0-100)
- Verify the label assignment: 85-100=Strong, 70-84=Fair, 0-69=Weak
- Update the Executive Summary with the correct Overall Score and interpretation
```

## Step 10. Resolve Unknowns and Finalize

Goal: Address any "Unknown" items by opening missing files, then regenerate affected sections if needed.

Prompt:
```
Review the generated report for any "Unknown" entries:
- If any section lists "Unknown" due to missing file/artifact, open that file
- Re-run the audit for affected sections
- Ensure all scores are integer values (0-100)
- Verify the overall weighted score calculation (use Step 9 verification)
- Confirm plain-text format with no markdown headings (use plain numbered/bulleted lists)
```

## Step 11. Export Final Report

Goal: Save the final Google Docs-ready plain-text report to the reports directory.

Prompt:
```
Create the reports directory if it doesn't exist and save the final Flutter Project Health Audit report to:
./reports/flutter_audit.txt

The report must include:
- Executive Summary with overall score
- At-a-Glance Scorecard with all 9 section scores
- All 9 detailed sections (including coverage analysis from Step 0)
- Additional Metrics (including coverage percentages)
- Quality Index
- Risks & Opportunities (5-8 bullets)
- Recommendations (6-10 prioritized actions)
- Appendix: Evidence Index

Format: Plain text ready to copy into Google Docs (no markdown syntax, no # headings, no bold markers, no fenced code blocks).

Execute the following command to create the directory and save the report:
```bash
mkdir -p reports
# Save report content to ./reports/flutter_audit.txt
```
```

