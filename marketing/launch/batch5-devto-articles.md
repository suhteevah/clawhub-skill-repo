# Dev.to Article Outlines — Batch 5 (CryptoLint, RetryLint, HTTPLint, DateGuard)

*Publish on [Dev.to](https://dev.to) | Cross-post to [Hashnode](https://hashnode.com)*

---

## Article 1: "Your Crypto Is Broken — 6 Patterns That Guarantee a Breach"

**Tags:** #security #cryptography #webdev #devops

### Intro Paragraph

Most devs don't think about cryptography until something breaks. You copy encryption code from Stack Overflow, use MD5 "just for checksums" (spoiler: someone's using it for passwords), hardcode a key because "it's just for development." But crypto code has a unique property: it fails silently. Your encryption works — it just doesn't protect anything. A 2024 analysis found that 68% of open source projects contain at least one deprecated cryptographic algorithm in active use. Your crypto isn't just outdated — it's a liability.

### Sections

#### 1. MD5/SHA-1 for Password Hashing
- The pattern: `createHash('md5').update(password).digest('hex')` or `SHA1(password)` used to hash user credentials before storage
- Why it's dangerous: MD5 and SHA-1 are not password hashing algorithms — they are message digests designed for speed. That speed is the problem. Modern GPUs can brute-force billions of MD5 hashes per second. Rainbow tables for MD5 are freely available and cover every common password. Collision attacks against MD5 have been practical since 2004, and SHA-1 since 2017.
- Code example: a registration handler that hashes the password with `crypto.createHash('sha1').update(req.body.password).digest('hex')` and stores the result in the database
- What CryptoLint catches: rule WA-001 (MD5 used for password or credential hashing), WA-003 (SHA-1 used in authentication context)
- The fix: use bcrypt with a cost factor of at least 12, scrypt, or Argon2id. These algorithms are intentionally slow and include salting by default. `await bcrypt.hash(password, 12)` is the one-liner that replaces the vulnerability.

#### 2. Hardcoded Encryption Keys
- The pattern: `const ENCRYPTION_KEY = 'mySecretKey123'` or `const IV = Buffer.from('1234567890123456')` declared as string literals in source code
- Why it's dangerous: anyone with access to the repository has the key — every developer, every CI runner, every backup. Key rotation is impossible without a code change and redeployment. If the key leaks (and hardcoded keys always leak), every piece of data ever encrypted with it is compromised retroactively.
- Code example: an encryption utility module that exports a `encrypt(plaintext)` function using a key defined as a constant at the top of the file
- What CryptoLint catches: rule KM-001 (encryption key hardcoded as string literal), KM-004 (initialization vector hardcoded or reused across calls)
- The fix: load keys from environment variables at minimum. For production, use a KMS (AWS KMS, GCP KMS, Azure Key Vault) or HashiCorp Vault. Keys should be rotatable without code changes. IVs must be randomly generated per encryption operation.

#### 3. ECB Mode for AES
- The pattern: `crypto.createCipheriv('aes-128-ecb', key, null)` or any AES cipher instantiation using ECB mode
- Why it's dangerous: ECB (Electronic Codebook) encrypts each 16-byte block independently with the same key. Identical plaintext blocks produce identical ciphertext blocks. This leaks patterns in the data — the classic demonstration is the ECB penguin, where an encrypted bitmap image is still visually recognizable. In practice, this means an attacker can detect repeated data, reorder blocks, and perform substitution attacks.
- Code example: a function that encrypts user data with `aes-256-ecb` and returns the hex-encoded ciphertext
- What CryptoLint catches: rule EM-001 (AES used in ECB mode)
- The fix: use AES-GCM, which provides both confidentiality and integrity (authenticated encryption). If AES-GCM is unavailable, use AES-CBC with a random IV per operation and a separate HMAC for integrity. `crypto.createCipheriv('aes-256-gcm', key, iv)` is the correct call.

#### 4. Math.random() for Security Tokens
- The pattern: `Math.random().toString(36).substring(2)` used to generate session tokens, API keys, password reset codes, or any security-sensitive identifiers
- Why it's dangerous: `Math.random()` is a pseudorandom number generator seeded from a predictable source. Its output is not cryptographically secure — given enough samples, an attacker can predict future values. In V8, the internal state of Math.random can be reconstructed from fewer than 10 outputs, allowing prediction of every subsequent token.
- Code example: a password reset handler that generates a reset token with `const token = Math.random().toString(36) + Math.random().toString(36)` and stores it in the database
- What CryptoLint catches: rule RN-001 (Math.random() used for token or security-sensitive value generation)
- The fix: use `crypto.randomBytes(32).toString('hex')` in Node.js or `crypto.getRandomValues(new Uint8Array(32))` in the browser. These read from the operating system's cryptographic random number generator and are not predictable.

