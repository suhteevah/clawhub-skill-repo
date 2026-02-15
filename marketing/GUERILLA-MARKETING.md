# $0 Guerilla Marketing Campaign — DocSync + DepGuard

## Core Philosophy

Stop marketing. Start being useful in places where developers complain about the exact problems we solve. Every post should feel like a developer helping another developer, not a company selling a product.

**The play:** Lurk → Help → Mention naturally → Repeat

---

## Channel Breakdown

### 1. ClawHub Forums / OpenClaw Discord
**Priority: HIGHEST — This is home turf**

**Why:** These are people already using the platform our skills run on. Lowest friction conversion path.

**Actions:**
- Post the skill announcement (already written: `launch/clawhub-forum-post.md`)
- Be active in the General channel daily — answer questions about skill development
- When someone asks about documentation or dependency management, drop a casual "oh I actually built something for this"
- Create example use cases: "Here's how I use DocSync + DepGuard together as part of my dev workflow"
- Offer to help people build their own skills — builds reputation, people check your profile, see your tools

**Discord Guild:** `1471337835297509471` / General: `1471337835842900132`

---

### 2. 4chan /g/ (Technology Board)
**Priority: HIGH — Raw, unfiltered developer audience**

**Why:** /g/ is full of developers who hate SaaS, love local-first tools, and will actually try your stuff if it's not bloated. Perfect audience for "100% local, no telemetry, no cloud."

**Tone:** Blunt, technical, zero marketing speak. Self-deprecating humor works. Never say "we" — say "I."

**Threads to target:**
- `/dpt/` — Daily Programming Thread (post useful code snippets showing DocSync output)
- `/wdg/` — Web Development General (DepGuard for npm audit)
- `/fglt/` — Friendly GNU/Linux Thread (local-first angle)
- Any thread complaining about documentation, npm security, or dependency hell

**Post templates:**

**/dpt/ DocSync drop:**
```
>be me
>write function
>forget to update docs
>3 months later nobody knows what anything does
>wrote a pre-commit hook that parses AST with tree-sitter and blocks commits when docs drift
>clawhub install docsync
>free, runs locally, no botnet
>https://docsync-1q4.pages.dev

inb4 just write better docs — yeah that's what everyone says and nobody does
```

**/g/ DepGuard drop:**
```
wrote a dep scanner that wraps native audit tools (npm audit, pip-audit, cargo audit, etc)
instead of sending your shit to snyk's cloud

>100% local
>zero telemetry
>works offline
>covers 10 package managers
>free

clawhub install depguard

the pro version adds git hooks so you can't commit vulnerable deps but honestly the free scan is the main thing
```

**Rules:**
- Never shill. If someone calls it out, own it: "yeah I made it, it's free, use it or don't"
- Be in the thread BEFORE you post about your tool — answer other questions first
- If someone roasts it, take the feedback and respond with humor
- Post source code links, not landing pages. /g/ hates marketing pages
- NEVER post the same thing twice in a week

---

### 3. Reddit — Guerilla Style (Not the Clean Version)
**Priority: HIGH**

The existing reddit-posts.md is good for launch day. This is for the long game.

**Strategy: Answer, Don't Announce**

Search Reddit daily for these queries:
- "documentation out of date"
- "how to keep docs updated"
- "npm audit alternative"
- "snyk alternative free"
- "dependency vulnerability scanner"
- "license compliance open source"
- "pre-commit hooks documentation"
- "stale documentation"

When you find a relevant thread, reply with genuine help first, then mention the tool as ONE option:

**Example reply:**
> There are a few approaches to this:
> 1. Manually audit on a schedule (painful but works)
> 2. Use tree-sitter to parse your code and compare against docs (this is what I do)
> 3. Use an LLM to regenerate docs on each PR
>
> I actually built option 2 into a tool called DocSync if you want to try it. It's free for one-shot generation, the pre-commit hooks are paid though. `clawhub install docsync`

