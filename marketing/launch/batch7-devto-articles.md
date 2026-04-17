# Dev.to Article Outlines — Batch 7 (RegexGuard, SerdeLint, CronLint, GQLLint)

*Publish on [Dev.to](https://dev.to) | Cross-post to [Hashnode](https://hashnode.com)*

---

## Article 1: "Your Regex Is a Ticking Time Bomb — 6 Patterns That Guarantee ReDoS"

**Tags:** #regex #security #programming #webdev
**Cover image suggestion:** A ticking bomb icon with a regex pattern `/^(a+)+$/` printed on the fuse

### Intro Paragraph

Regular expressions are one of the most powerful tools in a programmer's toolkit — and one of the most dangerous. A single regex in an input validation function can bring an entire web server to its knees. It's called catastrophic backtracking, or ReDoS (Regular Expression Denial of Service), and it happens when a carefully crafted input string forces the regex engine to explore an exponential number of matching paths. In 2019, Cloudflare had a global outage caused by a single regex that consumed 100% CPU across every server. Stack Overflow went down in 2016 for the same reason. Your regex doesn't crash with an error. It just sits there, eating CPU, while every other request queues behind it. The worst part: most regex validation code is never tested with adversarial inputs. You test that it matches valid emails and rejects obviously invalid ones. Nobody tests with a 50-character string of repeating characters designed to trigger exponential backtracking. RegexGuard does.

### Sections

#### 1. Catastrophic Backtracking (Nested Quantifiers)
- The pattern: `/^(a+)+$/` or more realistically, `/^([a-zA-Z0-9_.+-]+)@([a-zA-Z0-9-]+\.)+[a-zA-Z]{2,}$/` — nested quantifiers where an inner quantified group is itself quantified by an outer group
- Why it's dangerous: when the regex engine fails to find a match, it backtracks. With nested quantifiers, the number of backtracking paths grows exponentially with input length. A 25-character input can trigger over 33 million backtracking steps. A 30-character input can take minutes. A 40-character input can take hours. This is not theoretical — it's the exact mechanism behind every major ReDoS incident.
- Code example: an Express middleware that validates user input with `if (!input.match(/^([a-z]+\.)+[a-z]+$/)) return res.status(400)` — works perfectly for valid domains, hangs forever on `aaaaaaaaaaaaaaaaaaaaaaaaa!`
- What RegexGuard catches: rule BT-001 (nested quantifier with overlapping character classes), BT-003 (exponential backtracking risk in user-facing validation), BT-005 (quantified group containing quantified alternation)
- The fix: use atomic groups or possessive quantifiers where your engine supports them. Rewrite `(a+)+` as `(a+)` — the outer quantifier is redundant. For complex patterns, set a timeout on regex execution or use RE2-compatible syntax that guarantees linear-time matching.

#### 2. Missing Anchoring on Validation Patterns
- The pattern: `if (email.match(/[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z]{2,}/))` — a validation regex without `^` and `$` anchors, so it matches a substring rather than the entire input
- Why it's dangerous: the regex matches `valid@email.com<script>alert('xss')</script>` because it finds the valid email substring and ignores everything after it. Unanchored validation patterns are bypassed by appending or prepending malicious content. Email validation, URL validation, phone number validation — all vulnerable if not anchored.
- Code example: a signup form validator that uses `match(/\d{3}-\d{3}-\d{4}/)` for phone numbers — accepts `000-000-0000; DROP TABLE users;--` because the regex finds the phone number substring and ignores the SQL injection payload
- What RegexGuard catches: rule AN-001 (validation pattern without start/end anchors), AN-003 (user input validation with partial-match regex)
- The fix: always use `^` and `$` anchors for input validation. `^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z]{2,}$` matches the full string, not a substring. In multiline contexts, use `\A` and `\z` (or language-equivalent) to match the absolute start and end of the string.

#### 3. Pattern Injection via User Input
- The pattern: `new RegExp(userInput)` or `re.compile(user_input)` — constructing a regex from untrusted user input without escaping special characters
- Why it's dangerous: if a user submits `.*` as a search query, your regex matches everything. If they submit `(?=.*a)(?=.*b)(?=.*c)(?=.*d)(?=.*e)(?=.*f)(?=.*g)(?=.*h)`, they can trigger catastrophic backtracking on purpose. If they submit `)(`, they crash the regex engine with an invalid pattern. User-controlled regex input is both a DoS vector and a crash vector.
- Code example: `const regex = new RegExp(req.query.filter); results = data.filter(item => regex.test(item.name))` — the search endpoint where users can inject arbitrary regex patterns
- What RegexGuard catches: rule PI-001 (regex compiled from user input without escaping), PI-003 (dynamic regex construction with unvalidated variable)
- The fix: escape user input before building a regex: `new RegExp(userInput.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'))`. Better yet, don't use regex for user-facing search — use string methods like `includes()` or `indexOf()` for simple text matching.

#### 4. Portability Errors Across Regex Engines
- The pattern: using features that work in one regex engine but fail silently or error in another — lookbehinds in JavaScript (only supported since ES2018), `\p{L}` Unicode properties in Python (requires `re.UNICODE` flag), atomic groups in PCRE (unsupported in most other engines)
- Why it's dangerous: your regex works in development (Node 18) and fails in production (Node 14). Or it works in Python but fails when the same pattern is used in a Go service via a shared config. Regex engine differences are subtle — a pattern can compile successfully in both engines but match different strings. `\b` in JavaScript doesn't understand Unicode word boundaries, so `\bCafe\b` matches "Cafe" but `\bCafe\u0301\b` (with the combining accent) does not.
- What RegexGuard catches: rule PT-001 (engine-specific syntax in cross-platform context), PT-004 (lookbehind with variable length not supported in target engine), PT-006 (Unicode property escapes used without engine compatibility check)
- The fix: document your target regex engine. Use RegexGuard's portability check to flag patterns that rely on engine-specific features. Stick to POSIX ERE or RE2 syntax for maximum portability.

#### 5. Greedy Quantifiers in HTML/XML Parsing
- The pattern: `/<div class="content">(.+)<\/div>/` — using greedy `.+` or `.*` to match content between delimiters, especially in HTML or XML
- Why it's dangerous: greedy quantifiers match as much as possible. If the HTML contains multiple `<div>` elements, `.+` matches everything from the first opening tag to the LAST closing tag, consuming far more content than intended. In a log parsing context, `.*` can match across line boundaries, consuming the entire file into a single match group.
- What RegexGuard catches: rule GR-001 (greedy quantifier between delimiters without lazy modifier), GR-003 (dot-star pattern used for HTML/XML content extraction)
- The fix: use lazy quantifiers: `(.+?)` instead of `(.+)`. Or better, don't parse HTML with regex at all — use a proper HTML parser. For structured data extraction, regex is a tool of last resort.

#### 6. Unmaintainable Patterns Without Comments
- The pattern: `^(?:(?:\+?1\s*(?:[.-]\s*)?)?(?:\(\s*(?:[2-9]1[02-9]|[2-9][02-8]1|[2-9][02-8][02-9])\s*\)|(?:[2-9]1[02-9]|[2-9][02-8]1|[2-9][02-8][02-9]))\s*(?:[.-]\s*)?)?(?:[2-9]1[02-9]|[2-9][02-9]1|[2-9][02-9]{2})\s*(?:[.-]\s*)?(?:[0-9]{4})$` — a phone number validation regex that nobody can read, modify, or verify
- Why it's dangerous: when a regex is unreadable, it's unverifiable. Nobody reviews it because nobody can understand it. When the requirements change (new area code, international support), nobody dares modify it because any change might break existing matches. The pattern becomes load-bearing technical debt — critical to the system, understood by nobody.
- What RegexGuard catches: rule MN-001 (regex exceeding complexity threshold without x-mode comments), MN-003 (unnamed capture groups beyond count threshold), MN-005 (duplicate character class ranges)
- The fix: use the verbose/extended mode (`x` flag) to add comments and whitespace. Break complex patterns into named groups. Or use a regex builder library that constructs the pattern programmatically.

### Conclusion

Regular expressions are deceptively dangerous. A pattern that works for valid input can hang on adversarial input. A validation pattern that looks correct can be bypassed by appending extra characters. A pattern that works in your engine can fail silently in another.

RegexGuard scans for all 6 of these patterns (and 84 more) in one command:

```bash
clawhub install regexguard
regexguard scan .
```

```
$ regexguard scan src/

  validators/email.ts:12
    [CRITICAL] BT-001: Nested quantifier — exponential backtracking risk
    Pattern: /^([a-zA-Z0-9_.+-]+)@([a-zA-Z0-9-]+\.)+[a-zA-Z]{2,}$/

  middleware/search.js:45
    [CRITICAL] PI-001: Regex compiled from user input without escaping
    new RegExp(req.query.filter)

  utils/parser.py:78
    [HIGH] AN-001: Validation pattern without anchors
    re.match(r'[a-z0-9]+@[a-z]+\.[a-z]+', email)

  lib/phone.js:23
    [MEDIUM] MN-001: Regex exceeds complexity threshold (no comments)
    143 characters, 0 comments, 7 capture groups

  Score: 38/100 (Grade: F)
  4 files scanned | 11 findings | 2 critical
```

Most codebases score below 45 on first scan. The most common finding is nested quantifiers in validation patterns — the exact pattern that causes ReDoS.

Free to scan. Pro ($19/mo) adds pre-commit hooks and auto-fix suggestions. Runs 100% locally — your regex patterns never leave your machine.

https://regexguard.pages.dev | https://github.com/suhteevah/regexguard

---

## Article 2: "Your JSON.parse Has No Try/Catch — 6 Serialization Patterns That Corrupt Data"

**Tags:** #json #serialization #backend #webdev
**Cover image suggestion:** A broken chain link icon with JSON/YAML/Protobuf logos flowing through

### Intro Paragraph

Every application serializes data. JSON over HTTP. YAML for configuration. Protocol Buffers between microservices. CSV for exports. MessagePack for performance. And almost every application does it wrong. Not spectacularly wrong — quietly wrong. A `JSON.parse()` without a try/catch that crashes the server when a single malformed message arrives. A `pickle.loads()` on user-submitted data that gives an attacker arbitrary code execution. A floating-point type used for currency that silently rounds $19.99 to $19.98. An API that returns dates as strings without specifying the timezone, so every consumer parses them differently. Serialization bugs don't trigger alerts. They corrupt data, lose precision, and create security holes that persist for months before anyone notices. SerdeLint finds them before they ship.

### Sections

#### 1. Unsafe Parsing Without Error Handling
- The pattern: `const data = JSON.parse(body)` with no try/catch. `yaml.load(content)` without safe_load. Any deserialization call that assumes the input is always well-formed.
- Why it's dangerous: a single malformed JSON payload crashes the process. In a Node.js server, an unhandled exception from `JSON.parse` kills the entire process if there's no global error handler. In a queue consumer, a malformed message causes the consumer to crash and restart in a loop. The poisoned message stays at the head of the queue, crashing the consumer every time it restarts.
- Code example: a webhook handler that does `const event = JSON.parse(req.body)` with no try/catch — one malformed webhook payload from a third-party service crashes the server
- What SerdeLint catches: rule UP-001 (JSON.parse without try/catch), UP-003 (yaml.load instead of safe_load), UP-005 (deserialization of untrusted input without schema validation)
- The fix: always wrap deserialization in error handling. `try { data = JSON.parse(body) } catch (e) { /* handle malformed input */ }`. For YAML, always use `yaml.safe_load()`. For any untrusted input, validate against a schema after parsing.

#### 2. Pickle/Marshal on Untrusted Data
- The pattern: `pickle.loads(user_data)` in Python, `Marshal.load(data)` in Ruby, `ObjectInputStream` in Java — deserializing untrusted data with a format that supports arbitrary object instantiation
- Why it's dangerous: pickle deserialization can execute arbitrary code. An attacker crafts a pickle payload that runs `os.system('rm -rf /')` when deserialized. This is not a theoretical vulnerability — it's one of the most exploited deserialization bugs in production systems. The Python docs explicitly warn: "Never unpickle data received from an untrusted or unauthenticated source."
- Code example: a Flask endpoint that receives a pickled object from a client: `data = pickle.loads(request.data)` — remote code execution via crafted pickle payload
- What SerdeLint catches: rule UP-010 (pickle.loads on request/user data), UP-012 (Java ObjectInputStream without type allowlisting), UP-014 (Marshal.load on network input)
- The fix: never deserialize untrusted data with pickle, marshal, or Java serialization. Use JSON, Protocol Buffers, or MessagePack — formats that only represent data, not executable code. If you must use pickle for internal communication, sign the payloads with HMAC and verify before deserializing.

#### 3. Floating Point for Currency
- The pattern: `price: float`, `amount: number`, `total: double` — using IEEE 754 floating-point types to represent monetary values
- Why it's dangerous: `0.1 + 0.2 = 0.30000000000000004` in every programming language. Floating-point arithmetic cannot precisely represent most decimal fractions. When you multiply 19.99 by a tax rate, the result has rounding errors. Those errors compound across thousands of transactions. Customers are overcharged or undercharged by fractions of cents. Financial reports don't balance. Rounding inconsistencies between services cause reconciliation failures.
- Code example: `const total = price * quantity * (1 + taxRate)` where all values are JavaScript `number` — produces 23.987000000000002 instead of 23.99
- What SerdeLint catches: rule DL-001 (float/double type used for currency-related field), DL-003 (arithmetic on monetary values without decimal library), DL-005 (currency field serialized without fixed precision)
- The fix: use integer cents (1999 instead of 19.99), decimal types (Python's `Decimal`, Java's `BigDecimal`), or dedicated money libraries. Serialize as strings with fixed precision ("19.99") rather than floating-point numbers.

#### 4. Encoding Mismatches
- The pattern: accepting input in one encoding (UTF-8) and serializing it in another (Latin-1), or reading a file without specifying encoding and relying on the OS default
- Why it's dangerous: encoding mismatches corrupt text silently. A user's name with an accent (Jose) becomes Josÿ. Emoji in a chat message become question marks. A CSV exported as UTF-8 opens in Excel as garbage because Excel defaults to the system encoding. The data looks correct in the database but garbled in the API response.
- What SerdeLint catches: rule EM-001 (file read without explicit encoding parameter), EM-003 (response encoding not matching content-type header), EM-005 (string concatenation across different encoding boundaries)
- The fix: declare encoding everywhere. Use UTF-8 as the default. Always pass `encoding='utf-8'` when reading files. Set `Content-Type: application/json; charset=utf-8` in HTTP responses. Test with non-ASCII input.

#### 5. Schema Validation Gaps
- The pattern: trusting that an API response or configuration file has the expected structure without validating it. `const userId = response.data.user.id` — no check that `response.data` exists, that `user` exists, or that `id` is the expected type.
- Why it's dangerous: when a third-party API changes its response format, your code throws `Cannot read property 'id' of undefined`. When a config file has a typo, the application starts with incorrect settings and runs for hours before anyone notices. Without schema validation, your application accepts any shape of data and fails unpredictably downstream.
- What SerdeLint catches: rule SV-001 (API response consumed without schema validation), SV-003 (configuration loaded without type checking), SV-005 (database query result accessed without null check)
- The fix: validate all external data against a schema. Use Zod, Joi, or JSON Schema for runtime validation. Use TypeScript or mypy for compile-time guarantees. Never trust the structure of data that crosses a trust boundary.

#### 6. Format Interoperability Issues
- The pattern: a system where Service A serializes dates as ISO 8601 strings, Service B expects Unix timestamps, and Service C uses a locale-specific format like "MM/DD/YYYY"
- Why it's dangerous: date parsing ambiguity is the most common interop bug. Is "01/02/2024" January 2nd or February 1st? It depends on which service is reading it. Timezone omission is even worse — "2024-01-15T10:00:00" is a different moment in time depending on whether the reader assumes UTC, EST, or PST. Amount formats (1,234.56 vs 1.234,56) cause similar confusion across locales.
- What SerdeLint catches: rule FI-001 (date serialized without timezone), FI-003 (numeric format without locale specification), FI-005 (inconsistent serialization format across service boundaries)
- The fix: standardize on ISO 8601 with timezone for dates, use integer cents for money, use explicit schemas (Protocol Buffers, Avro) for inter-service communication. Document the serialization contract for every API boundary.

### Conclusion

Serialization is the plumbing of every application. Data flows in, gets parsed, transformed, serialized, and sent out. Every step is an opportunity for silent corruption — a dropped timezone, a rounded penny, a crash from malformed input, or an RCE from a pickle payload.

SerdeLint scans for all 6 of these patterns (and 84 more) in one command:

```bash
clawhub install serdelint
serdelint scan .
```

```
$ serdelint scan src/

  api/webhooks.js:34
    [CRITICAL] UP-001: JSON.parse without try/catch
    const event = JSON.parse(req.body)

  ml/model_loader.py:12
    [CRITICAL] UP-010: pickle.loads on request data
    model = pickle.loads(request.data)

  billing/calculator.ts:56
    [HIGH] DL-001: Float type used for currency field
    const total: number = price * quantity

  utils/csv-export.py:23
    [MEDIUM] EM-001: File write without explicit encoding
    open('export.csv', 'w')

  Score: 35/100 (Grade: F)
  6 files scanned | 14 findings | 3 critical
```

Free to scan. Pro ($19/mo) adds pre-commit hooks and framework-specific fix suggestions. Runs 100% locally — your serialization patterns never leave your machine.

https://serdelint.pages.dev | https://github.com/suhteevah/serdelint

---

## Article 3: "Your Cron Jobs Are Running Blind — 6 Patterns That Guarantee Silent Failures"

**Tags:** #devops #cron #sysadmin #backend
**Cover image suggestion:** A clock face with gears jammed, overlaid with a crontab expression `0 * * * *`

### Intro Paragraph

Cron jobs are the invisible infrastructure of every production system. They run billing calculations at midnight, clean up temp files at 3 AM, sync data between services every 15 minutes, and rotate logs every Sunday. They also fail silently more than any other component. A cron job that throws an error at 2 AM doesn't page anyone — it just doesn't run. The next morning, someone notices the report is missing, or the data sync is 12 hours behind, or the disk is full because cleanup never ran. Cron has no built-in error handling, no retry mechanism, no overlap prevention, and no observability. If your cron job takes longer than its interval, you get two instances running simultaneously, competing for the same resources, corrupting the same files. If it fails, you find out when a human notices the side effect. CronLint scans your crontabs, systemd timers, and scheduled task code for the anti-patterns that guarantee these failures.

### Sections

#### 1. Overlapping Execution (No Locking)
- The pattern: a cron job scheduled every 5 minutes that sometimes takes 8 minutes to complete. Two instances overlap, both processing the same data, writing to the same files, or contending for the same database rows.
- Why it's dangerous: overlapping cron jobs cause data corruption, duplicate processing, and resource contention. A billing job that runs twice charges customers twice. A data sync that overlaps with itself inserts duplicate records. A cleanup job that overlaps with itself tries to delete files the other instance is reading.
- Code example: `*/5 * * * * /usr/bin/python3 /opt/sync/process_orders.py` — no lock file, no check for an existing running instance, no timeout
- What CronLint catches: rule OE-001 (scheduled task without lock file or mutex), OE-003 (cron interval shorter than typical execution time), OE-005 (no flock/lockfile wrapper on long-running job)
- The fix: use `flock` to prevent overlap: `*/5 * * * * /usr/bin/flock -n /tmp/sync.lock /usr/bin/python3 /opt/sync/process_orders.py`. The `-n` flag makes it non-blocking — if the previous run is still going, the new invocation exits immediately.

#### 2. Timezone Errors
- The pattern: a cron job scheduled for `0 9 * * *` (9 AM) that behaves differently during daylight saving time transitions, or a job scheduled on a server in UTC that the developer thought was in local time
- Why it's dangerous: during a DST "spring forward," 2:00 AM becomes 3:00 AM. A job scheduled at 2:30 AM doesn't run at all. During "fall back," 1:00 AM happens twice. A job scheduled at 1:30 AM runs twice. Server timezone doesn't always match application timezone — a cron job running on a UTC server that was designed for EST runs 5 hours early.
- What CronLint catches: rule TZ-001 (cron schedule in DST-affected window without explicit timezone), TZ-003 (system timezone differs from application timezone), TZ-005 (no TZ= prefix in crontab for timezone-sensitive jobs)
- The fix: always set the timezone explicitly in your crontab with the `TZ=` prefix or `CRON_TZ=` directive. Use UTC for all scheduled jobs to avoid DST ambiguity. If the job must run at a local time, document the DST behavior explicitly.

#### 3. Missing Error Recovery
- The pattern: a cron job script with no error handling — if the database is down, the API times out, or the disk is full, the script exits silently with no retry, no alert, and no record of failure
- Why it's dangerous: cron doesn't retry failed jobs. If a nightly billing job fails at 2 AM because the database was temporarily unreachable, it simply doesn't run that night. There's no automatic retry at 2:05 AM. The next run is 24 hours later. You lose an entire day of billing. If the job fails two nights in a row, you lose two days.
- Code example: `0 2 * * * /opt/billing/run.sh` where `run.sh` has no `set -e`, no error trapping, no exit code checking, and no notification mechanism
- What CronLint catches: rule ER-001 (shell script without set -e or error trap), ER-003 (no exit code checking after critical operations), ER-005 (no notification/alerting on job failure)
- The fix: add `set -euo pipefail` at the top of every cron shell script. Add error trapping: `trap 'echo "Job failed at $(date)" | mail -s "CRON FAILURE" ops@company.com' ERR`. Implement retry logic for transient failures. Write exit codes to a status file that monitoring can check.

#### 4. Resource Contention
- The pattern: multiple cron jobs scheduled at the same time (midnight, top of the hour) that compete for CPU, memory, disk I/O, or database connections
- Why it's dangerous: everyone schedules jobs at midnight. The nightly backup, the log rotation, the report generator, the data sync, and the cleanup script all start at `0 0 * * *`. They compete for disk I/O, exhaust database connection pools, and spike CPU to 100%. Individual jobs that take 5 minutes each take 45 minutes when they all run simultaneously. Some time out and fail.
- What CronLint catches: rule RC-001 (multiple cron jobs with identical schedule), RC-003 (three or more jobs scheduled within the same 5-minute window), RC-005 (resource-intensive job without nice/ionice priority setting)
- The fix: stagger job start times. Instead of all at midnight, schedule at 0:00, 0:15, 0:30, 0:45. Use `nice` and `ionice` to set CPU and I/O priorities. Identify resource-heavy jobs and ensure they don't overlap with each other.

#### 5. Lifecycle Management Issues
- The pattern: cron jobs that reference deleted scripts, decommissioned servers, or deprecated APIs. Orphan crontab entries that nobody knows about or dares to remove.
- Why it's dangerous: orphan cron jobs consume resources silently. A job that tries to sync data to a decommissioned server fails every run but nobody sees the errors. A job that references a deleted script generates error emails that go to a shared inbox nobody checks. Over time, production crontabs accumulate dead entries that create noise in logs and confusion during incident response.
- What CronLint catches: rule LM-001 (cron entry referencing non-existent script), LM-003 (no documentation or comment for cron entry), LM-005 (crontab last modified more than 12 months ago with no review)
- The fix: audit crontabs quarterly. Add a comment above every cron entry explaining what it does, who owns it, and when it was last reviewed. Use a cron management tool or version-controlled crontab. Remove jobs for decommissioned services immediately.

#### 6. Observability Gaps
- The pattern: cron jobs that produce no output, write no logs, update no metrics, and send no alerts — completely invisible until someone notices the side effect of their failure
- Why it's dangerous: you can't manage what you can't see. A job that runs for 2 hours with no progress logging is indistinguishable from a hung job. A job that fails silently looks the same as a job that didn't run. Without start/end timestamps, you can't calculate duration trends. Without exit code logging, you can't build a reliability history.
- What CronLint catches: rule OG-001 (no output redirection or logging in cron command), OG-003 (no start/end timestamp logging), OG-005 (no health check or heartbeat mechanism for long-running jobs)
- The fix: every cron job should log start time, end time, exit code, and a summary of work done. Redirect output to a log file or logging service. Use a heartbeat/dead-man's-switch service (Healthchecks.io, Cronitor) that alerts when a job fails to check in on schedule.

### Conclusion

Cron jobs are the most undertested, under-monitored, and under-documented component of every production system. They run in the background, fail in silence, and cause problems that take hours to diagnose because nobody thought to add logging.

CronLint scans for all 6 of these patterns (and 84 more) in one command:

```bash
clawhub install cronlint
cronlint scan .
```

```
$ cronlint scan /etc/crontab /var/spool/cron/ scripts/

  /etc/crontab:15
    [CRITICAL] OE-001: No lock file for job running every 5 minutes
    */5 * * * * /opt/sync/process_orders.py

  scripts/billing.sh:1
    [CRITICAL] ER-001: Shell script without set -e or error trap
    #!/bin/bash (no error handling)

  /var/spool/cron/root:8
    [HIGH] RC-001: 4 jobs scheduled at identical time (0 0 * * *)

  /etc/crontab:22
    [HIGH] TZ-001: Schedule in DST-affected window without TZ
    30 2 * * * /opt/reports/daily.sh

  Score: 31/100 (Grade: F)
  3 sources scanned | 18 findings | 4 critical
```

Most crontabs score below 40 on first scan. The most common finding is missing lock files on jobs that run more frequently than every hour.

Free to scan. Pro ($19/mo) adds CI/CD integration and crontab-as-code validation. Runs 100% locally.

https://cronlint.pages.dev | https://github.com/suhteevah/cronlint

---

## Article 4: "Your GraphQL API Is an All-You-Can-Eat Buffet for Attackers — 6 Anti-Patterns That Guarantee Abuse"

**Tags:** #graphql #security #api #webdev
**Cover image suggestion:** A spider web pattern overlaid with a GraphQL logo, with depth levels labeled 1-20

### Intro Paragraph

GraphQL gives clients the power to ask for exactly the data they need. It also gives attackers the power to ask for all the data, nested 20 levels deep, in a single request that takes your server 30 seconds to resolve. REST APIs have natural boundaries — each endpoint returns a fixed shape of data. GraphQL has no natural boundaries. A client can construct a query that joins users to posts to comments to authors to posts to comments, recursing until the server runs out of memory. Without explicit protections, your GraphQL API is an open invitation for query depth attacks, N+1 resolver performance problems, data over-fetching, and authorization bypass. GQLLint scans your schema, resolvers, and client queries for the anti-patterns that make GraphQL APIs slow, expensive, and exploitable.

### Sections

#### 1. Query Depth Attacks (Recursive Nesting)
- The pattern: a GraphQL schema where `User` has `posts`, `Post` has `author`, and `author` returns a `User` — creating a cycle that clients can exploit with arbitrarily deep nesting
- Why it's dangerous: an attacker sends `{ user { posts { author { posts { author { posts { ... } } } } } } }` nested 50 levels deep. Each level multiplies the number of database queries. Level 1: 1 user. Level 2: 50 posts. Level 3: 50 authors. Level 4: 2,500 posts. By level 10, the server is executing millions of resolver calls. One query, one HTTP request, complete denial of service.
- Code example: a schema with bidirectional relationships: `type User { posts: [Post] }` and `type Post { author: User }` — no depth limit configured
- What GQLLint catches: rule QD-001 (schema with cyclic type references and no depth limit), QD-003 (depth limit not configured or set above 10), QD-005 (recursive fragment spread without depth restriction)
- The fix: configure a query depth limit. Most GraphQL servers support this via middleware. `graphql-depth-limit` for Node.js. Set it to 5-7 for most APIs. Also implement query cost analysis that weights fields by their resolver complexity.

#### 2. N+1 Resolver Problem
- The pattern: a resolver for `User.posts` that queries the database individually for each user: `resolve(user) { return db.posts.findAll({ where: { authorId: user.id } }) }` — called once per user in the parent list
- Why it's dangerous: if the parent query returns 100 users, the `posts` resolver executes 100 separate database queries — one per user. This is the GraphQL equivalent of the SQL N+1 problem. At 5ms per query, that's 500ms of pure database time for one GraphQL query. Add comments on posts and you get 100 users x 50 posts x 1 comment query = 5,000 database queries from a single API call.
- What GQLLint catches: rule NP-001 (list field resolver with individual database query), NP-003 (no DataLoader usage for batch-loadable field), NP-005 (nested list resolver without pagination)
- The fix: use DataLoader to batch and deduplicate resolver queries. Instead of 100 individual queries, DataLoader collects all the user IDs and executes a single `SELECT * FROM posts WHERE author_id IN (id1, id2, ...)` query. One database call instead of 100.

#### 3. Over-Fetching and Under-Fetching
- The pattern: resolvers that fetch entire database rows when the query only asks for one field, or resolvers that make additional API calls for fields that weren't requested
- Why it's dangerous: a client asks for `{ users { name } }` but the resolver does `SELECT * FROM users` — fetching email, address, preferences, and every other column. The database does unnecessary work, the network transfers unnecessary data, and sensitive fields are loaded into memory even though the client didn't ask for them. Under-fetching is the opposite problem: the resolver doesn't fetch enough data, requiring additional queries for related fields.
- What GQLLint catches: rule OF-001 (SELECT * in resolver when query requests specific fields), OF-003 (resolver fetches data for unrequested fields), UF-001 (resolver missing eager loading for commonly requested nested fields)
- The fix: use field-level resolution to only fetch what's requested. Parse the GraphQL info object to determine which fields the client wants: `const requestedFields = graphqlFields(info)`. Build your SQL query to only select those columns.

#### 4. Rate Limiting and Authentication Gaps
- The pattern: a GraphQL API with a single `/graphql` endpoint that has no per-query rate limiting, no query cost analysis, and resolvers that don't check authorization before returning data
- Why it's dangerous: REST APIs get natural rate limiting because different operations hit different endpoints. GraphQL funnels everything through one endpoint, making traditional rate limiting ineffective. An attacker can send 1 request that's equivalent to 10,000 REST calls. Field-level authorization gaps are even worse: a client queries `{ user(id: "other-user") { email, ssn, paymentMethods { last4 } } }` and gets data they shouldn't have because the resolver checks authentication (is the user logged in?) but not authorization (is the user allowed to see THIS user's data?).
- What GQLLint catches: rule RL-001 (no query cost/complexity analysis configured), RL-003 (no per-field rate limiting), AU-001 (resolver without authorization check), AU-003 (sensitive field without field-level permission guard)
- The fix: implement query cost analysis — assign a cost to each field and reject queries that exceed a threshold. Add field-level authorization to every resolver, not just the top-level query. Use a library like `graphql-shield` to define permission rules declaratively.

