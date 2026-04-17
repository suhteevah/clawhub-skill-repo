# Reddit Launch Posts — Batch 4 (LogSentry, InputShield, AuthAudit, CloudGuard)

## 1. r/devtools — Mega Overview

**Title:** I built 26 CLI security & quality tools that run 100% locally — no cloud, no telemetry, no accounts

**Body:**

I've been building developer tools for the past several months. Started with two (DocSync for documentation drift, DepGuard for dependency auditing) and kept going. Now there are 26.

Every tool follows the same philosophy:

- Runs 100% locally. No code leaves your machine.
- Zero telemetry. I don't know who installs them.
- Offline license validation (signed JWT, no phone-home).
- Freemium: free core scanning, paid git hooks + advanced features.
- One-command install via ClawHub.

Here's the full list, grouped by category:

**Documentation & Code Quality:**
- DocSync — documentation drift detection (tree-sitter AST parsing)
- DeadCode — unused code detection
- DocCoverage — documentation coverage analysis
- StyleGuard — code style enforcement
- TestGap — test coverage gap finder
- BundlePhobia — bundle size regression detection

**Security:**
- DepGuard — dependency audit + license compliance (10 package managers)
- EnvGuard — environment variable leak prevention
- SecretScan — hardcoded secrets detection
- SQLGuard — SQL injection & query safety
- InputShield — input validation & sanitization scanning
- AuthAudit — authentication & authorization pattern analysis
- ConfigSafe — configuration file security
- APIShield — API security best practices

**Infrastructure & Reliability:**
- CloudGuard — IaC security (Terraform/CloudFormation)
- MigrateSafe — database migration safety
- LicenseGuard — software license compliance
- PerfGuard — performance regression detection
- MemGuard — memory leak detection
- ConcurrencyGuard — race condition detection
- ErrorLens — error handling quality
- LogSentry — logging quality & observability
- I18nCheck — internationalization readiness
- GitPulse — git health analytics
- TypeDrift — type safety regression
- AccessLint — web accessibility compliance

**Install any of them:**

```bash
clawhub install <toolname>
```

**Pricing:** Free tier for scanning. Pro $19/mo adds git hooks + auto-fix. Team $39/mo adds policies + compliance.

**Tech stack:** Cloudflare Pages (free) for landing pages, Cloudflare Workers (free) for license API, Stripe for payments. Total infrastructure cost: $0/month.

Happy to answer questions about the architecture, distribution model, or any individual tool. GitHub: https://github.com/suhteevah

---

## 2. r/programming — LogSentry Spotlight

**Title:** Your logging is probably leaking PII — here's how to find out in 30 seconds

**Body:**

I spent a week auditing logging code across a dozen open-source projects. What I found was grim:

- `console.log(user)` dumping entire user objects including hashed passwords and emails
- Request bodies logged verbatim, including credit card fields
- No correlation IDs, making distributed tracing impossible
- Different log formats per file (some console.log, some winston, some pino)
- Error handlers that catch exceptions and log nothing
- Debug statements left in production code paths

The core problem: we have linters for code style, type checkers for safety, test frameworks for correctness. But logging? Pure honor system.

I built LogSentry to fix this. It's a static analysis tool that scans for 90 logging anti-patterns:

- **Sensitive data exposure:** PII in log output, secrets in debug logs, full object dumps
- **Structured logging violations:** console.log in production, inconsistent log libraries
- **Missing observability:** no correlation IDs, silent error paths, missing context
- **Log level misuse:** ERROR for informational messages, DEBUG in production builds
- **Compliance flags:** GDPR/HIPAA-relevant data appearing in log output

Example output:

```
$ logsentry scan src/

[CRITICAL] SL-001 console.log in production code — app/server.js:15
[CRITICAL] SD-003 PII detected in log output (email) — services/user.ts:42
[HIGH] OB-007 Missing correlation ID in request handler — api/routes.ts:88

Score: 52/100 (Grade: F)
```

Runs 100% locally. Zero telemetry. Free to scan.

```bash
clawhub install logsentry
logsentry scan .
```

