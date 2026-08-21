# Site scan (headless instrumentation + competing-tools enrichment)

A no-browser, no-login enrichment pass over the customer's public web surfaces. It answers two things project 2 and Clay cannot: **where the customer runs PostHog** (marketing site, app, both, or nowhere on the public web) and **what competing tools they run alongside it**. Both feed outreach (a consolidation hook) and call prep (their real stack).

It reads static HTML and the app's Content-Security-Policy, so it recovers install, token and region plus the competing-tool list, but not live runtime state (active flag values, live network calls). Where PostHog lives behind a login, the CSP allowlist still exposes feature-flag, observability and adoption tools; the live PostHog config on that surface needs a browser and a login, which is out of scope.

## When to run

Every account with a web domain, and **one agent per team rather than one per account**. The batch-1 agent has only the admin email domain: scan exactly that, nothing else. Every team beyond the first gets its own agent in batch 2, handed that team's id and `api_token` from `resolve-teams`, because an org with several teams runs several tokens and one scan leaves every other project's `init()` unread. When the admin email is on a public provider (gmail, outlook and the like), skip the batch-1 scan and run in Round 2 instead, where Step 1 supplies the real domain. Cheap and fast. Skip only if the account has no web domain.

**Given a token, establish which hosts it actually serves rather than inferring that from the domain you were sent to.** One token routinely serves several hosts behind a `tenant`-style super property, and team names do not track products, so a team called after one product can be carrying three. Report the token found in each bundle so main can join it back to the team list, and never name a team's product from its name alone.

Which domain to scan, from Step 1 onward: the customer's, from Vitally `traits.sfdc.Website` / `sfdc.Domain__c`, else the admin email domain; rescan when it differs from the batch-1 target. If `sfdc.Website` or `sfdc.Domain__c` is a public-email domain (`gmail.com`, `outlook.com`, and the like), ignore it and use the admin email domain: on gmail-admin startups the SFDC record is matched to the email provider, so scanning it points at Google and the firmographics beside it (`NumberOfEmployees`, `AnnualRevenue`, `Company_Type`) describe the provider, not the customer. Distrust those SFDC firmographics whenever the SFDC domain is a public-email domain, the same way Harmonic is distrusted. When the SFDC fields AND the admin email are all public providers, scan nothing: pull a company domain from enrichment, notes or conversations, else report that no customer domain was available.

## Running it

```bash
scripts/site-scan.sh acme.com
```

One command does the whole pass: fetches the marketing root, `www.` and ten likely app and storefront subdomains with a browser user agent, greps each body and its response headers, and finishes on the live remote config when it found a token. It exists so nobody retypes the detector list or rediscovers that CSP usually arrives as a header rather than a meta tag.

**It is the floor of the scan, never the ceiling.** It covers the common shape; the interesting accounts are the ones that do not have it. Keep going by hand whenever the output points somewhere it does not reach, and say in the brief what you ran beyond it:

- **Their app is not on one of the probed subdomains.** `console.`, `admin.`, `beta.`, a country subdomain, or a path on the marketing domain. Take the real one from `sfdc.Website`, the CSP report endpoint, a login link in the marketing HTML, or the customer's own docs, then `curl -sL -A "<the script's UA>"` it and grep the same way.
- **A tool you can see but the detector cannot.** The grep is a list of names, so anything new, renamed, or self-hosted is invisible to it. Read the `<script src>` list and the CSP allowlist yourself when the tool list looks thinner than the account should have, and add the tool to the table here and the grep in the script in the same pass.
- **The token turns up somewhere the script did not fetch**, or the config comes back empty because they proxy. Retry as `https://<their-domain>/<proxy-path>/array/<token>/config`, taking the proxy path from the CSP allowlist or the `/array/` hit.
- **A 000 or a challenge page on the surface that matters.** A 000 means no HTTP response reached the scan (WAF, DNS, or network); a challenge page is a WAF. Either way the scan cannot answer it and neither can a retry: say so, and take the question to the customer or to a browser rather than reporting silence as absence.
- **Anything the account makes you curious about.** A scan that only ever returns the script's six sections is a scan that asked the script's questions instead of this account's.

