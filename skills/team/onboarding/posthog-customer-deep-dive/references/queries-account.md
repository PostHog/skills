# Queries: account core

Step 1 resolution, the always-run core, and the Customer Analytics reads. Conventions, ids, regions, and the source rules live in `data-rules.md`; this file's headings are its index.

## sibling-sweep

Step 1, every account with a domain. Run BOTH queries below, because they see different populations. The members query reads the daily per-person usage report, so it finds every org where anyone with the domain holds a seat, in both regions, admin or not; an org whose people carry no email on their person record drops out of it. The `billing_customer` query catches those by admin email, including free orgs and orgs whose sole admin also admins the paying org, which is exactly the consolidation story the sweep exists to find. Neither alone is complete.

Then look each org id up in `system.accounts` (`external_id`), in one grouped read. **An org the sweep finds with no Customer Analytics account is still a sibling**: report it, and never read the missing account as a missing org.

```sql
SELECT $group_0 AS posthog_org_id, count(DISTINCT person.properties.email) AS users,
       groupUniqArray(10)(person.properties.email) AS sample_emails
FROM events
WHERE event = 'organization usage report per person' AND timestamp >= now() - INTERVAL 8 DAY
  AND properties.scope = 'user' AND person.properties.email ILIKE '%@<domain>'
GROUP BY posthog_org_id ORDER BY users DESC LIMIT 20
```

```sql
SELECT id AS billing_customer_id, name, organization_id, admin_emails
FROM postgres.prod.billing_customer
WHERE toString(admin_emails) ILIKE '%@<domain>%' ORDER BY name LIMIT 30
```

`admin_emails` is `Nullable(String)`, not an array, so match it with `ILIKE` and never with `arrayExists`, which errors with `Argument 2 of function arrayExists must be Array`. **An admin on a public provider (gmail.com, outlook.com and the like) is invisible to a domain search**, so run the second query once more with that admin's full address in place of `@<domain>`: that is how a second org run by the same person turns up. Filter out unrelated orgs that merely share one domain user (a single-user org named nothing like the account is usually noise, not a duplicate).

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

**`api_token` is selected here because Round 1a batch 2b hands each surface's `site-scan` every token it might carry.** It is also what settles the token-to-team mapping later without a second query: a scan finds a `phc_...` token in a bundle, and this result says which project it belongs to. A token the scan finds that this result does not return belongs to another org: look it up (`SELECT organization_id, id AS team, name FROM all_posthog_team WHERE api_token IN (...)`) and add that org to the siblings, because a marketing site an agency runs sends its events to the agency's org, which no sweep by admin domain finds. Deriving that mapping from domain names instead is unreliable, because one team's token routinely serves several hosts and team names do not track products. If the column is missing on a region's view, fall back to `postgres.posthog_team` / `eu_postgres_posthog_team` for it, all-or-nothing per the region rule.

Scope by `organization_id`, never by a bare team id (the collision rule in `data-rules.md`, "What we can and cannot see"); an org's own `(org, team)` pairs are unique, so this query returns each of its teams once.

Read the team names before picking a project: they carry the production / staging / demo / deprecated split in plain text. **Treat the names as a hint and never as the answer**, because one team's token routinely serves several hosts and the names do not track products. Measured on a multi-brand account, 2026-08-19: one team was named after a single storefront and served only that storefront, while a blandly named team beside it carried the main store AND a second brand's point-of-sale AND a third white-label tenant, all behind one token. Confirm which is production by volume from the org usage report's per-team `teams` map, which main reads with `org-snapshot` in batch 2a and writes to the context file; `change-point` publishes the daily per-team series to `<run scratchpad>/daily-by-team.md`.

## customer-hosts

Where the customer's own product actually runs, from the hosts on their own events. Round 1a batch 2b, on the direct connection (`scripts/phq.py ch-us` or `ch-eu`), once `resolve-teams` has the team ids. The admin email domain is often an agency, a parent company or a marketing site, and the product lives somewhere else. **Run both reads in one batch**: seven days of pageviews for reach, and one day of every event for an app that has pageviews turned off.

```sql
SELECT team_id AS team, domain(JSONExtractString(properties, '$current_url')) AS host, count() AS pageviews,
       topK(8)(splitByChar('/', path(JSONExtractString(properties, '$current_url')))[2]) AS first_paths,
       max(timestamp) AS latest
FROM events
WHERE team_id IN (<TEAM_IDS>) AND event = '$pageview' AND timestamp >= now() - INTERVAL 7 DAY
GROUP BY team, host ORDER BY pageviews DESC LIMIT 10 BY team LIMIT 100
```

```sql
SELECT team_id AS team, domain(JSONExtractString(properties, '$current_url')) AS host, count() AS events,
       topK(8)(splitByChar('/', path(JSONExtractString(properties, '$current_url')))[2]) AS first_paths,
       max(timestamp) AS latest
FROM events
WHERE team_id IN (<TEAM_IDS>) AND timestamp >= now() - INTERVAL 1 DAY
  AND JSONExtractString(properties, '$current_url') != ''
GROUP BY team, host ORDER BY events DESC LIMIT 10 BY team LIMIT 100
```

The windows are what keep these under `ch-eu`'s ten-second ceiling: seven days of every event times out there on a busy team, and an app that disables pageviews (one sending 1.2M events a day showed 793 pageviews) only appears in the second read. Count the teams returned against the teams asked for: a team in neither result sent no browser traffic, which on a server-side or mobile team is the answer. Every host carrying real volume that is not on the domain already scanned gets its own `site-scan --url`, and so does a recurring `first_paths` value that is a sub-app rather than a route (`/app/`, `/tpai/`, not ids or `/file/`). A host that belongs to a sibling org is that org's surface: scan it as a sibling finding. An empty host is server-side or mobile traffic, or a web app sending a relative `$current_url`; a large empty-host pageview count is the second, so read its `$pathname` before calling it server-side.

## discovery

Run every time. Shows the full event mix; scan the result for unfamiliar high-volume events. The AI and self-driving event names to recognize (PostHog AI chat, Inbox, Scouts/signals, PostHog Code, MCP) are enumerated in `self-driving-check` below, and the `$ai_*`, `mcp_*`, `react_framerate`, and `livestream_sse_*` families are PostHog's own app telemetry (staff and admins using PostHog), never the customer's product usage. `replay_vision_scan_completed` is a backend event carrying no email, so it reads like noise: it means Replay Vision is scanning and spending credits, and it routes to `replay-vision` in `queries-products.md`. If a new product appears, add a query for it in the owning file and note it.

```sql
SELECT team_id AS team, event, count() AS total_events
FROM events
WHERE timestamp >= now() - INTERVAL <days> DAY AND $group_0 = '<ORG_ID>'
GROUP BY team, event ORDER BY total_events DESC LIMIT 200
```

**Exactly 200 rows back means truncated, not complete**, and an org with a few hundred admin event names fills it. `team` reads 2 on every row: these are their admins in the PostHog app, never their product. Re-run the tail before concluding an event is absent (on the MCP: `OFFSET 198` with a larger LIMIT; on the personal-API-key path OFFSET is rejected with HTTP 400, so use `HAVING total_events <= <200th row's count>` or keyset paging on the ranking column instead); the tail is where a new product first shows up.

## account-state

