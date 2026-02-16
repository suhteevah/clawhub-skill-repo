---
name: gitpulse
description: Repo health scoring — CI hygiene, branch protection, stale cleanup, and compliance checks
homepage: https://gitpulse.pages.dev
metadata:
  {
    "openclaw": {
      "emoji": "📊",
      "primaryEnv": "GITPULSE_LICENSE_KEY",
      "requires": {
        "bins": ["git", "bash"]
      },
      "install": [
        {
          "id": "lefthook",
          "kind": "brew",
          "formula": "lefthook",
          "bins": ["lefthook"],
          "label": "Install lefthook (git hooks manager)"
        }
      ],
      "os": ["darwin", "linux", "win32"]
    }
  }
user-invocable: true
disable-model-invocation: false
---

# GitPulse — Repo Health Scoring & CI Hygiene

GitPulse calculates a 0-100 health score for any git repository by analyzing repository basics, git hygiene, CI/CD configuration, dependency health, and documentation quality. It integrates with lefthook for pre-push health gates and can cross-reference other ClawHub skills (DepGuard, DocSync) for deeper analysis.

## Commands

### Free Tier (No license required)

#### `gitpulse score [directory]`
Calculate a one-shot health score (0-100) for any repository with category breakdown and actionable recommendations.

**How to execute:**
```bash
bash "<SKILL_DIR>/scripts/gitpulse.sh" score [directory]
```

**What it does:**
1. Scans repository for key files (README, LICENSE, CODEOWNERS, .gitignore, etc.)
2. Analyzes git history for hygiene issues (large files, secrets, commit conventions)
3. Inspects CI/CD configuration for best practices
4. Checks dependency health (lockfiles, outdated packages, license compliance)
5. Evaluates documentation quality (installation, usage, API docs, badges)
6. Outputs a scored report with letter grade and top issues

**Example usage scenarios:**
- "Score this repo's health" -> runs `gitpulse score .`
- "Check the health of my project" -> runs `gitpulse score .`
- "Rate my repo" -> runs `gitpulse score .`

#### `gitpulse check [directory]`
Quick health check — lightweight pass/fail for CI gates.

**How to execute:**
```bash
bash "<SKILL_DIR>/scripts/gitpulse.sh" check [directory]
```

**What it does:**
1. Runs the same scoring engine as `score` but with streamlined output
2. Returns exit code 0 if score >= 60 (passing), exit code 1 otherwise
3. Lists only critical issues that need immediate attention

### Pro Tier ($19/user/month — requires GITPULSE_LICENSE_KEY)

#### `gitpulse hooks install`
Install a pre-push hook that blocks pushes when repo health is below threshold.

**How to execute:**
```bash
bash "<SKILL_DIR>/scripts/gitpulse.sh" hooks install
```

**What it does:**
1. Validates Pro+ license
2. Copies lefthook config to project root
3. Installs lefthook pre-push hook
4. On every push: runs health score, blocks if below configured threshold (default: 60)

#### `gitpulse hooks uninstall`
Remove GitPulse git hooks.

```bash
bash "<SKILL_DIR>/scripts/gitpulse.sh" hooks uninstall
```

#### `gitpulse lint-ci [directory]`
Lint CI workflow files (GitHub Actions, GitLab CI, etc.) for best practices.

**How to execute:**
```bash
bash "<SKILL_DIR>/scripts/gitpulse.sh" lint-ci [directory]
```

