# Agent briefs: the conventions block and the reading map

Main reads this file once, **first, before Round 1a**, because its own row in the map below decides what else main opens; it reads nothing else on behalf of the gatherers. Every brief main writes carries three things from here: the conventions block below pasted verbatim, the reading map row for that role, and the path to the context file.


This file holds no query recipes and no rules of its own. The conventions block is the one home for those lines; the map is pointers. If a rule below and a query file disagree, the query file is newer and wins, and this file gets fixed in the same pass.

## The conventions block

Paste this verbatim into every gatherer brief. It replaces the CONVENTIONS section of `data-rules.md`, which no gatherer opens. Four roles do open that file for its direct-connection section, and only that section, per the map below.

````
CONVENTIONS (binding, no file read needed):
- Org scope is `$group_0 = '<ORG_ID>'`, with no exceptions. Use the bare column, not `properties.$group_0`.
- Person accessor is `person.properties.email` everywhere.
- Put a LIMIT on every query. The server caps at 100 rows, 500 maximum. Rows returned equal to your LIMIT means TRUNCATED, not complete: re-run the tail before calling anything absent.
- **Bots are a judgment about who counts as a user, so measure rather than choose.** Count both ways in one query (`count()` beside `countIf(getBotName(properties.$raw_user_agent) = '')`) and report both whenever they differ by more than a few percent. The gap is a finding, not noise: on an API-driven or agent-driven account the "bots" are the customer's own automation, and filtering them out halves the number you came for. Never `isLikelyBot` or `$virt_is_bot` in either direction: they read an absent user agent as automation, so every server-side SDK vanishes.
- **Put `team_id` in the SELECT of every `events` query and read the value back.** Project 2's `events` scoped by `$group_0` returns `team_id = 2`, which is the customer's admins clicking around the PostHog app, never their product. Event names that exist in both worlds (`$feature_flag_called`, `$pageview`, `$identify`, `$autocapture`) are where this bites, because the result reads as a plausible answer to the question you asked.
- Project 2 reports timestamps in US/Pacific. Convert before any date reaches a finding.
- Your reads are independent unless stated. Fire them in ONE block, 4 wide on the HTTP path. Never queue.
- A source that cannot answer is UNMEASURABLE, never zero. Say which source would carry it.
- Cast with `toInt(...)` / `toFloat(...)`, never the width-suffixed forms. Test property presence with `IS NULL` / `IS NOT NULL`, never `!= ''`.
- A grouped query silently drops groups that returned nothing: seed the zeros with `arrayJoin([<ids>])` and cap with `LIMIT n BY <group>`. `LIMIT n BY` does NOT lift the server's row cap on the whole result, so keep `n` times the group count under it and count the groups you got back against the groups you asked about; a missing group is truncation until a narrower query proves it empty.
- **Namespace every temp file you write with your own role name** (`/tmp/<your-role>-queries.jsonl`, not `/tmp/queries.jsonl`). Eight to ten gatherers run at once; a shared path gets overwritten mid-run by a sibling and the failure looks like your own query being malformed.
````

## The reading map

One row per role. Open the sections named and nothing else. A section's own headings are its index.

