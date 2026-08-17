# Queries: products

One block per product: its org-usage-report fields, its admin-activity read, its config and definition reads (US and EU side by side), and its region caveat. Conventions, ids, regions, and the source rules live in `data-rules.md`; this file's headings are its index. Run the blocks the account's paid products and the question at hand implicate; call prep runs them all.

## Shared rules (read before any block)

**Every admin-activity query in this file reads the customer's ADMIN events in project 2: their team clicking around the PostHog app, never their product's traffic.** Every `$pageview` under an account's `$group_0` sits on host `us.posthog.com`, in team 2 (PostHog's own project). Never quote one as customer volume; the org usage report is the authoritative per-SDK and billable-volume source.

**Every definition count needs `WHERE deleted = false`**, with two known exceptions called out in their blocks: `posthog_survey` has no `deleted` column and errors on it (filter `archived`), and `posthog_propertydefinition` has no `deleted` column at all (nothing to filter). This list is a prior, not a guarantee. The column set is probe-verifiable, so when a `deleted` filter errors on any other table, read the error and check `system.information_schema.columns` for that table instead of assuming the recipe is right, then say the list missed one.

The filter is not optional: a soft-deleted row is gone from the customer's UI and still sitting in the mirror, so an unfiltered count describes something the customer cannot see, and dashboards and flags both overstate badly without it. Filtered, the mirror and the usage report agree exactly, so cross-check them whenever a count drives a recommendation.

### admin-activity-pattern

Most admin-activity reads are one shape; substitute the block's event list:
```sql
SELECT person.properties.email AS email, count() AS events, max(timestamp) AS latest
FROM events
WHERE event IN (<the block's event list>) AND timestamp >= now() - INTERVAL <days> DAY
  AND $group_0 = '<ORG_ID>' AND person.properties.email IS NOT NULL
GROUP BY email ORDER BY events DESC LIMIT 50
```
Two variants stay inside the pattern: `countIf(event = '...')` per event name when you want the per-action split, and extra `properties.*` columns in the SELECT and GROUP BY when the block names useful ones. Every admin read here is a **top-N sample**: explicit ORDER BY, stated LIMIT, and a large account routinely fills it, so rows returned equal to the LIMIT means truncated, not complete. Raise the LIMIT (server cap in `data-rules.md`) when you need the tail, and never read a missing name as absent. Queries whose shape genuinely differs appear below as their own recipes.

### Reading the org usage report

One row per org per day in project 2, event `organization usage report`; `org-snapshot` in `queries-account.md` pulls the latest row.
- **Every `*_in_period` field covers ONE UTC DAY, not a month.** The emitter (`posthog/tasks/usage_report.py`) builds the report from `get_previous_day()`, and the event's own `period` property carries a single day's `start_inclusive` / `end_inclusive`. Reading any of these as a monthly figure is a roughly 30x overstatement. To get a month, sum the daily reports, or use `billing_usage_by_org_date` (`per-product-usage` in `queries-account.md`).
- **Cumulative vs daily.** `dashboard_count`, `ff_count`, `survey_count`, `symbol_sets_count`, `group_types_total`, `organization_user_count`, `team_count`, and `issues_created_total` are lifetime totals as of that day, not daily deltas. Do not sum them across days.
- **This event vs `billing_usage_by_org_date`.** They agree field for field on the 16 volume metrics they share, so the choice is about the other roughly 140 keys: default to the billing table for "how much and is it growing", and come here for "what is it made of and where does it run" (the region via `site_url`, self-hosted orgs, the per-SDK breakdown, the per-team map). The billing table's facts and its two confident-zero traps live beside `per-product-usage` in `queries-account.md`.
- The event carries **155 property keys**. **111 repeat per project inside the `teams` map** and are marked "org+team" below; the remaining 44 are org-level only. Enumerate keys with `JSONExtractKeys(properties)`. `JSONExtractKeys(toJSONString(properties))` returns 0 because it double-encodes an already-JSON string.
- Read one project's metric out of the map with `JSONExtractInt(assumeNotNull(properties.teams), '<TEAM_ID>', '<metric>')` (`properties.teams` is `Nullable(String)`). A team id absent from the map reads as 0, not null, so confirm the id is in `JSONExtractKeys(assumeNotNull(properties.teams))` before reading a 0 as real.
- **The `teams` breakdown is silently emptied for large orgs.** When the payload exceeds roughly 900KB the emitter drops the per-project map and sets `teams_omitted_due_to_size = true`. A missing or empty `teams` map is a payload-size artifact, not evidence that the org has one project: check `team_count` and the flag before concluding anything about project structure. The flag is absent (reads null) when the map is intact, so treat null as "not omitted".
- **Two absences on this event, both probe-verifiable against the project-2 catalog.** There is **no autocapture field**, and no per-event-name breakdown of any kind, so neither the customer's autocapture share nor any other `% of your events` figure comes from this event, and no admin-activity count ever stands in for one. Get those from the direct ClickHouse connection, in either region (`references/data-rules.md`). Heatmap volume IS here, as `heatmap_events_count_in_period`, at org level and inside the `teams` map. `heatmaps_opt_in` in `team-config` gives on or off; this gives the number.

**Volume** (org+team; the billable core):
- `event_count_in_period`: **billable** events for the day, already deduped. Excludes `$feature_flag_called`, `$experiment_exposure`, the three survey events (`survey sent`, `survey shown`, `survey dismissed`), `$exception`, all AI events, and the conversations-widget events, then dedupes on `distinct toDate(timestamp), event, cityHash64(distinct_id), cityHash64(uuid)`. A raw `count()` in the customer's project will never match it, and should not be reconciled against it. **This list is verifiable from source and worth re-reading rather than trusting**, since it drifts: `get_teams_with_billable_event_count_in_period` in `posthog/tasks/usage_report.py` (see the GitHub section in `data-rules.md`). `enhanced_persons_event_count_in_period` applies the identical exclusion list plus `person_mode IN ('full','force_upgrade')`.
- **No docs page enumerates which event types are billable**, so an event's billability is settled from that exclusion list, never cited to a pricing page. Anything not excluded is billed, `$web_vitals`, `$pageview`, `$autocapture` and `$pageleave` included.
- **Every `% of your events` share divides by the BILLABLE total, never the raw event count.** Subtract the excluded families from the direct-connection catalogue first, because they sit in the raw counts while billing on their own meters, and dividing by the raw total understates every lever you are about to recommend. Show the subtraction inline so the denominator is visible.
- **Before calling any event family a cost saving, confirm it is on this meter.** Products bill on separate meters, so an event type excluded here is not free, it is billed on its own product line. Some event types may appear on no meter at all. `$csp_violation` is the open case: neither the arithmetic nor the docs settle whether it bills, so do not tell a customer those reports are free, and do not recommend cutting them to save money either. **Note it, base nothing on it.** The general check is the same either way: reconstruct the meter from raw events, compare, and only name a family as a saving once it demonstrably moves this number.
- `enhanced_persons_event_count_in_period`: same query plus `person_mode IN ('full','force_upgrade')`: the identified (person-processed) events. Identified share = this / `event_count_in_period`; anonymous events are the difference between the two.
- `event_count_with_groups_in_period`: events carrying a group. Volume here with no group-analytics add-on is the "used incorrectly" finding; the add-on with 0 here is the "paid but unused" one.
- `has_non_zero_usage`: boolean, org only: did the org ingest anything this day.

