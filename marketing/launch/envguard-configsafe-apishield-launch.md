# Launch Posts — EnvGuard, ConfigSafe, APIShield

**Created:** 2026-02-24
**Skills:** EnvGuard (pre-commit secret detection), ConfigSafe (infrastructure config auditor), APIShield (API security scanner)

---

## LINKEDIN POSTS

### LinkedIn: EnvGuard

Your .env just got committed. Again.

Every team I've worked with has had the same fire drill — a Stripe key in a config file, an AWS secret in a test fixture, a database URL in a docker-compose pushed to a public repo. GitGuardian emails you 3 hours later. By then, bots have already scraped it.

I built EnvGuard to fix this at the source. It's a pre-commit hook that scans for 50+ secret patterns across 20+ services before anything touches git. Runs 100% locally — zero data leaves your machine.

One command: `envguard scan`

Free to use. Open source. No cloud dependency.

If you've ever rotated credentials at 2am because someone pushed a key, this is for you.

https://envguard.pages.dev
https://github.com/suhteevah/envguard

#DevSecOps #Security #DevTools #OpenSource #PreCommit

---

### LinkedIn: ConfigSafe

Your container is running as root. You just don't know it yet.

Dockerfiles with no USER directive. Kubernetes pods running privileged. Terraform security groups open to 0.0.0.0/0. GitHub Actions with write permissions on PRs.

These misconfigurations don't trigger build failures — they pass CI, deploy to production, and become CVEs.

I built ConfigSafe to catch them before they leave your machine. It scans 80+ misconfiguration patterns across 6 config types:

- Dockerfiles & docker-compose
- Kubernetes manifests
- Terraform
- CI/CD pipelines (GitHub Actions, GitLab CI)
- Web server configs (Nginx, Apache)

One command: `configsafe scan`

100% local. Zero telemetry. Pre-commit hooks available.

If you manage infrastructure, this is the 5-minute install that saves you from the 3am incident.

https://configsafe.pages.dev
https://github.com/suhteevah/configsafe

#DevOps #Kubernetes #Docker #Terraform #InfrastructureSecurity #OpenSource

---

### LinkedIn: APIShield

Your API routes are exposed. You just don't know it yet.

Missing auth middleware on a single endpoint. A wildcard CORS config copy-pasted from a tutorial. An /admin route with no access control. req.body used without validation.

Static analysis tools miss these. Penetration testers find them. But by then the endpoint is live and the damage is done.

I built APIShield to scan your route definitions for 20+ security issues across 6 frameworks: Express, FastAPI, Flask, Django, Rails, and Next.js.

It runs locally, before you commit. One command: `apishield scan`

If you're shipping APIs, this catches the vulnerabilities that code review misses.

https://apishield-a78.pages.dev
https://github.com/suhteevah/apishield

#APISecurity #WebDev #Security #DevTools #OpenSource #CORS

---

## X/TWITTER POSTS (@ClawMMXYZ)

### X: EnvGuard

Your .env just got committed. Again.

I built EnvGuard — pre-commit secret detection. 50+ patterns. 20+ services. Runs locally. Zero telemetry.

One command: `envguard scan`

Free. Open source. No more 2am credential rotations.

https://envguard.pages.dev

### X: ConfigSafe

Your container is running as root. Your Terraform SG is open to 0.0.0.0/0. Your GitHub Actions have write perms on PRs.

I built ConfigSafe — 80+ misconfiguration patterns across Dockerfile, K8s, Terraform, CI/CD, and Nginx.

One command: `configsafe scan`

https://configsafe.pages.dev

### X: APIShield

Missing auth middleware on one endpoint = game over.

I built APIShield — scans your API routes for 20+ security issues across Express, FastAPI, Flask, Django, Rails, and Next.js.

Locally. Before you commit.

`apishield scan`

https://apishield-a78.pages.dev

---

## SHOW HN POSTS

### Show HN: EnvGuard

**Title:** Show HN: EnvGuard -- Pre-commit secret detection (50+ patterns, 100% local)

**URL:** https://github.com/suhteevah/envguard

**Text:**
Hey HN,

I got tired of rotating credentials at 2am because someone pushed an API key. Built EnvGuard to fix it.

It's a pre-commit hook that scans for secrets before they touch git. 50+ regex patterns covering AWS, Stripe, GitHub, Slack, database connection strings, private keys, and 20+ other services.

What it does:
- Scans files for secrets (API keys, tokens, passwords, private keys, connection strings)
- Blocks commits with pre-commit hooks (Pro)
- Generates reports with severity and remediation steps (Pro)
- 100% local — zero data leaves your machine
- Works offline

How it's different from GitGuardian/TruffleHog:
- Runs locally as a pre-commit hook, not a cloud scan after push
- Zero telemetry, no account required
- Catches secrets BEFORE they enter git history

Written in Bash. ~2,400 lines. MIT licensed. Free tier covers one-shot scanning.

Install: `clawhub install envguard`

Would love feedback on the pattern coverage — always looking to add more service-specific detectors.

---

### Show HN: ConfigSafe

**Title:** Show HN: ConfigSafe -- Catch infra misconfigurations before they become CVEs (80+ patterns)

**URL:** https://github.com/suhteevah/configsafe

**Text:**
Hey HN,

I built ConfigSafe because I kept seeing the same infrastructure misconfigurations make it to production — root containers, privileged pods, open security groups, CI pipelines with excessive permissions.

