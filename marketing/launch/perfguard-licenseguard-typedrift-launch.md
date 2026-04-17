# ClawHub Launch Posts — Day 2
## PerfGuard, LicenseGuard, TypeDrift
### Date: 2026-02-25

---

## LinkedIn Posts

### PerfGuard — LinkedIn

Your code is slow. You just don't know where yet.

That await inside a for loop? That SELECT * on a 40-column table? That readFileSync buried in your Express handler?

These anti-patterns don't show up in unit tests. They destroy your p99 latency.

APM tools find them AFTER your users complain. By then the damage is done.

PerfGuard catches 40+ performance anti-patterns across Python, JavaScript/TypeScript, Ruby, and Java — locally, before you commit.

What it catches:
→ N+1 queries
→ Missing eager loading
→ Await in loops
→ Sync file I/O in server code
→ Memory leaks (event listeners without cleanup)
→ Missing Promise.all
→ JSON deep clone on every request
→ Unbounded queries without LIMIT

Works with Django, Flask, FastAPI, Express, React, Next.js, Rails, Spring, and Hibernate.

Free to scan. $19/mo for pre-commit hooks and reports.

Zero telemetry. 100% local. No code leaves your machine.

https://perfguard.pages.dev
https://github.com/suhteevah/perfguard

#perfguard #performance #webdev #devtools #clawhub

---

### LicenseGuard — LinkedIn

That GPL dependency you just shipped? Your legal team would like a word.

It starts innocently. A utility library. A CSV parser. You npm install without a second thought.

Three months later, legal discovers you shipped AGPL-3.0 code in your proprietary SaaS product. Now you owe the world your source code.

LicenseGuard scans your dependencies for copyleft, viral, and problematic licenses across 8 ecosystems — npm, Python, Ruby, Go, Java/Kotlin, Rust, PHP, and .NET.

Every dependency classified by risk:
→ Critical: GPL, AGPL, SSPL (your app must be open-sourced)
→ High: LGPL, MPL (modifications must be shared)
→ Medium: Apache, BSD, MIT (notice required)
→ Low: Unlicense, CC0 (essentially public domain)
→ Unknown: No license = no permission to use

Generate SBOMs. Check license compatibility. Enforce approved license lists in CI.

Competitors charge $230/mo (FOSSA) or $25/dev/mo (Snyk). LicenseGuard is free to scan, $19/mo for full features.

100% local. Zero telemetry. No dependency data leaves your machine.

https://licenseguard.pages.dev
https://github.com/suhteevah/licenseguard

#licenseguard #opensource #compliance #devtools #clawhub

---

### TypeDrift — LinkedIn

It starts with one `as any`. Then it spreads.

A @ts-ignore to ship a hotfix. A # type: ignore to pass CI. A @SuppressWarnings("unchecked") because generics are hard. An _ = err because "we'll handle it later."

Later never comes. One escape hatch becomes ten. Ten becomes a hundred. Your strict TypeScript config means nothing when half the codebase bypasses it.

TypeDrift catches quality erosion before it spreads. 80+ patterns across 6 languages — TypeScript, JavaScript, Python, Java, Kotlin, Go, and Ruby.

What it detects:
→ as any / as unknown
→ @ts-ignore / @ts-nocheck
→ # type: ignore / @no_type_check
→ eslint-disable
→ @SuppressWarnings
→ //nolint
→ _ = err (silenced Go errors)
→ rubocop:disable

Every scan produces a drift score (0-100). Track trends across commits. Block erosion in pre-commit hooks. Set quality baselines for legacy codebases.

Competitors: SonarQube (~$150/mo), CodeClimate ($15/dev/mo). TypeDrift is free to scan, $19/mo for hooks and reports.

100% local. Zero telemetry. Pattern matching only.

https://typedrift.pages.dev
https://github.com/suhteevah/typedrift

#typedrift #typescript #codequality #devtools #clawhub

---

## X/Twitter Posts

### PerfGuard — Tweet

Your code is slow. You just don't know where yet.

PerfGuard catches 40+ performance anti-patterns — N+1 queries, await in loops, sync file I/O, memory leaks — across Python, JS/TS, Ruby & Java.

Local. Pre-commit. Zero telemetry.

Free → perfguard.pages.dev

#devtools #performance

---

### LicenseGuard — Tweet

That GPL dependency you just shipped? Your legal team would like a word.

LicenseGuard scans 8 ecosystems for copyleft & problematic licenses. SBOM generation. Policy enforcement. 100% local.

Free → licenseguard.pages.dev

#opensource #compliance #devtools

---

### TypeDrift — Tweet

It starts with one `as any`. Then it spreads.

TypeDrift detects 80+ type suppression patterns across 6 languages. Drift score. Pre-commit hooks. Git blame attribution.

Stop quality erosion before it takes over.

Free → typedrift.pages.dev

#typescript #codequality #devtools