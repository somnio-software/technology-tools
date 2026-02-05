# Somnio Technology Tools

A centralized repository for Somnio Software's technology department containing all tools developed to accelerate project analysis, improve code quality, and optimize development processes.

## 🎯 Purpose

This repository's main objectives are:

- **Centralize tools**: Keep all analysis and development tools in one place
- **Accelerate analysis**: Provide automated tools to evaluate project health
- **Improve quality**: Establish consistent development standards and processes
- **Optimize processes**: Automate repetitive analysis and auditing tasks
- **Facilitate maintenance**: Create reusable and scalable tools

## 🛠️ Available Tools

This repository contains technology-specific auditing and analysis tools organized by technology stack:

### Flutter Plans
Comprehensive auditing and best practices validation tools for Flutter/Dart projects.

**Location**: `flutter-plans/`

**Documentation**: See `flutter-plans/README.md` for detailed information about available Flutter tools and usage instructions.

### NestJS Plans
Auditing system for NestJS backend and cloud functions projects.

**Location**: `nestjs-plans/`

**Documentation**: See `nestjs-plans/README.md` for current status and TODO items.

### NestJS Project Health Audit
Complete auditing system for NestJS/Node.js backend projects that includes:

- **Automated analysis**: 9 analysis categories with scoring (Tech Stack, Architecture, API Design, Data Layer, Testing, Code Quality, Security, Documentation, CI/CD)
- **Monorepo support**: Handles single-app and monorepo structures (nx, turborepo, lerna, custom)
- **Standardized reports**: 16-section format ready for Google Docs
- **API design analysis**: REST/GraphQL validation, DTOs, OpenAPI/Swagger documentation
- **Security analysis**: Authentication/authorization patterns, OWASP Top 10 compliance
- **Test coverage**: Execution, aggregation, and 70% minimum threshold validation
- **ChatGPT integration**: Specialized prompt for generating executive summaries

**Location**: `nestjs-plans/nestjs_project_health_audit/`

**Documentation**: See `nestjs-plans/nestjs_project_health_audit/README.md` for detailed instructions.

## 📁 Repository Structure

```
technology-tools/
├── flutter-plans/                        # Flutter-related plans and tools
│   ├── flutter_project_health_audit/    # Flutter auditing system
│   ├── flutter_best_practices_check/     # Micro-level code auditing
│   └── README.md                         # Flutter tools documentation
├── nestjs-plans/                        # NestJS-related plans and tools
│   └── README.md                        # NestJS tools documentation
└── README.md                            # This file
```

## 🚀 Quick Start

### For Flutter projects

Navigate to the Flutter plans directory and follow the instructions in the Flutter README:

```bash
cd flutter-plans/
# See flutter-plans/README.md for detailed instructions
```

### For NestJS projects

Navigate to the NestJS plans directory and check the current status:

```bash
cd nestjs-plans/
# See nestjs-plans/README.md for current status and TODO items
```

### For NestJS Health Audit
```bash
# Navigate to the specific tool
cd nestjs-plans/nestjs_project_health_audit/

# Follow instructions in the specific README
# See nestjs-plans/nestjs_project_health_audit/README.md
```

### For new tools

1. Create new folder with descriptive name (e.g., `react/`, `nodejs/`)
2. Include complete documentation in README.md within the folder
3. Update this main README with the new tool category

## 🔧 Development

### Adding new tools

1. Create folder with descriptive name
2. Include complete documentation in README.md within the folder
3. Update this main README with the new tool category
4. Follow established documentation standards

### Documentation standards

- Complete README.md in each technology folder
- Clear usage instructions
- Practical examples
- Documented file structure
- Tool-specific details should be in the technology folder's README

## 📈 Roadmap

- [x] Flutter Project Health Audit
- [x] Flutter Best Practices Check
- [ ] NestJS Project Health Audit (Backend)
- [ ] NestJS Project Health Audit (Cloud Functions)
- [ ] Tools for React/Next.js project analysis
- [ ] Security analysis tools
- [ ] Deployment automation
- [ ] Performance and quality metrics

## 🤝 Contributing

1. Fork the repository
2. Create feature branch: `git checkout -b feature/new-tool`
3. Commit changes: `git commit -m 'Add new tool'`
4. Push to branch: `git push origin feature/new-tool`
5. Open Pull Request

### Development guidelines

- Follow established folder structure
- Document each tool completely in its technology folder
- Include usage examples
- Maintain backward compatibility

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

For questions, issues, or contributions:
- **Issues**: [GitHub Issues](https://github.com/somnio-software/technology-tools/issues)
- **Discussions**: [GitHub Discussions](https://github.com/somnio-software/technology-tools/discussions)
- **Pull Requests**: [GitHub Pull Requests](https://github.com/somnio-software/technology-tools/pulls)

## 🏢 About Somnio Software

This project is maintained by [Somnio Software](https://github.com/somnio-software), a company focused on delivering high-quality software solutions and development tools.

---

**Made with ❤️ by the Somnio Software team**