## What each section of the output means

**surfaces**: the final URL and HTTP status per host. A known site builder in the assets (Webflow `website-files.com`, WordPress `wp-content`, Framer, `_next/`) marks a surface as the marketing site rather than the product, and a B2B SaaS usually instruments PostHog in the app.

**PostHog install / token / region**: `posthog.init(` and the `!function(t,e)` snippet are a script-tag install, while bare `posthog` and `PostHogProvider` are an SPA bundle referencing the npm package, so the counts distinguish the two. `phc_` is the project token, and `(us|eu).i.posthog.com`, `us-assets` / `eu-assets`, or a custom path carrying `/array/phc_` or `/flags/` gives the region or the proxy.

**competing tools**: hits from both `<script src>` hosts and bare npm package names, because SPA bundles reference tools as `@sentry/nextjs` or `launchdarkly-js-client-sdk` and never as a CDN host. **A hit on a docs or marketing surface can be the page's own content rather than their stack**, because a page that writes about a competitor names it in prose. Check where the hit landed before it reaches a brief, and treat a tool named on a docs page as unconfirmed.

**CSP allowlist**: where an SPA reveals its real stack even when the snippet is injected at runtime. The report endpoint often names their PostHog proxy and token.

**live remote config**: the strongest read in the scan, because it returns the customer's LIVE settings rather than an inference: autocapture, surveys, heatmaps, flags, error tracking, and the whole `sessionRecording` block (`sampleRate`, `minimumDurationMilliseconds`, `urlTriggers`, `urlBlocklist`, `eventTriggers`, `linkedFlag`, `recordCanvas`, `canvasFps`, `consoleLogRecordingEnabled`, `masking`, `networkPayloadCapture`). `team-config` in `queries-products.md` owns the fetch itself and what a mirror disagreement means; the proxy retry is in the by-hand list above. Absent for token-hidden SPA shells; skip rather than guess.

**A `null` in that config means the SDK default applies, never that the feature is off.** The two look identical in a scan and the difference decides whether a finding is real. `masking: null` on a healthcare site does NOT mean recordings are unmasked, because inputs are masked by default; it means no override was set. Read the value, then check the current default on the docs page for that setting, and report the combination. Never turn a `null` into an alarm.

## Competing-tools map (each = a PostHog consolidation pitch)

The category column is what a hit feeds: map the category to the current PostHog product with a live docs search at draft time (product names and lifecycle stages are product state and are not written down here, per the two-kinds rule in `SKILL.md`). Several PostHog products double as access surfaces rather than destinations (web, Slack, MCP, CLI, the desktop app), and a static-site scan cannot see them; coding agents, warehouses, and server-side tooling leave no signal in public HTML or CSP, so do not force every product into the detector.

| Category | Competing tools / context |
|---|---|
| Product analytics | Amplitude, Mixpanel, Heap, June |
| Web analytics | Google Analytics / GTM, Adobe Analytics, Plausible, Matomo, Fathom |
| Feature flags / experiments | LaunchDarkly, Optimizely, Split, GrowthBook, VWO, Statsig, Webtrends Optimize |
| Session replay / heatmaps | FullStory, Hotjar, LogRocket, Mouseflow, Lucky Orange, MS Clarity |
| Surveys / feedback | Qualtrics, SurveyMonkey, Typeform, Sprig, UserVoice, Canny |
| Product adoption / onboarding | Pendo, Userflow, Userpilot, Appcues, Chameleon |
| Error tracking / APM | Sentry, Datadog RUM, New Relic, Bugsnag, Rollbar |
| Logs | Datadog, New Relic, Grafana / Loki, Splunk, Better Stack |
| Support / help desk | Zendesk, Intercom, Pylon, Front, Help Scout, Freshdesk |
| CDP / pipelines | Segment, RudderStack, mParticle |
| Customer messaging / automation | Customer.io, Braze, Iterable, OneSignal, Klaviyo |
| AI Observability | Langfuse, Helicone, LangSmith |
| Embedded analytics / query APIs | Cube, Tinybird |
| AI coding agents | Cursor, Claude Code, GitHub Copilot, Codex, Windsurf, Devin |