#### 5. String Comparison for HMAC Verification
- The pattern: `if (computedHmac === providedHmac)` or `if (hash === expectedHash)` using standard string equality to verify cryptographic values
- Why it's dangerous: standard string comparison is not constant-time. It returns `false` as soon as it finds the first mismatched byte. An attacker can measure the response time to determine how many leading bytes of their guess are correct, then brute-force the value one byte at a time. This is a timing side-channel attack, and it works over the network — response time differences of microseconds are measurable.
- Code example: a webhook verification function that computes the HMAC of the request body and compares it to the signature header with `===`
- What CryptoLint catches: rule TC-001 (non-constant-time comparison of HMAC, hash, or token values)
- The fix: use `crypto.timingSafeEqual(Buffer.from(computedHmac), Buffer.from(providedHmac))`. This function always compares all bytes regardless of where the first mismatch is, eliminating the timing signal. Both buffers must be the same length.

#### 6. Disabled TLS Verification
- The pattern: `rejectUnauthorized: false` in HTTPS options, `NODE_TLS_REJECT_UNAUTHORIZED=0` in environment, or `verify=False` in Python requests
- Why it's dangerous: disabling certificate verification means your application will accept any certificate — including one presented by a man-in-the-middle attacker. The encrypted channel is still established, but you have no guarantee you're talking to the server you think you are. Every piece of data sent over that connection can be intercepted and modified.
- Code example: an API client configured with `const agent = new https.Agent({ rejectUnauthorized: false })` because the dev environment uses a self-signed certificate, and the flag was never removed before deploy
- What CryptoLint catches: rule CP-001 (TLS certificate verification disabled), CP-003 (NODE_TLS_REJECT_UNAUTHORIZED set to 0)
- The fix: use proper certificate management. For development, add self-signed CA certificates to the trust store instead of disabling verification entirely. For production, this flag must never be set. CryptoLint's pre-commit hook rejects any commit containing `rejectUnauthorized: false`.

### Conclusion

Cryptographic code is the only category of code where "it works" and "it's secure" have zero overlap. Every pattern above will encrypt, hash, or generate tokens successfully. None of them will protect your users.

CryptoLint scans for all 6 of these patterns (and 84 more) in one command:

```bash
clawhub install cryptolint
cryptolint scan .
```

Free to scan. Pro ($19/mo) adds pre-commit hooks so broken crypto can't merge. Runs 100% locally — your cryptographic implementation details never leave your machine.

https://cryptolint.pages.dev | https://github.com/suhteevah/cryptolint

---

## Article 2: "Your Retry Logic Is a Ticking Time Bomb — 6 Patterns That Cause Cascading Failures"

**Tags:** #microservices #reliability #devops #backend

### Intro Paragraph

Every distributed system fails. Networks partition. Services crash. Databases timeout. The question isn't whether your system will encounter failures — it's how it handles them. And the answer, in most codebases, is "badly." Infinite retry loops that amplify a single failure into a cascading outage. Fixed delays that create thundering herds. Missing circuit breakers that let one bad service take down the entire cluster. I've seen a single misconfigured retry loop take down a production system serving 50M requests/day. Here are the 6 patterns that cause it.

### Sections

#### 1. Infinite Retry Without Max Attempts
- The pattern: `while (true) { try { await fetch(url); break; } catch (e) { await sleep(1000); } }` — a retry loop with no exit condition other than success
- Why it's dangerous: if the downstream service is down, you are not retrying — you are DDoSing it. Every request that comes in spawns an infinite retry loop. If your service handles 1,000 requests per second and each one retries indefinitely, you've turned a single service outage into 1,000 persistent connections hammering a dead endpoint. The downstream service can never recover because the moment it comes back, it's overwhelmed by the backlog.
- Code example: a payment service client that wraps an HTTP call in a while-true loop with a 1-second sleep between attempts and no maximum attempt counter
- What RetryLint catches: rule RL-001 (retry loop with no maximum attempt limit), RL-003 (while-true pattern wrapping external service call)
- The fix: set a maximum retry count of 3-5 attempts. After that, fail fast and return an error to the caller. `for (let attempt = 0; attempt < 3; attempt++)` is the structural change.

