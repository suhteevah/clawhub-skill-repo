# Stripe Product Setup — Quick Reference

## Your 4 Products to Create

Go to **https://dashboard.stripe.com/products** → Click **+ Add product** for each:

---

### 1. DocSync Pro — $29/month

**Name:** `DocSync Pro`

**Description:**
```
DocSync Pro — Automated documentation management for individual developers.

Includes:
• Git pre-commit hooks that block merges when docs drift out of sync
• Real-time drift detection across 40+ programming languages
• One-command auto-fix to regenerate stale documentation
• Tree-sitter powered AST analysis (fast, deterministic, offline)
• Lifetime access to updates

Perfect for solo developers and freelancers who want documentation that stays alive.
```

**Pricing:** Recurring → Monthly → $29.00 USD

**After creating:** Copy the Price ID (starts with `price_...`)

---

### 2. DocSync Team — $49/month

**Name:** `DocSync Team`

**Description:**
```
DocSync Team — Living documentation for development teams.

Everything in Pro, plus:
• Auto-generated onboarding guides for new team members
• Architecture documentation that updates with your codebase
• Team-wide drift reports and compliance dashboards
• Priority support and feature requests

Built for teams of 2-20 developers who need documentation
that scales with their codebase.
```

**Pricing:** Recurring → Monthly → $49.00 USD per seat

**After creating:** Copy the Price ID

---

### 3. DepGuard Pro — $19/month

**Name:** `DepGuard Pro`

**Description:**
```
DepGuard Pro — Continuous dependency security for developers.

Includes:
• Git pre-commit hooks that block vulnerable dependency changes
• Automatic vulnerability fix suggestions (npm, pip, cargo, go)
• Continuous file-watcher monitoring for lockfile changes
• Covers 10 package managers: npm, yarn, pnpm, pip, cargo, go,
  composer, bundler, maven, gradle
• 100% local — your code never leaves your machine

Stop shipping vulnerable dependencies. Get alerted before they hit production.
```

**Pricing:** Recurring → Monthly → $19.00 USD

**After creating:** Copy the Price ID

---

### 4. DepGuard Team — $39/month

**Name:** `DepGuard Team`

**Description:**
```
DepGuard Team — License compliance and security governance for teams.

Everything in Pro, plus:
• CycloneDX 1.5 SBOM generation for compliance requirements
• License policy enforcement (block GPL, AGPL, or custom rules)
• Full compliance reports for audits and legal review
• Team-wide vulnerability dashboards
• Priority support and SLA

Essential for teams shipping software with open-source dependencies
who need license compliance and audit trails.
```

**Pricing:** Recurring → Monthly → $39.00 USD per seat

**After creating:** Copy the Price ID

---

## After Creating All 4 Products

You'll have 4 Price IDs. Set them as Cloudflare Worker secrets:

```bash
# In Git Bash, from the license-api directory:
cd "J:/clawhub skill repo/sites/license-api"

echo "price_XXXXX" | npx wrangler secret put DOCSYNC_PRO_PRICE
echo "price_XXXXX" | npx wrangler secret put DOCSYNC_TEAM_PRICE
echo "price_XXXXX" | npx wrangler secret put DEPGUARD_PRO_PRICE
echo "price_XXXXX" | npx wrangler secret put DEPGUARD_TEAM_PRICE
```

## Webhook Setup

1. Go to **https://dashboard.stripe.com/webhooks**
2. Click **+ Add endpoint**
3. Endpoint URL: `https://license-api.<your-account>.workers.dev/webhook`
4. Select these events:
   - `checkout.session.completed`
   - `invoice.payment_succeeded`
   - `customer.subscription.deleted`
5. Click **Add endpoint**
6. Copy the **Signing secret** (starts with `whsec_...`)
7. Set it as a Worker secret:
   ```bash
   echo "whsec_XXXXX" | npx wrangler secret put STRIPE_WEBHOOK_SECRET
   ```

## Other Required Secrets

```bash
# Your Stripe secret key (from https://dashboard.stripe.com/apikeys)
echo "sk_live_XXXXX" | npx wrangler secret put STRIPE_SECRET_KEY

# Random strings for JWT signing and admin access
echo "$(openssl rand -hex 32)" | npx wrangler secret put JWT_SECRET
echo "$(openssl rand -hex 16)" | npx wrangler secret put ADMIN_SECRET
```

## Business Website for Stripe

Your business website is live at: **https://suhteevah.github.io/chicocellrepair/**
(Deployed to GitHub Pages, repo: github.com/suhteevah/chicocellrepair)

Once DNS is configured (see DNS-SETUP.md), it will also be available at:
**https://chicocellrepair.com**

In Stripe Settings → Business details → Website: enter `https://suhteevah.github.io/chicocellrepair/`
(Update to `https://chicocellrepair.com` after DNS propagation)

---

**Total time: ~5 minutes to create 4 products and set secrets.**