**Per-SDK event split** (org+team, events/day, each key shaped `<sdk>_events_count_in_period`; the SDK list grows, so enumerate the live keys with `JSONExtractKeys` rather than trusting a roll call here). **Never present an SDK count as a percentage of billable events.** The per-SDK counts sum to *more* than `event_count_in_period`, because they are raw per-library counts taken before the billable exclusions and the dedupe above. Use them to rank which SDKs carry the volume, not to build a share-of-bill pie. Pick the SDKs by what the customer actually runs: mobile SDKs alone can be the majority of an org's volume, and `react_native_` is 0 for most orgs, so selecting it while omitting `android_` and `ios_` hides the real driver.

**Query cost** (org+team, 14 fields): `query_app_*`, `query_api_*`, `event_explorer_app_*`, `event_explorer_api_*`, each with `_bytes_read`, `_rows_read`, `_duration_ms`; plus `api_queries_bytes_read` and `api_queries_query_count`. `_app_` is the PostHog UI, `_api_` is their programmatic queries. Heavy `_api_` read volume beside light `_app_` usage means they query PostHog from their own tooling, which changes who to talk to and what to demo.

**Org metadata** (org only; the org-only keys are these plus the 19 `$`-prefixed ones; identity, seat, and date fields say what their names say):
- `teams`: the per-project map, `{"<team_id>": {111 fields}}`. See the size trap above.
- `site_url` / `$group_1`: **the org's region** (`https://us.posthog.com` or `https://eu.posthog.com`). This event is the reliable region signal, and it is US+EU combined in project 2.
- `realm` / `product` / `scope` / `instance_tag` / `deployment_infrastructure`: deployment shape (`cloud` vs self-hosted).
- `clickhouse_version` / `helm` / `plugins_enabled` / `plugins_installed` / `table_sizes` / `users_who_logged_in` / `users_who_logged_in_count` / `users_who_signed_up` / `users_who_signed_up_count`: **null on cloud**, populated for self-hosted only. Do not report these for a cloud account.
- `num_keys_in_properties`: the emitter's own key count, which is lower than the 155 keys observed on the ingested event (ingestion adds the `$`-prefixed ones).
- The 19 `$`-prefixed keys (`$lib`, `$lib_version`, `$os`, `$ip`, `$sent_at`, `$transformations_*`, and so on) describe the `posthog-python` cron that emits the report, not the customer. They are never customer signal.

## team-config

Cross-product opt-ins and replay settings: the on/off switches. For replay and heatmaps they are the primary project-2 signal, since capture data for those never lands in the customer's events (the capture-data guardrail in `data-rules.md`). For surveys and error tracking the opt-in is confirmatory, since capture also lands in events. Four rules for reading the result, all read off the column definitions:

**Confirm anything you are going to tell the customer about their own settings against the live remote config, which is stronger than this mirror.** It is what their SDK receives, and it costs one fetch with no site scan, login or browser: take `api_token` from this same query and `curl https://<region>.i.posthog.com/array/<token>/config`. Read the `sessionRecording` block (`sampleRate`, `minimumDurationMilliseconds`, `linkedFlag`, `urlTriggers`, `eventTriggers`, `urlBlocklist`, `masking`, `networkPayloadCapture`), plus `autocapture_opt_out`, `heatmaps` and the full `surveys` array with its targeting conditions, all for free in the same response. `sessionRecording: false` there means recording is off for that project outright, which is a different finding from the controls being unset, and the two are easy to conflate from the mirror alone. Where mirror and live config disagree, the live config wins and the disagreement is itself worth reporting: it means a stale sync, and every other setting you read from the mirror in that run is suspect.
- **Read NULL as off on the `*_opt_in` columns, not as missing data.** They are nullable with no default, and NULL is the common case rather than the exception. Only `session_recording_opt_in` defaults to false and is never NULL.
- **`autocapture_opt_out` runs the other way.** It is an opt-OUT, so `true` means the customer turned autocapture off, and `false` and NULL both mean it is on (autocapture is on by default). Do not read it like the columns beside it. It is the one autocapture signal that works on EU, where `posthog_action` does not exist, so the zero-Actions check (`actions-defined`) is unavailable.
- **The replay cost levers sit beside the opt-ins**: `replay_retention`, `console_logs_on`, `url_triggers`, `person_processing_off`. Retention varies per team inside one org, so read it per row rather than per account. Console logs on enlarge the replay payload. A live `url_triggers` regex is the answer to "why is replay recording that page".
- **`revenue_tracking_config` is the revenue mapping, and `{}` means revenue reports nothing** no matter what properties the customer sends. It is the first thing to read on any revenue question, because the fix is a settings change and not a code change (`SKILL.md`, Expansion). Read `base_currency` beside it: it defaults to USD, so a store selling in another currency reports converted into dollars until someone changes it.
- **`wizard_onboarding_for` is wizard state, not products-enabled. Never read it as "the products they use".** It records which onboarding wizard flows a team completed, and it is wrong in both directions: teams carry real replay volume without ever declaring replay here, and teams declare replay with no recordings at all. The org usage report volumes are the truth for what a customer uses. `onboarding_tasks` is the same class of data, useful as a map of wizard progress per team and nothing more.
```sql
SELECT id, name,
       session_recording_opt_in AS replay_on, heatmaps_opt_in AS heatmaps_on,
       surveys_opt_in AS surveys_on, autocapture_exceptions_opt_in AS error_tracking_on,
       autocapture_web_vitals_opt_in AS web_vitals_on,
       autocapture_opt_out AS autocapture_disabled,
       session_recording_minimum_duration_milliseconds AS min_duration_ms,
       session_recording_sample_rate AS sample_rate, session_recording_linked_flag AS linked_flag,
       session_recording_retention_period AS replay_retention,
       capture_console_log_opt_in AS console_logs_on,
       substring(coalesce(toString(session_recording_url_trigger_config), '[]'), 1, 60) AS url_triggers,
       person_processing_opt_out AS person_processing_off,
       base_currency,
       substring(coalesce(toString(revenue_tracking_config), '{}'), 1, 200) AS revenue_config,
       substring(coalesce(toString(onboarding_tasks), '{}'), 1, 90) AS onboarding_tasks,
       substring(coalesce(toString(has_completed_onboarding_for), '{}'), 1, 60) AS wizard_onboarding_for
FROM postgres.posthog_team WHERE organization_id = '<ORG_ID>' ORDER BY id LIMIT 20
```
Every column above exists in both regions, so this runs EU-swapped as written. **Swap the whole `postgres.posthog_team` token for the bare `eu_postgres_posthog_team`, with no `postgres.` prefix: `postgres.eu_postgres_posthog_team` errors with `Unknown table`.** Adding other columns may not swap: the EU team mirror is a strict column subset of the US one (notably `event_retention_months`, `logs_settings`, `session_recording_trigger_groups`, `default_experiment_stats_method`), and a US-only column errors on EU. Region handling is per column here, not only per table.

## proxy-domains

US only; empty = no managed proxy, the common case. `eu_postgres_posthog_proxyrecord` does not exist under any naming, so the EU swap errors rather than returning empty. On EU, managed proxy is unmeasurable from project 2, not absent. The table has no `deleted` column; `status` is the lifecycle field.
```sql
SELECT domain, status, created_at, updated_at
FROM postgres.posthog_proxyrecord WHERE organization_id = '<ORG_ID>' ORDER BY created_at DESC LIMIT 20
```

## Feature flags