#### 2. Fixed Delay Between Retries
- The pattern: `await sleep(1000)` as a constant delay between every retry attempt, regardless of attempt number
- Why it's dangerous: when a service goes down, every client starts retrying at the same interval. If 500 clients all retry every 1 second, the service receives 500 simultaneous requests every second the moment it restarts. This is the thundering herd problem — the coordinated retry storm prevents the recovering service from staying up. It oscillates between alive and overwhelmed.
- Code example: a retry wrapper function that accepts a callback and retries it with `await new Promise(r => setTimeout(r, 1000))` between each attempt
- What RetryLint catches: rule BO-001 (fixed/constant delay between retry attempts), BO-003 (retry delay that does not increase with attempt number)
- The fix: exponential backoff with jitter. Delay = base * 2^attempt + random(0, base). This spreads retries over time so recovering services aren't hit with a coordinated spike. `const delay = Math.min(1000 * Math.pow(2, attempt) + Math.random() * 1000, 30000)`.

#### 3. Missing Circuit Breaker
- The pattern: external API calls wrapped in retry logic but with no circuit breaker to stop retrying when the service is clearly down
- Why it's dangerous: if a downstream service is down for 10 minutes, every inbound request generates retries for 10 minutes. Connection pools exhaust. Thread pools saturate. Memory climbs as pending requests stack up. Your service — which has nothing wrong with it — crashes because it's holding open thousands of connections to a dead endpoint. One bad dependency takes down everything.
- Code example: a microservice that calls three downstream APIs with retry logic but no circuit breaker — when one API goes down, the entire service becomes unresponsive
- What RetryLint catches: rule CB-001 (external service call with retry but no circuit breaker), CB-004 (multiple downstream dependencies without independent circuit breakers)
- The fix: implement a circuit breaker with three states: closed (normal), open (stop calling for 30s after 5 consecutive failures), half-open (try one probe request to test recovery). Libraries like opossum (Node.js) or resilience4j (Java) implement this pattern.

#### 4. No Timeout on HTTP Calls
- The pattern: `fetch(url)` or `axios.get(url)` with no explicit timeout configured — relying on the system's default TCP timeout, which is typically 2-5 minutes
- Why it's dangerous: a service that responds slowly is worse than a service that's down. A down service fails immediately. A slow service ties up your connection, your thread, your memory — for minutes. If your connection pool has 10 slots and 10 requests are each waiting 2 minutes for a slow response, your service is effectively dead for 2 minutes with no errors in the logs.
- Code example: an API client that calls `await axios.get('https://api.partner.com/data')` with no timeout option — the call hangs for 120 seconds when the partner API is slow
- What RetryLint catches: rule TO-001 (HTTP call without explicit timeout), TO-003 (timeout value exceeding reasonable SLA threshold)
- The fix: set explicit timeouts based on your SLA. If your endpoint must respond in 2 seconds, set downstream timeouts to 1 second. `axios.get(url, { timeout: 5000 })` or `fetch(url, { signal: AbortSignal.timeout(5000) })`. Always shorter than your own SLA.

#### 5. Retrying Non-Idempotent Operations
- The pattern: retry logic wrapping POST requests that create resources, trigger payments, send emails, or modify state — operations that are not safe to repeat
- Why it's dangerous: the first attempt succeeds but the response is lost (network timeout after server processes it). The retry sends the same request again. Now you have duplicate orders, double charges, duplicate email sends, or corrupted state. The retry logic "worked" — it just created a worse problem than the original failure.
- Code example: a checkout function that retries `POST /api/orders` up to 3 times with exponential backoff — a timeout on the first attempt's response leads to a duplicate order
- What RetryLint catches: rule RL-008 (retry logic wrapping non-idempotent HTTP method), RL-010 (POST/PUT request in retry block without idempotency key)
- The fix: add idempotency keys. Generate a unique key per operation and send it as a header. The server checks if it's already processed that key. Alternatively, only retry operations that are known to be safe: GET, HEAD, OPTIONS, and DELETE (if your DELETE is idempotent).