**Subreddits to patrol:**
- r/programming (2.6M members)
- r/webdev (1.1M)
- r/devtools (30K but high quality)
- r/selfhosted (430K — DepGuard's privacy angle kills here)
- r/node (260K)
- r/rust (280K)
- r/python (1.3M)
- r/golang (240K)
- r/sysadmin (870K — license compliance angle)
- r/ExperiencedDevs (180K)

---

### 4. Hacker News — Long Game
**Priority: HIGH**

**Launch posts** are already written. Beyond launch:

**Weekly HN engagement:**
- Search for threads about documentation, dependency management, security scanning
- Leave genuinely helpful technical comments
- Only mention your tool if directly relevant and AFTER providing standalone value
- The goal is to build "suhteevah" as a recognizable username that HN trusts

**Ask HN posts to make:**
- "Ask HN: How does your team keep documentation in sync with code?" (don't mention DocSync — let the thread validate the problem, then link in a reply)
- "Ask HN: What's your dependency audit workflow?" (same pattern)

---

### 5. Dev Discord Servers
**Priority: MEDIUM-HIGH**

These are goldmines because conversations are real-time and people are actively asking for help.

**Target servers:**
- **Reactiflux** (200K+ members) — #help-js, #help-ts
- **Python Discord** (380K+) — #help, #meta
- **Rust Community** (50K+) — #beginners, #general
- **The Coding Den** (100K+) — #general
- **TypeScript Community** — #general
- **Node.js Official Slack** — various channels
- **DevOps Engineers** — #tools

**Strategy:**
1. Join and lurk for 1 week. No promotion.
2. Help 10+ people with genuine answers.
3. When someone asks about docs or deps, mention your tool naturally
4. Add "Built DocSync & DepGuard" to your Discord bio/status — passive marketing

---

### 6. GitHub — The Stealth Channel
**Priority: HIGH**

**Star farming (ethical):**
- Find repos that have documentation issues filed → open a PR that fixes their docs using DocSync-style output → mention DocSync in the PR description
- Find repos with known vulnerabilities → open issues mentioning the vuln → suggest DepGuard as one way to catch these

**Awesome Lists — Direct PRs:**
- `awesome-developer-tools` → add DocSync
- `awesome-security` → add DepGuard
- `awesome-nodejs` → add both
- `awesome-python` → add DepGuard
- `awesome-cli-tools` → add both
- `awesome-devops` → add DepGuard

**GitHub Discussions:**
- Enable Discussions on both repos
- Seed with: "What documentation problems do you want solved?"
- Cross-link from Discord/Reddit when relevant

**GitHub Topics:**
- DocSync: `documentation`, `developer-tools`, `tree-sitter`, `git-hooks`, `cli`, `ast-parser`
- DepGuard: `security`, `vulnerability-scanner`, `license-compliance`, `sbom`, `dependency-audit`, `cli`

---

### 7. Dev.to + Hashnode — SEO Content
**Priority: MEDIUM**

Already have 2 blog posts written. The guerilla angle:

**Write "pain point" articles that rank for problem searches:**
1. "Why Your Documentation Is Always Wrong (And How to Fix It)" — targets people googling the problem
2. "I Replaced Snyk With a Local Script (Here's How)" — targets people looking for alternatives
3. "The Real Cost of Outdated Documentation" — targeting managers/leads
4. "How I Set Up Pre-Commit Hooks That Actually Work" — tutorial format, DocSync as the hero
5. "10 Package Managers, 1 Vulnerability Scanner" — DepGuard capability showcase

**Cross-post to:**
- Dev.to (immediate distribution)
- Hashnode (SEO ownership with custom domain)
- Medium (additional distribution, use friend links to bypass paywall)

---

### 8. Twitter/X — Build in Public
**Priority: MEDIUM**

**Daily posts (takes 10 min):**
- Screenshot of terminal output (DocSync detecting drift, DepGuard finding vulns)
- One-liner tips: "TIL you can block commits with stale docs using a pre-commit hook"
- Engage with dev influencers who tweet about documentation or security
- Quote-tweet complaints about docs/deps with "I literally built a tool for this"

**Target accounts to engage with:**
- Anyone tweeting about documentation problems
- DevRel people at major companies
- Indie hackers building dev tools
- Security researchers discussing supply chain attacks

---

### 9. Indie Hackers
**Priority: MEDIUM**

**"Building in Public" post:**
- Title: "From $0 to first customer — launching two dev tools with zero budget"
- Be transparent about everything: tech stack, pricing, marketing strategy
- Indie Hackers community loves transparency and will share genuine stories

---

### 10. Stack Overflow
**Priority: LOW (high effort, slow payoff)**

**Answer questions** tagged with:
- `documentation-generation`
- `git-hooks`
- `pre-commit`
- `npm-audit`
- `dependency-management`
- `license`

When your answer is genuinely helpful, add a note at the end: "I also built [tool] that handles this automatically if you want to try it." Stack Overflow allows this as long as you disclose the affiliation.

---

## Weekly Guerilla Schedule

| Day | Channel | Action | Time |
|-----|---------|--------|------|
| Monday | Reddit + HN | Search for relevant threads, reply to 3-5 | 30 min |
| Tuesday | 4chan /g/ | Drop into /dpt/ or relevant thread | 15 min |
| Tuesday | Discord | Help in 2 servers, mention tool if natural | 30 min |
| Wednesday | Dev.to | Publish or update a blog post | 1 hour |
| Wednesday | Twitter | Post 3 tweets, engage with 10 accounts | 20 min |
| Thursday | GitHub | Open 1-2 PRs or issues on other repos | 30 min |
| Thursday | ClawHub Discord | Be active, help people | 20 min |
| Friday | Reddit + HN | Search, reply, engage | 30 min |
| Weekend | 4chan /g/ | Weekend threads are slower, easier to dominate | 15 min |

**Total time: ~4 hours/week**

---

## Content to Create NOW (Pre-Launch)

### Must-have before Tuesday launch:
1. [x] ClawHub forum post (done)
2. [x] Show HN posts for both products (done)
3. [x] Reddit posts for 5 subreddits (done)
4. [x] Twitter threads (done)
5. [ ] 4chan /g/ posts (3 variants for different threads)
6. [ ] Discord intro messages (3 server-specific versions)
7. [ ] "Building in Public" Indie Hackers post
8. [ ] GitHub repo READMEs published to actual repos

---

## Anti-Patterns (What NOT to Do)

1. **Never use marketing speak.** No "revolutionize", "leverage", "empower", "streamline"
2. **Never post the same text twice.** Every post should feel native to the platform
3. **Never lead with the product.** Lead with the problem or a helpful answer
4. **Never argue with haters.** Agree, learn, or ignore
5. **Never buy fake stars/upvotes.** One real user > 100 fake metrics
6. **Never spam.** If you feel like you're posting too much, you are
7. **Never post landing page links on 4chan or HN.** Link to GitHub or the actual tool
8. **On /g/, never use emojis.** You will get roasted into oblivion

---

## Measuring Success

**Week 1 targets:**
- 50+ GitHub stars (combined)
- 100+ unique visitors to landing pages
- 20+ email signups
- 5+ ClawHub installs
- 1+ organic mention from someone else

**Week 2 targets:**
- 150+ GitHub stars
- 300+ landing page visitors
- 50+ email signups
- First paid customer

**If you hit these, double down on whatever channel drove the most traffic.**
**If you miss, pivot the messaging — not the channels.**
