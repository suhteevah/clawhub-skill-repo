# Show HN Posts — Batch 4 (LogSentry, InputShield, AuthAudit, CloudGuard)

## Show HN: LogSentry — Static analysis for logging quality (90 patterns, runs locally)

**Title:** Show HN: LogSentry — Static analysis for logging quality (90 anti-patterns, 100% local)

**URL:** https://logsentry.pages.dev

**Text:**

Hi HN,

I built LogSentry because logging is the one thing every codebase has and nobody audits.

We have linters for code style, type checkers for safety, test coverage tools for correctness. But logging? I've never seen a team with automated logging standards. The result: console.log statements leaking PII into log aggregators, inconsistent log formats across services, error handlers that swallow exceptions silently, and missing correlation IDs that make distributed tracing impossible.

LogSentry scans your codebase for 90 logging anti-patterns across 6 categories:

1. **Sensitive data exposure** — PII in log output (emails, tokens, passwords), full object dumps, request body logging
2. **Structured logging violations** — console.log in production, mixed logging libraries, inconsistent formats
3. **Missing observability** — no correlation IDs in request handlers, silent error paths, missing context fields
4. **Log level misuse** — ERROR for informational messages, DEBUG statements in production code
5. **Performance** — synchronous logging in hot paths, excessive log volume
6. **Compliance** — GDPR/HIPAA-relevant data appearing in log output

How it works:

```bash
clawhub install logsentry
logsentry scan .
```

You get a scored report (0-100) with findings mapped to severity levels. Most codebases I've scanned score below 60.