The unified `billing_customer` snapshot, cross-checked against `onboarding-state`, which carries the same money from v8. Extract: `billing_period_ends`, `plans_map`, `custom_limits_map`, `admin_emails`, `organization_users`, `internal_notes`, `amount_off`, `percent_off`, `account_executive_id`, `metadata`. `crm_segments` and `sales_info` are left out on purpose: they are a frozen copy of the retired CRM's segments (the retired-sources guard in `data-rules.md`).

```sql
SELECT bc.name, bc.billing_period_starts, bc.billing_period_ends, bc.subscription_start_date,
       bc.plans_map, bc.custom_limits_map, bc.admin_emails,
       bc.organization_users, bc.internal_notes, bc.amount_off, bc.percent_off, bc.account_executive_id, bc.metadata
FROM postgres.prod.billing_customer bc WHERE bc.organization_id = '<ORG_ID>' LIMIT 1
```

## org-snapshot

The latest org usage report in one row, which is one UTC day (a weekend day understates a weekday business: read `per-product-usage` for typical volume). Every `*_in_period` field on this event covers ONE UTC DAY, not a month, and `properties.date` is that day's label even though it prints with a Pacific offset, so read its date part only; the reading rules and the full field dictionary are in the `queries-products.md` shared intro.

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
       argMax(properties.ios_events_count_in_period, timestamp) AS ios_events,
       argMax(toString(properties.teams), timestamp) AS teams_map
       -- add argMax(properties.<field>, timestamp) for every other field this account implicates (comma-separate them before teams_map).
       -- Per-SDK keys follow <sdk>_events_count_in_period (web, node, python, php, ruby, go, java, rust, dotnet, elixir, react_native, flutter, ios, android, unity, edge, convex, openclaw), plus mcp_tool_call_, posthog_ai_ and posthog_pi_events_count_in_period; enumerate the live keys with JSONExtractKeys(properties) rather than trusting this list, and read the field dictionary in queries-products.md
FROM events
WHERE $group_0 = '<ORG_ID>' AND event = 'organization usage report'
  AND timestamp >= now() - INTERVAL 8 DAY LIMIT 1
```

**Use `argMax(field, timestamp)`, never `max(field)`.** `max()` takes each field's peak independently across the window and splices different days into one row that never existed: a peak-day event count next to a different day's recording count next to today's dashboard count. `argMax(field, timestamp)` pins every column to the single latest report. The 8-day window is deliberate (it survives a missed cron run), and the query is aggregate-only, so it always returns exactly one row. The org can also emit the same day's report several times as late data lands; `argMax` correctly takes the last one.

**`teams_map` comes back truncated at full width**, and `JSONExtractKeys` on the `argMax` errors on its Nullable type, so read it one row per team instead:

```sql
SELECT t AS team, JSONExtractInt(m, t, 'event_count_in_period') AS events,
       JSONExtractInt(m, t, 'heatmap_events_count_in_period') AS heatmaps,
       JSONExtractInt(m, t, 'mobile_billable_recording_count_in_period') AS mobile_billable_recordings
FROM (SELECT coalesce(toString(argMax(properties.teams, timestamp)), '{}') AS m
      FROM events
      WHERE event = 'organization usage report' AND $group_0 = '<ORG_ID>' AND timestamp >= now() - INTERVAL 8 DAY)
ARRAY JOIN JSONExtractKeys(m) AS t
LIMIT 100
```

Add a `JSONExtractInt(m, t, '<field>')` line for any other per-team field. Swap the window for `properties.date = toDate('YYYY-MM-DD')` to pin a specific day, or add `properties.date` plus `GROUP BY` for the daily series. Group on the report's own `date`, never on `toDate(timestamp)`: a report is sometimes emitted the day after the one it covers, which puts two reports on one day and leaves a gap the day before. A date can also carry two identical reports, so take one per date (`argMax(field, timestamp)` grouped on `properties.date`) and never `sum()` across reports, which doubles that day.

## top-users

```sql
SELECT person.properties.email AS email, person.properties.role_at_organization AS role,
       count(DISTINCT $session_id) AS session_count, count() AS total_events
FROM events
WHERE timestamp >= now() - INTERVAL <days> DAY AND $group_0 = '<ORG_ID>' AND person.properties.email IS NOT NULL
GROUP BY email, role ORDER BY session_count DESC LIMIT 15
```

One query covers both rankings: `session_count` is the engagement order, and re-sorting the same rows by `total_events` gives the volume order. Subtract the machine floor `seat-roster` describes before calling anyone active: a member with no sessions and a few dozen events did nothing.

## page-paths

Look for `/feature_flags`, `/replay`, `/surveys`, `/billing`, `/llm-analytics`, `/data-warehouse`, multiple `/project/<id>`.

**This one read also answers who watches the bill, so there is no separate billing query: group by path for the surface ranking, and read `surface = 'billing'` out of the same result.** Who watches the bill decides who a cost email is addressed to, and it is often not the person who booked the call. Empty is a real answer there only when the result came back under its row cap: nobody is looking at billing, so rank contacts by volume alone.

```sql
SELECT properties.$pathname AS path,
       person.properties.email AS email,
       multiIf(properties.$pathname LIKE '%/billing%', 'billing',
               properties.$pathname LIKE '%vision%', 'replay_vision',
               properties.$pathname LIKE '%/replay%', 'replay',
               properties.$pathname LIKE '%/feature_flags%', 'flags',
               properties.$pathname LIKE '%/error_tracking%', 'errors',
               properties.$pathname LIKE '%/surveys%', 'surveys',
               properties.$pathname LIKE '%/experiments%', 'experiments',
               properties.$pathname LIKE '%/inbox%', 'inbox',
               properties.$pathname LIKE '%/sql%', 'sql',
               properties.$pathname LIKE '%/dashboard%', 'dashboards',
               'other') AS surface,
       count() AS cnt, max(timestamp) AS latest
FROM events
WHERE $group_0 = '<ORG_ID>' AND event = '$pageview' AND timestamp >= now() - INTERVAL <days> DAY
GROUP BY path, email, surface ORDER BY surface, cnt DESC LIMIT 25 BY surface LIMIT 200
```

The `LIMIT 25 BY surface` keeps the low-count billing rows from falling off the end behind busy project pages.

The leading `%` on each pattern cannot be anchored away: the PostHog app nests these under `/organization/` and `/project/<id>/`, so `/billing%` matches nothing while `%/billing%` matches `/organization/billing`. Index pruning is lost either way, so keep the window tight rather than widening it here.

## docs-viewed

**Scope this one by EMAIL, never by `$group_0`, or it returns empty every time.** Docs pageviews on `posthog.com` carry no group, so the org filter every other query in this file uses matches nothing here and the empty result reads as "they never open the docs" when the truth can be hundreds of views. `<ADMIN_EMAILS>` is the admin emails from the context block, each single-quoted and comma-separated.

Anchor the path rather than searching the URL: `$pathname LIKE '/docs/%'` prunes on the index where `$current_url LIKE '%/docs/%'` is a full scan with a leading wildcard, and `/docs/` is top level so anchoring is safe here (unlike the app paths above).

```sql
SELECT person.properties.email AS email, properties.$pathname AS path,
       count() AS views, max(timestamp) AS latest
