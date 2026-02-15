#!/bin/bash
# ============================================================================
# ClawHub Launch Setup — Run this BEFORE Tuesday
# Handles: Wrangler auth, Worker deploy, Pages deploy, GitHub repos, Stripe
# ============================================================================

set -e

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

step=0
total_steps=12

progress() {
  step=$((step + 1))
  echo ""
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}  [$step/$total_steps] $1${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

success() { echo -e "  ${GREEN}✓${NC} $1"; }
warn()    { echo -e "  ${YELLOW}⚠${NC} $1"; }
fail()    { echo -e "  ${RED}✗${NC} $1"; }
info()    { echo -e "  ${CYAN}→${NC} $1"; }

echo ""
echo -e "${BOLD}${CYAN}"
echo "  ╔═══════════════════════════════════════════════════╗"
echo "  ║        🚀 CLAWHUB LAUNCH SETUP SCRIPT 🚀         ║"
echo "  ║                                                   ║"
echo "  ║  DocSync + DepGuard — Tuesday Feb 17 Launch       ║"
echo "  ║  Target: \$0 budget → first revenue in 30 days     ║"
echo "  ╚═══════════════════════════════════════════════════╝"
echo -e "${NC}"

# ──────────────────────────────────────────────────────────────────────────────
progress "Checking prerequisites"

MISSING=0

if command -v npx &>/dev/null; then
  WRANGLER_VER=$(npx wrangler --version 2>/dev/null || echo "not found")
  success "Wrangler: $WRANGLER_VER"
else
  fail "npx not found — install Node.js first"
  MISSING=1
fi

if command -v gh &>/dev/null; then
  success "GitHub CLI: $(gh --version | head -1)"
else
  warn "GitHub CLI not installed — will skip repo creation (do it manually)"
  echo ""
  echo -e "    Install: ${BOLD}winget install GitHub.cli${NC}"
  echo -e "    Or:      ${BOLD}https://cli.github.com${NC}"
  echo ""
fi

if command -v node &>/dev/null; then
  success "Node.js: $(node --version)"
else
  fail "Node.js not found"
  MISSING=1
fi

if [ $MISSING -eq 1 ]; then
  fail "Missing prerequisites. Install them and re-run."
  exit 1
fi

# ──────────────────────────────────────────────────────────────────────────────
progress "Authenticating Wrangler (Cloudflare)"

AUTH_STATUS=$(npx wrangler whoami 2>&1 || true)
if echo "$AUTH_STATUS" | grep -q "not authenticated"; then
  info "Opening browser for Cloudflare login..."
  npx wrangler login
  success "Authenticated with Cloudflare"
else
  ACCOUNT=$(echo "$AUTH_STATUS" | grep -oP "(?<=\| ).*(?= \|)" | head -1 || echo "unknown")
  success "Already authenticated: $ACCOUNT"
fi

# ──────────────────────────────────────────────────────────────────────────────
progress "Installing Worker dependencies"

cd "$REPO_ROOT/sites/license-api"
npm install
success "Dependencies installed"

# ──────────────────────────────────────────────────────────────────────────────
progress "Deploying License API Worker"

info "Deploying to Cloudflare Workers..."
DEPLOY_OUTPUT=$(npx wrangler deploy 2>&1)
echo "$DEPLOY_OUTPUT"

# Extract the worker URL
WORKER_URL=$(echo "$DEPLOY_OUTPUT" | grep -oP 'https://[^\s]+workers\.dev' | head -1 || echo "")
if [ -n "$WORKER_URL" ]; then
  success "Worker deployed: $WORKER_URL"
  echo "$WORKER_URL" > "$REPO_ROOT/launch/.worker-url"
else
  warn "Could not extract Worker URL. Check output above."
  read -p "  Enter your Worker URL manually: " WORKER_URL
  echo "$WORKER_URL" > "$REPO_ROOT/launch/.worker-url"
fi

# ──────────────────────────────────────────────────────────────────────────────
progress "Creating KV Namespace for email subscribers"

KV_OUTPUT=$(npx wrangler kv namespace create SUBSCRIBERS 2>&1)
echo "$KV_OUTPUT"

KV_ID=$(echo "$KV_OUTPUT" | grep -oP '(?<=id = ")[^"]+' || echo "")
if [ -n "$KV_ID" ]; then
  success "KV Namespace created: $KV_ID"

  # Update wrangler.toml with the KV ID
  cd "$REPO_ROOT/sites/license-api"

  # Replace the commented KV section with the real one
  cat > wrangler.toml.tmp << TOML
name = "license-api"
main = "src/worker.js"
compatibility_date = "2024-12-01"

[vars]
# Set these via: npx wrangler secret put <NAME>
# STRIPE_SECRET_KEY, STRIPE_WEBHOOK_SECRET, JWT_SECRET, ADMIN_SECRET
# DOCSYNC_PRO_PRICE, DOCSYNC_TEAM_PRICE, DEPGUARD_PRO_PRICE, DEPGUARD_TEAM_PRICE

[[kv_namespaces]]
binding = "SUBSCRIBERS"
id = "$KV_ID"
TOML
  mv wrangler.toml.tmp wrangler.toml
  success "Updated wrangler.toml with KV namespace ID"

  # Redeploy with KV binding
  info "Redeploying worker with KV binding..."
  npx wrangler deploy 2>&1
  success "Worker redeployed with KV"
else
  warn "KV namespace may already exist or creation failed. Check output above."
fi

# ──────────────────────────────────────────────────────────────────────────────
progress "Setting Worker Secrets"

echo ""
echo -e "  ${BOLD}Now we need to set your secrets.${NC}"
echo -e "  You'll need your Stripe dashboard open: ${CYAN}https://dashboard.stripe.com${NC}"
echo ""

secrets_to_set=(
  "STRIPE_SECRET_KEY:Stripe secret key (sk_live_... or sk_test_...)"
  "STRIPE_WEBHOOK_SECRET:Stripe webhook signing secret (whsec_...)"
  "JWT_SECRET:A random string for signing license keys"
  "ADMIN_SECRET:A random string for the admin subscriber list endpoint"
)

for secret_pair in "${secrets_to_set[@]}"; do
  IFS=':' read -r secret_name secret_desc <<< "$secret_pair"
  echo ""
  info "$secret_desc"

  # Check if already set by trying to read (will fail, but wrangler shows a message)
  read -p "  Enter $secret_name (or press Enter to skip if already set): " secret_val
  if [ -n "$secret_val" ]; then
    echo "$secret_val" | npx wrangler secret put "$secret_name" 2>&1
    success "$secret_name set"
  else
    warn "Skipped $secret_name"
  fi
done

echo ""
echo -e "  ${BOLD}Stripe Price IDs${NC} — Create products in Stripe Dashboard first"
echo -e "  Products → Create Product → Add recurring prices"
echo ""

price_secrets=(
  "DOCSYNC_PRO_PRICE:DocSync Pro price ID (price_...)"
  "DOCSYNC_TEAM_PRICE:DocSync Team price ID (price_...)"
  "DEPGUARD_PRO_PRICE:DepGuard Pro price ID (price_...)"
  "DEPGUARD_TEAM_PRICE:DepGuard Team price ID (price_...)"
)

for secret_pair in "${price_secrets[@]}"; do
  IFS=':' read -r secret_name secret_desc <<< "$secret_pair"
  read -p "  $secret_desc: " secret_val
  if [ -n "$secret_val" ]; then
    echo "$secret_val" | npx wrangler secret put "$secret_name" 2>&1
    success "$secret_name set"
  else
    warn "Skipped $secret_name (set later via: npx wrangler secret put $secret_name)"
  fi
done

# ──────────────────────────────────────────────────────────────────────────────
progress "Updating landing pages with Worker URL"

WORKER_URL=$(cat "$REPO_ROOT/launch/.worker-url" 2>/dev/null || echo "")

if [ -n "$WORKER_URL" ]; then
  info "Updating API endpoints in landing pages to: $WORKER_URL"

  # Update DocSync landing page
  if [ -f "$REPO_ROOT/sites/docsync.dev/index.html" ]; then
    sed -i "s|https://license-api\.docsync-depguard\.workers\.dev|$WORKER_URL|g" "$REPO_ROOT/sites/docsync.dev/index.html"
    sed -i "s|https://license-api\..*\.workers\.dev|$WORKER_URL|g" "$REPO_ROOT/sites/docsync.dev/index.html"
    success "Updated DocSync landing page API URL"
  fi

  # Update DepGuard landing page
  if [ -f "$REPO_ROOT/sites/depguard.dev/index.html" ]; then
    sed -i "s|https://license-api\.docsync-depguard\.workers\.dev|$WORKER_URL|g" "$REPO_ROOT/sites/depguard.dev/index.html"
    sed -i "s|https://license-api\..*\.workers\.dev|$WORKER_URL|g" "$REPO_ROOT/sites/depguard.dev/index.html"
    success "Updated DepGuard landing page API URL"
  fi

  # Update success pages
  for page in "$REPO_ROOT/sites/docsync.dev/success.html" "$REPO_ROOT/sites/depguard.dev/success.html"; do
    if [ -f "$page" ]; then
      sed -i "s|https://license-api\.docsync-depguard\.workers\.dev|$WORKER_URL|g" "$page"
      sed -i "s|https://license-api\..*\.workers\.dev|$WORKER_URL|g" "$page"
    fi
  done
  success "Updated all success pages"
else
  warn "No Worker URL found. Update landing pages manually."
fi

# ──────────────────────────────────────────────────────────────────────────────
progress "Deploying DocSync Landing Page"

info "Creating Cloudflare Pages project: docsync"
npx wrangler pages project create docsync --production-branch main 2>&1 || warn "Project may already exist"

info "Deploying to Cloudflare Pages..."
PAGES_OUTPUT=$(npx wrangler pages deploy "$REPO_ROOT/sites/docsync.dev" --project-name=docsync 2>&1)
echo "$PAGES_OUTPUT"

DOCSYNC_URL=$(echo "$PAGES_OUTPUT" | grep -oP 'https://[^\s]+\.pages\.dev' | head -1 || echo "https://docsync-1q4.pages.dev")
success "DocSync deployed: $DOCSYNC_URL"

# ──────────────────────────────────────────────────────────────────────────────
progress "Deploying DepGuard Landing Page"

info "Creating Cloudflare Pages project: depguard"
npx wrangler pages project create depguard --production-branch main 2>&1 || warn "Project may already exist"

info "Deploying to Cloudflare Pages..."
PAGES_OUTPUT=$(npx wrangler pages deploy "$REPO_ROOT/sites/depguard.dev" --project-name=depguard 2>&1)
echo "$PAGES_OUTPUT"

DEPGUARD_URL=$(echo "$PAGES_OUTPUT" | grep -oP 'https://[^\s]+\.pages\.dev' | head -1 || echo "https://depguard.pages.dev")
success "DepGuard deployed: $DEPGUARD_URL"

# ──────────────────────────────────────────────────────────────────────────────
progress "Creating GitHub Repositories"

if command -v gh &>/dev/null; then
  GH_AUTH=$(gh auth status 2>&1 || true)
  if echo "$GH_AUTH" | grep -q "Logged in"; then
    GH_USER=$(gh api user --jq '.login' 2>/dev/null || echo "")

    if [ -n "$GH_USER" ]; then
      info "Creating docsync repo as $GH_USER/docsync..."

      # Create docsync repo
      DOCSYNC_REPO_DIR=$(mktemp -d)
      cd "$DOCSYNC_REPO_DIR"
      git init
      cp "$REPO_ROOT/marketing/github-repos/docsync-oss-README.md" README.md
      echo "MIT License" > LICENSE
      git add -A
      git commit -m "Initial commit: DocSync — documentation that stays alive"

      gh repo create docsync --public --description "Documentation that stays alive — auto-generate, detect drift, enforce via git hooks" --source=. --push 2>&1 || warn "Repo may already exist"
      success "docsync repo created"

      # Create depguard repo
      DEPGUARD_REPO_DIR=$(mktemp -d)
      cd "$DEPGUARD_REPO_DIR"
      git init
      cp "$REPO_ROOT/marketing/github-repos/depguard-oss-README.md" README.md
      echo "MIT License" > LICENSE
      git add -A
      git commit -m "Initial commit: DepGuard — dependency audit + license compliance"

      gh repo create depguard --public --description "Dependency audit + license compliance — 10 package managers, 100% local" --source=. --push 2>&1 || warn "Repo may already exist"
      success "depguard repo created"

      # Add topics
      gh api -X PUT "repos/$GH_USER/docsync/topics" -f '{"names":["developer-tools","documentation","cli","git-hooks","tree-sitter","code-quality","devtools"]}' 2>/dev/null || true
      gh api -X PUT "repos/$GH_USER/depguard/topics" -f '{"names":["security","dependency-audit","license-compliance","sbom","cli","devops","devtools"]}' 2>/dev/null || true
      success "Added repo topics"

      cd "$REPO_ROOT"
      rm -rf "$DOCSYNC_REPO_DIR" "$DEPGUARD_REPO_DIR"
    fi
  else
    warn "GitHub CLI not authenticated. Run: gh auth login"
  fi
else
  warn "GitHub CLI not installed. Create repos manually:"
  echo "    https://github.com/new — name: docsync"
  echo "    https://github.com/new — name: depguard"
fi

# ──────────────────────────────────────────────────────────────────────────────
progress "Configuring Stripe Webhook"

echo ""
echo -e "  ${BOLD}Configure your Stripe webhook:${NC}"
echo ""
echo -e "  1. Go to: ${CYAN}https://dashboard.stripe.com/webhooks${NC}"
echo -e "  2. Click 'Add endpoint'"
echo -e "  3. URL: ${BOLD}${WORKER_URL}/webhook${NC}"
echo -e "  4. Select events:"
echo -e "     • checkout.session.completed"
echo -e "     • invoice.payment_succeeded"
echo -e "     • customer.subscription.deleted"
echo -e "  5. Copy the signing secret (whsec_...)"
echo -e "  6. If not already set: ${BOLD}npx wrangler secret put STRIPE_WEBHOOK_SECRET${NC}"
echo ""
read -p "  Press Enter when webhook is configured (or type 'skip')... " webhook_response

if [ "$webhook_response" != "skip" ]; then
  success "Webhook configured"
fi

# ──────────────────────────────────────────────────────────────────────────────
progress "Running Health Checks"

echo ""
if [ -n "$WORKER_URL" ]; then
  info "Testing Worker health..."
  HEALTH=$(curl -s "$WORKER_URL/health" 2>/dev/null || echo '{"error":"unreachable"}')
  if echo "$HEALTH" | grep -q '"status":"ok"'; then
    success "Worker health: OK"
  else
    warn "Worker health check failed: $HEALTH"
  fi
else
  warn "No Worker URL to test"
fi

if [ -n "$DOCSYNC_URL" ]; then
  info "Testing DocSync landing page..."
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$DOCSYNC_URL" 2>/dev/null || echo "000")
  if [ "$HTTP_CODE" = "200" ]; then
    success "DocSync landing page: HTTP $HTTP_CODE"
  else
    warn "DocSync landing page returned: HTTP $HTTP_CODE"
  fi
fi

if [ -n "$DEPGUARD_URL" ]; then
  info "Testing DepGuard landing page..."
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$DEPGUARD_URL" 2>/dev/null || echo "000")
  if [ "$HTTP_CODE" = "200" ]; then
    success "DepGuard landing page: HTTP $HTTP_CODE"
  else
    warn "DepGuard landing page returned: HTTP $HTTP_CODE"
  fi
fi

# ──────────────────────────────────────────────────────────────────────────────
# Summary
echo ""
echo -e "${BOLD}${GREEN}"
echo "  ╔═══════════════════════════════════════════════════╗"
echo "  ║           ✅ SETUP COMPLETE                       ║"
echo "  ╚═══════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""
echo -e "  ${BOLD}Deployed:${NC}"
echo -e "    Worker:   ${CYAN}${WORKER_URL}${NC}"
echo -e "    DocSync:  ${CYAN}${DOCSYNC_URL}${NC}"
echo -e "    DepGuard: ${CYAN}${DEPGUARD_URL}${NC}"
echo ""
echo -e "  ${BOLD}Next steps:${NC}"
echo -e "    1. Test a checkout flow in Stripe test mode"
echo -e "    2. Run the pre-launch validator: ${BOLD}bash launch/validate.sh${NC}"
echo -e "    3. On Tuesday Feb 17 at 8:00 AM PST: ${BOLD}bash launch/go.sh${NC}"
echo ""
echo -e "  ${BOLD}${YELLOW}🚀 T-minus $(( ($(date -d '2026-02-17' +%s) - $(date +%s)) / 3600 )) hours until launch${NC}"
echo ""