| Role | Round | Opens | Owns |
|---|---|---|---|
| **main** | 1, 3, 5 | `data-rules.md`: "Conventions", "IDs", "Regions", "Reading data without being fooled", "Traps". **Not** the direct-connection section or the EU reachability table, which gatherers get inline. Plus `queries-account.md` for its Round 1 slugs, then the one mode file at Step 5 and `levers.md` and `voice.md` before drafting | Orchestration, the Round 1 reads, reconciliation, verification, the write |
| `site-scan` | 0 | `site-scan.md`, whole file (91 lines) | Site scan and competing-tool detection. **Run it in Round 2 instead when the admin email is on a public provider**, since that domain is not theirs. Rescan when Step 1 returns a different domain |
| `clay` | 2 | nothing. The Clay procedure is short enough to inline: read the free Vitally and Salesforce fields first and spend credits only on the gap; `search-companies` first and stop if it returns empty; people by full NAME plus company, never by email; always request the `Email` data point and confirm it matches the one you started from; `add-*-data-points` returns a `taskId`, so poll `get-task-context` and read an empty immediate response as pending, not no-match; Tech Stack is the highest-value field | Enrichment. Read the free Vitally traits first, spend credits only on the gap. Slow, so fire it in wave one |
| `docs-prewarm` | 2 | `levers.md`, whole file (69 lines) | Fetches pages this account could need into the scratchpad. Verifies nothing, decides nothing, cites nothing; Round 4 owns all three |
| `money-invoices` | 2 | `queries-money.md`: the file intro, `money-picture`, `invoice-history`, `invoice-line-items`, `booked-vs-list` | `money-picture`, `invoice-history`, `invoice-line-items`, `booked-vs-list`, plans and limits map, and the tier rebuild reconciling the last completed invoice to a residual. Plus the `llm-cost-*` block whenever the scope probe shows any `ai_event_count_in_period`; on an AI-native account that block IS the cost picture |
| `money-quotas` | 2 | `queries-money.md`: the file intro, `quota-limits`, `in-flight-period` | `quota-limits` and `in-flight-period`. Split from the invoice reads because they share no data and merging them put one agent on the critical path. Owns which product a limit actually cut off, when, and whether it is dropping now |
| `usage-trend` | 2 | `queries-money.md`: `usage-mix`. `queries-account.md`: `per-product-usage`, `org-snapshot`, and `usage-dashboard` (optional, two calls, take whatever fills and query the rest) | `per-product-usage` daily series, `usage-mix`, `org-snapshot` |
| `change-point` | 2, required in call prep and on any account whose volume, cost or product mix moved | `data-rules.md`: "The direct ClickHouse connection" only | What changed, when, and on which project. Daily per-team series for events, the product that moved, `person_mode` and `$lib`, plus the last event from any team that went quiet. **Owns the per-team daily series for the whole run and publishes it.** It reports the effect and the exact timestamp; it never asserts the cause, which lives in their code |
| `event-mix` | 2 | `data-rules.md`: "The direct ClickHouse connection" only. `queries-account.md`: `discovery` | Per-event volume and share, per project; duplicate and unused event names, including the unqueried-events join against `query_log_archive` on EU (on US it is unreadable, say so) |
| `identity-and-sdks` | 2 | `data-rules.md`: "The direct ClickHouse connection" only | `person_mode` mix, per-SDK split, pageviews per session (median, p95, max), `$set` and `identify()` frequency, double-fire check |
| `replay-and-errors` | 2 | `queries-products.md`: `team-config`, "Session replay", "Error tracking". `data-rules.md`: "The direct ClickHouse connection" | `team-config` replay levers confirmed against the live remote config, `replay-interaction`, `replay-vision`, `error-admin-activity`, both volume fields |
| `flags-and-experiments` | 2 | `queries-products.md`: "Feature flags", "Experiments" | `flag-hygiene`, `stale-flags`, decide-versus-local-evaluation split, `experiment-inventory`, `experiment-engagement`, `experiment-definitions`, `experiment-definitions-eu` on EU |
| `data-platform` | 2 | `queries-products.md`: "Data warehouse", "CDP and destinations", "Surveys", "Logs" | `warehouse-activity`, `warehouse-tables`, `warehouse-sync-jobs`, `warehouse-schema-health`, `hog-functions`, `batch-exports`, `endpoints`, `group-types`, `surveys-paid-check`, `survey-builds`, `survey-definitions` |
| `app-engagement` (on EU, `eu_postgres_posthog_organizationmembership` reads and gives a better seat roster than `seat-roster`) | 2 | `queries-account.md`: `discovery`, `top-users`, `page-paths`, `docs-viewed`, `query-usage`, `seat-roster`, `self-driving-check`, `event-breakdown`. `queries-products.md`: "Product analytics" | `discovery`, `top-users`, `page-paths` (which answers billing-page visits; never run that separately), `docs-viewed`, `query-usage`, `seat-roster`, `self-driving-check`, `posthog-ai-chat`, `dashboard-views`, `insights-viewed`, `org-membership` (US), `event-breakdown`. `nps-verbatims` only when a verbatim is wanted, since it is slow |
| `definitions-and-hygiene` | 2 | `queries-products.md`: `actions-defined`, `property-definitions`, `cohort-inventory`, `cohort-count-eu`, `dashboard-definitions`, `stale-dashboards`, `proxy-domains` | `actions-defined`, `property-definitions`, `cohort-inventory`, `cohort-count-eu`, `dashboard-definitions`, `stale-dashboards`, `proxy-domains`. On EU: `dashboard-definitions` on `eu_postgres_posthog_dashboard`, `property-definitions` on the direct connection; `actions-defined`, `cohort-inventory` and `proxy-domains` are unmeasurable there. `stale-dashboards` always runs |
| `internal-context` | 2 | `config.md`, the optional-sources table only | Slack and meeting transcripts (Gong first, per `config.md`; a transcript is complete only when its paginated total is reached) |

