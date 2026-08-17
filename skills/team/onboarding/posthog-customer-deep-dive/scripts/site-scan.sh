#!/usr/bin/env bash
# Headless scan of a customer's public web surfaces. Run this file, never read it to copy its greps.
#
#   scripts/site-scan.sh acme.com
#
# Answers two things no query and no enrichment tool can: where the customer runs PostHog
# (marketing site, app, both, or nowhere public) and which competing tools sit beside it.
# It reads static HTML plus the app shell's Content-Security-Policy, so it recovers the
# install, the token, the region and the tool list, and it cannot see live runtime state.
#
# How to read the output is in references/site-scan.md, including the two readings that are
# wrong every time: a 000 status means no HTTP response reached us (NXDOMAIN or a WAF), so dig before reading it,
# and a CSP allowlist entry is presence, never proof of daily use.
#
# Needs: curl, grep, python3 (for the remote config pretty-print). No pip packages.

set -uo pipefail

D="${1:-}"
if [ -z "$D" ]; then
  echo "usage: $(basename "$0") <domain>   e.g. $(basename "$0") acme.com" >&2
  exit 2
fi
D="${D#http://}"; D="${D#https://}"; D="${D%%/*}"; D="${D#www.}"

# A real browser UA, because a bare curl UA is what most WAFs bounce first.
UA="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
# 20s is past the point where a slow marketing page is still worth waiting for, and the
# scan fires twelve of these, so a longer ceiling makes a blocked host hold up the whole run.
MAXTIME=20

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

echo "--- surfaces (status 000 = no HTTP response: NXDOMAIN or a WAF; dig it before calling it blocked) ---"
for h in "" www. app. platform. console. api. account. portal. dashboard. login. my. shop. store. dev. docs.; do
  n=${h:-root}; n=${n%.}
  curl -s -o "$work/$n.html" -D "$work/$n.headers" \
    -w "$n.$D %{http_code} %{url_effective}\n" \
    -L -A "$UA" "https://${h}$D" --max-time "$MAXTIME" 2>/dev/null &
done
wait

echo
echo "--- PostHog install (case-folded, counts only) ---"
grep -rhoiE "posthog\.init\(|_POSTHOG_REMOTE_CONFIG|PostHogProvider|posthog" "$work" \
  | tr 'A-Z' 'a-z' | sort | uniq -c | sort -rn | head -10
echo "--- PostHog token / region (VERBATIM: a project token is case-sensitive) ---"
grep -rhoE "phc_[A-Za-z0-9]+|(us|eu)\.i\.posthog\.com|/array/phc_[A-Za-z0-9]+" "$work" \
  | sort | uniq -c | sort -rn | head -10

echo
echo "--- competing tools (host patterns + npm package names) ---"
grep -rhoiE "google-analytics|googletagmanager|gtag\(|adobedtm|adobe-analytics|plausible\.io|matomo|usefathom|cdn\.segment|rudderlabs|mparticle|mxpnl|mixpanel|cdn\.amplitude|amplitude|heapanalytics|june\.so|fullstory|static\.hotjar|hotjar|logrocket|mouseflow|luckyorange|clarity\.ms|qualtrics|surveymonkey|typeform|sprig\.com|uservoice|canny\.io|sentry|datadoghq|newrelic|bugsnag|rollbar|grafana|loki|splunk|betterstack|launchdarkly|cdn\.optimizely|split\.io|splitsoftware|visualwebsiteoptimizer|vwo\.com|webtrends|growthbook|statsig|featureassets|prodregistryv2|pendo\.io|userpilot|userflow|appcues|chameleon|zendesk|intercom|usepylon|frontapp|helpscout|freshdesk|customer\.io|customerio|braze|iterable|onesignal|klaviyo|langfuse|helicone|langsmith|smith\.langchain|cube\.dev|tinybird|hs-scripts|hubspot" "$work" \
  | tr 'A-Z' 'a-z' | sort | uniq -c | sort -rn | head -40

echo
echo "--- consent managers (ANY hit here voids every absence claim from this scan) ---"
grep -rhoiE "cookiebot|onetrust|cookiepro|cookieyes|cookie-script|termly|iubenda|usercentrics|didomi|quantcast|osano|complianz|klaro|trustarc|axeptio|consentmanager|civicuk|cookiefirst" "$work" \
  | tr 'A-Z' 'a-z' | sort | uniq -c | sort -rn | head -10

echo
echo "--- site builder (marketing site vs product) ---"
grep -rhoiE "framer|webflow|website-files|wp-content|_next/|myshopify|cdn\.shopify|shopify|bigcommerce|woocommerce|squarespace" "$work" | tr 'A-Z' 'a-z' | sort | uniq -c | sort -rn | head -5

echo
echo "--- CSP allowlist (where an SPA reveals its real stack) ---"
grep -rhoiE "content-security-policy[^>]+" "$work" | grep -oiE "https://[a-z0-9.*-]+" | sort -u | head -60

echo
echo "--- CSP report endpoint (often names their PostHog proxy and token) ---"
grep -rhoiE "report-uri [^;]+|report-to [^;]+" "$work" | sort -u | head -10

# The strongest read in the scan when a token turned up on a server-rendered page: the live
# remote config, which returns their real settings rather than an inference. A null in it
# means the SDK default applies, never that the feature is off.
TOKEN=$(grep -rhoE "phc_[A-Za-z0-9]+" "$work" | sort -u | head -1)
if [ -n "$TOKEN" ]; then
  HOST=$(grep -rhoiE "(us|eu)\.i\.posthog\.com" "$work" | tr 'A-Z' 'a-z' | sort -u | head -1)
  HOST="${HOST:-us.i.posthog.com}"
  echo
  echo "--- live remote config ($TOKEN via $HOST) ---"
  curl -s --max-time "$MAXTIME" "https://$HOST/array/$TOKEN/config" \
    | python3 -m json.tool 2>/dev/null | head -60 \
    || echo "config not readable at $HOST; if they proxy, retry as https://$D/<proxy-path>/array/$TOKEN/config"
else
  echo
  echo "--- live remote config: no phc_ token on a server-rendered page, skipped ---"
fi
