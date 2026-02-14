# Show HN: DocSync – Git hooks that block commits with stale documentation

**Title:** Show HN: DocSync – Git hooks that block commits with stale documentation

**URL:** https://docsync.pages.dev

**Text:**

Hi HN,

I built DocSync because every team I've worked on has the same problem: documentation that was accurate when it was written and never updated after.

DocSync uses tree-sitter to parse your code and extract symbols (functions, classes, types). On every commit, a pre-commit hook compares those symbols against existing docs. If you added a function without documenting it, the commit is blocked.

How it works:

1. `clawhub install docsync` (free)
2. `docsync generate .` — generates docs from your code
3. `docsync hooks install` — installs a lefthook pre-commit hook
4. From now on, every commit checks for doc drift

Key design decisions:
- 100% local — no code leaves your machine. Uses tree-sitter for AST parsing, not an LLM.
- Falls back to regex if tree-sitter isn't installed
- Uses lefthook (not husky) for git hooks — it's faster and language-agnostic
- License validation is offline (signed JWT, no phone-home)
- Free tier does one-shot doc generation. Pro ($29/user/mo) adds hooks and drift detection.

Supports TypeScript, JavaScript, Python, Rust, Go, Java, C/C++, Ruby, PHP, C#, Swift, Kotlin.

Would love feedback on the approach. Is doc drift detection something your team would actually use?
