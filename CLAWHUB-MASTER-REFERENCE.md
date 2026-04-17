# ClawHub Master Reference Document

**Last Updated:** 2026-02-16
**Total Skills:** 10
**Total Code Lines:** 25,973 (skills) + 7,245 (landing pages) + 479 (license API) = **33,697 lines**
**Revenue Model:** Free / Pro $19/user/mo / Team $39/user/mo (per skill)
**Max MRR at full adoption:** $580/user/mo (10 skills x $58 avg)

---

## Table of Contents

1. [Infrastructure](#infrastructure)
2. [Stripe Configuration (LIVE)](#stripe-configuration-live)
3. [Skill Inventory](#skill-inventory)
4. [Landing Pages](#landing-pages)
5. [Architecture Patterns](#architecture-patterns)
6. [File Structure Convention](#file-structure-convention)
7. [Worker API Reference](#worker-api-reference)
8. [Deployment Playbook](#deployment-playbook)
9. [Adding a New Skill Checklist](#adding-a-new-skill-checklist)

---

## Infrastructure

### Accounts

| Service | Account | Notes |
|---------|---------|-------|
| **GitHub** | [suhteevah](https://github.com/suhteevah) | All 10 skill repos + clawhub-skill-repo monorepo |
| **Cloudflare** | Account ID: `fa060224cf991e28db66a2b3f3dd0995` | Workers + Pages + KV |
| **Stripe** | Ridge Cell Repair (`acct_1T0qGzA3SuLeinmV`) | **LIVE MODE** |

### Cloudflare Worker (License API)

| Item | Value |
|------|-------|
| Worker name | `license-api` |
| URL | `https://clawhub-api.workers.dev` |
| Source | `J:/clawhub skill repo/sites/license-api/src/worker.js` (479 lines) |
| KV Namespace | `SUBSCRIBERS` -- ID: `5eb3770901e4467081dcb743c4588ec5` |
| Last deployed version | `ce780a77-7aeb-4ddc-b421-12c45db4d97e` |
| Compatibility date | `2024-12-01` |

### Worker Secrets (set via `wrangler secret put`)

```
STRIPE_SECRET_KEY          # sk_live_REDACTED
STRIPE_WEBHOOK_SECRET      # whsec_...
JWT_SECRET                 # Signing key for offline JWT license tokens
ADMIN_SECRET               # For /subscribers endpoint auth
DOCSYNC_PRO_PRICE          # price_...
DOCSYNC_TEAM_PRICE         # price_...
DEPGUARD_PRO_PRICE         # price_...
DEPGUARD_TEAM_PRICE        # price_...
ENVGUARD_PRO_PRICE         # price_1T1g8sA3SuLeinmVM8lmNawh
ENVGUARD_TEAM_PRICE        # price_1T1g8sA3SuLeinmVOHwz708J
GITPULSE_PRO_PRICE         # price_1T1g8sA3SuLeinmVKVaUT00q
GITPULSE_TEAM_PRICE        # price_1T1g8tA3SuLeinmVO9BkLCDJ
MIGRATESAFE_PRO_PRICE      # price_1T1g8tA3SuLeinmVqG4e8wdE
MIGRATESAFE_TEAM_PRICE     # price_1T1g8uA3SuLeinmV52DPnCun
APISHIELD_PRO_PRICE        # price_1T1g8uA3SuLeinmVLeB7h9VG
APISHIELD_TEAM_PRICE       # price_1T1g8vA3SuLeinmVpiRhZKyM
TYPEDRIFT_PRO_PRICE        # price_1T1gOPA3SuLeinmVylCFgOnS
TYPEDRIFT_TEAM_PRICE       # price_1T1gOQA3SuLeinmVkXxoHY9j
CONFIGSAFE_PRO_PRICE       # price_1T1gOSA3SuLeinmVnaFAmu99
CONFIGSAFE_TEAM_PRICE      # price_1T1gOUA3SuLeinmVhcs0HXIo
PERFGUARD_PRO_PRICE        # price_1T1gOWA3SuLeinmVP0XvC565
PERFGUARD_TEAM_PRICE       # price_1T1gOYA3SuLeinmV0QWO9ZYm
LICENSEGUARD_PRO_PRICE     # price_1T1gOaA3SuLeinmVDlJj1GGk
LICENSEGUARD_TEAM_PRICE    # price_1T1gOcA3SuLeinmVE8p9lPQ0
```

---

## Stripe Configuration (LIVE)

### Stripe Live API Key

```
sk_live_REDACTED_SEE_STRIPE_DASHBOARD
```

### Products and Prices

#### Original 6 Skills (Session 7-8)

| Skill | Tier | Product ID | Price ID | Amount |
|-------|------|-----------|----------|--------|
| DocSync | Pro | *(created in session 7)* | *(set as secret)* | $29/mo |
| DocSync | Team | *(created in session 7)* | *(set as secret)* | $49/mo |
| DepGuard | Pro | *(created in session 7)* | *(set as secret)* | $19/mo |
| DepGuard | Team | *(created in session 7)* | *(set as secret)* | $39/mo |
| EnvGuard | Pro | *(created in session 8)* | price_1T1g8sA3SuLeinmVM8lmNawh | $19/mo |
| EnvGuard | Team | *(created in session 8)* | price_1T1g8sA3SuLeinmVOHwz708J | $39/mo |
| GitPulse | Pro | *(created in session 8)* | price_1T1g8sA3SuLeinmVKVaUT00q | $19/mo |
| GitPulse | Team | *(created in session 8)* | price_1T1g8tA3SuLeinmVO9BkLCDJ | $39/mo |
| MigrateSafe | Pro | *(created in session 8)* | price_1T1g8tA3SuLeinmVqG4e8wdE | $19/mo |
| MigrateSafe | Team | *(created in session 8)* | price_1T1g8uA3SuLeinmV52DPnCun | $39/mo |
| APIShield | Pro | *(created in session 8)* | price_1T1g8uA3SuLeinmVLeB7h9VG | $19/mo |
| APIShield | Team | *(created in session 8)* | price_1T1g8vA3SuLeinmVpiRhZKyM | $39/mo |

#### New 4 Skills (Session 9)

| Skill | Tier | Product ID | Price ID | Amount |
|-------|------|-----------|----------|--------|
| TypeDrift | Pro | prod_TzfjIoHmpHK9cn | price_1T1gOPA3SuLeinmVylCFgOnS | $19/mo |
| TypeDrift | Team | prod_TzfjdUYxsXo5XS | price_1T1gOQA3SuLeinmVkXxoHY9j | $39/mo |
| ConfigSafe | Pro | prod_TzfjG1viIIDIb2 | price_1T1gOSA3SuLeinmVnaFAmu99 | $19/mo |
| ConfigSafe | Team | prod_Tzfjk02WUiKPA9 | price_1T1gOUA3SuLeinmVhcs0HXIo | $39/mo |
| PerfGuard | Pro | prod_TzfjHBVdmrtZTt | price_1T1gOWA3SuLeinmVP0XvC565 | $19/mo |
| PerfGuard | Team | prod_Tzfjv7l5dd9VZ5 | price_1T1gOYA3SuLeinmV0QWO9ZYm | $39/mo |
| LicenseGuard | Pro | prod_TzfjsbnR4k7MtR | price_1T1gOaA3SuLeinmVDlJj1GGk | $19/mo |
| LicenseGuard | Team | prod_TzfjAYM9AMFT6m | price_1T1gOcA3SuLeinmVE8p9lPQ0 | $39/mo |

---

## Skill Inventory

### Complete Skill Matrix

| # | Skill | Emoji | What It Does | Languages/Targets | Lines | GitHub | Landing Page |
|---|-------|-------|-------------|-------------------|-------|--------|-------------|
| 1 | **DocSync** | :books: | Keep docs in sync with code | JS/TS/Python/Ruby/Go/Java | 2,102 | [suhteevah/docsync](https://github.com/suhteevah/docsync) | [docsync-1q4.pages.dev](https://docsync-1q4.pages.dev) |
| 2 | **DepGuard** | :shield: | Dependency audit + vulnerability scanning | npm/pip/gem/cargo/go/composer | 1,580 | [suhteevah/depguard](https://github.com/suhteevah/depguard) | [depguard.pages.dev](https://depguard.pages.dev) |
| 3 | **EnvGuard** | :lock: | Pre-commit secret detection | All languages | 2,410 | [suhteevah/envguard](https://github.com/suhteevah/envguard) | [envguard.pages.dev](https://envguard.pages.dev) |
| 4 | **GitPulse** | :bar_chart: | Git workflow analytics + hygiene | Git repos | 2,972 | [suhteevah/gitpulse](https://github.com/suhteevah/gitpulse) | [gitpulse-dad.pages.dev](https://gitpulse-dad.pages.dev) |
| 5 | **MigrateSafe** | :file_cabinet: | Database migration safety checks | SQL/ORM migrations | 2,591 | [suhteevah/migratesafe](https://github.com/suhteevah/migratesafe) | [migratesafe.pages.dev](https://migratesafe.pages.dev) |
| 6 | **APIShield** | :closed_lock_with_key: | API endpoint security auditor | Express/FastAPI/Flask/Django/Rails/Next.js | 2,445 | [suhteevah/apishield](https://github.com/suhteevah/apishield) | [apishield-a78.pages.dev](https://apishield-a78.pages.dev) |
| 7 | **TypeDrift** | :mag: | Code quality erosion detector | TS/JS/Python/Go/Java/Ruby/Kotlin | 2,816 | [suhteevah/typedrift](https://github.com/suhteevah/typedrift) | [typedrift.pages.dev](https://typedrift.pages.dev) |
| 8 | **ConfigSafe** | :whale: | Infrastructure config auditor | Dockerfile/K8s/Terraform/CI-CD/Nginx | 3,002 | [suhteevah/configsafe](https://github.com/suhteevah/configsafe) | [configsafe.pages.dev](https://configsafe.pages.dev) |
| 9 | **PerfGuard** | :zap: | Performance anti-pattern scanner | JS/TS/Python/Ruby/Java/SQL | 2,561 | [suhteevah/perfguard](https://github.com/suhteevah/perfguard) | [perfguard.pages.dev](https://perfguard.pages.dev) |
| 10 | **LicenseGuard** | :scroll: | OSS license compliance scanner | npm/pip/gem/cargo/go/composer/maven/NuGet | 3,494 | [suhteevah/licenseguard](https://github.com/suhteevah/licenseguard) | [licenseguard.pages.dev](https://licenseguard.pages.dev) |

### Detailed File Inventory

#### 1. DocSync (2,102 lines)

| File | Lines | Purpose |
|------|-------|---------|
| scripts/generate.sh | 501 | Doc generation engine |
| scripts/analyze.sh | 294 | Code analysis |
| scripts/drift.sh | 247 | Drift detection |
| scripts/license.sh | 246 | JWT license validation |
| SKILL.md | 195 | Skill manifest |
| scripts/docsync.sh | 174 | CLI dispatcher |
| scripts/hooks-install.sh | 141 | Hook management |
| README.md | 121 | Documentation |
| templates/onboarding.md.tmpl | 52 | Template |
| templates/readme.md.tmpl | 47 | Template |
| templates/architecture.md.tmpl | 36 | Template |
| templates/api-doc.md.tmpl | 27 | Template |
| config/lefthook.yml | 21 | Pre-commit config |

#### 2. DepGuard (1,580 lines)

| File | Lines | Purpose |
|------|-------|---------|
| scripts/scanner.sh | 449 | Vulnerability scanner |
| scripts/policy.sh | 220 | Policy enforcement |
| SKILL.md | 180 | Skill manifest |
| scripts/depguard.sh | 179 | CLI dispatcher |
| scripts/license.sh | 168 | JWT license validation |
| scripts/sbom.sh | 142 | SBOM generation |
| scripts/hooks.sh | 116 | Hook management |
| README.md | 106 | Documentation |
| config/lefthook.yml | 20 | Pre-commit config |

#### 3. EnvGuard (2,410 lines)

| File | Lines | Purpose |
|------|-------|---------|
| scripts/scanner.sh | 935 | Secret scanning engine |
| scripts/envguard.sh | 490 | CLI dispatcher |
| scripts/patterns.sh | 265 | Secret detection patterns |
| SKILL.md | 232 | Skill manifest |
| README.md | 184 | Documentation |
| scripts/license.sh | 182 | JWT license validation |
| templates/report.md.tmpl | 101 | Report template |
| config/lefthook.yml | 21 | Pre-commit config |

#### 4. GitPulse (2,972 lines)

| File | Lines | Purpose |
|------|-------|---------|
| scripts/scorer.sh | 962 | Git scoring engine |
| scripts/hygiene.sh | 657 | Git hygiene checks |
| scripts/ci-lint.sh | 315 | CI config linting |
| scripts/gitpulse.sh | 265 | CLI dispatcher |
| SKILL.md | 251 | Skill manifest |
| README.md | 187 | Documentation |
| scripts/license.sh | 168 | JWT license validation |
| templates/report.md.tmpl | 146 | Report template |
| config/lefthook.yml | 21 | Pre-commit config |

#### 5. MigrateSafe (2,591 lines)

| File | Lines | Purpose |
|------|-------|---------|
| scripts/analyzer.sh | 1,239 | Migration analysis engine |
| scripts/migratesafe.sh | 422 | CLI dispatcher |
| scripts/license.sh | 286 | JWT license validation |
| SKILL.md | 236 | Skill manifest |
| scripts/patterns.sh | 200 | Migration anti-patterns |
| README.md | 157 | Documentation |
| templates/report.md.tmpl | 33 | Report template |
| config/lefthook.yml | 18 | Pre-commit config |

#### 6. APIShield (2,445 lines)

| File | Lines | Purpose |
|------|-------|---------|
| scripts/auditor.sh | 1,141 | API security audit engine |
| scripts/apishield.sh | 320 | CLI dispatcher |
| scripts/license.sh | 295 | JWT license validation |
| SKILL.md | 213 | Skill manifest |
| README.md | 201 | Documentation |
| scripts/patterns.sh | 170 | Security check patterns |
| templates/report.md.tmpl | 88 | Report template |
| config/lefthook.yml | 17 | Pre-commit config |

#### 7. TypeDrift (2,816 lines)

| File | Lines | Purpose |
|------|-------|---------|
| scripts/analyzer.sh | 1,234 | Code quality erosion scanner |
| scripts/patterns.sh | 344 | 80+ erosion patterns (6 languages) |
| scripts/typedrift.sh | 311 | CLI dispatcher |
| scripts/license.sh | 265 | JWT license validation |
| README.md | 262 | Documentation |
| SKILL.md | 256 | Skill manifest |
| templates/report.md.tmpl | 124 | Report template |
| config/lefthook.yml | 20 | Pre-commit config |

#### 8. ConfigSafe (3,002 lines)

| File | Lines | Purpose |
|------|-------|---------|
| scripts/analyzer.sh | 1,476 | Infrastructure config scanner |
| scripts/patterns.sh | 437 | 80+ config patterns (6 config types) |
| scripts/configsafe.sh | 288 | CLI dispatcher |
| scripts/license.sh | 237 | JWT license validation |
| README.md | 230 | Documentation |
| SKILL.md | 216 | Skill manifest |
| templates/report.md.tmpl | 97 | Report template |
| config/lefthook.yml | 21 | Pre-commit config |

#### 9. PerfGuard (2,561 lines)

| File | Lines | Purpose |
|------|-------|---------|
| scripts/analyzer.sh | 1,040 | Performance anti-pattern scanner |
| scripts/perfguard.sh | 343 | CLI dispatcher |
| scripts/license.sh | 296 | JWT license validation |
| SKILL.md | 268 | Skill manifest |
| scripts/patterns.sh | 258 | N+1, sync I/O, memory leak patterns |
| README.md | 246 | Documentation |
| templates/report.md.tmpl | 93 | Report template |
| config/lefthook.yml | 17 | Pre-commit config |

#### 10. LicenseGuard (3,494 lines)

| File | Lines | Purpose |
|------|-------|---------|
| scripts/analyzer.sh | 1,991 | OSS license compliance scanner |
| scripts/patterns.sh | 404 | 60+ license text patterns + SPDX |
| scripts/license.sh | 268 | JWT license validation |
| scripts/licenseguard.sh | 261 | CLI dispatcher |
| SKILL.md | 254 | Skill manifest |
| README.md | 167 | Documentation |
| templates/report.md.tmpl | 129 | Report template |
| config/lefthook.yml | 20 | Pre-commit config |

---

## Landing Pages

### Page Inventory

| Skill | Directory | index.html | success.html | Total | Cloudflare Pages URL |
|-------|-----------|-----------|-------------|-------|---------------------|
| DocSync | sites/docsync.dev/ | 741 | 114 | 855 | https://docsync-1q4.pages.dev |
| DepGuard | sites/depguard.dev/ | 469 | 73 | 542 | https://depguard.pages.dev |
| EnvGuard | sites/envguard.dev/ | 640 | 99 | 739 | https://envguard.pages.dev |
| GitPulse | sites/gitpulse.dev/ | 735 | 74 | 809 | https://gitpulse-dad.pages.dev |
| MigrateSafe | sites/migratesafe.dev/ | 653 | 99 | 752 | https://migratesafe.pages.dev |
| APIShield | sites/apishield.dev/ | 628 | 99 | 727 | https://apishield-a78.pages.dev |
| TypeDrift | sites/typedrift.dev/ | 641 | 98 | 739 | https://typedrift.pages.dev |
| ConfigSafe | sites/configsafe.dev/ | 606 | 99 | 705 | https://configsafe.pages.dev |
| PerfGuard | sites/perfguard.dev/ | 581 | 99 | 680 | https://perfguard.pages.dev |
| LicenseGuard | sites/licenseguard.dev/ | 597 | 100 | 697 | https://licenseguard.pages.dev |
| **Total** | | | | **7,245** | |

### Landing Page Structure (every page follows this)

1. **Nav** -- Sticky dark nav with emoji brand, links to Features/Compare/Pricing/GitHub
2. **Hero** -- Provocative headline, subtitle, `clawhub install <skill>` copy bar, terminal demo
3. **Problem Statement** -- Fear-driven one-liner with stats
4. **Stats Bar** -- 3 danger-colored statistics
5. **Features Grid** -- 6 feature cards with emoji icons
6. **Comparison Table** -- Us vs 3 competitors across 10+ dimensions
7. **Pricing** -- 3-tier grid (Free / Pro $19 featured / Team $39)
8. **Email Subscribe** -- Posts to `clawhub-api.workers.dev/subscribe`
9. **CTA** -- Final install bar with urgency copy
10. **Footer** -- Brand + GitHub + Support links

### success.html Pattern

- Fetches license key from `clawhub-api.workers.dev/session/{session_id}`
- Displays key in copy-to-clipboard box
- 5-step setup instructions specific to the skill
- Error state with support email fallback

---

## Architecture Patterns

### Skill Code Architecture

Every skill follows this exact pattern:

```
skillname/
  SKILL.md              # Frontmatter manifest (openclaw metadata)
  README.md             # Marketing README with badges
  scripts/
    skillname.sh        # CLI dispatcher (routes commands)
    license.sh          # JWT offline license validation
    patterns.sh         # Detection patterns (REGEX|SEVERITY|ID|DESC|REC)
    analyzer.sh         # Core scanning engine (largest file)
  config/
    lefthook.yml        # Pre-commit hook configuration
  templates/
    report.md.tmpl      # Markdown report template with {{PLACEHOLDERS}}
```

### SKILL.md Frontmatter

```yaml
---
name: skillname
emoji: "X"
version: "1.0.0"
description: "One-line description"
author: "ClawHub"
license: "MIT"
homepage: "https://skillname.pages.dev"
repository: "https://github.com/suhteevah/skillname"
primaryEnv: "SKILLNAME_LICENSE_KEY"
requires:
  bins:
    - bash
    - grep
    - sed
    - awk
  optionalBins:
    - jq
    - python3
    - node
lefthook:
  install: "config/lefthook.yml"
os:
  - linux
  - macos
  - windows
---
```

### License Validation Pattern (license.sh)

Every skill's `license.sh` implements these functions:

1. `get_skillname_key()` -- Reads from `SKILLNAME_LICENSE_KEY` env var or `~/.openclaw/openclaw.json`
2. `decode_jwt_payload()` -- Base64url decode with 3 fallbacks (Linux/macOS/Git Bash)
3. `extract_field()` -- JSON field extraction via python3/node/jq/grep
4. `validate_license()` -- Checks issuer=`license-api`, product=`skillname`, expiry, tier
5. `check_skillname_license()` -- Tier-gated access (free=0, pro=1, team=2, enterprise=3)
6. `get_skillname_tier()` -- Returns current tier as string
7. `show_skillname_status()` -- Formatted display of license info

### Pattern Format

All `patterns.sh` files use pipe-delimited arrays:

```
REGEX|SEVERITY|CHECK_ID|DESCRIPTION|RECOMMENDATION
```

Severity levels: `CRITICAL`, `HIGH`, `MEDIUM`, `LOW`

### Scoring System

All skills score 0-100 with letter grades:

| Grade | Score Range |
|-------|-------------|
| A | 90 -- 100 |
| B | 80 -- 89 |
| C | 70 -- 79 |
| D | 60 -- 69 |
| F | 0 -- 59 |

Exit codes: `0` = pass (score >= 70), `1` = fail

### Tier Gating

| Feature | Free | Pro ($19/mo) | Team ($39/mo) |
|---------|------|-------------|--------------|
| Scan (limited) | 5 files | Unlimited | Unlimited |
| Score + grade | Yes | Yes | Yes |
| Pre-commit hooks | No | Yes | Yes |
| Reports | No | Yes | Yes |
| Advanced features | No | No | Yes |

---

## Worker API Reference

### Endpoints

| Method | Path | Description | Auth |
|--------|------|-------------|------|
| POST | `/create-checkout` | Create Stripe checkout session | None |
| POST | `/webhook` | Stripe webhook handler | Stripe signature |
| GET | `/verify` | Verify JWT license key | Bearer token |
| POST | `/subscribe` | Email list signup | None |
| GET | `/subscribers` | List subscribers | Admin secret |
| GET | `/session/:id` | Get checkout session details (for success page) | None |

### POST /create-checkout

```json
{
  "product": "envguard",
  "plan": "pro",
  "seats": 1
}
```

Returns: `{ "url": "https://checkout.stripe.com/..." }`

Valid products: `docsync`, `depguard`, `envguard`, `gitpulse`, `migratesafe`, `apishield`, `typedrift`, `configsafe`, `perfguard`, `licenseguard`

Valid plans: `pro`, `team`

### Webhook Flow

1. Stripe sends `checkout.session.completed` event
2. Worker retrieves session + subscription details
3. Worker generates JWT license key with claims:
   - `iss`: `license-api`
   - `sub`: customer email
   - `product`: skill name
   - `tier`: `pro` or `team`
   - `seats`: seat count
   - `exp`: subscription period end
4. Key stored in KV for retrieval via `/session/:id`

---

## Deployment Playbook

### Deploy a Landing Page

```bash
cd "J:/clawhub skill repo/sites/skillname.dev"
npx wrangler pages deploy . --project-name skillname --commit-dirty=true
```

### Deploy the License API Worker

```bash
cd "J:/clawhub skill repo/sites/license-api"
npx wrangler deploy
```

### Set a Worker Secret

```bash
cd "J:/clawhub skill repo/sites/license-api"
echo "price_XXXX" | npx wrangler secret put SKILLNAME_PRO_PRICE
echo "price_XXXX" | npx wrangler secret put SKILLNAME_TEAM_PRICE
```

### Push a Skill to GitHub

```bash
cd "J:/clawhub skill repo/skillname"
git init && git add -A && git commit -m "Initial commit"
git branch -M main
git remote add origin https://github.com/suhteevah/skillname.git
git push -u origin main
```

### Create a Cloudflare Pages Project

```bash
npx wrangler pages project create skillname --production-branch main
```

---

## Adding a New Skill Checklist

### 1. Code (8 files)

- [ ] `SKILL.md` -- Frontmatter with openclaw metadata
- [ ] `README.md` -- Marketing README with badges and comparison table
- [ ] `scripts/skillname.sh` -- CLI dispatcher (~250-350 lines)
- [ ] `scripts/license.sh` -- JWT validation (~250-300 lines)
- [ ] `scripts/patterns.sh` -- Detection patterns (~200-450 lines)
- [ ] `scripts/analyzer.sh` -- Core engine (~1,000-2,000 lines)
- [ ] `config/lefthook.yml` -- Pre-commit hook config (~20 lines)
- [ ] `templates/report.md.tmpl` -- Report template (~90-130 lines)

### 2. Stripe (LIVE)

- [ ] Create Pro product: `curl --data-urlencode "name=SkillName Pro" ...`
- [ ] Create Team product: `curl --data-urlencode "name=SkillName Team" ...`
- [ ] Create Pro price ($19/mo recurring)
- [ ] Create Team price ($39/mo recurring)
- [ ] Set worker secrets: `SKILLNAME_PRO_PRICE`, `SKILLNAME_TEAM_PRICE`

### 3. Worker Update

- [ ] Add `priceMap` entries in worker.js
- [ ] Add `successUrls` entry
- [ ] Add `cancelUrls` entry
- [ ] Add env variable comment at top
- [ ] Deploy worker: `npx wrangler deploy`

### 4. Landing Page (2 files)

- [ ] `sites/skillname.dev/index.html` -- Full landing page (~600-750 lines)
- [ ] `sites/skillname.dev/success.html` -- Post-purchase page (~100 lines)
- [ ] Create Cloudflare Pages project
- [ ] Deploy: `npx wrangler pages deploy`

### 5. GitHub

- [ ] Create repo: `gh repo create suhteevah/skillname --public`
- [ ] Init, add, commit, push

---

## Session History

| Session | Date | What Was Built |
|---------|------|---------------|
| 1-5 | (earlier) | Initial ClawHub concept, CLI framework |
| 6 | 2026-02-15 | DocSync + DepGuard skills, landing pages |
| 7 | 2026-02-15 | EnvGuard + GitPulse + MigrateSafe + APIShield skills |
| 8 | 2026-02-15 | All 6 landing pages deployed, Stripe switched to LIVE, all 6 products created |
| 9 | 2026-02-16 | TypeDrift + ConfigSafe + PerfGuard + LicenseGuard (4 skills + 4 landing pages + Stripe + deploy) |

---

## Key Metrics

| Metric | Value |
|--------|-------|
| Total skills | 10 |
| Total skill code lines | 25,973 |
| Total landing page lines | 7,245 |
| Total worker lines | 479 |
| **Grand total lines** | **33,697** |
| Total files (skills) | ~80 (8 per skill) |
| Total files (sites) | 20 (2 per skill) |
| Stripe LIVE products | 20 (2 per skill) |
| Stripe LIVE prices | 20 (2 per skill) |
| GitHub repos | 10 |
| Cloudflare Pages projects | 10 |
| Worker secrets | 24+ |
| Potential MRR per user (all Pro) | $188/mo |
| Potential MRR per user (all Team) | $388/mo |

---

*This document is the single source of truth for the entire ClawHub ecosystem.*
*Local path: `J:/clawhub skill repo/CLAWHUB-MASTER-REFERENCE.md`*
