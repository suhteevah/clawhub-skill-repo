# Product Hunt Launch Plan

## DocSync

**Tagline:** Documentation that stays alive — auto-generate, detect drift, enforce via git hooks

**Description:**
DocSync uses tree-sitter to parse your code (40+ languages) and generate structured documentation. Then it installs a git pre-commit hook that blocks commits when documentation drifts out of sync with your code.

Free: one-shot doc generation
Pro: git hooks + drift detection + auto-fix
Team: onboarding guides + architecture docs

Everything runs locally. Your code never leaves your machine.

**Topics:** Developer Tools, Productivity, Open Source, Documentation

**Makers comment:**
"I built DocSync after watching docs rot on every team I've worked with. The insight: documentation needs the same enforcement mechanism as tests. That's why it hooks into git — if you add a function without documenting it, the commit is blocked. The free tier is fully functional for doc generation. The paid tier adds the 'living docs' workflow."

**First comment:**
"Happy to answer questions about the technical approach. We use tree-sitter for AST parsing (not an LLM) because it's fast, deterministic, and works offline. The hook uses lefthook because it's faster than husky and works across all languages. Everything is MIT licensed."

---

## DepGuard

**Tagline:** Dependency audit + license compliance — 10 package managers, 100% local

**Description:**
DepGuard wraps native package manager audit tools into one interface and adds license compliance. Scan npm, pip, cargo, go, composer, and more for vulnerabilities. Check every dependency license against your policy. Generate CycloneDX SBOMs. All locally.

Free: vulnerability scan + license check
Pro: git hooks + auto-fix + continuous monitoring
Team: SBOM generation + compliance reports + policy enforcement

**Topics:** Developer Tools, Security, Open Source, Compliance

---

## Launch Timing

**Best days:** Tuesday, Wednesday, Thursday
**Best time:** 12:01 AM PST (Product Hunt day resets at midnight PST)
**Prep:** Have 5-10 supporters ready to upvote and comment in the first hour

## Pre-launch Checklist

- [ ] Create Product Hunt maker account
- [ ] Upload logo/icon (📖 for DocSync, 🛡️ for DepGuard)
- [ ] 3 product screenshots/GIFs:
  1. Terminal showing drift detection
  2. Generated documentation output
  3. Landing page pricing
- [ ] Schedule launch for Tuesday 12:01 AM PST
- [ ] Prep 5 "first supporters" to comment authentically
- [ ] Have dev.to article ready to publish same day
- [ ] Have Twitter thread ready to go
- [ ] Post to HN 2-3 hours after PH launch
