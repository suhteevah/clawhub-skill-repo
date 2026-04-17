/**
 * License API — Cloudflare Worker
 *
 * Handles:
 * 1. POST /create-checkout  → Creates Stripe checkout session
 * 2. POST /webhook           → Stripe webhook → generates JWT license key → emails to customer
 * 3. GET  /verify            → Verify a license key (optional, for debugging)
 * 4. GET  /health            → Health check
 *
 * Environment variables (set via wrangler secret):
 *   STRIPE_SECRET_KEY, STRIPE_WEBHOOK_SECRET, JWT_SECRET
 *   DOCSYNC_PRO_PRICE, DOCSYNC_TEAM_PRICE
 *   DEPGUARD_PRO_PRICE, DEPGUARD_TEAM_PRICE
 *   ENVGUARD_PRO_PRICE, ENVGUARD_TEAM_PRICE
 *   GITPULSE_PRO_PRICE, GITPULSE_TEAM_PRICE
 *   MIGRATESAFE_PRO_PRICE, MIGRATESAFE_TEAM_PRICE
 *   APISHIELD_PRO_PRICE, APISHIELD_TEAM_PRICE
 *   TYPEDRIFT_PRO_PRICE, TYPEDRIFT_TEAM_PRICE
 *   CONFIGSAFE_PRO_PRICE, CONFIGSAFE_TEAM_PRICE
 *   PERFGUARD_PRO_PRICE, PERFGUARD_TEAM_PRICE
 *   LICENSEGUARD_PRO_PRICE, LICENSEGUARD_TEAM_PRICE
 *   DEADCODE_PRO_PRICE, DEADCODE_TEAM_PRICE
 *   TESTGAP_PRO_PRICE, TESTGAP_TEAM_PRICE
 *   BUNDLEPHOBIA_PRO_PRICE, BUNDLEPHOBIA_TEAM_PRICE
 *   SQLGUARD_PRO_PRICE, SQLGUARD_TEAM_PRICE
 *   SECRETSCAN_PRO_PRICE, SECRETSCAN_TEAM_PRICE
 *   ACCESSLINT_PRO_PRICE, ACCESSLINT_TEAM_PRICE
 *   STYLEGUARD_PRO_PRICE, STYLEGUARD_TEAM_PRICE
 *   DOCCOVERAGE_PRO_PRICE, DOCCOVERAGE_TEAM_PRICE
 *   ERRORLENS_PRO_PRICE, ERRORLENS_TEAM_PRICE
 *   MEMGUARD_PRO_PRICE, MEMGUARD_TEAM_PRICE
 *   I18NCHECK_PRO_PRICE, I18NCHECK_TEAM_PRICE
 *   CONCURRENCYGUARD_PRO_PRICE, CONCURRENCYGUARD_TEAM_PRICE
 *   LOGSENTRY_PRO_PRICE, LOGSENTRY_TEAM_PRICE
 *   INPUTSHIELD_PRO_PRICE, INPUTSHIELD_TEAM_PRICE
 *   AUTHAUDIT_PRO_PRICE, AUTHAUDIT_TEAM_PRICE
 *   CLOUDGUARD_PRO_PRICE, CLOUDGUARD_TEAM_PRICE
 */

// ─── CORS ────────────────────────────────────────────────────────────────────

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Stripe-Signature',
};

function corsResponse(body, status = 200, extraHeaders = {}) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      'Content-Type': 'application/json',
      ...CORS_HEADERS,
      ...extraHeaders,
    },
  });
}

// ─── JWT Generation ──────────────────────────────────────────────────────────