Pro ($19/mo) adds pre-commit hooks so bad logging patterns can't merge. https://logsentry.pages.dev

Curious what logging standards others enforce on their teams. I've found most teams have informal conventions but nothing automated.

---

## 3. r/webdev — InputShield Spotlight

**Title:** Every form input is an attack vector — InputShield catches what ESLint security plugins miss

**Body:**

I audited the input validation in several web applications recently. Here's what's still shipping to production in 2026:

- `innerHTML` set directly from user input
- `exec()` called with user-controlled strings
- SQL queries built with template literals instead of parameterized queries
- File paths constructed from query parameters (hello, path traversal)
- User input passed directly to `fetch()` URLs (SSRF)

eslint-plugin-security catches some of this, but it's pattern matching on AST nodes. It misses cases where user input flows through a variable or two before reaching the sink.

I built InputShield to do deeper analysis. It scans for 90 input validation patterns across:

- **Command injection** — unsanitized exec(), spawn(), system calls
- **XSS** — innerHTML, dangerouslySetInnerHTML, document.write from untrusted sources
- **SQL injection** — string concatenation in queries, missing parameterization
- **Path traversal** — user input in fs operations
- **SSRF** — user-controlled URLs in server-side requests
- **XXE** — XML parsers with external entities enabled
- **ReDoS** — regex built from user input

Example:

```
$ inputshield scan src/

[CRITICAL] CI-002 Unsanitized exec() call with user input — api/convert.js:31
[CRITICAL] SQ-001 SQL query built with string concatenation — db/users.js:55
[HIGH] XS-001 innerHTML assignment from untrusted source — components/comment.tsx:18

Score: 38/100 (Grade: F)
```

Runs 100% locally. No telemetry. Your code never leaves your machine.

```bash
clawhub install inputshield
inputshield scan .
```

Free to scan. Pro ($19/mo) adds pre-commit hooks. https://inputshield.pages.dev

What input validation checks does your team run beyond ESLint? Genuinely looking for patterns I might be missing.

---

## 4. r/netsec — AuthAudit Spotlight

**Title:** Scanning for broken auth patterns with static analysis — catches missing middleware, insecure token storage, CSRF gaps

**Body:**

Broken authentication is OWASP #1, but most of the tooling around it is runtime testing (pentest tools, DAST scanners). By the time those catch something, the code is already deployed.

I built AuthAudit as a static analysis tool for authentication and authorization patterns. It reads your source code and flags anti-patterns before they reach production.

**What it scans for (90 patterns across 6 categories):**

- **Access control** — route definitions with no auth middleware, missing role checks, IDOR patterns
- **Token management** — JWTs in localStorage, tokens without expiry, secrets in client code
- **Session security** — cookies missing HttpOnly/Secure/SameSite, no session rotation
- **CSRF protection** — state-changing endpoints without CSRF tokens
- **Password handling** — plaintext comparison, weak hashing algorithms, no rate limiting on login
- **Authorization** — frontend-only role checks, horizontal privilege escalation patterns

**Example output:**

```
$ authaudit scan src/

[CRITICAL] AC-001 Unprotected admin route (no auth middleware) — routes/admin.js:5
[CRITICAL] TK-003 JWT stored in localStorage — auth/client.js:22
[HIGH] CS-002 Session cookie missing HttpOnly flag — config/session.js:8
[HIGH] AC-008 Role check in frontend only — api/dashboard.js:45

Score: 41/100 (Grade: F)
```

Findings map to OWASP Top 10 categories (A01:2021 Broken Access Control, A07:2021 Identification and Authentication Failures).

**Key design decisions:**

- Static analysis only. Does not execute your code or make network requests.
- 100% local. Auth code is arguably your most sensitive code — it should never leave your machine.
- Zero telemetry. No analytics, no usage tracking, no phone-home.
- Works as a pre-commit hook (Pro tier) to catch auth issues before merge.

```bash
clawhub install authaudit
authaudit scan .
```

Free to scan. Pro ($19/mo) adds hooks + OWASP compliance reports. https://authaudit.pages.dev

I'd appreciate feedback from this community on what auth patterns you'd want scanned that I might be missing. Especially interested in OAuth/OIDC-specific anti-patterns.

