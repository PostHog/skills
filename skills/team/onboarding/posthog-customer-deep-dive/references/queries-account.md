# Queries: account core

Step 1 resolution, the always-run core, and the Vitally warehouse reads. Conventions, ids, regions, and the source rules live in `data-rules.md`; this file's headings are its index.

## sibling-sweep

Step 1, every account with a domain. Run BOTH queries below, because they see different populations. The `vitally.users` query only knows Vitally-synced accounts, so it misses free and self-serve siblings entirely; the `billing_customer` query catches those, including orgs whose sole admin also admins the paying org, which is exactly the consolidation story the sweep exists to find. The `vitally.users` query catches siblings that share the domain through their user list rather than an admin email. Neither alone is complete.

Caveats on the `vitally.users` query: it scans a large table, so a cold run is slow and can hit the server's execution ceiling (if it times out, retry once and the cached result returns: the retry rule in `data-rules.md`); and the warehouse syncs hours to days behind, so treat an empty result on a fresh account as sync lag, not proof of no siblings. A sync-lag warning banner is normal; note the as-of date.

```sql
SELECT JSONExtractString(acc, 'name') AS account_name, JSONExtractString(acc, 'id') AS vitally_account_id,
       JSONExtractString(acc, 'externalId') AS posthog_org_id, count() AS users
FROM vitally.users ARRAY JOIN JSONExtractArrayRaw(coalesce(toString(accounts), '[]')) AS acc
WHERE email ILIKE '%@<domain>' GROUP BY account_name, vitally_account_id, posthog_org_id
ORDER BY users DESC LIMIT 20
```

```sql
SELECT id AS billing_customer_id, name, organization_id, admin_emails
FROM postgres.prod.billing_customer
WHERE toString(admin_emails) ILIKE '%@<domain>%' ORDER BY name LIMIT 30
```

`admin_emails` is `Nullable(String)`, not an array, so match it with `ILIKE` and never with `arrayExists`, which errors with `Argument 2 of function arrayExists must be Array`. Filter out unrelated orgs that merely share one domain user (a single-user org named nothing like the account is usually noise, not a duplicate).

## resolve-teams

Run this first; it returns the team list and the region in one read, and every regional choice downstream depends on the answer.

```sql
SELECT id AS team, name AS team_name, api_token, app_region, project_id, is_demo, created_at
FROM all_posthog_team
WHERE organization_id = '<ORG_ID>'
ORDER BY team
LIMIT 100
```

`all_posthog_team` is cross-region, so this works for a US and an EU org identically. **The key is `id`; there is no `team_id` column.** Alias it to `team`, per the conventions. `app_region` is lowercase (`us` / `eu`): compare it lowercase, and pass it to anything region-prefixed.

**`api_token` is selected here because Round 1a batch 2 fans out one `site-scan` per team and each scan needs its own token.** It is also what settles the token-to-team mapping later without a second query: a scan finds a `phc_...` token in a bundle, and this result says which project it belongs to. Deriving that mapping from domain names instead is unreliable, because one team's token routinely serves several hosts and team names do not track products. If the column is missing on a region's view, fall back to `postgres.posthog_team` / `eu_postgres_posthog_team` for it, all-or-nothing per the region rule.

Scope by `organization_id`, never by a bare team id (the collision rule in `SKILL.md`); an org's own `(org, team)` pairs are unique, so this query returns each of its teams once.

Read the team names before picking a project: they carry the production / staging / demo / deprecated split in plain text. **Treat the names as a hint and never as the answer**, because one team's token routinely serves several hosts and the names do not track products. Measured on a multi-brand account, 2026-08-19: one team was named after a single storefront and served only that storefront, while a blandly named team beside it carried the main store AND a second brand's point-of-sale AND a third white-label tenant, all behind one token. Confirm which is production by volume from the org usage report's per-team `teams` map, which **`change-point` owns and publishes to `<run scratchpad>/daily-by-team.md`** (`org-snapshot` in this file is the recipe it uses). Main does not run it separately; where the split matters before `change-point` returns, take volume per org from the Round 1a scope probe and defer the per-team split.

## discovery

Run every time. Shows the full event mix; scan the result for unfamiliar high-volume events. The AI and self-driving event names to recognize (PostHog AI chat, Inbox, Scouts/signals, PostHog Code, MCP) are enumerated in `self-driving-check` below, and the `$ai_*`, `mcp_*`, `react_framerate`, and `livestream_sse_*` families are PostHog's own app telemetry (staff and admins using PostHog), never the customer's product usage. `replay_vision_scan_completed` is a backend event carrying no email, so it collapses into one `(null)` row and reads like noise: it means Replay Vision is scanning and spending credits, and it routes to `replay-vision` in `queries-products.md`. If a new product appears, add a query for it in the owning file and note it.

```sql
SELECT event, count() AS total_events
FROM events
WHERE timestamp >= now() - INTERVAL <days> DAY AND $group_0 = '<ORG_ID>'
GROUP BY event ORDER BY total_events DESC LIMIT 50
```

**Exactly 50 rows back means truncated, not complete.** Re-run the tail before concluding an event is absent (on the MCP: `OFFSET 48` with a larger LIMIT; on the personal-API-key path OFFSET is rejected with HTTP 400, so use `HAVING total_events <= <50th row's count>` or keyset paging on the ranking column instead); the tail is where a new product first shows up.

## account-state

The unified `billing_customer` snapshot; it overlaps `get_user_details`, run both to cross-check. Extract: `billing_period_ends`, `crm_segments`, `sales_info`, `plans_map`, `custom_limits_map`, `admin_emails`, `organization_users`, `internal_notes`, `amount_off`, `account_executive_id`, `metadata`.

```sql
SELECT bc.name, bc.billing_period_starts, bc.billing_period_ends, bc.subscription_start_date,
       bc.crm_segments, bc.sales_info, bc.plans_map, bc.custom_limits_map, bc.admin_emails,
       bc.organization_users, bc.internal_notes, bc.amount_off, bc.account_executive_id, bc.metadata
FROM postgres.prod.billing_customer bc WHERE bc.organization_id = '<ORG_ID>' LIMIT 1
```

## org-snapshot

The latest org usage report in one row. Every `*_in_period` field on this event covers ONE UTC DAY, not a month; the reading rules and the full field dictionary are in the `queries-products.md` shared intro.