async function generateJWT(payload, secret) {
  const header = { alg: 'HS256', typ: 'JWT' };

  const encode = (obj) => {
    const json = JSON.stringify(obj);
    const bytes = new TextEncoder().encode(json);
    return btoa(String.fromCharCode(...bytes))
      .replace(/\+/g, '-')
      .replace(/\//g, '_')
      .replace(/=+$/, '');
  };

  const headerB64 = encode(header);
  const payloadB64 = encode(payload);
  const data = `${headerB64}.${payloadB64}`;

  // Sign with HMAC-SHA256
  const key = await crypto.subtle.importKey(
    'raw',
    new TextEncoder().encode(secret),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign']
  );

  const signature = await crypto.subtle.sign(
    'HMAC',
    key,
    new TextEncoder().encode(data)
  );

  const sigB64 = btoa(String.fromCharCode(...new Uint8Array(signature)))
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/, '');

  return `${data}.${sigB64}`;
}

async function verifyJWT(token, secret) {
  try {
    const [headerB64, payloadB64, sigB64] = token.split('.');
    const data = `${headerB64}.${payloadB64}`;

    const key = await crypto.subtle.importKey(
      'raw',
      new TextEncoder().encode(secret),
      { name: 'HMAC', hash: 'SHA-256' },
      false,
      ['verify']
    );

    // Decode signature
    const sigStr = sigB64.replace(/-/g, '+').replace(/_/g, '/');
    const padded = sigStr + '='.repeat((4 - sigStr.length % 4) % 4);
    const sigBytes = Uint8Array.from(atob(padded), c => c.charCodeAt(0));

    const valid = await crypto.subtle.verify(
      'HMAC',
      key,
      sigBytes,
      new TextEncoder().encode(data)
    );

    if (!valid) return null;

    // Decode payload
    const payloadStr = payloadB64.replace(/-/g, '+').replace(/_/g, '/');
    const payloadPadded = payloadStr + '='.repeat((4 - payloadStr.length % 4) % 4);
    const payloadJSON = atob(payloadPadded);
    return JSON.parse(payloadJSON);
  } catch (e) {
    return null;
  }
}

// ─── Stripe helpers ──────────────────────────────────────────────────────────

