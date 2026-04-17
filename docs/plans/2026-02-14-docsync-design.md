# DocSync — ClawHub Skill Design

**Date:** 2026-02-14
**Status:** Approved
**Approach:** Git Hook Integration + FOSS Stack

## Overview

DocSync is an OpenClaw/ClawHub skill that auto-generates documentation from code and detects when docs drift out of sync — enforced via git hooks (lefthook).

## Pricing

| Tier | Price | Features |
|------|-------|----------|
| Free | $0 | One-shot README/doc gen for single files |
| Pro | $29/user/mo | Git hooks, drift detection, auto-regen, multi-lang |
| Team | $49/user/mo | Pro + onboarding guides, cross-repo drift, custom templates |
| Enterprise | $79/user/mo | Team + SSO, audit logs, compliance, SLA |

## FOSS Stack

- **tree-sitter** — AST parsing (40+ languages, MIT)
- **lefthook** — Git hooks (Go, MIT)
- **difftastic** — Semantic diffing (Rust, MIT)
- **jsdoc-to-markdown / TypeDoc** — JS/TS doc gen
- **Sphinx / pdoc** — Python doc gen
- **mdformat** — Markdown formatting

## Architecture

```
commit → lefthook pre-commit → DocSync analyzes staged files via tree-sitter
  → extracts symbols (functions, classes, exports, types)
  → compares against existing docs
  → generates drift report
  → FREE: warns + allows commit
  → PRO: blocks until docs updated, offers auto-regen
  → TEAM: cross-repo drift tracking
```

## License Gating

- Free: no key needed, SKILL.md instructions work out of the box
- Paid: signed JWT in `~/.openclaw/openclaw.json` at `skills.entries.docsync.apiKey`
- JWT encodes: tier, seat count, expiry
- Local validation only, no network call
- Key delivered via Stripe checkout on static site

## File Structure

```
docsync/
├── SKILL.md              # Skill manifest + LLM instructions
├── scripts/
│   ├── docsync.sh        # Main entry point
│   ├── analyze.sh        # tree-sitter analysis
│   ├── drift.sh          # Drift detection
│   ├── generate.sh       # Doc generation
│   ├── hooks-install.sh  # lefthook setup (PRO+)
│   └── license.sh        # JWT license validation
├── templates/
│   ├── readme.md.tmpl    # README template
│   ├── api-doc.md.tmpl   # API documentation template
│   ├── architecture.md.tmpl # Architecture doc template
│   └── onboarding.md.tmpl   # Onboarding guide template (TEAM+)
├── config/
│   └── lefthook.yml      # Hook configuration
└── README.md
```

## Monetization Infrastructure

- Static site (GitHub Pages or Cloudflare Pages) — $0/mo
- Stripe for payments — 2.9% + $0.30 per transaction
- JWT key generation script — runs on Cloudflare Worker free tier
- Total infrastructure: ~$0/mo until Enterprise tier