FROM events
WHERE event = '$pageview' AND timestamp >= now() - INTERVAL <days> DAY
  AND properties.$pathname LIKE '/docs/%'
  AND person.properties.email IN (<ADMIN_EMAILS>)
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

Cross-check the result against `custom_limits_map` on `account-state`, which carries the CURRENT limit per product including any zero. The product list above is a floor: a key the event carries that the list leaves out is dropped, so when `custom_limits_map` names a product missing here, read that key off the same events with `JSONExtractKeys(e.properties)`. A limit in that map with no matching row here predates the 120 day window, or was set at signup: a new org carries a default map of limits on the credit products, so on an org younger than the window, read it as the default rather than a choice anyone made.

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

The one row that says who this account is, what it pays and where it is hosted. `accounts_replacement_v2` is the account spine: keyed on `organization_id`, both regions, one row per org. People come from `account-roster`, never from here.

```sql
SELECT a.name AS account, r.region AS region, r.teams AS teams,
       a.mrr AS mrr, a.customer_stage AS stage, a.stripe_subscription_status AS sub_status,
       a.slack_channel AS slack_channel,
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

**No owner column is selected here, on purpose.** This view's owner fields are a Salesforce copy that disagrees with Customer Analytics, so the roster comes from `account-roster` below and nowhere else. Roster names are reported, never routed on (Step 4).

**Pre-aggregate the team side, as above, or the join fans out.** An org has many teams, so joining `all_posthog_team` on `organization_id` directly returns one row per team, each carrying a full copy of the same MRR. Nothing errors, the row just repeats, so any downstream sum multiplies the money by the team count. The grouped subquery makes the join one-to-one and hands back `teams` as a free count.

**`accounts_replacement_v2` has no region column: take region from `all_posthog_team.app_region`.** Never read `billing_country` as region. It is where the account pays from, not where its data is hosted, and the two disagree in both directions often enough to matter.

`groupUniqArray` rather than `min(app_region)`: an org can hold teams in both regions, and the array form shows `eu,us` where `min()` would silently report one. `mrr`, `effective_mrr`, and `sticky_mrr` are byte-identical copies of each other, so read one and ignore the other two. `ORDER BY a.mrr DESC LIMIT 1` is the dedup guard: a few org ids carry a second, empty record, and this keeps the populated one. `mrr` here is what PostHog books, not the invoice; the MRR rule is in `data-rules.md`, and the money reads are in `queries-money.md`.

## account-roster

Step 4, every account. Who holds each role on the account in Customer Analytics, current and past, with names and emails, in one read keyed on the org id.

```sql
SELECT d.name AS role, u.email AS email, concat(u.first_name, ' ', u.last_name) AS full_name,
       r.started_at AS started_at, r.ended_at AS ended_at, a.id AS ca_account_id
FROM system.account_relationships r
JOIN system.account_relationship_definitions d ON d.id = r.definition_id
JOIN system.accounts a ON a.id = r.account_id
LEFT JOIN postgres.posthog_user u ON u.id = r.user_id
WHERE a.external_id = '<ORG_ID>'
ORDER BY isNull(r.ended_at) DESC, r.started_at DESC
LIMIT 50
```

A null `ended_at` is a current holder; an ended row is ownership history, and it is the only record of who held the account before. Read the role names off the `role` column rather than matching a fixed list, since teams add roles. **No rows is two different facts**: an account with no relationships (a real `NONE` on every role) and an org with no Customer Analytics account at all, so check `system.accounts` for the org before writing `NONE`. Never read ownership from the `csm`, `account_executive` or `account_owner` keys on the account's `properties`: they are no longer written.

The Onboarding specialist is cleared when an account reaches `3. Onboarding Completed` or `Sales Handoff`, so on a finished account the ended row is who worked it. Several specialists can have emailed one account; who did is in `conversation-history`, not here.

## org-status

Whether the org is switched on, why not if it is off, whether it signed a HIPAA BAA, and whether it allows AI data processing, in one row for any org and either region. Each of these decides what the run may recommend, so read them before Step 3.

```sql
SELECT k.org_id AS org_id,
       coalesce(us.active, eu.active) AS org_active, coalesce(us.reason, eu.reason) AS inactive_reason,
       sf.baa_signed AS hipaa_baa_signed,
       coalesce(us.ai_ok, eu.ai_ok) AS ai_processing_approved
FROM (SELECT '<ORG_ID>' AS org_id) AS k
LEFT JOIN (SELECT posthog_org_id_c AS org, max(hipaa_baa_signed_date_c) AS baa_signed
           FROM salesforce.account WHERE posthog_org_id_c = '<ORG_ID>' GROUP BY org) AS sf ON sf.org = k.org_id
LEFT JOIN (SELECT toString(id) AS org, is_active AS active, is_not_active_reason AS reason, is_ai_data_processing_approved AS ai_ok
           FROM postgres.posthog_organization WHERE toString(id) = '<ORG_ID>') AS us ON us.org = k.org_id
LEFT JOIN (SELECT toString(id) AS org, is_active AS active, is_not_active_reason AS reason, is_ai_data_processing_approved AS ai_ok
           FROM eu_postgres_posthog_organization WHERE toString(id) = '<ORG_ID>') AS eu ON eu.org = k.org_id
LIMIT 1
```

- **`org_active = false` means finance or support has switched the org off**, and `inactive_reason` says why (an unpaid balance, suspected abuse). Neither v8 nor the pipeline knows: an inactive org can still read `Eligible` at `1. New Account`. It leads the header as a flag, and an onboarding email to it is a note to the owner of that decision instead, unless the user asks for the draft in so many words.
- **A signed BAA rules out every AI-feature lever** until the live [HIPAA page](https://posthog.com/docs/privacy/hipaa-compliance.md) says otherwise: PostHog AI, Replay Vision and the other AI features have been outside the BAA, so re-read the page and quote it rather than pitching one. `is_hipaa` on the org table looks like the field to read and is null or false on every org, so never read it.
- Empty columns mean the org is in neither table, which makes them unmeasured, not "active" or "not approved".

## org-universe

One row per org from `org_universe`, the cross-source org table Growth and RevOps maintain: engagement, products in use, usage momentum, billing risk, credits, Salesforce lead history and Growth's enrichment, in either region. Rebuilt daily. Read it for who on the account actually uses PostHog and whether that is growing, which nothing else here gives in one read.

```sql
SELECT universe_version, as_of, activity_as_of, usage_as_of,
       primary_organization_id = organization_id AS is_main_org, primary_organization_id, company_domain,
       engaged_users_7d, engaged_users_30d, engaged_users_prior_30d, builders_30d, engaged_days_30d, days_since_last_seen,
       member_count, invites_30d, signups_30d,
       products_activated_30d, products_used_30d, billable_events_momentum, billable_spend_ramp_7d, billable_rising_surfaces,
       billing_limits, capped_products, credits_remaining, credit_runway_days, credits_expiring_at,
       startup_plan_active, startup_plan_ends_at, trial_status,
       last_lead_task_at, last_lead_task_source, sfdc_last_disqualification_reason, sfdc_use_cases,
       icp_fit_status, icp_fit_score, enrichment_is_ai_native, enrichment_headcount, enrichment_headcount_engineering,
       enrichment_funding_stage, enrichment_total_raised, is_yc_company