---

## 5. r/devops — CloudGuard Spotlight

**Title:** Static analysis for Terraform/CloudFormation misconfigurations — 90 patterns, compliance mapping, pre-commit hooks

**Body:**

`terraform plan` tells you what will change. It doesn't tell you if what you're deploying is secure.

I built CloudGuard because I was tired of finding public S3 buckets and wildcard IAM policies during code review. By the time it hits PR review, someone's already spent time writing it and doesn't want to hear it's insecure.

**What it scans for (90 patterns):**

- **Storage** — public bucket ACLs, unencrypted volumes, open blob storage
- **IAM** — wildcard policies (Action: *, Resource: *), overprivileged roles, missing MFA conditions
- **Network** — security groups open to 0.0.0.0/0, missing NACLs, public subnets without NAT
- **Encryption** — unencrypted RDS, missing KMS key rotation, old TLS versions
- **Logging** — CloudTrail disabled, no VPC flow logs, no access logging on S3
- **Compliance** — SOC2, HIPAA, PCI-DSS mapping on every finding

**Example:**

```
$ cloudguard scan infra/

[CRITICAL] S3-001 Bucket with public-read ACL — infra/storage.tf:15
[CRITICAL] IM-003 IAM policy: Action: * on Resource: * — iam/admin-role.tf:22
[HIGH] SG-001 Security group allows 0.0.0.0/0 on port 22 — network/security.tf:34
[HIGH] EC-005 RDS without encryption at rest — database/main.tf:18

Score: 38/100 (Grade: F)
```

**How it compares to tfsec/checkov:**

Both are solid tools. CloudGuard differs in:

1. Scoring (0-100 grade per scan, not just pass/fail)
2. Built-in compliance mapping (SOC2/HIPAA/PCI in the report)
3. Pre-commit hook integration (bad IaC never merges)
4. Part of a larger ecosystem (26 tools, same installer, same philosophy)

100% local. Zero telemetry. Your infrastructure code is literally a map of your cloud — it should never leave your machine.

```bash
clawhub install cloudguard
cloudguard scan .
```

Free to scan. Pro ($19/mo) adds hooks + compliance reports. Team ($39/mo) adds team policies. https://cloudguard.pages.dev

What IaC scanning tools is your team running today? I'm trying to understand what gaps exist in the current tooling.

---

## 6. r/selfhosted — Privacy Angle (All 4 Tools)

**Title:** Local-only security scanning — no cloud, no telemetry, no accounts, no Docker required

**Body:**

Posting here because I know this community cares about keeping data local.

I've been building CLI security tools where the core design constraint is: your code never leaves your machine. Not for scanning, not for license validation, not for analytics. Nothing phones home.

Just shipped 4 new tools (26 total now):

**LogSentry** — scans for logging anti-patterns. PII in log output, missing correlation IDs, console.log in production. Matters because your logs often contain more sensitive data than your database.

**InputShield** — scans for input validation failures. SQL injection, XSS, command injection, path traversal. Catches what ESLint security plugins miss because it traces data flow.

**AuthAudit** — scans for broken authentication patterns. Missing auth middleware, JWTs in localStorage, insecure session cookies. Maps to OWASP Top 10.

**CloudGuard** — scans Terraform and CloudFormation for misconfigurations. Public buckets, wildcard IAM, open security groups. Your IaC code is a map of your infrastructure — it definitely should not leave your machine.

**How the privacy model works:**

- Tools are distributed via ClawHub (command-line package manager)
- License validation is offline — it's a signed JWT, no server call
- Zero telemetry. I literally don't know how many people use them.
- No account required. No email required for free tier.
- No Docker. No containers. Just bash + coreutils.
- Works air-gapped.

```bash
clawhub install logsentry
clawhub install inputshield
clawhub install authaudit
clawhub install cloudguard
```

All free to scan. Pro ($19/mo) adds git hooks + advanced features.

Full list of all 26 tools: https://github.com/suhteevah

---

## 7. r/SideProject — Business Angle

**Title:** 26 dev tools, zero budget — the full build-in-public breakdown

**Body:**

