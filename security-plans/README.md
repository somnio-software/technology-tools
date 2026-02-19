# Security Tools

Framework-agnostic security auditing tools developed by Somnio Software to
detect vulnerabilities, exposed secrets, and dependency risks across any
project type.

## 🎯 Purpose

This directory contains security-focused tools designed to:

- **Detect vulnerabilities**: Automated scanning for secrets, credentials,
  and sensitive file exposure
- **Audit dependencies**: Run native package manager vulnerability scans
  across any technology stack
- **Adapt to any project**: Auto-detect Flutter, NestJS, Node.js, Go, Rust,
  Python, or generic projects at runtime
- **Generate reports**: Create severity-classified, actionable security
  reports for project stakeholders

## 🛠️ Available Tools

### Security Audit

Standalone, framework-agnostic security audit that detects the project type
at runtime and adapts checks accordingly. Can be run independently or after
a health audit.

- **Framework-agnostic**: Auto-detects Flutter, NestJS, Node.js, Go, Rust,
  Python, or generic projects
- **Sensitive file analysis**: Scans for exposed credentials, API keys,
  keystores, and checks .gitignore coverage
- **Source code secret scanning**: Detects hardcoded secrets, tokens,
  passwords, and cloud credentials in source code
- **Dependency vulnerability audit**: Runs native package manager scans
  (`npm audit`, `pub outdated`, `pip audit`, `cargo audit`, etc.)
- **Gemini AI analysis (optional)**: Leverages Gemini CLI with the security
  extension for advanced vulnerability detection
- **Severity-classified reports**: Findings categorized as HIGH, MEDIUM,
  LOW with a remediation priority matrix
- **Modular execution**: 6 sequential rules, each independently executable

**Location**: `security_audit/`

**Documentation**: See `security_audit/plan/security.plan.md` for the
detailed execution plan.

## 📁 Directory Structure

```
security-plans/
├── security_audit/                     # Security auditing system
│   ├── plan/                           # Execution plan
│   │   └── security.plan.md            # Modular execution plan
│   ├── cursor_rules/                   # Analysis rules (YAML)
│   │   ├── security_tool_installer.yaml
│   │   ├── security_file_analysis.yaml
│   │   ├── security_secret_patterns.yaml
│   │   ├── security_dependency_audit.yaml
│   │   ├── security_gemini_analysis.yaml
│   │   ├── security_report_generator.yaml
│   │   ├── security_report_format_enforcer.yaml
│   │   └── templates/
│   │       └── security_report_template.txt
│   ├── .agent/workflows/               # Antigravity workflow
│   │   └── security_audit.md
│   └── env/                            # Environment variable template
│       └── copy.env
└── README.md                           # This file
```

## 🚀 Quick Start

### Option 1: Via CLI (Recommended)

Run the security audit from any project root. The CLI handles setup,
pre-flight checks, and step-by-step execution:

```bash
# From the target project root
somnio run sa
```

### Option 2: Via IDE Skill

Use the installed slash command in Claude Code or Cursor:

```bash
# Claude Code
/somnio-sa

# Cursor
# Available as a command in the command palette
```

### Option 3: Via Antigravity Workflow

The `.agent/workflows/security_audit.md` workflow is available after
installing with `somnio antigravity`.

### Gemini AI Analysis (Optional)

To enable the optional AI-powered security analysis step, either:

1. Set `GEMINI_API_KEY` in your environment (see `security_audit/env/copy.env`)
2. Or sign in with `gemini auth login` (Google One AI Premium subscription)

If Gemini CLI is unavailable, the audit skips this step gracefully and
continues with the remaining checks.

## 📋 Prerequisites

- Git repository with a supported project type
- Somnio CLI installed (`dart pub global activate --source git ...`)
- AI CLI available: Claude Code (`claude`), Cursor CLI (`agent`), or
  Gemini CLI (`gemini`)
- **Optional**: `GEMINI_API_KEY` or Google subscription for AI-powered
  analysis

## 🔍 Audit Steps

The security audit executes 6 modular rules in sequence:

| Step | Rule | Description |
|------|------|-------------|
| 1 | `security_tool_installer` | Detect project type and available tools |
| 2 | `security_file_analysis` | Scan for sensitive files and .gitignore gaps |
| 3 | `security_secret_patterns` | Search source code for hardcoded secrets |
| 4 | `security_dependency_audit` | Run native package manager vulnerability scans |
| 5 | `security_gemini_analysis` | AI-powered vulnerability detection (optional) |
| 6 | `security_report_generator` | Synthesize findings into final report |

**Report output**: `./reports/security_audit.txt`

## 🔧 Development

### Adding new security rules

1. Create a new YAML rule file in `security_audit/cursor_rules/`
2. Follow the existing naming convention: `security_{rule_name}.yaml`
3. Update the execution plan in `security_audit/plan/security.plan.md`
4. Update the Antigravity workflow in
   `security_audit/.agent/workflows/security_audit.md`
5. Update this README with the new rule

### Documentation standards

- Complete documentation in each rule's YAML description
- Clear bash commands with error handling
- Documented file structure
- Practical examples

### Code Quality Standards

All YAML rule files follow strict formatting standards:
- **Line Length**: Maximum 80 characters per line
- **Formatting**: Commands split using shell continuation (`\`)
- **Descriptions**: Use folded scalar format (`>`) for multi-line text
- **Readability**: Optimized for maintainability and consistency

## 📈 Roadmap

- [x] Framework-Agnostic Security Audit
- [x] Gemini AI-Powered Analysis (optional step)
- [ ] SAST (Static Application Security Testing) integration
- [ ] Container security scanning
- [ ] Infrastructure-as-Code security checks

## 🤝 Contributing

1. Fork the repository
2. Create feature branch: `git checkout -b feature/new-security-tool`
3. Commit changes: `git commit -m 'Add new security tool'`
4. Push to branch: `git push origin feature/new-security-tool`
5. Open Pull Request

### Development guidelines

- Follow established folder structure
- Document each rule completely
- Include usage examples
- Maintain backward compatibility
- Test with multiple project types (Flutter, NestJS, Node.js, etc.)

## 📝 License

This project is licensed under the MIT License - see the
[LICENSE](../LICENSE) file for details.

## 🆘 Support

For questions, issues, or contributions:
- **Issues**: [GitHub Issues](https://github.com/somnio-software/technology-tools/issues)
- **Discussions**: [GitHub Discussions](https://github.com/somnio-software/technology-tools/discussions)
- **Pull Requests**: [GitHub Pull Requests](https://github.com/somnio-software/technology-tools/pulls)

## 🏢 About Somnio Software

This project is maintained by
[Somnio Software](https://github.com/somnio-software), a company focused on
delivering high-quality software solutions and development tools.

---

**Made with ❤️ by the Somnio Software team**
