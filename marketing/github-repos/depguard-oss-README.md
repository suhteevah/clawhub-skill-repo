# depguard

<p align="center">
  <img src="https://img.shields.io/badge/package_managers-10-blue" alt="10 package managers">
  <img src="https://img.shields.io/badge/license-MIT-green" alt="MIT License">
  <img src="https://img.shields.io/badge/install-clawhub-blue" alt="ClawHub">
  <img src="https://img.shields.io/badge/zero-telemetry-brightgreen" alt="Zero telemetry">
</p>

<h3 align="center">Dependency audit, vulnerability scanning, and license compliance.</h3>

<p align="center">
  <a href="https://depguard.pages.dev">Website</a> &middot;
  <a href="#quick-start">Quick Start</a> &middot;
  <a href="#supported-package-managers">Package Managers</a> &middot;
  <a href="https://depguard.pages.dev/#pricing">Pricing</a>
</p>

---

## The Problem

Every dependency is an attack surface. A single vulnerable package can compromise your entire application. And license compliance? Most teams don't even check until legal asks.

**DepGuard scans your dependencies for vulnerabilities, enforces license policies, and generates SBOMs — all locally.**

## Quick Start

```bash
# Install via ClawHub (free)
clawhub install depguard

# Scan for vulnerabilities
depguard scan

# Generate a security report
depguard report

# Auto-fix vulnerable packages (Pro)
depguard fix

# Install git hooks (Pro)
depguard hooks install

# Generate SBOM (Team)
depguard sbom

# Check license compliance (Team)
depguard compliance
```

## Supported Package Managers

| Manager | Lockfile | Audit Tool |
|---------|----------|------------|
| **npm** | package-lock.json | npm audit |
| **yarn** | yarn.lock | yarn audit |
| **pnpm** | pnpm-lock.yaml | pnpm audit |
| **pip** | requirements.txt | pip-audit |
| **cargo** | Cargo.lock | cargo audit |
| **go** | go.sum | govulncheck |
| **composer** | composer.lock | composer audit |
| **bundler** | Gemfile.lock | bundle audit |
| **maven** | pom.xml | dependency-check |
| **gradle** | build.gradle | dependencyCheck |

## What It Does

### Vulnerability Scanning
Uses native audit tools (npm audit, pip-audit, cargo audit, govulncheck) for accurate, up-to-date vulnerability detection. No proprietary database — uses the same sources your package managers trust.

### License Compliance
Categorizes every dependency license:
- **Permissive** (MIT, Apache, BSD) — low risk
- **Copyleft** (GPL, AGPL) — high risk for proprietary projects
- **Unknown** — critical, needs investigation

### SBOM Generation
Produces CycloneDX 1.5 JSON SBOMs for compliance and audit requirements.

### Git Hook Protection
Pre-commit hooks scan lockfile changes for new vulnerabilities before they reach your codebase.

## Pricing

| Feature | Free | Pro ($19/user/mo) | Team ($39/user/mo) |
|---------|:----:|:------------------:|:-------------------:|
| Vulnerability scan | ✓ | ✓ | ✓ |
| License detection | ✓ | ✓ | ✓ |
| Markdown report | ✓ | ✓ | ✓ |
| Git hooks | | ✓ | ✓ |
| Auto-fix | | ✓ | ✓ |
| Continuous monitoring | | ✓ | ✓ |
| License policy enforcement | | | ✓ |
| SBOM generation | | | ✓ |
| Compliance reports | | | ✓ |

## Privacy

- 100% local — no code or dependency data sent externally
- Zero telemetry
- Offline license validation

## License

MIT