```sql
SELECT argMax(properties.date, timestamp) AS report_date,
       argMax(properties.site_url, timestamp) AS region,
       argMax(properties.realm, timestamp) AS realm,
       argMax(properties.organization_user_count, timestamp) AS org_users,
       argMax(properties.team_count, timestamp) AS team_count,
       argMax(properties.event_count_in_period, timestamp) AS events_day,
       argMax(properties.enhanced_persons_event_count_in_period, timestamp) AS identified_events_day,
       argMax(properties.event_count_with_groups_in_period, timestamp) AS group_events_day,
       argMax(properties.web_events_count_in_period, timestamp) AS web_events,
       argMax(properties.web_lite_events_count_in_period, timestamp) AS web_lite_events,
       argMax(properties.node_events_count_in_period, timestamp) AS node_events,
       argMax(properties.python_events_count_in_period, timestamp) AS python_events,
       argMax(properties.android_events_count_in_period, timestamp) AS android_events,
       argMax(properties.ios_events_count_in_period, timestamp) AS ios_events
       -- add argMax(properties.<field>, timestamp) for every other field this account implicates (comma-separate them after ios_events).
       -- Per-SDK keys follow <sdk>_events_count_in_period (web, node, python, php, ruby, go, java, rust, dotnet, elixir, react_native, flutter, ios, android, unity, edge, convex, openclaw), plus mcp_tool_call_, posthog_ai_ and posthog_pi_events_count_in_period; enumerate the live keys with JSONExtractKeys(properties) rather than trusting this list, and read the field dictionary in queries-products.md
FROM events
WHERE $group_0 = '<ORG_ID>' AND event = 'organization usage report'
  AND timestamp >= now() - INTERVAL 8 DAY LIMIT 1
```

**Use `argMax(field, timestamp)`, never `max(field)`.** `max()` takes each field's peak independently across the window and splices different days into one row that never existed: a peak-day event count next to a different day's recording count next to today's dashboard count. `argMax(field, timestamp)` pins every column to the single latest report. The 8-day window is deliberate (it survives a missed cron run), and the query is aggregate-only, so it always returns exactly one row. The org can also emit the same day's report several times as late data lands; `argMax` correctly takes the last one.

Swap the window for `properties.date = toDate('YYYY-MM-DD')` to pin a specific day, or add `toDate(timestamp)` plus `GROUP BY` for the daily series.

## top-users

```sql
SELECT person.properties.email AS email, person.properties.role_at_organization AS role,
       count(DISTINCT $session_id) AS session_count, count() AS total_events
FROM events
WHERE timestamp >= now() - INTERVAL <days> DAY AND $group_0 = '<ORG_ID>' AND person.properties.email IS NOT NULL
GROUP BY email, role ORDER BY session_count DESC LIMIT 15
```

One query covers both rankings: `session_count` is the engagement order, and re-sorting the same rows by `total_events` gives the volume order.

## page-paths

Look for `/feature_flags`, `/replay`, `/surveys`, `/billing`, `/llm-analytics`, `/data-warehouse`, multiple `/project/<id>`.

**This one read also answers who watches the bill, so there is no separate billing query: group by path for the surface ranking, and read `surface = 'billing'` out of the same result.** Who watches the bill decides who a cost email is addressed to, and it is often not the person who booked the call. Empty is a real answer there: nobody is looking at billing, so rank contacts by volume alone.

```sql
SELECT properties.$pathname AS path,
       person.properties.email AS email,
       multiIf(properties.$pathname LIKE '%/billing%', 'billing',
               properties.$pathname LIKE '%/replay%', 'replay',
               properties.$pathname LIKE '%/feature_flags%', 'flags',
               properties.$pathname LIKE '%/error_tracking%', 'errors',
               properties.$pathname LIKE '%/surveys%', 'surveys',
               properties.$pathname LIKE '%/experiments%', 'experiments',
               'other') AS surface,
       count() AS cnt, max(timestamp) AS latest
FROM events
WHERE $group_0 = '<ORG_ID>' AND event = '$pageview' AND timestamp >= now() - INTERVAL <days> DAY
GROUP BY path, email, surface ORDER BY cnt DESC LIMIT 200
```

The leading `%` on each pattern cannot be anchored away: the PostHog app nests these under `/organization/` and `/project/<id>/`, so `/billing%` matches nothing while `%/billing%` matches `/organization/billing`. Index pruning is lost either way, so keep the window tight rather than widening it here.

## docs-viewed

**Scope this one by EMAIL, never by `$group_0`, or it returns empty every time.** Docs pageviews on `posthog.com` carry no group, so the org filter every other query in this file uses matches nothing here and the empty result reads as "they never open the docs" when the truth can be hundreds of views. Pass the admin emails from the context block.

Anchor the path rather than searching the URL: `$pathname LIKE '/docs/%'` prunes on the index where `$current_url LIKE '%/docs/%'` is a full scan with a leading wildcard, and `/docs/` is top level so anchoring is safe here (unlike the app paths above).

```sql
SELECT person.properties.email AS email, properties.$pathname AS path,
       count() AS views, max(timestamp) AS latest
FROM events
WHERE event = '$pageview' AND timestamp >= now() - INTERVAL <days> DAY
  AND properties.$pathname LIKE '/docs/%'
  AND person.properties.email IN ('<admin1>','<admin2>', ...)
GROUP BY email, path ORDER BY views DESC LIMIT 50
```

Read the dates as much as the pages: a cluster on one product in the last week is a live problem, and often the thing they booked the call about.

## billing-limit-updates

Fixed 120 day window, ignoring `<days>`: billing-limit changes are sparse, and a 30 day window misses the update that explains the current limit.

**Filter on key presence with `JSONHas`, never on the value.** A `!= 0` value test cannot see a limit being SET TO ZERO, which is the most aggressive limit a customer can set and the one that silently drops every unit past the free tier, so the account that most needs the finding is the one that returns nothing. `JSONHas` separates "the key is absent from this event" (the products untouched by that update) from "the key is present and its value is 0".

```sql
SELECT e.timestamp, e.person.properties.email AS email, product_name AS product,
       JSONExtractFloat(e.properties, product_key) AS limit_amount
FROM events e
ARRAY JOIN ['product_analytics','session_replay','feature_flags','realtime_destinations','posthog_ai','logs','error_tracking','llm_analytics','workflows_emails','surveys','replay_vision','data_warehouse','inbox','posthog_code_usage'] AS product_key,
          ['Product Analytics','Session Replay','Feature Flags','Realtime Destinations','PostHog AI','Logs','Error Tracking','LLM Analytics','Workflows/Emails','Surveys','Replay Vision','Data Warehouse','Inbox','PostHog Code'] AS product_name
WHERE e.event = 'billing limits updated' AND e.$group_0 = '<ORG_ID>'
  AND timestamp >= now() - INTERVAL 120 DAY AND JSONHas(e.properties, product_key)
ORDER BY timestamp DESC LIMIT 50
```

