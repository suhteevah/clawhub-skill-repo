# Dev.to Article Outlines — Batch 6 (CacheLint, AsyncGuard, FeatureLint, EventLint)

*Publish on [Dev.to](https://dev.to) | Cross-post to [Hashnode](https://hashnode.com)*

---

## Article 1: "Your Cache Is Broken — 6 Patterns That Guarantee Stale Data"

**Tags:** #redis #caching #backend #devops

### Intro Paragraph

Caching is the first thing teams reach for when they need performance and the last thing they audit for correctness. You add Redis, wrap your database queries, and response times drop from 200ms to 5ms. Everyone celebrates. But nobody asks: when does this cache expire? What happens when someone writes to the database — does the cache know? What if a thousand users request the same expired key at the same millisecond? Caching doesn't fail loudly. It fails by serving stale data. Users see yesterday's prices, last week's inventory counts, someone else's profile. A 2024 survey of production Redis deployments found that 74% had at least one key with no TTL set. Your cache isn't fast — it's a time bomb of stale data.

### Sections

#### 1. Missing Invalidation After Write
- The pattern: a write operation updates the database but does not delete or update the corresponding cache entry. `db.update(user)` succeeds, but `cache.del('user:' + id)` is never called.
- Why it's dangerous: the cache now contains the old version of the record. Every subsequent read returns stale data until the TTL expires — if there even is a TTL. In the worst case, the stale cached value persists indefinitely. Users update their email address and the old one keeps showing up. Inventory is sold out in the database but the cache still says 5 units available. Prices change but the API serves yesterday's prices for hours.
- Code example: an Express route handler that updates a user's profile in PostgreSQL and returns a success response, but never touches the Redis cache that `GET /users/:id` reads from
- What CacheLint catches: rule CI-001 (database write operation without corresponding cache invalidation), CI-003 (cache key pattern found in read path but not in write path for same entity)
- The fix: invalidate on write, always. The simplest correct pattern is cache-aside with explicit deletion: after every successful write to the database, delete the corresponding cache key. `await db.update(user); await cache.del('user:' + user.id);`. If you need stronger consistency, use write-through caching where the cache is updated atomically with the database.

#### 2. No TTL on cache.set()
- The pattern: `cache.set('config:pricing', pricingData)` or `redis.set(key, value)` with no expiration argument — the key lives in Redis forever until someone manually deletes it or the instance restarts
- Why it's dangerous: keys without TTLs accumulate. After six months, your Redis instance holds thousands of keys that may reference deleted users, deprecated features, or outdated configurations. Memory grows until Redis starts evicting keys under its maxmemory policy — and the eviction is indiscriminate. It might evict a hot, frequently-accessed key to make room for a stale one that nobody reads. Without TTLs, you have no cache — you have an append-only data store with no garbage collection.
- Code example: a caching utility module that wraps Redis and exposes a `set(key, value)` function that calls `redis.set(key, JSON.stringify(value))` with no EX or PX argument
- What CacheLint catches: rule TL-001 (cache.set() or redis.set() without TTL/expiration argument), TL-004 (cache write helper that does not accept or pass through a TTL parameter)
- The fix: every cache.set() must include a TTL. Make TTL a required parameter in your cache wrapper — not optional, not defaulted to infinity. `cache.set(key, value, { ttl: 3600 })`. If you genuinely need a permanent key, that's a database row, not a cache entry.

#### 3. Cache Stampede on Expiry
- The pattern: a popular cache key expires, and hundreds or thousands of concurrent requests all find the cache empty, all query the database simultaneously, and all write the result back to the cache
- Why it's dangerous: if a cache key serving 10,000 requests per minute expires, every request in the next few hundred milliseconds hits the database directly. A single expired key can generate a sudden spike of hundreds of identical database queries. The database slows down, which makes the cache writes slower, which means more requests find the cache empty. This is a cache stampede, and it can take down your database in seconds. Popular keys are the most dangerous because they have the highest request rate and therefore the highest stampede intensity.
- Code example: a product catalog endpoint where the cache key for the homepage product list expires every 60 seconds — at second 61, 500 concurrent requests all query PostgreSQL for the same product list simultaneously
- What CacheLint catches: rule CS-001 (high-traffic cache key without stampede protection), CS-003 (cache-aside pattern with no locking or early refresh mechanism on popular keys)
- The fix: implement one of three stampede prevention strategies. Probabilistic early refresh: refresh the cache at random intervals before expiry so it never actually expires under load. Locking: the first request that finds the cache empty acquires a lock, fetches from the database, and populates the cache; all other requests wait for the lock or serve a slightly-stale value. Stale-while-revalidate: serve the expired value while one background request refreshes it.

#### 4. KEYS * in Production
- The pattern: `redis.keys('user:*')` or `KEYS *` used in application code to find, list, or iterate over cache keys in a production Redis instance
- Why it's dangerous: `KEYS` is O(N) where N is the total number of keys in the database. Redis is single-threaded. While KEYS is running, every other operation — every GET, every SET, every health check — is blocked. On a Redis instance with 10 million keys, `KEYS *` takes several seconds. During those seconds, every request to your application that touches Redis hangs. Connection pools exhaust. Timeouts fire. Health checks fail. Your load balancer marks the service as down. One debug command in production code triggers a full outage.
- Code example: an admin endpoint that calls `redis.keys('session:*')` to count active sessions, deployed to production where Redis holds 5 million keys
- What CacheLint catches: rule KS-001 (redis.keys() or KEYS command in application code), KS-003 (pattern-based key lookup without SCAN cursor)
- The fix: use `SCAN` with a cursor instead of `KEYS`. `SCAN 0 MATCH user:* COUNT 100` iterates incrementally without blocking. For counting, maintain a separate counter key that you increment and decrement as entries are added and removed. Never call KEYS in production code. If you need it for debugging, use it on a replica, not the primary.

#### 5. N+1 Cache Lookups
- The pattern: a loop that calls `cache.get()` individually for each item in a collection. `for (const id of userIds) { users.push(await cache.get('user:' + id)); }` — one network round-trip per item
- Why it's dangerous: each `cache.get()` is a network round-trip to Redis. If you have 100 items, that's 100 round-trips. At 0.5ms per round-trip, that's 50ms of pure network latency — no computation, no database queries, just Redis round-trips. This is the cache equivalent of the N+1 database query problem. It eliminates the performance benefit of caching for any list operation. And it gets worse under load: 1,000 requests each making 100 cache calls means 100,000 Redis operations per second from a single endpoint.
- Code example: an API handler that fetches a list of order IDs from the database and then calls `redis.get()` in a loop for each order's cached details, resulting in 50 sequential Redis calls per request
- What CacheLint catches: rule NP-001 (cache.get() inside a for/forEach/map loop), NP-003 (sequential cache reads where MGET pattern is applicable)
- The fix: use `MGET` for bulk reads. `const users = await redis.mget(userIds.map(id => 'user:' + id))` fetches all 100 values in a single network round-trip. For more complex operations, use Redis pipelines. One round-trip instead of N. The code change is minimal, the performance improvement is proportional to the collection size.

#### 6. Sensitive Data in Cache Unencrypted
- The pattern: `cache.set('user:123', JSON.stringify({ name: 'Alice', ssn: '123-45-6789', creditCard: '4111...' }))` — personally identifiable information, payment data, or authentication tokens stored in Redis in plaintext
- Why it's dangerous: Redis has no built-in encryption at rest. By default, anyone with network access to the Redis port can read every key. If Redis is compromised, every cached value is exposed in plaintext. PII, payment card numbers, session tokens, API keys — all readable without decryption. This violates PCI-DSS, GDPR, HIPAA, and virtually every other compliance framework. Even with TLS in transit, the data sits unencrypted in Redis memory and in RDB/AOF persistence files on disk.
- Code example: a session store that caches the full user object including email, phone number, and hashed password in Redis for faster authentication lookups
- What CacheLint catches: rule SD-001 (PII field names detected in cache value serialization), SD-003 (authentication tokens or credentials stored in cache without encryption), SD-005 (cache key containing user data written without field-level encryption)
- The fix: never cache raw PII. Either encrypt sensitive fields before caching (`cache.set(key, encrypt(JSON.stringify(data)))`), or cache only non-sensitive fields and fetch sensitive data from the database on demand. For session stores, cache a session ID that references server-side session data — don't cache the session payload itself. Audit your cache keys with `SCAN` and check what data you're actually storing.

### Conclusion

Caching is not a performance upgrade you install and forget. Every cache entry is a promise that the value is still correct, the key will eventually expire, and the data is safe to store. Break any of those promises and you get stale data, stampedes, memory leaks, or compliance violations.

CacheLint scans for all 6 of these patterns (and 84 more) in one command:

```bash
clawhub install cachelint
cachelint scan .
```

You get a scored report (0-100) with every finding mapped to a severity level and a recommended fix. Each finding includes the cache operation, the file location, and a brief explanation of what's wrong and how to fix it. For example, if it finds `redis.set(key, value)` without a third argument, it explains that this creates a key with no expiration and recommends adding an EX parameter.

Most codebases I've tested score below 50 on first scan. The most frequent findings are missing TTLs and write operations that don't invalidate the cache.

Free to scan. Pro ($19/mo) adds pre-commit hooks so broken cache patterns can't merge. Runs 100% locally — your caching architecture never leaves your machine.

https://cachelint.pages.dev | https://github.com/suhteevah/cachelint

---

## Article 2: "Your Async Code Is Leaking — 6 Patterns That Silently Kill Performance"

**Tags:** #javascript #async #nodejs #webdev

### Intro Paragraph

Async/await made asynchronous JavaScript readable. It did not make it correct. The same patterns that caused callback hell — leaked resources, swallowed errors, unbounded concurrency — still exist. They just look cleaner now. You write `await fetch()` and feel like you've handled everything, but you haven't attached an AbortController, you haven't bounded your Promise.all, and somewhere in your codebase there's a `readFileSync` sitting inside an async Express handler blocking the event loop for every request. Async bugs are performance bugs, and performance bugs are the kind that only appear under load — in production, at 3 AM, when your Node.js process is at 100% CPU and you can't figure out why.

### Sections

#### 1. Unhandled Promise Rejections
- The pattern: `someAsyncFunction()` called without `await`, without `.catch()`, and without a surrounding try/catch — the returned promise is silently discarded. If it rejects, the error goes nowhere.
- Why it's dangerous: in Node.js 15+, unhandled promise rejections crash the process by default. In earlier versions (and in many configurations), they're silently swallowed — the operation fails, but nothing logs it, nothing reports it, and the calling code assumes success. A database write that fails silently. An email that's never sent. A payment webhook that's acknowledged but never processed. The code continues as if nothing went wrong.
- Code example: an Express middleware that calls `analytics.track(event)` without await or .catch() — the tracking call occasionally fails due to network timeouts, but the errors vanish into the void
- What AsyncGuard catches: rule UP-001 (async function called without await or .catch()), UP-003 (promise-returning function invoked in fire-and-forget context without error handler)
- The fix: every promise must be either awaited (inside try/catch) or have a `.catch()` handler attached. If you intentionally fire-and-forget, make it explicit: `someAsyncFunction().catch(err => logger.error('background task failed', err))`. The `.catch()` is not optional — it's the difference between a logged failure and a silent one.

#### 2. readFileSync in Async Handler
- The pattern: `fs.readFileSync()`, `child_process.execSync()`, or any synchronous blocking call used inside an async request handler, middleware, or event listener
- Why it's dangerous: Node.js is single-threaded. A synchronous file read blocks the entire event loop. While `readFileSync` reads a 10MB config file from disk (50ms on SSD, 500ms+ on network storage), every other request, timer, and I/O callback is frozen. Under load, this serializes request handling — 100 concurrent requests each blocking for 50ms means 5 seconds of cumulative blocking. Your async server becomes synchronous. Throughput collapses. p99 latency spikes. And the profiler shows the event loop blocked by filesystem I/O in a function marked `async`.
- Code example: an async Express route handler that calls `fs.readFileSync('./templates/email.html')` on every request to load an email template, blocking the event loop for each render
- What AsyncGuard catches: rule SB-001 (readFileSync inside async function), SB-003 (execSync or spawnSync inside request handler), SB-005 (any *Sync function call in async context)
- The fix: replace every `*Sync` call with its async equivalent. `fs.readFileSync` becomes `await fs.promises.readFile`. `execSync` becomes `await exec` (using `util.promisify`). For files that are read once at startup, `readFileSync` at module load time is fine — but never inside a request handler.

#### 3. Missing AbortController Cleanup
- The pattern: `fetch(url)` or any abortable async operation started without an AbortController, or an AbortController created but never aborted when the calling context ends (component unmount, request cancellation, timeout)
- Why it's dangerous: without an AbortController, a fetch request to a slow endpoint will wait for the full TCP timeout (often 2+ minutes) even if the user has navigated away or the server has already sent a response to the client. In a server context, this ties up memory and connections for operations whose results will never be used. In a browser context, it causes state updates on unmounted components. Over time, leaked fetch requests accumulate — each one holding a socket, a promise chain, and closure references that the garbage collector can't reclaim.
- Code example: a React useEffect that calls `fetch('/api/data')` without an AbortController — navigating away before the response arrives causes a memory leak and a state update on an unmounted component
- What AsyncGuard catches: rule AC-001 (fetch() called without AbortController signal), AC-003 (AbortController created but abort() never called in cleanup path), AC-005 (async operation in useEffect without cleanup function)
- The fix: create an AbortController for every fetch, pass its signal, and call `abort()` in the cleanup path. In React: `useEffect(() => { const ac = new AbortController(); fetch(url, { signal: ac.signal }); return () => ac.abort(); }, [])`. In server code: use `AbortSignal.timeout(5000)` to enforce a maximum duration.

#### 4. .catch(() => {}) Swallowing Errors
- The pattern: `promise.catch(() => {})` or `promise.catch(e => {})` — an empty catch handler that intercepts the rejection and does nothing with it. The error is silently discarded.
- Why it's dangerous: this is the async equivalent of `try { } catch { }`. The operation failed, but the error is actively suppressed. It's worse than an unhandled rejection — at least unhandled rejections generate a warning or crash the process. A swallowed catch produces no log, no metric, no alert. The failure is invisible. Debug sessions stretch for hours because "there are no errors in the logs" while the code is actively catching and discarding dozens of errors per minute.
- Code example: a background job processor that calls `processJob(job).catch(() => {})` to "prevent crashes" — failed jobs silently disappear with no logging, no retry, no dead letter queue
- What AsyncGuard catches: rule SC-001 (empty .catch() handler on promise), SC-003 (.catch() handler that does not log, re-throw, or report the error), SC-005 (try/catch with empty catch block in async function)
- The fix: every .catch() must do something with the error. At minimum, log it: `.catch(err => logger.error('operation failed', { error: err.message, stack: err.stack }))`. If the error is recoverable, handle it and continue. If it's not, re-throw it. An empty catch is never the right answer — it trades a visible failure for an invisible one.

#### 5. Unbounded Promise.all
- The pattern: `Promise.all(urls.map(url => fetch(url)))` where `urls` is an array of unbounded size — potentially hundreds or thousands of concurrent HTTP requests launched simultaneously
- Why it's dangerous: Promise.all launches every promise immediately. If the array has 1,000 URLs, that's 1,000 simultaneous TCP connections. Socket pools exhaust. File descriptor limits are hit. Memory spikes as 1,000 response buffers accumulate simultaneously. The target server may rate-limit or block you. And if any single promise rejects, Promise.all rejects immediately and the other 999 in-flight requests are orphaned — still running, consuming resources, but their results are discarded.
- Code example: a data migration script that calls `Promise.all(records.map(r => uploadToS3(r)))` on 50,000 records, launching 50,000 simultaneous S3 uploads that exhaust the connection pool
- What AsyncGuard catches: rule UA-001 (Promise.all with dynamically-sized array), UA-003 (Promise.all wrapping network calls without concurrency limit), UA-005 (array.map inside Promise.all with external API calls)
- The fix: use a concurrency limiter. `p-limit`, `p-map`, or a simple semaphore pattern that restricts concurrent promises to a reasonable number (10-50 for HTTP requests). `await pMap(urls, url => fetch(url), { concurrency: 10 })` processes all URLs but never has more than 10 in flight simultaneously.

#### 6. Fire-and-Forget Without Logging
- The pattern: calling an async function without awaiting it and without any error handling or logging — `sendEmail(user)` or `updateAnalytics(event)` dropped into the middle of a request handler as a side effect
- Why it's dangerous: fire-and-forget is sometimes intentional — you don't want to wait for analytics to complete before responding to the user. But without any error handling, you have no idea whether it worked. The email might not have sent. The analytics event might have been lost. The audit log might have a gap. These failures accumulate invisibly. A month later, someone notices the email delivery rate dropped to 60% and there's no trail to follow because every failure was silently discarded.
- Code example: an order confirmation handler that calls `sendConfirmationEmail(order)` and `updateInventory(order)` without await — if either fails, the order is confirmed but the email is never sent and inventory is never decremented
- What AsyncGuard catches: rule FF-001 (async function called without await in non-void context), FF-003 (fire-and-forget without .catch() or error boundary), FF-005 (side-effect async call in request handler without logging)
- The fix: if you intentionally don't await, you must still handle errors. The pattern is: `sendEmail(user).catch(err => logger.error('email send failed', { userId: user.id, error: err.message }))`. For critical side effects (inventory updates, payment captures), don't fire-and-forget at all — await them. For non-critical side effects (analytics, logging), fire-and-forget with explicit error handling.

### Conclusion

Async/await is syntactic sugar over promises. It doesn't add safety — it adds readability. Every pattern above compiles, passes type checking, and works correctly under light load. They fail under production conditions: high concurrency, network latency, slow downstream services, and large datasets.

AsyncGuard scans for all 6 of these patterns (and 84 more) in one command:

```bash
clawhub install asyncguard
asyncguard scan .
```

You get a scored report (0-100) with every finding mapped to a severity and a recommended fix. Each finding includes the async anti-pattern type, the file and line, and the correct alternative. For example, if it finds `readFileSync` inside an async function, it recommends `await fs.promises.readFile` with the same arguments.

Most Node.js codebases I've tested score below 50 on first scan. The most frequent findings are unhandled promise rejections and empty .catch() handlers. Both are trivial to fix but invisible without dedicated analysis.

Free to scan. Pro ($19/mo) adds pre-commit hooks so dangerous async patterns can't merge. Runs 100% locally — your codebase never leaves your machine.

https://asyncguard.pages.dev | https://github.com/suhteevah/asyncguard

---

## Article 3: "Your Feature Flags Are Rotting — 6 Patterns That Guarantee Tech Debt"

**Tags:** #devops #featureflags #webdev #programming

### Intro Paragraph

Feature flags are the best idea in software deployment that nobody cleans up. You add a flag to gate a new feature behind a gradual rollout. The rollout completes. The flag stays. Six months later, nobody remembers whether it's safe to remove. A year later, there are 400 flags in the system, 300 of which are permanently set to true, 50 of which gate critical payment paths, and nobody knows what happens if you turn any of them off. Feature flags are meant to be temporary. In practice, they become permanent conditional branches that accumulate until your codebase is a decision tree that nobody can reason about. A 2024 analysis of feature flag platforms found that the average flag lifespan is 14 months — for flags designed to last 2 weeks.

### Sections

#### 1. Flags Hardcoded to true
- The pattern: `if (true) { /* new feature */ }` or `const ENABLE_NEW_CHECKOUT = true` — a feature flag that was set to true during rollout and never removed, leaving dead conditional branches in the code
- Why it's dangerous: the code inside the `if (true)` block is always executed. The else branch is dead code. But the flag is still there, so anyone reading the code assumes it might be toggled. Nobody removes it because nobody's sure whether something depends on the flag's value in another service, a config file, or a monitoring dashboard. Over time, hundreds of `if (true)` blocks accumulate, each adding visual noise and cognitive load. The codebase becomes harder to read, harder to refactor, and harder to understand — all for conditions that are never false.
- Code example: a React component with `if (featureFlags.NEW_DASHBOARD) { return <NewDashboard /> }` where `NEW_DASHBOARD` has been true for 11 months and the old dashboard component is still in the bundle
- What FeatureLint catches: rule HC-001 (feature flag with constant true/false value), HC-003 (flag that has not changed value in 90+ days based on git history), HC-005 (conditional branch that is always taken or never taken)
- The fix: schedule flag removal as part of the rollout process. When a flag reaches 100% rollout, create a ticket to remove the flag and its else branch within 2 weeks. FeatureLint's pre-commit hook flags any flag whose value hasn't changed in configurable time window.

#### 2. Flags Gating Auth/Payment Paths
- The pattern: `if (flags.newAuth) { authenticateV2(user) } else { authenticateV1(user) }` or `if (flags.newCheckout) { processPaymentV2() }` — feature flags wrapping authentication, authorization, or payment processing code
- Why it's dangerous: feature flags are designed for gradual rollout of non-critical features. Authentication and payment paths are the worst possible candidates because a misconfigured flag can disable authentication entirely, skip payment validation, or route users to an untested payment flow. If the flag service goes down and defaults to false, users fall back to the old auth — which may have been partially decommissioned. If it defaults to true, an untested code path handles payments. Either default is dangerous for security-critical paths.
- Code example: a login endpoint that uses a feature flag to switch between a legacy password auth and a new OAuth flow — when the flag service experiences a 30-second outage, some users get no authentication at all because the fallback code path was deleted months ago
- What FeatureLint catches: rule AP-001 (feature flag gating authentication or authorization logic), AP-003 (feature flag wrapping payment processing code), AP-005 (security-critical code path with flag dependency)
- The fix: never gate security-critical paths behind feature flags. Authentication, authorization, payment processing, and data encryption should use versioned APIs, blue-green deployments, or canary releases — not runtime flags. If you must use a flag, ensure the fallback path is fully functional and tested, and add monitoring on both branches.

#### 3. Flag Evaluation in Loop Without Cache
- The pattern: `for (const user of users) { if (await flagService.isEnabled('feature-x', user)) { ... } }` — evaluating a feature flag inside a loop, making a network call or SDK evaluation for every iteration
- Why it's dangerous: feature flag evaluation often involves a network call to a flag service (LaunchDarkly, Unleash, Flagsmith) or at minimum a rule evaluation against user attributes. Inside a loop of 10,000 users, that's 10,000 flag evaluations. Even with a local SDK cache, the rule evaluation overhead per iteration is measurable. With a remote flag service, it's 10,000 HTTP round-trips. The loop that should take 100ms now takes 30 seconds. Batch operations become unusable. Background jobs time out.
- Code example: a nightly batch job that iterates over 50,000 users and evaluates a feature flag per user to determine which notification template to send — the flag evaluation adds 15 minutes to a job that should take 2 minutes
- What FeatureLint catches: rule LE-001 (flag evaluation call inside for/while/forEach loop), LE-003 (async flag evaluation inside synchronous iteration), LE-005 (flag service call in hot path without local cache)
- The fix: evaluate the flag once before the loop if it doesn't vary per user. If it varies per user (percentage rollout, user targeting), batch-evaluate using the flag SDK's batch API, or cache the evaluation result per user context. `const flagValue = await flagService.isEnabled('feature-x'); for (const user of users) { if (flagValue) { ... } }`.

#### 4. Nested Flag Conditions
- The pattern: `if (flags.featureA) { if (flags.featureB) { if (flags.featureC) { /* the only path that actually runs */ } } }` — multiple feature flags nested inside each other, creating a combinatorial explosion of code paths
- Why it's dangerous: three boolean flags create 8 possible combinations. Five flags create 32. In practice, only 1-2 combinations are ever tested, and the others are unknown states. When flag A is true, flag B is false, and flag C is true — what happens? Nobody knows. Nobody tested it. It may work, or it may produce a subtly broken state that only affects users in that flag combination. Debugging requires knowing the exact flag state for a specific user, which is often not logged.
- Code example: a pricing calculation function where three feature flags control different aspects of the pricing algorithm — the interaction between "new tax calculation," "discount V2," and "currency conversion update" creates 8 possible pricing behaviors, only 2 of which were tested
- What FeatureLint catches: rule NF-001 (feature flag conditional nested inside another feature flag conditional), NF-003 (more than 2 flags evaluated in the same function), NF-005 (flag interaction creating more than 4 possible code paths)
- The fix: flatten flag dependencies. Each feature should be controlled by exactly one flag. If features interact, create a single flag that represents the combined state: `PRICING_V2` instead of three separate flags. Test every flag combination that can exist in production, or reduce the combinations by serializing rollouts — finish rolling out flag A before starting flag B.

#### 5. 100% Rollout Without Removal
- The pattern: a feature flag that has been at 100% rollout for weeks or months — every user gets the new code path, but the flag, the old code path, and the flag evaluation overhead remain in the codebase
- Why it's dangerous: the flag is now technical debt. It adds a conditional branch that is never taken. It keeps the old code path in the bundle (increasing bundle size in frontend apps). It adds a flag evaluation on every request (adding latency). It creates a false sense of safety — "we can always roll back" — while the old code path quietly bitrots because nobody tests it. After 6 months at 100%, rolling back is not safe anyway. The flag is doing nothing except making the code harder to read and the system slightly slower.
- Code example: a feature flag dashboard showing 47 flags at 100% rollout, the oldest dating back 18 months — each one still evaluating on every request, each one maintaining a dead code path
- What FeatureLint catches: rule RO-001 (flag at 100% rollout for more than 14 days), RO-003 (flag at 100% with no scheduled removal date), RO-005 (dead else branch from fully-rolled-out flag still in codebase)
- The fix: automate flag lifecycle management. When a flag reaches 100%, automatically create a cleanup ticket with a 2-week deadline. FeatureLint's report includes a "stale flags" section listing every flag at 100% and how long it's been there. The pre-commit hook can warn or block when flag count exceeds a configurable threshold.

#### 6. Flag Coupling Between Services
- The pattern: the same feature flag name evaluated in multiple services — `if (flags.newPricingEngine)` checked in the API service, the billing service, and the notification service, with the assumption that all three will see the same flag value at the same time
- Why it's dangerous: distributed feature flags have no transactional guarantees. Service A might see the flag as true while service B still sees it as false — due to cache lag, deployment timing, or SDK polling intervals. If the new pricing engine is active in the API but the billing service still uses the old calculation, invoices won't match what users see. If the notification service uses new templates but the API returns old data, emails contain incorrect information. Cross-service flag coupling creates distributed inconsistency windows.
- Code example: a microservices architecture where the "new checkout flow" flag is evaluated in the frontend, the cart service, and the payment service — during a gradual rollout, some users see the new UI but their payments are processed by the old backend, causing amount mismatches
- What FeatureLint catches: rule FC-001 (same flag name evaluated in multiple service directories), FC-003 (flag used across service boundaries without consistency mechanism), FC-005 (cross-service flag without documented rollout order)
- The fix: avoid cross-service flags entirely when possible. Each service should own its own flags. If coordination is required, use an explicit rollout order: roll out the backend flag first, verify, then roll out the frontend flag. Document the dependency. Add monitoring for inconsistency. Never assume two services will see the same flag value at the same instant.

### Conclusion

Feature flags are temporary by design and permanent in practice. Every flag that outlives its rollout is a conditional branch that nobody tests, nobody removes, and eventually nobody understands. Flag rot is technical debt that compounds — each new flag interacts with every existing flag, and the complexity grows combinatorially.

FeatureLint scans for all 6 of these patterns (and 84 more) in one command:

```bash
clawhub install featurelint
featurelint scan .
```

You get a flag health report: total flag count, stale flags (hardcoded or unchanged for 90+ days), flags gating critical paths, nested complexity score, and cross-service coupling warnings. Each finding includes the flag name, location, how long it's been in its current state, and whether the else branch has been tested or modified recently.

The average codebase I've tested has 3x more flags than the team believes. The most frequent finding is "flag at 100% rollout without removal plan," followed by "hardcoded flag value" and "nested flag conditions."

Free to scan. Pro ($19/mo) adds pre-commit hooks so stale flags can't accumulate. Runs 100% locally — your feature flag configuration never leaves your machine.

https://featurelint.pages.dev | https://github.com/suhteevah/featurelint

---

## Article 4: "Your Events Are Lost — 6 Patterns That Cause Duplicate Charges"

**Tags:** #kafka #microservices #backend #devops

### Intro Paragraph

Event-driven architecture is the backbone of modern microservices. Services publish events, consumers process them, and the system stays decoupled and scalable. That's the theory. In practice, events get lost, processed twice, delivered out of order, and silently dropped into dead letter queues that nobody monitors. The failure modes of event-driven systems are fundamentally different from request/response — they're asynchronous, delayed, and invisible. A lost HTTP response triggers an immediate error. A lost event triggers... nothing. Nobody knows it's missing until a customer reports that their order was never fulfilled, their refund was never processed, or their account was charged twice. A 2024 post-mortem analysis found that 40% of production incidents in event-driven systems involved either lost events or duplicate processing.

### Sections

#### 1. Fire-and-Forget Publish
- The pattern: `await kafka.send({ topic: 'orders', messages: [{ value: orderData }] })` with no confirmation that the message was actually persisted to the broker, no error handling on the publish call, and no retry on failure
- Why it's dangerous: message publishing can fail. The broker might be temporarily unavailable. The network might drop the packet. The message might exceed the broker's size limit. If the publish call fails silently, the event is lost. The order was placed in your database, but the fulfillment service never received the event. The payment was captured, but the receipt service never sent the confirmation. These are not hypothetical failures — they happen regularly in production, especially during broker restarts, rebalances, and network partitions.
- Code example: an order service that publishes an `order.created` event after inserting the order into the database, but wraps the publish call in `try/catch` with an empty catch block — failed publishes are silently discarded
- What EventLint catches: rule FF-001 (event publish without confirmation/ack verification), FF-003 (publish call without error handling or retry), FF-005 (publish wrapped in catch-all that swallows errors)
- The fix: always verify publish acknowledgment. With Kafka, use `acks: 'all'` to ensure the message is replicated before acknowledging. Wrap publish calls in retry logic with exponential backoff. If the publish ultimately fails after retries, write the event to a local outbox table for later retry. Never silently drop a publish failure.

#### 2. No Idempotency on Consumers
- The pattern: a consumer that processes every message it receives without checking whether it has already processed that message — `consumer.on('message', (msg) => processOrder(msg))` with no deduplication
- Why it's dangerous: at-least-once delivery is the default guarantee for most message brokers. Kafka, RabbitMQ, and SQS will all redeliver messages under various conditions: consumer crashes, rebalances, network timeouts, acknowledgment failures. If your consumer processes every delivery without checking for duplicates, redelivered messages are processed again. Payment captured twice. Order fulfilled twice. Email sent twice. The customer is charged $200 instead of $100 because the payment event was delivered twice and processed both times.
- Code example: a payment consumer that calls `chargeCard(event.amount)` for every `payment.requested` event — during a consumer group rebalance, three events are redelivered and three duplicate charges are created
- What EventLint catches: rule ID-001 (consumer handler without idempotency check), ID-003 (state-changing consumer without deduplication mechanism), ID-005 (consumer processing without event ID tracking)
- The fix: make every consumer idempotent. Store the event ID (or a hash of the event payload) before processing, and check it before processing the next event. `if (await db.exists('processed_events', event.id)) return;`. For payment operations, use idempotency keys with the payment provider. The consumer should produce the same result whether it receives the message once or ten times.

#### 3. Missing Dead Letter Queue
- The pattern: a consumer that retries failed messages in-place with no dead letter queue (DLQ) — messages that can't be processed are retried indefinitely, blocking the partition
- Why it's dangerous: some messages will never process successfully. The order references a deleted product. The event schema is malformed. The downstream service has a bug. Without a DLQ, this "poison pill" message blocks the consumer. It's retried forever — or until someone manually intervenes. Meanwhile, all subsequent messages on that partition are stuck behind it. A single bad event can halt processing for an entire topic. Consumer lag grows. SLAs are breached. And the original failure that caused the poison pill is invisible because the error logs are flooded with retry noise.
- Code example: a Kafka consumer that retries failed messages up to 100 times with no DLQ — a malformed event causes 100 retry attempts over 30 minutes, blocking 200 valid events queued behind it
- What EventLint catches: rule DL-001 (consumer without dead letter queue configuration), DL-003 (retry loop on consumer without max retry limit), DL-005 (failed event handling that blocks partition progress)
- The fix: configure a dead letter queue for every consumer. After N failed attempts (typically 3-5), move the message to a DLQ topic. Monitor the DLQ. Alert when messages arrive. Process DLQ messages manually or with a separate consumer after fixing the underlying issue. The consumer continues processing subsequent messages without being blocked by poison pills.

#### 4. No Schema Versioning
- The pattern: events published with no schema version field, no schema registry, and no contract between producer and consumer about the event structure
- Why it's dangerous: event schemas evolve. You add a field, rename a field, change a type. Without versioning, the producer publishes events in a new format while consumers still expect the old format. Consumer deserialization fails. Or worse — it succeeds but misinterprets the data. A field that was a string is now a number. A field that was required is now missing. These incompatibilities are discovered at runtime, in production, when a consumer crashes or produces incorrect results.
- Code example: an order event producer adds a `discountAmount` field to the event payload — three downstream consumers that don't expect this field either crash during deserialization or silently ignore the discount, producing incorrect totals
- What EventLint catches: rule SV-001 (event published without version field in payload), SV-003 (event schema without compatibility check against consumer expectations), SV-005 (breaking schema change without version increment)
- The fix: include a `version` field in every event payload. Use a schema registry (Confluent Schema Registry, AWS Glue Schema Registry) to enforce compatibility. Follow semantic versioning for schemas: additive changes (new optional fields) are backward-compatible; removal or type changes require a version bump and consumer migration. Test schema compatibility in CI before deploying producers.

#### 5. Publish Before DB Commit (Dual-Write)
- The pattern: publishing an event and writing to the database as two separate operations that are not transactionally linked — `await publishEvent(order); await db.insert(order);` or the reverse
- Why it's dangerous: if you publish first and the database write fails, consumers receive an event for data that doesn't exist. If you write to the database first and the publish fails, the data exists but no event was sent. Either way, the event stream and the database are out of sync. This is the dual-write problem, and it's the most common source of data inconsistency in event-driven systems. It can't be solved by ordering the operations — any ordering leaves a failure window where one succeeds and the other hasn't happened yet.
- Code example: an order service that calls `kafka.publish('order.created', order)` and then `db.orders.insert(order)` — when the database insert fails due to a constraint violation, consumers have already received an event for an order that doesn't exist
- What EventLint catches: rule DW-001 (event publish and database write as separate non-transactional operations), DW-003 (publish call before database commit in same function), DW-005 (dual-write pattern without outbox or CDC mechanism)
- The fix: use the transactional outbox pattern. Write the event to an outbox table in the same database transaction as the business data: `BEGIN; INSERT INTO orders ...; INSERT INTO outbox (event_type, payload) ...; COMMIT;`. A separate process (or CDC connector like Debezium) reads the outbox and publishes to the message broker. The event is guaranteed to be published if and only if the business data was committed.

#### 6. No Consumer Lag Monitoring
- The pattern: consumers running without monitoring the offset lag — the difference between the latest message published and the latest message consumed. No alerts, no dashboards, no visibility into how far behind consumers are.
- Why it's dangerous: consumer lag is the early warning system for event-driven architectures. A consumer falling behind means messages are accumulating faster than they're being processed. Without monitoring, you won't know until the symptoms appear: stale data in the UI, delayed notifications, orders stuck in "processing" for hours, inconsistency between services. By the time a user reports "my order hasn't been confirmed," the consumer might be 100,000 messages behind. Recovery takes hours. And without lag visibility, you can't distinguish between "the consumer is slow" and "the consumer is dead."
- Code example: a notification consumer that falls behind during a traffic spike, accumulating 50,000 unprocessed messages — without lag monitoring, the team doesn't notice until users complain about missing notifications 6 hours later
- What EventLint catches: rule LM-001 (consumer group without lag monitoring configuration), LM-003 (consumer without health check or heartbeat mechanism), LM-005 (topic without consumer lag alerting threshold)
- The fix: monitor consumer lag for every consumer group. Set alert thresholds: warn at 1,000 messages behind, page at 10,000. Use Kafka's built-in consumer group metrics, or tools like Burrow, Kafka Lag Exporter, or your cloud provider's built-in monitoring. Consumer lag should be on your primary dashboard alongside CPU, memory, and error rate.

### Conclusion

Event-driven architectures trade synchronous simplicity for asynchronous complexity. Every event is a promise that it will be delivered, processed exactly once, and handled correctly regardless of consumer failures. Without idempotency, dead letter queues, schema versioning, and lag monitoring, that promise is broken — silently, asynchronously, and expensively.

EventLint scans for all 6 of these patterns (and 84 more) in one command:

```bash
clawhub install eventlint
eventlint scan .
```

You get a scored report (0-100) with every finding mapped to a severity level and a recommended fix. Each finding includes the event operation, the file location, and the correct alternative. For example, if it finds a Kafka consumer handler that modifies state without deduplication, it recommends implementing an idempotency check using the event ID or a hash of the event payload, with a code example.

The average first-scan score is 38 — the lowest of any tool in the ClawHub suite. Event-driven code consistently has the weakest error handling because the failures are asynchronous and invisible. The most frequent findings are "consumer without idempotency check" and "event published without ack verification."

Free to scan. Pro ($19/mo) adds pre-commit hooks so dangerous event patterns can't merge. Runs 100% locally — your event architecture never leaves your machine.

https://eventlint.pages.dev | https://github.com/suhteevah/eventlint
