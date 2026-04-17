# Indie Hackers — Building in Public Update (Batch 4)

## Title

From 2 tools to 26 — scaling a $0-budget dev tool business

## Body

Six months ago I posted here about launching DocSync and DepGuard — two CLI tools for developers, $0 budget, everything on Cloudflare free tier. A few people asked me to post an update when I had more to share.

Now there are 26 tools. Same budget. Same architecture. Same philosophy. Here's everything.

### The starting point

DocSync blocks git commits when documentation drifts from code. DepGuard scans dependencies for vulnerabilities and license issues. Both were scratching my own itch — I had these problems, couldn't find tools that ran locally without sending my code to a SaaS platform, so I built them.

The feedback from those first two launches taught me something: developers want tools that run locally and don't phone home. That message resonated more than any individual feature. So I kept building.

### The pattern

Every tool follows the same architecture:

- **Scanner:** bash + POSIX grep + tree-sitter + jq for the analysis engine
- **Git hooks:** lefthook (Go-based, faster than Husky) for pre-commit integration
- **Licensing:** JWT-based, validated offline. No phone-home. The token is signed, the tool verifies the signature locally, done.
- **Distribution:** ClawHub (my command-line package manager). One command to install anything: `clawhub install <toolname>`
- **Landing page:** Cloudflare Pages with a standard template. Each tool gets its own `<name>.pages.dev` domain.

This pattern means I can ship a new tool in about a week. The architecture is proven. The installer works. The payment flow works. I just need to write the scanning rules and the landing page content.

### Tech stack and costs

**Total fixed costs: $0/month.**

