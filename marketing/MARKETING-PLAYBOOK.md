# ClawHub Revenue Playbook: DocSync + DepGuard

## $0 Budget → First Revenue in 30 Days

**Products:** DocSync (documentation drift prevention) + DepGuard (dependency audit & license compliance)
**Hosting:** Cloudflare Pages (free) + Cloudflare Workers (free tier: 100K req/day)
**Payments:** Stripe (2.9% + $0.30 per transaction)
**Total fixed cost:** $0/month

---

## Revenue Targets

| Milestone | Target Timeline | MRR |
|-----------|----------------|-----|
| First paying customer | Week 2-4 | $19-49 |
| 10 paying users | Month 2-3 | $190-490 |
| $500 MRR | Month 3-4 | $500 |
| $1,000 MRR | Month 4-6 | $1,000 |
| $5,000 MRR | Month 8-12 | $5,000 |

**Benchmark:** 2-5% freemium conversion rate is average SaaS. Top performers hit 5-10%. Target 4-8% within 90 days.

---

## Assets Already Built

| Asset | File | Status |
|-------|------|--------|
| DocSync OSS GitHub README | `marketing/github-repos/docsync-oss-README.md` | Ready |
| DepGuard OSS GitHub README | `marketing/github-repos/depguard-oss-README.md` | Ready |
| SEO Blog: "Why Your Docs Are Always Stale" | `marketing/blog/why-your-docs-are-always-stale.md` | Ready |
| SEO Blog: "Best Snyk Alternatives 2026" | `marketing/blog/snyk-alternatives-2026.md` | Ready |
| Show HN: DocSync | `marketing/launch/show-hn-docsync.md` | Ready |
| Show HN: DepGuard | `marketing/launch/show-hn-depguard.md` | Ready |
| Reddit Posts (5 subreddits) | `marketing/launch/reddit-posts.md` | Ready |
| Twitter/X Threads (3 threads) | `marketing/launch/twitter-threads.md` | Ready |
| Product Hunt Launch Plan | `marketing/launch/product-hunt.md` | Ready |
| DocSync Landing Page | `sites/docsync.dev/index.html` | Ready |
| DepGuard Landing Page | `sites/depguard.dev/index.html` | Ready |
| License API (Stripe + JWT) | `sites/license-api/src/worker.js` | Ready |
| Email Capture (KV-backed) | Built into landing pages + API | Ready |

---

## The Funnel

```
GitHub OSS Repos (free users)
       ↓
Landing Pages (docsync.pages.dev / depguard.pages.dev)
       ↓
Email Capture (newsletter signup)
       ↓
SEO Blog Posts (Dev.to / Hashnode)
       ↓
Stripe Checkout → JWT License → Paid User
```

**Key insight from research:** Developers convert when they hit a genuine capability ceiling, not when they are annoyed into upgrading. The free tier must be genuinely useful. Gate on team/workflow features, not core functionality.

---

## Week-by-Week Execution Plan

### PRE-LAUNCH: Deploy Infrastructure (Days 1-2)

**Day 1: Deploy everything**

```bash
# 1. Deploy License API Worker
cd sites/license-api
wrangler deploy

# 2. Set secrets
wrangler secret put STRIPE_SECRET_KEY
wrangler secret put STRIPE_WEBHOOK_SECRET
wrangler secret put JWT_SECRET
wrangler secret put ADMIN_SECRET

# 3. Create KV namespace for email subscribers
wrangler kv namespace create SUBSCRIBERS
# Copy the ID into wrangler.toml, uncomment the kv_namespaces block, redeploy

# 4. Deploy landing pages
wrangler pages project create docsync
wrangler pages deploy sites/docsync.dev --project-name=docsync

wrangler pages project create depguard
wrangler pages deploy sites/depguard.dev --project-name=depguard
```

**Day 2: Set up Stripe**
- Create Stripe products: DocSync Pro, DocSync Team, DepGuard Pro, DepGuard Team
- Create price IDs for each and set as Worker env vars
- Configure webhook endpoint: `https://license-api.<account>.workers.dev/webhook`
- Events to subscribe to: `checkout.session.completed`, `invoice.payment_succeeded`, `customer.subscription.deleted`
- Test with Stripe CLI: `stripe listen --forward-to localhost:8787/webhook`

**Day 2: Create GitHub repos**
- Create `docsync` public repo — use `marketing/github-repos/docsync-oss-README.md` as README
- Create `depguard` public repo — use `marketing/github-repos/depguard-oss-README.md` as README
- Add topics: `developer-tools`, `documentation`, `cli`, `git-hooks`, `tree-sitter` (DocSync)
- Add topics: `security`, `dependency-audit`, `license-compliance`, `sbom`, `cli` (DepGuard)
- Enable GitHub Discussions on both repos
- Add LICENSE (MIT), CONTRIBUTING.md, .github/ISSUE_TEMPLATE

