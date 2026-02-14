# Deployment Guide

## Overview

Three things need to be deployed:
1. **docsync.pages.dev** — Static landing page (Cloudflare Pages, free)
2. **depguard.pages.dev** — Static landing page (Cloudflare Pages, free)
3. **license-api** — Cloudflare Worker for Stripe checkout + JWT key generation (free tier)

Total infrastructure cost: **$0/month** (Cloudflare free tier covers everything)

---

## Step 1: Stripe Setup

### Create Stripe Account
1. Go to https://dashboard.stripe.com/register
2. Complete verification

### Create Products and Prices

Create these products in Stripe:

**DocSync:**
```
Product: DocSync Pro    → Price: $29/user/month (recurring)
Product: DocSync Team   → Price: $49/user/month (recurring)
```

**DepGuard:**
```
Product: DepGuard Pro   → Price: $19/user/month (recurring)
Product: DepGuard Team  → Price: $39/user/month (recurring)
```

Note the `price_XXXX` IDs for each.

### Set Up Webhook
1. Go to Stripe Dashboard → Developers → Webhooks
2. Add endpoint: `https://license-api.YOUR-SUBDOMAIN.workers.dev/webhook`
3. Select events: `checkout.session.completed`, `invoice.payment_succeeded`, `customer.subscription.deleted`
4. Note the `whsec_XXXX` signing secret

---

## Step 2: Deploy License API (Cloudflare Worker)

### Prerequisites
```bash
npm install -g wrangler
wrangler login
```

### Configure Secrets
```bash
cd sites/license-api

# Set secrets (paste each when prompted)
wrangler secret put STRIPE_SECRET_KEY        # sk_live_...
wrangler secret put STRIPE_WEBHOOK_SECRET    # whsec_...
wrangler secret put JWT_SECRET               # Generate: openssl rand -hex 32

# Set Stripe price IDs
wrangler secret put DOCSYNC_PRO_PRICE        # price_...
wrangler secret put DOCSYNC_TEAM_PRICE       # price_...
wrangler secret put DEPGUARD_PRO_PRICE       # price_...
wrangler secret put DEPGUARD_TEAM_PRICE      # price_...
```

### Deploy
```bash
npm install
wrangler deploy
```

The worker will be available at `https://license-api.YOUR-SUBDOMAIN.workers.dev`

---

## Step 3: Deploy Landing Pages (Cloudflare Pages)

No domains to buy — Cloudflare Pages gives you free `*.pages.dev` subdomains automatically.

### DocSync Landing Page

```bash
# Option A: Cloudflare Pages via Dashboard
# 1. Go to Cloudflare Dashboard → Pages → Create a project
# 2. Choose "Upload assets" (direct upload)
# 3. Name the project "docsync" — this gives you docsync.pages.dev
# 4. Upload the sites/docsync.dev/ folder

# Option B: Wrangler CLI
wrangler pages project create docsync
wrangler pages deploy sites/docsync.dev --project-name=docsync
```

Your site is now live at `https://docsync.pages.dev`

### DepGuard Landing Page

```bash
# Option A: Dashboard — name the project "depguard"

# Option B: Wrangler CLI
wrangler pages project create depguard
wrangler pages deploy sites/depguard.dev --project-name=depguard
```

Your site is now live at `https://depguard.pages.dev`

---

## Step 4: Update API URL (if needed)

The landing pages already point to the license API. After deploying the Worker,
update the `apiBase` URL in both landing pages if your Workers subdomain differs:

**In `sites/docsync.dev/index.html`:**
```javascript
const apiBase = 'https://license-api.YOUR-SUBDOMAIN.workers.dev';
```

**In `sites/depguard.dev/index.html`:**
```javascript
const apiBase = 'https://license-api.YOUR-SUBDOMAIN.workers.dev';
```

Then redeploy the Pages projects.

---

## Step 5: Test the Flow

1. Go to `https://docsync.pages.dev`
2. Click "Get Pro"
3. Should redirect to Stripe Checkout
4. Use test card: `4242 4242 4242 4242`
5. After payment, redirected to success page with license key
6. Copy key → add to `~/.openclaw/openclaw.json`
7. Run `docsync drift` → should validate license and work

---

## Cost Summary

| Item | Monthly Cost |
|------|-------------|
| Cloudflare Pages (2 sites) | $0 |
| Cloudflare Worker (license API) | $0 (100k req/day free) |
| Stripe | 2.9% + $0.30 per transaction |
| **Total** | **$0/month + Stripe fees on sales** |

---

## Optional: Custom Domains Later

If revenue justifies it, you can buy `docsync.dev` and `depguard.dev` (~$12/year each
via Cloudflare Registrar) and add them as custom domains to your Pages projects.
Zero code changes needed — Cloudflare handles the routing automatically.

---

## Monitoring

- **Stripe Dashboard**: Revenue, subscriptions, churn
- **Cloudflare Analytics**: Page views, worker invocations
- **Worker Logs**: `wrangler tail` for real-time logs