Cross-check the result against `custom_limits_map` on `account-state`, which carries the CURRENT limit per product including any zero. A limit in that map with no matching row here predates the 120 day window.

## event-breakdown

Per-person product categories for the top 15% of users, using the `dana_usage_events` allowlist. `dana_usage_events` is a shared saved view in project 2 that maps PostHog app event names to a product category (`event_name`, `product_category`), PostHog AI and Customer Analytics included. It is a colleague-maintained view rather than a system table, so if this query errors with an unknown table, the view was renamed or dropped: skip this one query, fall back on the discovery and core event mix, and never block a run on it.

**Name the three columns in the base CTE; never `SELECT *` here.** This CTE is referenced twice below and CTEs are inlined rather than materialized, so the org's whole window is scanned twice. With `SELECT *` each of those scans drags the full `properties` JSON blob, and a JSON blob read is far slower than a materialized column. Narrowed to the three columns it uses, the two scans are cheap. If it still drags on a very large org, the next step is `uniqState` / `uniqMerge` on `$session_id` to collapse the two scans into one, unconfirmed on this HogQL path so test it first.

```sql
WITH session_data AS (
  SELECT person.properties.email AS email, event, $session_id FROM events
  WHERE $group_0 = '<ORG_ID>' AND timestamp >= now() - INTERVAL <days> DAY AND person.properties.email IS NOT NULL),
event_data AS (
  SELECT event, count() AS event_count, email FROM session_data
  WHERE event IN (SELECT event_name FROM dana_usage_events) GROUP BY event, email),
session_counts AS (
  SELECT email, count(DISTINCT $session_id) AS session_count, count() AS total_events FROM session_data GROUP BY email),
top_users AS (
  SELECT email, session_count, total_events,
         PERCENT_RANK() OVER (ORDER BY session_count) AS session_pct,
         PERCENT_RANK() OVER (ORDER BY total_events) AS events_pct FROM session_counts),
categorized AS (
  SELECT ed.email, ed.event, ed.event_count, due.product_category, tu.session_count, tu.total_events
  FROM event_data ed JOIN dana_usage_events due ON ed.event = due.event_name
  JOIN top_users tu ON ed.email = tu.email WHERE tu.session_pct >= 0.85 OR tu.events_pct >= 0.85)
SELECT email, product_category, SUM(event_count) AS category_total,
       SUM(event_count) / SUM(SUM(event_count)) OVER (PARTITION BY email) AS pct_of_total,
       MAX(session_count) AS session_count, MAX(total_events) AS total_events
FROM categorized GROUP BY email, product_category ORDER BY session_count DESC, email, category_total DESC LIMIT 100
```

## account-spine

The one row that says who this account is, what it pays, and which PostHog people are already on it, the Onboarding Specialist included. `accounts_replacement_v2` is the account spine: keyed on `organization_id`, both regions, one row per org.

```sql
SELECT a.name AS account, r.region AS region, r.teams AS teams,
       a.mrr AS mrr, a.customer_stage AS stage, a.stripe_subscription_status AS sub_status,
       a.csm_name AS csm, a.csm_email AS csm_email,
       a.ae_name AS ae, a.ae_email AS ae_email,
       a.owner_slack_id AS owner_slack_id, a.slack_channel AS slack_channel,
       a.user_count AS seats, a.archetype AS archetype, a.icp_score AS icp_score,
       a.stripe_customer_id AS stripe_customer_id, a.stripe_delinquent AS delinquent
FROM accounts_replacement_v2 AS a
LEFT JOIN (
  SELECT organization_id, arrayStringConcat(groupUniqArray(app_region), ',') AS region, count() AS teams
  FROM all_posthog_team GROUP BY organization_id
) AS r ON r.organization_id = a.organization_id
WHERE a.organization_id = '<ORG_ID>'
ORDER BY a.mrr DESC
LIMIT 1
```

**`os_name` / `os_email` are deliberately not selected here: they read null on accounts that do have an Onboarding Specialist.** Take the roster from the Vitally `key_roles` array instead (the `keyrole` rows in `account-context`), which carries the role label, the email and the name together. `csm_name` / `ae_name` above corroborate, and a null in either is usually a real `NONE` rather than a broken field. Roster names are reported, never routed on (Step 4).

**Pre-aggregate the team side, as above, or the join fans out.** An org has many teams, so joining `all_posthog_team` on `organization_id` directly returns one row per team, each carrying a full copy of the same MRR and owner values. Nothing errors, the row just repeats, so any downstream sum multiplies the money by the team count. The grouped subquery makes the join one-to-one and hands back `teams` as a free count.

**`accounts_replacement_v2` has no region column: take region from `all_posthog_team.app_region`.** Never read `billing_country` as region. It is where the account pays from, not where its data is hosted, and the two disagree in both directions often enough to matter.

`groupUniqArray` rather than `min(app_region)`: an org can hold teams in both regions, and the array form shows `eu,us` where `min()` would silently report one. `mrr`, `effective_mrr`, and `sticky_mrr` are byte-identical copies of each other, so read one and ignore the other two. `ORDER BY a.mrr DESC LIMIT 1` is the dedup guard: a few org ids carry a second, empty record, and this keeps the populated one. `mrr` here is what PostHog books, not the invoice; the MRR framing rule is in `SKILL.md`, and the money reads are in `queries-money.md`.

## other-account-tables