Started building developer tools a few months ago. Launched DocSync (documentation drift) and DepGuard (dependency audit) first. Kept going. Now there are 26 CLI tools covering security, code quality, and infrastructure.

**Total infrastructure cost: $0/month.**

Here's the full stack:

- **26 landing pages:** Cloudflare Pages (free tier, *.pages.dev domains)
- **License API:** Cloudflare Workers + KV storage (free tier, 100K req/day)
- **Payments:** Stripe (no monthly cost, 2.9% + $0.30 per transaction)
- **Distribution:** ClawHub (free, command-line package manager)
- **Tools built with:** bash, POSIX grep, tree-sitter, jq
- **No databases.** No servers. No Docker. No AWS.

**Revenue model:**
- Free: core scanning + reporting
- Pro ($19/mo): git hooks + auto-fix + advanced rules
- Team ($39/mo): team policies + compliance reports

**The math I'm betting on:**

If a 20-developer team adopts 5 tools on Team tier:
$39 x 5 x 20 = $3,900/month

The portfolio approach means I don't need any single tool to be huge. I need breadth.

**Marketing (also $0):**
- Show HN posts per tool launch
- Reddit posts (you're reading one)
- Dev.to + Hashnode SEO articles
- Discord/Slack community engagement
- 4chan /g/ (surprisingly good technical feedback)
- Twitter threads

**What's working:**
- Show HN drives initial awareness
- Niche subreddit posts convert better than broad ones
- "100% local, zero telemetry" resonates everywhere
- The portfolio pitch ("26 tools, one installer") gets attention

**What's not working (yet):**
- SEO takes time to compound
- Free-to-paid conversion is slower than projected
- Twitter reach is low without an existing audience
- Some tools are too niche for broad marketing

**The 26 tools:**

Documentation: DocSync, DeadCode, DocCoverage, StyleGuard, TestGap, BundlePhobia
Security: DepGuard, EnvGuard, SecretScan, SQLGuard, InputShield, AuthAudit, ConfigSafe, APIShield
Infrastructure: CloudGuard, MigrateSafe, LicenseGuard, PerfGuard, MemGuard, ConcurrencyGuard, ErrorLens, LogSentry, I18nCheck, GitPulse, TypeDrift, AccessLint

Everything: https://github.com/suhteevah

Happy to answer questions about the business model, tech decisions, or marketing approach.

---

## 8. r/ExperiencedDevs — Discussion Starter

**Title:** What security checks do you run pre-commit? Here's what I've been automating.

**Body:**

Genuine question for teams with mature development workflows: what static analysis do you run as pre-commit hooks?

I've been building a set of CLI tools that run various security and quality checks at commit time, and I'm trying to understand what experienced teams already have automated vs. what falls through the cracks.

Here's what I've been finding when I scan codebases:

**Logging:** Most teams have zero automated logging standards. console.log statements with PII (`console.log(user)` dumping emails and tokens), inconsistent log formats across services, missing correlation IDs. We lint for code style but not for log quality.

**Input validation:** Even in mature codebases, there are usually a few places where user input flows to a dangerous sink without proper sanitization. Not obvious SQL injection — more like an exec() call three function calls deep from a request handler.

**Auth patterns:** The trickiest one. Your auth can be perfect on 99 routes, but route 100 might be missing middleware. Or you have CSRF tokens on POST endpoints but not on PUT/DELETE. Or JWTs in localStorage because someone copied a tutorial.

**Infrastructure:** Terraform codebases accumulate security debt just like application code. Overprivileged IAM roles that were "temporary" 18 months ago. Security groups that were opened for debugging and never closed.

I've been automating checks for all of these as pre-commit hooks. The tools are called LogSentry, InputShield, AuthAudit, and CloudGuard — all run locally, no cloud dependency.

But I'm more interested in what *your* team does:

1. What pre-commit hooks do you run beyond formatting and linting?
2. Do you have any auth-specific static analysis?
3. How do you handle Terraform security review — manual or automated?
4. Do you audit your logging for PII/compliance issues?

Genuinely looking for blind spots in my approach. If there are common checks I'm not covering, I want to know.
