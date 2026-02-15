# 4chan /g/ Posts — Ready to Drop

## Post 1: /dpt/ — Daily Programming Thread (DocSync)

```
wrote a pre-commit hook that uses tree-sitter to parse your code and block commits when docs are stale

basically:
>you write a function
>don't update the docs
>try to commit
>get blocked
>forced to update docs or skip the hook like a degenerate

supports 40+ languages, runs 100% locally, no cloud bullshit

clawhub install docsync
https://github.com/suhteevah/docsync

free for one-shot doc generation. the git hooks are $29/mo because I need to eat

genuinely curious if anyone else has tried to solve this or if everyone just accepts that docs rot
```

---

## Post 2: /g/ General or /dpt/ (DepGuard)

```
got tired of snyk wanting to phone home with my entire dependency tree so I wrote my own scanner

>wraps native audit tools (npm audit, pip-audit, cargo audit, govulncheck, etc)
>10 package managers
>adds license compliance scanning on top
>zero telemetry
>runs offline
>doesn't need an account

clawhub install depguard

free to scan. pro version adds git hooks that block you from committing vulnerable deps

before you ask: yes I know about npm audit. this is npm audit + pip-audit + cargo audit + 7 others in one command, plus it checks licenses so you don't accidentally ship AGPL in your proprietary codebase

https://github.com/suhteevah/depguard
```

---

## Post 3: /dpt/ — Problem First (No Product Mention Initially)

```
genuine question /dpt/: how do you keep documentation in sync with your code?

every project I've worked on starts with great docs and 6 months later they're completely wrong. new functions aren't documented, deleted functions are still in the docs, parameter changes aren't reflected.

I've tried:
>manually reviewing on PR (nobody does it)
>CI checks that fail if docs/ was changed (too many false positives)
>generating everything from JSDoc/docstrings (only covers function-level stuff)
>tree-sitter AST comparison (this actually worked)

what does /g/ do? or does everyone just accept the entropy
```

Then follow up in the thread with DocSync if people engage.

---

## Post 4: Weekend /g/ — Building in Public Angle

```
/g/ rate my side project

>two cli tools for developers
>one blocks commits when docs are stale (tree-sitter AST parsing)
>one scans dependencies for vulnerabilities across 10 package managers
>both 100% local, zero telemetry
>hosted on cloudflare free tier so my costs are literally $0
>freemium model: free core, paid git hooks

https://github.com/suhteevah/docsync
https://github.com/suhteevah/depguard

be brutal. what would make you actually use something like this?
```

---

## Tone Guide for /g/

- Greentext for storytelling
- Self-deprecating humor
- Never use emojis
- Never use corporate language
- "I" not "we"
- Always link GitHub, never landing pages
- If called out for shilling: "yeah I made it, it's free, cope"
- If roasted: take the feedback, post an update later incorporating it
- If ignored: don't repost for at least 3 days