**What it does:**
1. Validates Pro+ license
2. Finds all CI configuration files (.github/workflows/*.yml, .gitlab-ci.yml, Jenkinsfile)
3. Checks for: missing timeout-minutes, unpinned action versions, missing permissions block, hardcoded secrets, missing concurrency, deprecated actions, no caching, missing fail-fast on matrix builds
4. Outputs lint results with severity and fix recommendations

#### `gitpulse stale [directory]`
Find stale branches, PRs, and issues in the repository.

**How to execute:**
```bash
bash "<SKILL_DIR>/scripts/gitpulse.sh" stale [directory]
```

**What it does:**
1. Validates Pro+ license
2. Lists branches with no commits in >30 days
3. Lists merged branches that haven't been deleted
4. Detects orphaned branches
5. Reports overall staleness metrics

### Team Tier ($39/user/month — requires GITPULSE_LICENSE_KEY with team tier)

#### `gitpulse report [directory]`
Generate a full health report as a markdown document.

**How to execute:**
```bash
bash "<SKILL_DIR>/scripts/gitpulse.sh" report [directory]
```

**What it does:**
1. Validates Team+ license
2. Runs the complete scoring engine
3. Generates a detailed markdown report with all categories, scores, issues, and remediation steps
4. Writes report to HEALTH-REPORT.md in the target directory

#### `gitpulse compliance [directory]`
Run compliance checks aligned with SOC2 and HIPAA basics.

**How to execute:**
```bash
bash "<SKILL_DIR>/scripts/gitpulse.sh" compliance [directory]
```

**What it does:**
1. Validates Team+ license
2. Checks for SECURITY.md, branch protection indicators, signed commits, access control files
3. Checks for audit logging, incident response docs, data handling policies
4. Generates a compliance checklist with pass/fail/missing status

#### `gitpulse cost [directory]`
Estimate GitHub Actions CI/CD costs based on workflow configuration.

**How to execute:**
```bash
bash "<SKILL_DIR>/scripts/gitpulse.sh" cost [directory]
```

**What it does:**
1. Validates Team+ license
2. Parses GitHub Actions workflow files
3. Estimates minutes per run based on job configuration
4. Projects monthly costs based on estimated run frequency
5. Suggests optimizations to reduce CI spend

## Score Breakdown

GitPulse evaluates five categories, each worth 20 points (100 total):

| Category | Weight | What It Checks |
|----------|--------|----------------|
| Repository Basics | 20 pts | README, LICENSE, .gitignore, CODEOWNERS, SECURITY.md, CONTRIBUTING.md, etc. |
| Git Hygiene | 20 pts | Large files, tracked secrets, commit conventions, merge commits |
| CI/CD Health | 20 pts | CI config exists, tests, linting, security scanning, dependabot |
| Dependency Health | 20 pts | Lockfiles, vulnerabilities, outdated deps, license compliance |
| Documentation | 20 pts | Install/usage docs, API docs, badges, architecture docs |

### Grades
- **A+ (90-100):** Excellent — production-ready, well-maintained
- **A (80-89):** Great — minor improvements possible
- **B (70-79):** Good — some gaps to address
- **C (60-69):** Needs Work — significant issues
- **D (50-59):** Poor — major problems
- **F (0-49):** Critical — immediate attention required

## Configuration

Users can configure GitPulse in `~/.openclaw/openclaw.json`:

```json
{
  "skills": {
    "entries": {
      "gitpulse": {
        "enabled": true,
        "apiKey": "YOUR_LICENSE_KEY_HERE",
        "config": {
          "minScore": 60,
          "excludeCategories": [],
          "staleBranchDays": 30,
          "stalePRDays": 14,
          "maxFileSizeMB": 5,
          "commitConvention": "conventional"
        }
      }
    }
  }
}
```

## Cross-Skill Integration

GitPulse integrates with other ClawHub skills when available:

- **DepGuard**: Uses `depguard scan` results for dependency health scoring (vulnerability and license checks)
- **DocSync**: Uses `docsync drift` results for documentation quality scoring (stale docs detection)
- **EnvGuard**: Uses secret scanning results for git hygiene scoring

When these skills are not installed, GitPulse falls back to its own built-in checks (less detailed but functional).

## Important Notes

- **Free tier** works immediately with no configuration
- **All processing happens locally** — no code is sent to external servers
- **License validation is offline** — no network calls needed
- Git hooks use **lefthook** which must be installed (see install metadata above)
- Works on any git repository regardless of language or framework
- Scoring is deterministic — same repo state always produces the same score

## Error Handling

- If not inside a git repository, show clear error message
- If lefthook is not installed and user tries `hooks install`, prompt to install it
- If license key is invalid or expired, show clear message with link to https://gitpulse.pages.dev/renew
- If a category has no applicable checks (e.g., no CI config), score that category proportionally

## When to Use GitPulse

The user might say things like:
- "How healthy is this repo?"
- "Score my repository"
- "Check my CI configuration"
- "Find stale branches"
- "Are there any repo hygiene issues?"
- "Generate a health report"
- "Set up pre-push health checks"
- "Check compliance for SOC2"
- "How much are my GitHub Actions costing?"
- "Lint my CI workflows"