**Usage report fields** (org+team):
- `billable_feature_flag_requests_count_in_period`: the billed flag requests for the day, the flag cost driver.
- `decide_requests_count_in_period`: `/decide` and `/flags` calls for the day.
- `local_evaluation_requests_count_in_period`: local-evaluation polls for the day, each billing as 10 requests.
- `ff_count` / `ff_active_count`: flags total vs active (cumulative). A wide gap is flag debt worth a cleanup nudge.

The billing rule, in code: `billable_feature_flag_requests = decide_requests + (local_evaluation_requests x 10)`. Read the two inputs side by side to see which evaluation pattern they run, and to say precisely which one is driving the bill.

**Admin activity** (the pattern, with a fixed 90 day window: flag work is sparse, and a 30 day window reads an active flag team as idle): `feature flag created` (useful properties: `creation_context`, `has_rollout_percentage`), `feature flag updated`, `feature flag scheduled`.

**Config reads** (US only: flag keys, names, and rollout have no EU source; flag counts work in both regions via `ff_count`). On EU, recover the keys the SDK actually evaluated from `$feature_flag_called` on the direct connection, per the EU flag-keys note in `data-rules.md`; dormant flags stay nameless there, so pair it with `ff_count` and report "N exist, K evaluated".

### flag-hygiene

How many exist, how many are live, and how many are stale enough to pitch a cleanup. The `deleted = false` count equals usage report `ff_count` exactly, so this doubles as the cross-check that the mirror filter is right. Two reading rules: `ff_count` counts archived flags among its total, so quote `flags_total` minus `flags_archived` as live, not `ff_count`; and `active_older_than_180d` is the stale-flag cleanup pitch in one number.
```sql
SELECT t.name AS project_name,
       count() AS flags_total,
       countIf(ff.active) AS flags_active,
       countIf(ff.archived) AS flags_archived,
       countIf(NOT ff.active AND NOT ff.archived) AS flags_disabled_not_archived,
       countIf(ff.created_at < now() - INTERVAL 180 DAY AND ff.active) AS active_older_than_180d
FROM postgres.posthog_featureflag ff JOIN postgres.posthog_team t ON ff.team_id = t.id
WHERE t.organization_id = '<ORG_ID>' AND ff.deleted = false
GROUP BY t.name ORDER BY flags_total DESC LIMIT 20
```

### stale-flags

The specific flags to name in outreach, oldest live first. `flag_name` is a free-text description field, so it often carries the customer's own cleanup note beside a flag they never removed. That is an outreach hook in their words rather than yours.
```sql
SELECT t.name AS project_name, ff.key AS flag_key, ff.name AS flag_name,
       ff.active, ff.archived, ff.created_at,
       dateDiff('day', ff.created_at, now()) AS age_days
FROM postgres.posthog_featureflag ff JOIN postgres.posthog_team t ON ff.team_id = t.id
WHERE t.organization_id = '<ORG_ID>' AND ff.deleted = false AND ff.active AND NOT ff.archived
ORDER BY ff.created_at ASC LIMIT 40
```

## Session replay (web + mobile)

**Usage report fields** (org+team):
- `recording_count_in_period`: session recordings for the day (0 = replay paid but unused; also the `before_send` kill signal).
- `recording_bytes_in_period`: replay bytes ingested for the day.
- `mobile_recording_count_in_period` / `mobile_billable_recording_count_in_period`: mobile recordings captured vs billed (replay cost is often mobile, not web).
- `mobile_recording_bytes_in_period`: mobile replay bytes for the day.
- `zero_duration_recording_count_in_period`: recordings with no duration: pure waste, and a concrete minimum-duration recommendation.
- `replay_vision_credits_used_in_period`: Replay Vision credits spent for the day, and its own cost line. Read it through `replay-vision` below, never as a footnote to the recording count.

**Region and vantage**: replay and heatmap capture data never lands in `events`, and project 2 cannot read a customer's replay tables at all (the full rule and the inside-their-project queries are in `SKILL.md`). From project 2: `team-config` opt-ins and settings for on/off and levers, the fields above for volume, and for heatmaps the opt-in is the ceiling (no volume field exists anywhere).

### replay-interaction

Admin engagement with replay. `play_time_minutes` is an admin's watch time in the replay UI, not their users' session length.

**The LIMIT caps people, not recordings, so a captured-versus-watched ratio built on this is a floor on a large org**: it returns the top 25 admins by watch time, so once more than 25 people opened a recording the viewed counts are truncated. Check the row count against the seat roster before quoting the ratio, and raise the LIMIT when they are close.
```sql
SELECT person.properties.email AS email, countIf(event = 'recording analyzed') AS recordings_analyzed,
       countIf(event = 'recording viewed') AS recordings_viewed,
       round(sumIf(toFloat(properties.play_time_ms), event = 'recording viewed summary') / 60000, 1) AS play_time_minutes,
       countIf(event = 'recording list filters changed') AS list_filters_changed
FROM events
WHERE event IN ('recording analyzed','recording viewed','recording viewed summary','recording list filters changed')
  AND timestamp >= now() - INTERVAL <days> DAY AND $group_0 = '<ORG_ID>'
GROUP BY email ORDER BY play_time_minutes DESC LIMIT 25
```

### replay-vision

Run on every account that records anything, both regions. Nonzero credits is a cost line; zero credits beside real recording volume is the adoption pitch (`SKILL.md`).

```sql
SELECT toDate(timestamp) AS day,
       argMax(properties.replay_vision_credits_used_in_period, timestamp) AS rv_credits,
       argMax(properties.recording_count_in_period, timestamp) AS recordings
FROM events
WHERE $group_0 = '<ORG_ID>' AND event = 'organization usage report'
  AND timestamp >= now() - INTERVAL 12 DAY
GROUP BY day ORDER BY day DESC LIMIT 12
```

Keep the window at 12 days or so; a much wider version of this query times out.

**Credits are the meter, not observations**, and credits per observation vary by the scanner's model, so a scan count never prices a month. Confirm the credit price, the monthly free tier, and the default org credit budget with a live docs search rather than from memory, then show the arithmetic: daily rate, days left in the cycle, free tier, budget.

**A run of zeros stepping up to a steady daily number means a scanner was switched on that day**, and mid-cycle adoption reads trivially cheap until you multiply the daily rate by a full cycle. That projection is the finding; the credits spent so far are not.

**The usage report carries spend and never says which scanner spent it, so two other routes matter.** `hog-functions` names the scanner: one with a digest writes an `internal_destination` row called `Replay Vision · <digest name>` (EU-swapped where needed), giving its name and creation date, which is what separates a customer who chose this from one who tripped over a default.

**And `$recording_observed` is a normal row on the `events` table**, so the scanner's actual output is queryable with plain SQL in either region: each observation carries the scanner's verdict, tags, score or summary. That is the route to what the scanner FOUND rather than what it cost, so reach for it when the question is whether the spend is buying anything. Do not report Replay Vision output as unreadable; only the per-scanner spend split is.

**A hit session-replay or product-analytics billing limit starves the scanner**: capped recordings are dropped at ingestion, so it reads nothing while the spend already booked stands. Whenever an account runs a billing limit and a scanner together, say that pairing out loud.

## Experiments

No experiment volume source exists anywhere in project 2; definitions are US mirror or EU project 1 only (`data-rules.md`).

### experiment-inventory