async function stripeRequest(path, body, secretKey) {
  const res = await fetch(`https://api.stripe.com/v1${path}`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${secretKey}`,
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: new URLSearchParams(body).toString(),
  });
  return res.json();
}

async function verifyStripeWebhook(request, secret) {
  const body = await request.text();
  const sig = request.headers.get('Stripe-Signature');

  if (!sig) return { valid: false };

  // Parse signature header
  const parts = {};
  sig.split(',').forEach(part => {
    const [key, val] = part.split('=');
    parts[key.trim()] = val;
  });

  const timestamp = parts.t;
  const expectedSig = parts.v1;

  // Verify timestamp (within 5 minutes)
  const now = Math.floor(Date.now() / 1000);
  if (Math.abs(now - parseInt(timestamp)) > 300) {
    return { valid: false };
  }

  // Compute expected signature
  const payload = `${timestamp}.${body}`;
  const key = await crypto.subtle.importKey(
    'raw',
    new TextEncoder().encode(secret),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign']
  );

  const sigBytes = await crypto.subtle.sign(
    'HMAC',
    key,
    new TextEncoder().encode(payload)
  );

  const computedSig = Array.from(new Uint8Array(sigBytes))
    .map(b => b.toString(16).padStart(2, '0'))
    .join('');

  if (computedSig !== expectedSig) {
    return { valid: false };
  }

  return { valid: true, event: JSON.parse(body) };
}

// ─── Route: Create Checkout ──────────────────────────────────────────────────

async function handleCreateCheckout(request, env) {
  const { plan, product, seats = 1 } = await request.json();

  // Map product + plan to Stripe price ID
  const priceMap = {
    'docsync:pro': env.DOCSYNC_PRO_PRICE,
    'docsync:team': env.DOCSYNC_TEAM_PRICE,
    'depguard:pro': env.DEPGUARD_PRO_PRICE,
    'depguard:team': env.DEPGUARD_TEAM_PRICE,
    'envguard:pro': env.ENVGUARD_PRO_PRICE,
    'envguard:team': env.ENVGUARD_TEAM_PRICE,
    'gitpulse:pro': env.GITPULSE_PRO_PRICE,
    'gitpulse:team': env.GITPULSE_TEAM_PRICE,
    'migratesafe:pro': env.MIGRATESAFE_PRO_PRICE,
    'migratesafe:team': env.MIGRATESAFE_TEAM_PRICE,
    'apishield:pro': env.APISHIELD_PRO_PRICE,
    'apishield:team': env.APISHIELD_TEAM_PRICE,
    'typedrift:pro': env.TYPEDRIFT_PRO_PRICE,
    'typedrift:team': env.TYPEDRIFT_TEAM_PRICE,
    'configsafe:pro': env.CONFIGSAFE_PRO_PRICE,
    'configsafe:team': env.CONFIGSAFE_TEAM_PRICE,
    'perfguard:pro': env.PERFGUARD_PRO_PRICE,
    'perfguard:team': env.PERFGUARD_TEAM_PRICE,
    'licenseguard:pro': env.LICENSEGUARD_PRO_PRICE,
    'licenseguard:team': env.LICENSEGUARD_TEAM_PRICE,
    'deadcode:pro': env.DEADCODE_PRO_PRICE,
    'deadcode:team': env.DEADCODE_TEAM_PRICE,
    'testgap:pro': env.TESTGAP_PRO_PRICE,
    'testgap:team': env.TESTGAP_TEAM_PRICE,
    'bundlephobia:pro': env.BUNDLEPHOBIA_PRO_PRICE,
    'bundlephobia:team': env.BUNDLEPHOBIA_TEAM_PRICE,
    'sqlguard:pro': env.SQLGUARD_PRO_PRICE,
    'sqlguard:team': env.SQLGUARD_TEAM_PRICE,
    'secretscan:pro': env.SECRETSCAN_PRO_PRICE,
    'secretscan:team': env.SECRETSCAN_TEAM_PRICE,
    'accesslint:pro': env.ACCESSLINT_PRO_PRICE,
    'accesslint:team': env.ACCESSLINT_TEAM_PRICE,
    'styleguard:pro': env.STYLEGUARD_PRO_PRICE,
    'styleguard:team': env.STYLEGUARD_TEAM_PRICE,
    'doccoverage:pro': env.DOCCOVERAGE_PRO_PRICE,
    'doccoverage:team': env.DOCCOVERAGE_TEAM_PRICE,
    'errorlens:pro': env.ERRORLENS_PRO_PRICE, 'errorlens:team': env.ERRORLENS_TEAM_PRICE,
    'memguard:pro': env.MEMGUARD_PRO_PRICE, 'memguard:team': env.MEMGUARD_TEAM_PRICE,
    'i18ncheck:pro': env.I18NCHECK_PRO_PRICE, 'i18ncheck:team': env.I18NCHECK_TEAM_PRICE,
    'concurrencyguard:pro': env.CONCURRENCYGUARD_PRO_PRICE, 'concurrencyguard:team': env.CONCURRENCYGUARD_TEAM_PRICE,
    'logsentry:pro': env.LOGSENTRY_PRO_PRICE, 'logsentry:team': env.LOGSENTRY_TEAM_PRICE,
    'inputshield:pro': env.INPUTSHIELD_PRO_PRICE, 'inputshield:team': env.INPUTSHIELD_TEAM_PRICE,
    'authaudit:pro': env.AUTHAUDIT_PRO_PRICE, 'authaudit:team': env.AUTHAUDIT_TEAM_PRICE,
    'cloudguard:pro': env.CLOUDGUARD_PRO_PRICE, 'cloudguard:team': env.CLOUDGUARD_TEAM_PRICE,
  };

  const priceId = priceMap[`${product}:${plan}`];
  if (!priceId) {
    return corsResponse({ error: 'Invalid product/plan' }, 400);
  }

  // Determine success URL based on product
  const successUrls = {
    docsync: 'https://docsync-1q4.pages.dev/success?session_id={CHECKOUT_SESSION_ID}',
    depguard: 'https://depguard.pages.dev/success?session_id={CHECKOUT_SESSION_ID}',
    envguard: 'https://envguard.pages.dev/success?session_id={CHECKOUT_SESSION_ID}',
    gitpulse: 'https://gitpulse.pages.dev/success?session_id={CHECKOUT_SESSION_ID}',
    migratesafe: 'https://migratesafe.pages.dev/success?session_id={CHECKOUT_SESSION_ID}',
    apishield: 'https://apishield.pages.dev/success?session_id={CHECKOUT_SESSION_ID}',
    typedrift: 'https://typedrift.pages.dev/success?session_id={CHECKOUT_SESSION_ID}',
    configsafe: 'https://configsafe.pages.dev/success?session_id={CHECKOUT_SESSION_ID}',
    perfguard: 'https://perfguard.pages.dev/success?session_id={CHECKOUT_SESSION_ID}',
    licenseguard: 'https://licenseguard.pages.dev/success?session_id={CHECKOUT_SESSION_ID}',
    deadcode: 'https://deadcode-9rs.pages.dev/success?session_id={CHECKOUT_SESSION_ID}',
    testgap: 'https://testgap.pages.dev/success?session_id={CHECKOUT_SESSION_ID}',
    bundlephobia: 'https://bundlephobia.pages.dev/success?session_id={CHECKOUT_SESSION_ID}',
    sqlguard: 'https://sqlguard.pages.dev/success?session_id={CHECKOUT_SESSION_ID}',
    secretscan: 'https://secretscan.pages.dev/success?session_id={CHECKOUT_SESSION_ID}',
    accesslint: 'https://accesslint-8zy.pages.dev/success?session_id={CHECKOUT_SESSION_ID}',
    styleguard: 'https://styleguard.pages.dev/success?session_id={CHECKOUT_SESSION_ID}',
    doccoverage: 'https://doccoverage.pages.dev/success?session_id={CHECKOUT_SESSION_ID}',
    errorlens: 'https://errorlens-d88.pages.dev/success?session_id={CHECKOUT_SESSION_ID}',
    memguard: 'https://memguard.pages.dev/success?session_id={CHECKOUT_SESSION_ID}',
    i18ncheck: 'https://i18ncheck.pages.dev/success?session_id={CHECKOUT_SESSION_ID}',
    concurrencyguard: 'https://concurrencyguard.pages.dev/success?session_id={CHECKOUT_SESSION_ID}',
    logsentry: 'https://logsentry.pages.dev/success?session_id={CHECKOUT_SESSION_ID}',
    inputshield: 'https://inputshield.pages.dev/success?session_id={CHECKOUT_SESSION_ID}',
    authaudit: 'https://authaudit.pages.dev/success?session_id={CHECKOUT_SESSION_ID}',
    cloudguard: 'https://cloudguard.pages.dev/success?session_id={CHECKOUT_SESSION_ID}',
  };

  const cancelUrls = {
    docsync: 'https://docsync-1q4.pages.dev/#pricing',
    depguard: 'https://depguard.pages.dev/#pricing',
    envguard: 'https://envguard.pages.dev/#pricing',
    gitpulse: 'https://gitpulse.pages.dev/#pricing',
    migratesafe: 'https://migratesafe.pages.dev/#pricing',
    apishield: 'https://apishield.pages.dev/#pricing',
    typedrift: 'https://typedrift.pages.dev/#pricing',
    configsafe: 'https://configsafe.pages.dev/#pricing',
    perfguard: 'https://perfguard.pages.dev/#pricing',
    licenseguard: 'https://licenseguard.pages.dev/#pricing',
    deadcode: 'https://deadcode-9rs.pages.dev/#pricing',
    testgap: 'https://testgap.pages.dev/#pricing',
    bundlephobia: 'https://bundlephobia.pages.dev/#pricing',
    sqlguard: 'https://sqlguard.pages.dev/#pricing',
    secretscan: 'https://secretscan.pages.dev/#pricing',
    accesslint: 'https://accesslint-8zy.pages.dev/#pricing',
    styleguard: 'https://styleguard.pages.dev/#pricing',
    doccoverage: 'https://doccoverage.pages.dev/#pricing',
    errorlens: 'https://errorlens-d88.pages.dev/#pricing',
    memguard: 'https://memguard.pages.dev/#pricing',
    i18ncheck: 'https://i18ncheck.pages.dev/#pricing',
    concurrencyguard: 'https://concurrencyguard.pages.dev/#pricing',
    logsentry: 'https://logsentry.pages.dev/#pricing',
    inputshield: 'https://inputshield.pages.dev/#pricing',
    authaudit: 'https://authaudit.pages.dev/#pricing',
    cloudguard: 'https://cloudguard.pages.dev/#pricing',
  };

  const session = await stripeRequest('/checkout/sessions', {
    'mode': 'subscription',
    'line_items[0][price]': priceId,
    'line_items[0][quantity]': seats,
    'success_url': successUrls[product] || successUrls.docsync,
    'cancel_url': cancelUrls[product] || cancelUrls.docsync,
    'metadata[product]': product,
    'metadata[plan]': plan,
    'metadata[seats]': seats,
    'subscription_data[metadata][product]': product,
    'subscription_data[metadata][plan]': plan,
    'subscription_data[metadata][seats]': seats,
  }, env.STRIPE_SECRET_KEY);

  if (session.error) {
    return corsResponse({ error: session.error.message }, 500);
  }

  return corsResponse({ url: session.url, sessionId: session.id });
}

// ─── Route: Stripe Webhook ───────────────────────────────────────────────────

async function handleWebhook(request, env) {
  const { valid, event } = await verifyStripeWebhook(request, env.STRIPE_WEBHOOK_SECRET);

  if (!valid) {
    return corsResponse({ error: 'Invalid signature' }, 400);
  }

  // Handle checkout.session.completed
  if (event.type === 'checkout.session.completed') {
    const session = event.data.object;
    const email = session.customer_details?.email || session.customer_email;
    const product = session.metadata?.product;
    const plan = session.metadata?.plan;
    const seats = parseInt(session.metadata?.seats || '1');

    if (!email || !product || !plan) {
      return corsResponse({ error: 'Missing metadata' }, 400);
    }

    // Generate license key (JWT valid for 1 year)
    const now = Math.floor(Date.now() / 1000);
    const oneYear = 365 * 24 * 60 * 60;

    const licensePayload = {
      sub: email,
      product,
      tier: plan,
      seats,
      iat: now,
      exp: now + oneYear,
      iss: 'license-api',
    };

    const licenseKey = await generateJWT(licensePayload, env.JWT_SECRET);

    // Send license key via Stripe receipt (or you can integrate an email service)
    // For now, we'll store it and make it retrievable via the success page
    // In production, integrate with Resend, SendGrid, or similar

    console.log(`License generated for ${email}: ${product}/${plan} (${seats} seats)`);
    console.log(`Key: ${licenseKey}`);

    // You could also update the Stripe customer with the license key
    // Or use a KV store to map session_id → license_key for the success page

    return corsResponse({
      success: true,
      email,
      product,
      plan,
      // Don't expose the key in the webhook response for security
    });
  }

  // Handle subscription renewal
  if (event.type === 'invoice.payment_succeeded') {
    const invoice = event.data.object;
    const subscriptionId = invoice.subscription;

    // Subscription renewed — license key continues to work
    // JWT expiry will be checked; if approaching expiry, generate a new one
    console.log(`Subscription ${subscriptionId} renewed`);

    return corsResponse({ success: true });
  }

  // Handle cancellation
  if (event.type === 'customer.subscription.deleted') {
    const subscription = event.data.object;
    console.log(`Subscription ${subscription.id} cancelled`);
    // The JWT will naturally expire; no action needed for offline validation
    return corsResponse({ success: true });
  }

  return corsResponse({ received: true });
}

// ─── Route: Verify License ───────────────────────────────────────────────────

async function handleVerify(request, env) {
  const url = new URL(request.url);
  const token = url.searchParams.get('key');

  if (!token) {
    return corsResponse({ error: 'Missing key parameter' }, 400);
  }

  const payload = await verifyJWT(token, env.JWT_SECRET);

  if (!payload) {
    return corsResponse({ valid: false, error: 'Invalid or expired key' }, 401);
  }

  const now = Math.floor(Date.now() / 1000);
  if (payload.exp && now > payload.exp) {
    return corsResponse({ valid: false, error: 'Key expired', expiredAt: new Date(payload.exp * 1000).toISOString() }, 401);
  }

  return corsResponse({
    valid: true,
    product: payload.product,
    tier: payload.tier,
    seats: payload.seats,
    email: payload.sub,
    expires: new Date(payload.exp * 1000).toISOString(),
  });
}

// ─── Route: Email Subscribe ──────────────────────────────────────────────────

async function handleSubscribe(request, env) {
  const { email, product, source } = await request.json();

  if (!email || !email.includes('@')) {
    return corsResponse({ error: 'Invalid email' }, 400);
  }

  // Store in KV if available, otherwise just log
  // KV binding: SUBSCRIBERS (add to wrangler.toml when ready)
  const entry = {
    email,
    product: product || 'unknown',
    source: source || 'unknown',
    timestamp: new Date().toISOString(),
  };

  if (env.SUBSCRIBERS) {
    // KV: key = email, value = JSON entry
    await env.SUBSCRIBERS.put(email, JSON.stringify(entry));
  }

  // Always log for wrangler tail visibility
  console.log(`[SUBSCRIBE] ${email} | ${product} | ${source}`);

  return corsResponse({ success: true });
}

// ─── Route: List Subscribers (admin only) ────────────────────────────────────

async function handleListSubscribers(request, env) {
  // Simple auth: require admin secret in query param
  const url = new URL(request.url);
  const secret = url.searchParams.get('secret');

  if (!secret || secret !== env.ADMIN_SECRET) {
    return corsResponse({ error: 'Unauthorized' }, 401);
  }

  if (!env.SUBSCRIBERS) {
    return corsResponse({ error: 'KV not configured' }, 500);
  }

  const list = await env.SUBSCRIBERS.list({ limit: 1000 });
  const subscribers = [];

  for (const key of list.keys) {
    const value = await env.SUBSCRIBERS.get(key.name);
    if (value) {
      subscribers.push(JSON.parse(value));
    }
  }

  return corsResponse({ count: subscribers.length, subscribers });
}

// ─── Router ──────────────────────────────────────────────────────────────────

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    const method = request.method;

    // CORS preflight
    if (method === 'OPTIONS') {
      return new Response(null, { status: 204, headers: CORS_HEADERS });
    }

    try {
      // Routes
      if (method === 'POST' && url.pathname === '/create-checkout') {
        return handleCreateCheckout(request, env);
      }

      if (method === 'POST' && url.pathname === '/webhook') {
        return handleWebhook(request, env);
      }

      if (method === 'GET' && url.pathname === '/verify') {
        return handleVerify(request, env);
      }

      if (method === 'POST' && url.pathname === '/subscribe') {
        return handleSubscribe(request, env);
      }

      if (method === 'GET' && url.pathname === '/subscribers') {
        return handleListSubscribers(request, env);
      }

      if (method === 'GET' && url.pathname === '/health') {
        return corsResponse({ status: 'ok', timestamp: new Date().toISOString() });
      }


      // 404
      return corsResponse({ error: 'Not found' }, 404);

    } catch (e) {
      console.error('Error:', e);
      return corsResponse({ error: 'Internal server error' }, 500);
    }
  },
};
