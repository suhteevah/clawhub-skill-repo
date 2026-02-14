#!/bin/bash
# ============================================================================
# 🚀 DAY 2 LAUNCH — Wednesday Feb 18, 2026 — DepGuard
# Same playbook as Tuesday, but for DepGuard
# ============================================================================

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

GH_USER=$(gh api user --jq '.login' 2>/dev/null || echo "YOUR_USERNAME")
WORKER_URL=$(cat "$REPO_ROOT/launch/.worker-url" 2>/dev/null || echo "")

open_url() {
  if command -v start &>/dev/null; then start "$1"
  elif command -v xdg-open &>/dev/null; then xdg-open "$1"
  elif command -v open &>/dev/null; then open "$1"
  fi
}

phase() {
  echo ""
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}  PHASE: $1${NC}"
  echo -e "  ${YELLOW}Time: $(date '+%I:%M %p %Z')${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

done_step() { echo -e "  ${GREEN}✓${NC} $1"; }

echo ""
echo -e "${BOLD}${CYAN}"
echo "  ╔═══════════════════════════════════════════════════╗"
echo "  ║      🛡️ DAY 2 LAUNCH — DEPGUARD 🛡️               ║"
echo "  ║      Wednesday Feb 18, 2026                       ║"
echo "  ╚═══════════════════════════════════════════════════╝"
echo -e "${NC}"

# ── 8:00 AM: Hacker News ────────────────────────────────────────────────────
phase "1 — HACKER NEWS (8:00 AM PST)"
echo -e "  ${BOLD}Post Show HN: DepGuard${NC}"
echo -e "  Title: ${CYAN}Show HN: DepGuard – Scan 10 package managers for vulns + license issues, 100% local${NC}"
echo -e "  Link: ${CYAN}https://github.com/$GH_USER/depguard${NC}"
echo -e "  Content: ${CYAN}marketing/launch/show-hn-depguard.md${NC}"

read -p "  → Open HN submit? [Y/n] " yn
[ "$yn" != "n" ] && [ "$yn" != "N" ] && open_url "https://news.ycombinator.com/submit"
read -p "  → Press Enter when posted... "
done_step "Show HN: DepGuard posted"

# ── 8:15 AM: Twitter ────────────────────────────────────────────────────────
phase "2 — TWITTER/X (8:15 AM PST)"
echo -e "  ${BOLD}Post DepGuard launch thread${NC}"
echo -e "  Content: ${CYAN}marketing/launch/twitter-threads.md${NC} (Thread 2)"

read -p "  → Open Twitter? [Y/n] " yn
[ "$yn" != "n" ] && [ "$yn" != "N" ] && open_url "https://twitter.com/compose/tweet"
read -p "  → Press Enter when posted... "
done_step "DepGuard Twitter thread posted"

# ── 9:00 AM: Reddit ─────────────────────────────────────────────────────────
phase "3 — REDDIT (9:00 AM PST)"
echo -e "  ${BOLD}Post to r/webdev and r/selfhosted${NC}"
echo -e "  Content: ${CYAN}marketing/launch/reddit-posts.md${NC}"

for sub in webdev selfhosted; do
  read -p "  → Open r/$sub? [Y/n] " yn
  [ "$yn" != "n" ] && [ "$yn" != "N" ] && open_url "https://www.reddit.com/r/$sub/submit"
  read -p "  → Press Enter when posted... "
  done_step "r/$sub post published"
done

# ── 10:00 AM: Dev.to ────────────────────────────────────────────────────────
phase "4 — DEV.TO BLOG (10:00 AM PST)"
echo -e "  ${BOLD}Publish: 'Best Snyk Alternatives 2026'${NC}"
echo -e "  Content: ${CYAN}marketing/blog/snyk-alternatives-2026.md${NC}"

read -p "  → Open Dev.to? [Y/n] " yn
[ "$yn" != "n" ] && [ "$yn" != "N" ] && open_url "https://dev.to/new"
read -p "  → Press Enter when published... "
done_step "Dev.to blog post published"

# ── Summary ──────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}  ✅ DAY 2 LAUNCH COMPLETE — DepGuard is live${NC}"
echo ""
echo -e "  ${BOLD}Thursday:${NC} Post 'Building in Public' Twitter thread"
echo -e "  ${BOLD}Next Tuesday:${NC} Product Hunt launch (both products)"
echo ""
echo -e "  ${BOLD}${YELLOW}Keep engaging. Every comment = a potential customer. 🛡️🚀${NC}"
echo ""
