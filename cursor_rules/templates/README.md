# Templates Directory

This directory contains template files used by the Flutter Project Health Audit rules.

## Files

### `flutter_report_template.txt`
- **Purpose**: Template showing the exact format structure for Flutter Project Health Audit reports
- **Usage**: Reference for the `flutter_report_format_enforcer.yaml` rule
- **Format**: Plain text template with placeholders for dynamic content
- **Sections**: 16 mandatory sections in exact order

## Usage

The template file serves as a visual reference for:
1. **Report Structure**: Shows the exact 16-section structure
2. **Format Consistency**: Demonstrates proper formatting rules
3. **Content Placeholders**: Shows where dynamic content should be inserted
4. **Validation**: Helps verify report completeness

## Integration

The template is referenced by:
- `flutter_report_format_enforcer.yaml` - Enforces the template structure
- `flutter_report_generator.yaml` - Uses template format for generation
- `flutter_project_health_audit.yaml` - Follows template structure

## Format Rules

- **NO Markdown**: Plain text only
- **NO Bold**: No bold markers
- **NO Code Fences**: No code blocks
- **NO Tables**: Bullet points only
- **Headers**: "X. Section Name" format
- **Scores**: "[Score]/100 ([Label])" format
- **Labels**: "Strong" (85-100), "Fair" (70-84), "Weak" (0-69)
