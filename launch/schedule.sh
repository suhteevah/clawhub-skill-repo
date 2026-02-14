#!/bin/bash
# ============================================================================
# 🗓️  LAUNCH SCHEDULER
#
# Sets up reminders and pre-positions everything for Tuesday Feb 17
# Run this Saturday/Sunday to get everything queued
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
echo "  ║        🗓️  LAUNCH SCHEDULE & COUNTDOWN            ║"
echo "  ╚═══════════════════════════════════════════════════╝"
echo -e "${NC}"

# Calculate countdown
NOW=$(date +%s)
# Tuesday Feb 17 8:00 AM PST = 16:00 UTC
LAUNCH_EPOCH=$(date -d "2026-02-17T08:00:00-08:00" +%s 2>/dev/null || echo "1771344000")
DIFF=$((LAUNCH_EPOCH - NOW))
HOURS=$((DIFF / 3600))
MINS=$(( (DIFF % 3600) / 60))

if [ $DIFF -gt 0 ]; then
  echo -e "  ${BOLD}⏰ T-minus ${HOURS}h ${MINS}m until launch${NC}"
else
  echo -e "  ${RED}${BOLD}🚀 LAUNCH WINDOW IS OPEN — GO GO GO${NC}"
fi

echo ""
echo -e "${BOLD}  ═══ TIMELINE ═══${NC}"
echo ""
echo -e "  ${CYAN}Saturday Feb 15 (TODAY — Prep)${NC}"
echo -e "    □ Run setup.sh to deploy infrastructure"
echo -e "    □ Set Stripe secrets"
echo -e "    □ Test checkout flow in Stripe test mode"
echo -e "    □ Create GitHub repos"
echo ""
echo -e "  ${CYAN}Sunday Feb 16 (Final Prep)${NC}"
echo -e "    □ Run validate.sh — all checks must pass"
echo -e "    □ Review all launch posts one final time"
echo -e "    □ Set up Product Hunt 'Coming Soon' page"
echo -e "    □ DM 5-10 supporters for Tuesday morning"
echo -e "    □ Pre-write HN first comment"
echo -e "    □ Queue Twitter thread in Typefully (or similar)"
echo ""
echo -e "  ${CYAN}Monday Feb 17 (Night Before)${NC}"
echo -e "    □ Run validate.sh again — verify everything is green"
echo -e "    □ Test landing pages load fast"
echo -e "    □ Test email capture works"
echo -e "    □ Set alarm for 7:45 AM PST"
echo -e "    □ Have coffee ready"
echo ""
echo -e "  ${YELLOW}${BOLD}Tuesday Feb 17 — LAUNCH DAY 🚀${NC}"
echo ""
echo -e "    ${BOLD}7:45 AM PST${NC}  — Wake up, coffee, final check"
echo -e "    ${BOLD}8:00 AM PST${NC}  — Post Show HN: DocSync"
echo -e "    ${BOLD}8:05 AM PST${NC}  — Post HN first comment (technical detail)"
echo -e "    ${BOLD}8:15 AM PST${NC}  — Tweet DocSync launch thread"
echo -e "    ${BOLD}9:00 AM PST${NC}  — Reddit: r/devtools + r/programming"
echo -e "    ${BOLD}10:00 AM PST${NC} — Publish Dev.to blog post"
echo -e "    ${BOLD}10:15 AM PST${NC} — Cross-post to Hashnode"
echo -e "    ${BOLD}10:30 AM PST${NC} — Reddit: r/webdev + r/SideProject + r/selfhosted"
echo -e "    ${BOLD}11:00 AM PST${NC} — Post to OpenClaw Discord"
echo -e "    ${BOLD}All day${NC}      — ENGAGE with every single comment"
echo ""
echo -e "  ${YELLOW}${BOLD}Wednesday Feb 18 — DEPGUARD LAUNCH${NC}"
echo ""
echo -e "    ${BOLD}8:00 AM PST${NC}  — Post Show HN: DepGuard"
echo -e "    ${BOLD}8:15 AM PST${NC}  — Tweet DepGuard launch thread"
echo -e "    ${BOLD}9:00 AM PST${NC}  — Reddit: r/webdev + r/selfhosted"
echo -e "    ${BOLD}10:00 AM PST${NC} — Publish Snyk alternatives blog"
echo ""
echo -e "  ${CYAN}Week of Feb 23 — PRODUCT HUNT${NC}"
echo ""
echo -e "    ${BOLD}Tuesday Feb 24, 12:01 AM PST${NC} — Product Hunt: DocSync"
echo -e "    ${BOLD}Thursday Feb 26, 12:01 AM PST${NC} — Product Hunt: DepGuard"
echo ""

echo -e "${BOLD}  ═══ QUICK COMMANDS ═══${NC}"
echo ""
echo -e "  Deploy everything:     ${CYAN}bash launch/setup.sh${NC}"
echo -e "  Validate before launch: ${CYAN}bash launch/validate.sh${NC}"
echo -e "  Launch Day (DocSync):  ${CYAN}bash launch/go.sh${NC}"
echo -e "  Launch Day (DepGuard): ${CYAN}bash launch/go-depguard.sh${NC}"
echo -e "  Post to Discord:       ${CYAN}bash launch/post-discord.sh${NC}"
echo -e "  Check subscribers:     ${CYAN}curl \$(cat launch/.worker-url)/subscribers?secret=YOUR_SECRET${NC}"
echo ""

# ── Windows Task Scheduler helper ─────────────────────────────────────────
echo -e "${BOLD}  ═══ OPTIONAL: SET WINDOWS REMINDERS ═══${NC}"
echo ""
echo -e "  To set a Windows notification for launch morning:"
echo ""
echo -e "  ${CYAN}schtasks /create /tn \"ClawHub Launch\" /tr \"msg * /time:5 'LAUNCH TIME — run: bash launch/go.sh'\" /sc once /sd 02/17/2026 /st 07:45${NC}"
echo ""
read -p "  Create this Windows reminder? [y/N] " create_reminder
if [ "$create_reminder" = "y" ] || [ "$create_reminder" = "Y" ]; then
  schtasks.exe /create /tn "ClawHub Launch" /tr "msg.exe * /time:5 \"LAUNCH TIME - Run: bash launch/go.sh\"" /sc once /sd 02/17/2026 /st 07:45 2>&1 || warn "Could not create task. Create manually."
  echo -e "  ${GREEN}✓ Reminder set for Tuesday Feb 17 at 7:45 AM${NC}"
fi

echo ""
echo -e "  ${BOLD}${YELLOW}Everything is built. Everything is ready.${NC}"
echo -e "  ${BOLD}${YELLOW}Tuesday we send this to the moon. 🚀🌕${NC}"
echo ""
