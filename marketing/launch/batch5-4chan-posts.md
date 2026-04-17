# /g/ Posts — Batch 5 (CryptoLint, RetryLint, HTTPLint, DateGuard)

*Post on /g/ - Technology board. Keep it casual, technical, slightly provocative.*

---

## Post 1: CryptoLint

**Subject:** Your crypto code is broken and you don't know it

Your codebase has MD5 somewhere. Don't deny it. "It's just for checksums" you say, while someone on your team used it for password hashing 3 years ago and nobody noticed because it works. It hashes. It just doesn't protect anything.

Built a scanner that finds all of it. 90 patterns covering weak algorithms, hardcoded keys, ECB mode, Math.random() for tokens, timing-vulnerable comparisons, disabled TLS verification.

```
$ cryptolint scan src/
  auth/hash.js:23
    ✗ [CRITICAL] WA-001: MD5 used for password hashing
  config/crypto.ts:8
    ⚠ [HIGH] KM-003: Hardcoded encryption key
  Score: 58/100 (Grade: F)
```

Most repos score below 60.

Free to scan. Runs locally. No telemetry. Pure bash.

https://cryptolint.pages.dev
https://github.com/suhteevah/cryptolint

---

## Post 2: RetryLint

**Subject:** >he doesn't have circuit breakers

Anon, your retry logic is a while(true) loop with sleep(1000). When the upstream service goes down for 2 minutes, every single request retries infinitely with no backoff, creating a retry storm that's 50x your normal traffic. When the service comes back, it immediately goes down again under the load.

I've seen this take down production systems serving 50M req/day. The fix was killing a single while loop.

Built a tool that finds these patterns statically:
- Infinite retries without max attempts
- Fixed delays instead of exponential backoff
- External calls without circuit breakers
- HTTP requests with no timeout
- Retrying non-idempotent operations (duplicate charges, anyone?)
- No fallback for degraded services

90 patterns. One command. Pure bash. Runs locally.

https://retrylint.pages.dev

---

## Post 3: HTTPLint

**Subject:** >Access-Control-Allow-Origin: *

Anon... I can see your CORS from here.

91% of production APIs are missing at least one critical security header. No CSP. No HSTS. No X-Frame-Options. CORS set to wildcard because "it fixed the error in development."

Also:
- fetch() with no error handling (just... hoping it works)
- New HTTP client per request (no connection pooling)
- No Cache-Control on any endpoint
- catch(e) {} on API calls (the error is gone now, right?)

Built a scanner. 90 patterns. Headers, CORS, connection management, caching, error handling, monitoring.

```
$ httplint scan src/
  middleware/cors.js:12
    ✗ [CRITICAL] HH-001: CORS wildcard (*)
  services/api.ts:45
    ⚠ [HIGH] HC-003: fetch() with no error handling
  Score: 61/100 (Grade: D)
```

Free. Local. No telemetry. Pure bash.

https://httplint.pages.dev

---

## Post 4: DateGuard

**Subject:** new Date() is wrong and you don't know it

```javascript
const now = new Date();
```

This is wrong. You just don't know what timezone you got. Might be UTC. Might be the server's local time. Might be the developer's laptop timezone that got baked into a Docker image during a Saturday deploy.

Date bugs don't throw errors. They silently produce wrong results that look right:
- Timezone-naive dates that work until DST changes
- Hardcoded 365 days/year (leap year says hi)
- Hardcoded 28/30/31 days per month
- String comparison of dates (works until it doesn't)
- "01/02/2024" — January 2 or February 1? Depends on locale
- Date.now()/1000 stored in 32-bit int (Y2038 time bomb)

90 patterns. One command. Scores your codebase 0-100.

```
$ dateguard scan src/
  services/booking.js:23
    ✗ [CRITICAL] TZ-001: new Date() without timezone
  lib/scheduler.js:67
    ⚠ [HIGH] DA-002: Hardcoded 365 days/year
  Score: 64/100 (Grade: D)
```

Free. Local. No cloud. No telemetry.

https://dateguard.pages.dev
