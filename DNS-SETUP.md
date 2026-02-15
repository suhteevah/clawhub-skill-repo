# DNS Setup — chicocellrepair.com → GitHub Pages

## Current Status
- Site is LIVE at: https://suhteevah.github.io/chicocellrepair/
- GitHub Pages repo: github.com/suhteevah/chicocellrepair
- Custom domain configured in GitHub Pages: chicocellrepair.com (pending DNS)

## What You Need to Do in Squarespace DNS

Go to: https://account.squarespace.com/domains/managed/chicocellrepair.com/dns/dns-settings

Squarespace requires Google re-authentication (Login with Google as sativa@chicocellrepair.com) to modify DNS records. Click CONTINUE when the verification dialog appears, log in with Google, then:

### Step 1: Delete Squarespace Defaults
Click the red trash icon next to "Squarespace Defaults" to remove these records:
- 4 A records (198.185.159.145, 198.49.23.145, 198.49.23.144, 198.185.159.144)
- www CNAME (ext-sq.squarespace.com)
- HTTPS record

### Step 2: Add GitHub Pages A Records (Custom Records section)
Click "ADD RECORD" for each:

| Type | Host | Data               |
|------|------|--------------------|
| A    | @    | 185.199.108.153    |
| A    | @    | 185.199.109.153    |
| A    | @    | 185.199.110.153    |
| A    | @    | 185.199.111.153    |

### Step 3: Add www CNAME (Custom Records section)

| Type  | Host | Data                     |
|-------|------|--------------------------|
| CNAME | www  | suhteevah.github.io     |

### Step 4: Keep These Records (DO NOT DELETE)
- Google Workspace MX records (for email)
- google._domainkey TXT record (DKIM for email)

## After DNS Propagation (15 min - 48 hrs)

1. Re-add custom domain in GitHub Pages:
   ```bash
   gh api repos/suhteevah/chicocellrepair/pages -X PUT \
     -f "cname=chicocellrepair.com" \
     -f "build_type=legacy" \
     -f "source[branch]=main" \
     -f "source[path]=/"
   ```

2. Add CNAME file to repo:
   ```bash
   cd "J:/clawhub skill repo/sites/chicocellrepair.com"
   echo "chicocellrepair.com" > CNAME
   git add CNAME && git commit -m "Add CNAME for custom domain" && git push
   ```

3. Enable HTTPS enforcement:
   ```bash
   gh api repos/suhteevah/chicocellrepair/pages -X PUT \
     -f "https_enforced=true" \
     -f "build_type=legacy" \
     -f "source[branch]=main" \
     -f "source[path]=/"
   ```

4. Update Stripe business website URL to: https://chicocellrepair.com

## Verify DNS
```bash
# Check A records
dig chicocellrepair.com A +short
# Should show: 185.199.108.153, 185.199.109.153, 185.199.110.153, 185.199.111.153

# Check CNAME
dig www.chicocellrepair.com CNAME +short
# Should show: suhteevah.github.io
```