---

### WEEK 1: Seed Launch (Simultaneous Multi-Platform)

**Goal:** 50+ GitHub stars per repo, 100+ landing page visits, 20+ email signups

**Tuesday 12:01 AM PST — Launch Day**

| Time | Action | Platform | Asset |
|------|--------|----------|-------|
| 12:01 AM | Post Show HN: DocSync | Hacker News | `launch/show-hn-docsync.md` |
| 12:05 AM | Tweet DocSync launch thread | Twitter/X | `launch/twitter-threads.md` Thread 1 |
| 7:00 AM | Post to r/devtools | Reddit | `launch/reddit-posts.md` Post 1 |
| 8:00 AM | Post to r/programming | Reddit | `launch/reddit-posts.md` Post 2 |
| 9:00 AM | Publish blog: "Why Your Docs Are Always Stale" | Dev.to + Hashnode | `blog/why-your-docs-are-always-stale.md` |
| 10:00 AM | Post to r/SideProject | Reddit | `launch/reddit-posts.md` Post 4 |
| All day | Respond to every HN comment | Hacker News | Engage authentically |
| All day | Respond to every Reddit comment | Reddit | Add value, don't sell |

**Key HN tactics (from research):**
- Link to GitHub repo, NOT the landing page
- Title: modest, crystal clear, no superlatives
- First comment: deep technical detail, talk like a fellow builder
- Handle criticism: find something to agree with first

**Wednesday — DepGuard Launch**

| Time | Action | Platform | Asset |
|------|--------|----------|-------|
| 8:00 AM | Post Show HN: DepGuard | Hacker News | `launch/show-hn-depguard.md` |
| 8:05 AM | Tweet DepGuard launch thread | Twitter/X | `launch/twitter-threads.md` Thread 2 |
| 9:00 AM | Post to r/webdev | Reddit | `launch/reddit-posts.md` Post 3 |
| 10:00 AM | Post to r/selfhosted | Reddit | `launch/reddit-posts.md` Post 5 |
| 11:00 AM | Publish blog: "Best Snyk Alternatives 2026" | Dev.to + Hashnode | `blog/snyk-alternatives-2026.md` |

**Thursday — Combined "Building in Public" Thread**

| Time | Action | Platform |
|------|--------|----------|
| 9:00 AM | Tweet "Building in Public" thread | Twitter/X |
| 10:00 AM | Post journey on Indie Hackers | indiehackers.com |

**Friday — Community Seeding**

- Join 3-5 Discord/Slack communities:
  - ReactiFlux (Discord, 200K+ devs)
  - Node.js (Slack, official)
  - DevOps Engineers (Slack/Discord)
  - Python Discord
  - Rust Community Discord
- **Do NOT self-promote yet.** Introduce yourself, answer questions, be helpful.

---

### WEEK 2: Content Amplification + SEO Foundation

**Goal:** 200+ landing page visits, 50+ email signups, first organic search impressions

**Monday-Tuesday: SEO Amplification**

1. **Cross-post blogs** to Medium (for additional distribution)
2. **Submit to directories:**
   - AlternativeTo.net (list both tools)
   - StackShare (create tool profiles)
   - LibHunt (submit to relevant lists)
   - Awesome Lists: PR to `awesome-devtools`, `awesome-nodejs`, `awesome-python`
3. **Set up Google Search Console** for both `*.pages.dev` domains

**Wednesday-Thursday: Write 2 New SEO Posts**

Target keywords with buyer intent:

1. **"How to Set Up Pre-Commit Hooks for Documentation"** (targets: pre-commit hooks, git hooks documentation, lefthook tutorial)
   - Natural DocSync CTA at the end
   - Publish to Dev.to + Hashnode (custom domain for SEO)

2. **"Dependency License Compliance: A Developer's Guide"** (targets: license compliance, open source license check, SBOM generation)
   - Natural DepGuard CTA at the end
   - Publish to Dev.to + Hashnode

**Friday: Community Engagement**

- Spend 1 hour answering questions in Discord/Slack (established in Week 1)
- Reply to any open GitHub issues
- Engage with anyone who mentioned DocSync/DepGuard on Twitter

---

### WEEK 3: Product Hunt Launch + Conversion Optimization

**Goal:** Product Hunt Top 5, 500+ landing page visits, 100+ email signups, first paid customers

**Monday: Product Hunt Prep**

- Create "Coming Soon" page on Product Hunt (if not done in Week 1)
- Upload product screenshots/GIFs:
  1. Terminal showing drift detection (DocSync)
  2. Terminal showing vulnerability scan (DepGuard)
  3. Pricing page screenshot
- Record 30-45 second demo video (screen recording with voiceover)
- DM 20-50 supporters with personalized messages (not templates)

