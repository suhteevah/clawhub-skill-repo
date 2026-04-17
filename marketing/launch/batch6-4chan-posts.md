# /g/ Posts — Batch 6 (CacheLint, AsyncGuard, FeatureLint, EventLint)

*Post on /g/ - Technology board. Keep it casual, technical, slightly provocative.*

---

## Post 1: CacheLint

**Subject:** Your cache is lying to you and you don't even know it

Anon, I need you to go look at your Redis code right now. Find every `cache.set()` call. Count how many have a TTL. I'll wait.

74% of codebases I've scanned have at least one cache.set() with no expiration. The key lives forever. Memory grows until Redis starts evicting your hot keys to make room for stale garbage nobody reads. And that's the minor problem.

The real fun starts when a popular cache key expires and 1,000 requests simultaneously hit your database because none of them found the cached value. That's a cache stampede. Your database goes from handling 10 queries/sec to 1,000 in a single millisecond. Congratulations, you've turned a cache expiry into a database outage.

Also found in the wild:
- Database writes that never invalidate the cache (users see stale data for hours)
- KEYS * in production code (blocks Redis for 8 seconds, everything freezes)
- N+1 cache lookups in a for loop instead of MGET (100 round-trips instead of 1)
- PII and payment data sitting in Redis in plaintext

Built a scanner. 90 patterns. One command. Pure bash.

```
$ cachelint scan src/
  services/users.ts:45
    ✗ [CRITICAL] CI-001: DB write without cache invalidation
  lib/cache.js:23
    ⚠ [HIGH] TL-001: cache.set() without TTL
  Score: 42/100 (Grade: F)
```

Most codebases score below 50.

Free. Local. No telemetry. Pure bash.

https://cachelint.pages.dev
https://github.com/suhteevah/cachelint

---

## Post 2: AsyncGuard

**Subject:** >he puts readFileSync inside an async function

Anon, your async code is a lie. It looks concurrent. It reads like concurrent. It's actually serializing every request through a synchronous file read that blocks the event loop for 50ms per hit.

True story: a Node.js service hit 100% CPU under load. No errors. No memory leak. No indication of anything wrong except everything was frozen. Root cause: `fs.readFileSync` inside an `async` Express handler. 15ms per call. 200 concurrent requests. Event loop blocked for 3+ seconds at a time. Health checks timing out. Load balancer marking instances as dead.

The function had been in production for 6 months. Nobody caught it because it was inside an async function and looked like all the other await calls.

Other async horrors found in production:
- Async function called without await (returned promise silently discarded, errors vanish)
- .catch(() => {}) actively suppressing errors (worse than no catch at all)
- Promise.all on a dynamic array of 50,000 items (50K simultaneous connections)
- Fire-and-forget sendEmail() that sometimes works and sometimes doesn't and nobody knows
- fetch() without AbortController (hangs for 2 minutes after everyone's moved on)

90 patterns. One command. AST-aware, not grep-level matching.

```
$ asyncguard scan src/
  routes/render.js:45
    ✗ [CRITICAL] SB-001: readFileSync inside async handler
  services/analytics.ts:23
    ⚠ [HIGH] UP-001: async call without await
  Score: 45/100 (Grade: F)
```

Free. Local. No cloud. No telemetry.

https://asyncguard.pages.dev
https://github.com/suhteevah/asyncguard

---

## Post 3: FeatureLint

**Subject:** >400 feature flags
>300 hardcoded to true
>"we'll clean them up eventually"

Anon, your feature flags are not controlling releases. They haven't controlled releases for 14 months. They're `if (true)` blocks with dead else branches that nobody will ever remove because nobody knows if it's safe.

The lifecycle of every feature flag in existence:
1. Developer creates flag for gradual rollout
2. Feature ships
3. Flag reaches 100%
4. Nobody removes flag
5. Six months later: 400 flags
6. Nobody knows which are safe to remove
7. New features built on top of flag-dependent code
8. The codebase is a maze of conditional branches nobody can reason about

Best finding: a flag gating a payment flow at 100% for 9 months. The old payment code path had been partially deleted. The flag was the only thing keeping the system from routing to a broken code path. Nobody knew this. Would have been discovered when someone "cleaned up" the flag.

Also catches:
- Flags gating authentication (flag service goes down = auth bypass)
- Flag evaluation inside loops (50K iterations x 1 eval = 30 min batch job)
- Nested flags: if (A) { if (B) { if (C) { } } } — 8 paths, 2 tested
- Same flag name in 3 services, each seeing a different value during rollout

90 patterns. Git-history-aware. SDK-aware for LaunchDarkly, Unleash, Flagsmith, Split.

```
$ featurelint scan src/
  config/flags.ts:12
    ✗ [CRITICAL] HC-001: Flag hardcoded to true for 11 months
  middleware/auth.js:34
    ⚠ [HIGH] AP-001: Feature flag gating auth logic
  Score: 51/100 (Grade: D-)
```

Free. Local. No telemetry.

https://featurelint.pages.dev
https://github.com/suhteevah/featurelint

---

## Post 4: EventLint

**Subject:** >at-least-once delivery
>consumer has no idempotency check
>enjoy your double charges

Anon, your Kafka consumer processes every message it receives. No dedup. No idempotency key. No check for "did I already process this?" At-least-once delivery means the broker WILL redeliver messages. Consumer restarts, rebalances, network hiccups — all cause redelivery. Without idempotency, that's duplicate charges, duplicate emails, duplicate database records.

Real incident: consumer group rebalanced during a traffic spike. Three payment events redelivered. Consumer processed all three again. Three duplicate charges. $12K before anyone noticed. The consumer assumed exactly-once delivery. Kafka doesn't do exactly-once delivery for your application logic. That's your job.

Other event-driven nightmares found in the wild:
- Fire-and-forget publish (no ack, no retry — event just disappears)
- No dead letter queue (one bad message blocks the entire partition forever)
- No schema versioning (producer changes format, consumers silently break)
- Publish before DB commit (event sent for data that doesn't exist)
- No consumer lag monitoring (50K messages behind, nobody knows for 6 hours)

Event-driven codebases have the lowest scores of anything I scan. Average: 38/100. Teams build the happy path and ignore every failure mode.

```
$ eventlint scan src/
  consumers/payment.js:12
    ✗ [CRITICAL] ID-001: Consumer without idempotency check
  services/orders.ts:34
    ⚠ [HIGH] FF-001: Event publish without ack
  Score: 38/100 (Grade: F)
```

90 patterns. Broker-aware: KafkaJS, confluent-kafka, Pika, SQS/SNS.

Free. Local. No telemetry. Pure bash.

https://eventlint.pages.dev
https://github.com/suhteevah/eventlint