FROM org_universe WHERE organization_id = '<ORG_ID>'
```

- **Read the column descriptions before quoting a column you have not used before** (`system.information_schema.columns WHERE table_name = 'org_universe'`). It has close to 400 columns, each documented, and `universe_version` changes whenever a meaning does.
- **Engagement is the strongest column here, and it is PostHog-app use**: `engaged_users_30d` and `builders_30d` count their team querying, viewing and building in PostHog, staff excluded. `engaged_users_prior_30d` is NULL while the stored history is short, which means unknown, not zero.
- **`capped_products` is not data loss.** It lists products whose billing limit sits at or below 1.2 times last month's spend, and billing's own defaults count, so a `posthog_ai` or `data_warehouse` entry is usually a limit nobody chose. Whether a limit actually cut data off is `org_quota_limited_until` (`quota-limits` in `queries-money.md`); who set it is `billing-limit-updates`.
- **`products_activated_30d` carries four keys only** (`recordings`, `error_tracking`, `feature_flags`, `surveys`), with product analytics never among them. For LLM analytics, logs and the warehouse read `billable_ai_events_30d`, `billable_logs_mb_30d` and `billable_rows_synced_30d`.
- **Growth's enrichment is thin on onboarding's accounts.** The ICP fit columns cover US orgs only and most new paying orgs have none, so an empty `icp_fit_score` or headcount means unscored, never small. Never rank or disqualify an account on it.
- **Freshness is on the row**: each `*_as_of` column names when its source last landed, and a `built_at` older than a day means an input failed to build.
- **The money columns here are cross-checks.** The forecast comes from `onboarding-state` and the last bill from `money-picture`, per `SKILL.md`.

## signup-intent

What the org said it came for when it signed up, and whether it finished setup. It comes from PostHog's own signup and onboarding events in project 2, which carry the org as `$group_0` in both regions. The primary product picked at signup is the best single line for what to open an email with, and a product picked but not in use is an adoption hook (`levers.md`).

```sql
SELECT event, count() AS n, min(timestamp) AS first_at, max(timestamp) AS last_at,
       groupUniqArrayIf(5)(toString(properties.product_key), toString(properties.intent_context) = 'onboarding product selected - primary') AS primary_picks,
       groupUniqArrayIf(10)(toString(properties.product_key), toString(properties.intent_context) = 'onboarding product selected - secondary') AS secondary_picks,
       groupUniqArray(5)(toString(properties.use_case)) AS use_cases,
       groupUniqArray(5)(toString(properties.path)) AS selection_paths,
       groupUniqArrayIf(3)(left(toString(properties.referral_source_ai_prompt), 300), notEmpty(toString(properties.referral_source_ai_prompt))) AS ai_prompts
FROM events
WHERE $group_0 = '<ORG_ID>' AND timestamp >= now() - INTERVAL 730 DAY
  AND event IN ('user showed product intent', 'onboarding product selection path', 'user signed up',
                'setup wizard finished', 'wizard: agent started')
GROUP BY event
```

- **Only the `onboarding product selected` contexts are intent.** Every other `user showed product intent` row is a page or panel the person happened to open (`endpoints_viewed` fires on almost every org), the same impression trap as a pay gate, so never quote one as what they want.
- **Several people can sign up to one org**, each picking their own products, so `primary_picks` can hold more than one. Read it as what the team came for, not one person's choice, and check `first_at` against the org's age: a pick from a teammate who joined last week is not why the org signed up.
- **`use_case`** (`see_user_behavior`, `fix_issues`, `launch_features`, `collect_feedback`, `monitor_ai`) mostly repeats the primary pick; it is the fallback when there is no pick.
- **`setup wizard finished` carries the org; `wizard: started` never does**, because it fires before login, so no row for it means nothing. No `setup wizard finished` row means the wizard was not finished by anyone signed in, not that setup is missing: read the event mix before saying so.
- **`ai_prompts` is the question they asked an AI assistant before signing up**, and only a few orgs have one. It is context for whoever writes, never a line to quote back to the customer.

## salesforce-firmographics

The free company and contact fields `clay` reads before spending credits, and the domain the site scan should scan. Batch 3; both go into the context file. Zero rows is common (most self-serve orgs have no Salesforce account) and means Clay works from the domain alone.

```sql
SELECT a.name AS name, a.website AS website, a.domain_c AS domain, a.harmonic_headcount_c AS headcount,
       a.harmonic_company_type_c AS company_type, a.harmonic_funding_stage_c AS funding_stage,
       a.company_tech_c AS company_tech, a.built_with_technologies_c AS built_with