One row per experiment, with true status. **Run `experiment-definitions` first and treat this as the enrichment**, because this query reads lifecycle EVENTS: an account whose experiments were all created and launched outside the window returns zero rows here while the mirror shows several, and widening the window far enough to catch them can time out. Read `status` from `argMax(event, timestamp)`, the actual latest lifecycle event, and query the **whole** lifecycle event list. Anything narrower misreports, because stopping an experiment emits `experiment stopped` and `experiment completed` together, and archiving emits neither. Deriving status from a created/launched/completed subset therefore calls every stopped experiment "completed", calls paused ones "launched", and loses archived ones entirely. `stats_method` is only ever set on `experiment completed`, so NULL means "not finished yet", not "unknown method".
```sql
SELECT max(timestamp) AS latest_activity, arrayStringConcat(groupUniqArray(person.properties.email), ', ') AS created_by,
       max(properties.experiment_name) AS experiment_name,
       multiIf(argMax(event, timestamp) = 'experiment archived','archived',
               argMax(event, timestamp) = 'experiment completed','completed',
               argMax(event, timestamp) = 'experiment stopped','stopped',
               argMax(event, timestamp) = 'experiment paused','paused',
               argMax(event, timestamp) IN ('experiment launched','experiment resumed'),'launched',
               argMax(event, timestamp) IN ('experiment created','experiment reset'),'draft','unknown') AS status,
       max(properties.feature_flag_key) AS flag_key, max(properties.variant_count) AS variants,
       max(properties.metrics_count) AS metrics,
       maxIf(properties.stats_method, properties.stats_method IS NOT NULL) AS stats_method,
       round(maxIf(toFloat(properties.duration), event = 'experiment completed') / 86400, 1) AS duration_days
FROM events
WHERE timestamp >= now() - INTERVAL <days> DAY AND $group_0 = '<ORG_ID>'
  AND event IN ('experiment created','experiment launched','experiment completed','experiment stopped',
                'experiment archived','experiment paused','experiment resumed','experiment reset')
  AND properties.experiment_id IS NOT NULL AND person.properties.email IS NOT NULL
GROUP BY properties.experiment_id ORDER BY latest_activity DESC LIMIT 30
```
An experimenting account fills this LIMIT easily, and the ORDER BY means what you get is their most recent experiments. Raise it, or shorten `<days>`, before reading the list as their whole inventory.


### experiment-engagement

`viewed recordings from experiment` is deliberately absent: the event carries no experiment reference, so it cannot be grouped by experiment and every row would be dropped by the filter below. Count it from the replay queries instead.
```sql
SELECT person.properties.email AS user, coalesce(properties.experiment_name, properties.name) AS experiment_name,
       max(timestamp) AS latest_activity,
       arrayStringConcat(arrayFilter(x -> x != '', [
         if(countIf(event='experiment viewed')>0, concat('viewed (', toString(countIf(event='experiment viewed')), ')'), ''),
         if(countIf(event='experiment metrics refreshed')>0, concat('metrics refreshed (', toString(countIf(event='experiment metrics refreshed')), ')'), ''),
         if(countIf(event='experiment variant shipped')>0, concat('variant shipped (', toString(countIf(event='experiment variant shipped')), ')'), ''),
         if(countIf(event='experiment shared metric created')>0, concat('shared metric created (', toString(countIf(event='experiment shared metric created')), ')'), ''),
         if(countIf(event='experiment ai summary requested')>0, concat('ai summary (', toString(countIf(event='experiment ai summary requested')), ')'), ''),
         if(countIf(event='experiment metric breakdown added')>0, concat('breakdown added (', toString(countIf(event='experiment metric breakdown added')), ')'), ''),
         if(countIf(event='experiment timeseries viewed')>0, concat('timeseries viewed (', toString(countIf(event='experiment timeseries viewed')), ')'), ''),
         if(countIf(event='experiment release conditions viewed')>0, concat('release conditions viewed (', toString(countIf(event='experiment release conditions viewed')), ')'), '')
       ]), ', ') AS activity
FROM events
WHERE timestamp >= now() - INTERVAL <days> DAY AND $group_0 = '<ORG_ID>'
  AND event IN ('experiment viewed','experiment metrics refreshed','experiment variant shipped',
                'experiment shared metric created','experiment ai summary requested','experiment metric breakdown added',
                'experiment timeseries viewed','experiment release conditions viewed')
  AND coalesce(properties.experiment_id, properties.id) IS NOT NULL
GROUP BY person.properties.email, properties.experiment_id, experiment_name ORDER BY latest_activity DESC LIMIT 50
```

### experiment-definitions

US mirror; the lifecycle split, not just a total. `never_launched` beside `running` is the adoption story: experiments created and abandoned before launch read differently from a team shipping tests.

**Never alias an aggregate to the name of the column it reads.** `countIf(e.archived) AS archived` shadows `e.archived`, so the resolver hits a circular reference and the EU endpoint returns a hard **HTTP 400**. The US path tolerates it; both variants below are aliased `archived_count` instead. The same shape bites anywhere in this file, so check any `countIf(x) AS x` you add.
```sql
SELECT t.name AS project_name, count() AS experiments_total,
       countIf(e.archived) AS archived_count,
       countIf(e.start_date IS NOT NULL AND e.end_date IS NULL AND NOT e.archived) AS running,
       countIf(e.start_date IS NULL) AS never_launched,
       countIf(e.end_date IS NOT NULL) AS completed
FROM postgres.posthog_experiment e JOIN postgres.posthog_team t ON e.team_id = t.id
WHERE t.organization_id = '<ORG_ID>' AND e.deleted = false
GROUP BY t.name ORDER BY experiments_total DESC LIMIT 20
```

### experiment-definitions-eu

The one read that leaves project 2: `POST https://eu.posthog.com/api/projects/1/query/` with `POSTHOG_PERSONAL_API_KEY_EU` (mechanics in `data-rules.md`). Same SQL with EU prefixes. The per-project rows sum to the org's `deleted = false` total. With no EU key set, report EU experiments as unavailable rather than reading the gap as zero.
```sql
SELECT t.name AS project_name, count() AS experiments_total,
       countIf(e.archived) AS archived_count,
       countIf(e.start_date IS NOT NULL AND e.end_date IS NULL AND NOT e.archived) AS running,
       countIf(e.start_date IS NULL) AS never_launched,
       countIf(e.end_date IS NOT NULL) AS completed
FROM eu_postgres_posthog_experiment e JOIN eu_postgres_posthog_team t ON e.team_id = t.id
WHERE t.organization_id = '<ORG_ID>' AND e.deleted = false
GROUP BY t.name ORDER BY experiments_total DESC LIMIT 20
```

## Surveys

**Usage report fields** (org+team): `survey_count` (surveys created, cumulative), `survey_responses_count_in_period` (responses for the day; surveys built with no responses is the "shipped but not launched" finding).

### survey-builds

One row per survey; `email` is the admin who built it, and respondents are `survey_responses_count_in_period`, never this.
```sql
SELECT max(person.properties.email) AS email, properties.name AS survey_name,
       maxIf(properties.survey_type, event = 'survey created') AS type,
       maxIf(properties.creation_source, event = 'survey created') AS creation_source,
       maxIf(toFloat(properties.questions_length), properties.questions_length IS NOT NULL) AS questions,
       max(properties.has_branching_logic) AS branching_logic, max(properties.has_partial_responses) AS partial_responses,
       countIf(event = 'survey created') > 0 AS created, countIf(event = 'survey launched') > 0 AS launched,
       countIf(event = 'survey edited') AS edits
FROM events
WHERE timestamp >= now() - INTERVAL <days> DAY AND $group_0 = '<ORG_ID>'
  AND event IN ('survey created','survey edited','survey launched') AND person.properties.email IS NOT NULL
GROUP BY survey_name ORDER BY launched DESC, edits DESC, survey_name LIMIT 50
```

