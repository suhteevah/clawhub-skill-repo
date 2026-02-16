#!/usr/bin/env bash
# GitPulse — Main CLI entry point
# Usage: gitpulse.sh <command> [args...]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
VERSION="1.0.0"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

log_info()    { echo -e "${BLUE}[GitPulse]${NC} $*"; }
log_success() { echo -e "${GREEN}[GitPulse]${NC} $*"; }
log_warn()    { echo -e "${YELLOW}[GitPulse]${NC} $*"; }
log_error()   { echo -e "${RED}[GitPulse]${NC} $*" >&2; }

show_version() {
  echo -e "${BOLD}GitPulse${NC} v${VERSION}"
  echo "  Repo health scoring & CI hygiene"
  echo "  https://gitpulse.pages.dev"
}

show_help() {
  show_version
  echo ""
  echo -e "${BOLD}USAGE${NC}"
  echo "  gitpulse <command> [options]"
  echo ""
  echo -e "${BOLD}FREE COMMANDS${NC}"
  echo "  score [directory]         Health score (0-100) with breakdown"
  echo "  check [directory]         Quick health check (pass/fail)"
  echo ""
  echo -e "${BOLD}PRO COMMANDS${NC} (\$19/user/month)"
  echo "  hooks install             Install pre-push health gate"
  echo "  hooks uninstall           Remove GitPulse hooks"
  echo "  lint-ci [directory]       Lint CI workflow files"
  echo "  stale [directory]         Find stale branches & hygiene issues"
  echo ""
  echo -e "${BOLD}TEAM COMMANDS${NC} (\$39/user/month)"
  echo "  report [directory]        Generate full health report (markdown)"
  echo "  compliance [directory]    SOC2/HIPAA compliance checks"
  echo "  cost [directory]          GitHub Actions cost estimation"
  echo ""
  echo -e "${BOLD}OTHER${NC}"
  echo "  status                    Show license and config info"
  echo "  --help, -h                Show this help"
  echo "  --version, -v             Show version"
  echo ""
  echo "Get a license at ${CYAN}https://gitpulse.pages.dev${NC}"
}

# ─── License ────────────────────────────────────────────────────────────────

require_license() {
  local required_tier="${1:-pro}"
  source "$SCRIPT_DIR/license.sh"
  check_gitpulse_license "$required_tier"
}

# ─── Hooks management ───────────────────────────────────────────────────────

do_hooks_install() {
  if ! command -v lefthook &>/dev/null; then
    echo -e "${RED}[GitPulse]${NC} lefthook not installed."
    echo "  Install: brew install lefthook"
    return 1
  fi

  if ! git rev-parse --git-dir &>/dev/null 2>&1; then
    echo -e "${RED}[GitPulse]${NC} Not inside a git repository."
    return 1
  fi

  local repo_root
  repo_root=$(git rev-parse --show-toplevel)

  log_info "Installing hooks in ${BOLD}$repo_root${NC}"

  local config="$repo_root/lefthook.yml"

  if [[ -f "$config" ]]; then
    if grep -q "gitpulse" "$config" 2>/dev/null; then
      log_success "Hooks already configured."
      return 0
    fi

    # Append to existing config
    cat >> "$config" <<'HOOKS'

# ─── GitPulse hooks ─────────────────────────────
pre-push:
  parallel: true
  commands:
    gitpulse-health-check:
      run: |
        GITPULSE_SKILL_DIR="${GITPULSE_SKILL_DIR:-$HOME/.openclaw/skills/gitpulse}"
        if [[ -f "$GITPULSE_SKILL_DIR/scripts/scorer.sh" ]]; then
          source "$GITPULSE_SKILL_DIR/scripts/scorer.sh"
          hook_health_check
        else
          echo "[GitPulse] Skill not found at $GITPULSE_SKILL_DIR — skipping health check"
        fi
      fail_text: |
        Repo health score too low!
        Run 'gitpulse score' to see details
        Run 'gitpulse check --fix' for quick fixes
        Or 'git push --no-verify' to skip
HOOKS
    echo -e "${GREEN}+${NC} Appended GitPulse hooks to existing lefthook.yml"
  else
    cp "$SKILL_DIR/config/lefthook.yml" "$config"
    echo -e "${GREEN}+${NC} Created lefthook.yml"
  fi

  (cd "$repo_root" && lefthook install)
  echo ""
  log_success "Hooks installed! Pushes will be gated on repo health score."
}

