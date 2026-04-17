#!/usr/bin/env bash
# GitPulse — CI Workflow Linter
# Lints GitHub Actions workflows for best practices

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

declare -a LINT_ERRORS=()
declare -a LINT_WARNINGS=()
declare -a LINT_INFO=()

lint_error() {
  local file="$1" line="${2:-0}" msg="$3"
  LINT_ERRORS+=("$file:$line|$msg")
}

lint_warning() {
  local file="$1" line="${2:-0}" msg="$3"
  LINT_WARNINGS+=("$file:$line|$msg")
}

lint_info() {
  local file="$1" line="${2:-0}" msg="$3"
  LINT_INFO+=("$file:$line|$msg")
}

# ─── Known deprecated actions ────────────────────────────────────────────────

DEPRECATED_ACTIONS=(
  "actions/create-release"
  "actions/upload-release-asset"
  "peaceiris/actions-gh-pages@v2"
  "actions/cache@v1"
  "actions/checkout@v1"
  "actions/checkout@v2"
  "actions/setup-node@v1"
  "actions/setup-python@v1"
  "actions/setup-java@v1"
  "actions/setup-go@v1"
)

# ─── Lint a single GitHub Actions workflow file ──────────────────────────────

lint_github_actions_file() {
  local file="$1"
  local filename
  filename=$(basename "$file")
  local content
  content=$(cat "$file" 2>/dev/null || true)
  [[ -z "$content" ]] && return

  local line_num=0

  # Check for missing timeout-minutes on jobs
  local in_jobs=false
  local in_job=false
  local current_job=""
  local has_timeout=false
  local job_line=0

  while IFS= read -r line; do
    ((line_num++)) || true

    # Track jobs section
    if echo "$line" | grep -qE '^jobs:'; then
      in_jobs=true
      continue
    fi

    if [[ "$in_jobs" == "true" ]]; then
      # New job definition (indented exactly 2 spaces)
      if echo "$line" | grep -qE '^  [a-zA-Z_][a-zA-Z0-9_-]*:'; then
        # Check previous job
        if [[ -n "$current_job" && "$has_timeout" == "false" ]]; then
          lint_warning "$filename" "$job_line" "Job '$current_job' missing timeout-minutes (jobs can run indefinitely)"
        fi
        current_job=$(echo "$line" | sed 's/^ *//; s/:.*//')
        has_timeout=false
        job_line=$line_num
      fi

      if echo "$line" | grep -qE 'timeout-minutes:'; then
        has_timeout=true
      fi
    fi
  done <<< "$content"

  # Check last job
  if [[ -n "$current_job" && "$has_timeout" == "false" ]]; then
    lint_warning "$filename" "$job_line" "Job '$current_job' missing timeout-minutes (jobs can run indefinitely)"
  fi

  # Check for unpinned action versions (@latest, @master, @main, non-SHA tags)
  line_num=0
  while IFS= read -r line; do
    ((line_num++)) || true
    if echo "$line" | grep -qE 'uses:.*@(latest|master|main)$'; then
      local action
      action=$(echo "$line" | grep -oE 'uses: *[^ ]+' | sed 's/uses: *//')
      lint_error "$filename" "$line_num" "Unpinned action: $action (pin to a specific SHA or version tag)"
    elif echo "$line" | grep -qE 'uses:.*@v[0-9]+$'; then
      local action
      action=$(echo "$line" | grep -oE 'uses: *[^ ]+' | sed 's/uses: *//')
      lint_info "$filename" "$line_num" "Action uses major version tag: $action (consider pinning to full SHA)"
    fi
  done <<< "$content"

  # Check for missing permissions block
  if ! echo "$content" | grep -qE '^permissions:'; then
    lint_warning "$filename" "1" "Missing top-level 'permissions' block (runs with default GITHUB_TOKEN permissions)"
  fi

  # Check for hardcoded secrets
  line_num=0
  while IFS= read -r line; do
    ((line_num++)) || true
    # Detect potential hardcoded tokens/keys (but not ${{ secrets.* }} references)
    if echo "$line" | grep -qE '(AKIA[0-9A-Z]{16}|sk_live_|ghp_[a-zA-Z0-9]+|-----BEGIN)'; then
      lint_error "$filename" "$line_num" "Possible hardcoded secret detected (use \${{ secrets.* }} instead)"
    fi
    # Check for env vars set to literal strings that look like keys
    if echo "$line" | grep -qE '^\s+[A-Z_]+:\s*["\x27]?[a-zA-Z0-9]{20,}["\x27]?\s*$' && \
       ! echo "$line" | grep -qE '\$\{\{'; then
      lint_warning "$filename" "$line_num" "Possible hardcoded credential in env variable (use \${{ secrets.* }})"
    fi
  done <<< "$content"

  # Check for missing concurrency on PR workflows
  local is_pr_workflow=false
  if echo "$content" | grep -qE '(pull_request|pull_request_target)'; then
    is_pr_workflow=true
  fi
  if [[ "$is_pr_workflow" == "true" ]] && ! echo "$content" | grep -qE '^concurrency:'; then
    lint_warning "$filename" "1" "PR workflow missing 'concurrency' block (duplicate runs won't be cancelled)"
  fi

  # Check for deprecated actions
  for deprecated in "${DEPRECATED_ACTIONS[@]}"; do
    if echo "$content" | grep -qF "$deprecated"; then
      local dep_line
      dep_line=$(echo "$content" | grep -nF "$deprecated" | head -1 | cut -d: -f1)
      lint_warning "$filename" "${dep_line:-0}" "Deprecated action: $deprecated"
    fi
  done

  # Check for missing caching
  local has_node=false has_python=false has_cache=false
  echo "$content" | grep -qE 'setup-node' && has_node=true
  echo "$content" | grep -qE 'setup-python' && has_python=true
  echo "$content" | grep -qE '(actions/cache|with:.*cache)' && has_cache=true

  if [[ ("$has_node" == "true" || "$has_python" == "true") && "$has_cache" == "false" ]]; then
    lint_info "$filename" "1" "No caching configured (consider actions/cache for faster builds)"
  fi

  # Check for missing fail-fast: false on matrix builds
  if echo "$content" | grep -qE 'matrix:' && ! echo "$content" | grep -qE 'fail-fast:\s*false'; then
    lint_info "$filename" "1" "Matrix build without fail-fast: false (one failure stops all matrix jobs)"
  fi

  # Check for container jobs without explicit user
  if echo "$content" | grep -qE '^\s+container:' && ! echo "$content" | grep -qE 'options:.*--user'; then
    lint_info "$filename" "1" "Container job without explicit user (may run as root)"
  fi

  # Check for workflow_dispatch without inputs
  if echo "$content" | grep -qE 'workflow_dispatch:$'; then
    lint_info "$filename" "1" "workflow_dispatch has no inputs defined"
  fi
}