- Support tickets: PostHog Support holds them now, so read them over the MCP with `conversations-tickets-list` (its `emails` parameter takes a comma-separated **string**, not an array, so pass the account's admin emails joined by commas), then `conversations-tickets-messages-retrieve` for bodies. Those carry per-message direction, which Vitally's `type` does not on Slack and Zapier threads. `zendesk_tickets_by_org` (key `organization_id`) is the historical set only: an unbounded `SELECT *` times out, so keep a row cap or name your columns.
- Ownership without duplication: `billing_customers_with_owner` (columns `current_owner_email`, `ae_email`, `owner_role`; no `owner_email`; zero rows means the view does not cover the org, not that it is unowned, so corroborate elsewhere). `vitally_all_assigned_customers` duplicates a row per owner.

## per-product-usage

How much of each product they actually consume, typed and daily, no JSON extraction and no `argMax`. This section owns the `billing_usage_by_org_date` facts; `usage-mix` in `queries-money.md` points back here rather than restating them.

`billing_usage_by_org_date`, key `organization_id`, daily grain, exactly unique so no dedup guard is needed, fresh to the previous day, US and EU combined with no region column, and typed. It agrees with the org usage report on the volume metrics they share. Eighteen columns in total including `date` and `organization_id`, so there is no per-SDK or per-event-name breakdown to reach for here. Which of the two sources to reach for is the choice rule in the `queries-products.md` shared intro.

| Product | Column |
|---|---|
| Product analytics | `event_count_in_period` |
| Identified events | `enhanced_persons_event_count_in_period` |
| Session replay | `recording_count_in_period`, `mobile_recording_count_in_period` |
| Feature flags | `billable_feature_flag_requests_count_in_period` |
| Surveys | `survey_responses_count_in_period` |
| Error tracking | `exceptions_captured_in_period` |
| AI Observability | `ai_event_count_in_period`, `ai_credits_used_in_period` |
| Data warehouse | `rows_synced_in_period`, `rows_exported_in_period` |
| CDP and destinations | `cdp_billable_invocations_in_period` |
| Logs | `logs_mb_in_period` |

**Two traps, both of which read as a confident zero.** It is **Cloud only**, so a self-hosted org reads zero across every column while emitting usage daily: check `realm` on `org-snapshot` before believing a flat zero. And it carries a row only where there was usage, rather than zero-filling, which cuts two ways: a **missing day** means no usage that day, and an **org with no rows at all** has no Cloud usage in the window. Neither is ever no data.

No source exists at all for experiment volume or web analytics volume. Per-org heatmap volume rides on the usage report's `teams` map as `heatmap_events_count_in_period`, so read it there rather than calling it unmeasurable.

**`mobile_billable_recording_count_in_period` is NOT on this table**, and selecting it here fails with HTTP 400 rather than returning zero. This table carries `mobile_recording_count_in_period` (captured) only; the billable twin lives on the `organization usage report` event, where both sit side by side (`queries-products.md`, Session replay). The gap between captured and billable is the free tier plus anything a limit dropped, so on a mobile-heavy account read both and never quote the captured figure as the billed one.

```sql
SELECT count() AS days_reported, min(date) AS first_day, max(date) AS last_day,
       sum(event_count_in_period) AS events,
       sum(enhanced_persons_event_count_in_period) AS identified_events,
       round(sum(enhanced_persons_event_count_in_period) / nullIf(sum(event_count_in_period), 0) * 100, 1) AS identified_pct,
       sum(recording_count_in_period) AS recordings,
       sum(mobile_recording_count_in_period) AS mobile_recordings,
       sum(billable_feature_flag_requests_count_in_period) AS billable_flag_requests,
       sum(survey_responses_count_in_period) AS survey_responses,
       sum(exceptions_captured_in_period) AS exceptions,
       sum(ai_event_count_in_period) AS ai_events,
       sum(ai_credits_used_in_period) AS ai_credits,
       sum(rows_synced_in_period) AS dwh_rows_synced,
       sum(free_historical_rows_synced_in_period) AS dwh_free_backfill_rows,
       sum(rows_exported_in_period) AS rows_exported,
       sum(cdp_billable_invocations_in_period) AS cdp_invocations,
       sum(workflow_billable_invocations_in_period) AS workflow_invocations,
       sum(workflow_emails_sent_in_period) AS workflow_emails,
       sum(logs_mb_in_period) AS logs_mb
FROM billing_usage_by_org_date
WHERE organization_id = '<ORG_ID>'
  AND date >= today() - <days>
LIMIT 1
```

`days_reported` against `<days>` is this query's own built-in check on the second trap.

Daily form for spike and trend work: add `date`, `GROUP BY date`, `ORDER BY date DESC`.

## usage-dashboard

**An opportunistic shortcut, never a required read and never something to plan around.** Dashboard **1397076** in project 2 is a set of `postgres.prod.billing_usagereport` insights parameterized on a single `organization_id` variable, and `dashboard-insights-run` will run every tile against any org you name: events, identified persons, recordings, billable flag requests, exceptions, CDP and workflow invocations, and data-warehouse rows, at daily and weekly grain.

**How much of that arrives is unreliable and varies run to run, all-null included**, because it turns on server-side load at that moment rather than on the org or the call. Take whatever fills as a free head start and route everything still null to its own query. Nothing downstream may depend on it: the daily series a run actually needs is `per-product-usage` plus the `change-point` per-team read.

```
call dashboard-insights-run {"id": 1397076, "refresh": "force_cache", "variables_override": {"019520c8-451d-0000-2744-bda3fdd29d02": {"code_name": "organization_id", "variableId": "019520c8-451d-0000-2744-bda3fdd29d02", "value": "<ORG_ID>"}}}
```

Five rules for reading whatever it does return:

- **Use `force_cache`, never `blocking`**, which times out on this dashboard. `force_cache` does NOT serve another org's stale numbers when an override is present; it recalculates per override.
- **Call it twice, then stop.** Tiles that time out return `result: null` and the server caches them as it finishes, so a second identical call can fill some in. Every tile null on both calls is a normal outcome, not a sign the override is wrong.
- **A `null` result is UNMEASURED, never zero, however many times you call.** Route every still-null product to its own query rather than reporting an absence.
- **Cross-check one figure against `per-product-usage` before trusting the set**, the same way every other borrowed number in this skill earns its place.
- **The variable id is dashboard state and can change.** If the override silently does nothing, read the current `variableId` and `code_name` off `dashboard-get` for this dashboard and use those. Note the parameter is `variables_override`; `filters_override` is a different thing and will not carry an org.

## change-timeline

**Run every time, before any recommendation is written.** One dated list of everything the customer changed themselves, newest first. It is an assembly of reads this file and its siblings already own, not a new query set: nothing else puts them on one axis, and separately none of them reads as a decision.

The failure it prevents: a customer who has already fixed the thing they wrote in about still shows the old numbers everywhere that matters, because the last invoice is historical, the limits map shows the cap not the usage under it, and a 30-day total averages across the change. Recommending a fix they already shipped proves nobody looked.

Assemble from five sources, each already defined:

| Source | What it contributes | Where |
|---|---|---|
| `billing-limit-updates` | every limit move with its actor, product and amount | this file |
| The daily per-product series | the date each volume moved, and by how much | `change-point`, via its scratchpad file |
| `chat with ai` prompt text | the customer's own words: what they were trying to do, in sequence | `queries-products.md`, `posthog-ai-chat` |
| `docs-viewed` | what they were working out unaided, and who | this file |
| `team-config` | the settings as they stand now, which is the outcome of the above | `queries-products.md` |

Then look for the org's other setting-change events, rather than assuming `billing limits updated` is the only one: rank the org's own admin events from `discovery` and read any name that records a change. Event names here move, so enumerate rather than trusting a list.

Read it as a narrative and write the narrative down: a limit raised four times then lowered is somebody managing a cap by hand; a docs page read six times by one person beside a config that never changed is somebody stuck; a volume cliff with no limit behind it is a deploy nobody told us about. Each of those is a different opening line.

Two rules for what comes out of it. Anything on this timeline is **confirmation, never recommendation** (the disqualifier in `levers.md` owns that judgment). And the timeline reports the effect and its date; it never asserts the cause, which lives in code this skill cannot read, so an unexplained step change becomes the question to ask rather than a finding to state.

## onboarding-state

Where the account sits in the pipeline and how healthy it is, with "never onboarded" said out loud instead of implied.

```sql
SELECT a.name AS account,
       if(isNull(o.org_id), 'never entered onboarding', 'in onboarding_accounts') AS onboarding_membership,
       o.pipeline_stage AS pipeline_stage, o.os_priority AS os_priority,
       o.onboarding_specialist AS onboarding_specialist, o.temporary_owner AS temporary_owner,
       o.days_since_last_messaged AS days_since_last_messaged, o.next_renewal AS next_renewal,
       o.credit_days_left AS credit_days_left, o.usage_drop_flag AS usage_drop_flag,
       o.stripe_mrr AS stripe_mrr, o.forecasted_mrr AS forecasted_mrr, o.mrr_segment AS mrr_segment,
       o.admin_emails_csv AS admin_emails_csv, o.paid_invoices AS paid_invoices,
       h.health_score AS posthog_health_score, h.engagement_health AS engagement_health,
       h.stickiness AS stickiness, h.n_products AS n_products,
       h.e_product_analytics AS e_product_analytics, h.e_session_replay AS e_session_replay,
       h.e_experiments AS e_experiments, h.e_error_tracking AS e_error_tracking,
       h.e_surveys AS e_surveys, h.e_llm_analytics AS e_llm_analytics,
       h.e_logs AS e_logs, h.e_posthog_ai AS e_posthog_ai
FROM accounts_replacement_v2 AS a
LEFT JOIN onboarding_accounts AS o ON o.org_id = a.organization_id
LEFT JOIN account_health_scores AS h ON h.org_id = a.organization_id
WHERE a.organization_id = '<ORG_ID>'
LIMIT 1
```

Both tables key on **`org_id`**, not `organization_id`, and both hold one row per org, so neither join fans out. `account_health_scores` covers both regions: `health_score`, `engagement_health`, `stickiness`, `n_products`, and an `e_<product>` engagement score per product, where a null `e_` column is a product they do not run.

**`account_health_scores.health_score` is not Vitally's health score, despite the name**, so it is aliased `posthog_health_score` here and never fills the header. It is PostHog's own model, scoring engagement and stickiness across PostHog products, and the two disagree on the same account. Its real value is the `e_<product>` columns and `n_products`, which say which products they actually run. Quote it as a PostHog engagement score, never as "their health score". `onboarding_accounts` carries the pipeline view: `os_priority`, `pipeline_stage`, `admin_emails_csv` (the names to write to), `usage_drop_flag`, `credit_days_left`, and `stripe_mrr`.

**`onboarding_accounts` holds only accounts that entered onboarding, so a miss means never onboarded, not missing data.** Driving from `accounts_replacement_v2` is what keeps that legible: the row always comes back, health scores still populate, and `onboarding_membership` states which case it is.

**Test membership with `isNull(o.org_id)`.** A missed LEFT JOIN reads NULL here, and `o.org_id = ''` returns false against it, so the empty-string test reports an account as onboarded when it never was. For the same reason do not coalesce the onboarding columns to 0: a genuine `os_priority` of 0 and an absent row are both live shapes, and collapsing them makes an account that was never onboarded look like a deprioritized one.

## self-driving-check

Run always; cheap and it maps the account onto the company direction. Buckets: PostHog AI chat, Inbox, Scouts/signals, PostHog Code, MCP. Human-action events (`Inbox viewed`, `Scout fleet viewed`, `Task viewed`) = admins engaging; machine events (`signals_scout_run_started`, `signal_emitted`, `pr_created`) = the automation actually running for them. Zero across all buckets on an AI-native account is the self-driving adoption pitch (see `levers.md`). This detects usage only; Inbox report CONTENT is not readable from project 2.

The org usage report carries the credit side of the same story: `ai_credits_used_in_period` (PostHog AI), `posthog_code_credits_used_in_period` (PostHog Code / Desktop), `signals_credits_used_in_period` (Scouts and signals), all org+team, credits/day. **This is the only per-account measure of self-driving adoption available in project 2.** All three at 0 means the org has not touched the self-driving product line, which is an outreach hook rather than a cost finding.

**Match event-name prefixes with `startsWith()`, never `ILIKE`.** Two traps, both live in the MCP bucket, and they push the count in opposite directions so they do not cancel out. The real MCP events come in a dollar-prefixed set (`$mcp_initialize`, `$mcp_tools_list`, `$mcp_tool_call`) beside the bare ones (`mcp_initialize`, `mcp_tool_call`), and the dollar-prefixed set outweighs the bare one, so a pattern anchored at `mcp_` alone is blind to the larger half and undercounts events. Meanwhile `_` is a single-character wildcard in LIKE, so `ILIKE 'mcp_%'` also swallows the hint banner (`mcp hint shown`, `mcp hint dismissed`), which is an impression rather than usage, and every admin who merely saw the banner inflates the user count. Escaping is not the way out: `ILIKE 'mcp\_%'` errors with "unrecognised escape". `startsWith()` fixes both at once, and it drops the space-named hint events for free, since a space is not an underscore. It is case-sensitive, which is correct here: `Inbox`, `Scout`, and `Signal source connected` are capitalized, `signal_` and `signals_` are not.

**The `mcp` bucket counts connections, not work, so never quote it as usage on its own.** `$mcp_initialize` and `$mcp_tools_list` fire on every handshake and dominate the count, far above the queries anyone actually ran. `$mcp_tool_call` is the middle signal and `query executed` with `source = 'mcp'` (`query-usage`) is the depth one, so read the bucket for reach and that column for whether anyone did anything. Two more things to look out for rather than assume: the prefix also catches `mcp_store`, `mcp_gateway` and `mcp_ui_app_` events, which are separate products and not the customer querying PostHog, and several real MCP actions are space-named (`mcp project switched`, `mcp organization switched`, `mcp feedback submitted`) so they fall outside it entirely. Check what the account actually emits before reading the bucket as a total.

```sql
SELECT multiIf(event IN ('$conversations_loaded','max conversation turn completed','chat with ai'), 'posthog_ai_chat',
               startsWith(event, 'Inbox'), 'inbox',
               startsWith(event, 'Scout') OR startsWith(event, 'signals_') OR startsWith(event, 'signal_')
                 OR event = 'Signal source connected', 'scouts_signals',
               event IN ('pr_created','pr_merged','task_created','Task viewed'), 'posthog_code',
               startsWith(event, 'mcp_') OR startsWith(event, '$mcp_'), 'mcp', 'other') AS bucket,
       count() AS events, count(DISTINCT person.properties.email) AS users, max(timestamp) AS latest
FROM events
WHERE $group_0 = '<ORG_ID>' AND timestamp >= now() - INTERVAL <days> DAY
  AND (event IN ('$conversations_loaded','max conversation turn completed','chat with ai','pr_created','pr_merged',
                 'task_created','Task viewed','Signal source connected')
       OR startsWith(event, 'Inbox') OR startsWith(event, 'Scout') OR startsWith(event, 'signals_')
       OR startsWith(event, 'signal_') OR startsWith(event, 'mcp_') OR startsWith(event, '$mcp_'))
GROUP BY bucket ORDER BY events DESC LIMIT 10
```

An `other` bucket in the result means the WHERE and the `multiIf` have drifted apart: every arm of one has a twin in the other, so a row that matched the filter but no bucket is the tell that a new event slipped between them.

## query-usage

How they pull data out, and usually the highest-volume admin event on the account. `source` is the column that matters: `web` (the UI), `api`, `mcp`, `posthog_ai`, plus `terraform`, `cli`, `wizard`, `alert`, `export`, `subscription`. It says whether this account drives PostHog by clicking or by machine, and an `api` or `mcp` majority is the agentic-adoption tell that pairs with `self-driving-check`. Exclude `cache_warming`: it is PostHog pre-warming their caches, not a person querying.

```sql
SELECT person.properties.email AS email, count() AS queries,
       countIf(properties.source = 'web') AS via_web,
       countIf(properties.source = 'api') AS via_api,
       countIf(properties.source = 'mcp') AS via_mcp,
       countIf(properties.source = 'posthog_ai') AS via_posthog_ai,
       arrayStringConcat(topK(3)(toString(properties.query_type)), ', ') AS top_query_types,
       countIf(properties.has_error = true) AS errors,
       max(timestamp) AS latest
FROM events
WHERE event = 'query executed' AND $group_0 = '<ORG_ID>'
  AND timestamp >= now() - INTERVAL <days> DAY AND person.properties.email IS NOT NULL
  AND coalesce(toString(properties.source), 'unknown') != 'cache_warming'
GROUP BY email ORDER BY queries DESC, email LIMIT 25
```

`query_type` names the query kind (`HogQLQuery`, `TrendsQuery`, `FunnelsQuery`, `ExperimentQuery`, ...), so a `HogQLQuery` majority means they write SQL and a `TrendsQuery` majority means they build insights in the UI. Two different conversations.

## seat-roster

Who has a seat and who uses it. Region-agnostic, and the only roster that works on EU.

Built on `organization usage report per person`, the per-person twin of the org usage report: it fires daily per member, carrying `org_membership_level` (`owner` / `administrator` / `member`), `role_at_organization`, and `has_non_zero_usage`. Filter `scope = 'user'`; a `machine` scope also exists and is rare.

**`has_non_zero_usage` does not reliably separate a held seat from a used one, so never quote it as an active-user count.** It splits both ways across PostHog as a whole, but on a given account it can read `true` for every member including people who did almost nothing all month. Get real activity from `top-users` instead, and subtract the machine floor described next.

**This event is itself a floor under every per-person event count.** It fires once per member per day, so a 30-day `top-users` read carries ~30 events per person that nobody generated. On a low-engagement account that floor is most of what a dormant seat appears to do, so subtract it before ranking contacts or calling anyone active.

This fills a gap the postgres mirror cannot. **`postgres.posthog_organizationmembership` returns zero rows for an EU org**, so `org-membership` has no roster there; this event does, because every org's usage report lands in project 2 regardless of region. Use `org-membership` on US accounts when you also want `last_login` and `date_joined`, which this event does not carry.

```sql
SELECT person.properties.email AS email,
       argMax(properties.org_membership_level, timestamp) AS membership_level,
       argMax(properties.role_at_organization, timestamp) AS role,
       argMax(properties.has_non_zero_usage, timestamp) AS active_last_report,
       max(timestamp) AS latest_report
FROM events
WHERE event = 'organization usage report per person' AND $group_0 = '<ORG_ID>'
  AND timestamp >= now() - INTERVAL 8 DAY AND properties.scope = 'user'
  AND person.properties.email IS NOT NULL
GROUP BY email
ORDER BY multiIf(membership_level = 'owner', 1, membership_level = 'administrator', 2, 3),
         active_last_report DESC, email
LIMIT 60
```

The 8-day window is fixed on purpose: it catches one daily report per person, and `argMax` keeps the latest. A large org overruns the LIMIT, and the ORDER BY is built so the truncation drops members first and never the owners and admins, which are the names you write to.

## org-membership

Who the owners and admins are, with `last_login` and `date_joined`. US accounts only (see `seat-roster` for EU).

Swap every table in this query or none (the half-swap rule in `data-rules.md`): `user_id` collides across regions exactly like `team_id`, and a half-swapped join returns strangers from other companies wearing this account's roles, with no error, ending in an email to the wrong person. `org_id` is in the SELECT to make that visible: check the returned org id before using a name.

Filter `u.is_active`: deactivated users stay in the membership table. Keep the limit above the org's member count, or the roster silently truncates; enterprise accounts run to hundreds.

```sql
SELECT m.organization_id AS org_id, u.email,
       CASE m.level WHEN 15 THEN 'owner' WHEN 8 THEN 'admin' WHEN 1 THEN 'member' ELSE toString(m.level) END AS role,
       concat(u.first_name, ' ', u.last_name) AS full_name, u.is_active, u.last_login, u.date_joined
FROM postgres.posthog_organizationmembership m JOIN postgres.posthog_user u ON m.user_id = u.id
WHERE m.organization_id = '<ORG_ID>' AND u.is_active
ORDER BY m.level DESC, u.last_login DESC LIMIT 200
```

## Vitally warehouse

PostHog syncs the full Vitally CRM into the warehouse, queryable from project 2. Ten objects, each existing under both namings (`vitally.accounts` and `vitally_accounts` are one physical table). Run `account-context` and `touchpoint-timeline` for EVERY account: they are the CRM context, they take the PostHog org id directly, and they replace the MCP `get_account_notes` / `get_account_tasks` calls that overflow on large accounts.

Join path: **`vitally.accounts.external_id = '<ORG_ID>'`**, populated and distinct on every row, strictly 1:1. **`vitally.accounts.organization_id` is NULL on every row**, so the obvious join returns nothing, silently. Never match on name: several accounts share one.

| Object | Account link | Freshness | Notes |
|---|---|---|---|
| `vitally.accounts` | **`external_id` = the PostHog org id** | fresh | health, MRR, renewal, NPS, segments, key roles, traits. `organization_id` is NULL on every row |
| `vitally.notes` | `account_id` | fresh | `note` is the body, HTML |
| `vitally.tasks` | `account_id` | fresh | open tasks have a null `completed_at`; `name` is JSON, wrap in `toString` |
| `vitally.projects` | `account_id` | **frozen, do not read** | nothing created or updated for months. Dropped from `touchpoint-timeline` for that reason |
| `vitally.custom_object_featurerequest` | **`customers` array** | fresh | `customer_id` holds only the primary account and silently misses the rest |
| `vitally.conversations` | **none** | fresh | no account or org column of any kind: `external_id` is null, `traits` holds only channel metadata |
| `vitally.messages` | **none** (`from` / `to` hold user ids) | fresh | the conversation bodies; scope by `conversation_id` |
| `vitally.nps_responses` | **none** (`user_id` only) | fresh but **duplicated** | append-only rather than upsert: one `id` versioned by `updated_at`. Dedupe with `ORDER BY updated_at DESC LIMIT 1 BY id` |
| `vitally.users` | `accounts` JSON array only | **stale, days behind** | avoid, see below |
| `vitally.custom_objects` | definitions only | fresh | the custom-object schema, not customer data |

**`vitally.users` is this section's one hard constraint, and the rule is standalone only.** A full scan is slow regardless of predicate, because the cost is the table scan itself rather than the predicate: `users.accounts[]` embeds a full copy of each account including its large `traits` blob. **Standalone it does return**, which is what makes the mandatory `sibling-sweep` viable. **Joining it to another table exceeds the timeout**, so it stays out of `account-context` and `touchpoint-timeline`, and it is the only warehouse path from an account to `conversations` and to `nps_responses`, which is why neither is reachable per account in a single read. The one sanctioned join is `nps-verbatims`, which is best-effort by design: it often times out, and re-running it hits the cache. Its embedded account copy is stale besides, so never read account fields out of it. `users` has no `account_id` column at all, only `accounts`.

**Trait keys are inconsistent, so confirm the key before trusting the value.** Some are snake_case (`usage_mrr`, `forecasted_usage_mrr`), others are dotted (`stripe.accountBalance`, `stripe.metadata.credit_discount_percent`, `vitally.custom.purchasedCreditAmount`). A wrong key returns 0.0 or an empty string silently, so a missing trait and a real zero look identical.

Prefer **UNION ALL with a `source` column** over a wide JOIN for the one-to-many objects. The naive three-way JOIN fans out and repeats the whole large account blob on every row, for information the UNION returns intact.

The CS views (`get_vitally_org_v2`, `csm_hud_notes`, `csm_hud_tasks`, `org_user_counts_by_vitally`) exist but are stale partial snapshots: read the live tables instead.

If a query errors, confirm columns with `information_schema.columns` (the Vitally sync schema can drift).

## account-context

Who this account is: the account row, its key roles, and its feature requests, in one read that takes the org id and never needs the Vitally account id resolved first.

**`account-context` and `touchpoint-timeline` split by question, and neither repeats the other.** This one is the durable state: identity, money, NPS, segments, ownership, and what they have asked for. The timeline answers what happened and when. Run both.

NPS comes from `vitally.accounts`, not from `nps_responses`: the account row carries `nps_score`, `nps_promoter_count`, `nps_passive_count`, and `nps_detractor_count` natively, fresh, at no join cost, and this query folds all four in. Read them right: the counts reflect each user's latest response rather than a response count, and `nps_score` is null (not zero) for an account nobody has ever answered for.

```sql
SELECT * FROM (
  SELECT 'account' AS source,
         parseDateTimeBestEffort(coalesce(updated_at, '1970-01-01T00:00:00Z')) AS ts,
         name AS title,
         concat('MRR=', toString(mrr),
                ' | renewal=', coalesce(next_renewal_date, 'none'),
                ' | users=', toString(users_count),
                ' | NPS=', toString(nps_score),
                ' (p/pa/d=', toString(nps_promoter_count), '/', toString(nps_passive_count), '/', toString(nps_detractor_count), ')',
                ' | last_in=', coalesce(last_inbound_message_timestamp, '-'),
                ' | last_out=', coalesce(last_outbound_message_timestamp, '-'),
                ' | churned=', coalesce(churned_at, 'no')) AS detail,
         arrayStringConcat(arrayMap(s -> JSONExtractString(s, 'name'),
                JSONExtractArrayRaw(coalesce(toString(segments), '[]'))), ', ') AS meta
  FROM vitally.accounts
  WHERE external_id = '<ORG_ID>'

  UNION ALL
  SELECT 'keyrole',
         parseDateTimeBestEffort(coalesce(JSONExtractString(kr, 'assignedAt'), '1970-01-01T00:00:00Z')),
         JSONExtractString(JSONExtractRaw(kr, 'keyRole'), 'label'),
         coalesce(nullIf(JSONExtractString(JSONExtractRaw(kr, 'vitallyUser'), 'email'), ''), '(unassigned)'),
         JSONExtractString(JSONExtractRaw(kr, 'vitallyUser'), 'name')
  FROM vitally.accounts
  ARRAY JOIN JSONExtractArrayRaw(coalesce(toString(key_roles), '[]')) AS kr
  WHERE external_id = '<ORG_ID>'

  UNION ALL
  SELECT 'featurerequest', parseDateTimeBestEffort(coalesce(fr.created_at, '1970-01-01T00:00:00Z')), fr.name,
         substring(toString(fr.description_body), 1, 120),
         concat('state=', JSONExtractString(coalesce(toString(fr.traits), '{}'), 'state'))
  FROM vitally.custom_object_featurerequest AS fr
  WHERE arrayExists(x -> JSONExtractString(x, 'id') IN (
          SELECT id FROM vitally.accounts WHERE external_id = '<ORG_ID>'
        ), JSONExtractArrayRaw(coalesce(toString(fr.customers), '[]')))
)
ORDER BY source = 'account' DESC, ts DESC
LIMIT 40
```

The `ORDER BY source = 'account' DESC` pins the account row to the top and sorts everything else newest first. Row counts match the base tables per `source` with no fan-out. `keyrole` is where the **Onboarding Specialist** shows up, and a role defined but not filled reads `(unassigned)` rather than going missing. A feature-request-heavy account can still fill the LIMIT: raise it, or read `source` by `source`, when you need the tail.

**Health is deliberately absent here, do not add it back.** `vitally.accounts.health_score` is a warehouse copy of Vitally's score and it drifts, because the score recomputes continuously while the sync does not. The header takes health from `get_user_details`, so this query does not compete with it. Every other field here (MRR, renewal, users, NPS) matches the live API, which is why they stay.

## touchpoint-timeline

What happened with this customer and when: notes and tasks in one chronological list with a `source` column. Fixed 180 day window: touchpoints are sparse, and the closing note below says what an empty result means.

```sql
WITH a AS (
  SELECT id AS aid FROM vitally.accounts WHERE external_id = '<ORG_ID>'
)
SELECT * FROM (
  SELECT 'note' AS source,
         n.note_date AS ts,
         coalesce(n.subject, '(no subject)') AS title,
         substring(replaceRegexpAll(coalesce(n.note, ''), '<[^>]*>', ' '), 1, 220) AS detail,
         coalesce(nullIf(JSONExtractString(coalesce(toString(n.author), '{}'), 'email'), ''), '(system)') AS who
  FROM vitally.notes AS n
  WHERE n.account_id IN (SELECT aid FROM a) AND n.archived_at IS NULL

  UNION ALL
  SELECT 'task', t.created_at, toString(t.name),
         substring(replaceRegexpAll(coalesce(t.description, ''), '<[^>]*>', ' '), 1, 220),
         concat(coalesce(nullIf(JSONExtractString(coalesce(toString(t.assigned_to), '{}'), 'email'), ''), '(unassigned)'),
                ' | due=', coalesce(t.due_date, '-'),
                ' | ', if(t.completed_at IS NULL, 'OPEN', 'done'))
  FROM vitally.tasks AS t
  WHERE t.account_id IN (SELECT aid FROM a) AND t.archived_at IS NULL
)
WHERE ts > now() - INTERVAL 180 DAY
ORDER BY ts DESC
LIMIT 40
```

Four notes on reading it. `replaceRegexpAll(..., '<[^>]*>', ' ')` strips the HTML Vitally stores in `note` and `description`, which otherwise burns most of the character budget on markup. Messages are deliberately absent: they need `users`, which puts the query over the timeout every time. Projects are absent too, because that table is frozen (see the object table above) and mixing frozen rows into a fresh timeline reads as activity that did not happen. Repeated identical rows are real, not a join artifact: Vitally writes same-second twin tasks of its own accord. Dedupe on title plus timestamp at read time if they are noise, but never with `SELECT DISTINCT`, which would also hide real repeat activity. And this query is the only read of notes, tasks, and projects, so **an empty result means no touchpoint inside 180 days, not no history**: widen the window before concluding an account was never worked.

**There is no separate notes or tasks query.** This one covers both, keyed on the org id rather than the Vitally account id, so a standalone read of either is redundant.

## nps-verbatims

The only thing `nps_responses` adds over the account row's NPS fields is verbatim feedback text, and reaching it per account means going through `users`, so run it standalone only when a verbatim is actually wanted. Optional and slow (it often times out; a re-run hits the cache), and dedupe it as below.

```sql
WITH u AS (
  SELECT id AS uid, email FROM vitally.users
  WHERE like(toString(accounts), '%"id":"<VITALLY_ACCOUNT_ID>"%')
)
SELECT n.score, n.feedback, u.email, n.responded_at
FROM (SELECT * FROM vitally.nps_responses ORDER BY updated_at DESC LIMIT 1 BY id) AS n
INNER JOIN u ON u.uid = n.user_id
ORDER BY n.responded_at DESC
```

## conversation-bodies

Always run. **Read the account row, not the conversations table**: `vitally.conversations` has no account link, so the warehouse-side path runs through `users` and times out more often than not. The account row already answers the recency question, fresh, via `last_inbound_message_timestamp` and `last_outbound_message_timestamp`, both in `account-context`. For bodies, get the account's conversation ids from the MCP `get_account_conversations(accountId)` (already account-scoped, with `source` + `subject`, and no `users` scan), then pull bodies in one query.

`message` is the body (HTML, strip tags); `type` is inbound (customer) or outbound (staff), but it is unreliable on Slack and Zapier-sourced threads, where every message can read `inbound` including ones plainly from PostHog staff. Do not trust `type` alone: read the sender and the body to tell customer from staff, and never route a mode on `type` for a `source` of `slack` or `zapier`. This query is more reliable than the Vitally REST single-GET, whose body field is `messages[].message` (not `.body`, the usual cause of "bodies look empty") and whose large HTML payloads are easy to mis-parse.

```sql
SELECT conversation_id, type, timestamp, substring(message, 1, 600) AS body
FROM vitally.messages
WHERE conversation_id IN ('<id1>','<id2>', ...)
ORDER BY conversation_id, timestamp LIMIT 100
```

Four rules for this table: (1) the batch above is a survey pass; cap it at the ~6 most recent conversations, since pulling every thread on a chatty account overflows the response even with short bodies. (2) Before drafting a follow-up or reply, re-pull the latest inbound and latest outbound with NO substring; the draft is built on those two and truncation cuts recommendations mid-sentence. (3) `timestamp` is a String; compare as a string (`timestamp >= '2026-07-08'`), never `toDateTime(...)`. (4) If the batch query throws a bytes-serialization error, one thread carries a bad row: split the query by `conversation_id` to isolate and skip it.

`vitally.messages.from` / `to` are JSON `{id, type}`, where `user` = customer and `admin` = PostHog staff. Do not build a fully warehouse-side account-to-messages chain: the only link runs through `vitally.users`, which is the timeout described above.

**The warehouse syncs hours behind, so check freshness before trusting it**: compare `vitally.accounts.last_outbound_message_timestamp` against `lastOutboundMessageTimestamp` from the MCP `get_user_details`. When they disagree, or when a conversation's `createdAt` is inside the last 24 hours, `vitally.messages` has no rows for it yet and REST is the only path to the body.

The REST single-GET: `AUTH=$(printf '%s:' "$VITALLY_API_KEY" | base64); curl -s "https://rest.vitally-eu.io/resources/conversations/<id>" -H "Authorization: Basic $AUTH"`, which exposes `messages` (body in `.message`), `accounts`, `admins`, and `users`. The trailing colon in `printf '%s:'` is the empty password Basic auth needs; without it the request 401s.
