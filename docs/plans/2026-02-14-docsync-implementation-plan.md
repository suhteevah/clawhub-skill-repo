# DocSync Implementation Plan

## Steps

1. Create skill directory structure at `J:/clawhub skill repo/docsync/`
2. Write `SKILL.md` with full frontmatter and LLM instructions
3. Write `scripts/docsync.sh` — main CLI entry point (generate, drift, hooks-install)
4. Write `scripts/analyze.sh` — tree-sitter symbol extraction
5. Write `scripts/drift.sh` — compare extracted symbols vs existing docs
6. Write `scripts/generate.sh` — doc generation from templates
7. Write `scripts/hooks-install.sh` — lefthook pre-commit setup (PRO+)
8. Write `scripts/license.sh` — JWT license validation (local, offline)
9. Write all templates (readme, api-doc, architecture, onboarding)
10. Write `config/lefthook.yml` — hook configuration
11. Write `README.md` — user-facing docs for the skill
12. Test the skill locally
13. Publish to ClawHub