It scans 80+ misconfiguration patterns across 6 config types:
- Dockerfiles (no USER, latest tags, storing secrets in ENV)
- docker-compose (privileged mode, host network, no resource limits)
- Kubernetes (no security context, no resource limits, host path mounts)
- Terraform (open security groups, unencrypted storage, missing logging)
- CI/CD (GitHub Actions write perms, secret exposure, untrusted action versions)
- Web servers (Nginx/Apache: missing security headers, directory listing, weak SSL)

Runs as a pre-commit hook so misconfigs never enter your repo. 100% local, zero cloud, zero telemetry.

3,002 lines of Bash. MIT licensed.

Install: `clawhub install configsafe`

Especially interested in feedback from anyone running K8s or Terraform at scale — are the patterns useful? What's missing?

---

### Show HN: APIShield

**Title:** Show HN: APIShield -- Scan API routes for security vulnerabilities (6 frameworks, 20+ checks)

**URL:** https://github.com/suhteevah/apishield

**Text:**
Hey HN,

I built APIShield because the most common API vulnerabilities aren't complex exploits — they're missing auth middleware on a single route, wildcard CORS, no rate limiting, unvalidated request bodies.

It scans your route definitions for 20+ security checks across 6 frameworks:
- Express.js
- FastAPI
- Flask
- Django
- Ruby on Rails
- Next.js (App Router)

Checks include:
- Missing authentication middleware
- Wildcard CORS configurations
- Missing rate limiting
- No input validation
- Exposed admin/debug routes
- Missing security headers
- Verbose error exposure

Runs locally, pre-commit. ~2,445 lines of Bash. MIT licensed.

The idea is that these are the vulnerabilities that code review often misses because each route looks fine in isolation — the pattern only becomes obvious when you scan every route at once.

Install: `clawhub install apishield`

Would love feedback from anyone who does security audits — are these the right checks? What would you add?

---

## INDIE HACKERS POSTS

### IH: Combined Post — 3 New Security Tools

**Title:** Built 3 security dev tools with $0 budget — here's the stack

**Body:**
I just launched three new tools in my ClawHub ecosystem — all focused on catching security issues before they hit production.

**EnvGuard** — Pre-commit secret detection. 50+ patterns across 20+ services. Catches API keys, tokens, passwords before they touch git. Because GitGuardian emailing you 3 hours after the push is too late.

**ConfigSafe** — Infrastructure config auditor. 80+ patterns across Dockerfiles, K8s manifests, Terraform, CI/CD pipelines, and web server configs. Catches root containers, privileged pods, open security groups.

**APIShield** — API endpoint security scanner. 20+ checks across Express, FastAPI, Flask, Django, Rails, and Next.js. Finds missing auth, wildcard CORS, no rate limiting.

**The stack (total cost: $0/month):**
- Code: Bash (~8K lines across the three tools)
- Hosting: Cloudflare Pages (free)
- Payments: Stripe (pay per transaction)
- License delivery: Cloudflare Worker + KV (free tier)
- Marketing: HN, Reddit, X, Discord (free)

**Revenue model:** Free tier covers one-shot scanning. Pro ($19/mo) adds pre-commit hooks and reports. Team ($39/mo/seat) adds policy enforcement.

All three are MIT licensed and run 100% locally with zero telemetry.

What I've learned building dev tools: developers convert when they hit a genuine capability ceiling, not when they're annoyed into upgrading. The free tier has to be genuinely useful.

Links:
- https://envguard.pages.dev
- https://configsafe.pages.dev
- https://apishield-a78.pages.dev
- GitHub: https://github.com/suhteevah

Happy to answer any questions about the build, the stack, or the marketing approach.

---

## REDDIT POSTS

### r/devtools + r/selfhosted + r/programming

**Title:** I built 3 security tools that run 100% locally — secret detection, infra config auditing, API security scanning

**Body:**
I kept hitting the same problems across projects:

1. Someone pushes an API key to git. We rotate creds at 2am.
2. A Dockerfile running as root makes it to production. We find out from a vulnerability scan.
3. An API endpoint ships without auth middleware. We find out from a pen test.

So I built three tools to catch these before they leave your machine:

**EnvGuard** — Pre-commit secret detection. 50+ patterns, 20+ services. `envguard scan`

**ConfigSafe** — Infrastructure config auditor. 80+ patterns across Dockerfile, K8s, Terraform, CI/CD, Nginx. `configsafe scan`

**APIShield** — API route security scanner. 20+ checks across Express, FastAPI, Flask, Django, Rails, Next.js. `apishield scan`

All three:
- Run locally (no cloud, no telemetry)
- Work as pre-commit hooks
- Free tier for one-shot scanning
- MIT licensed

Links in comments. Happy to answer questions or take feature requests.

---

## PLATFORM SUMMARY

| Platform | Post Type | Skills | Status |
|----------|-----------|--------|--------|
| LinkedIn | 3 individual posts | EnvGuard, ConfigSafe, APIShield | READY |
| X/Twitter | 3 individual tweets | EnvGuard, ConfigSafe, APIShield | READY |
| Hacker News | 3 Show HN posts | EnvGuard, ConfigSafe, APIShield | READY |
| Indie Hackers | 1 combined post | All 3 | READY |
| Reddit | 1 combined post | All 3 | READY |

**Posting order recommendation:**
1. LinkedIn (3 posts, stagger over 3 days)
2. X/Twitter (same day as each LinkedIn post)
3. Show HN (one at a time, wait for engagement before posting next)
4. Indie Hackers (after HN posts)
5. Reddit (after IH, target r/devtools first, then cross-post)
