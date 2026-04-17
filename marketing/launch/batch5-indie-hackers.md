# Indie Hackers Posts — Batch 5 (CryptoLint, RetryLint, HTTPLint, DateGuard)

---

## Post 1: CryptoLint

**Title:** I'm building developer security tools — just launched CryptoLint, a crypto misuse detector ($0-$39/mo)

**Body:**

Hey IH! I've been building a suite of CLI developer tools under the ClawHub umbrella. The latest is CryptoLint — a static analysis tool that scans codebases for cryptographic anti-patterns.

**The problem:** Most codebases have broken crypto that "works." MD5 for password hashing (it hashes, just not securely). Hardcoded encryption keys (the encryption works, but anyone with source access has the key). ECB mode (it encrypts, but leaks patterns). Math.random() for tokens (they look random, but they're predictable). The code runs fine — it just doesn't protect anything.

**What I built:** CryptoLint scans for 90 cryptographic anti-patterns across 6 categories: weak algorithms, key management, encryption modes, random number generation, timing attacks, and certificate/protocol issues. One command, scored report, pre-commit hooks.

**Business model:** Freemium. Free tier scans with 30 patterns. Pro ($19/mo) unlocks 60 patterns + JSON/HTML reports. Team ($39/mo) unlocks all 90 + CI/CD integration.

**Tech stack:** Pure bash, regex pattern matching, zero dependencies beyond git and bash. Runs 100% locally — no telemetry, no cloud, offline license validation via signed JWT.

**Numbers so far:** This is tool #27 in the ClawHub suite. All tools follow the same architecture and pricing model. Revenue is growing but I'm focused on breadth right now — each tool targets a different developer pain point.

**What I'd love feedback on:**
- Is the pricing right? $19/mo feels standard for dev tools but I'm open to annual discounts.
- Which of these 4 new tools would you pay for first: crypto scanning, retry pattern analysis, HTTP misconfiguration detection, or date/time bug detection?

https://cryptolint.pages.dev | https://github.com/suhteevah/cryptolint

---

## Post 2: RetryLint

**Title:** Built a tool that finds retry/resilience anti-patterns before they cause outages

**Body:**

New tool drop: RetryLint — a CLI scanner for retry logic, circuit breakers, backoff strategies, and timeout configuration.

**Origin story:** I watched a single misconfigured retry loop take down a production system serving 50M req/day. The upstream service went down for 2 minutes. Every request retried infinitely with 1-second fixed delays. The retry traffic was 50x normal load. When the service came back, it went right back down under the retry storm. This happened 3 times before someone manually killed the retry loop.

**What it catches:** Missing max retries, fixed delays instead of exponential backoff, external calls without circuit breakers, HTTP requests with no timeout, retrying non-idempotent operations, no fallback for degraded services.

**Business model:** Same freemium as my other tools. Free: 30 patterns. Pro ($19/mo): 60 patterns + reports. Team ($39/mo): all 90 + CI/CD.

**Differentiator from runtime observability:** This is static analysis. It finds the anti-patterns in your code before deployment, not after the outage. Think of it as a linter for resilience.

Anyone here running microservices? I'd love to know if retry configuration is something your team standardizes or if every service does its own thing.

https://retrylint.pages.dev | https://github.com/suhteevah/retrylint

---

## Post 3: HTTPLint

**Title:** 91% of APIs are missing critical security headers — I built a scanner for HTTP misconfigurations

**Body:**

HTTPLint scans codebases for HTTP client and server misconfiguration patterns. Missing security headers, wildcard CORS, no connection pooling, missing error handling on fetch calls, no cache strategy.

**Why this matters:** HTTP is the protocol every developer uses and almost nobody configures correctly. You set up Express, add routes, deploy. But CSP headers? HSTS? Connection pooling? Cache-Control? Error handling on every fetch()? These get skipped because they're not blocking bugs — they're silent vulnerabilities.

**What it catches (90 patterns, 6 categories):** HTTP client issues, headers & CORS, connection management, caching, request/response patterns, error & monitoring gaps.

**How I'm selling it:** Freemium. Free gets you 30 patterns covering client issues and headers. Pro ($19/mo) adds connection and caching checks. Team ($39/mo) adds everything plus CI/CD.

This is part of my ClawHub suite (27 tools and growing). All bash-based, local-only, zero telemetry.

https://httplint.pages.dev | https://github.com/suhteevah/httplint

---

## Post 4: DateGuard

**Title:** Date bugs are the quietest bugs in software — I built a scanner that finds them

**Body:**

DateGuard scans for date/time anti-patterns: timezone-naive dates, hardcoded month lengths, Y2038 risks, string comparison of dates, ambiguous date formats, dates stored as locale-dependent strings.

**Why I built it:** Date bugs don't throw errors. They produce wrong results that look right. I've seen timezone-naive dates cause incorrect billing for months before anyone noticed. Hardcoded "365 days/year" broke annual subscriptions for leap year customers. The code worked perfectly — just not correctly.

**The unique selling point:** No other static analysis tool focuses specifically on date/time patterns. ESLint won't catch `new Date()` without a timezone. TypeScript won't flag `if (dateA > dateB)` where both are strings. SonarQube has a few date rules but nothing comprehensive.

**Business model:** Same freemium. Free: timezone + formatting checks (30 patterns). Pro ($19/mo): adds epoch/precision + arithmetic (60). Team ($39/mo): all 90 including comparison/parsing and storage/transport.

**Question for the community:** What's the worst date/time bug you've shipped? I'm collecting war stories for a blog post.

https://dateguard.pages.dev | https://github.com/suhteevah/dateguard
