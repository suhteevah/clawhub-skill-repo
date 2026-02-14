# Reddit Launch Posts

## r/devtools

**Title:** I built a tool that blocks git commits when documentation is stale

**Body:**

Documentation rots because there's no enforcement. Tests run on CI. Linting catches style issues. But docs? Pure honor system.

DocSync changes that with a pre-commit hook:

1. Parses staged files with tree-sitter (40+ languages)
2. Extracts functions, classes, types
3. Checks if they're documented
4. Blocks the commit if critical drift detected

Free to use for doc generation. Pro adds the hooks. Everything runs locally — no code leaves your machine.

`clawhub install docsync`

https://docsync.pages.dev

---

## r/programming

**Title:** We treated documentation like tests — here's what happened

**Body:**

What if your docs had CI the same way your code does?

We built a pre-commit hook that uses tree-sitter to parse code, extract symbols, and compare them against existing documentation. If you add a function without documenting it, the commit is blocked.

Results after 3 months of internal use:
- Doc coverage went from ~40% to 95%
- New team members onboard 2x faster
- "Update the docs" tickets dropped to near zero

The tool is called DocSync. Free tier generates docs from code. Pro adds the git hooks.

https://docsync.pages.dev

---

## r/webdev

**Title:** Auto-generate API documentation from your TypeScript/JavaScript with one command

**Body:**

Built a tool that parses your TS/JS files (and 40+ other languages) using tree-sitter and generates structured markdown documentation.

```bash
clawhub install docsync
docsync generate src/api/
```

Outputs markdown with:
- Table of contents
- Function signatures
- Parameter tables
- Type definitions
- Class hierarchies

Free, runs locally, no account needed.

The pro version adds a git hook that catches when you change code but don't update the docs.

https://docsync.pages.dev

---

## r/SideProject

**Title:** I launched two dev tools today — here's the zero-budget marketing playbook

**Body:**

Just launched DocSync (auto-docs + drift detection) and DepGuard (dependency audit + license compliance) on ClawHub.

Total cost to build and launch: $0

- Skills: published to ClawHub (free)
- Landing pages: Cloudflare Pages (free, *.pages.dev)
- Payment: Stripe (no monthly cost, just per-transaction fees)
- License delivery: Cloudflare Worker (free tier, 100k req/day)
- Marketing: HN, Reddit, Dev.to (free)

Revenue model: freemium with per-seat pricing ($19-79/user/month).

Happy to share the full playbook if anyone's interested.

---

## r/selfhosted / r/privacy

**Title:** DepGuard: dependency vulnerability scanning that runs 100% locally (no Snyk, no cloud)

**Body:**

If you're like me and don't want to send your dependency manifests to Snyk's cloud, DepGuard runs everything locally.

It wraps native audit tools (npm audit, pip-audit, cargo audit, govulncheck) and adds license compliance scanning on top. Supports 10 package managers.

- Zero telemetry
- No code or data sent externally
- License validation is offline (signed JWT)
- Works in air-gapped environments

Free scan + license check. Pro adds git hooks and auto-fix.

`clawhub install depguard`

https://depguard.pages.dev
