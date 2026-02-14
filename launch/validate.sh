#!/bin/bash
# ============================================================================
# Pre-Launch Validator — Run the night before launch (Monday evening)
# Checks everything is green before Tuesday morning
# ============================================================================

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

PASS=0
FAIL=0
WARN=0

check_pass() { PASS=$((PASS+1)); echo -e "  ${GREEN}✓ PASS${NC}  $1"; }
check_fail() { FAIL=$((FAIL+1)); echo -e "  ${RED}✗ FAIL${NC}  $1"; }
check_warn() { WARN=$((WARN+1)); echo -e "  ${YELLOW}⚠ WARN${NC}  $1"; }

echo ""
echo -e "${BOLD}${CYAN}"
echo "  ╔═══════════════════════════════════════════════════╗"
echo "  ║      🔍 PRE-LAUNCH VALIDATION CHECKLIST          ║"
echo "  ║      Run Monday night before Tuesday launch       ║"
echo "  ╚═══════════════════════════════════════════════════╝"
echo -e "${NC}"

# ── Infrastructure ───────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}  Infrastructure${NC}"

WORKER_URL=$(cat "$REPO_ROOT/launch/.worker-url" 2>/dev/null || echo "")
if [ -z "$WORKER_URL" ]; then
  check_fail "Worker URL not found — run setup.sh first"
else
  # Health check
  HEALTH=$(curl -s --max-time 10 "$WORKER_URL/health" 2>/dev/null || echo "")
  if echo "$HEALTH" | grep -q '"status":"ok"'; then
    check_pass "Worker health endpoint responding"
  else
    check_fail "Worker health endpoint not responding: $WORKER_URL/health"
  fi

  # Test subscribe endpoint
  SUB_TEST=$(curl -s --max-time 10 -X POST "$WORKER_URL/subscribe" \
    -H "Content-Type: application/json" \
    -d '{"email":"test-validate@example.com","product":"docsync","source":"validation"}' 2>/dev/null || echo "")
  if echo "$SUB_TEST" | grep -q '"success":true'; then
    check_pass "Email subscribe endpoint working"
  else
    check_fail "Email subscribe endpoint failed"
  fi

  # Test verify endpoint (should return error for missing key)
  VERIFY_TEST=$(curl -s --max-time 10 "$WORKER_URL/verify" 2>/dev/null || echo "")
  if echo "$VERIFY_TEST" | grep -q '"error"'; then
    check_pass "License verify endpoint responding (correctly rejects empty key)"
  else
    check_fail "License verify endpoint not responding"
  fi

  # Test checkout endpoint (should fail without valid price, but should respond)
  CHECKOUT_TEST=$(curl -s --max-time 10 -X POST "$WORKER_URL/create-checkout" \
    -H "Content-Type: application/json" \
    -d '{"plan":"pro","product":"docsync"}' 2>/dev/null || echo "")
  if echo "$CHECKOUT_TEST" | grep -q '"url"\|"error"'; then
    check_pass "Checkout endpoint responding"
  else
    check_warn "Checkout endpoint may not be configured (check Stripe keys)"
  fi
fi

# ── Landing Pages ────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}  Landing Pages${NC}"

for site in docsync depguard; do
  URL="https://${site}.pages.dev"
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$URL" 2>/dev/null || echo "000")
  if [ "$HTTP_CODE" = "200" ]; then
    check_pass "$site landing page live ($URL)"
  else
    check_fail "$site landing page returned HTTP $HTTP_CODE ($URL)"
  fi

  # Check success page
  SUCCESS_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$URL/success.html" 2>/dev/null || echo "000")
  if [ "$SUCCESS_CODE" = "200" ]; then
    check_pass "$site success page accessible"
  else
    check_warn "$site success page returned HTTP $SUCCESS_CODE"
  fi
done

# ── GitHub Repos ─────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}  GitHub Repos${NC}"

if command -v gh &>/dev/null; then
  GH_USER=$(gh api user --jq '.login' 2>/dev/null || echo "")
  if [ -n "$GH_USER" ]; then
    for repo in docsync depguard; do
      REPO_CHECK=$(gh repo view "$GH_USER/$repo" --json name 2>/dev/null || echo "")
      if [ -n "$REPO_CHECK" ]; then
        check_pass "GitHub repo $GH_USER/$repo exists"
      else
        check_fail "GitHub repo $GH_USER/$repo not found"
      fi
    done
  else
    check_warn "GitHub CLI not authenticated"
  fi
else
  check_warn "GitHub CLI not installed — verify repos manually"
fi

# ── Launch Assets ────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}  Launch Assets${NC}"

ASSETS=(
  "marketing/launch/show-hn-docsync.md:Show HN post (DocSync)"
  "marketing/launch/show-hn-depguard.md:Show HN post (DepGuard)"
  "marketing/launch/reddit-posts.md:Reddit posts"
  "marketing/launch/twitter-threads.md:Twitter threads"
  "marketing/launch/product-hunt.md:Product Hunt plan"
  "marketing/blog/why-your-docs-are-always-stale.md:Blog: Doc drift SEO post"
  "marketing/blog/snyk-alternatives-2026.md:Blog: Snyk alternatives SEO post"
  "marketing/github-repos/docsync-oss-README.md:GitHub README (DocSync)"
  "marketing/github-repos/depguard-oss-README.md:GitHub README (DepGuard)"
  "marketing/MARKETING-PLAYBOOK.md:Marketing playbook"
)

for asset_pair in "${ASSETS[@]}"; do
  IFS=':' read -r file_path desc <<< "$asset_pair"
  if [ -f "$REPO_ROOT/$file_path" ]; then
    LINES=$(wc -l < "$REPO_ROOT/$file_path")
    check_pass "$desc ($LINES lines)"
  else
    check_fail "$desc — FILE MISSING: $file_path"
  fi
done

# ── Skills Published ─────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}  ClawHub Skills${NC}"

for skill in docsync depguard; do
  if [ -f "$REPO_ROOT/$skill/SKILL.md" ]; then
    check_pass "$skill skill published (SKILL.md present)"
  else
    check_fail "$skill skill SKILL.md missing"
  fi
done

# ── Summary ──────────────────────────────────────────────────────────────────
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

TOTAL=$((PASS+FAIL+WARN))
if [ $FAIL -eq 0 ]; then
  echo -e "  ${GREEN}${BOLD}🚀 ALL SYSTEMS GO — $PASS/$TOTAL checks passed ($WARN warnings)${NC}"
  echo ""
  echo -e "  Ready for Tuesday launch. Run: ${BOLD}bash launch/go.sh${NC}"
else
  echo -e "  ${RED}${BOLD}⚠ $FAIL FAILURES — Fix before launch${NC}"
  echo -e "  ${GREEN}$PASS passed${NC} | ${RED}$FAIL failed${NC} | ${YELLOW}$WARN warnings${NC}"
fi

echo ""
echo -e "  Launch: ${BOLD}Tuesday Feb 17, 2026${NC}"
echo -e "  Time:   ${BOLD}8:00 AM PST (HN + Twitter) → 9:00 AM (Reddit) → 10:00 AM (Dev.to)${NC}"
echo ""