### survey-definitions

US only; which surveys exist and whether they ever launched. Filter `archived`, not `deleted` (the shared filter rule above); the row count cross-checks usage report `survey_count`.

**On EU there is no mirror at all**: `eu_postgres_posthog_survey` does not exist under any naming, so this is UNMEASURABLE rather than "US only" in the sense of a table you could swap a prefix on. Reconstruct survey state from `survey_count` on the usage report plus the `survey created` / `survey launched` admin events, which is enough to separate the three cases that matter: never built, built and never launched, launched and silent.
```sql
SELECT t.name AS project_name, s.name AS survey_name, s.type AS survey_type,
       s.archived, s.created_at, s.start_date, s.end_date,
       if(s.start_date IS NULL, 'never launched', if(s.end_date IS NOT NULL, 'stopped', 'running')) AS state
FROM postgres.posthog_survey s JOIN postgres.posthog_team t ON s.team_id = t.id
WHERE t.organization_id = '<ORG_ID>' AND s.archived = false
ORDER BY s.created_at DESC LIMIT 40
```

### surveys-paid-check

A `paid-*` plans_map key is tier enrollment, not spend: pair it with a non-zero forecast or invoice line before claiming they pay for an unused product.

Region-agnostic: usage report plus `billing_customer`, no mirror, so it runs unchanged on EU. Answers two findings in one read. A surveys plan with `surveys_defined = 0` is paying for a product they never set up. `surveys_defined > 0` with `peak_day_responses_8d = 0` is shipped and silent, the stronger finding. Pair the second with `survey-definitions` to name which survey is running. `billing_customer` is live and holds exactly one row per org, so the plan key is current and the join cannot fan out. **The two aggregates differ on purpose, so do not unify them.** `surveys_defined` reads `survey_count`, which is cumulative, so `argMax` pins it to the latest report. `peak_day_responses_8d` reads a **daily** field, and the finding is "did anyone answer at all", so the 8-day peak is the right test and `max` is the correct aggregate: `argMax` would read a single quiet day as silence, which is a false "shipped and silent". `max` also absorbs the same day being emitted twice as late data lands, where a `sum` would double-count it.
```sql
SELECT JSONExtractString(toString(bc.plans_map), 'surveys') AS surveys_plan,
       argMax(e.properties.survey_count, e.timestamp) AS surveys_defined,
       max(toFloat(e.properties.survey_responses_count_in_period)) AS peak_day_responses_8d
FROM events e, postgres.prod.billing_customer bc
WHERE bc.organization_id = '<ORG_ID>'
  AND e.$group_0 = '<ORG_ID>' AND e.event = 'organization usage report'
  AND e.timestamp >= now() - INTERVAL 8 DAY
GROUP BY surveys_plan LIMIT 1
```

## Error tracking

**Usage report fields** (org+team):
- `exceptions_captured_in_period`: exceptions captured for the day.
- `<sdk>_exceptions_captured_in_period`: per-SDK exceptions (enumerate the live keys with `JSONExtractKeys`; `unknown_` is one of them). Unlike the event split, these do reconcile against the total.
- `issues_created_total`: cumulative issues created.
- `symbol_sets_count` / `resolved_symbol_sets_count`: uploaded vs resolved symbol sets: the symbolication-health pair (a big gap means unreadable stack traces).

### error-admin-activity

Who on their team works the error-tracking UI. Their product's exception volume is `exceptions_captured_in_period`, never this. Two events are unreachable under any scope and are gone from the list: `error_tracking_issue_created` and `error_tracking_issue_reopened` carry **no org attribution of any kind**, neither `$group_0` nor the person property. They can never return a row, so putting them back reads as "this customer never creates or reopens issues" when the query simply could not see them. `error_tracking_symbol_set_uploaded` earns its place: it is the customer wiring sourcemap upload into their build, which is real instrumentation rather than clicking. It is a backend event with org attribution but no person, so `coalesce` the email into one `(backend, no user)` row instead of dropping it. `error_tracking_issue_merged` and `error_tracking_fingerprint_embedding_result_metrics` are org-attributed too but are PostHog's own grouping machinery firing, not a customer action: leave them out.
```sql
SELECT coalesce(person.properties.email, '(backend, no user)') AS user, max(timestamp) AS latest_activity,
       arrayStringConcat(arrayFilter(x -> x != '', [
         if(countIf(event='error_tracking_issues_list_viewed')>0, concat('issues list viewed (', toString(countIf(event='error_tracking_issues_list_viewed')), ')'), ''),
         if(uniqIf(properties.issue_id, event='error_tracking_issue_viewed')>0, concat(toString(uniqIf(properties.issue_id, event='error_tracking_issue_viewed')),' issues viewed'), ''),
         if(countIf(event='error_tracking_stacktrace_explored')>0, concat('stacktrace explored (', toString(countIf(event='error_tracking_stacktrace_explored')), ')'), ''),
         if(countIf(event='error_tracking_query_executed')>0, concat('query executed (', toString(countIf(event='error_tracking_query_executed')), ')'), ''),
         if(countIf(event='error_tracking_issue_update_status')>0, concat('issue status updated (', toString(countIf(event='error_tracking_issue_update_status')), ')'), ''),
         if(countIf(event='error_tracking_issue_bulk_resolve')>0, concat('issue bulk resolved (', toString(countIf(event='error_tracking_issue_bulk_resolve')), ')'), ''),
         if(countIf(event='error_tracking_insights_viewed')>0, concat('insights viewed (', toString(countIf(event='error_tracking_insights_viewed')), ')'), ''),
         if(countIf(event='error_tracking_alert_created')>0, concat('alert created (', toString(countIf(event='error_tracking_alert_created')), ')'), ''),
         if(countIf(event='error_tracking_symbol_set_uploaded')>0, concat('symbol sets uploaded (', toString(countIf(event='error_tracking_symbol_set_uploaded')), ')'), '')
       ]), ', ') AS activity
FROM events
WHERE timestamp >= now() - INTERVAL <days> DAY AND $group_0 = '<ORG_ID>'
  AND event IN ('error_tracking_issues_list_viewed','error_tracking_issue_viewed','error_tracking_query_executed',
                'error_tracking_stacktrace_explored','error_tracking_issue_update_status','error_tracking_issue_bulk_resolve',
                'error_tracking_insights_viewed','error_tracking_alert_created','error_tracking_symbol_set_uploaded')
GROUP BY user ORDER BY latest_activity DESC LIMIT 30
```
The pairing to read for: a big `symbol sets uploaded` row beside thin human rows means they instrumented error tracking and then stopped looking at it, which is the "you are paying for this, here is how to use it" opening.

## Data warehouse

**Usage report fields** (org+team):
- `rows_synced_in_period`: billable warehouse rows synced for the day.
- `free_historical_rows_synced_in_period`: non-billable historical backfill rows for the day (a first-sync spike lands here, not in the line above).
- `rows_exported_in_period`: rows sent out via batch export for the day.
- `dwh_tables_storage_in_s3_in_mib` / `dwh_mat_views_storage_in_s3_in_mib` / `dwh_total_storage_in_s3_in_mib`: warehouse S3 storage in MiB (total is the sum of the two parts).
- `active_external_data_schemas_in_period`: live warehouse source schemas. `active_batch_exports_in_period`: live batch exports.

### warehouse-activity