One role needs more than its map row, and the brief carries it rather than a file:

- Anything touching **EU** gets the region rules inline: definitions and mirrors are `eu_postgres_posthog_*`, flag keys and Actions have no EU mirror, and a customer's own raw events come from the direct connection in both regions.

The vantage warning used to sit here, scoped to "anything reading a customer's own product events". That scoping is what failed, because it made main classify each role in advance and main classified `flags-and-experiments` wrong. It now sits in the conventions block and therefore in **every** brief, not only the direct-connection roles. That is deliberate: the roles most likely to fall for it are the ones with **no** direct-connection row in the map above, because they have no other table to reach for and will improvise with `events`.

## The frozen context block

Main resolves these once and **writes them to `<run scratchpad>/context.md`**; every brief points at that path instead of carrying a copy. **No gatherer re-resolves any of them.** A gatherer that needs one and does not have it reports the gap rather than querying for it.

Org id, Vitally account id, region, team ids with their names, `plans_map`, `custom_limits_map`, domain, admin emails, and `team-config` for every team.

The first five come from Round 1a and unblock the launch; the rest are appended as Round 1b resolves them, so a brief written early points at a file that fills in behind it. Write the file, then launch.

**The file carries appends safely and corrections not at all, so a corrected value needs a message, not an edit.** An agent reads the context once, at the top of its run. A value appended behind it is fine, because nobody had it yet and whoever needs it reads later. A value you CHANGE is different: every agent already past that line is holding the old one, the file now disagrees with their working state, and nothing in the run will tell you which findings rest on it. So when a Round 1b read corrects something Round 1a wrote, fix the file AND re-brief the agents whose subject it touches, naming the old value and the new one.

**Re-brief a running gatherer whenever a later round changes its question.** Corrections are one case; the broader one is timing. Round 0 and Round 1b land after Round 2 has started, and when what they return would have changed how a brief was written, sending that gatherer a short follow-up is cheaper than reconciling a wrong finding afterwards, and far cheaper than shipping it. A site scan that arrives late and reveals which product a config actually belongs to is the common case: without the follow-up the gatherer answers the question it was given, correctly, about the wrong thing.

One file beats nine copies for two reasons. Main hand-writing the same block into every brief is real generation on the critical path, and every retyping is a chance to transpose a team id into one brief and not the others, which produces a wrong number in one section and no error anywhere.


## Shared results between gatherers

The per-team daily series (events, and the product that moved, by day by team) is read by several roles and is expensive on a multi-project account. **`change-point` owns it and writes it to `<run scratchpad>/daily-by-team.md`; every other role reads that file rather than re-querying it.** A role needing a cut the file does not carry queries for that cut alone and says so.

This is a deduplication rule, never a silencing one: where two roles measure the same quantity by different routes, both still report, and a disagreement between them goes to Round 3 intact. Overlapping reads are how a source conflict surfaces at all, so the thing to remove is the repeated identical query, not the second opinion.

## The five return rules

Every brief closes with these.

1. Return numbers, never prose. Every figure carries the query or table that produced it.
2. Report which traps fired. A brief reporting none is one to be suspicious of.
3. Name every skip with its reason. Not valid: "to keep it small", "to save tokens", "the depth budget", "the probe said zero", "another read covered it". Running a read and confirming a zero is not a skip.
4. Cap the digest at roughly 250 words. Full detail goes to the scratchpad file. Do not restate the context block back to main.
5. Write the digest file before returning.
