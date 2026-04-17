---
name: SchemaLint
version: 1.0.0
description: "Database schema & query anti-pattern analyzer -- detects missing indexes, type safety issues, naming violations, constraint gaps, dangerous query patterns, and unsafe migration practices"
homepage: https://schemalint.pages.dev
metadata:
  {
    "openclaw": {
      "emoji": "\ud83d\uddc4\ufe0f",
      "primaryEnv": "SCHEMALINT_LICENSE_KEY",
      "requires": {
        "bins": ["git", "bash", "python3", "jq"]
      },
      "configPaths": ["~/.openclaw/openclaw.json"],
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

# SchemaLint -- Database Schema & Query Anti-Pattern Analyzer

SchemaLint scans codebases for database schema design issues, query anti-patterns, and data modeling problems. It detects missing indexes, type safety violations, naming convention issues, constraint gaps, dangerous query patterns, and unsafe migration practices. It uses regex-based pattern matching against 90 database-specific patterns across 6 categories, lefthook for git hook integration, and produces markdown reports with actionable remediation guidance. 100% local. Zero telemetry.

## Commands

### Free Tier (No license required)

#### `schemalint scan [file|directory]`
One-shot database schema quality scan of files or directories.

**How to execute:**
```bash
bash "<SKILL_DIR>/scripts/dispatcher.sh" --path [target]
```

**What it does:**
1. Accepts a file path or directory (defaults to current directory)
2. Discovers all source files (skips .git, node_modules, binaries, images, .min.js)
3. Runs 30 schema quality patterns against each file (free tier limit)
4. Calculates a schema quality score (0-100) per file and overall
5. Grades: A (90-100), B (80-89), C (70-79), D (60-69), F (<60)
6. Outputs findings with: file, line number, check ID, severity, description, recommendation
7. Exit code 0 if score >= 70, exit code 1 if schema quality is poor
8. Free tier limited to first 30 patterns (IX + TY categories)

**Example usage scenarios:**
- "Scan my code for database issues" -> runs `schemalint scan .`
- "Check this file for schema anti-patterns" -> runs `schemalint scan src/schema.sql`
- "Find missing indexes" -> runs `schemalint scan src/`
- "Audit database schema in my project" -> runs `schemalint scan .`
- "Check for SQL injection risks" -> runs `schemalint scan .`

### Pro Tier ($19/user/month -- requires SCHEMALINT_LICENSE_KEY)

#### `schemalint scan --tier pro [file|directory]`
Extended scan with 60 patterns covering indexing, type safety, naming conventions, and relationship constraints.

**How to execute:**
```bash
bash "<SKILL_DIR>/scripts/dispatcher.sh" --path [target] --tier pro
```

**What it does:**
1. Validates Pro+ license
2. Runs 60 schema patterns (IX, TY, NM, RL categories)
3. Detects naming convention violations (reserved words, CamelCase)
4. Identifies missing constraints and relationship issues
5. Full category breakdown reporting

#### `schemalint scan --format json [directory]`
Generate JSON output for CI/CD integration.

```bash
bash "<SKILL_DIR>/scripts/dispatcher.sh" --path [directory] --format json
```

#### `schemalint scan --format html [directory]`
Generate HTML report for browser viewing.

```bash
bash "<SKILL_DIR>/scripts/dispatcher.sh" --path [directory] --format html
```

#### `schemalint scan --category IX [directory]`
Filter scan to a specific check category (IX, TY, NM, RL, QP, MG).

```bash
bash "<SKILL_DIR>/scripts/dispatcher.sh" --path [directory] --category IX
```

### Team Tier ($39/user/month -- requires SCHEMALINT_LICENSE_KEY with team tier)

#### `schemalint scan --tier team [directory]`
Full scan with all 90 patterns across all 6 categories including query patterns and migration safety.

**How to execute:**
```bash
bash "<SKILL_DIR>/scripts/dispatcher.sh" --path [directory] --tier team
```

**What it does:**
1. Validates Team+ license
2. Runs all 90 patterns across 6 categories
3. Includes query pattern checks (SELECT *, SQL injection, N+1 setup)
4. Includes migration safety checks (DROP COLUMN, destructive ALTER TABLE)
5. Full category breakdown with per-file results

#### `schemalint scan --verbose [directory]`
Verbose output showing every matched line and pattern details.

```bash
bash "<SKILL_DIR>/scripts/dispatcher.sh" --path [directory] --verbose
```

#### `schemalint status`
Show license and configuration information.

```bash
bash "<SKILL_DIR>/scripts/dispatcher.sh" status
```

## Check Categories

SchemaLint detects 90 database anti-patterns across 6 categories:

| Category | Code | Patterns | Description | Severity Range |
|----------|------|----------|-------------|----------------|
| **Indexing Issues** | IX | 15 | Missing indexes on foreign keys, over-indexing, function calls on indexed columns, full table scan risks | medium -- high |
| **Type Safety** | TY | 15 | VARCHAR(255) default, FLOAT for money, INT for booleans, TEXT for short fields, JSON as TEXT | medium -- critical |
| **Naming Conventions** | NM | 15 | Reserved word table names, CamelCase identifiers, ambiguous column names like data or value | low -- high |
| **Relationships & Constraints** | RL | 15 | Missing ON DELETE, no NOT NULL, missing foreign key constraints, circular references, contradictory defaults | low -- critical |
| **Query Patterns** | QP | 15 | SELECT *, SQL injection via concatenation, no LIMIT, ORDER BY RAND(), NOT IN with NULL | medium -- critical |
| **Migration Safety** | MG | 15 | DROP COLUMN without backup, NOT NULL without DEFAULT, TRUNCATE TABLE, destructive ALTER TABLE | low -- critical |

## Tier-Based Pattern Access

| Tier | Patterns | Categories |
|------|----------|------------|
| **Free** | 30 | IX, TY |
| **Pro** | 60 | IX, TY, NM, RL |
| **Team** | 90 | IX, TY, NM, RL, QP, MG |
| **Enterprise** | 90 | IX, TY, NM, RL, QP, MG + priority support |

## Scoring

SchemaLint uses a deductive scoring system starting at 100 (perfect):

| Severity | Point Deduction | Description |
|----------|-----------------|-------------|
| **Critical** | -25 per finding | Severe issue (SQL injection, data loss from DROP, FLOAT for money) |
| **High** | -15 per finding | Significant quality problem (missing indexes, wrong types, reserved words) |
| **Medium** | -8 per finding | Moderate concern (VARCHAR(255) default, missing NOT NULL) |
| **Low** | -3 per finding | Informational / best practice suggestion |

### Grading Scale

| Grade | Score Range | Meaning |
|-------|-------------|---------|
| **A** | 90-100 | Excellent schema quality |
| **B** | 80-89 | Good quality with minor issues |
| **C** | 70-79 | Acceptable but needs improvement |
| **D** | 60-69 | Poor schema quality |
| **F** | Below 60 | Critical database problems |

- **Pass threshold:** 70 (Grade C or better)
- Exit code 0 = pass (score >= 70)
- Exit code 1 = fail (score < 70)

## Configuration

Users can configure SchemaLint in `~/.openclaw/openclaw.json`:

```json
{
  "skills": {
    "entries": {
      "schemalint": {
        "enabled": true,
        "apiKey": "YOUR_LICENSE_KEY_HERE",
        "config": {
          "severityThreshold": "medium",
          "ignorePatterns": ["**/test/**", "**/fixtures/**", "**/*.test.*"],
          "ignoreChecks": [],
          "reportFormat": "text"
        }
      }
    }
  }
}
```

## Important Notes

- **Free tier** works immediately with no configuration
- **All scanning happens locally** -- no code is sent to external servers
- **License validation is offline** -- no phone-home or network calls
- Pattern matching only -- no AST parsing, no external dependencies beyond bash
- Supports scanning all file types in a single pass (SQL, ORM files, migration scripts)
- Git hooks use **lefthook** which must be installed (see install metadata above)
- Exit codes: 0 = pass (score >= 70), 1 = fail (for CI/CD integration)
- Output formats: text (default), json, html

## Error Handling

- If lefthook is not installed and user tries hooks, prompt to install it
- If license key is invalid or expired, show clear message with link to https://schemalint.pages.dev/renew
- If a file is binary, skip it automatically with no warning
- If no scannable files found in target, report clean scan with info message
- If an invalid category is specified with --category, show available categories

## When to Use SchemaLint

The user might say things like:
- "Scan my code for database issues"
- "Check my database schema"
- "Find missing indexes"
- "Detect SQL injection risks"
- "Are there any schema anti-patterns?"
- "Check for missing foreign key constraints"
- "Audit my database schema"
- "Find type safety issues in my SQL"
- "Check for unsafe migrations"
- "Scan for query anti-patterns"
- "Run a schema quality audit"
- "Generate a schema quality report"
- "Check if I'm using FLOAT for money"
- "Find SELECT * queries in my code"
- "Check my migration files for dangerous operations"
