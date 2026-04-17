# Dev.to Article Outlines — Batch 4 (LogSentry, InputShield, AuthAudit, CloudGuard)

*Publish on [Dev.to](https://dev.to) | Cross-post to [Hashnode](https://hashnode.com)*

---

## Article 1: "Your Logs Are a Security Risk — 6 Patterns That Leak PII"

**Tags:** #security #logging #observability #devops

### Intro Paragraph

Most teams treat logging as an afterthought. You add console.log during debugging, maybe upgrade to a structured logger eventually, and call it done. But here's the problem: logs are the largest unaudited data stream in most applications. A 2024 study found that 73% of production log streams contain personally identifiable information that violates at least one data protection regulation. Your logs are not just noisy — they are a compliance liability and an active security risk. I spent months scanning codebases for logging anti-patterns. Here are the 6 most dangerous ones I keep finding.

### Sections

#### 1. Console.log With Full User Objects
- The pattern: `console.log(user)` or `console.log('Login:', req.body)` dumping entire objects into log output
- Why it's dangerous: user objects contain emails, hashed passwords, tokens, phone numbers, addresses — all of it ends up in Datadog/Splunk/CloudWatch where every developer and ops engineer can see it
- Code example: show a typical Express login handler that logs the full request body
- What LogSentry catches: rule SD-001 (full object dump in log output), SD-003 (PII detected in log arguments — email, token, password patterns)
- The fix: log only what you need — user ID, action, timestamp. Never log the full object.

#### 2. Stack Traces With Sensitive Data
- The pattern: `catch(e) { logger.error(e.stack) }` where the error was thrown during processing of sensitive data
- Why it's dangerous: stack traces can contain function arguments, local variable values, database connection strings, API keys from environment variable interpolation
- Code example: a payment processing function that throws and the stack trace includes card details from the call stack
- What LogSentry catches: rule SD-005 (unfiltered stack trace in production logs), SD-008 (error log containing potential secrets pattern)
- The fix: sanitize stack traces before logging. Strip arguments, redact known sensitive patterns.

#### 3. Missing Log Levels (Everything Is console.log)
- The pattern: entire codebase uses console.log for everything — errors, debug info, user actions, system events
- Why it's dangerous: you can't filter by severity, can't set up alerts on error-level events, can't strip debug logs from production. When everything is the same level, nothing is actionable.
- Code example: show a file with console.log for error handling, debug output, and informational messages all mixed together
- What LogSentry catches: rule SL-001 (console.log in production code), SL-004 (no log level differentiation in file), SL-009 (missing structured log library)
- The fix: pick a structured logger (winston, pino, bunyan). Use appropriate levels. Strip debug in production builds.

#### 4. No Correlation IDs Across Services
- The pattern: request handlers that log events without any trace ID or correlation ID linking them to the originating request
- Why it's dangerous: when a request touches 5 microservices and something breaks, you have no way to trace the path. Debugging production issues goes from minutes to hours.
- Code example: an Express middleware chain with logging in each handler but no shared request ID
- What LogSentry catches: rule OB-007 (request handler without correlation ID), OB-012 (missing trace context propagation)
- The fix: generate a correlation ID at the entry point (or extract from X-Request-ID header), pass it through context, include it in every log line.

#### 5. Structured Logging Failures (Mixed Formats)
- The pattern: half the codebase uses winston with JSON output, the other half uses console.log with string interpolation. Some files use pino. One file uses debug().
- Why it's dangerous: your log aggregator can't parse inconsistent formats. Search and filtering break. Dashboards show half the data. Alerting misses events because the format doesn't match the expected pattern.
- Code example: three different files in the same project using three different logging approaches
- What LogSentry catches: rule SL-012 (inconsistent log library usage), SL-015 (mixed structured/unstructured logging in same service), SL-018 (string interpolation in structured logger)
- The fix: pick one logger. Enforce it. LogSentry's pre-commit hook blocks commits that introduce a different logging library.

#### 6. Silent Error Paths (Catch and Swallow)
- The pattern: `catch(e) { /* TODO: handle this */ }` or `catch(e) { return null }` with no logging at all
- Why it's dangerous: the error happened but you'll never know. The function returns null, something downstream breaks in a confusing way, and you have zero trail to follow. These are the bugs that take 4 hours to diagnose.
- Code example: a database query wrapped in try/catch that swallows the error and returns an empty array
- What LogSentry catches: rule OB-001 (empty catch block), OB-003 (catch block with no logging), OB-006 (error path returning default value without logging)
- The fix: every catch block should log at minimum the error message, the function name, and relevant context. If you're intentionally ignoring an error, add a comment explaining why and log it at debug level.

### Conclusion

Logging is infrastructure. It deserves the same automated standards we apply to code style and test coverage. None of these patterns are hard to fix individually — the problem is that nobody checks.

LogSentry scans for all 6 of these patterns (and 84 more) in one command:

```bash
clawhub install logsentry
logsentry scan .
```

Free to scan. Pro ($19/mo) adds pre-commit hooks so these patterns can't merge. Runs 100% locally — your log analysis never leaves your machine.

https://logsentry.pages.dev | https://github.com/suhteevah/logsentry

---

## Article 2: "I Automated OWASP Top 10 Checks With a Pre-Commit Hook"

**Tags:** #security #owasp #webdev #authentication

### Intro Paragraph

Broken Access Control has been OWASP #1 since 2021. Not because developers don't understand authentication — but because auth is a consistency problem. Your auth can be perfect on 99 endpoints. Endpoint 100 ships without middleware because someone forgot, or copied a route template that didn't include it, or added an "admin-only" page during a hackathon and never locked it down. Most auth tooling is runtime: pentest frameworks, DAST scanners, bug bounties. By the time they find something, the code is deployed and the vulnerability is live. I wanted a pre-commit hook that catches the common stuff before it leaves the developer's machine. So I built one.

### Sections

#### How AuthAudit Maps to OWASP

- Table mapping: AuthAudit pattern categories to OWASP Top 10 2021 entries
- A01:2021 Broken Access Control --> Access control patterns (missing middleware, IDOR, frontend-only role checks)
- A02:2021 Cryptographic Failures --> Token management, weak hashing, missing encryption
- A04:2021 Insecure Design --> Authorization logic patterns, missing rate limiting
- A07:2021 Identification and Authentication Failures --> Session management, password handling, CSRF gaps
- Each OWASP category shows how many AuthAudit rules apply to it

#### Pattern 1: Unprotected Routes
- What it looks like: Express route definition with no auth middleware, Django view without @login_required, Flask endpoint missing @auth_required
- Why it happens: route templates without auth, copy-paste from tutorials, "I'll add auth later"
- Code example: an admin route in Express with no middleware between the path and the handler
- What AuthAudit catches: rule AC-001 (route definition with no auth middleware), AC-003 (admin path without elevated auth)
- How the pre-commit hook blocks it: show the hook output rejecting a commit that adds an unprotected route

#### Pattern 2: JWT Stored in localStorage
- What it looks like: `localStorage.setItem('token', jwt)` in client-side JavaScript
- Why it's dangerous: any XSS vulnerability gives the attacker the full JWT. Game over. Full account takeover. HttpOnly cookies are the alternative — they're not accessible to JavaScript.
- Code example: a login handler that stores the JWT in localStorage after a successful auth response
- What AuthAudit catches: rule TK-003 (JWT/token stored in localStorage), TK-005 (sensitive token accessible to client-side JavaScript)

#### Pattern 3: Missing CSRF Protection
- What it looks like: POST/PUT/DELETE endpoints without CSRF token validation
- Why it happens: SPA frameworks handle CSRF differently than server-rendered apps, developers assume "the frontend handles it"
- Code example: a state-changing API endpoint with no CSRF middleware
- What AuthAudit catches: rule CS-004 (state-changing endpoint without CSRF protection), CS-006 (SameSite cookie attribute missing)

#### Pattern 4: Session Fixation and Mismanagement
- What it looks like: session ID not rotated after login, session cookies without Secure/HttpOnly/SameSite flags, no session expiry
- Code example: Express session config missing secure cookie flags
- What AuthAudit catches: rule CS-001 (session cookie missing HttpOnly), CS-002 (session cookie missing Secure), CS-007 (no session rotation after authentication)

#### Pattern 5: Insecure Password Handling
- What it looks like: `if (password === storedPassword)` plaintext comparison, MD5/SHA1 hashing instead of bcrypt/argon2, no rate limiting on login
- Code example: a login handler comparing passwords with === instead of bcrypt.compare
- What AuthAudit catches: rule PW-001 (plaintext password comparison), PW-003 (weak hashing algorithm for passwords), PW-006 (login endpoint without rate limiting)

#### Pattern 6: Frontend-Only Role Checks
- What it looks like: `{user.role === 'admin' && <AdminPanel />}` in React with no corresponding backend authorization check on the API endpoint
- Why it's dangerous: anyone can call your API directly. Frontend checks are UX, not security.
- Code example: a React component that conditionally renders admin UI but the API endpoint serves admin data to any authenticated user
- What AuthAudit catches: rule AC-008 (role check in frontend only, no backend enforcement), AC-011 (API endpoint missing role-based authorization)

#### Setting Up the Pre-Commit Hook
- Step-by-step: install AuthAudit, run initial scan, configure lefthook, show the hook blocking a bad commit
- How to handle existing issues: baseline your codebase, fix criticals first, use severity thresholds to avoid blocking on everything at once
- CI integration: run authaudit scan in CI as a safety net for anything the pre-commit hook misses

### Conclusion

You don't need a pentest to catch `localStorage.setItem('token', jwt)`. You don't need a DAST scanner to find a route definition missing auth middleware. These are patterns — detectable statically, fixable before merge.

AuthAudit isn't a replacement for a real security audit. It catches the stuff that shouldn't survive code review but consistently does.

```bash
clawhub install authaudit
authaudit scan .
```

Free to scan. Pro ($19/mo) adds the pre-commit hook + OWASP compliance reports. 100% local — your auth code never leaves your machine.

https://authaudit.pages.dev | https://github.com/suhteevah/authaudit

---

## Article 3: "Every Input Is an Attack Vector: A Developer's Guide to Input Validation"

**Tags:** #security #webdev #javascript #beginners

### Intro Paragraph

Injection attacks have been in the OWASP Top 10 since the list was created. In 2023, injection flaws were responsible for over 33% of web application breaches. The reason is simple: developers build applications that trust user input. Not intentionally — but through defaults, shortcuts, and the steady pressure to ship. Every form field, query parameter, URL slug, file upload, and HTTP header your application accepts is an attack surface. If you're not validating and sanitizing all of them, you have vulnerabilities. This isn't a question of "if" — it's a question of how many.

### Sections

#### 1. SQL Injection — Still Alive in 2026
- Why it still happens: ORMs handle most queries, but there's always that one raw query for a complex join or a search feature
- The pattern: string concatenation or template literals in SQL queries instead of parameterized queries
- Code example: a search endpoint that builds a WHERE clause from user input with template literals
- What InputShield catches: rule SQ-001 (string concatenation in SQL query), SQ-004 (template literal in raw SQL call), SQ-007 (ORM raw query with unparameterized input)
- The fix: always use parameterized queries. No exceptions. Even for "simple" queries.

#### 2. Cross-Site Scripting (XSS) — More Vectors Than You Think
- Beyond innerHTML: dangerouslySetInnerHTML in React, v-html in Vue, [innerHTML] in Angular, document.write, href attributes with javascript: protocol
- The pattern: user-supplied data rendered as HTML without sanitization
- Code example: a comment component that renders markdown by setting innerHTML from a processed (but not sanitized) string
- What InputShield catches: rule XS-001 (innerHTML from untrusted source), XS-003 (dangerouslySetInnerHTML with unsanitized data), XS-007 (href attribute with user-controlled value), XS-011 (document.write with external data)
- The fix: sanitize with DOMPurify or equivalent before rendering. Use textContent instead of innerHTML where possible.

#### 3. Command Injection — The exec() Problem
- The pattern: user input passed to exec(), spawn(), system(), or child_process without sanitization
- Why it happens: file conversion, image processing, PDF generation — anything that shells out to a system command
- Code example: a file conversion endpoint that passes a user-supplied filename to exec()
- What InputShield catches: rule CI-001 (user input in exec() call), CI-004 (unsanitized string in child_process.spawn), CI-008 (command built from request parameters)
- The fix: use library APIs instead of shell commands. If you must shell out, use execFile with explicit arguments (no shell interpolation) and whitelist allowed values.

#### 4. Path Traversal — When Users Control File Paths
- The pattern: user input used in fs.readFile(), fs.writeFile(), path.join(), or any file system operation
- Why it happens: file download endpoints, user avatar uploads, report generation with user-specified filenames
- Code example: an API endpoint that serves files based on a filename query parameter — `../../etc/passwd` does exactly what you think
- What InputShield catches: rule PT-001 (user input in fs.readFile path), PT-004 (path.join with user-controlled segment), PT-007 (directory traversal sequence in file operation)
- The fix: resolve the path and verify it stays within the expected directory. Strip `../` sequences. Use a whitelist of allowed filenames.

#### 5. Deserialization — Don't Trust Serialized Data
- The pattern: JSON.parse, yaml.load, pickle.loads, unserialize() on user-supplied data without validation
- Why it happens: APIs that accept complex nested objects, file uploads of serialized data, inter-service communication with user-controlled payloads
- Code example: a Python endpoint that uses pickle.loads on uploaded data
- What InputShield catches: rule DS-001 (unsafe deserialization of user input), DS-004 (yaml.load without SafeLoader), DS-007 (pickle.loads on untrusted data)
- The fix: use safe deserialization methods (yaml.safe_load, JSON with schema validation). Never deserialize arbitrary user data with pickle or PHP unserialize.

#### 6. ReDoS — Regular Expressions as Attack Vectors
- The pattern: regex patterns constructed from user input, or complex regex applied to user-supplied strings
- Why it happens: search features, input validation, URL routing with dynamic patterns
- Code example: a search endpoint that builds a regex from the user's search query — a crafted input causes catastrophic backtracking
- What InputShield catches: rule RE-001 (regex constructed from user input), RE-004 (regex with potential catastrophic backtracking applied to user data)
- The fix: never build regex from user input. If you must match user-supplied patterns, use a regex timeout or a safe regex library.

### Conclusion

Input validation is not a feature. It's a property of every boundary in your application. Every place data enters your system needs a check.

InputShield scans for all 6 of these categories (90 patterns total) in one pass:

```bash
clawhub install inputshield
inputshield scan .
```

Free to scan. Pro ($19/mo) adds pre-commit hooks so injection vectors can't merge. Runs 100% locally — your source code stays on your machine.

The average web application I've scanned scores 38/100. Run it on your codebase and see where you land.

https://inputshield.pages.dev | https://github.com/suhteevah/inputshield

---

## Article 4: "Your Terraform Is Probably Insecure — Here Are 90 Patterns to Check"

**Tags:** #devops #terraform #security #cloud

### Intro Paragraph

Cloud misconfigurations were responsible for 15% of all initial attack vectors in data breaches in 2023. Not zero-days. Not sophisticated exploits. Misconfigurations. Public S3 buckets, overprivileged IAM roles, security groups that allow the entire internet to SSH in. The infrastructure-as-code revolution was supposed to fix this — codify your infrastructure, review it like application code, catch mistakes in PRs. But `terraform plan` tells you what will change. It does not tell you if what you're deploying is secure. I built CloudGuard to close that gap. 90 security patterns for Terraform and CloudFormation files. Here's what it checks and why.

### Sections

#### 1. Public S3 Buckets and Storage Access
- The pattern: `acl = "public-read"` on S3 buckets, GCS buckets without uniform bucket-level access, Azure blob containers with public access
- Why it still happens: marketing wants a public assets bucket, someone copies a Terraform example that defaults to public, the bucket policy is complex and nobody reads it carefully
- Code example: a Terraform S3 bucket resource with public-read ACL and no block_public_access configuration
- What CloudGuard catches: rule S3-001 (public-read ACL on bucket), S3-004 (missing S3 Block Public Access configuration), S3-008 (bucket policy allowing wildcard principal)
- Real-world impact: every major cloud data breach in the past 5 years involved a misconfigured storage bucket

#### 2. Wildcard IAM Policies
- The pattern: `Action: "*"` on `Resource: "*"` — full admin access to everything
- Why it happens: "I'll scope it down later." You won't. Or: "It's just for the CI pipeline." Until the CI credentials leak.
- Code example: an IAM policy document in Terraform with Action: * and Resource: *
- What CloudGuard catches: rule IM-001 (wildcard Action in IAM policy), IM-003 (wildcard Resource in IAM policy), IM-007 (IAM role assuming wildcard trust policy)
- The fix: least privilege. Scope to specific actions and resources. Use IAM Access Analyzer to find unused permissions.

#### 3. Open Security Groups
- The pattern: ingress rules allowing 0.0.0.0/0 on sensitive ports (22, 3389, 3306, 5432, 27017)
- Why it happens: "I need to SSH in from home," debugging in production, VPN is down so someone opens SSH to the internet "temporarily"
- Code example: an AWS security group with ingress from 0.0.0.0/0 on port 22
- What CloudGuard catches: rule SG-001 (security group allows 0.0.0.0/0 ingress), SG-004 (database port open to internet), SG-007 (overly permissive egress rule)
- The fix: restrict to specific CIDR blocks. Use a bastion host or AWS SSM Session Manager. Never expose databases directly.

#### 4. Unencrypted Storage and Databases
- The pattern: RDS instances without `storage_encrypted = true`, EBS volumes without encryption, S3 without server-side encryption
- Why it happens: Terraform defaults — most resources don't enable encryption by default. If you don't explicitly set it, it's off.
- Code example: an RDS instance resource with no encryption configuration
- What CloudGuard catches: rule EC-001 (RDS without encryption at rest), EC-004 (EBS volume without encryption), EC-008 (S3 bucket without server-side encryption), EC-012 (missing KMS key rotation)
- The fix: encrypt everything at rest. Use AWS KMS with automatic key rotation. There's almost no performance penalty.

#### 5. Missing Logging and Audit Trails
- The pattern: CloudTrail disabled, no VPC Flow Logs, S3 access logging turned off, no GuardDuty
- Why it happens: logging costs money (VPC Flow Logs especially), nobody thinks about audit trails until after the incident
- Code example: a Terraform configuration with no aws_cloudtrail resource, no VPC flow log configuration
- What CloudGuard catches: rule LG-001 (no CloudTrail configuration), LG-004 (VPC without flow logs), LG-007 (S3 bucket without access logging), LG-010 (no GuardDuty detector)
- The fix: CloudTrail is non-negotiable. VPC Flow Logs on at least the VPCs with production workloads. S3 access logging on any bucket with sensitive data.

#### 6. Configuration Drift and Compliance Mapping
- The problem: infrastructure accumulates security debt exactly like application code. That "temporary" overprivileged role from 18 months ago is still there.
- How CloudGuard handles it: every finding is tagged with compliance framework sections (SOC2, HIPAA, PCI-DSS). Run a scan, get a compliance report.
- How scoring works: 0-100 grade based on severity-weighted findings. Most Terraform codebases score below 50.
- Baseline workflow: run an initial scan, fix critical findings, set up the pre-commit hook to prevent regression, re-scan weekly to track progress

#### How CloudGuard Compares to tfsec and checkov
- tfsec: excellent pattern library, fast, well-maintained. CloudGuard differs with scoring (grade not just pass/fail), built-in compliance mapping, and pre-commit hook integration.
- checkov: 1000+ policies, broader coverage. CloudGuard has fewer patterns (90) but focused on the highest-impact ones. Simpler output.
- The local-only advantage: both tfsec and checkov run locally too. Where CloudGuard differs is that it's part of a 26-tool ecosystem with the same installer, same licensing model, same philosophy. If you're already using InputShield or AuthAudit, adding CloudGuard is one command.
- Honest take: if tfsec or checkov is working for your team, you probably don't need to switch. CloudGuard is for teams that want scoring + compliance mapping + the broader ecosystem.

### Conclusion

`terraform plan` and `terraform apply` are not security tools. They tell you what changes. They don't tell you if those changes are safe.

CloudGuard scans for the 90 most impactful Terraform and CloudFormation security patterns in one command:

```bash
clawhub install cloudguard
cloudguard scan infra/
```

Free to scan. Pro ($19/mo) adds pre-commit hooks so insecure IaC can't merge. Team ($39/mo) adds compliance reports and team policies. 100% local — your infrastructure code is literally a map of your cloud. It should never leave your machine.

https://cloudguard.pages.dev | https://github.com/suhteevah/cloudguard