Count sources from **`data warehouse source created`**, the live funnel event. It carries `source_type` (snake_case: `Stripe`, `Postgres`, `MetaAds`, ...) plus `source`, the surface the source was created from (`web`, `wizard`, `mcp`, `api`), which is the interesting half: a source created via `wizard` or `mcp` says the customer is already on the agentic path. Two shape rules. **`source created` fires on the same sessions as `data warehouse source created`**, so it is the legacy twin of the same action and summing the two double-counts; count the funnel event alone. **The source-type key changed case between them**, camelCase `sourceType` on the older `source created` / `schema reloaded`, snake_case `source_type` on the funnel event, so `coalesce` both or the column reads NULL for whichever family you missed.

```sql
SELECT person.properties.email AS email,
       coalesce(properties.source_type, properties.sourceType) AS source_type,
       countIf(event = 'data warehouse source created') AS sources_created,
       arrayStringConcat(groupUniqArrayIf(toString(properties.source), event = 'data warehouse source created'), ', ') AS created_via,
       countIf(event = 'source deleted') AS sources_deleted,
       countIf(event = 'schema reloaded') AS schemas_reloaded,
       countIf(event = 'materialized view created') AS mat_views_created,
       max(timestamp) AS latest
FROM events
WHERE timestamp >= now() - INTERVAL <days> DAY AND $group_0 = '<ORG_ID>'
  AND event IN ('data warehouse source created','source deleted','schema reloaded','materialized view created')
  AND person.properties.email IS NOT NULL
GROUP BY email, source_type
ORDER BY sources_created DESC, mat_views_created DESC, latest DESC LIMIT 30
```
Empty is common and is a real answer: most accounts never connect a warehouse source. Widen to 120 days before calling it never, since source creation is a one-off setup act rather than recurring behavior and a short window misses it.

### warehouse-tables

Which sources sync the most rows, for incremental-sync recommendations.
```sql
SELECT dwt.team_id AS team, dwt.name AS table_name, dwt.row_count, dwt.created_at, dwt.updated_at, dwt.deleted_at
FROM postgres.posthog_datawarehousetable dwt JOIN postgres.posthog_team t ON dwt.team_id = t.id
WHERE t.organization_id = '<ORG_ID>' AND (dwt.deleted = false OR dwt.deleted IS NULL)
ORDER BY dwt.row_count DESC NULLS LAST LIMIT 50
```

### warehouse-sync-jobs

Sharper than `warehouse-tables`: `row_count` is the current table size, this is the actual bill driver. `posthog_externaldatajob` carries per-job `rows_synced` and a `billable` boolean, joinable by team to org. `billable_rows_synced` cross-checks Vitally `rowsSyncedLast30DaysIfSendingData`. A high `limit_blocked_jobs` count = the customer is hammering their warehouse billing limit, a real bill-shock/near-cap signal.
```sql
SELECT t.name AS project_name,
       sumIf(edj.rows_synced, edj.billable AND edj.status = 'Completed') AS billable_rows_synced,
       countIf(edj.status = 'Completed') AS completed_jobs,
       countIf(edj.status = 'Failed') AS failed_jobs,
       countIf(edj.status = 'BillingLimitReached') AS limit_blocked_jobs
FROM postgres.posthog_externaldatajob edj JOIN postgres.posthog_team t ON edj.team_id = t.id
WHERE t.organization_id = '<ORG_ID>' AND edj.created_at >= now() - INTERVAL <days> DAY
GROUP BY t.name ORDER BY billable_rows_synced DESC LIMIT 30
```

### warehouse-schema-health

Run whenever `active_external_data_schemas` > 0 OR a data warehouse plan exists; the trait undercounts, so a warehouse plan alone is enough to run this, even with a $0 forecast. Reads ALL schemas, not just syncing ones, and classifies: `Failed` = broken setup (`latest_error` names the fix, e.g. "Primary key required for incremental syncs"); `should_sync = false` with no `last_synced_at` = an abandoned setup attempt; `Completed` but `last_synced_at` older than 2x the frequency = stale despite Completed. An abandoned-warehouse story is a first-class onboarding finding: the customer tried to adopt, hit an error wall, and gave up. The table names alone reveal their internal data model. Note: `warehouse-sync-jobs` returns EMPTY when no jobs ran in the window, so an empty result there with nonzero `active_external_data_schemas` means run this, not "no warehouse story".
```sql
SELECT t.name AS project_name, eds.name AS schema_name, eds.sync_type AS sync_type, eds.status AS status,
       eds.should_sync AS should_sync, eds.sync_frequency_interval AS freq_seconds,
       eds.last_synced_at AS last_synced, substring(eds.latest_error, 1, 120) AS latest_error
FROM postgres.posthog_externaldataschema eds JOIN postgres.posthog_team t ON eds.team_id = t.id
WHERE t.organization_id = '<ORG_ID>' AND (eds.deleted = false OR eds.deleted IS NULL)
ORDER BY eds.last_synced_at DESC NULLS LAST LIMIT 40
```
Use the postgres app-DB tables above from project 2. (Inside a customer's own project the equivalents are `system.source_sync_jobs`, `system.source_schemas` and `system.data_warehouse_sources`, which is what the call-prep notebook prompt reaches for; from project 2 those return PostHog's own data.)

## CDP and destinations

**Usage report fields** (org+team):
- `cdp_billable_invocations_in_period`: billed destination/transformation invocations for the day, the CDP cost driver.
- `hog_function_calls_in_period` / `hog_function_fetch_calls_in_period`: hog function calls vs outbound fetches for the day.
- `active_hog_destinations_in_period` / `active_hog_transformations_in_period`: live destinations vs transformations.
- `workflow_billable_invocations_in_period`: billed workflow invocations for the day.
- `workflow_emails_sent_in_period` / `workflow_push_sent_in_period` / `workflow_sms_sent_in_period`: messages sent per channel for the day.

**Admin activity** (the pattern): event `hog function saved`, with properties `template_name` (the destination), `type`, and `enabled`; group by email and destination, and split `countIf(properties.enabled = true)` vs `= false` to separate live saves from drafts.

### hog-functions

Destinations + transformations actually configured. **Scan the `transformation` rows before interpreting any event-volume result**, because one that samples or drops events silently rewrites the denominator under every count and share you are about to compute (the rule is in `data-rules.md`). Read the `inputs` column on a suspect row for the percentage and which events it covers, and read `created_at` as the date the customer's numbers changed meaning. Sampling and drop templates are the ones to look for; GeoIP is the common harmless row.
```sql
SELECT hf.name, hf.type, hf.created_at, hf.enabled, hf.template_id
FROM postgres.posthog_hogfunction hf JOIN postgres.posthog_team t ON hf.team_id = t.id
WHERE t.organization_id = '<ORG_ID>' AND hf.deleted = false ORDER BY hf.created_at ASC LIMIT 50
```

### batch-exports

```sql
SELECT b.name, b.created_at, b.paused, b.interval, d.type AS destination_type
FROM postgres.posthog_batchexport b JOIN postgres.posthog_batchexportdestination d ON b.destination_id = d.id
JOIN postgres.posthog_team t ON b.team_id = t.id
WHERE t.organization_id = '<ORG_ID>' AND b.deleted = false ORDER BY b.created_at ASC LIMIT 50
```

## AI Observability

**Usage report fields** (org+team): `ai_event_count_in_period` (LLM-analytics events from the customer's product, for the day), and `event_count_from_langfuse_in_period` / `event_count_from_helicone_in_period` / `event_count_from_traceloop_in_period` / `event_count_from_keywords_ai_in_period` (events ingested from a competing LLM-observability tool: non-zero means they run that tool beside PostHog, a consolidation opening, and the only place this event names a competitor).

The customer's AI spend queries (their PostHog AI line from project 2; their product's own LLM spend off the direct ClickHouse connection in either region) are in `queries-money.md`.

