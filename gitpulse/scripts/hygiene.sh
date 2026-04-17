#!/usr/bin/env bash
# GitPulse — Branch & Repository Hygiene Module
# Finds stale branches, orphaned PRs, large binaries, and sensitive files

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# ─── Configuration defaults ──────────────────────────────────────────────────

STALE_BRANCH_DAYS=30
STALE_PR_DAYS=14
MAX_FILE_SIZE_MB=5

load_config() {
  if [[ -f "${HOME}/.openclaw/openclaw.json" ]] && command -v node &>/dev/null; then
    STALE_BRANCH_DAYS=$(node -e "
try {
  const cfg = require('${HOME}/.openclaw/openclaw.json');
  console.log(cfg?.skills?.entries?.gitpulse?.config?.staleBranchDays || 30);
} catch(e) { console.log(30); }
" 2>/dev/null || echo 30)
    STALE_PR_DAYS=$(node -e "
try {
  const cfg = require('${HOME}/.openclaw/openclaw.json');
  console.log(cfg?.skills?.entries?.gitpulse?.config?.stalePRDays || 14);
} catch(e) { console.log(14); }
" 2>/dev/null || echo 14)
    MAX_FILE_SIZE_MB=$(node -e "
try {
  const cfg = require('${HOME}/.openclaw/openclaw.json');
  console.log(cfg?.skills?.entries?.gitpulse?.config?.maxFileSizeMB || 5);
} catch(e) { console.log(5); }
" 2>/dev/null || echo 5)
  fi
}

# ─── Stale branches ──────────────────────────────────────────────────────────

find_stale_branches() {
  local dir="$1"
  local stale_count=0
  local now
  now=$(date +%s)
  local cutoff=$((now - STALE_BRANCH_DAYS * 86400))

  echo -e "${BOLD}Stale Branches${NC} ${DIM}(no commits in >${STALE_BRANCH_DAYS} days)${NC}"
  echo ""

  local default_branch
  default_branch=$(git -C "$dir" symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||' || \
    git -C "$dir" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")

  while IFS= read -r ref; do
    [[ -z "$ref" ]] && continue
    local branch_name last_commit_ts last_commit_date author

    branch_name=$(echo "$ref" | sed 's|refs/heads/||')

    # Skip default branch and current branch
    [[ "$branch_name" == "$default_branch" ]] && continue
    [[ "$branch_name" == "HEAD" ]] && continue

    last_commit_ts=$(git -C "$dir" log -1 --format="%ct" "$branch_name" 2>/dev/null || echo 0)
    last_commit_date=$(git -C "$dir" log -1 --format="%cr" "$branch_name" 2>/dev/null || echo "unknown")
    author=$(git -C "$dir" log -1 --format="%an" "$branch_name" 2>/dev/null || echo "unknown")

    if [[ $last_commit_ts -lt $cutoff && $last_commit_ts -gt 0 ]]; then
      echo -e "  ${YELLOW}!${NC} ${BOLD}$branch_name${NC}"
      echo -e "     Last commit: ${DIM}$last_commit_date${NC} by ${DIM}$author${NC}"
      ((stale_count++)) || true
    fi
  done < <(git -C "$dir" for-each-ref --format='%(refname)' refs/heads/ 2>/dev/null)

  if [[ $stale_count -eq 0 ]]; then
    echo -e "  ${GREEN}No stale branches found.${NC}"
  else
    echo ""
    echo -e "  ${YELLOW}${stale_count} stale branch(es)${NC} found."
    echo -e "  ${DIM}Delete with: git branch -d <branch-name>${NC}"
  fi

  echo ""
  return "$stale_count"
}

# ─── Orphaned branches (merged but not deleted) ─────────────────────────────

find_orphaned_branches() {
  local dir="$1"
  local orphan_count=0

  local default_branch
  default_branch=$(git -C "$dir" symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||' || \
    git -C "$dir" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")

  echo -e "${BOLD}Orphaned Branches${NC} ${DIM}(merged but not deleted)${NC}"
  echo ""

  while IFS= read -r branch; do
    branch=$(echo "$branch" | sed 's|^[* ]*||; s| *$||')
    [[ -z "$branch" ]] && continue
    [[ "$branch" == "$default_branch" ]] && continue

    echo -e "  ${CYAN}>${NC} ${BOLD}$branch${NC} ${DIM}(merged into $default_branch)${NC}"
    ((orphan_count++)) || true
  done < <(git -C "$dir" branch --merged "$default_branch" 2>/dev/null)

  if [[ $orphan_count -eq 0 ]]; then
    echo -e "  ${GREEN}No orphaned branches found.${NC}"
  else
    echo ""
    echo -e "  ${CYAN}${orphan_count} orphaned branch(es)${NC} can be safely deleted."
    echo -e "  ${DIM}Clean up: git branch --merged $default_branch | grep -v '$default_branch' | xargs git branch -d${NC}"
  fi

  echo ""
  return 0
}

# ─── Large binary files in history ───────────────────────────────────────────

find_large_files() {
  local dir="$1"
  local max_bytes=$((MAX_FILE_SIZE_MB * 1024 * 1024))
  local large_count=0

  echo -e "${BOLD}Large Files${NC} ${DIM}(>${MAX_FILE_SIZE_MB}MB in working tree)${NC}"
  echo ""

  # Check working tree files tracked by git
  while IFS= read -r file; do
    [[ -z "$file" ]] && continue
    local filepath="$dir/$file"
    [[ -f "$filepath" ]] || continue

    local size
    size=$(wc -c < "$filepath" 2>/dev/null || echo 0)

    if [[ $size -gt $max_bytes ]]; then
      local human_size
      if [[ $size -gt 1073741824 ]]; then
        human_size="$(( size / 1073741824 ))GB"
      elif [[ $size -gt 1048576 ]]; then
        human_size="$(( size / 1048576 ))MB"
      else
        human_size="$(( size / 1024 ))KB"
      fi

      echo -e "  ${RED}!${NC} ${BOLD}$file${NC} ${DIM}($human_size)${NC}"
      ((large_count++)) || true
    fi
  done < <(git -C "$dir" ls-files 2>/dev/null)

  # Also check git history for large blobs
  echo ""
  echo -e "${BOLD}Large Blobs in History${NC} ${DIM}(top 5 by size)${NC}"
  echo ""

  local blob_report
  blob_report=$(git -C "$dir" rev-list --objects --all 2>/dev/null | \
    git -C "$dir" cat-file --batch-check='%(objecttype) %(objectsize) %(objectname) %(rest)' 2>/dev/null | \
    grep '^blob' | sort -k2 -rn | head -5 || true)

  if [[ -n "$blob_report" ]]; then
    while IFS= read -r line; do
      [[ -z "$line" ]] && continue
      local size name
      size=$(echo "$line" | awk '{print $2}')
      name=$(echo "$line" | awk '{$1=""; $2=""; $3=""; print}' | sed 's/^ *//')
      [[ -z "$name" ]] && name="(unnamed)"

      if [[ $size -gt $max_bytes ]]; then
        local human_size
        if [[ $size -gt 1048576 ]]; then
          human_size="$(( size / 1048576 ))MB"
        else
          human_size="$(( size / 1024 ))KB"
        fi
        echo -e "  ${RED}!${NC} ${BOLD}$name${NC} ${DIM}($human_size)${NC}"
        ((large_count++)) || true
      fi
    done <<< "$blob_report"
  fi

  if [[ $large_count -eq 0 ]]; then
    echo -e "  ${GREEN}No oversized files found.${NC}"
  else
    echo ""
    echo -e "  ${DIM}Consider using Git LFS for large files: git lfs track \"*.bin\"${NC}"
  fi

  echo ""
  return 0
}

# ─── Sensitive file patterns ─────────────────────────────────────────────────

find_sensitive_files() {
  local dir="$1"
  local sensitive_count=0

  echo -e "${BOLD}Sensitive Files${NC} ${DIM}(tracked files that should not be in git)${NC}"
  echo ""

  local patterns=(
    '\.env$'
    '\.env\.'
    '\.pem$'
    '\.key$'
    '\.p12$'
    '\.pfx$'
    '\.jks$'
    'id_rsa'
    'id_dsa'
    'id_ecdsa'
    'id_ed25519'
    '\.keystore$'
    '\.credentials$'
    '\.secret$'
    '\.secrets$'
    'credentials\.json$'
    'service-account.*\.json$'
    'serviceaccount.*\.json$'
    '\.htpasswd$'
    '\.npmrc$'
    '\.pypirc$'
    '\.netrc$'
    'tokens\.json$'
    'auth\.json$'
    '\.terraform\.tfstate$'
    'terraform\.tfstate$'
  )

  local pattern_regex
  pattern_regex=$(printf '%s\n' "${patterns[@]}" | paste -sd'|' -)

  while IFS= read -r file; do
    [[ -z "$file" ]] && continue
    if echo "$file" | grep -qE "$pattern_regex"; then
      echo -e "  ${RED}!${NC} ${BOLD}$file${NC}"
      ((sensitive_count++)) || true
    fi
  done < <(git -C "$dir" ls-files 2>/dev/null)

  if [[ $sensitive_count -eq 0 ]]; then
    echo -e "  ${GREEN}No sensitive files tracked.${NC}"
  else
    echo ""
    echo -e "  ${RED}${sensitive_count} sensitive file(s)${NC} found in git."
    echo -e "  ${DIM}Remove from tracking: git rm --cached <file>${NC}"
    echo -e "  ${DIM}Then add to .gitignore to prevent re-adding.${NC}"
  fi

  echo ""
  return 0
}

# ─── Main stale/hygiene function ─────────────────────────────────────────────

do_stale() {
  local dir="${1:-.}"

  # Resolve absolute path
  dir=$(cd "$dir" 2>/dev/null && pwd || echo "$dir")

  if ! git -C "$dir" rev-parse --git-dir &>/dev/null 2>&1; then
    echo -e "${RED}[GitPulse]${NC} Not a git repository: $dir"
    return 1
  fi

  load_config

  echo -e "${BOLD}━━━ GitPulse Stale & Hygiene Report ━━━${NC}"
  echo ""
  echo -e "Repository: ${BOLD}$(basename "$dir")${NC}"
  echo -e "Config: branches >${STALE_BRANCH_DAYS}d stale, files >${MAX_FILE_SIZE_MB}MB large"
  echo ""

  find_stale_branches "$dir"
  find_orphaned_branches "$dir"
  find_large_files "$dir"
  find_sensitive_files "$dir"

  echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
}

# ─── Compliance checks (TEAM tier) ───────────────────────────────────────────

do_compliance() {
  local dir="${1:-.}"

  # Resolve absolute path
  dir=$(cd "$dir" 2>/dev/null && pwd || echo "$dir")

  if ! git -C "$dir" rev-parse --git-dir &>/dev/null 2>&1; then
    echo -e "${RED}[GitPulse]${NC} Not a git repository: $dir"
    return 1
  fi

  echo -e "${BOLD}━━━ GitPulse Compliance Check ━━━${NC}"
  echo ""
  echo -e "Repository: ${BOLD}$(basename "$dir")${NC}"
  echo ""

  local pass=0 fail=0 warn=0

  # ─── SOC2 Basics ─────────────────────────────────────────────────

  echo -e "${BOLD}SOC2 Trust Service Criteria:${NC}"
  echo ""

  # CC6.1 - Access Control
  echo -e "  ${BOLD}Access Control (CC6.1):${NC}"
  if [[ -f "$dir/CODEOWNERS" || -f "$dir/.github/CODEOWNERS" ]]; then
    echo -e "    ${GREEN}PASS${NC} CODEOWNERS file exists"
    ((pass++)) || true
  else
    echo -e "    ${RED}FAIL${NC} Missing CODEOWNERS file"
    ((fail++)) || true
  fi

  # Check branch protection (indirect: look for required status checks in CI)
  local has_branch_protection=false
  if [[ -f "$dir/.github/settings.yml" ]] || \
     (git -C "$dir" config --get-regexp 'branch\..*\.protect' &>/dev/null 2>&1); then
    has_branch_protection=true
  fi
  if [[ "$has_branch_protection" == "true" ]]; then
    echo -e "    ${GREEN}PASS${NC} Branch protection configured"
    ((pass++)) || true
  else
    echo -e "    ${YELLOW}WARN${NC} Cannot verify branch protection (check GitHub settings)"
    ((warn++)) || true
  fi

  # CC6.6 - System Operations
  echo ""
  echo -e "  ${BOLD}System Operations (CC6.6):${NC}"

  local has_ci=false
  [[ -d "$dir/.github/workflows" ]] && has_ci=true
  [[ -f "$dir/.gitlab-ci.yml" ]] && has_ci=true
  [[ -f "$dir/Jenkinsfile" ]] && has_ci=true
  if [[ "$has_ci" == "true" ]]; then
    echo -e "    ${GREEN}PASS${NC} CI/CD pipeline configured"
    ((pass++)) || true
  else
    echo -e "    ${RED}FAIL${NC} No CI/CD pipeline found"
    ((fail++)) || true
  fi

  # Automated testing
  if [[ "$has_ci" == "true" ]]; then
    local ci_content=""
    for wf in "$dir/.github/workflows"/*.yml "$dir/.github/workflows"/*.yaml; do
      [[ -f "$wf" ]] && ci_content+=$(cat "$wf" 2>/dev/null)
    done
    [[ -f "$dir/.gitlab-ci.yml" ]] && ci_content+=$(cat "$dir/.gitlab-ci.yml" 2>/dev/null)

    if echo "$ci_content" | grep -qiE '(test|pytest|jest|mocha|rspec)'; then
      echo -e "    ${GREEN}PASS${NC} Automated testing in CI"
      ((pass++)) || true
    else
      echo -e "    ${RED}FAIL${NC} No automated testing detected in CI"
      ((fail++)) || true
    fi
  fi

  # CC7.2 - Change Management
  echo ""
  echo -e "  ${BOLD}Change Management (CC7.2):${NC}"

  if [[ -f "$dir/CHANGELOG.md" || -f "$dir/CHANGES.md" ]]; then
    echo -e "    ${GREEN}PASS${NC} Change log maintained"
    ((pass++)) || true
  else
    echo -e "    ${RED}FAIL${NC} No CHANGELOG.md found"
    ((fail++)) || true
  fi

  if [[ -f "$dir/CONTRIBUTING.md" || -f "$dir/.github/CONTRIBUTING.md" ]]; then
    echo -e "    ${GREEN}PASS${NC} Contributing guidelines documented"
    ((pass++)) || true
  else
    echo -e "    ${YELLOW}WARN${NC} No CONTRIBUTING.md found"
    ((warn++)) || true
  fi

  # Check for signed commits (recent 20)
  local signed_count=0 total_recent=0
  while IFS= read -r sig; do
    ((total_recent++)) || true
    if [[ "$sig" =~ ^G ]]; then
      ((signed_count++)) || true
    fi
  done < <(git -C "$dir" log --format="%G?" -20 2>/dev/null)
  if [[ $total_recent -gt 0 && $signed_count -gt $((total_recent / 2)) ]]; then
    echo -e "    ${GREEN}PASS${NC} Commit signing (${signed_count}/${total_recent} recent commits signed)"
    ((pass++)) || true
  elif [[ $signed_count -gt 0 ]]; then
    echo -e "    ${YELLOW}WARN${NC} Partial commit signing (${signed_count}/${total_recent})"
    ((warn++)) || true
  else
    echo -e "    ${YELLOW}WARN${NC} No signed commits detected"
    ((warn++)) || true
  fi

  # CC8.1 - Risk Assessment
  echo ""
  echo -e "  ${BOLD}Risk Assessment (CC8.1):${NC}"

  if [[ -f "$dir/SECURITY.md" || -f "$dir/.github/SECURITY.md" ]]; then
    echo -e "    ${GREEN}PASS${NC} Security policy documented"
    ((pass++)) || true
  else
    echo -e "    ${RED}FAIL${NC} Missing SECURITY.md"
    ((fail++)) || true
  fi

  # Check for security scanning in CI
  if [[ -n "${ci_content:-}" ]]; then
    if echo "$ci_content" | grep -qiE '(codeql|snyk|trivy|semgrep|bandit|gosec|dependabot)'; then
      echo -e "    ${GREEN}PASS${NC} Security scanning in CI"
      ((pass++)) || true
    else
      echo -e "    ${RED}FAIL${NC} No security scanning in CI"
      ((fail++)) || true
    fi
  fi

  # ─── HIPAA Basics ────────────────────────────────────────────────

  echo ""
  echo -e "${BOLD}HIPAA Technical Safeguards (basic checks):${NC}"
  echo ""

  # Access controls
  echo -e "  ${BOLD}Access Controls:${NC}"
  local sensitive
  sensitive=$(git -C "$dir" ls-files 2>/dev/null | grep -iE '(\.env|\.pem|\.key|credential|secret|token)' | head -5 || true)
  if [[ -z "$sensitive" ]]; then
    echo -e "    ${GREEN}PASS${NC} No sensitive files in version control"
    ((pass++)) || true
  else
    echo -e "    ${RED}FAIL${NC} Sensitive files tracked in git"
    ((fail++)) || true
  fi

  # Audit controls
  echo -e "  ${BOLD}Audit Controls:${NC}"
  if git -C "$dir" rev-parse --git-dir &>/dev/null; then
    echo -e "    ${GREEN}PASS${NC} Git provides full audit trail of changes"
    ((pass++)) || true
  fi

  # Integrity controls
  echo -e "  ${BOLD}Integrity Controls:${NC}"
  if [[ -f "$dir/.github/dependabot.yml" || -f "$dir/renovate.json" ]]; then
    echo -e "    ${GREEN}PASS${NC} Automated dependency updates configured"
    ((pass++)) || true
  else
    echo -e "    ${YELLOW}WARN${NC} No automated dependency updates"
    ((warn++)) || true
  fi

  # ─── Summary ─────────────────────────────────────────────────────

  local total=$((pass + fail + warn))
  echo ""
  echo -e "${BOLD}━━━ Compliance Summary ━━━${NC}"
  echo ""
  echo -e "  ${GREEN}PASS: $pass${NC}  ${RED}FAIL: $fail${NC}  ${YELLOW}WARN: $warn${NC}  Total: $total"
  echo ""

  if [[ $fail -eq 0 ]]; then
    echo -e "${GREEN}${BOLD}All critical compliance checks passed.${NC}"
  else
    echo -e "${RED}${BOLD}${fail} compliance check(s) failed.${NC} Address these before audit."
  fi
  echo ""
  echo -e "${DIM}Note: This is a baseline check, not a full compliance audit.${NC}"
  echo -e "${DIM}Consult your compliance team for comprehensive SOC2/HIPAA assessment.${NC}"
  echo ""
}

# ─── GitHub Actions cost estimation (TEAM tier) ──────────────────────────────

do_cost() {
  local dir="${1:-.}"

  # Resolve absolute path
  dir=$(cd "$dir" 2>/dev/null && pwd || echo "$dir")

  echo -e "${BOLD}━━━ GitPulse CI Cost Estimator ━━━${NC}"
  echo ""

  if [[ ! -d "$dir/.github/workflows" ]]; then
    echo -e "  ${YELLOW}!${NC} No .github/workflows directory found."
    echo "  This tool currently supports GitHub Actions cost estimation."
    return 1
  fi

  echo -e "  ${DIM}Estimating based on workflow configuration...${NC}"
  echo ""

  # GitHub Actions pricing (free tier: 2,000 min/mo)
  local linux_rate=8   # $0.008/min in millicents
  local windows_rate=16 # $0.016/min
  local macos_rate=80   # $0.080/min

  local total_linux_min=0
  local total_windows_min=0
  local total_macos_min=0
  local workflow_count=0

  echo -e "${BOLD}Workflow Analysis:${NC}"
  echo ""

  for wf in "$dir/.github/workflows"/*.yml "$dir/.github/workflows"/*.yaml; do
    [[ -f "$wf" ]] || continue
    ((workflow_count++)) || true

    local name
    name=$(basename "$wf" | sed 's/\.ya\?ml$//')
    local content
    content=$(cat "$wf" 2>/dev/null || true)

    # Count jobs
    local job_count
    job_count=$(echo "$content" | grep -cE '^\s{2}[a-zA-Z_][a-zA-Z0-9_-]*:' || echo 0)

    # Detect triggers to estimate frequency
    local est_runs_per_month=20  # default
    if echo "$content" | grep -qE 'schedule:'; then
      # Cron-based: estimate from cron expression
      if echo "$content" | grep -qE "cron:.*'\* \*"; then
        est_runs_per_month=720  # hourly
      elif echo "$content" | grep -qE "cron:.*'0 \*"; then
        est_runs_per_month=720
      elif echo "$content" | grep -qE "cron:.*'0 0"; then
        est_runs_per_month=30   # daily
      else
        est_runs_per_month=4    # weekly
      fi
    fi
    if echo "$content" | grep -qE 'pull_request'; then
      est_runs_per_month=40  # ~2 PRs/day
    fi
    if echo "$content" | grep -qE 'push:'; then
      est_runs_per_month=60  # ~3 pushes/day
    fi

    # Detect runner OS
    local runs_on_linux=0 runs_on_windows=0 runs_on_macos=0
    echo "$content" | grep -E 'runs-on:' | while IFS= read -r line; do
      if echo "$line" | grep -qiE 'windows'; then
        runs_on_windows=1
      elif echo "$line" | grep -qiE 'macos'; then
        runs_on_macos=1
      else
        runs_on_linux=1
      fi
    done

    # Estimate timeout per job (use explicit or default 360min)
    local timeout
    timeout=$(echo "$content" | grep -oE 'timeout-minutes:\s*[0-9]+' | head -1 | grep -oE '[0-9]+' || echo 10)

    local est_minutes=$((job_count * timeout))
    local est_monthly_minutes=$((est_minutes * est_runs_per_month))

    # Add to appropriate OS total
    if echo "$content" | grep -qiE 'runs-on:.*macos'; then
      total_macos_min=$((total_macos_min + est_monthly_minutes))
    elif echo "$content" | grep -qiE 'runs-on:.*windows'; then
      total_windows_min=$((total_windows_min + est_monthly_minutes))
    else
      total_linux_min=$((total_linux_min + est_monthly_minutes))
    fi

    echo -e "  ${BLUE}●${NC} ${BOLD}$name${NC}"
    echo -e "    Jobs: $job_count | Est. ${est_minutes}min/run | ~${est_runs_per_month} runs/mo | ~${est_monthly_minutes}min/mo"
  done

  echo ""
  echo -e "${BOLD}Estimated Monthly Usage:${NC}"
  echo ""
  echo -e "  Linux:   ${total_linux_min} minutes"
  echo -e "  Windows: ${total_windows_min} minutes"
  echo -e "  macOS:   ${total_macos_min} minutes"
  echo ""

  # Calculate cost
  local linux_cost=$((total_linux_min * linux_rate))
  local windows_cost=$((total_windows_min * windows_rate))
  local macos_cost=$((total_macos_min * macos_rate))
  local total_cost=$((linux_cost + windows_cost + macos_cost))

  # Free tier: 2000 Linux minutes
  local free_savings=$((2000 * linux_rate))
  if [[ $free_savings -gt $total_cost ]]; then free_savings=$total_cost; fi
  local net_cost=$((total_cost - free_savings))
  if [[ $net_cost -lt 0 ]]; then net_cost=0; fi

  # Convert millicents to dollars
  local total_dollars=$(echo "scale=2; $total_cost / 100000" | bc 2>/dev/null || echo "~$(( total_cost / 100000 ))")
  local net_dollars=$(echo "scale=2; $net_cost / 100000" | bc 2>/dev/null || echo "~$(( net_cost / 100000 ))")

  echo -e "${BOLD}Estimated Monthly Cost:${NC}"
  echo ""
  echo -e "  Gross:     \$${total_dollars}"
  echo -e "  Free tier: -${free_savings} Linux minutes included"
  echo -e "  ${BOLD}Net:       \$${net_dollars}/month${NC}"
  echo ""

  # Optimization suggestions
  echo -e "${BOLD}Optimization Suggestions:${NC}"
  echo ""

  if [[ $total_macos_min -gt 0 ]]; then
    echo -e "  ${YELLOW}!${NC} macOS runners are 10x Linux cost — consider Linux where possible"
  fi
  if [[ $total_windows_min -gt 0 ]]; then
    echo -e "  ${YELLOW}!${NC} Windows runners are 2x Linux cost — consider Linux where possible"
  fi

  local has_cache=false
  for wf in "$dir/.github/workflows"/*.yml "$dir/.github/workflows"/*.yaml; do
    [[ -f "$wf" ]] || continue
    if grep -qE 'actions/cache' "$wf" 2>/dev/null; then
      has_cache=true
      break
    fi
  done
  if [[ "$has_cache" == "false" ]]; then
    echo -e "  ${YELLOW}!${NC} No caching detected — adding cache can reduce build times 30-50%"
  fi

  local total_minutes=$((total_linux_min + total_windows_min + total_macos_min))
  if [[ $total_minutes -gt 3000 ]]; then
    echo -e "  ${YELLOW}!${NC} High usage — consider self-hosted runners for cost savings"
  fi

  echo ""
}
