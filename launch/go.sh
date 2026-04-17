#!/bin/bash
# ============================================================================
# 🚀 LAUNCH DAY — Tuesday Feb 17, 2026
#
# This script is your mission control for launch day.
# It opens all platforms with pre-written content ready to paste.
# ============================================================================

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

echo ""
echo -e "${BOLD}${CYAN}"
echo "  ╔═══════════════════════════════════════════════════╗"
echo "  ║         🚀 LAUNCH DAY — LET'S GO! 🚀             ║"
echo "  ║                                                   ║"
echo "  ║  DocSync + DepGuard — Tuesday Feb 17, 2026        ║"
echo "  ║  Target: GitHub Trending + HN Front Page          ║"
echo "  ╚═══════════════════════════════════════════════════╝"
echo -e "${NC}"

GH_USER=$(gh api user --jq '.login' 2>/dev/null || echo "YOUR_USERNAME")
WORKER_URL=$(cat "$REPO_ROOT/launch/.worker-url" 2>/dev/null || echo "https://license-api.YOUR_ACCOUNT.workers.dev")

# ── Helper: Open URL in browser ──────────────────────────────────────────────
open_url() {
  if command -v start &>/dev/null; then
    start "$1"  # Windows
  elif command -v xdg-open &>/dev/null; then
    xdg-open "$1"  # Linux
  elif command -v open &>/dev/null; then
    open "$1"  # macOS
  fi
}

# ── Helper: Copy to clipboard ────────────────────────────────────────────────
clip() {
  if command -v clip.exe &>/dev/null; then
    echo "$1" | clip.exe  # Windows/WSL
  elif command -v pbcopy &>/dev/null; then
    echo "$1" | pbcopy  # macOS
  elif command -v xclip &>/dev/null; then
    echo "$1" | xclip -selection clipboard  # Linux
  fi
}

# ── Phase display ────────────────────────────────────────────────────────────
phase() {
  echo ""
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}  PHASE: $1${NC}"
  echo -e "  ${YELLOW}Time: $(date '+%I:%M %p %Z')${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

done_step() {
  echo -e "  ${GREEN}✓${NC} $1"
}

# ============================================================================
# PHASE 1: HACKER NEWS — 8:00 AM PST
# ============================================================================
phase "1 — HACKER NEWS (8:00 AM PST)"

echo ""
echo -e "  ${BOLD}Post Show HN: DocSync${NC}"
echo ""
echo -e "  Title: ${CYAN}Show HN: DocSync – Git hooks that block commits when docs drift out of sync${NC}"
echo ""
echo -e "  Link: ${CYAN}https://github.com/$GH_USER/docsync${NC}"
echo ""

# Copy the Show HN text
HN_TEXT=$(cat "$REPO_ROOT/marketing/launch/show-hn-docsync.md" 2>/dev/null | head -30)
echo -e "  First comment is in: marketing/launch/show-hn-docsync.md"
echo ""

read -p "  → Open Hacker News submit page? [Y/n] " yn
if [ "$yn" != "n" ] && [ "$yn" != "N" ]; then
  open_url "https://news.ycombinator.com/submit"
  echo ""
  echo -e "  ${YELLOW}ACTION: Paste the title and link. Submit. Then post your first comment.${NC}"
fi

read -p "  → Press Enter when HN post is live... "
done_step "Show HN: DocSync posted"

# ============================================================================
# PHASE 2: TWITTER — 8:15 AM PST
# ============================================================================
phase "2 — TWITTER/X (8:15 AM PST)"

echo ""
echo -e "  ${BOLD}Post DocSync launch thread${NC}"
echo -e "  Content in: ${CYAN}marketing/launch/twitter-threads.md${NC} (Thread 1)"
echo ""

read -p "  → Open Twitter? [Y/n] " yn
if [ "$yn" != "n" ] && [ "$yn" != "N" ]; then
  open_url "https://twitter.com/compose/tweet"
fi

read -p "  → Press Enter when thread is posted... "
done_step "DocSync Twitter thread posted"

# ============================================================================
# PHASE 3: REDDIT — 9:00 AM PST
# ============================================================================
phase "3 — REDDIT (9:00 AM PST)"

echo ""
echo -e "  ${BOLD}Post to r/devtools and r/programming${NC}"
echo -e "  Content in: ${CYAN}marketing/launch/reddit-posts.md${NC}"
echo ""

SUBREDDITS=("devtools" "programming")
for sub in "${SUBREDDITS[@]}"; do
  read -p "  → Open r/$sub submit page? [Y/n] " yn
  if [ "$yn" != "n" ] && [ "$yn" != "N" ]; then
    open_url "https://www.reddit.com/r/$sub/submit"
  fi
  read -p "  → Press Enter when r/$sub post is live... "
  done_step "r/$sub post published"
done

# ============================================================================
# PHASE 4: DEV.TO BLOG — 10:00 AM PST
# ============================================================================
phase "4 — DEV.TO BLOG POST (10:00 AM PST)"