#### 6. No Fallback / Graceful Degradation
- The pattern: a function that calls an external service, retries on failure, and then throws if all retries fail — no fallback path, no cached data, no degraded mode
- Why it's dangerous: if the recommendations service is down, should the entire product page fail? If the analytics service is unreachable, should the checkout fail? Without fallback logic, every dependency becomes a hard dependency. Your availability is the product of all your dependencies' availability — five nines times five nines times three nines equals three nines.
- Code example: a product page handler that calls a recommendation engine API and returns a 500 to the user if the recommendation service is unavailable
- What RetryLint catches: rule FT-001 (external call with no fallback after retry exhaustion), FT-004 (function with single external dependency and no degraded response path)
- The fix: define what "degraded mode" looks like for every external dependency. Recommendations down? Show popular products. Analytics down? Queue the event locally. Payment processor slow? Show "processing" and confirm asynchronously. Every external call should have an answer to "what do we show if this fails?"

### Conclusion

Retry logic is not resilience. Retry logic without backoff, circuit breakers, timeouts, and fallbacks is a force multiplier for outages. It takes a single failure and amplifies it across your entire system.

RetryLint scans for all 6 of these patterns (and 84 more) in one command:

```bash
clawhub install retrylint
retrylint scan .
```

Free to scan. Pro ($19/mo) adds pre-commit hooks so dangerous retry patterns can't merge. Runs 100% locally — your service architecture never leaves your machine.

https://retrylint.pages.dev | https://github.com/suhteevah/retrylint

---

## Article 3: "Your HTTP Config Is Leaking Data — 6 Patterns Every API Has"

**Tags:** #webdev #security #api #http

### Intro Paragraph

HTTP is the protocol every developer uses daily and almost nobody configures correctly. You set up Express, add your routes, deploy. But you never added security headers. CORS is set to wildcard because it "worked in development." There's no connection pooling, so every request opens a new TCP connection. A 2024 analysis of 10,000 production APIs found that 91% were missing at least one critical security header. Your HTTP isn't just misconfigured — it's an open invitation.

### Sections

#### 1. Missing Security Headers
- The pattern: API responses that contain none of the standard security headers — no Content-Security-Policy, no Strict-Transport-Security, no X-Frame-Options, no X-Content-Type-Options, no Permissions-Policy
- Why it's dangerous: without CSP, any injected script runs with full page permissions. Without HSTS, a user's first request can be intercepted over HTTP before the redirect to HTTPS. Without X-Content-Type-Options, browsers will MIME-sniff uploaded files and potentially execute them. Without X-Frame-Options, your application can be embedded in a malicious page for clickjacking. Each missing header is a distinct attack vector.
- Code example: an Express application with routes defined but no security header middleware — `curl -I` shows only the default Express headers
- What HTTPLint catches: rule HH-001 (missing Content-Security-Policy header), HH-002 (missing Strict-Transport-Security), HH-003 (missing X-Frame-Options), HH-004 (missing X-Content-Type-Options), HH-005 (missing Permissions-Policy)
- The fix: use the `helmet` middleware for Express (`app.use(helmet())`), which sets sensible defaults for all security headers. For other frameworks, configure each header explicitly. One line of middleware eliminates five vulnerability classes.

#### 2. CORS Wildcard (Access-Control-Allow-Origin: *)
- The pattern: `res.setHeader('Access-Control-Allow-Origin', '*')` or CORS middleware configured with `origin: '*'` on an API that handles authenticated requests
- Why it's dangerous: a wildcard origin allows any website to make authenticated requests to your API if combined with `Access-Control-Allow-Credentials: true`. An attacker's page can silently call your API and read the response, exfiltrating user data. Even without credentials, wildcard CORS on internal APIs exposes endpoint structure and response formats to reconnaissance.
- Code example: an Express API using `cors({ origin: '*' })` alongside cookie-based authentication — any website can read authenticated responses
- What HTTPLint catches: rule HH-001 (CORS wildcard on authenticated endpoint), HH-008 (wildcard origin combined with credentials header)
- The fix: replace the wildcard with an explicit origin whitelist. `cors({ origin: ['https://app.example.com', 'https://admin.example.com'] })`. Validate the Origin header against your list. Never reflect the request Origin header directly — that's equivalent to a wildcard.