### posthog-ai-chat

Their admins using PostHog AI, not their product's LLM. **Read adoption from all four signals, never from `chat with ai` alone**: an account can drive PostHog AI hard and fire that event zero times, in which case a single-event filter reports the heaviest AI user on the account as a non-user.
```sql
SELECT person.properties.email AS email,
       countIf(event = 'chat with ai') AS prompts,
       countIf(event = '$conversations_loaded') AS conv_loaded,
       countIf(event = 'max conversation turn completed') AS turns,
       countIf(event = 'query executed' AND properties.source = 'posthog_ai') AS ai_queries,
       max(timestamp) AS latest
FROM events
WHERE $group_0 = '<ORG_ID>' AND timestamp >= now() - INTERVAL <days> DAY
  AND (event IN ('chat with ai','$conversations_loaded','max conversation turn completed')
       OR (event = 'query executed' AND properties.source = 'posthog_ai'))
  AND person.properties.email IS NOT NULL
GROUP BY email ORDER BY ai_queries + prompts + conv_loaded DESC LIMIT 25
```
`ai_queries` is the column that carries the weight: it counts questions that actually ran a query, and it survives when the chat events are absent. `conv_loaded` counts panel opens, so it runs high and shallow. Cross-check the total against `self-driving-check`, which buckets the same three chat events.

For the prompt text itself, only `chat with ai` carries a `prompt` property, so run this second and treat an empty result as "no prompts captured", never as "no PostHog AI usage":
```sql
SELECT person.properties.email AS email, toStartOfDay(timestamp) AS day,
       substring(toString(properties.prompt), 1, 200) AS question_preview
FROM events
WHERE event = 'chat with ai' AND timestamp >= now() - INTERVAL <days> DAY AND $group_0 = '<ORG_ID>'
GROUP BY email, day, question_preview ORDER BY day DESC, email, question_preview LIMIT 20
```
Twenty prompts is a sample of the newest day, not their whole AI history. `email` and `question_preview` are in the ORDER BY only to make the truncation repeatable; raise the LIMIT to read further back.

**Raise it on any cost or call-prep run, because this is where the customer's stated goal lives in their own words.** Nothing else in the skill reaches it. What they asked PostHog AI is what they were trying to do, in sequence and dated: the question they could not answer, the setting they went looking for, the fix they then applied. It is a required input to `change-timeline` (`queries-account.md`). Quote them verbatim into a brief; a customer's own sentence outranks any restatement of it.

## Group analytics

**Usage report fields**: `event_count_with_groups_in_period` (in the shared volume list above) and `group_types_total` (cumulative; 0 with group-analytics volume, or the reverse, is the group-analytics misconfiguration tell).

### group-types

US only. Empty means no group types defined, **but only once you have confirmed the sync is not paused**: this mirror can sit paused and return zero rows silently while `group_types_total` on the usage report is nonzero. Read the resolver warning and cross-check that field before calling it zero. Group Analytics is a cumulative add-on: switching it on bills every identified event at the group rate from then on. So "add-on paid, no group types defined" is a concrete cost cut, and this query plus `event_count_with_groups_in_period` from the usage report is the pair that proves it. `eu_postgres_posthog_grouptypemapping` is unreadable, so on EU this check is unavailable rather than zero.
```sql
SELECT t.name AS project_name, gtm.group_type, gtm.group_type_index, gtm.name_singular, gtm.name_plural
FROM postgres.posthog_grouptypemapping gtm JOIN postgres.posthog_team t ON gtm.team_id = t.id
WHERE t.organization_id = '<ORG_ID>' ORDER BY t.name, gtm.group_type_index LIMIT 30
```

## Web analytics

No per-org web analytics volume source exists in project 2, in either region (the same absence as experiment volume and heatmap volume). Adoption reads only from admin behavior: web-analytics paths in `page-paths` and categories in `event-breakdown`.

## Logs

**Usage report fields** (org+team): `logs_records_in_period` (records/day), `logs_bytes_in_period` and `logs_mb_in_period` (volume/day), `logs_retention_14d_mb_in_period` / `logs_retention_30d_mb_in_period` / `logs_retention_90d_mb_in_period` (MB/day split by retention tier, so a retention downgrade is a costed recommendation), and the per-SDK `<sdk>_logs_records_in_period` keys (enumerate live). Log capture never lands in `events` (the rule in `SKILL.md`).

## Product analytics (insights, dashboards, actions, cohorts, properties)

**Usage report fields** (org+team, cumulative): `dashboard_count` (dashboards in the org; high count with no recent dashboard views = built and abandoned), `dashboard_shared_count` / `dashboard_tagged_count` / `dashboard_template_count` (shared publicly, tagged, and template-derived dashboards).

**Admin activity** (the pattern, `countIf` per event): `dashboard created`, `dashboard updated`, `insight created`, `insight subscription created`, `action created`, `cohort created` for the builder view; `dashboard analyzed`, `viewed dashboard`, `dashboard refreshed`, `dashboard insight refreshed` for the consumer view, adding `count(DISTINCT properties.dashboard_id) AS unique_dashboards` for breadth.

### dashboard-views

Views per dashboard, with the shared-vs-creator split.
```sql
SELECT person.properties.email AS email, properties.dashboard.name AS dashboard_name, count() AS views,
       properties.item_count AS dashboard_items,
       CASE WHEN properties.is_shared = true AND properties.viewer_is_creator = false THEN 'shared - not creator'
            WHEN properties.is_shared = true THEN 'is shared'
            WHEN properties.viewer_is_creator = false THEN 'not creator' ELSE NULL END AS other
FROM events
WHERE event IN ('viewed dashboard','dashboard analyzed') AND timestamp >= now() - INTERVAL <days> DAY
  AND $group_0 = '<ORG_ID>' AND properties.dashboard_id IS NOT NULL
GROUP BY properties.dashboard_id, email, dashboard_items, other, dashboard_name ORDER BY views DESC LIMIT 50
```

### insights-viewed

Which insights each admin returns to, by query kind.
```sql
SELECT person.properties.email AS email, properties.query_kind AS type,
       arrayStringConcat(arrayMap(name -> concat('\'', name, '\''), groupUniqArray(properties.insight.name)), ', ') AS insights,
       count() AS views, count(DISTINCT properties.insight_id) AS unique_insights
FROM events
WHERE event IN ('insight analyzed','insight viewed') AND timestamp >= now() - INTERVAL <days> DAY
  AND $group_0 = '<ORG_ID>' AND properties.query_kind IS NOT NULL
GROUP BY person.properties.email, properties.query_kind ORDER BY views DESC LIMIT 50
```

### actions-defined

US only; zero actions + significant autocapture = waste. EU has no `posthog_action` in either project, so on EU this check is unmeasurable rather than zero (`data-rules.md`); the EU fallback signal is `autocapture_opt_out` in `team-config`.
```sql
SELECT a.name FROM postgres.posthog_action a JOIN postgres.posthog_team t ON a.team_id = t.id
WHERE t.organization_id = '<ORG_ID>' AND a.deleted = false ORDER BY a.name ASC LIMIT 200
```

### property-definitions

