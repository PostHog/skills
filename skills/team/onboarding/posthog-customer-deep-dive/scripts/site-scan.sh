#!/usr/bin/env bash
# Headless scan of a customer's public web surfaces. Run this file, never read it to copy its greps.
#
#   scripts/site-scan.sh acme.com                          # a domain: root, www. and likely subdomains
#   scripts/site-scan.sh --url app.acme.com acme.com/app/   # only these pages: product hosts, sub-apps under a path
#
# Answers two things no query and no enrichment tool can: where the customer runs PostHog
# (marketing site, app, both, or nowhere public) and which competing tools sit beside it.
# It reads static HTML, each host's /config.json, a few same-host scripts per page (relative paths
# resolved against the page) and the app
# shell's Content-Security-Policy, so it recovers the install, the token, the region and the
# tool list, and it cannot see live runtime state. It never fetches binaries.
#
# How to read the output is in references/site-scan.md, including the two readings that are
# wrong every time: a 000 status means no HTTP response reached us (NXDOMAIN or a WAF), so dig before reading it,
# and a CSP allowlist entry is presence, never proof of daily use.
#
# Needs: curl, grep, python3 (for the remote config pretty-print). No pip packages.

set -uo pipefail

MODE=domain; TOKENS_IN=""; ARGS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --url) MODE=url ;;
    --token) shift; TOKENS_IN="$TOKENS_IN ${1:-}" ;;
    *) ARGS+=("$1") ;;
  esac
  shift