| Component | Service | Cost |
|-----------|---------|------|
| 26 landing pages | Cloudflare Pages | Free |
| License API | Cloudflare Workers + KV | Free (100K req/day) |
| Payments | Stripe | 2.9% + $0.30 per transaction |
| Distribution | ClawHub (self-hosted on CF) | Free |
| Source hosting | GitHub | Free |
| Domains | *.pages.dev subdomains | Free |
| Email | Cloudflare Email Routing | Free |
| Analytics | None (I don't track users) | $0 |

Cloudflare's free tier is absurdly generous for this kind of project. Workers KV alone handles all my license validation without hitting any limits.

### Revenue model

Same across all 26 tools:

- **Free:** core scanning + reporting. No account needed. No email required. Just install and run.
- **Pro ($19/mo):** git pre-commit hooks + auto-fix suggestions + advanced rules. This is the main conversion point — free shows you the problems, Pro blocks them from merging.
- **Team ($39/mo per seat):** team policies + compliance reports + custom rules + SBOM generation. For teams that need audit trails.

The bet: if a 20-developer team adopts 5 tools on Team tier, that's $39 x 5 x 20 = $3,900/month. I don't need any single tool to be massive. I need breadth.

### All 26 tools by category

**Code Quality (5 tools):**
- DocSync — documentation drift detection (tree-sitter AST parsing)
- DeadCode — unused code detection
- StyleGuard — code style enforcement beyond linters
- DocCoverage — documentation coverage analysis
- TypeDrift — type safety regression detection

**Security (8 tools):**
- SecretScan — hardcoded secrets detection
- SQLGuard — SQL injection & query safety
- APIShield — API security best practices
- InputShield — input validation & sanitization scanning (90 patterns: injection, XSS, path traversal)
- AuthAudit — authentication & authorization pattern analysis (OWASP Top 10 mapped)
- DepGuard — dependency audit + license compliance (10 package managers)
- EnvGuard — environment variable leak prevention
- ConfigSafe — configuration file security

**Dependencies (3 tools):**
- DepGuard (also listed under Security — it spans both categories)
- LicenseGuard — software license compliance
- BundlePhobia — bundle size regression detection

**Infrastructure (3 tools):**
- EnvGuard — environment variable leak prevention
- ConfigSafe — configuration file security
- CloudGuard — IaC security scanning (Terraform, CloudFormation, 90 patterns, compliance mapping)

**Performance (3 tools):**
- PerfGuard — performance regression detection
- MemGuard — memory leak detection
- ConcurrencyGuard — race condition detection

**Testing (2 tools):**
- TestGap — test coverage gap finder
- ErrorLens — error handling quality analysis

**DevOps (3 tools):**
- GitPulse — git health analytics
- MigrateSafe — database migration safety
- LogSentry — logging quality & observability (90 patterns, 6 categories: PII detection, structured logging, correlation IDs)

**Accessibility (2 tools):**
- AccessLint — web accessibility compliance
- I18nCheck — internationalization readiness

### Marketing approach: organic only, $0 spent

No paid ads. No sponsored posts. No influencer deals. Everything is platform-native content:

**What I do for each batch of tools:**

- **Show HN** — one post per tool, linking to GitHub (not landing pages). HN rewards technical depth and honesty about trade-offs.
- **Reddit** — targeted subreddit posts. r/devops for CloudGuard, r/netsec for AuthAudit, r/webdev for InputShield. Niche subreddits convert better than broad ones.
- **Dev.to / Hashnode** — long-form articles targeting pain-point keywords. "Your Logs Are a Security Risk" ranks better than "Introducing LogSentry."
- **Discord** — join servers (Reactiflux, Python Discord, DevOps Engineers, etc.), lurk and help people for a few days, mention the tool only when it directly solves someone's stated problem.
- **4chan /g/** — greentext stories about the problem, tool drop at the end. Surprisingly good technical feedback. "post your score" drives engagement.
- **Twitter/X** — threads covering the problem, the solution, the demo, the CTA. Low reach without an existing following but compounds over time.
- **Indie Hackers** — you're reading it.

**What I don't do:** cold DMs, email blasts, LinkedIn engagement bait, paid placements, asking for upvotes.

### What's working

- **GitHub repos as SEO.** Each tool has a public GitHub repo with a solid README. Google indexes these. People searching for "terraform security scanner" or "logging anti-patterns" find them.
- **Landing pages converting.** The `<name>.pages.dev` pattern works. Each page is problem-first: what the tool scans for, example output, one-command install. No signup walls.
- **Show HN for credibility.** A Show HN post with real technical content and honest trade-offs gets taken seriously. It's also a backlink that Google respects.
- **"100% local, zero telemetry" as a positioning statement.** This resonates with every audience I've tested — security teams, indie developers, enterprise, open-source community. Nobody wants to send their code to another SaaS platform.
- **The portfolio pitch.** "26 tools, one installer" is more interesting than any individual tool. People share the list even if they only use one tool.

### What's not working (yet)

- **SEO is slow.** Expected. Organic search takes months to compound. I'm planting seeds.
- **Free-to-paid conversion is slower than projected.** The free tier is too good — some teams scan regularly and never upgrade because they don't need hooks. I might need to rethink the free/paid boundary.
- **Twitter/X reach is low.** Without an existing audience, threads get minimal impressions. Building a following is a separate, slow project.
- **Some tools are too niche for broad marketing.** I18nCheck and AccessLint are valuable but the addressable market for organic content is smaller. They'll grow through the portfolio effect.
- **Solo developer bandwidth.** 26 tools means 26 things to maintain, 26 READMEs to keep updated, 26 landing pages. The architecture scales, the content doesn't.

### What's next

- **Hit 50 tools.** There are more problem domains to cover. API testing, database schema validation, container security, CI pipeline analysis. Each new tool increases the surface area for discovery.
- **Build a marketplace hub.** A single site that organizes all tools by category, lets teams browse and compare, shows what other teams in their industry use. Think "App Store for developer tools."
- **First $1K MRR.** That's the near-term target. Proves the model works. From there it's optimization and scale.
- **Team tier adoption.** The real revenue is teams, not individuals. I need case studies and team-oriented content.

### Challenges I want to be transparent about

- **I'm a solo developer.** No co-founder, no team, no funding. Everything — code, marketing, support, content — is me. This is a strength (low burn rate) and a weakness (limited bandwidth).
- **Competing with free/OSS tools.** tfsec, checkov, eslint-plugin-security — there are free alternatives for parts of what I build. My pitch is the ecosystem + scoring + local-only, but some people will always prefer the established free tool.
- **Pricing might need adjustment.** $19/mo for a single tool might be right or might be too much for individual developers. I'm watching conversion data closely.
- **No usage data.** I literally don't know how many people use my tools. Zero telemetry means zero analytics. I measure interest through GitHub stars, landing page visits (Cloudflare analytics, no JS tracking), and Stripe transactions. That's it.

### Links

- All tools: https://github.com/suhteevah
- Latest 4 tools:
  - LogSentry: https://logsentry.pages.dev
  - InputShield: https://inputshield.pages.dev
  - AuthAudit: https://authaudit.pages.dev
  - CloudGuard: https://cloudguard.pages.dev

Happy to share details about the technical architecture, distribution model, pricing strategy, or marketing approach. AMA.