#### 3. No Connection Pooling
- The pattern: `new HttpClient()` or `new https.Agent()` instantiated per request instead of shared across the application — each outbound request opens a new TCP connection
- Why it's dangerous: TCP connection setup requires a three-way handshake (1 round trip), plus TLS negotiation (1-2 more round trips). Without pooling, every outbound API call pays this 50-150ms overhead. Under load, you exhaust ephemeral ports (the OS only has ~16,000), and new connections fail with EADDRNOTAVAIL. Connection pool exhaustion is one of the most common causes of production outages in microservice architectures.
- Code example: an API handler that creates a new `https.Agent` per request, resulting in 1,000 concurrent TCP connections when handling 1,000 concurrent requests to the same downstream service
- What HTTPLint catches: rule CM-001 (HTTP agent/client instantiated inside request handler), CM-003 (no keep-alive configured on HTTP agent)
- The fix: create a shared HTTP agent at module level with keep-alive enabled. `const agent = new https.Agent({ keepAlive: true, maxSockets: 50 })` and reuse it for all requests to the same host. Connection reuse eliminates the handshake overhead and caps resource consumption.

#### 4. Missing Error Handling on fetch()
- The pattern: `const data = await fetch(url).then(r => r.json())` with no check on `response.ok`, no try/catch for network errors, no handling of non-200 status codes
- Why it's dangerous: `fetch()` does not throw on 4xx or 5xx responses — it only throws on network errors. A 500 response is a successful fetch. Without checking `response.ok`, you pass the error body to `r.json()`, which may fail with a cryptic JSON parse error or — worse — succeed and your code processes the error body as if it were valid data. Silent data corruption from unhandled HTTP errors is extremely common.
- Code example: a data fetching function that calls `fetch()` and directly destructures the JSON response without checking the status code — a 404 returns `undefined` values that silently propagate
- What HTTPLint catches: rule HC-001 (fetch() call without response.ok check), HC-003 (fetch() without try/catch for network errors), HC-005 (response body consumed without status validation)
- The fix: always check `if (!response.ok) throw new Error(response.status + ' ' + response.statusText)` before consuming the body. Wrap the entire call in try/catch for network errors. Log the URL, method, status code, and duration for every failed request.

#### 5. No Cache-Control Headers
- The pattern: dynamic API responses served with no Cache-Control, Expires, or ETag headers — the browser and CDN have no caching instructions and fall back to heuristic caching
- Why it's dangerous: without explicit caching headers, intermediaries (CDNs, proxies, browsers) make their own caching decisions. A CDN might cache your dynamic API response for hours. A browser might serve stale data from disk cache. Heuristic caching is unpredictable and varies across clients. Users see stale data, and debugging "sometimes the data is wrong" issues is expensive.
- Code example: an Express API that returns user profile data with no Cache-Control header — the CDN caches it for 5 minutes, and users see stale profiles after updating
- What HTTPLint catches: rule CC-001 (API response with no Cache-Control header), CC-003 (dynamic endpoint without explicit no-cache directive), CC-006 (private user data served without Cache-Control: private)
- The fix: set appropriate Cache-Control per endpoint type. User-specific data: `Cache-Control: private, no-cache`. Static reference data: `Cache-Control: public, max-age=3600`. Mutable resources: `Cache-Control: no-cache` with ETag for conditional requests. Every endpoint should declare its caching intent.

#### 6. Swallowed HTTP Errors
- The pattern: `try { await callApi() } catch (e) { }` — an empty catch block on an HTTP call, or `catch (e) { return [] }` that returns a default value with no logging
- Why it's dangerous: the request failed, but nobody knows. The function returns an empty array, the UI renders an empty state, the user assumes there's no data. There is no log entry, no alert, no metric. These silent failures accumulate — ten swallowed errors per minute means 14,400 invisible failures per day. When someone finally notices the data looks wrong, there's no trail to follow.
- Code example: a dashboard data loader that wraps three API calls in try/catch blocks that each return empty arrays on failure — the dashboard renders with empty panels and no error indication
- What HTTPLint catches: rule EM-001 (empty catch block on HTTP call), EM-003 (catch block returning default value without logging), EM-005 (HTTP error caught without status code or URL in log output)
- The fix: every catch block on an HTTP call must log the error with: the URL called, the HTTP method, the status code (if available), the error message, and the duration. If you return a default value, log at warning level. If the failure is critical, re-throw. `catch (e) { logger.warn({ url, method, status: e.status, duration, error: e.message }); return []; }`.

### Conclusion

HTTP configuration is the attack surface you forgot about. Every missing header, every swallowed error, every uncontrolled CORS policy is a door left open.

HTTPLint scans for all 6 of these patterns (and 84 more) in one command:

```bash
clawhub install httplint
httplint scan .
```

Free to scan. Pro ($19/mo) adds pre-commit hooks so misconfigured HTTP can't merge. Runs 100% locally — your API configuration stays on your machine.

https://httplint.pages.dev | https://github.com/suhteevah/httplint

---

## Article 4: "Your Dates Are Wrong — 6 Patterns That Silently Corrupt Data"

**Tags:** #programming #bugs #javascript #backend

### Intro Paragraph

Date and time handling is the source of more silent data corruption than any other programming domain. Not because it's conceptually hard — but because it seems simple and isn't. You write `new Date()` and it works in your timezone. You subtract 365 days and it's "close enough." You store dates as strings and they sort correctly in your locale. Then daylight saving time changes, a user in Tokyo books a meeting, a leap year breaks your billing cycle, and a 32-bit timestamp overflows in 2038. Date bugs don't throw errors. They silently produce wrong results that look right.

### Sections

#### 1. Timezone-Naive Date Creation
- The pattern: `new Date()` or `new Date('2024-03-15')` without specifying a timezone — the resulting date depends on the machine's local timezone, which varies between your laptop, your CI server, and your production containers
- Why it's dangerous: `new Date('2024-03-15')` returns midnight UTC, but `new Date('2024-03-15 00:00:00')` returns midnight local time. The same constructor, nearly the same input, different results. A server in UTC creates a date that's March 15. The same code on a server in US Pacific creates a date that's March 14 at 5 PM UTC. Scheduled jobs fire at the wrong time. Events appear on the wrong day. Billing cycles shift by a day.
- Code example: a scheduling function that creates `new Date(dateString)` from user input without timezone specification — the scheduled time differs depending on which server processes the request
- What DateGuard catches: rule TZ-001 (Date constructor without explicit timezone), TZ-003 (date parsed from user input without timezone normalization)
- The fix: always store and compare dates in UTC. Parse user input with an explicit timezone: `new Date(dateString + 'T00:00:00Z')` for UTC, or use a library like `luxon` that makes timezone handling explicit. Display in local time at the presentation layer only.

#### 2. Hardcoded Days-in-Month/Year
- The pattern: `if (month === 2) days = 28` or `const oneYear = 365 * 24 * 60 * 60 * 1000` — assuming fixed values for calendar durations that are not fixed
- Why it's dangerous: February has 29 days every 4 years (except centuries, except quad-centuries). A year is 365 days — except when it's 366. If your billing cycle calculates "one month from now" by adding 30 days, a January 31 subscription renewal lands on March 2 instead of February 28. If your token expiry calculates "one year" as 365 days, it's off by a day every 4 years. These errors accumulate.
- Code example: a subscription renewal function that calculates the next billing date with `new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000)` instead of incrementing the month
- What DateGuard catches: rule DA-001 (hardcoded 28/30/31 days in month calculation), DA-002 (hardcoded 365 days in year calculation), DA-005 (duration arithmetic using fixed millisecond constants)
- The fix: use date library methods that handle calendar arithmetic correctly. `date.setMonth(date.getMonth() + 1)` handles month-length differences. `date.setFullYear(date.getFullYear() + 1)` handles leap years. Never multiply days by milliseconds to calculate calendar durations.

#### 3. 32-bit Unix Timestamp (Y2038)
- The pattern: `parseInt(Date.now() / 1000)` stored in a 32-bit integer column, or Unix timestamps used in systems that will run past January 19, 2038
- Why it's dangerous: a signed 32-bit integer can represent timestamps up to January 19, 2038, 03:14:07 UTC. After that, it overflows to a negative number — which most systems interpret as a date in December 1901. If your database stores timestamps in a 32-bit INT column, every date after 2038 wraps to 1901. This is not a theoretical problem — systems being built today will be in production in 2038.
- Code example: a database schema using `INT` for a created_at column that stores `Math.floor(Date.now() / 1000)` — any date after 2038 wraps to 1901
- What DateGuard catches: rule EP-003 (Unix timestamp stored in 32-bit integer type), EP-005 (timestamp arithmetic that will overflow before 2050)
- The fix: use 64-bit integers (BIGINT) for Unix timestamps, or store dates as ISO 8601 strings. Better yet, use your database's native TIMESTAMP or DATETIME type, which handles this correctly. If you're designing a schema today, there is no reason to use a 32-bit integer for time.

