# Indie Hackers — Building in Public Post

## Title
Launching two dev tools with $0 budget — here's everything

## Body

I just launched DocSync and DepGuard — two CLI tools for developers.

**DocSync** blocks git commits when your documentation is stale. It uses tree-sitter to parse code, extract symbols, and compare them against your docs. If you added a function and didn't document it, you can't commit.

**DepGuard** scans dependencies for vulnerabilities and license issues. Wraps native audit tools (npm audit, pip-audit, cargo audit, etc.) for 10 package managers into one command.

### The numbers

**Total cost to build and launch: $0**

- Hosting: Cloudflare Pages (free tier)
- Payment processing: Stripe (no monthly cost, 2.9% + $0.30 per transaction)
- License delivery: Cloudflare Worker with KV storage (free tier — 100K requests/day)
- Domain: Already owned (chicocellrepair.com for business verification)
- Marketing: Reddit, HN, Dev.to, Discord, 4chan /g/ (all free)

**Revenue model:**
- DocSync: Free doc generation → Pro $29/mo (git hooks + drift detection) → Team $49/mo/seat
- DepGuard: Free scanning → Pro $19/mo (git hooks + auto-fix) → Team $39/mo/seat (SBOM + compliance)

### Tech stack

- tree-sitter for AST parsing (fast, deterministic, offline — not an LLM)
- lefthook for git hooks (Go-based, faster than Husky)
- JWT-based licensing with offline validation (no phone-home)
- Cloudflare Workers for the license API
- Stripe for payments with webhook → JWT generation flow

### What I'm doing for marketing

Week 1:
- Show HN for both products (linking to GitHub repos, not landing pages)
- Reddit posts across 5 subreddits
- ClawHub forum announcement
- Dev.to blog posts targeting pain-point keywords
- Being genuinely helpful in Discord servers

Week 2:
- Product Hunt launch
- More SEO content
- Community engagement

### What I'd do differently

If I could start over, I'd validate the problem harder before building. I built this because I personally had the problem, but I should have talked to 20+ developers first to understand how they think about it.

### Links

- DocSync: https://docsync-1q4.pages.dev
- DepGuard: https://depguard.pages.dev
- GitHub: https://github.com/suhteevah

Happy to share any details about the technical implementation, pricing strategy, or marketing approach. AMA.
