# gitpulse

<p align="center">
  <img src="https://img.shields.io/badge/score-0--100-blue" alt="0-100 scoring">
  <img src="https://img.shields.io/badge/license-MIT-green" alt="MIT License">
  <img src="https://img.shields.io/badge/install-clawhub-blue" alt="ClawHub">
  <img src="https://img.shields.io/badge/zero-telemetry-brightgreen" alt="Zero telemetry">
</p>

<h3 align="center">Your repo is a 47/100. Here's why.</h3>

<p align="center">
  <a href="https://gitpulse.pages.dev">Website</a> &middot;
  <a href="#quick-start">Quick Start</a> &middot;
  <a href="#what-it-scores">What It Scores</a> &middot;
  <a href="https://gitpulse.pages.dev/#pricing">Pricing</a>
</p>

---

## The Problem

You merge a PR. Tests pass. Ship it. But nobody checked if the README has an install section. Nobody noticed the CODEOWNERS file is missing. Nobody saw that 3 dependencies are 8 months old. Nobody looked at the CI config running without timeouts or pinned action versions.

**Your code passes CI. Your repo fails hygiene.**

GitPulse gives every repository a health score from 0 to 100 across five categories: repo basics, git hygiene, CI/CD health, dependency management, and documentation quality. One command. One number. Actionable fixes.

## Quick Start

```bash
# 1. Install via ClawHub (free)
clawhub install gitpulse

# 2. Score your repo
gitpulse score

# 3. See the output
#    GitPulse Health Score: 73/100 (B — Good)
#    ...with category breakdown and quick wins
```

That's it. No config. No cloud. No signup.

## What It Scores

GitPulse evaluates five categories, each worth 20 points:

```
GitPulse Health Score: 73/100 (B — Good)

Category Breakdown:
  Repository Basics:   15/20 ███████████████░░░░░
  Git Hygiene:         18/20 ██████████████████░░
  CI/CD Health:        12/20 ████████████░░░░░░░░
  Dependency Health:   16/20 ████████████████░░░░
  Documentation:       12/20 ████████████░░░░░░░░

Top Issues:
  !  Missing CODEOWNERS file (-3 pts)
  !  No security scanning in CI (-3 pts)
  !  3 dependencies outdated >6 months (-4 pts)
  !  Missing architecture documentation (-3 pts)

Quick Wins (highest impact):
  1. Update stale dependencies (+4 pts)
  2. Add CODEOWNERS file (+3 pts)
  3. Add security scanning to CI (+3 pts)
```

### Repository Basics (20 pts)

README, LICENSE, .gitignore, CONTRIBUTING.md, SECURITY.md, CODEOWNERS, CODE_OF_CONDUCT.md, .editorconfig, CHANGELOG.md

### Git Hygiene (20 pts)

No large files (>5MB), no tracked .env files, no secrets in commits, branch naming conventions, conventional commits, no merge commits on main

### CI/CD Health (20 pts)

CI config exists, tests run, linting runs, security scanning, build step, Dependabot/Renovate configured

### Dependency Health (20 pts)

Lockfile exists, no critical vulnerabilities, dependencies up to date, license compliance, no unused dependencies

### Documentation (20 pts)

Installation section, usage section, contributing section, API docs, no stale docs, status badges, architecture docs

## Comparison

| Feature | GitPulse | SonarQube | CodeClimate | Codacy |
|---------|:--------:|:---------:|:-----------:|:------:|
| **Repo hygiene scoring** | Yes | No | No | No |
| **CI workflow linting** | Yes | No | No | No |
| **Runs 100% locally** | Yes | Self-host only | No | No |
| **Zero config** | Yes | No | No | No |
| **Git hook integration** | Yes | No | No | No |
| **Dependency health** | Yes | Plugin | No | Yes |
| **Compliance checks** | Yes | Enterprise | No | No |
| **CI cost estimation** | Yes | No | No | No |
| **Free tier** | Generous | Community | Limited | Limited |
| **Privacy** | 100% local | Depends | Cloud | Cloud |

GitPulse is not a code quality tool. It is a **repo quality** tool. SonarQube tells you about bugs in your code. GitPulse tells you about problems in your repository.

## Pricing

| Feature | Free | Pro ($19/mo) | Team ($39/mo) |
|---------|:----:|:------------:|:-------------:|
| Health score (0-100) | Yes | Yes | Yes |
| Quick health check | Yes | Yes | Yes |
| Pre-push health gate | | Yes | Yes |
| CI workflow linting | | Yes | Yes |
| Stale branch cleanup | | Yes | Yes |
| Full health report | | | Yes |
| SOC2/HIPAA compliance | | | Yes |
| CI cost estimation | | | Yes |

**Free tier works immediately** with zero configuration. Score any repo, any language, any framework.

## All Commands

```bash
# Free
gitpulse score [dir]          # Full health score with breakdown
gitpulse check [dir]          # Quick pass/fail check (exit code)

# Pro ($19/user/month)
gitpulse hooks install        # Pre-push health gate
gitpulse hooks uninstall      # Remove hooks
gitpulse lint-ci [dir]        # Lint CI workflows
gitpulse stale [dir]          # Find stale branches & files

# Team ($39/user/month)
gitpulse report [dir]         # Full markdown health report
gitpulse compliance [dir]     # SOC2/HIPAA compliance checks
gitpulse cost [dir]           # GitHub Actions cost estimation

# Utility
gitpulse status               # Show license info
gitpulse --help               # Show help
gitpulse --version            # Show version
```

## Cross-Skill Integration

GitPulse gets smarter when used alongside other ClawHub skills:

- **DepGuard** — Feeds real vulnerability and license data into the dependency health score
- **DocSync** — Feeds real drift detection into the documentation quality score
- **EnvGuard** — Feeds real secret scanning into the git hygiene score

Without these skills, GitPulse falls back to its own built-in checks. With them, the scores are more precise.

## Privacy

- **100% local processing** — your code never leaves your machine
- **Zero telemetry** — no analytics, no tracking, no phone-home
- **Offline license validation** — works in air-gapped environments
- No cloud. No account. No signup.

## CI Integration

Use GitPulse as a CI gate:

```yaml
# .github/workflows/health.yml
name: Repo Health
on: [push, pull_request]

jobs:
  health-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Health Check
        run: |
          bash gitpulse/scripts/gitpulse.sh check .
```

The `check` command returns exit code 1 if the score is below 60, failing the CI job.

## License

MIT
