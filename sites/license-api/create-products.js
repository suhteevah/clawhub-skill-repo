/**
 * One-shot product creator — deploy temporarily, hit the endpoint, then remove.
 * This worker uses the STRIPE_SECRET_KEY already stored in worker secrets
 * to create DeadCode and TestGap products + prices in Stripe LIVE mode.
 *
 * Deploy: cd sites/license-api && npx wrangler deploy -c create-products-wrangler.toml
 * Call:   curl -X POST https://product-creator.clawhub-api.workers.dev/create
 * Remove: npx wrangler delete --name product-creator
 */

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

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    if (request.method !== 'POST' || url.pathname !== '/create') {
      return new Response(JSON.stringify({ error: 'POST /create only' }), { status: 404 });
    }

    const key = env.STRIPE_SECRET_KEY;
    if (!key) {
      return new Response(JSON.stringify({ error: 'STRIPE_SECRET_KEY not set', envKeys: Object.keys(env) }), { status: 500 });
    }

    try {
    const results = { keyPrefix: key.substring(0, 10) + '...' };

    // DeadCode Pro
    const dcPro = await stripeRequest('/products', {
      'name': 'DeadCode Pro',
      'description': 'Dead code & unused export detector — Pro tier ($19/mo). Unlimited files, pre-commit hooks, reports, orphan detection. 60+ patterns across JS/TS, Python, Go, CSS. 100% local.',
      'metadata[skill]': 'deadcode',
      'metadata[tier]': 'pro',
    }, env.STRIPE_SECRET_KEY);
    results.deadcode_pro_product = dcPro.id;

    const dcProPrice = await stripeRequest('/prices', {
      'product': dcPro.id,
      'unit_amount': '1900',
      'currency': 'usd',
      'recurring[interval]': 'month',
    }, env.STRIPE_SECRET_KEY);
    results.deadcode_pro_price = dcProPrice.id;

    // DeadCode Team
    const dcTeam = await stripeRequest('/products', {
      'name': 'DeadCode Team',
      'description': 'Dead code & unused export detector — Team tier ($39/mo). Cross-repo analysis, custom ignore rules, SARIF output, CI integration. Everything in Pro plus team features.',
      'metadata[skill]': 'deadcode',
      'metadata[tier]': 'team',
    }, env.STRIPE_SECRET_KEY);
    results.deadcode_team_product = dcTeam.id;

    const dcTeamPrice = await stripeRequest('/prices', {
      'product': dcTeam.id,
      'unit_amount': '3900',
      'currency': 'usd',
      'recurring[interval]': 'month',
    }, env.STRIPE_SECRET_KEY);
    results.deadcode_team_price = dcTeamPrice.id;

    // TestGap Pro
    const tgPro = await stripeRequest('/products', {
      'name': 'TestGap Pro',
      'description': 'Test coverage gap analyzer — Pro tier ($19/mo). Unlimited files, pre-commit hooks, test quality analysis, reports. Maps source to test files. 60+ patterns. 100% local.',
      'metadata[skill]': 'testgap',
      'metadata[tier]': 'pro',
    }, env.STRIPE_SECRET_KEY);
    results.testgap_pro_product = tgPro.id;

    const tgProPrice = await stripeRequest('/prices', {
      'product': tgPro.id,
      'unit_amount': '1900',
      'currency': 'usd',
      'recurring[interval]': 'month',
    }, env.STRIPE_SECRET_KEY);
    results.testgap_pro_price = tgProPrice.id;

    // TestGap Team
    const tgTeam = await stripeRequest('/products', {
      'name': 'TestGap Team',
      'description': 'Test coverage gap analyzer — Team tier ($39/mo). Critical gap detection, cross-module analysis, SARIF output, CI integration. Everything in Pro plus team features.',
      'metadata[skill]': 'testgap',
      'metadata[tier]': 'team',
    }, env.STRIPE_SECRET_KEY);
    results.testgap_team_product = tgTeam.id;

    const tgTeamPrice = await stripeRequest('/prices', {
      'product': tgTeam.id,
      'unit_amount': '3900',
      'currency': 'usd',
      'recurring[interval]': 'month',
    }, env.STRIPE_SECRET_KEY);
    results.testgap_team_price = tgTeamPrice.id;

    return new Response(JSON.stringify(results, null, 2), {
      headers: { 'Content-Type': 'application/json' },
    });
    } catch (e) {
      return new Response(JSON.stringify({ error: e.message, stack: e.stack }), {
        status: 500,
        headers: { 'Content-Type': 'application/json' },
      });
    }
  },
};