#### 4. String Comparison of Dates
- The pattern: `if (dateA > dateB)` where both `dateA` and `dateB` are strings like `"2024-03-15"` or `"03/15/2024"` — relying on lexicographic string comparison for date ordering
- Why it's dangerous: string comparison works for ISO 8601 format (`"2024-03-15" > "2024-03-14"` is true) but fails for every other format. `"3/15/2024" > "12/1/2024"` is true because "3" > "1" lexicographically — even though December comes after March. Even ISO 8601 breaks when timezone offsets differ: `"2024-03-15T23:00:00+00:00"` compared to `"2024-03-16T01:00:00+02:00"` are the same instant but compare as different.
- Code example: a sorting function that sorts event dates with `events.sort((a, b) => a.date > b.date ? 1 : -1)` where dates are stored as `"MM/DD/YYYY"` strings — December sorts before March
- What DateGuard catches: rule CP-001 (string comparison operators used on date-formatted values), CP-004 (array sort on date strings without parse)
- The fix: always parse dates to Date objects or epoch milliseconds before comparing. `events.sort((a, b) => new Date(a.date) - new Date(b.date))`. If you store dates as strings, use ISO 8601 format exclusively — it's the only format where lexicographic order matches chronological order.

#### 5. Ambiguous Date Formats
- The pattern: `"01/02/2024"` — is this January 2 (US format MM/DD/YYYY) or February 1 (European format DD/MM/YYYY)? The answer depends on the locale of whoever reads it.
- Why it's dangerous: dates between the 1st and 12th of any month are ambiguous in slash-delimited formats. `"03/04/2024"` is March 4 in the US and April 3 in Europe. If your API accepts dates in this format and your users are international, some dates will be silently misinterpreted. No error is thrown — the date is valid in both interpretations. You won't know it's wrong until a user in London reports that their March 4 appointment shows up on April 3.
- Code example: an API endpoint that accepts `date` as a query parameter and parses it with `new Date(req.query.date)` — the parse result depends on the server's locale and the V8 engine's heuristics
- What DateGuard catches: rule NF-001 (ambiguous date format in user-facing input), NF-003 (date parsed from slash-delimited string without explicit format specifier)
- The fix: use ISO 8601 (`"2024-03-15"`) for all date interchange. It's unambiguous, internationally standardized, and sorts correctly as a string. If you must accept localized formats in a UI, parse with an explicit format specifier: `DateTime.fromFormat(input, 'dd/MM/yyyy')`. Never rely on implicit parsing.

#### 6. Dates Stored as Locale Strings
- The pattern: `db.insert({ created_at: new Date().toString() })` or `new Date().toLocaleString()` stored in a database column — the string format varies by runtime, OS locale, and Node.js version
- Why it's dangerous: `new Date().toString()` produces output like `"Sat Mar 15 2024 14:30:00 GMT-0700 (Pacific Daylight Time)"`. This format is not standardized. It changes with locale settings, OS updates, and runtime versions. Parsing it back to a Date is unreliable. Sorting it as a string produces nonsensical order. Querying a date range on a column of locale strings requires parsing every row. Your database loses the ability to index, sort, or query by time.
- Code example: a logging system that stores timestamps with `new Date().toLocaleString('en-US')` — the format produces `"3/15/2024, 2:30:00 PM"` which cannot be reliably parsed back or sorted
- What DateGuard catches: rule ST-001 (Date.toString() or toLocaleString() used for storage), ST-003 (non-ISO date string written to database), ST-006 (date column using VARCHAR/TEXT type instead of native date type)
- The fix: store dates as ISO 8601 strings (`new Date().toISOString()` produces `"2024-03-15T21:30:00.000Z"`) or as Unix epoch milliseconds (`Date.now()`). Use your database's native TIMESTAMP/DATETIME type whenever possible. Convert to locale strings only at the presentation layer, never for storage or interchange.

### Conclusion

Date bugs are insidious because the code runs, the dates look plausible, and the errors only surface when a timezone changes, a leap year arrives, or a user in a different locale reports that "the date is wrong." By then, you may have months of silently corrupted data.

DateGuard scans for all 6 of these patterns (and 84 more) in one command:

```bash
clawhub install dateguard
dateguard scan .
```

Free to scan. Pro ($19/mo) adds pre-commit hooks so date anti-patterns can't merge. Runs 100% locally — your codebase never leaves your machine.

https://dateguard.pages.dev | https://github.com/suhteevah/dateguard
