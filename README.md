# ClawHub Skill Repo — clawhub-lint Distribution

This repository packages all 39 [clawhub-lint](https://github.com/suhteevah/clawhub-lint) static analyzers as individually publishable ClawHub skills.

## What's Inside

39 regex-based static analysis tools, each packaged as a standalone ClawHub skill with:

- `SKILL.md` — Frontmatter (name, description, version, tags) + full documentation
- `scripts/patterns.sh` — Pattern definitions (POSIX ERE grep patterns)
- `scripts/scan.sh` — Minimal wrapper that sources patterns and runs the scan
- `scripts/<name>.sh` or `scripts/dispatcher.sh` — Full CLI entry point
- `scripts/analyzer.sh` — Core analysis engine
- `scripts/license.sh` — License validation (free/pro/team tiers)
- `config/` — Hook configurations (lefthook, etc.)
- `templates/` — Report templates

## Analyzers

| # | Skill | Category |
|---|-------|----------|
| 1 | **accesslint** | Web accessibility & WCAG compliance |
| 2 | **apishield** | API security & best practices |
| 3 | **asyncguard** | Async/await anti-patterns |
| 4 | **authaudit** | Authentication & authorization |
| 5 | **bundlephobia** | Bundle size & dependency bloat |
| 6 | **cachelint** | Caching strategy & invalidation |
| 7 | **cloudguard** | Cloud infrastructure security |
| 8 | **concurrencyguard** | Concurrency & race conditions |
| 9 | **configsafe** | Configuration security |
| 10 | **containerlint** | Docker & container best practices |
| 11 | **cronlint** | Cron job & scheduler patterns |
| 12 | **cryptolint** | Cryptography misuse detection |
| 13 | **dateguard** | Date/time handling anti-patterns |
| 14 | **deadcode** | Dead code & unused exports |
| 15 | **doccoverage** | Documentation coverage gaps |
| 16 | **envguard** | Environment variable safety |
| 17 | **errorlens** | Error handling anti-patterns |
| 18 | **eventlint** | Event system & pub/sub patterns |
| 19 | **featurelint** | Feature flag hygiene |
| 20 | **gqllint** | GraphQL schema & query patterns |
| 21 | **httplint** | HTTP client/server best practices |
| 22 | **i18ncheck** | Internationalization & localization |
| 23 | **inputshield** | Input validation & sanitization |
| 24 | **licenseguard** | License compliance & attribution |
| 25 | **logsentry** | Logging quality & sensitive data |
| 26 | **memguard** | Memory management & leaks |
| 27 | **migratesafe** | Database migration safety |
| 28 | **perfguard** | Performance anti-patterns |
| 29 | **pipelinelint** | CI/CD pipeline security |
| 30 | **ratelint** | Rate limiting & throttling |
| 31 | **regexguard** | Regex complexity & ReDoS |
| 32 | **retrylint** | Retry logic & backoff patterns |
| 33 | **schemalint** | Schema validation patterns |
| 34 | **secretscan** | Secret & credential detection |
| 35 | **serdelint** | Serialization/deserialization safety |
| 36 | **sqlguard** | SQL injection & query safety |
| 37 | **styleguard** | CSS/style anti-patterns |
| 38 | **testgap** | Test coverage gaps & anti-patterns |
| 39 | **typedrift** | Type safety & drift detection |

## Quick Start

Scan a project with any single analyzer:

```bash
bash <skill-dir>/scripts/scan.sh /path/to/project
```

## Publishing All Skills

```bash
bash publish-all.sh            # publish all 39 to ClawHub
bash publish-all.sh --dry-run  # preview what would be published
```

## Origin

All patterns originate from [clawhub-lint](https://github.com/suhteevah/clawhub-lint) (3,348+ patterns across 39 analyzers). This repo is the ClawHub distribution channel — each analyzer becomes a standalone, installable skill.

## License

MIT

---

---

---

---

---

---

---

---

---

---

---

---

---

---

---

---

---

---

## Support This Project

If you find this project useful, consider buying me a coffee! Your support helps me keep building and sharing open-source tools.

[![Donate via PayPal](https://img.shields.io/badge/Donate-PayPal-blue.svg?logo=paypal)](https://www.paypal.me/baal_hosting)

**PayPal:** [baal_hosting@live.com](https://paypal.me/baal_hosting)

Every donation, no matter how small, is greatly appreciated and motivates continued development. Thank you!