#### 5. Schema Design Issues
- The pattern: nullable fields that should be non-nullable, missing input validation, unused types, inconsistent naming conventions, deeply nested input types without validation
- Why it's dangerous: a nullable `email` field on a `User` type means every client must handle the null case. If it should always be present, make it non-null in the schema. Missing input validation means the server accepts `createUser(name: "")` or `createUser(name: "a".repeat(100000))`. Inconsistent naming (some fields camelCase, some snake_case) makes the API harder to consume and prone to client-side bugs.
- What GQLLint catches: rule SD-001 (nullable field that is always populated), SD-003 (input type without validation directives), SD-005 (inconsistent naming convention across schema), SD-007 (enum with fewer than 2 values)
- The fix: make fields non-null when they're always present. Add input validation directives or custom scalars for constrained types (Email, URL, PositiveInt). Follow a naming convention consistently across the entire schema.

#### 6. Client Query Safety
- The pattern: client-side GraphQL queries that over-fetch data, use inline strings instead of persisted queries, or include sensitive fields in client-visible query strings
- Why it's dangerous: a React component that queries all user fields but only displays the name wastes bandwidth and exposes sensitive data to the browser's network inspector. Inline query strings are visible in client bundles and can be modified by attackers. Without persisted queries (allowlisted query hashes), any client can send any query to your API.
- What GQLLint catches: rule CQ-001 (client query requesting fields not used in component), CQ-003 (inline query string instead of persisted query), CQ-005 (sensitive field requested in client-side query)
- The fix: use persisted queries (automatic persisted queries or a query allowlist) so only pre-approved queries execute on the server. Lint client queries against field usage — every requested field should be used in the component. Keep sensitive fields in server-to-server queries only.