**Tuesday 12:01 AM PST: Product Hunt Launch — DocSync**

- Use tagline from `launch/product-hunt.md`
- Maker's comment and first comment pre-written
- Have 5-10 supporters upvote + comment authentically in first hour
- Cross-promote on Twitter, Reddit, Discord throughout the day

**Thursday 12:01 AM PST: Product Hunt Launch — DepGuard**

- Same playbook as Tuesday

**Weekend: Analyze + Optimize**

- Review analytics: which channels drove signups?
- Check email subscriber count: `GET /subscribers?secret=YOUR_SECRET`
- Look at Stripe dashboard for any conversions
- Identify top-performing content and double down

---

### WEEK 4: Nurture + Convert

**Goal:** $100+ MRR, 200+ email signups, established community presence

**Monday-Tuesday: Email Outreach to Subscribers**

Send first email to collected subscribers:
- Subject: "Your DocSync/DepGuard is ready"
- Content: Quick win tutorial (how to generate your first doc / run your first scan)
- Soft CTA: "Unlock git hooks with Pro" / "Add license compliance with Pro"
- Keep it short, technical, and valuable

**Wednesday-Thursday: Targeted Content**

Write comparison/alternative posts (highest conversion content type per research):

1. **"DocSync vs Swimm vs Mintlify: Documentation Tools Compared"**
2. **"DepGuard vs Snyk vs Socket: Local-First Security Scanning"**

These "alternatives" posts captured 12% traffic share growth — they target users in the decision phase.

**Friday: Community Building**

- Start a GitHub Discussion thread: "What documentation pain points do you have?"
- Engage in Discord/Slack communities (you should have credibility by now)
- Naturally mention your tools when they solve someone's stated problem

---

## MONTH 2: Scale What Works

### Weekly Cadence (Ongoing)

| Day | Activity | Time |
|-----|----------|------|
| Monday | Write 1 blog post or comparison page | 2-3 hours |
| Tuesday | Publish + distribute across platforms | 1 hour |
| Wednesday | Community engagement (Discord, Slack, Reddit) | 1 hour |
| Thursday | Respond to GitHub issues + feature requests | 1 hour |
| Friday | Analyze metrics, plan next week | 30 min |

### Content Calendar (Month 2)

| Week | Blog Post | Target Keyword |
|------|-----------|---------------|
| 5 | "Automating Documentation with Git Hooks" | git hooks documentation automation |
| 6 | "SBOM Generation Guide for Node.js Projects" | sbom generation nodejs cyclonedx |
| 7 | "Why Local-First Developer Tools Are the Future" | local first developer tools privacy |
| 8 | "Setting Up License Compliance in CI/CD" | license compliance cicd pipeline |

### Conversion Optimization

1. **Add "Upgrade" prompts in CLI output** — when a free user runs a Pro command, show what they'd get
2. **GitHub issue → feature request pipeline** — every issue is a signal of what to build or gate
3. **Track funnel metrics:**
   - GitHub stars → landing page visits (target: 10%)
   - Landing page visits → email signups (target: 5-10%)
   - Email signups → free installs (target: 30-50%)
   - Free installs → paid conversions (target: 4-8%)

---

## MONTH 3: Compound Growth

### Expand Distribution

1. **Submit talks to meetups/conferences** — CFPs for local meetups, virtual conferences
2. **Create YouTube content** — 5-minute tutorials, "How I built X" videos
3. **Guest posts** on established dev blogs
4. **Podcast appearances** — reach out to dev-focused podcasts (Changelog, devtools.fm, etc.)

### SEO Compounding

By Month 3 you should have 8-12 blog posts live. Internal linking between posts creates a content cluster that boosts all pages. Key actions:

1. Add internal links between all related posts
2. Update titles with "2026" for freshness signals
3. Monitor Search Console for rising keywords — write new posts targeting them
4. Ensure content is structured for AI citation (clear factual statements, well-organized data)

### Revenue Optimization

1. **Annual pricing discount** — offer 2 months free for annual billing (improves cash flow, reduces churn)
2. **Team tier upsell** — when Pro users mention team use cases, offer Team trial
3. **Referral program** — "Give 1 month free, get 1 month free" for referrals

---

## Channel-Specific Playbooks

### Hacker News Playbook

- **Frequency:** 1 Show HN per product launch/major update. Otherwise, engage in relevant threads.
- **Link to:** GitHub repo (not landing page)
- **Tone:** Fellow builder, technically deep, modest
- **Criticism response:** Agree with something first, then explain your perspective
- **2026 trend:** HN favors local-first, no-telemetry, simple tools — both products fit perfectly

### Reddit Playbook