done
set -- ${ARGS[@]+"${ARGS[@]}"}
if [ $# -lt 1 ]; then
  echo "usage: $(basename "$0") <domain>        e.g. $(basename "$0") acme.com" >&2
  echo "       $(basename "$0") --url <page>...  e.g. $(basename "$0") --url app.acme.com acme.com/app/" >&2
  echo "       add --token <project token> (repeatable) to read the live config of a token the page hides" >&2
  exit 2
fi

# A real browser UA, because a bare curl UA is what most WAFs bounce first.
UA="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
# 20s is past the point where a slow marketing page is still worth waiting for, and a domain
# scan fires eighteen of these, so a longer ceiling makes a blocked host hold up the whole run.
MAXTIME=20

# Set SITE_SCAN_DIR to keep the fetched pages for follow-up greps; otherwise they go with the run.
# Each scan gets its own fresh folder inside it, so two scans never read each other's pages.
if [ -n "${SITE_SCAN_DIR:-}" ]; then mkdir -p "$SITE_SCAN_DIR"; work=$(mktemp -d "$SITE_SCAN_DIR/scan.XXXXXX"); else work=$(mktemp -d); trap 'rm -rf "$work"' EXIT; fi
mkdir -p "$work/assets"

# One line per page to fetch: <file name> <label> <url>.
: > "$work/.targets"
if [ "$MODE" = domain ]; then
  D="${1#http://}"; D="${D#https://}"; D="${D%%/*}"; D="${D#www.}"
  for h in "" www. app. apps. platform. console. admin. api. account. portal. dashboard. login. my. crm. shop. store. dev. docs.; do
    n=${h:-root}; n=${n%.}
    echo "$n ${h}$D https://${h}$D" >> "$work/.targets"
  done
else
  i=0
  for u in "$@"; do
    i=$((i+1)); u="${u#http://}"; u="${u#https://}"
    echo "u$i $u https://$u" >> "$work/.targets"
  done
  D=$(head -1 "$work/.targets" | awk '{print $2}'); D="${D%%/*}"
fi

echo "--- surfaces (status 000 = no HTTP response: NXDOMAIN or a WAF; dig it before calling it blocked) ---"
while read -r n label url; do
  curl -s --compressed -o "$work/$n.html" -D "$work/$n.headers" \
    -w "$label %{http_code} %{url_effective}\n" \
    -L -A "$UA" "$url" --max-time "$MAXTIME" --max-filesize 5000000 2>/dev/null | tee "$work/$n.status" &
done < "$work/.targets"
wait

# A single-page app keeps its token and its vendors in its config file and its scripts, not
# its HTML. Fetch /config.json on every host that answered, and up to six same-host scripts per
# page, resolving ./x.js and x.js against the page and /x.js against the host. Text only and
# capped at 20 MB, above any real app bundle and far below an installer or archive.
while read -r n label url; do
  [ -s "$work/$n.headers" ] || continue
  grep -qiE "^HTTP/[0-9.]+ 200" "$work/$n.headers" || continue
  eff=$(awk '{print $3}' "$work/$n.status" 2>/dev/null); eff="${eff:-$url}"
  origin=$(echo "$eff" | sed -E 's#^(https?://[^/]+).*#\1#')
  case "$eff" in */) base="$eff" ;; *) base=$(echo "$eff" | sed -E 's#/[^/]*$#/#') ;; esac
  case "$base" in https://*/) ;; *) base="$origin/" ;; esac
  curl -s --compressed -o "$work/assets/$n.config.json" -A "$UA" --max-time "$MAXTIME" --max-filesize 2000000 "$origin/config.json" 2>/dev/null &
  grep -oE 'src="[^"]+\.js[^"]*"' "$work/$n.html" 2>/dev/null | sed -E 's/^src="//; s/"$//' | head -6 \
    | while read -r js; do
      case "$js" in
        https://*|http://*|//*) full="$js"; case "$full" in //*) full="https:$full" ;; esac
          case "$full" in "$origin"/*) ;; *) continue ;; esac ;;
        /*) full="$origin$js" ;;
        *) full="$base${js#./}" ;;
      esac
      curl -s --compressed -o "$work/assets/$n.$(echo "$js" | tr '/?=&.' '_____' | cut -c1-80).js" -A "$UA" --max-time "$MAXTIME" \
        --max-filesize 20000000 "$full" 2>/dev/null
    done &
done < "$work/.targets"
wait
# A tag manager injects its tags at runtime, so a GTM container is fetched and read like a bundle:
# PostHog and every competing tool installed through it are invisible in the page HTML.
for g in $(grep -rhoE "GTM-[A-Z0-9]{4,10}" "$work" 2>/dev/null | sort -u | head -3); do
  curl -s --compressed -o "$work/assets/gtm.$g.js" -A "$UA" --max-time "$MAXTIME" --max-filesize 3000000 \
    "https://www.googletagmanager.com/gtm.js?id=$g" 2>/dev/null &
done
wait
# A config fetch that came back as an HTML page (an SPA fallback or a challenge) is not config.
for c in "$work"/assets/*.config.json; do [ -f "$c" ] && head -c 200 "$c" | grep -qi "<html\|<!doctype" && rm -f "$c"; done
rm -f "$work"/*.status "$work/.targets"
echo
echo "--- PostHog install (case-folded, counts only) ---"
grep -rhoiE "posthog\.init\(|_POSTHOG_REMOTE_CONFIG|PostHogProvider|posthog" "$work" \
  | tr 'A-Z' 'a-z' | sort | uniq -c | sort -rn | head -10
echo "--- PostHog token / region (VERBATIM: a project token is case-sensitive) ---"
# Older projects carry a token without the phc_ prefix, so the init call's first argument counts too.
INIT_TOKENS=$(grep -rhoE "posthog\.init\([[:space:]]*['\"][A-Za-z0-9_-]{10,}['\"]" "$work" 2>/dev/null | sed -E "s/.*['\"]([A-Za-z0-9_-]+)['\"]$/\1/" | sort -u)
{ grep -rhoE "phc_[A-Za-z0-9]+|(us|eu)\.i\.posthog\.com|(us|eu)-assets\.i\.posthog\.com|/array/phc_[A-Za-z0-9]+" "$work"; [ -n "$INIT_TOKENS" ] && echo "$INIT_TOKENS"; } \
  | sort | uniq -c | sort -rn | head -10

echo
echo "--- competing tools (host patterns + npm package names) ---"
# posthog-js ships the strings intercom, sentry, cookiepro and gtag( in its own bundle, so those
# four count only in files that do not bundle posthog-js, and are listed apart where they do.
PH_MARK='__POSTHOG|PostHog was initialized'
AMB='intercom|sentry\.io|@sentry/|sentry-cdn|sentry\.init|ingest\.sentry|sentry_key|browser\.sentry|gtag\(|cookiepro'
find "$work" -type f ! -name '.*.list' > "$work/.all.list.tmp" && mv "$work/.all.list.tmp" "$work/.all.list"
: > "$work/.ph.list"; : > "$work/.plain.list"
while read -r f; do
  if grep -qE "$PH_MARK" "$f" 2>/dev/null; then echo "$f" >> "$work/.ph.list"; else echo "$f" >> "$work/.plain.list"; fi
done < "$work/.all.list"
greplist() { [ -s "$1" ] || return 0; tr '\n' '\0' < "$1" | xargs -0 grep -hoiE "$2" 2>/dev/null; }
{ greplist "$work/.all.list" "google-analytics|googletagmanager|adobedtm|adobe-analytics|plausible\.io|matomo|usefathom|cdn\.segment|rudderlabs|mparticle|mxpnl|mixpanel|cdn\.amplitude|amplitude\.com|@amplitude|heapanalytics|june\.so|fullstory|static\.hotjar|hotjar|logrocket|lr-cdn|lr-ingest|_lrasyncscript|mouseflow|luckyorange|clarity\.ms|qualtrics|surveymonkey|typeform|sprig\.com|uservoice|canny\.io|datadoghq|newrelic|bugsnag|rollbar\.com|cdn\.rollbar|rollbar\.min|grafana|loki|splunk|betterstack|launchdarkly\.com|clientstream\.launchdarkly|cdn\.optimizely|split\.io|splitsoftware|visualwebsiteoptimizer|vwo\.com|webtrends|growthbook|statsig\.com|statsigapi|featureassets|prodregistryv2|pendo\.io|userpilot|userflow|appcues|chameleon|zendesk|usepylon|frontapp|helpscout|freshdesk|customer\.io|customerio|braze|iterable\.com|onesignal|klaviyo|langfuse|helicone|langsmith|smith\.langchain|cube\.dev|tinybird|hs-scripts|hubspot"; greplist "$work/.plain.list" "intercom|sentry\.io|@sentry/|sentry-cdn|sentry\.init|ingest\.sentry|sentry_key|browser\.sentry|gtag\("; } \
  | tr 'A-Z' 'a-z' | sort | uniq -c | sort -rn | head -40
VEND_ALL="google-analytics|googletagmanager|adobedtm|adobe-analytics|plausible\.io|matomo|usefathom|cdn\.segment|rudderlabs|mparticle|mxpnl|mixpanel|cdn\.amplitude|amplitude\.com|@amplitude|heapanalytics|june\.so|fullstory|static\.hotjar|hotjar|logrocket|lr-cdn|lr-ingest|_lrasyncscript|mouseflow|luckyorange|clarity\.ms|qualtrics|surveymonkey|typeform|sprig\.com|uservoice|canny\.io|datadoghq|newrelic|bugsnag|rollbar\.com|cdn\.rollbar|rollbar\.min|grafana|loki|splunk|betterstack|launchdarkly\.com|clientstream\.launchdarkly|cdn\.optimizely|split\.io|splitsoftware|visualwebsiteoptimizer|vwo\.com|webtrends|growthbook|statsig\.com|statsigapi|featureassets|prodregistryv2|pendo\.io|userpilot|userflow|appcues|chameleon|zendesk|usepylon|frontapp|helpscout|freshdesk|customer\.io|customerio|braze|iterable\.com|onesignal|klaviyo|langfuse|helicone|langsmith|smith\.langchain|cube\.dev|tinybird|hs-scripts|hubspot"
# Where each hit landed, so a docs page writing about a tool, or a chunk named after one, reads as what it is.
where=$( { [ -s "$work/.all.list" ] && tr '\n' '\0' < "$work/.all.list" | xargs -0 grep -oiHE "$VEND_ALL" 2>/dev/null; [ -s "$work/.plain.list" ] && tr '\n' '\0' < "$work/.plain.list" | xargs -0 grep -oiHE "intercom|sentry\.io|@sentry/|sentry-cdn|sentry\.init|ingest\.sentry|sentry_key|browser\.sentry|gtag\(" 2>/dev/null; } | sed "s#^$work/##" | tr 'A-Z' 'a-z' | sort | uniq -c | sort -rn | head -25)
[ -n "$where" ] && { echo "  where each hit came from (file: tool; docs.* and chunk names are often prose or filenames, not a tool):"; echo "$where" | sed 's/^/  /'; }
if [ -s "$work/.ph.list" ]; then
  amb=$(greplist "$work/.ph.list" "$AMB" | tr 'A-Z' 'a-z' | sort | uniq -c | sort -rn)
  [ -n "$amb" ] && { echo "  in files that bundle posthog-js (these can be posthog-js's own strings; confirm elsewhere before claiming the tool):"; echo "$amb" | sed 's/^/  /'; }
fi

echo
echo "--- consent managers (ANY hit here voids every absence claim from this scan) ---"
{ greplist "$work/.all.list" "cookiebot|onetrust|cookieyes|cookie-script|termly|iubenda|usercentrics|didomi|quantcast|osano|complianz|klaro|trustarc|axeptio|consentmanager|civicuk|cookiefirst"; greplist "$work/.plain.list" "cookiepro"; } \
  | tr 'A-Z' 'a-z' | sort | uniq -c | sort -rn | head -10

echo
echo "--- site builder (marketing site vs product) ---"
grep -rhoiE "framer|webflow|website-files|wp-content|_next/|myshopify|cdn\.shopify|shopify|bigcommerce|woocommerce|squarespace" "$work" | tr 'A-Z' 'a-z' | sort | uniq -c | sort -rn | head -5

echo
echo "--- CSP allowlist (where an SPA reveals its real stack) ---"
grep -rhoiE "content-security-policy[^>]+" "$work" | grep -oiE "((https?|wss)://)?[a-z0-9*][a-z0-9.*-]*\.[a-z]{2,}" | sed -E 's#^(https?|wss)://##' | sort -u | head -80

echo
echo "--- CSP report endpoint (often names their PostHog proxy and token) ---"
grep -rhoiE "report-uri [^;]+|report-to [^;]+" "$work" | sort -u | head -10

# The strongest read in the scan when a token turned up on a server-rendered page: the live
# remote config, which returns their real settings rather than an inference. A null in it
# means the SDK default applies, never that the feature is off.
TOKENS=$( { grep -rhoE "phc_[A-Za-z0-9]{20,}" "$work"; [ -n "$INIT_TOKENS" ] && echo "$INIT_TOKENS"; for t in $TOKENS_IN; do echo "$t"; done; } | sort -u | head -8)
if [ -n "$TOKENS" ]; then
  # A token answers only in its own region (the other returns an empty body), so try the region
  # the pages name first, then the other one.
  if grep -rqiE "eu\.i\.posthog\.com" "$work" && ! grep -rqiE "us\.i\.posthog\.com" "$work"; then ORDER="eu us"; else ORDER="us eu"; fi
  for TOKEN in $TOKENS; do
    got=""
    for r in $ORDER; do
      body=$(curl -s --max-time "$MAXTIME" --max-filesize 5000000 "https://$r.i.posthog.com/array/$TOKEN/config")
      if [ "${body:0:1}" = "{" ]; then got="$r"; break; fi
    done
    echo
    if [ -n "$got" ]; then
      echo "--- live remote config ($TOKEN via $got.i.posthog.com) ---"
      cfg="$work/assets/remote-config.$TOKEN.json"; echo "$body" > "$cfg"
      # The JSON runs to thousands of lines, alphabetically, so print the settings that decide
      # findings and point at the full file rather than cutting it at an arbitrary line.
      python3 - "$cfg" <<'PYEOF'
import json, sys
c = json.load(open(sys.argv[1]))
def show(k, v):
    t = json.dumps(v, separators=(",", ":"))
    print(f"{k}: {t[:1500]}{' ...(truncated)' if len(t) > 1500 else ''}")
for k in ("autocapture_opt_out", "autocaptureExceptions", "heatmaps", "capturePerformance", "defaultIdentifiedOnly",
          "captureDeadClicks", "elementsChainAsString", "sessionRecording", "errorTracking", "logs"):
    if k in c: show(k, c[k])
s = c.get("surveys")
print(f"surveys: {len(s) if isinstance(s, list) else s}")
ff = c.get("featureFlags") or c.get("flags")
if ff is not None: print(f"feature flags in config: {len(ff) if hasattr(ff, '__len__') else ff}")
PYEOF
      echo "(full config: $cfg$([ -n "${SITE_SCAN_DIR:-}" ] || echo ', deleted at exit; set SITE_SCAN_DIR to keep it'))"
    else
      echo "--- live remote config ($TOKEN): not readable in either region; if they proxy, retry as https://$D/<proxy-path>/array/$TOKEN/config ---"
    fi
  done
else
  echo
  echo "--- live remote config: no project token found on a server-rendered page or handed in with --token, skipped ---"
fi
rm -f "$work"/.all.list "$work"/.ph.list "$work"/.plain.list
[ -n "${SITE_SCAN_DIR:-}" ] && echo "--- fetched files kept in $work ---"
exit 0