A competing tool in the same category PostHog already bills them for is the strongest consolidation signal. Support is also a direct migration pitch: its docs explicitly offer a Zendesk historical import.

## Ecommerce and Shopify

A large share of EU consumer accounts run Shopify, and the scan reads them badly by default. Three things to do rather than trust the output:

- **Classify the surface properly.** A Shopify storefront carries hundreds of `shopify` / `myshopify` / `cdn.shopify` references and will otherwise classify as no known builder at all.
- **Find the logged-in area.** It is almost never on `app.`; it is on `account.` or `my.`, and it is where their identified traffic legitimately lives. Splitting events by `$host` is what tells you how much volume sits on each surface, and that split decides whether a high identified share is a finding or is correct.
- **Expect two capture paths.** A theme snippet and an app-injected one both firing is the normal Shopify double-capture shape, so break the event mix down by `$lib` before concluding anything about volume.

Two known false positives in the detector, both from Shopify pages: `featureassets` matches Shopify's own `window.Shopify.featureAssets` and is not a feature-flag vendor, and `rollbar` matches inside the Tailwind class `scrollbar-none`. A hit that appears only on a storefront or a docs page is the page's own content until you can point at where it loads from.

## What to conclude

**This scan is authoritative for what it FOUND and never for what it did not.** Every mechanism that hides a tag (a WAF challenge, a consent gate, runtime injection, a login wall, a token-hidden SPA shell) hides it silently and looks exactly like a clean absence. Write "not visible to this scan", and say which of those you hit.

Two rules follow, and the second settles it outright:

- **A consent manager voids every absence claim from the scan.** Cookiebot, OneTrust, Usercentrics, Didomi and the rest gate tag loading behind consent, so a scan that has not consented cannot see anything downstream of them. The script's consent-manager section exists for this; a hit there means the tool list is a floor and the absences are unknowns.
- **Absence is settled by the customer's own event stream, not by the scan.** If their team is receiving events carrying that host in `$current_url`, PostHog is installed there whatever the scan saw. That is one query, it is definitive, and it is a named pair in the Round 3 reconcile in `SKILL.md`. Run it before any "PostHog is not on their site" reaches an output, because that sentence is one a customer will contradict from memory.

- **Where PostHog runs**: marketing / app / both / not visible to this scan (which on a B2B account usually means app-only behind login, and is a question rather than a conclusion).
- **Region**: confirm against Vitally `usEuInstance` first, falling back to `cloudRegion`, per the precedence in `SKILL.md`.
- **Competing tools by category**, each mapped to a PostHog product.
- **Limits, state them honestly**: a CSP allowlist entry is a strong signal a tool is wired in, not proof of active daily use (confirm live if it drives the pitch), and a static scan cannot read an SPA app's live token or config.

## How it feeds the output

- **Outreach (first touch or follow-up)**: one consolidation hook, written per the "Competing-tool consolidation" product fact in `references/levers.md`, which owns the wording rules.
- **Call prep**: a "Their stack" section listing where PostHog runs and the competing tools by category, each with the consolidation angle. Cross-check against Clay Tech Stack and Vitally `sfdc.Company_tech__c`; the scan is often more current and catches tools those lists miss.

## Keeping the detector current

The script's grep covers every row of the table above except AI coding agents, which leave no trace in public HTML; enrich that row and other server-side tooling from Clay, `sfdc.Company_tech__c`, calls, or the customer's repo. It also carries a separate consent-manager section, which is not a competing-tool list and must not be merged into one: its only job is to say whether this scan is entitled to report an absence at all. Two notes on matching: `split`, `june`, `vwo`, `front` and `sprig` are ordinary words, so they are matched on their domains rather than bare text. HubSpot is matched too, though it is marketing and CRM context rather than a consolidation target. Adding a tool means editing the table here and the grep in `scripts/site-scan.sh` in the same pass.