### Conclusion

GraphQL's flexibility is its greatest strength and its greatest attack surface. Without depth limits, cost analysis, authorization, and rate limiting, your GraphQL API accepts arbitrary queries from anyone, resolves them without limits, and returns whatever data the schema exposes.

GQLLint scans for all 6 of these patterns (and 84 more) in one command:

```bash
clawhub install gqllint
gqllint scan .
```

```
$ gqllint scan src/

  schema/types.graphql:23
    [CRITICAL] QD-001: Cyclic type reference without depth limit
    User -> posts -> Post -> author -> User

  resolvers/user.ts:45
    [CRITICAL] AU-001: Resolver without authorization check
    Query.user returns data without permission guard

  resolvers/posts.ts:12
    [HIGH] NP-001: List field resolver with individual DB query
    Post.comments — no DataLoader, N+1 risk

  schema/types.graphql:67
    [MEDIUM] SD-001: Nullable field always populated
    User.email: String (should be String!)

  Score: 34/100 (Grade: F)
  12 files scanned | 22 findings | 5 critical
```

Most GraphQL APIs score below 40 on first scan. The most common findings are missing depth limits and resolvers without DataLoader.

Free to scan. Pro ($19/mo) adds schema evolution tracking and pre-commit hooks. Runs 100% locally — your GraphQL schema and resolver logic never leave your machine.

https://gqllint.pages.dev | https://github.com/suhteevah/gqllint