do_hooks_uninstall() {
  if ! git rev-parse --git-dir &>/dev/null 2>&1; then
    echo -e "${RED}[GitPulse]${NC} Not inside a git repository."
    return 1
  fi

  local repo_root
  repo_root=$(git rev-parse --show-toplevel)
  local config="$repo_root/lefthook.yml"

  if [[ -f "$config" ]]; then
    if grep -q "gitpulse" "$config" 2>/dev/null; then
      local tmp
      tmp=$(mktemp)
      # Remove the GitPulse hooks block
      sed '/# ─── GitPulse hooks/,/Or.*--no-verify.*to skip/d' "$config" > "$tmp"
      grep -v "gitpulse" "$tmp" > "$config" 2>/dev/null || mv "$tmp" "$config"
      rm -f "$tmp"
      echo -e "${GREEN}+${NC} Removed GitPulse hooks"
    else
      log_warn "No GitPulse hooks found"
    fi
  else
    log_warn "No lefthook.yml found"
  fi
}

# ─── Command dispatch ───────────────────────────────────────────────────────

main() {
  local cmd="${1:-}"
  shift || true

  case "$cmd" in
    score)
      local target="${1:-.}"
      log_info "Scoring repository health in ${BOLD}$target${NC}"
      echo ""
      source "$SCRIPT_DIR/scorer.sh"
      do_score "$target"
      ;;

    check)
      local target="${1:-.}"
      source "$SCRIPT_DIR/scorer.sh"
      do_check "$target"
      ;;

    hooks)
      require_license "pro"
      local subcmd="${1:-}"
      case "$subcmd" in
        install)
          do_hooks_install
          ;;
        uninstall)
          do_hooks_uninstall
          ;;
        *)
          log_error "Unknown hooks subcommand: $subcmd"
          echo "  Usage: gitpulse hooks [install|uninstall]"
          exit 1
          ;;
      esac
      ;;

    lint-ci)
      require_license "pro"
      local target="${1:-.}"
      log_info "Linting CI workflows in ${BOLD}$target${NC}"
      source "$SCRIPT_DIR/ci-lint.sh"
      do_lint_ci "$target"
      ;;

    stale)
      require_license "pro"
      local target="${1:-.}"
      log_info "Checking hygiene in ${BOLD}$target${NC}"
      source "$SCRIPT_DIR/hygiene.sh"
      do_stale "$target"
      ;;

    report)
      require_license "team"
      local target="${1:-.}"
      log_info "Generating health report for ${BOLD}$target${NC}"
      source "$SCRIPT_DIR/scorer.sh"
      local output
      output=$(generate_report_data "$target")
      log_success "Report written to ${BOLD}$output${NC}"
      ;;

    compliance)
      require_license "team"
      local target="${1:-.}"
      log_info "Running compliance checks on ${BOLD}$target${NC}"
      source "$SCRIPT_DIR/hygiene.sh"
      do_compliance "$target"
      ;;

    cost)
      require_license "team"
      local target="${1:-.}"
      log_info "Estimating CI costs for ${BOLD}$target${NC}"
      source "$SCRIPT_DIR/hygiene.sh"
      do_cost "$target"
      ;;

    status)
      show_version
      echo ""
      source "$SCRIPT_DIR/license.sh"
      show_gitpulse_status
      ;;

    --help|-h|help)
      show_help
      ;;

    --version|-v)
      show_version
      ;;

    "")
      show_help
      exit 1
      ;;

    *)
      log_error "Unknown command: $cmd"
      show_help
      exit 1
      ;;
  esac
}

main "$@"