FROM salesforce.account AS a
WHERE a.posthog_org_id_c = '<ORG_ID>'
LIMIT 5
```

```sql
SELECT c.email AS email, c.title AS title, c.linked_in_title_c AS linkedin_title, c.linkedin_profile_c AS linkedin
FROM salesforce.contact AS c
WHERE c.email IN (<ADMIN_EMAILS>)
LIMIT 50
```

## support-tickets

PostHog Support holds every ticket, so read them over the MCP: `conversations-tickets-list` with `emails` set to the admin emails as one comma-separated **string** (not an array) and `date_from` set to `all`, or it returns only recent tickets. Then `conversations-tickets-messages-retrieve` per ticket for the messages, which carry per-message direction. **Never scope tickets by org**: `system.support_tickets.organization_id` is null on most tickets, so an org filter returns a confident empty. v8's `open_tickets` and `last_ticket_at` are an org-joined count, a floor rather than the record.

## per-product-usage

How much of each product they actually consume, typed and daily, no JSON extraction and no `argMax`. This section owns the `billing_usage_by_org_date` facts; `usage-mix` in `queries-money.md` points back here rather than restating them.

`billing_usage_by_org_date`, key `organization_id`, daily grain, exactly unique so no dedup guard is needed, fresh to the previous day, US and EU combined with no region column, and typed. It agrees with the org usage report on the volume metrics they share. It carries no per-SDK or per-event-name breakdown, so do not reach for one here. Which of the two sources to reach for is the choice rule in the `queries-products.md` shared intro.

| Product | Column |
|---|---|
| Product analytics | `event_count_in_period` |
| Identified events | `enhanced_persons_event_count_in_period` |
| Session replay | `recording_count_in_period`, `mobile_recording_count_in_period` |
| Feature flags | `billable_feature_flag_requests_count_in_period` |
| Surveys | `survey_responses_count_in_period` |
| Error tracking | `exceptions_captured_in_period` |
| AI Observability | `ai_event_count_in_period` |
| PostHog AI | `ai_credits_used_in_period` |
| Replay Vision | `replay_vision_credits_used_in_period`, `replay_vision_observation_count_in_period` |
| Feature flags, local evaluation | `local_evaluation_requests_count_in_period` |
| Data warehouse | `rows_synced_in_period`, `rows_exported_in_period` |
| CDP and destinations | `cdp_billable_invocations_in_period` |
| Logs | `logs_mb_in_period` |

**Two traps, both of which read as a confident zero.** It is **Cloud only**, so a self-hosted org reads zero across every column while emitting usage daily: check `realm` on `org-snapshot` before believing a flat zero. And it carries a row only where there was usage, rather than zero-filling, which cuts two ways: a **missing day** means no usage that day, and an **org with no rows at all** has no Cloud usage in the window. Neither is ever no data.

PostHog Desktop, signals and sandbox compute credits are not on this table: read them from the org usage report (`posthog_code_credits_used_in_period`, `signals_credits_used_in_period`, `sandbox_compute_credits_used_in_period`), because on an agent-heavy account they can be nearly the whole bill. No billing source exists for experiment volume or web analytics volume. Per-org heatmap volume rides on the usage report's `teams` map as `heatmap_events_count_in_period`, so read it there rather than calling it unmeasurable.

**`mobile_billable_recording_count_in_period` is NOT on this table**, and selecting it here fails with HTTP 400 rather than returning zero. This table carries `mobile_recording_count_in_period` (captured) only; the billable twin lives on the `organization usage report` event, where both sit side by side (`queries-products.md`, Session replay). Where the two differ, the gap is anything a limit dropped or capture the meter does not bill (they are often equal), so on a mobile-heavy account read both and never quote the captured figure as the billed one.

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

`days_reported` against `<days>` is this query's own built-in check on the second trap. The table runs one to two days behind and fills the newest day over a couple of days, so read `last_day` before calling a recent drop real.

Daily form for spike and trend work: add `date`, `GROUP BY date`, `ORDER BY date DESC`.

## usage-dashboard

**An opportunistic shortcut, never a required read and never something to plan around.** Its tiles read the billing usage-report tables that `queries-money.md` says time out on single orgs, so nulls are the usual result. Dashboard **1397076** in project 2 is a set of `postgres.prod.billing_usagereport` insights parameterized on a single `organization_id` variable, and `dashboard-insights-run` will run every tile against any org you name: events, identified persons, recordings, billable flag requests, exceptions, CDP and workflow invocations, and data-warehouse rows, at daily and weekly grain.

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

Where the account sits in onboarding, what the team and its workflows have already done, and how healthy it is, in one row for any org: an org with no Customer Analytics account or no v8 row still comes back, with those columns empty, so "never onboarded" and "no account" are said out loud instead of implied.

```sql
SELECT k.org_id AS org_id, a.ca_account_id AS ca_account_id, a.ca_rows AS ca_rows, a.account AS account,
       a.churned_at AS churned_at, a.ignored_at AS ignored_at, a.tags AS tags,
       a.pipeline_property AS pipeline_property, a.opted_out AS opted_out,
       if(isNull(o.org_id), 0, 1) AS v8_row,
       o.onboarding_stage AS onboarding_stage, o.onboarding_eligibility AS onboarding_eligibility,
       o.eligibility_blocker AS eligibility_blocker, o.os_priority AS os_priority, o.priority_reason AS priority_reason,
       o.onboarding_last_email_at AS onboarding_last_email_at, o.days_since_onboarding_email AS days_since_onboarding_email,
       o.onboarding_outbound AS onboarding_outbound, o.onboarding_replied AS onboarding_replied,
       o.onboarding_engagement AS onboarding_engagement, o.onboarding_days_since_first_touch AS days_since_first_touch,
       o.other_outreach_30d AS other_outreach_30d, o.onboarding_call_booked AS onboarding_call_booked,
       o.next_onboarding_meeting_at AS next_onboarding_meeting_at, o.onboarding_meetings AS onboarding_meetings_held,
       o.sfdc_last_dq_at AS sfdc_last_dq_at, o.sfdc_last_dq_reason AS sfdc_last_dq_reason,
       o.forecasted_mrr AS forecasted_mrr, o.last_bill_mrr AS last_bill_mrr, o.next_bill_at AS next_bill_at,
       o.days_to_next_bill AS days_to_next_bill, o.months_billed AS months_billed, o.unpaid_invoices AS unpaid_invoices,
       o.stripe_delinquent AS stripe_delinquent, o.stripe_credit_balance AS stripe_credit_balance,
       o.credit_days_left AS credit_days_left, o.usage_drop_flag AS usage_drop_flag,
       o.admin_emails_csv AS admin_emails_csv, o.user_count AS user_count, o.active_users_30d AS active_users_30d,
       o.open_tickets AS open_tickets, o.last_ticket_at AS last_ticket_at,
       h.health_score AS health_score, h.scored_at AS health_scored_at, h.engagement_health AS engagement_health,
       h.stickiness AS stickiness, h.n_products AS n_products,
       h.e_product_analytics AS e_product_analytics, h.e_session_replay AS e_session_replay,
       h.e_feature_flags AS e_feature_flags, h.e_experiments AS e_experiments, h.e_error_tracking AS e_error_tracking,
       h.e_surveys AS e_surveys, h.e_web_analytics AS e_web_analytics, h.e_ai_observability AS e_ai_observability,
       h.e_logs AS e_logs, h.e_posthog_ai AS e_posthog_ai, h.e_inbox AS e_inbox, h.e_replay_vision AS e_replay_vision