echo ""
echo -e "  ${BOLD}Publish: 'Why Your Docs Are Always Stale'${NC}"
echo -e "  Content in: ${CYAN}marketing/blog/why-your-docs-are-always-stale.md${NC}"
echo ""

read -p "  → Open Dev.to new post? [Y/n] " yn
if [ "$yn" != "n" ] && [ "$yn" != "N" ]; then
  open_url "https://dev.to/new"
fi

read -p "  → Press Enter when blog post is published... "
done_step "Dev.to blog post published"

echo ""
echo -e "  ${BOLD}Also cross-post to Hashnode:${NC}"
read -p "  → Open Hashnode? [Y/n] " yn
if [ "$yn" != "n" ] && [ "$yn" != "N" ]; then
  open_url "https://hashnode.com/draft"
fi

read -p "  → Press Enter when Hashnode post is live... "
done_step "Hashnode cross-post published"

# ============================================================================
# PHASE 5: MORE REDDIT — 10:30 AM PST
# ============================================================================
phase "5 — MORE REDDIT (10:30 AM PST)"

SUBREDDITS2=("webdev" "SideProject" "selfhosted")
for sub in "${SUBREDDITS2[@]}"; do
  read -p "  → Open r/$sub submit page? [Y/n] " yn
  if [ "$yn" != "n" ] && [ "$yn" != "N" ]; then
    open_url "https://www.reddit.com/r/$sub/submit"
  fi
  read -p "  → Press Enter when r/$sub post is live... "
  done_step "r/$sub post published"
done

# ============================================================================
# PHASE 6: CLAWHUB FORUM — 11:00 AM PST
# ============================================================================
phase "6 — CLAWHUB FORUM (11:00 AM PST)"

echo ""
echo -e "  ${BOLD}Post to ClawHub forum / agent conversation board${NC}"
echo -e "  Content in: ${CYAN}marketing/launch/clawhub-forum-post.md${NC}"
echo ""

read -p "  → Open ClawHub forum? [Y/n] " yn
if [ "$yn" != "n" ] && [ "$yn" != "N" ]; then
  open_url "https://clawhub.com/forum"
fi

read -p "  → Press Enter when ClawHub post is live... "
done_step "ClawHub forum post published"

# ============================================================================
# PHASE 7: MONITOR & ENGAGE — All Day
# ============================================================================
phase "7 — MONITOR & ENGAGE (All Day)"

echo ""
echo -e "  ${BOLD}Your dashboard:${NC}"
echo ""
echo -e "    HN:       ${CYAN}https://news.ycombinator.com/submitted?id=YOUR_HN_USER${NC}"
echo -e "    Reddit:   ${CYAN}https://www.reddit.com/user/YOUR_USER/submitted${NC}"
echo -e "    Twitter:  ${CYAN}https://twitter.com/YOUR_HANDLE/analytics${NC}"
echo -e "    Stripe:   ${CYAN}https://dashboard.stripe.com${NC}"
echo -e "    Subs:     ${CYAN}$WORKER_URL/subscribers?secret=YOUR_ADMIN_SECRET${NC}"
echo -e "    CF Stats: ${CYAN}https://dash.cloudflare.com${NC}"
echo ""
echo -e "  ${BOLD}${YELLOW}RULES OF ENGAGEMENT:${NC}"
echo -e "    • Reply to EVERY HN comment within 15 minutes"
echo -e "    • Reply to EVERY Reddit comment"
echo -e "    • Reply to EVERY Twitter mention"
echo -e "    • When criticized: agree with something first, then explain"
echo -e "    • Be a builder, not a marketer"
echo -e "    • Never be defensive"
echo ""

# ============================================================================
# Summary
# ============================================================================
echo ""
echo -e "${BOLD}${GREEN}"
echo "  ╔═══════════════════════════════════════════════════╗"
echo "  ║       🎯 LAUNCH DAY SEQUENCE COMPLETE            ║"
echo "  ╚═══════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""
echo -e "  ${BOLD}Posted to:${NC}"
echo -e "    ${GREEN}✓${NC} Hacker News (Show HN)"
echo -e "    ${GREEN}✓${NC} Twitter/X (launch thread)"
echo -e "    ${GREEN}✓${NC} Reddit (5 subreddits)"
echo -e "    ${GREEN}✓${NC} Dev.to (SEO blog post)"
echo -e "    ${GREEN}✓${NC} Hashnode (cross-post)"
echo -e "    ${GREEN}✓${NC} ClawHub forum"
echo ""
echo -e "  ${BOLD}Now:${NC}"
echo -e "    → Monitor all platforms"
echo -e "    → Respond to every comment"
echo -e "    → Check Stripe for first revenue"
echo -e "    → Check email subscribers: ${CYAN}curl $WORKER_URL/subscribers?secret=...${NC}"
echo ""
echo -e "  ${BOLD}Wednesday:${NC} Launch DepGuard (same sequence — run ${CYAN}bash launch/go-depguard.sh${NC})"
echo ""
echo -e "  ${BOLD}${YELLOW}Let's send this thing to the fucking moon. 🚀🌕${NC}"
echo ""
