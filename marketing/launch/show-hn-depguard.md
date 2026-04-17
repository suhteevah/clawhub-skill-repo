# Show HN: DepGuard – Local dependency audit with license compliance and SBOM generation

**Title:** Show HN: DepGuard – Local dependency audit + license compliance for 10 package managers

**URL:** https://depguard.pages.dev

**Text:**

Hi HN,

DepGuard is a single tool that wraps native package manager audit commands (npm audit, pip-audit, cargo audit, govulncheck, etc.) and adds license compliance on top.

Why I built it: I was tired of running different audit commands for different projects and having no unified view of license risk. Snyk solves this but sends your data to the cloud. I wanted something local-only.

What it does:
- Detects your package manager automatically (supports 10: npm, yarn, pnpm, pip, cargo, go, composer, bundler, maven, gradle)
- Runs the native audit tool for each
- Scans all dependency licenses and categorizes them (permissive/copyleft/unknown)
- Generates CycloneDX SBOMs for compliance
- Git hooks that block commits modifying lockfiles with critical vulns
- Auto-fix by upgrading to patched versions

Design decisions:
- Uses native audit tools, not a proprietary vulnerability database
- Everything runs locally — no code or dep lists sent externally
- License validation is offline (JWT, no phone-home)
- Free: one-shot scan + license check. Pro ($19/user/mo): hooks + auto-fix. Team ($39/user/mo): SBOM + compliance.

Install: `clawhub install depguard`

Curious if license compliance is something you've been asked about by legal/compliance teams. That's been the most requested feature in my experience.
