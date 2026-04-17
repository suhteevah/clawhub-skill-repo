# Discord Server Intro Messages

## OpenClaw / ClawHub Discord

Already covered in `clawhub-forum-post.md`. Post in General channel.

---

## Reactiflux (#help-js or #general)

**Don't post this on day 1. Lurk and help for a few days first.**

When someone asks about documentation:
```
hey, I actually built something for this — it's a pre-commit hook that uses tree-sitter to parse your TS/JS and block commits when docs go stale

clawhub install docsync

free for doc generation, the hooks are paid. runs locally, no cloud stuff

happy to help set it up if you want to try it
```

When someone asks about dependency security:
```
if you want something that runs locally instead of sending your package-lock to snyk:

clawhub install depguard

wraps npm audit + adds license compliance checking. free to scan, pro adds git hooks

I built it because I didn't want to send my dep tree to a third party
```

---

## Python Discord (#help or #general)

When someone asks about documentation or dependencies:
```
I built a CLI tool for this if you want to try it

for docs: `clawhub install docsync` — uses tree-sitter to parse python and detect when your docs drift from your code. installs a pre-commit hook that blocks stale-docs commits

for deps: `clawhub install depguard` — wraps pip-audit and adds license scanning. catches vulnerable deps before they hit production

both free, runs locally, no telemetry
```

---

## Rust Community Discord

```
wrote a dep scanner that wraps cargo audit + adds license compliance scanning

clawhub install depguard

also supports npm, pip, go, composer, bundler, maven, gradle — 10 total

the rust community probably doesn't need this as much since cargo audit is already great but the license compliance part might be useful if you're shipping anything with mixed-license dependencies

free scan, pro adds git pre-commit hooks
```

---

## General "Helpful Reply" Template (Any Server)

When someone complains about docs being outdated:
```
this is literally why I built [tool name] — it installs a git hook that parses your code with tree-sitter and blocks commits when docs don't match

[link to github]

free to try, takes about 30 seconds to set up
```

When someone asks about vulnerability scanning:
```
I use depguard for this — it wraps the native audit tools for whatever package manager you're using and adds license checking on top

one command to scan everything: clawhub install depguard

no account needed, runs locally
```

---

## Discord Bio/Status

Set your Discord status or bio to:
```
Building DocSync & DepGuard — dev tools for docs & deps
github.com/suhteevah
```

This is passive marketing — anyone who clicks your profile sees it.

---

## Rules for Discord

1. Help 10 people before you ever mention your tool
2. Never DM people about your product unsolicited
3. Only mention your tool when it directly solves the problem being discussed
4. If a mod warns you about self-promotion, apologize and scale back
5. Build genuine relationships — these are your early adopters
6. Be in the server regularly, not just when you want to promote