US only; instrumentation breadth per project, and the event/person/group split. `posthog_propertydefinition` has no `deleted` column, so there is nothing to filter. `type` is 1 event, 2 person, 3 group. On EU, read the direct connection's `property_definitions` instead: `team_id` and `type` are Strings there, `is_numerical` does not exist (drop it from the SELECT), and rows repeat per (event, property), so `count()` overcounts; count `DISTINCT name`.
```sql
SELECT t.name AS project_name, count() AS property_definitions,
       countIf(pd.is_numerical) AS numerical,
       countIf(pd.type = 1) AS event_props, countIf(pd.type = 2) AS person_props, countIf(pd.type = 3) AS group_props
FROM postgres.posthog_propertydefinition pd JOIN postgres.posthog_team t ON pd.team_id = t.id
WHERE t.organization_id = '<ORG_ID>'
GROUP BY t.name ORDER BY property_definitions DESC LIMIT 20
```

### cohort-inventory

US; size, staleness, and whether calculation is erroring. `last_calculation` far behind `created_at` on a large cohort, or a nonzero `errors_calculating`, is a broken-cohort finding.
```sql
SELECT t.name AS project_name, c.name AS cohort_name, c.count AS people, c.is_static,
       c.created_at, c.last_calculation, c.errors_calculating
FROM postgres.posthog_cohort c JOIN postgres.posthog_team t ON c.team_id = t.id
WHERE t.organization_id = '<ORG_ID>' AND c.deleted = false
ORDER BY c.count DESC NULLS LAST LIMIT 40
```

### cohort-count-eu

A count from a frozen snapshot, so return the as-of date with it, every time. Naming trap: the table is `eu_posthog_cohortcalculationhistory`, with no `postgres` in it. It stopped advancing, so `snapshot_as_of` is the date the count describes and it drifts further from today every week. Date-check it before quoting the number, and never present it as current.
```sql
SELECT count(DISTINCT cch.cohort_id) AS distinct_cohorts,
       max(cch.started_at) AS snapshot_as_of,
       min(cch.started_at) AS earliest_row
FROM eu_posthog_cohortcalculationhistory cch JOIN eu_postgres_posthog_team t ON cch.team_id = t.id
WHERE t.organization_id = '<ORG_ID>' LIMIT 1
```

### dashboard-definitions

`eu_postgres_posthog_dashboarditem` has no `last_viewed_at` (only `last_modified_at`); read view activity from `stale-dashboards`, never from the item mirror.

On EU run the same read against `eu_postgres_posthog_dashboard`, which is readable, with one exception: `eu_postgres_posthog_dashboardtile.deleted` is NULL on live rows (deleted tiles carry true), so filter tiles with `deleted IS NULL OR deleted = false` or every live tile reads as missing. `created_last_90d` high with `pinned` low is a customer generating dashboards nobody curates.

**A per-parent count of exactly zero across ALL parents is a join artifact until a direct count says otherwise.** A `LEFT JOIN` from `eu_postgres_posthog_dashboard` onto `eu_postgres_posthog_dashboardtile` can return `tiles = 0` for every dashboard with no error, and it does not reproduce on a rerun, so treat it as intermittent rather than a rule about joins. The check is cheap and the failure is expensive: zero tiles everywhere reads as "they built empty dashboards and abandoned them", a plausible sentence to ship to a customer. Confirm any all-zero with `SELECT ... WHERE dashboard_id IN (...)` on the child table before it becomes a finding.

Two more columns worth knowing on the EU mirror. `eu_postgres_posthog_dashboard.last_accessed_at` exists and is populated, which the US recipe does not mention: it corroborates `stale-dashboards` and gives per-dashboard staleness the query log cannot. `eu_postgres_posthog_dashboarditem.last_refresh` is the opposite, **almost always NULL**, so it is a non-signal and never evidence a dashboard went stale.
```sql
SELECT t.name AS project_name, count() AS dashboards_total,
       countIf(d.created_at >= now() - INTERVAL 90 DAY) AS created_last_90d,
       countIf(d.pinned) AS pinned,
       min(d.created_at) AS oldest, max(d.created_at) AS newest
FROM postgres.posthog_dashboard d JOIN postgres.posthog_team t ON d.team_id = t.id
WHERE t.organization_id = '<ORG_ID>' AND d.deleted = false
GROUP BY t.name ORDER BY dashboards_total DESC LIMIT 20
```

### stale-dashboards

Both regions; the built-and-abandoned check, and the shape to copy for other objects. `query_log_archive_us` / `_eu` carries `lc_org_id` as a String, so this scopes by org with no team join and no collision hazard. The same table carries `lc_insight_id`, `lc_cohort_id`, `lc_experiment_id`, `lc_access_method`, and `lc_product`, so the same defined-versus-touched shape extends to those objects. **Carry the `> 0` guard across with it.** Rows where the object id is unset store 0 rather than NULL, so `uniq(lc_<object>_id)` without it counts that 0 as a distinct object and overstates by exactly one on every object type, which is the difference between "they have a cohort nobody touches" and "they have none". A large gap between the two numbers is the abandoned-dashboards story, and it reads as an onboarding finding rather than a scolding: they built, then stopped returning.
US variant:
```sql
SELECT
  (SELECT count() FROM postgres.posthog_dashboard d JOIN postgres.posthog_team t ON d.team_id = t.id
   WHERE t.organization_id = '<ORG_ID>' AND d.deleted = false) AS dashboards_defined,
  (SELECT uniq(lc_dashboard_id) FROM query_log_archive_us
   WHERE lc_org_id = '<ORG_ID>' AND event_time >= now() - INTERVAL 30 DAY
     AND lc_dashboard_id > 0) AS dashboards_touched_30d
LIMIT 1
```
The usage report's `dashboard_count` equals the mirror count in both regions, which makes this the cross-check that catches a broken mirror read. `argMax` rather than `max` on `dashboard_count`: it is cumulative but not monotonic, so on an org that deleted a dashboard in the window `max` reports the 8-day peak as the current count and widens the abandoned gap it is measuring.
EU variant (usage report for the defined count, EU query log for touched):
```sql
SELECT
  (SELECT argMax(properties.dashboard_count, timestamp) FROM events
   WHERE $group_0 = '<ORG_ID>' AND event = 'organization usage report'
     AND timestamp >= now() - INTERVAL 8 DAY) AS dashboards_defined_usage_report,
  (SELECT uniq(lc_dashboard_id) FROM query_log_archive_eu
   WHERE lc_org_id = '<ORG_ID>' AND event_time >= now() - INTERVAL 30 DAY
     AND lc_dashboard_id > 0) AS dashboards_touched_30d
LIMIT 1
```

## endpoints

Saved queries the customer calls as an API.
```sql
SELECT coalesce(toString(properties.endpoint_name), '(unnamed)') AS endpoint,
       countIf(event = 'endpoint created') AS created,
       countIf(event = 'endpoint executed') AS executions,
       arrayStringConcat(topK(3)(toString(properties.access_method)), ', ') AS access_methods,
       countIf(event = 'endpoint executed' AND properties.is_materialized = true) AS materialized_runs,
       max(timestamp) AS latest
FROM events
WHERE event IN ('endpoint created','endpoint executed') AND $group_0 = '<ORG_ID>'
  AND timestamp >= now() - INTERVAL <days> DAY
GROUP BY endpoint ORDER BY executions DESC, endpoint LIMIT 25
```
Adoption is narrow and deep: few accounts use Endpoints, and the ones that do call them on a schedule, usually over `personal_api_key` or `oauth`. One `created` against a far larger `executions` is the normal, healthy shape, so read `executions` and ignore `created`. `materialized_runs` near `executions` means the endpoint is materialized and cheap; far below it means every call recomputes, which is a cost conversation.