Design decisions:
- 100% local — your log analysis (which reveals what data you're logging, including PII) never leaves your machine
- Static analysis, not runtime — scans source code, not live log streams
- Zero telemetry — I don't collect any usage data
- License validation is offline (signed JWT)
- Free: scan + report. Pro ($19/mo): pre-commit hooks + auto-fix suggestions. Team ($39/mo): team policies + compliance exports.

LogSentry is part of a larger set of tools I've been building (26 total now). All follow the same philosophy: local, no telemetry, freemium.

I'm curious: does your team have any formal logging standards? And if so, how do you enforce them? I've found that even teams with well-documented logging guidelines have no automated way to check compliance.

---

## Show HN: InputShield — Input validation scanner (catches injection, XSS, path traversal)

**Title:** Show HN: InputShield — Input validation scanner for web apps (injection, XSS, path traversal)

**URL:** https://inputshield.pages.dev

**Text:**

Hi HN,

InputShield is a static analysis tool that scans for input validation and sanitization failures. It catches classes of vulnerabilities that standard linting tools miss.

Why I built it: eslint-plugin-security is good for obvious cases, but it's pattern matching on individual AST nodes. It catches `innerHTML = userInput` but not `innerHTML = processMarkdown(userInput)` where processMarkdown doesn't actually sanitize. InputShield attempts to trace data flow from sources (req.body, req.params, form inputs) to sinks (exec, innerHTML, SQL queries, file system calls).

What it scans for (90 patterns):

- **Command injection** — user input reaching exec(), spawn(), system() without sanitization
- **Cross-site scripting** — untrusted data in innerHTML, dangerouslySetInnerHTML, document.write, eval()
- **SQL injection** — string concatenation in queries, template literals in raw SQL, missing parameterization
- **Path traversal** — user-controlled strings in file system operations (fs.readFile, path.join from user input)
- **SSRF** — user-controlled URLs passed to server-side fetch/http calls
- **XXE** — XML parsers configured with external entity processing enabled
- **ReDoS** — regex patterns constructed from user input

Trade-offs and limitations:
- This is static analysis, not a DAST scanner. It reads code, doesn't execute it.
- Data flow tracing is heuristic. It will have false positives (it flags things that are actually sanitized) and false negatives (complex data flows it can't trace).
- Currently best with JavaScript/TypeScript. Python and Go support is more basic.
- It does not replace penetration testing. It catches the low-hanging fruit that shouldn't survive code review.

```bash
clawhub install inputshield
inputshield scan .
```

Free to scan. Pro ($19/mo) adds pre-commit hooks so flagged patterns can't merge. No telemetry, runs 100% locally.

Honest question for the security-minded: what input validation checks do you wish existed as static analysis that don't? I have a roadmap but I'd rather build what people actually need.

---

## Show HN: AuthAudit — Authentication & authorization pattern analyzer (OWASP Top 10)

**Title:** Show HN: AuthAudit — Static analysis for auth patterns (OWASP Top 10 mapped, local-only)

**URL:** https://authaudit.pages.dev

**Text:**

Hi HN,

AuthAudit scans your source code for authentication and authorization anti-patterns. It's static analysis, not a pentest tool — it reads your code and finds patterns that lead to auth bypasses before they reach production.

Why I built it: broken authentication has been in the OWASP Top 10 forever, but most of the tooling is runtime (DAST scanners, pentest frameworks). By the time those find something, the code is deployed. I wanted a pre-commit check that catches common auth mistakes at the code review stage.

What it scans for (90 patterns):

1. **Access control** — route definitions with no auth middleware, missing role checks, IDOR patterns, frontend-only authorization
2. **Token management** — JWTs in localStorage (XSS = full account takeover), tokens without expiry, secrets in client-side code
3. **Session security** — cookies missing HttpOnly/Secure/SameSite flags, no session rotation after auth, missing session expiry
4. **CSRF protection** — state-changing endpoints without CSRF tokens, missing SameSite cookie attribute
5. **Password handling** — plaintext comparison, weak hashing (MD5/SHA1), no rate limiting on login endpoints
6. **Authorization logic** — role checks only in frontend code, missing backend enforcement, privilege escalation patterns

Every finding maps to an OWASP Top 10 category (primarily A01:2021 Broken Access Control and A07:2021 Identification and Authentication Failures).

```bash
clawhub install authaudit
authaudit scan .
```

Design decisions and trade-offs:
- This is AST-level pattern matching, not symbolic execution. It catches *patterns* (like a route definition without auth middleware), not *logic bugs* (like a role check that uses the wrong comparison operator).
- Framework detection is heuristic. It works well with Express, Fastify, Django, Flask, Spring Boot. Less coverage for custom auth frameworks.
- 100% local execution. Your auth code is arguably the most sensitive code in your project — it should definitely not leave your machine.
- Zero telemetry, offline license validation (signed JWT).
- Free: scan + report. Pro ($19/mo): hooks + OWASP compliance report.

Limitations I want to be upfront about: AuthAudit finds *known anti-patterns*. It won't find a novel auth bypass in your custom OAuth implementation. For that, you still need manual security review or a dedicated pentest. This tool is for catching the stuff that shouldn't survive code review but often does.

What auth patterns do you check for during code review? I'm especially interested in OAuth/OIDC-specific issues that could be detected statically.

---

## Show HN: CloudGuard — IaC security scanner for Terraform and CloudFormation

**Title:** Show HN: CloudGuard — IaC security scanner for Terraform and CloudFormation (90 patterns, local)

**URL:** https://cloudguard.pages.dev

**Text:**

Hi HN,

CloudGuard scans Terraform (.tf) and CloudFormation (YAML/JSON) files for security misconfigurations. It's similar in spirit to tfsec and checkov, with some differences in approach.

Why another IaC scanner? I was building a set of developer tools (26 total now) and kept finding that the teams using my other tools had Terraform codebases with no automated security review. tfsec and checkov exist and are good, but I wanted something that:

1. **Scores** your infrastructure (0-100 grade, not just pass/fail)
2. **Maps to compliance frameworks** out of the box (SOC2, HIPAA, PCI-DSS per finding)
3. **Runs as a pre-commit hook** (not just CI — catch it before it's committed)
4. **Follows the same "100% local" philosophy** as the rest of my tools

What it scans for (90 patterns):

- **Storage** — public S3/GCS bucket ACLs, unencrypted EBS/RDS, open blob access
- **IAM** — wildcard Action/Resource policies, overprivileged roles, missing MFA conditions, cross-account trust without conditions
- **Network** — security groups open to 0.0.0.0/0, missing NACLs, public subnets, open database ports
- **Encryption** — missing encryption at rest/in transit, old TLS versions, no KMS key rotation
- **Logging** — CloudTrail disabled, missing VPC flow logs, S3 access logging off
- **Compliance** — each finding tagged with relevant compliance framework sections

```bash
clawhub install cloudguard
cloudguard scan infra/
```

Trade-offs:
- Currently supports Terraform and CloudFormation. Pulumi, CDK, and Bicep are on the roadmap but not yet implemented.
- Pattern-based, not plan-aware. It scans the files as written, not the resolved terraform plan output. This means it can't catch issues that only emerge after variable interpolation.
- It doesn't replace tfsec or checkov if you're already using them. It's an alternative with a different UX (scoring, compliance mapping, pre-commit focus).
- 90 patterns is fewer than checkov's 1000+ policies. I focused on the highest-impact patterns rather than trying to be comprehensive.

Free to scan. Pro ($19/mo) adds pre-commit hooks + compliance reports. No telemetry, runs locally.

For teams already using tfsec or checkov: what's your biggest pain point with those tools? I'm genuinely trying to understand if there's a gap worth filling or if the existing tools are sufficient for most teams.