- **90/10 rule:** 90% value, 10% promotion
- **Target subreddits:** r/devtools, r/programming, r/webdev, r/selfhosted, r/SideProject
- **Phase 1 (weeks 1-4):** Observe, build karma, help people
- **Phase 2 (weeks 5-8):** Answer questions, mention tool as ONE option among several
- **Phase 3 (ongoing):** Recognized community member, natural product mentions
- **Key stat:** Reddit influences 73% of purchasing decisions

### Twitter/X Playbook

- **Post frequency:** 3-5 tweets daily
- **Best times:** Weekdays 8-10 AM, 7-9 PM; Weekends 9-11 AM
- **Hashtags:** 1-2 maximum per tweet
- **Rule:** Engage (replies, likes) for 30 min BEFORE posting your own content
- **Reply to comments within 15 minutes** — signals engagement to algorithm
- **Average engagement rate:** 0.5-1% (3-5% for viral content)

### Product Hunt Playbook

- **Best day:** Tuesday-Thursday for traffic; Monday for less competition
- **Time:** 12:01 AM PST
- **Must have:** Demo video (your #1 asset), tagline under 60 characters
- **First hour:** 20-50 genuine upvotes + comments (personal DMs, not templates)
- **Treat as ongoing channel:** Supabase launched 16 times with 9 awards. Plan repeat launches for major updates.

### Dev.to / Hashnode Playbook

- **Dev.to:** Broad community reach, built-in discovery
- **Hashnode:** Map to custom domain for SEO ownership
- **Cross-post to both** — Dev.to for immediate reach, Hashnode for long-term SEO
- **Content type:** Technical tutorials that naturally feature your tool
- **Frequency:** 1 post per week minimum

---

## Metrics Dashboard

Track these weekly:

| Metric | Tool | Target (Month 1) |
|--------|------|------------------|
| GitHub Stars (DocSync) | GitHub | 100+ |
| GitHub Stars (DepGuard) | GitHub | 100+ |
| Landing Page Visits | Cloudflare Analytics | 500+ |
| Email Subscribers | `/subscribers` endpoint | 200+ |
| Free Installs | npm/pip download counts | 100+ |
| Paid Conversions | Stripe Dashboard | 5+ |
| MRR | Stripe Dashboard | $100+ |
| Blog Post Views | Dev.to + Hashnode analytics | 5,000+ |
| HN Upvotes | Hacker News | 50+ per post |
| Reddit Engagement | Reddit | 20+ upvotes per post |

---

## Revenue Projections (Conservative)

| Month | Free Users | Paid Users (4% conv.) | Avg Revenue/User | MRR |
|-------|-----------|----------------------|-------------------|-----|
| 1 | 100 | 4 | $29 | $116 |
| 2 | 300 | 12 | $32 | $384 |
| 3 | 600 | 24 | $35 | $840 |
| 4 | 1,000 | 40 | $35 | $1,400 |
| 6 | 2,000 | 80 | $38 | $3,040 |
| 9 | 4,000 | 160 | $40 | $6,400 |
| 12 | 7,000 | 280 | $42 | $11,760 |

*Assumptions: 4% conversion rate, $29-49 blended ARPU (mix of Pro and Team), 5% monthly churn, compounding organic growth from SEO + community.*

---

## Emergency Playbook: What If Nothing Works?

If after 30 days you have <10 email signups:

1. **Validate the problem:** Post on HN "Ask HN: How do you keep docs in sync with code?" — if <20 upvotes, the problem may not resonate
2. **Talk to users directly:** DM 20 developers on Twitter/Discord who've complained about docs/dependencies
3. **Pivot the positioning:** Maybe "documentation" isn't the hook — try "code quality" or "developer experience"
4. **Lower the barrier:** Offer 30-day free Pro trial instead of just free tier
5. **Partner up:** Find a complementary tool and cross-promote

---

## Quick Reference: Deploy Checklist

- [ ] Deploy Cloudflare Worker (`wrangler deploy`)
- [ ] Set all secrets (Stripe keys, JWT secret, admin secret)
- [ ] Create KV namespace, update wrangler.toml, redeploy
- [ ] Deploy DocSync landing page to Cloudflare Pages
- [ ] Deploy DepGuard landing page to Cloudflare Pages
- [ ] Create Stripe products and price IDs
- [ ] Configure Stripe webhook
- [ ] Test full checkout flow (use Stripe test mode)
- [ ] Create GitHub repos with OSS READMEs
- [ ] Publish DocSync skill to ClawHub
- [ ] Publish DepGuard skill to ClawHub
- [ ] Schedule Product Hunt launch
- [ ] Pre-write all launch day posts
- [ ] Line up 5-10 launch day supporters
- [ ] Set up Google Search Console
- [ ] Set up Cloudflare Analytics

---

*Total marketing budget: $0. Total infrastructure cost: $0/month + Stripe per-transaction fees.*
*All assets are pre-written and ready to deploy. Execute Week 1 launch on the next available Tuesday.*
