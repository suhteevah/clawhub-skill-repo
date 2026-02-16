#!/usr/bin/env bash
# GitPulse — Health Score Engine
# Calculates a 0-100 repo health score across 5 categories

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# ─── Issue tracking ──────────────────────────────────────────────────────────

declare -a ISSUES=()
declare -a QUICK_WINS=()

add_issue() {
  local points="$1" message="$2"
  ISSUES+=("$points|$message")
}

add_quick_win() {
  local points="$1" message="$2"
  QUICK_WINS+=("$points|$message")
}

# ─── Progress bar rendering ──────────────────────────────────────────────────

render_bar() {
  local score="$1" max="$2" width=20
  local filled=$((score * width / max))
  local empty=$((width - filled))
  local bar=""

  local color="$GREEN"
  local pct=$((score * 100 / max))
  if [[ $pct -lt 50 ]]; then color="$RED"
  elif [[ $pct -lt 70 ]]; then color="$YELLOW"
  elif [[ $pct -lt 85 ]]; then color="$BLUE"
  fi

  local i
  for ((i = 0; i < filled; i++)); do bar+="█"; done
  for ((i = 0; i < empty; i++)); do bar+="░"; done

  echo -e "${color}${bar}${NC}"
}

# ─── Grade calculation ────────────────────────────────────────────────────────

get_grade() {
  local score="$1"
  if   [[ $score -ge 90 ]]; then echo "A+ — Excellent"
  elif [[ $score -ge 80 ]]; then echo "A — Great"
  elif [[ $score -ge 70 ]]; then echo "B — Good"
  elif [[ $score -ge 60 ]]; then echo "C — Needs Work"
  elif [[ $score -ge 50 ]]; then echo "D — Poor"
  else echo "F — Critical"
  fi
}

get_grade_letter() {
  local score="$1"
  if   [[ $score -ge 90 ]]; then echo "A+"
  elif [[ $score -ge 80 ]]; then echo "A"
  elif [[ $score -ge 70 ]]; then echo "B"
  elif [[ $score -ge 60 ]]; then echo "C"
  elif [[ $score -ge 50 ]]; then echo "D"
  else echo "F"
  fi
}

get_grade_color() {
  local score="$1"
  if   [[ $score -ge 80 ]]; then echo "$GREEN"
  elif [[ $score -ge 60 ]]; then echo "$YELLOW"
  else echo "$RED"
  fi
}

# ─── Category 1: Repository Basics (20 points) ──────────────────────────────

score_repo_basics() {
  local dir="$1"
  local score=0

  # README.md exists (3 pts)
  if [[ -f "$dir/README.md" || -f "$dir/readme.md" || -f "$dir/README" || -f "$dir/README.rst" ]]; then
    score=$((score + 3))
  else
    add_issue 3 "Missing README.md file"
    add_quick_win 3 "Add a README.md file"
  fi

  # LICENSE file exists (3 pts)
  if [[ -f "$dir/LICENSE" || -f "$dir/LICENSE.md" || -f "$dir/LICENSE.txt" || -f "$dir/LICENCE" || -f "$dir/COPYING" ]]; then
    score=$((score + 3))
  else
    add_issue 3 "Missing LICENSE file"
    add_quick_win 3 "Add a LICENSE file"
  fi

  # .gitignore exists (2 pts)
  if [[ -f "$dir/.gitignore" ]]; then
    score=$((score + 2))
  else
    add_issue 2 "Missing .gitignore file"
    add_quick_win 2 "Add a .gitignore file"
  fi

  # CONTRIBUTING.md exists (2 pts)
  if [[ -f "$dir/CONTRIBUTING.md" || -f "$dir/contributing.md" || -f "$dir/.github/CONTRIBUTING.md" ]]; then
    score=$((score + 2))
  else
    add_issue 2 "Missing CONTRIBUTING.md file"
  fi

  # SECURITY.md exists (2 pts)
  if [[ -f "$dir/SECURITY.md" || -f "$dir/security.md" || -f "$dir/.github/SECURITY.md" ]]; then
    score=$((score + 2))
  else
    add_issue 2 "Missing SECURITY.md file"
    add_quick_win 2 "Add a SECURITY.md file"
  fi

  # CODEOWNERS exists (3 pts)
  if [[ -f "$dir/CODEOWNERS" || -f "$dir/.github/CODEOWNERS" || -f "$dir/docs/CODEOWNERS" ]]; then
    score=$((score + 3))
  else
    add_issue 3 "Missing CODEOWNERS file"
    add_quick_win 3 "Add a CODEOWNERS file"
  fi

  # CODE_OF_CONDUCT.md exists (1 pt)
  if [[ -f "$dir/CODE_OF_CONDUCT.md" || -f "$dir/.github/CODE_OF_CONDUCT.md" ]]; then
    score=$((score + 1))
  else
    add_issue 1 "Missing CODE_OF_CONDUCT.md file"
  fi

  # .editorconfig exists (2 pts)
  if [[ -f "$dir/.editorconfig" ]]; then
    score=$((score + 2))
  else
    add_issue 2 "Missing .editorconfig file"
  fi

  # CHANGELOG.md exists (2 pts)
  if [[ -f "$dir/CHANGELOG.md" || -f "$dir/changelog.md" || -f "$dir/CHANGES.md" || -f "$dir/HISTORY.md" ]]; then
    score=$((score + 2))
  else
    add_issue 2 "Missing CHANGELOG.md file"
  fi

  echo "$score"
}