# ─── Lint GitLab CI ──────────────────────────────────────────────────────────

lint_gitlab_ci() {
  local file="$1"
  local filename
  filename=$(basename "$file")
  local content
  content=$(cat "$file" 2>/dev/null || true)
  [[ -z "$content" ]] && return

  # Check for missing timeout
  if ! echo "$content" | grep -qE 'timeout:'; then
    lint_warning "$filename" "1" "No job timeouts configured"
  fi

  # Check for allow_failure on critical jobs
  if echo "$content" | grep -qE 'allow_failure:\s*true'; then
    local line_num
    line_num=$(echo "$content" | grep -nE 'allow_failure:\s*true' | head -1 | cut -d: -f1)
    lint_info "$filename" "${line_num:-0}" "allow_failure: true found (failures may be silently ignored)"
  fi

  # Check for missing retry
  if ! echo "$content" | grep -qE 'retry:'; then
    lint_info "$filename" "1" "No retry configuration (flaky jobs won't be retried)"
  fi
}

# ─── Main lint function ──────────────────────────────────────────────────────

do_lint_ci() {
  local dir="${1:-.}"

  # Resolve absolute path
  dir=$(cd "$dir" 2>/dev/null && pwd || echo "$dir")

  LINT_ERRORS=()
  LINT_WARNINGS=()
  LINT_INFO=()

  echo -e "${BOLD}━━━ GitPulse CI Linter ━━━${NC}"
  echo ""
  echo -e "Target: ${BOLD}$dir${NC}"
  echo ""

  local files_found=0

  # GitHub Actions workflows
  if [[ -d "$dir/.github/workflows" ]]; then
    for wf in "$dir/.github/workflows"/*.yml "$dir/.github/workflows"/*.yaml; do
      [[ -f "$wf" ]] || continue
      ((files_found++)) || true
      echo -e "  ${BLUE}●${NC} Linting $(basename "$wf")..."
      lint_github_actions_file "$wf"
    done
  fi

  # GitLab CI
  if [[ -f "$dir/.gitlab-ci.yml" ]]; then
    ((files_found++)) || true
    echo -e "  ${BLUE}●${NC} Linting .gitlab-ci.yml..."
    lint_gitlab_ci "$dir/.gitlab-ci.yml"
  fi

  # No CI files found
  if [[ $files_found -eq 0 ]]; then
    echo -e "  ${YELLOW}!${NC} No CI configuration files found."
    echo ""
    echo "  Supported:"
    echo "    - .github/workflows/*.yml (GitHub Actions)"
    echo "    - .gitlab-ci.yml (GitLab CI)"
    echo ""
    return 1
  fi

  echo ""

  # ─── Output results ────────────────────────────────────────────────

  local total=$((${#LINT_ERRORS[@]} + ${#LINT_WARNINGS[@]} + ${#LINT_INFO[@]}))

  if [[ ${#LINT_ERRORS[@]} -gt 0 ]]; then
    echo -e "${RED}${BOLD}Errors (${#LINT_ERRORS[@]}):${NC}"
    for entry in "${LINT_ERRORS[@]}"; do
      local loc msg
      loc=$(echo "$entry" | cut -d'|' -f1)
      msg=$(echo "$entry" | cut -d'|' -f2-)
      echo -e "  ${RED}E${NC} ${DIM}$loc${NC}  $msg"
    done
    echo ""
  fi

  if [[ ${#LINT_WARNINGS[@]} -gt 0 ]]; then
    echo -e "${YELLOW}${BOLD}Warnings (${#LINT_WARNINGS[@]}):${NC}"
    for entry in "${LINT_WARNINGS[@]}"; do
      local loc msg
      loc=$(echo "$entry" | cut -d'|' -f1)
      msg=$(echo "$entry" | cut -d'|' -f2-)
      echo -e "  ${YELLOW}W${NC} ${DIM}$loc${NC}  $msg"
    done
    echo ""
  fi

  if [[ ${#LINT_INFO[@]} -gt 0 ]]; then
    echo -e "${BLUE}${BOLD}Info (${#LINT_INFO[@]}):${NC}"
    for entry in "${LINT_INFO[@]}"; do
      local loc msg
      loc=$(echo "$entry" | cut -d'|' -f1)
      msg=$(echo "$entry" | cut -d'|' -f2-)
      echo -e "  ${BLUE}I${NC} ${DIM}$loc${NC}  $msg"
    done
    echo ""
  fi

  # Summary
  echo -e "${BOLD}Summary:${NC} $files_found file(s) scanned, $total issue(s) found"
  echo -e "  ${RED}${#LINT_ERRORS[@]} errors${NC}  ${YELLOW}${#LINT_WARNINGS[@]} warnings${NC}  ${BLUE}${#LINT_INFO[@]} info${NC}"
  echo ""

  if [[ ${#LINT_ERRORS[@]} -gt 0 ]]; then
    echo -e "${RED}${BOLD}CI lint failed.${NC} Fix errors before merging."
    return 1
  elif [[ ${#LINT_WARNINGS[@]} -gt 0 ]]; then
    echo -e "${YELLOW}${BOLD}CI lint passed with warnings.${NC} Consider fixing warnings."
    return 0
  else
    echo -e "${GREEN}${BOLD}CI lint passed.${NC} No issues found."
    return 0
  fi
}