FROM (SELECT '<ORG_ID>' AS org_id) AS k
LEFT JOIN (
  SELECT external_id, toString(any(id)) AS ca_account_id, any(name) AS account, any(churned_at) AS churned_at,
         any(ignored_at) AS ignored_at, any(tags.names) AS tags,
         any(toString(custom_properties.values.`019f5bfb-516d-7705-b541-51b775a97bb8`)) AS pipeline_property,
         any(toString(custom_properties.values.`01a0ed21-db99-731c-97d9-eb7ee011f676`)) AS opted_out,
         count() AS ca_rows
  FROM system.accounts WHERE external_id = '<ORG_ID>' GROUP BY external_id
) AS a ON a.external_id = k.org_id
LEFT JOIN onboarding_accounts_v8 AS o ON o.org_id = k.org_id
LEFT JOIN account_health_scores AS h ON h.org_id = k.org_id
LIMIT 1
```

Columns and their traps are in the v8 table in `data-rules.md` ("Customer Analytics and the onboarding model"). Read it as follows:

- **`v8_row = 0` means the org is outside `billing_customer_ownership` (often a brand-new billing customer), never "not onboarded".** Then `pipeline_property` (the `Onboarding Pipeline` property, straight off the account) is the stage. Where `pipeline_property` and `onboarding_stage` disagree, v8 is behind a recent change: say so and trust the property for the stage.
- **`ca_rows` above 1 means the org has two Customer Analytics accounts**: say so, and read the rest of the row as unreliable until you have looked at both.
- **`ca_account_id` empty means the org has no Customer Analytics account**, so tags, the pipeline property, notes, tasks and the automation timeline do not exist for it. Write `no Customer Analytics account` in the header and carry on with the org id.
- **`tags` holds the referral record**: any tag containing `referral` means the account was referred to sales. Stage reactor moves a stage 1 or 2 account to `Sales Handoff` only when such a tag is *added*, so a tag that predates the workflow or arrived with an import leaves the account at stage 1 or 2: flag that pair, never assume the move happened. Read it with `sfdc_last_dq_at`: referred and disqualified since means it came back to onboarding; referred and not disqualified means sales still has it.
- **`opted_out = 'true'` (Yes in the UI) means no onboarding email to it, explicit ask included.** A reply to a billing or support question the customer asked is the one exception, per Step 3.
- **`health_score` is PostHog's own model (0 to 10)**, the `Health score` account property, and it fills the header with its `health_scored_at` date. Its `e_<product>` columns say which products they actually run, where null is a product they do not use.
- Every v8 column is only as fresh as v8's last run, so check it per `data-rules.md` before quoting one.

## self-driving-check

Run always; cheap and it maps the account onto the company direction. Buckets: PostHog AI chat, Inbox, Scouts/signals, PostHog Code, MCP. Human-action events (`Inbox viewed`, `Scout fleet viewed`, `Task viewed`) = admins engaging; machine events (`signals_scout_run_started`, `signal_emitted`, a `pr_created` carrying an `origin_product`) = the automation actually running for them. **`pr_created` and `pr_merged` with an empty `origin_product` are their own repos' PR activity through a GitHub integration, not PostHog Code**, and on one account they were 94% of the old bucket; `task_created` carries its real source in `origin_product` (scouts, signal reports, PostHog AI, review bots). Zero across all buckets on an AI-native account is the self-driving adoption pitch (see `levers.md`). This detects usage only; Inbox report CONTENT is not readable from project 2.

The org usage report carries the credit side of the same story: `ai_credits_used_in_period` (PostHog AI), `posthog_code_credits_used_in_period` (PostHog Code / Desktop), `signals_credits_used_in_period` (Scouts and signals), all org+team, credits/day. **This is the only per-account measure of self-driving adoption available in project 2.** All three at 0 means the org has not touched the self-driving product line, which is an outreach hook rather than a cost finding.

**Match event-name prefixes with `startsWith()`, never `ILIKE`.** Two traps, both live in the MCP bucket, and they push the count in opposite directions so they do not cancel out. The real MCP events come in a dollar-prefixed set (`$mcp_initialize`, `$mcp_tools_list`, `$mcp_tool_call`) beside the bare ones (`mcp_initialize`, `mcp_tool_call`), and the dollar-prefixed set outweighs the bare one, so a pattern anchored at `mcp_` alone is blind to the larger half and undercounts events. Meanwhile `_` is a single-character wildcard in LIKE, so `ILIKE 'mcp_%'` also swallows the hint banner (`mcp hint shown`, `mcp hint dismissed`), which is an impression rather than usage, and every admin who merely saw the banner inflates the user count. Escaping is not the way out: `ILIKE 'mcp\_%'` errors with "unrecognised escape". `startsWith()` fixes both at once, and it drops the space-named hint events for free, since a space is not an underscore. It is case-sensitive, which is correct here: `Inbox`, `Scout`, and `Signal source connected` are capitalized, `signal_` and `signals_` are not.

**The `mcp` bucket counts connections, not work, so never quote it as usage on its own.** `$mcp_initialize` and `$mcp_tools_list` fire on every handshake and dominate the count, far above the queries anyone actually ran. `$mcp_tool_call` is the middle signal and `query executed` with `source = 'mcp'` (`query-usage`) is the depth one, so read the bucket for reach and that column for whether anyone did anything. Two more things to look out for rather than assume: the prefix also catches `mcp_store`, `mcp_gateway` and `mcp_ui_app_` events, which are separate products and not the customer querying PostHog, and several real MCP actions are space-named (`mcp project switched`, `mcp organization switched`, `mcp feedback submitted`) so they fall outside it entirely. Check what the account actually emits before reading the bucket as a total, and group it by `$mcp_client_name`: a bucket made only of `$mcp_tools_list` from `posthog-webmcp` is PostHog's own web app registering its tools, not an agent the customer connected.

```sql
SELECT multiIf(event IN ('$conversations_loaded','max conversation turn completed','chat with ai'), 'posthog_ai_chat',
               startsWith(event, 'Inbox'), 'inbox',
               startsWith(event, 'Scout') OR startsWith(event, 'signals_') OR startsWith(event, 'signal_')
                 OR event = 'Signal source connected', 'scouts_signals',
               event IN ('pr_created','pr_merged') AND coalesce(toString(properties.origin_product), '') = '', 'repo_prs_not_posthog',
               (event = 'task_created' AND toString(properties.origin_product) IN ('signals_scout','scout_suggestions','signal_report')), 'scouts_signals',
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

## posthog-code-usage

What PostHog Code (the PostHog Desktop app) actually did for them, by day. **Its events carry the project and not the org**, so every `$group_0` read here, `self-driving-check` included, reads zero on an account whose Desktop agents are running up the bill. Scope by the event's `team_id` property instead, against the org's own team ids, and by the US instance (`$group_1`), because team ids repeat across regions. **US only**: EU events carry no `team_id`, so on an EU org this read is unmeasurable and PostHog Desktop use comes from `posthog_code_credits_used_in_period` and the `posthog_code_mrr` line alone.

```sql
SELECT toStartOfDay(timestamp) AS day, count() AS generations, uniqExact(properties.$ai_trace_id) AS traces,
       round(sum(toFloat(properties.$ai_total_cost_usd)), 2) AS cost_usd,
       sum(toInt(properties.$ai_input_tokens)) AS input_tokens, sum(toInt(properties.$ai_output_tokens)) AS output_tokens,
       groupUniqArray(5)(toString(properties.$ai_model)) AS models
FROM events
WHERE event = '$ai_generation' AND toString(properties.ai_product) = 'posthog_code'
  AND $group_1 = 'https://us.posthog.com' AND toString(properties.team_id) IN (<TEAM_IDS_QUOTED>)
  AND timestamp >= now() - INTERVAL <days> DAY
GROUP BY day ORDER BY day DESC LIMIT 60
```

`cost_usd` is the model cost of the generations, not what the customer is billed: the bill is PostHog Desktop credits, from `posthog_code_credits_used_in_period` on the org usage report and the `posthog_code_mrr` line in `in-flight-period`. Read the two together, the generations for when and how hard the agents ran and the credits for what it costs them. Run it whenever the scope probe or the invoice shows any PostHog Desktop spend.

## mcp-intents

What an MCP user was trying to do, in their own agent's words. Someone who works through the PostHog MCP leaves almost nothing in `query-usage` or the PostHog AI reads, and `$mcp_intent` on every `$mcp_tool_call` is the only record of what they were after. Run it whenever `self-driving-check` shows an `mcp` bucket.

```sql
SELECT person.properties.email AS email, toStartOfDay(timestamp) AS day,
       count() AS tool_calls,
       groupUniqArray(10)(substring(toString(properties.$mcp_intent), 1, 200)) AS intents,
       groupUniqArray(10)(toString(properties.$mcp_tool_name)) AS tools
FROM events
WHERE event = '$mcp_tool_call' AND $group_0 = '<ORG_ID>' AND timestamp >= now() - INTERVAL <days> DAY
  AND properties.$mcp_intent IS NOT NULL
GROUP BY email, day ORDER BY day DESC, tool_calls DESC LIMIT 40
```

A second event, bare `mcp_tool_call` (server-side, `posthog-node`, carrying `$mcp_tool_name` and `$mcp_client_name` but never an intent), records tool calls the first one misses, so count tool calls over both and read intents from `$mcp_tool_call` alone. The intent is written by the user's agent, not typed by them, so quote it as "their agent's stated goal" and never as their words. Read it for direction: a run of intents about exporting data, self-hosting or comparing vendors is a churn signal worth leading a call with.

## query-usage

How they pull data out, and usually the highest-volume admin event on the account. `source` is the column that matters: `web` (the UI), `api`, `mcp`, `posthog_ai`, `self_driving` and `posthog_code` (PostHog's own agents working for them), plus `terraform`, `cli`, `wizard`, `alert`, `export`, `subscription`. It says whether this account drives PostHog by clicking or by machine, and an `api` or `mcp` majority is the agentic-adoption tell that pairs with `self-driving-check`. Exclude `cache_warming`: it is PostHog pre-warming their caches, not a person querying.

```sql
SELECT person.properties.email AS email, count() AS queries,
       countIf(properties.source = 'web') AS via_web,
       countIf(properties.source = 'api') AS via_api,
       countIf(properties.source = 'mcp') AS via_mcp,
       countIf(properties.source = 'posthog_ai') AS via_posthog_ai,
       countIf(properties.source IN ('self_driving', 'posthog_code')) AS via_agents,
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

Who has a seat and who uses it. Region-agnostic, so it is the fallback wherever `org-membership` cannot run.

Built on `organization usage report per person`, the per-person twin of the org usage report: it fires daily per member, carrying `org_membership_level` (`owner` / `administrator` / `member`), `role_at_organization`, and `has_non_zero_usage`. Filter `scope = 'user'`; a `machine` scope also exists and is rare.

**`has_non_zero_usage` does not reliably separate a held seat from a used one, so never quote it as an active-user count.** It splits both ways across PostHog as a whole, but on a given account it can read `true` for every member including people who did almost nothing all month. Get real activity from `top-users` instead, and subtract the machine floor described next.

**This event is itself a floor under every per-person event count.** It fires once per member per day, and server-side events (`cache_warming`, `task_created`) add more, so a 30-day `top-users` read carries roughly 35 events per member and about 120 per admin that nobody generated (measured on one account), enough to rank a dormant owner as a top user. On a low-engagement account that floor is most of what a dormant seat appears to do, so subtract it before ranking contacts or calling anyone active.

This fills a gap the postgres mirror cannot. **`postgres.posthog_organizationmembership` returns zero rows for an EU org**, so on EU `org-membership` runs against the EU mirrors instead (its own section says how), which carry `last_login` too. Use `org-membership` when you want `last_login` and `date_joined`, which this event does not carry.

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

Who the owners and admins are, with `last_login` and `date_joined`. On EU swap both tables, to `eu_postgres_posthog_organizationmembership` and `eu_postgres_posthog_user`; the US mirror returns no rows for an EU org.

Swap every table in this query or none (the half-swap rule in `data-rules.md`): `user_id` collides across regions exactly like `team_id`, and a half-swapped join returns strangers from other companies wearing this account's roles, with no error, ending in an email to the wrong person. `org_id` is in the SELECT to make that visible: check the returned org id before using a name.

Read `is_active` rather than filtering on it: deactivated users stay in the membership table, and on an org that was switched off the owner is deactivated too, so a filter returns nobody. Keep the limit above the org's member count, or the roster silently truncates; enterprise accounts run to hundreds.

```sql
SELECT m.organization_id AS org_id, u.email,
       CASE m.level WHEN 15 THEN 'owner' WHEN 8 THEN 'admin' WHEN 1 THEN 'member' ELSE toString(m.level) END AS role,
       concat(u.first_name, ' ', u.last_name) AS full_name, u.is_active, u.last_login, u.date_joined
FROM postgres.posthog_organizationmembership m JOIN postgres.posthog_user u ON m.user_id = u.id
WHERE m.organization_id = '<ORG_ID>'
ORDER BY u.is_active DESC, m.level DESC, u.last_login DESC LIMIT 200
```

## Customer Analytics reads

Everything below reads PostHog's own records of the account: Customer Analytics, the email sync and the `Onboarding::` workflows. Run `onboarding-automation`, `conversation-history` and `touchpoint-timeline` for every account with a Customer Analytics account; they are the account's whole history with PostHog, and `data-rules.md` ("Customer Analytics and the onboarding model") holds the rules for reading them. **On a multi-org account run them over every org the sweep returned** (each `= '<ORG_ID>'` becomes an `IN` over the sibling org ids, and `onboarding-automation` and the notes read run once per sibling's account): the email sync links a thread to whichever org an address matched, and Customer Analytics hangs notes and meetings on whichever account was open, so the live org's history often sits on a test or staging sibling and the live org alone reads empty.

## onboarding-automation

What onboarding's own workflows did to this account, and what people changed on it, newest first: every `Onboarding::` email sent, delivered, opened, clicked, bounced or failed, with its subject and recipient; every stage change with who or which workflow made it; tags added and removed; owners assigned and ended. Routine property syncs from the views are filtered out, apart from the pipeline itself.

```sql
SELECT e.timestamp AS timestamp, e.event AS event,
       coalesce(h.name, toString(e.properties.$workflow_id), toString(e.properties.workflow_id)) AS workflow,
       coalesce(toString(e.properties.actor_type), if(e.event LIKE '$workflows_%', 'workflow', '')) AS actor,
       toString(e.properties.actor_email) AS actor_email,
       multiIf(e.event = '$account_custom_property_changed',
                 concat(toString(e.properties.property_name), ': ', JSONExtractString(e.properties, 'previous_value'), ' -> ', JSONExtractString(e.properties, 'current_value')),
               e.event IN ('$account_tag_added', '$account_tag_removed'), toString(e.properties.tag),
               e.event = '$account_relationship_changed',
                 concat(toString(e.properties.relationship_name), ' ', toString(e.properties.change_type), ' ', coalesce(toString(e.properties.current_user_email), '')),
               concat(coalesce(toString(e.properties.$workflow_action_id), ''), ' | ', coalesce(toString(e.properties.$email_subject), ''),
                      ' | to ', coalesce(toString(e.properties.$email_to), ''))) AS detail
FROM events AS e
LEFT JOIN (SELECT toString(id) AS hid, name FROM system.hog_flows) AS h
  ON h.hid = coalesce(toString(e.properties.$workflow_id), toString(e.properties.workflow_id))
WHERE e.timestamp >= now() - INTERVAL 120 DAY
  AND (e.distinct_id IN (concat('account:', '<CA_ACCOUNT_ID>'), '<ORG_ID>')
       OR toString(e.properties.account_external_id) = '<ORG_ID>')
  AND (startsWith(e.event, '$workflows_')
       OR e.event IN ('$account_tag_added', '$account_tag_removed', '$account_relationship_changed')
       OR (e.event = '$account_custom_property_changed'
           AND (coalesce(toString(e.properties.actor_type), '') != 'system'
                OR toString(e.properties.property_id) = '019f5bfb-516d-7705-b541-51b775a97bb8')))
ORDER BY e.timestamp DESC
LIMIT 150
```

Four ways this has misled:

- **A change a person made fires on that person's own `distinct_id`**, not the account's, which is why the filter also matches `account_external_id`. Never narrow it to the account `distinct_id` alone.
- **`send_email_1` to `send_email_4` are the four sequence emails**; `send_email` alone is Payment Failed, which is billing and never counts as onboarding outreach. A `$workflows_email_delivered` row exists per recipient, the onboarding bcc mailbox included, and is incomplete, so count sends on `$workflows_email_sent` only.
- **Opens and clicks stopped on 15 October 2026**, when tracking went off on every onboarding send, so their absence after that date says nothing.
- **There is no reply event.** Whether they wrote back is in `conversation-history`.

Where the account sits in `Onboarding:: Email sequence` now, and when it wakes next, is in the run: `workflows-list-invocations` with the sequence's id (`01a0c9f0-60a6-0000-af22-9cd658e27d6c`) and `distinct_id` set to `account:<CA_ACCOUNT_ID>`, then `workflows-logs` with that invocation's `instance_id`; the last `Workflow will pause until` line is the next wake, in UTC. A run that ended has no wake, and the timeline above says why.

## conversation-history

Every email thread the email sync tied to the account, message by message, newest first. Every onboarding mailbox syncs, and every Workflows customer email is bcc'd to an onboarding mailbox, so the automated sends are here too.

```sql
SELECT m.sent_at AS sent_at, t.subject AS subject, m.direction AS direction,
       m.sender_email AS from_email, m.sender_name AS from_name,
       arrayStringConcat(arrayMap(x -> JSONExtractString(x, 'email'), JSONExtractArrayRaw(coalesce(toString(m.to_recipients), '[]'))), ', ') AS to_emails,
       arrayStringConcat(arrayMap(x -> JSONExtractString(x, 'email'), JSONExtractArrayRaw(coalesce(toString(m.cc_recipients), '[]'))), ', ') AS cc_emails,
       multiIf(m.sender_email IN (SELECT onboarding_team_members FROM onboarding_team_members), 'onboarding',
               m.sender_email ILIKE '%@posthog.com', 'posthog_other', 'customer') AS sender_kind,
       match(lower(t.subject), 'payment|overdue|unpaid|outstanding') AS billing_thread,
       t.message_count AS thread_messages, t.last_message_at AS thread_last_at,
       t.preview AS thread_preview, toString(m.thread_id) AS thread_id
FROM postgres.posthog_conversations_email_thread_message AS m
JOIN postgres.posthog_conversations_email_thread AS t ON t.id = m.thread_id
WHERE m.thread_id IN (SELECT thread_id FROM postgres.posthog_conversations_email_thread_account_link
                      WHERE account_external_id = '<ORG_ID>')
ORDER BY m.sent_at DESC
LIMIT 60
```

Read `sender_kind`, never `direction`, to say who wrote: a Workflows send copied to the onboarding bcc mailbox syncs as **inbound** from the teammate the rotation picked, so an `inbound` row with `sender_kind = 'onboarding'` is our own automated email. `billing_thread` marks payment threads, which never count as onboarding outreach. `posthog_other` is someone at PostHog outside onboarding, which is a collision to read before drafting. The sync stores only `thread_preview`, about 500 characters of the latest message: for a full body, read that thread in your own Gmail by its subject, after checking the recipient domain is the account's (`data-rules.md`). **Before a reply or a follow-up, read the latest customer message and the latest onboarding message at full width**, the preview or the Gmail thread, never a truncated line.

Before 12 October 2026 the record also lives in two frozen archives, metadata in the first and the onboarding team's inbound message bodies in the second. They overlap the live sync from August, so drop a thread that appears in both by subject and date:

```sql
SELECT last_message_at, subject, kind, thread_source, messages, inbound_msgs, outbound_msgs,
       last_direction, last_outbound_by_email, last_inbound_at
FROM onboarding_history_archive
WHERE org_id = '<ORG_ID>'
ORDER BY last_message_at DESC
LIMIT 40
```

```sql
SELECT sent_at, subject, thread_owner_email, substring(body_text, 1, 600) AS body
FROM onboarding_conversation_bodies_archive
WHERE org_id = '<ORG_ID>'
ORDER BY sent_at DESC
LIMIT 20
```

## touchpoint-timeline

Tasks, meetings and feature requests on the account in one dated list, newest first, with a `kind` column. Fixed window of a year back and 60 days ahead, because recurring meetings expand years into the future.

```sql
WITH acct AS (SELECT id FROM system.accounts WHERE external_id = '<ORG_ID>')
SELECT * FROM (
  SELECT 'task' AS kind, t.created_at AS ts, t.name AS title,
         substring(coalesce(t.description, ''), 1, 220) AS detail,
         concat(coalesce(u.email, '(unassigned)'), ' | ', t.status, ' | due=', coalesce(toString(t.due_at), '-')) AS who
  FROM system.customer_tasks AS t LEFT JOIN postgres.posthog_user AS u ON u.id = t.assigned_to_id
  WHERE t.account_id IN (SELECT id FROM acct) AND t.archived_at IS NULL
  UNION ALL
  SELECT 'meeting', m.start_time, m.title, substring(coalesce(m.description, ''), 1, 220),
         concat(coalesce(m.organizer_email, '-'), ' | ', coalesce(m.status, '-'))
  FROM postgres.customer_analytics_meeting AS m
  WHERE m.account_id IN (SELECT toString(id) FROM acct)
  UNION ALL
  SELECT 'feature_request', if(ev.requested_on IS NULL, coalesce(ev.created_at, l.created_at), toDateTime(ev.requested_on)), fr.title,
         substring(coalesce(ev.customer_quote, ev.summary, ''), 1, 220),
         concat(fr.status, ' | ', fr.priority, ' | ', coalesce(ev.source, '-'))
  FROM system.feature_request_account_links AS l
  JOIN system.feature_requests AS fr ON fr.id = l.feature_request_id
  LEFT JOIN system.feature_request_evidence AS ev ON ev.account_link_id = l.id
  WHERE l.account_id IN (SELECT id FROM acct) AND fr.archived_at IS NULL
)
WHERE ts > now() - INTERVAL 365 DAY AND ts < now() + INTERVAL 60 DAY
ORDER BY ts DESC
LIMIT 60
```

An open `Consider referring to sales`, `Check in after the meeting`, `Review onboarding brief` or `Sales disqualified this referral` task was made by an `Onboarding::` workflow; nothing records which, so the name is the only tell. A `Canceled: ` title prefix marks a cancelled meeting, since the status column almost never says so. Meetings only exist for teammates who connected their calendar, so an empty meetings list is unmeasured, not "never met": confirm on the work calendar. **Notes are not here**, because nothing links a note to an account in SQL: read them with `accounts-notebooks-list`, whose parameter is `account_id` (the CA account id). Gong call summaries are written there as notes, one per call.

## survey-feedback

What anyone at the org answered on PostHog's in-app surveys (product NPS, the post-onboarding survey and the rest), newest first. Each response is keyed by question, so read the survey name beside it before reading a number as an NPS score.

```sql
SELECT timestamp, toString(properties.$survey_name) AS survey, person.properties.email AS email,
       arrayStringConcat(arrayMap(k -> concat(replaceOne(k, '$survey_response', 'q'), '=', substring(JSONExtractRaw(toString(properties), k), 1, 300)),
                                  arrayFilter(k -> startsWith(k, '$survey_response'), JSONExtractKeys(assumeNotNull(toString(properties))))), ' | ') AS responses
FROM events
WHERE event = 'survey sent' AND $group_0 = '<ORG_ID>' AND timestamp >= now() - INTERVAL 365 DAY
ORDER BY timestamp DESC
LIMIT 30
```

No row means nobody at the org answered a survey in a year, never that they are neutral.