# ─── Category 2: Git Hygiene (20 points) ─────────────────────────────────────

score_git_hygiene() {
  local dir="$1"
  local score=0

  # Must be a git repo
  if ! git -C "$dir" rev-parse --git-dir &>/dev/null; then
    echo "0"
    add_issue 20 "Not a git repository"
    return
  fi

  # No large files (>5MB) in recent commits (4 pts)
  local large_files
  large_files=$(git -C "$dir" log --all --diff-filter=d --name-only --format="" -50 2>/dev/null | \
    sort -u | while IFS= read -r f; do
      [[ -z "$f" ]] && continue
      if [[ -f "$dir/$f" ]]; then
        local size
        size=$(wc -c < "$dir/$f" 2>/dev/null || echo 0)
        if [[ $size -gt 5242880 ]]; then
          echo "$f"
        fi
      fi
    done)
  if [[ -z "$large_files" ]]; then
    score=$((score + 4))
  else
    local count
    count=$(echo "$large_files" | wc -l | tr -d ' ')
    add_issue 4 "$count large files (>5MB) detected in repository"
  fi

  # No .env files tracked (4 pts)
  local tracked_env
  tracked_env=$(git -C "$dir" ls-files 2>/dev/null | grep -E '\.env$|\.env\.' | head -5 || true)
  if [[ -z "$tracked_env" ]]; then
    score=$((score + 4))
  else
    add_issue 4 "Tracked .env files found: $(echo "$tracked_env" | tr '\n' ', ' | sed 's/,$//')"
    add_quick_win 4 "Remove .env files from git tracking"
  fi

  # No secrets detected in recent commits (4 pts)
  local secrets_found=false
  local secret_patterns='(AKIA[0-9A-Z]{16}|-----BEGIN.*PRIVATE KEY-----|sk_live_[a-zA-Z0-9]+|ghp_[a-zA-Z0-9]+|xox[bpras]-[a-zA-Z0-9-]+)'
  local recent_diff
  recent_diff=$(git -C "$dir" log --all -10 --diff-filter=A -p 2>/dev/null | \
    grep -E "$secret_patterns" 2>/dev/null | head -3 || true)
  if [[ -z "$recent_diff" ]]; then
    score=$((score + 4))
  else
    secrets_found=true
    add_issue 4 "Potential secrets detected in recent commits"
    add_quick_win 4 "Remove secrets from git history (use git filter-branch or BFG)"
  fi

  # Branch naming convention followed (2 pts)
  local bad_branches=0
  local branch_pattern='^(main|master|develop|release|hotfix|feature|bugfix|fix|chore|docs|test|ci)(/[a-zA-Z0-9._-]+)*$'
  while IFS= read -r branch; do
    branch=$(echo "$branch" | sed 's|refs/heads/||; s|^[* ]*||; s| *$||')
    [[ -z "$branch" ]] && continue
    if ! echo "$branch" | grep -qE "$branch_pattern"; then
      ((bad_branches++)) || true
    fi
  done < <(git -C "$dir" branch 2>/dev/null)
  if [[ $bad_branches -eq 0 ]]; then
    score=$((score + 2))
  else
    add_issue 2 "$bad_branches branches do not follow naming conventions"
  fi

  # Commit message convention — conventional commits (3 pts)
  local total_commits=0 conventional_commits=0
  local cc_pattern='^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\(.+\))?!?:'
  while IFS= read -r msg; do
    [[ -z "$msg" ]] && continue
    ((total_commits++)) || true
    if echo "$msg" | grep -qE "$cc_pattern"; then
      ((conventional_commits++)) || true
    fi
  done < <(git -C "$dir" log --format="%s" -20 2>/dev/null)
  if [[ $total_commits -gt 0 ]]; then
    local cc_pct=$((conventional_commits * 100 / total_commits))
    if [[ $cc_pct -ge 80 ]]; then
      score=$((score + 3))
    elif [[ $cc_pct -ge 50 ]]; then
      score=$((score + 1))
      add_issue 2 "Only ${cc_pct}% of recent commits follow conventional commit format"
    else
      add_issue 3 "Only ${cc_pct}% of recent commits follow conventional commit format"
    fi
  else
    score=$((score + 3))  # No commits yet, don't penalize
  fi

  # No merge commits on main/master (3 pts)
  local default_branch
  default_branch=$(git -C "$dir" symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||' || \
    git -C "$dir" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")
  local merge_commits
  merge_commits=$(git -C "$dir" log "$default_branch" --merges --oneline -20 2>/dev/null | wc -l | tr -d ' ' || echo 0)
  if [[ $merge_commits -le 2 ]]; then
    score=$((score + 3))
  elif [[ $merge_commits -le 5 ]]; then
    score=$((score + 1))
    add_issue 2 "$merge_commits merge commits found on $default_branch (consider rebasing)"
  else
    add_issue 3 "$merge_commits merge commits found on $default_branch (consider rebasing)"
  fi

  echo "$score"
}

# ─── Category 3: CI/CD Health (20 points) ────────────────────────────────────

score_ci_health() {
  local dir="$1"
  local score=0

  # CI config exists (4 pts)
  local has_ci=false
  local ci_files=""
  if [[ -d "$dir/.github/workflows" ]]; then
    ci_files=$(find "$dir/.github/workflows" -name "*.yml" -o -name "*.yaml" 2>/dev/null | head -10)
    [[ -n "$ci_files" ]] && has_ci=true
  fi
  [[ -f "$dir/.gitlab-ci.yml" ]] && has_ci=true
  [[ -f "$dir/Jenkinsfile" ]] && has_ci=true
  [[ -f "$dir/.circleci/config.yml" ]] && has_ci=true
  [[ -f "$dir/.travis.yml" ]] && has_ci=true
  [[ -f "$dir/azure-pipelines.yml" ]] && has_ci=true
  [[ -f "$dir/bitbucket-pipelines.yml" ]] && has_ci=true

  if [[ "$has_ci" == "true" ]]; then
    score=$((score + 4))
  else
    add_issue 4 "No CI/CD configuration found"
    add_quick_win 4 "Add CI/CD configuration (e.g., .github/workflows/ci.yml)"
    echo "$score"
    return
  fi

  # Read all CI files for analysis
  local ci_content=""
  if [[ -n "$ci_files" ]]; then
    ci_content=$(cat $ci_files 2>/dev/null || true)
  fi
  [[ -f "$dir/.gitlab-ci.yml" ]] && ci_content+=$(cat "$dir/.gitlab-ci.yml" 2>/dev/null || true)

  # CI runs tests (4 pts)
  if echo "$ci_content" | grep -qiE '(npm test|yarn test|pnpm test|pytest|cargo test|go test|mvn test|gradle test|jest|mocha|vitest|rspec|phpunit|dotnet test)'; then
    score=$((score + 4))
  else
    add_issue 4 "CI does not appear to run tests"
    add_quick_win 4 "Add test step to CI workflow"
  fi

  # CI runs linting (3 pts)
  if echo "$ci_content" | grep -qiE '(eslint|prettier|black|flake8|pylint|ruff|clippy|golangci-lint|rubocop|php-cs-fixer|lint|stylelint|standardrb)'; then
    score=$((score + 3))
  else
    add_issue 3 "CI does not appear to run linting"
  fi

  # CI has security scanning step (3 pts)
  if echo "$ci_content" | grep -qiE '(codeql|snyk|trivy|grype|dependabot|renovate|semgrep|bandit|brakeman|gosec|npm audit|safety check|cargo audit|govulncheck|sonarqube|sonarcloud|checkmarx)'; then
    score=$((score + 3))
  else
    add_issue 3 "No security scanning in CI"
    add_quick_win 3 "Add security scanning to CI (e.g., CodeQL, Snyk, Trivy)"
  fi

  # CI has build step (3 pts)
  if echo "$ci_content" | grep -qiE '(npm run build|yarn build|pnpm build|cargo build|go build|mvn package|gradle build|docker build|make build|tsc|webpack|vite build|next build)'; then
    score=$((score + 3))
  else
    add_issue 3 "CI does not appear to have a build step"
  fi

  # Dependabot/Renovate config exists (3 pts)
  if [[ -f "$dir/.github/dependabot.yml" || -f "$dir/.github/dependabot.yaml" || \
        -f "$dir/renovate.json" || -f "$dir/renovate.json5" || -f "$dir/.renovaterc" || \
        -f "$dir/.renovaterc.json" ]]; then
    score=$((score + 3))
  else
    add_issue 3 "No automated dependency update config (Dependabot/Renovate)"
    add_quick_win 3 "Add .github/dependabot.yml for automated dependency updates"
  fi

  echo "$score"
}

# ─── Category 4: Dependency Health (20 points) ───────────────────────────────

score_dependency_health() {
  local dir="$1"
  local score=0

  # Package lockfile exists and up to date (4 pts)
  local has_lockfile=false
  local lockfiles=(
    "package-lock.json" "yarn.lock" "pnpm-lock.yaml"
    "Cargo.lock" "go.sum" "composer.lock" "Gemfile.lock"
    "Pipfile.lock" "poetry.lock" "pdm.lock"
  )
  local manifests=(
    "package.json" "Cargo.toml" "go.mod" "composer.json" "Gemfile"
    "Pipfile" "pyproject.toml" "requirements.txt"
  )

  local has_manifest=false
  for m in "${manifests[@]}"; do
    if [[ -f "$dir/$m" ]]; then
      has_manifest=true
      break
    fi
  done

  if [[ "$has_manifest" == "false" ]]; then
    # No package manager detected — give full marks (not applicable)
    echo "20"
    return
  fi

  for lf in "${lockfiles[@]}"; do
    if [[ -f "$dir/$lf" ]]; then
      has_lockfile=true
      break
    fi
  done

  if [[ "$has_lockfile" == "true" ]]; then
    score=$((score + 4))
  else
    add_issue 4 "Package lockfile missing — dependencies are not pinned"
    add_quick_win 4 "Generate a lockfile (npm install, cargo generate-lockfile, etc.)"
  fi

  # No known critical vulnerabilities — call depguard if available (4 pts)
  local depguard_skill="${HOME}/.openclaw/skills/depguard"
  if [[ -f "$depguard_skill/scripts/scanner.sh" ]]; then
    # Cross-skill integration: use DepGuard for vulnerability scanning
    local vuln_output
    vuln_output=$(bash "$depguard_skill/scripts/depguard.sh" scan "$dir" 2>/dev/null || true)
    if echo "$vuln_output" | grep -qi "critical"; then
      add_issue 4 "Critical vulnerabilities found (run depguard scan for details)"
    elif echo "$vuln_output" | grep -qi "high"; then
      score=$((score + 2))
      add_issue 2 "High severity vulnerabilities found"
    else
      score=$((score + 4))
    fi
  else
    # Fallback: basic check via native audit
    if [[ -f "$dir/package.json" ]] && command -v npm &>/dev/null; then
      local audit_output
      audit_output=$(cd "$dir" && npm audit --json 2>/dev/null || true)
      if echo "$audit_output" | grep -q '"critical":[1-9]' 2>/dev/null; then
        add_issue 4 "Critical npm vulnerabilities found (run npm audit)"
      elif echo "$audit_output" | grep -q '"high":[1-9]' 2>/dev/null; then
        score=$((score + 2))
        add_issue 2 "High severity npm vulnerabilities found"
      else
        score=$((score + 4))
      fi
    else
      # Can't check — give partial credit
      score=$((score + 2))
    fi
  fi

  # Dependencies not outdated >6 months (4 pts)
  if [[ -f "$dir/package.json" ]] && command -v npm &>/dev/null; then
    local outdated
    outdated=$(cd "$dir" && npm outdated --json 2>/dev/null || true)
    local outdated_count
    outdated_count=$(echo "$outdated" | grep -c '"current"' 2>/dev/null || echo 0)
    if [[ $outdated_count -le 2 ]]; then
      score=$((score + 4))
    elif [[ $outdated_count -le 5 ]]; then
      score=$((score + 2))
      add_issue 2 "$outdated_count dependencies are outdated"
    else
      add_issue 4 "$outdated_count dependencies outdated >6 months"
      add_quick_win 4 "Update stale dependencies"
    fi
  elif [[ -f "$dir/Cargo.toml" ]] && command -v cargo &>/dev/null; then
    local outdated
    outdated=$(cd "$dir" && cargo outdated --depth 1 2>/dev/null | tail -n +2 | wc -l | tr -d ' ' || echo 0)
    if [[ $outdated -le 2 ]]; then
      score=$((score + 4))
    elif [[ $outdated -le 5 ]]; then
      score=$((score + 2))
      add_issue 2 "$outdated Cargo dependencies are outdated"
    else
      add_issue 4 "$outdated Cargo dependencies are outdated"
    fi
  else
    score=$((score + 2))  # Can't determine, partial credit
  fi

  # License compliance — no copyleft in MIT project (4 pts)
  local project_license=""
  if [[ -f "$dir/LICENSE" ]]; then
    project_license=$(head -5 "$dir/LICENSE" 2>/dev/null || true)
  fi
  local is_permissive=false
  if echo "$project_license" | grep -qiE '(MIT|Apache|BSD|ISC)'; then
    is_permissive=true
  fi

  if [[ "$is_permissive" == "true" && -f "$dir/package.json" ]] && command -v node &>/dev/null; then
    local copyleft_deps
    copyleft_deps=$(node -e "
try {
  const fs = require('fs');
  const path = require('path');
  const nm = path.join('$dir', 'node_modules');
  if (!fs.existsSync(nm)) { process.exit(0); }
  const pkgs = fs.readdirSync(nm).filter(d => !d.startsWith('.'));
  let count = 0;
  for (const pkg of pkgs) {
    try {
      const p = JSON.parse(fs.readFileSync(path.join(nm, pkg, 'package.json'), 'utf8'));
      const lic = p.license || '';
      if (/GPL|AGPL|LGPL/i.test(lic)) count++;
    } catch(e) {}
  }
  console.log(count);
} catch(e) { console.log(0); }
" 2>/dev/null || echo 0)
    if [[ "${copyleft_deps:-0}" -eq 0 ]]; then
      score=$((score + 4))
    else
      add_issue 4 "$copyleft_deps copyleft dependencies in permissive-licensed project"
    fi
  else
    score=$((score + 4))  # Can't determine or not applicable
  fi

  # No unused dependencies detected (4 pts)
  if [[ -f "$dir/package.json" ]] && command -v npx &>/dev/null; then
    local unused
    unused=$(cd "$dir" && npx depcheck --json 2>/dev/null | \
      node -e "const d=require('/dev/stdin');console.log((d.dependencies||[]).length)" 2>/dev/null || echo 0)
    if [[ "${unused:-0}" -le 1 ]]; then
      score=$((score + 4))
    elif [[ "${unused:-0}" -le 3 ]]; then
      score=$((score + 2))
      add_issue 2 "$unused unused dependencies detected"
    else
      add_issue 4 "$unused unused dependencies detected"
    fi
  else
    score=$((score + 2))  # Can't determine, partial credit
  fi

  echo "$score"
}

# ─── Category 5: Documentation Quality (20 points) ───────────────────────────

score_documentation() {
  local dir="$1"
  local score=0

  local readme=""
  for f in "$dir/README.md" "$dir/readme.md" "$dir/README" "$dir/README.rst"; do
    if [[ -f "$f" ]]; then
      readme=$(cat "$f" 2>/dev/null || true)
      break
    fi
  done

  if [[ -z "$readme" ]]; then
    add_issue 20 "No README found — all documentation points lost"
    echo "0"
    return
  fi

  # README has installation section (3 pts)
  if echo "$readme" | grep -qiE '(##?\s*(install|getting started|setup|quick start))'; then
    score=$((score + 3))
  else
    add_issue 3 "README missing installation/setup section"
    add_quick_win 3 "Add installation instructions to README"
  fi

  # README has usage section (3 pts)
  if echo "$readme" | grep -qiE '(##?\s*(usage|how to use|examples|getting started|quick start))'; then
    score=$((score + 3))
  else
    add_issue 3 "README missing usage section"
    add_quick_win 3 "Add usage examples to README"
  fi

  # README has contributing section (2 pts)
  if echo "$readme" | grep -qiE '(##?\s*contribut)' || [[ -f "$dir/CONTRIBUTING.md" ]]; then
    score=$((score + 2))
  else
    add_issue 2 "README missing contributing section"
  fi

  # API docs exist (3 pts)
  local has_api_docs=false
  [[ -d "$dir/docs/api" || -d "$dir/docs/API" ]] && has_api_docs=true
  [[ -f "$dir/docs/api.md" || -f "$dir/API.md" ]] && has_api_docs=true
  [[ -d "$dir/api-docs" ]] && has_api_docs=true
  # Check for generated docs (typedoc, javadoc, godoc, rustdoc)
  [[ -f "$dir/typedoc.json" || -f "$dir/jsdoc.json" || -f "$dir/.jsdoc.json" ]] && has_api_docs=true
  # Swagger / OpenAPI
  [[ -f "$dir/swagger.json" || -f "$dir/swagger.yaml" || -f "$dir/openapi.json" || -f "$dir/openapi.yaml" ]] && has_api_docs=true
  if [[ "$has_api_docs" == "true" ]]; then
    score=$((score + 3))
  else
    add_issue 3 "No API documentation found"
  fi

  # No stale docs — call docsync if available (4 pts)
  local docsync_skill="${HOME}/.openclaw/skills/docsync"
  if [[ -f "$docsync_skill/scripts/docsync.sh" ]]; then
    local drift_output
    drift_output=$(bash "$docsync_skill/scripts/docsync.sh" drift "$dir" 2>/dev/null || true)
    if echo "$drift_output" | grep -qi "critical"; then
      add_issue 4 "Critical documentation drift detected (run docsync drift for details)"
    elif echo "$drift_output" | grep -qi "warning"; then
      score=$((score + 2))
      add_issue 2 "Documentation drift warnings detected"
    else
      score=$((score + 4))
    fi
  else
    # Fallback: check if docs have been modified recently
    if git -C "$dir" rev-parse --git-dir &>/dev/null 2>&1; then
      local last_doc_change
      last_doc_change=$(git -C "$dir" log -1 --format="%ct" -- "*.md" "docs/" 2>/dev/null || echo 0)
      local last_code_change
      last_code_change=$(git -C "$dir" log -1 --format="%ct" -- \
        "*.ts" "*.tsx" "*.js" "*.jsx" "*.py" "*.rs" "*.go" "*.java" "*.rb" "*.php" "*.c" "*.cpp" \
        2>/dev/null || echo 0)
      local now
      now=$(date +%s)
      if [[ $last_doc_change -gt 0 && $last_code_change -gt 0 ]]; then
        local doc_age=$(( (now - last_doc_change) / 86400 ))
        local code_age=$(( (now - last_code_change) / 86400 ))
        if [[ $doc_age -lt $((code_age + 30)) ]]; then
          score=$((score + 4))
        elif [[ $doc_age -lt $((code_age + 90)) ]]; then
          score=$((score + 2))
          add_issue 2 "Documentation appears stale (last updated ${doc_age} days ago)"
        else
          add_issue 4 "Documentation severely stale (last updated ${doc_age} days ago)"
        fi
      else
        score=$((score + 2))  # Can't determine
      fi
    else
      score=$((score + 2))
    fi
  fi

  # README has badges (CI status, version, license) (2 pts)
  if echo "$readme" | grep -qE '(\[!\[|\!\[|<img src=.*badge|shields\.io|badgen\.net|img\.shields)'; then
    score=$((score + 2))
  else
    add_issue 2 "README has no status badges"
  fi

  # Architecture docs exist (3 pts)
  local has_arch=false
  [[ -f "$dir/ARCHITECTURE.md" || -f "$dir/docs/architecture.md" ]] && has_arch=true
  [[ -f "$dir/docs/ARCHITECTURE.md" || -f "$dir/docs/design.md" ]] && has_arch=true
  [[ -f "$dir/ADR" || -d "$dir/docs/adr" || -d "$dir/docs/ADR" ]] && has_arch=true
  [[ -d "$dir/docs/architecture" || -d "$dir/docs/design" ]] && has_arch=true
  if [[ "$has_arch" == "true" ]]; then
    score=$((score + 3))
  else
    add_issue 3 "Missing architecture documentation"
    add_quick_win 3 "Add an ARCHITECTURE.md file"
  fi

  echo "$score"
}

# ─── Full scoring orchestrator ────────────────────────────────────────────────

do_score() {
  local dir="${1:-.}"

  # Resolve absolute path
  dir=$(cd "$dir" 2>/dev/null && pwd || echo "$dir")

  # Reset tracking arrays
  ISSUES=()
  QUICK_WINS=()

  echo -e "${DIM}Analyzing repository...${NC}"
  echo ""

  # Run all category scorers
  local basics_score ci_score hygiene_score dep_score doc_score
  basics_score=$(score_repo_basics "$dir")
  hygiene_score=$(score_git_hygiene "$dir")
  ci_score=$(score_ci_health "$dir")
  dep_score=$(score_dependency_health "$dir")
  doc_score=$(score_documentation "$dir")

  local total_score=$((basics_score + hygiene_score + ci_score + dep_score + doc_score))
  local grade
  grade=$(get_grade "$total_score")
  local grade_color
  grade_color=$(get_grade_color "$total_score")

  # ─── Output ──────────────────────────────────────────────────────────
  echo -e "${BOLD}${grade_color}GitPulse Health Score: ${total_score}/100 (${grade})${NC}"
  echo ""
  echo -e "${BOLD}Category Breakdown:${NC}"
  printf "  %-24s %2d/20  %s\n" "Repository Basics:" "$basics_score" "$(render_bar "$basics_score" 20)"
  printf "  %-24s %2d/20  %s\n" "Git Hygiene:" "$hygiene_score" "$(render_bar "$hygiene_score" 20)"
  printf "  %-24s %2d/20  %s\n" "CI/CD Health:" "$ci_score" "$(render_bar "$ci_score" 20)"
  printf "  %-24s %2d/20  %s\n" "Dependency Health:" "$dep_score" "$(render_bar "$dep_score" 20)"
  printf "  %-24s %2d/20  %s\n" "Documentation:" "$doc_score" "$(render_bar "$doc_score" 20)"
  echo ""

  # Top issues (sorted by point impact, descending)
  if [[ ${#ISSUES[@]} -gt 0 ]]; then
    echo -e "${BOLD}Top Issues:${NC}"
    IFS=$'\n' sorted_issues=($(printf '%s\n' "${ISSUES[@]}" | sort -t'|' -k1 -rn | head -8))
    for issue in "${sorted_issues[@]}"; do
      local pts msg
      pts=$(echo "$issue" | cut -d'|' -f1)
      msg=$(echo "$issue" | cut -d'|' -f2-)
      echo -e "  ${YELLOW}!${NC}  ${msg} ${DIM}(-${pts} pts)${NC}"
    done
    echo ""
  fi

  # Quick wins (highest impact first)
  if [[ ${#QUICK_WINS[@]} -gt 0 ]]; then
    echo -e "${BOLD}Quick Wins (highest impact):${NC}"
    IFS=$'\n' sorted_wins=($(printf '%s\n' "${QUICK_WINS[@]}" | sort -t'|' -k1 -rn | head -5))
    local idx=1
    for win in "${sorted_wins[@]}"; do
      local pts msg
      pts=$(echo "$win" | cut -d'|' -f1)
      msg=$(echo "$win" | cut -d'|' -f2-)
      echo -e "  ${idx}. ${msg} ${GREEN}(+${pts} pts)${NC}"
      ((idx++)) || true
    done
    echo ""
  fi

  # Store results for other functions
  export GITPULSE_LAST_SCORE="$total_score"
  export GITPULSE_BASICS="$basics_score"
  export GITPULSE_HYGIENE="$hygiene_score"
  export GITPULSE_CI="$ci_score"
  export GITPULSE_DEPS="$dep_score"
  export GITPULSE_DOCS="$doc_score"
}

# ─── Quick check (for CI gates) ──────────────────────────────────────────────

do_check() {
  local dir="${1:-.}"
  local threshold=60

  # Resolve absolute path
  dir=$(cd "$dir" 2>/dev/null && pwd || echo "$dir")

  # Reset tracking arrays
  ISSUES=()
  QUICK_WINS=()

  local basics_score hygiene_score ci_score dep_score doc_score
  basics_score=$(score_repo_basics "$dir")
  hygiene_score=$(score_git_hygiene "$dir")
  ci_score=$(score_ci_health "$dir")
  dep_score=$(score_dependency_health "$dir")
  doc_score=$(score_documentation "$dir")

  local total_score=$((basics_score + hygiene_score + ci_score + dep_score + doc_score))
  local grade_color
  grade_color=$(get_grade_color "$total_score")
  local grade_letter
  grade_letter=$(get_grade_letter "$total_score")

  if [[ $total_score -ge $threshold ]]; then
    echo -e "${GREEN}${BOLD}PASS${NC} — Health Score: ${grade_color}${total_score}/100 (${grade_letter})${NC}"

    # Show only critical issues if any
    local critical_count=0
    for issue in "${ISSUES[@]}"; do
      local pts
      pts=$(echo "$issue" | cut -d'|' -f1)
      if [[ $pts -ge 4 ]]; then
        ((critical_count++)) || true
      fi
    done

    if [[ $critical_count -gt 0 ]]; then
      echo ""
      echo -e "${YELLOW}${critical_count} high-impact issues found:${NC}"
      for issue in "${ISSUES[@]}"; do
        local pts msg
        pts=$(echo "$issue" | cut -d'|' -f1)
        msg=$(echo "$issue" | cut -d'|' -f2-)
        if [[ $pts -ge 4 ]]; then
          echo -e "  ${YELLOW}!${NC}  ${msg}"
        fi
      done
    fi

    return 0
  else
    echo -e "${RED}${BOLD}FAIL${NC} — Health Score: ${grade_color}${total_score}/100 (${grade_letter})${NC} (minimum: ${threshold})"
    echo ""
    echo -e "${BOLD}Critical issues:${NC}"
    IFS=$'\n' sorted_issues=($(printf '%s\n' "${ISSUES[@]}" | sort -t'|' -k1 -rn | head -5))
    for issue in "${sorted_issues[@]}"; do
      local pts msg
      pts=$(echo "$issue" | cut -d'|' -f1)
      msg=$(echo "$issue" | cut -d'|' -f2-)
      echo -e "  ${RED}!${NC}  ${msg} ${DIM}(-${pts} pts)${NC}"
    done
    echo ""
    echo -e "Run ${BOLD}gitpulse score${NC} for full breakdown."
    return 1
  fi
}

# ─── Hook entry point — called by lefthook pre-push ──────────────────────────

hook_health_check() {
  local dir
  dir=$(git rev-parse --show-toplevel 2>/dev/null || echo ".")
  local threshold=60

  # Load config threshold if available
  if [[ -f "${HOME}/.openclaw/openclaw.json" ]]; then
    local config_threshold
    if command -v node &>/dev/null; then
      config_threshold=$(node -e "
try {
  const cfg = require('${HOME}/.openclaw/openclaw.json');
  console.log(cfg?.skills?.entries?.gitpulse?.config?.minScore || 60);
} catch(e) { console.log(60); }
" 2>/dev/null || echo 60)
    elif command -v python3 &>/dev/null; then
      config_threshold=$(python3 -c "
import json
try:
    with open('${HOME}/.openclaw/openclaw.json') as f:
        cfg = json.load(f)
    print(cfg.get('skills', {}).get('entries', {}).get('gitpulse', {}).get('config', {}).get('minScore', 60))
except: print(60)
" 2>/dev/null || echo 60)
    else
      config_threshold=60
    fi
    threshold="${config_threshold:-60}"
  fi

  echo -e "${BLUE}[GitPulse]${NC} Running pre-push health check (minimum: ${threshold})..."
  echo ""

  ISSUES=()
  QUICK_WINS=()

  local basics_score hygiene_score ci_score dep_score doc_score
  basics_score=$(score_repo_basics "$dir")
  hygiene_score=$(score_git_hygiene "$dir")
  ci_score=$(score_ci_health "$dir")
  dep_score=$(score_dependency_health "$dir")
  doc_score=$(score_documentation "$dir")

  local total_score=$((basics_score + hygiene_score + ci_score + dep_score + doc_score))

  if [[ $total_score -ge $threshold ]]; then
    echo -e "${GREEN}${BOLD}PASS${NC} — Health Score: ${total_score}/100"
    return 0
  else
    echo -e "${RED}${BOLD}FAIL${NC} — Health Score: ${total_score}/100 (minimum: ${threshold})"
    echo ""
    IFS=$'\n' sorted_issues=($(printf '%s\n' "${ISSUES[@]}" | sort -t'|' -k1 -rn | head -3))
    for issue in "${sorted_issues[@]}"; do
      local pts msg
      pts=$(echo "$issue" | cut -d'|' -f1)
      msg=$(echo "$issue" | cut -d'|' -f2-)
      echo -e "  ${RED}!${NC}  ${msg}"
    done
    return 1
  fi
}

# ─── Generate report data (used by report command) ───────────────────────────

generate_report_data() {
  local dir="${1:-.}"

  # Resolve absolute path
  dir=$(cd "$dir" 2>/dev/null && pwd || echo "$dir")

  ISSUES=()
  QUICK_WINS=()

  local basics_score hygiene_score ci_score dep_score doc_score
  basics_score=$(score_repo_basics "$dir")
  hygiene_score=$(score_git_hygiene "$dir")
  ci_score=$(score_ci_health "$dir")
  dep_score=$(score_dependency_health "$dir")
  doc_score=$(score_documentation "$dir")

  local total_score=$((basics_score + hygiene_score + ci_score + dep_score + doc_score))
  local grade
  grade=$(get_grade "$total_score")
  local grade_letter
  grade_letter=$(get_grade_letter "$total_score")
  local project_name
  project_name=$(basename "$dir")
  local timestamp
  timestamp=$(date +%Y-%m-%d)

  local output="$dir/HEALTH-REPORT.md"
  local template="$SKILL_DIR/templates/report.md.tmpl"

  if [[ -f "$template" ]]; then
    # Use template
    sed -e "s|{{PROJECT_NAME}}|$project_name|g" \
        -e "s|{{DATE}}|$timestamp|g" \
        -e "s|{{TOTAL_SCORE}}|$total_score|g" \
        -e "s|{{GRADE}}|$grade|g" \
        -e "s|{{GRADE_LETTER}}|$grade_letter|g" \
        -e "s|{{BASICS_SCORE}}|$basics_score|g" \
        -e "s|{{HYGIENE_SCORE}}|$hygiene_score|g" \
        -e "s|{{CI_SCORE}}|$ci_score|g" \
        -e "s|{{DEP_SCORE}}|$dep_score|g" \
        -e "s|{{DOC_SCORE}}|$doc_score|g" \
        "$template" > "$output"
  else
    # Inline template fallback
    {
      echo "# Health Report: $project_name"
      echo ""
      echo "> Generated by [GitPulse](https://gitpulse.pages.dev) -- $timestamp"
      echo ""
      echo "## Overall Score: $total_score/100 ($grade)"
      echo ""
      echo "| Category | Score | Max |"
      echo "|----------|-------|-----|"
      echo "| Repository Basics | $basics_score | 20 |"
      echo "| Git Hygiene | $hygiene_score | 20 |"
      echo "| CI/CD Health | $ci_score | 20 |"
      echo "| Dependency Health | $dep_score | 20 |"
      echo "| Documentation | $doc_score | 20 |"
      echo "| **Total** | **$total_score** | **100** |"
      echo ""

      if [[ ${#ISSUES[@]} -gt 0 ]]; then
        echo "## Issues Found"
        echo ""
        IFS=$'\n' sorted_issues=($(printf '%s\n' "${ISSUES[@]}" | sort -t'|' -k1 -rn))
        for issue in "${sorted_issues[@]}"; do
          local pts msg
          pts=$(echo "$issue" | cut -d'|' -f1)
          msg=$(echo "$issue" | cut -d'|' -f2-)
          echo "- **-${pts} pts:** $msg"
        done
        echo ""
      fi

      if [[ ${#QUICK_WINS[@]} -gt 0 ]]; then
        echo "## Recommended Fixes"
        echo ""
        IFS=$'\n' sorted_wins=($(printf '%s\n' "${QUICK_WINS[@]}" | sort -t'|' -k1 -rn))
        local idx=1
        for win in "${sorted_wins[@]}"; do
          local pts msg
          pts=$(echo "$win" | cut -d'|' -f1)
          msg=$(echo "$win" | cut -d'|' -f2-)
          echo "${idx}. **+${pts} pts:** $msg"
          ((idx++)) || true
        done
        echo ""
      fi

      echo "---"
      echo ""
      echo "*Report generated by [GitPulse](https://gitpulse.pages.dev). Run \`gitpulse score\` for live results.*"
    } > "$output"
  fi

  echo "$output"
}
