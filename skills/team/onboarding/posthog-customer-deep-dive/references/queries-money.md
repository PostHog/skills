# Queries: money

Billing, credits, and LLM cost. The tables here are unified/central, not region-gated, so everything runs for EU accounts too. Conventions, ids, and the source rules live in `data-rules.md`; this file's headings are its index.

**The money model.** A discounted account prepays cash for a larger pool of credit (pay 65 cents for a dollar of credit at a 35% discount; the ratio is exact). Monthly usage is invoiced at **full list** and drawn down from that pool, and PostHog books the discounted share. So three different dollar figures are all true at once, and an account review states all three: the **list bill** (what the usage cost), the **credit applied** (what covered it), and the **cash due** (what they actually owe now). `money-picture` returns all of them in one read.

**Two kinds of credit, and they read identically until you check for a purchase.** Purchased credit is the arrangement above. A **free grant** (the startups programme, or goodwill) opens the same negative balance with **no `billing_reason = 'manual'` invoice behind it**, and PostHog books **$0.00** against it rather than a discounted share. That absence is the test: no manual row plus zero booked MRR across every completed period means granted, not bought, and no discount rate will ever reproduce it.

**On any credit-funded account, `usage_mrr` 0, `last_month_payment` 0, `paid_invoice_count` null and booked MRR 0.00 are all CORRECT.** They are not stale fields and the account is not dormant, so never write them up as a data problem or a quiet account: PostHog booked nothing and the customer paid no cash, because the credit absorbed the invoice. Read the list bill and the credit balance instead, and read the trend in the list bill, which is the only figure that shows the account growing.

**A separate percentage discount can sit on top as a Stripe coupon**, which is a different mechanism from credit and lives on `billing_customer.percent_off` and `stripe.discountPercentOff`. `money-picture` reads only the credit-discount traits, so it returns `discount_pct 0.0` on a coupon account. Check `percent_off` before ever calling an account undiscounted.

Read the booked figure from `billing_invoices_by_org.mrr` rather than recomputing it. `mrr = credits_used x (1 - discount/100)` holds on a fully credit-funded period and `mrr = cash_paid + credit x (1 - discount/100)` on a mixed one, but the arrangement changes over time, so recomputing a historical period with today's rate is wrong.

**Every MRR field answers a different question, so pick deliberately** (the framing rule for what to say is in `SKILL.md`). Establish the account type first from `money-picture`: `discount_pct` carries the discount and `credit_remaining` carries the credit, both read off Vitally traits with the caveats in its trap list below.

The dbt line-item tables (`dbt_billing_upcoming_line_items_latest`, `dbt_billing_usage_by_calendar_month`) are **dead**: they stopped writing in December 2025. The line-item table also carries one accrual snapshot per day with no snapshot-date filter, and `latest_row_in_day = 1` picks the latest row **within** each day rather than the latest day, so summing it multiplies a real bill by the number of days retained. Use the queries below: `postgres.prod.billing_upcominginvoice` is the live replacement for the line-item table, under `in-flight-period`.

**Those two tables only. Do not generalize "dead dbt pipeline" to the rest of the skill**, because the two tables it leans on hardest are both live and read as dead if you do. `dbt_stg_stripe_invoices` is a separate pipeline, fresh to the previous day, and is what `money-picture` is built on. `postgres.prod.billing_customer` is a live mirror, one row per org, with `plans_map`, `admin_emails`, `crm_segments`, and `sales_info` populated: it is what Step 1 account resolution, Step 4 ownership, `account-state`, `surveys-paid-check`, and the domain `sibling-sweep` are all built on. Distrusting either is how a run reports "no billing data" on an account that has plenty.

**Dead or broken, do not use**: `prod_postgres_invoice_with_annual_view` (**use the table `prod_postgres_invoice_with_annual` instead**: the view lags the table and carries far fewer rows, and many saved insights still read the view; the table is not authoritative on status either, because its `data` blob can freeze mid-dunning and go on reading `open` with a live `next_payment_attempt` months after the invoice went uncollectible, even while the table itself refreshes), `prod_stripe_invoice` and `stripe.prod.invoice` (months stale, failed sync), `webhookstripe_invoice`, `internalstripe_invoice` (times out, duplicate rows), `internal_org_product_usage.*_mrr` (a frozen snapshot repeated identically across every month, overstates), `PostHog_Customer_Archetype.latest_mrr` (reads 0.0 while its own per-product columns are non-zero), `account_list.total_mrr` (stale per row, and inconsistently so, which is more dangerous than uniformly broken), `Experiment_Exposures_By_Organization` (one row, PostHog Inc.), all four `cdp_usage_by_team_*`, `query_log_all_initial_only`.

## money-picture

The query an account review leads with: list bill, credit applied, cash owed, booked revenue, credit left and its runway, in one read.

```sql
WITH cust AS (
  SELECT DISTINCT customer_id FROM all_posthog_organization
  WHERE id = '<ORG_ID>' AND customer_id != ''
),
inv AS (
  SELECT 1 AS k, round(total, 2) AS list_total, round(amount_due, 2) AS cash_due,
         toDate(toDateTime(period_start)) AS period_start,
         toDate(toDateTime(period_end)) AS period_end,
         status AS invoice_status, invoice_id
  FROM dbt_stg_stripe_invoices
  WHERE customer_id IN (SELECT customer_id FROM cust)
    AND billing_reason != 'manual' AND toDateTime(period_end) <= now()
  ORDER BY period_end DESC LIMIT 1
),
booked AS (
  SELECT 1 AS k, round(mrr, 2) AS booked_mrr, round(abs(credits_used), 2) AS credit_applied
  FROM billing_invoices_by_org
  WHERE organization_id = '<ORG_ID>' AND type = 'completed' AND period_end <= now()
  ORDER BY period_end DESC LIMIT 1
),
vit AS (
  SELECT 1 AS k,
         JSONExtractFloat(assumeNotNull(toString(traits)), 'stripe.metadata.credit_discount_percent') AS discount_pct_underscore,
         JSONExtractFloat(assumeNotNull(toString(traits)), 'stripe.metadata.credit-discount-percent') AS discount_pct_hyphen,
         greatest(JSONExtractFloat(assumeNotNull(toString(traits)), 'stripe.metadata.credit_discount_percent'),
                  JSONExtractFloat(assumeNotNull(toString(traits)), 'stripe.metadata.credit-discount-percent')) AS discount_pct,
         round(abs(JSONExtractFloat(assumeNotNull(toString(traits)), 'stripe.accountBalance')), 2) AS credit_remaining,
         JSONExtractFloat(assumeNotNull(toString(traits)), 'vitally.custom.purchasedCreditAmount') AS credit_purchased,
         round(JSONExtractFloat(assumeNotNull(toString(traits)), 'vitally.custom.creditRunwayDays'), 1) AS credit_runway_days
  FROM vitally_accounts WHERE external_id = '<ORG_ID>' LIMIT 1
)
SELECT inv.period_start AS period_start, inv.period_end AS period_end,
       inv.invoice_status AS invoice_status, inv.invoice_id AS invoice_id,
       inv.list_total AS list_total, vit.discount_pct AS discount_pct,
       booked.credit_applied AS credit_applied, booked.booked_mrr AS booked_mrr,
       inv.cash_due AS cash_due, vit.credit_remaining AS credit_remaining,
       vit.credit_purchased AS credit_purchased, vit.credit_runway_days AS credit_runway_days
FROM inv LEFT JOIN booked ON booked.k = inv.k LEFT JOIN vit ON vit.k = inv.k
```

Traps:

- **Never filter on `status`; draft invoices are valid and the query deliberately has no status filter.** On a credit-funded account the recent cycles sit in draft and the draft **is** the real bill: its `starting_balance` plus its `total` equals the next invoice's `starting_balance` and the account's current credit balance, exactly. Filtering drafts out silently rolls the headline back to the last cash-paid month, understating the current bill by however many months the account has been on credit.
- **The `invoice_status` this query returns is from the mirror, so it is the one column here you may not act on.** Money columns off `dbt_stg_stripe_invoices` are sound and `list_total` is the figure the customer saw; the status and payment fields are not, and they go stale in both directions. **Before any sentence about what a customer has or has not paid, confirm against `postgres.revenue.invoice` and the `billing subscription paid` events** (`invoice-history` below owns that check). Treat `invoice_status` here as a hint about which cycle you are looking at, never as a payment fact.
- **Filter both period sources to `period_end <= now()`.** `billing_invoices_by_org` carries a forward-dated row for the next cycle holding only a small fixed add-on, so taking the newest row unfiltered headlines a few hundred dollars instead of the bill.
- **Exclude `billing_reason = 'manual'` from the usage bill.** Those rows are credit purchases (the cash prepayment), not usage, and they dwarf a monthly bill.
- **Anchor on the invoice and LEFT JOIN the rest.** An account with no Vitally row or no booked row still returns its bill; a CROSS JOIN drops the whole row and reads as "no billing data".
- `all_posthog_organization` repeats org rows, so dedupe `customer_id` before joining to Stripe. `created`, `period_start`, and `period_end` on `dbt_stg_stripe_invoices` are unix ints, so wrap them in `toDateTime()`.
- In `vitally_accounts` the org id is **`external_id`** (`organization_id` is null on every row), and the trait keys are **dotted**, not the snake_case names the Vitally API exposes: `stripe.accountBalance`, `vitally.custom.purchasedCreditAmount`. **The discount key exists in two spellings and the query reads both**, `stripe.metadata.credit_discount_percent` and `stripe.metadata.credit-discount-percent` (hyphens); a discounted account may carry either one or both. Reading only the underscore form reports a discounted account as undiscounted, silently. If both are populated and disagree, surface it rather than taking the larger. `JSONExtractFloat` returns 0.0 for a missing key, so an absent trait and a real zero look identical; confirm against `credit_applied` before calling an account undiscounted.
- `stripe.accountBalance` here is in **dollars**, matching the invoice `starting_balance` chain, not the cents the Stripe API returns. Negative means credit remaining, so the query returns `abs()`.
- `credit_applied` and `list_total` come from different tables with their own period attribution, so a fixed add-on can sit in the next period's row and leave a small gap between them. Reconcile with `booked-vs-list` rather than assuming either is wrong.
- `credit_runway_days` here and `credit_days_left` (`onboarding-state`) are two different credit clocks that disagree by design: report both per the rule in `SKILL.md`.

## quota-limits

**Run on every account carrying any billing limit.** This is the only source that says a limit was actually REACHED, which product it cut off, and on what date. Everything else in this skill infers it from a volume series falling to zero, and a volume series cannot tell a cut-off apart from a customer who stopped.

The event is `org_quota_limited_until`. **It fires on every quota state change, not only while a limit holds**, so four fields are needed and the inner `event` property is the one that decides what the row means: `resource` (the product), `event` (the state change), `current_usage`, and `quota_limited_until` (a unix int).

Observed `event` values, and only one of them means data was being dropped:

| `quota_event` | Means |
|---|---|
| `suspended` | Approaching the limit, still ingesting. A warning, not a cut-off |
| `suspension not expired` | Grace period, still ingesting. Often hundreds of fires over days |
| `suspended expired` | Grace period ended, at the flip into `already limited`. A transition marker, not the drop itself |
| **`already limited`** | **Cut off. Data is being dropped, and for recordings it is gone permanently** |
| `suspension removed` | Released, usually at the billing-period rollover |
| `limit removed` | Housekeeping after someone cleared the limit. Carries a live counter and a stale date |
| `ignored` | Seen in the wild on events and on feature flag requests. Not documented |

Treat this list as observed rather than exhaustive: read the distinct values on the account rather than assuming these are all of them.

**Two property-name traps.** The resource property is `resource`, not `quota_limited_until_by_resource`; that name does not exist and the taxonomy warning is the only thing that catches it. And the event's own `event` property collides with the table's `event` column, so alias it (`properties.event AS quota_event`) or the query silently reads the wrong one.

```sql
SELECT properties.resource AS resource, toDate(timestamp) AS day,
       properties.event AS quota_event,
       max(toFloat(properties.current_usage)) AS current_usage,
       max(toString(properties.quota_limited_until)) AS quota_limited_until,
       count() AS fires
FROM events
WHERE event = 'org_quota_limited_until' AND $group_0 = '<ORG_ID>'
  AND timestamp >= now() - INTERVAL <days> DAY
GROUP BY resource, day, quota_event ORDER BY resource, day DESC LIMIT 120
```

How to read it:

- **Route on `quota_event` first, and never infer state from the other three fields.** A `limit removed` row carries a live usage counter beside a `quota_limited_until` from a period long gone, so those fields alone report a cut-off on an account that was never limited. Both of the rules below only apply to rows whose `quota_event` says the limit was in force.
- **The earliest `already limited` day for a resource is the cut-off date.** Everything after it is lost data.
- **`current_usage` is a daily step function, so read it across days and never within one.** It refreshes at the UTC day boundary and holds that value for the rest of the day, so frozen across CONSECUTIVE DAYS confirms a cut-off, while a figure that climbs between two days inside an unbroken `already limited` window is the step function doing its job and is NOT evidence the limit lifted. On a cut-off less than a day old the field cannot confirm anything yet: route on `quota_event` alone and date it from the hourly fire pattern.
- **`quota_limited_until` goes stale and cannot be trusted alone.** It usually holds the billing period end, so a value equal to the CURRENT period end means limited right now and a PAST one means already released. When it matches neither, read `quota_event`.
- **A resource absent from the result is NOT limited**, whatever its volume did. That is how you tell a billing cap apart from a customer-side change, and it is the finding that matters most: a product whose volume collapsed with no row here changed on their end, and nobody at PostHog knows why until you ask.
- Resource names are the metered unit (`events`, `recordings`, `exceptions`), not the product name.

**Pair every hit with `billing-limit-updates` (who set it, when) and `custom_limits_map` (what it is now). `billing-limit-updates` returning zero rows is common and is not a failure**: the event has never fired for some orgs whose limits are plainly set, so `custom_limits_map` on `account-state` is the authoritative list of current limits and this query only ever adds who and when. Read the whole map rather than the products you expected: `inbox`, `replay_vision` and `posthog_code_usage` carry limits that the older product lists here do not mention.

## invoice-history

**`postgres.revenue.invoice` is the source of truth for invoice status. `dbt_stg_stripe_invoices` is not, and must never be the only source behind a sentence sent to a customer.** `revenue.invoice` is the live Fivetran mirror of Stripe and carries `status`, `amount_paid`, `amount_remaining`, `attempt_count` and the full `status_transitions_*` set (`finalized_at`, `paid_at`, `marked_uncollectible_at`, `voided_at`), which is what actually settles the question.

`dbt_stg_stripe_invoices` goes stale in BOTH directions, and both readings have already reached customers:

- **Reads `status: draft`, `paid: False`, `attempted: False`, `attempt_count: 0` when the invoice was PAID**, and does it across consecutive cycles, which is what makes it look like a settled fact.
- **Reads the same never-attempted draft, every `status_transitions_*` null, when the invoice was FINALIZED and then went `uncollectible`** after repeated failed charges. That reading has gone out as a customer email saying an invoice was cleared while the money was still outstanding.

**Cross-check with the events, which no mirror can contradict.** `billing invoice payment failed` carries `total_usd` and fires once per attempt, so several of them against an invoice the table calls never-attempted proves the table wrong. `billing subscription paid` does the same for the paid direction.

The check is one query:

```sql
SELECT toDate(timestamp) AS day, properties.total_usd AS total_usd, count() AS fires
FROM events
WHERE event = 'billing subscription paid' AND $group_0 = '<ORG_ID>'
  AND timestamp >= now() - INTERVAL 200 DAY
GROUP BY day, total_usd ORDER BY day DESC LIMIT 20
```

One row per period, `total_usd` matching that period's invoice. Sum them and they should equal Vitally's `ltv`; when they do, the drafts were paid and the mirror is lying. A truly uncollected invoice has no matching paid event. Never escalate an unpaid invoice, and never mention one to a customer, on the mirror's columns alone.

What the customer was actually billed, and when they bought credit.

```sql
SELECT toDate(toDateTime(i.created)) AS invoice_date,
       toDate(toDateTime(i.period_start)) AS period_start,
       toDate(toDateTime(i.period_end)) AS period_end,
       i.billing_reason AS reason, i.status AS status,
       round(i.total, 2) AS invoice_total,
       round(i.amount_due, 2) AS cash_due,
       round(i.starting_balance, 2) AS credit_before,
       round(i.ending_balance, 2) AS credit_after,
       i.paid AS paid, i.attempted AS attempted, i.attempt_count AS attempt_count,
       i.invoice_id AS invoice_id
FROM dbt_stg_stripe_invoices i
WHERE i.customer_id IN (
  SELECT DISTINCT customer_id FROM all_posthog_organization
  WHERE id = '<ORG_ID>' AND customer_id != ''
)
ORDER BY i.created DESC LIMIT 24
```

`dbt_stg_stripe_invoices` is the customer's actual Stripe invoice, fresh and free of duplicate rows, keyed by `customer_id` (the Stripe `cus_`); `total` is the figure the customer saw. `paid`, `attempted` and `attempt_count` are the fields to distrust: a `draft` invoice past its `period_end` with `attempt_count` 0 is a reading to verify against `postgres.revenue.invoice` and the `billing invoice payment failed` events, never a conclusion. Escalate the contradiction. `billing_reason` splits the two stories: `subscription_cycle` is the usage bill at list, `manual` is a credit purchase carrying the discounted cash amount. Dividing a `manual` total by the credit it adds to the balance recovers the discount ratio and cross-checks `discount_pct`. `ending_balance` is null until an invoice finalizes, so chain `credit_before` plus `invoice_total` to get the balance after a draft.

## invoice-line-items

**The per-product cost split, from the invoice itself. Run this before modelling anything from published tiers.** `dbt_stg_stripe_invoices.lines_data` carries one row per product per pricing tier, with the tier's unit price and the quantity billed at it, and the rows sum to the invoice total exactly, so it says what this customer pays for and how much of each with no arithmetic and no assumptions.

```sql
SELECT toDate(toDateTime(i.period_end)) AS period_end,
       round(i.total, 2) AS invoice_total,
       JSONExtractString(li, 'description') AS line_item,
       round(JSONExtractFloat(li, 'amount') / 100, 2) AS amount_usd
FROM dbt_stg_stripe_invoices i
ARRAY JOIN i.lines_data AS li
WHERE i.customer_id IN (
  SELECT DISTINCT customer_id FROM all_posthog_organization
  WHERE id = '<ORG_ID>' AND customer_id != ''
)
  AND toDateTime(i.period_end) <= now()
ORDER BY period_end DESC, amount_usd DESC
LIMIT 60
```

- **`lines_data` is typed `Array`, not a JSON string, so `ARRAY JOIN i.lines_data` is the join.** Wrapping it in `JSONExtractArrayRaw(toString(...))` returns zero rows silently, which reads as "this invoice has no line items".
- `amount` is in **cents**; divide by 100.
- The `description` carries the tier and unit price in plain text, for example `30000000 event x Identified events (add-on) (Tier 4 at $0.000036 / month)`. Sum the rows per product to get that product's cost, and read the quantities to get billed volume per product, which is the figure a customer recognizes.
- **Tier 1 rows at $0.00 are the free allowance**, so they show each product's free tier as the customer's invoice states it, with no docs lookup.
- **A product billed at exactly its `custom_limits_map` figure was capped**, and the gap between the quantity billed and the volume the usage report recorded is data the customer paid nothing for and lost. Cross-check with `quota-limits` for the dates.
- One line per **add-on** appears too, for example a flat monthly `1 x Scale add-on (at $750.00 / month)`, which no usage table will ever show you.

This is the source that makes the pricing-model rule in `SKILL.md` a cross-check rather than the method: model from published tiers only when no invoice exists yet, and reconcile against these rows whenever one does.

## in-flight-period

**The current cycle's bill, before it is invoiced. Run it whenever the question is about money the customer can see today**, because every other query in this file filters to `period_end <= now()` and so answers with the last closed invoice. A charge that started this cycle reads as a flat zero everywhere else, including on `invoice-line-items`, which is how a real spend gets reported as "never billed for that".

Two tables, keyed differently, and both are needed: one carries the metered units, the other the dollar forecast.

**Units metered to Stripe, period to date.** Keyed on `organization_id` (a String, and the only money table here that takes the org id directly).

```sql
SELECT r.date AS as_of,
       r.reported_to_period_end AS period_end,
       r.sent_to_stripe AS sent_to_stripe,
       toString(r.usage_sent_to_stripe) AS metered_units_period_to_date
FROM postgres.prod.billing_usagereport r
WHERE r.organization_id = '<ORG_ID>'
  AND r.reported_to_period_end >= today()
ORDER BY r.date DESC
LIMIT 1
```

**Forecast per product.** Keyed on `customer_id` (an Integer, the PostHog billing customer id), so it needs the lookup below rather than the org id.

```sql
SELECT u.period_start, u.period_end,
       max(u.updated_at) AS as_of,
       argMax(u.forecasted_mrr, u.updated_at) AS forecast_total,
       argMax(toString(u.mrr_per_product), u.updated_at) AS forecast_per_product,
       argMax(toString(u.forecasted_usage_units), u.updated_at) AS forecast_units
FROM postgres.prod.billing_upcominginvoice u
WHERE u.customer_id IN (
        SELECT id FROM postgres.prod.billing_customer WHERE organization_id = '<ORG_ID>')
  AND u.soft_deleted_at IS NULL
  AND u.period_start <= now() AND u.period_end > now()
GROUP BY u.period_start, u.period_end
LIMIT 1
```

- **The forward-dated row reads zero, and taking the newest row is the whole trap.** This table also holds rows for the NEXT period, and those carry `forecasted_mrr` 0.0 with `mrr_per_product` `{"scale": 0}` until that period opens. Ordering by `period_end DESC` and taking the top row therefore reports a four-figure bill as nothing. The `period_start <= now() AND period_end > now()` filter is what pins it to the live cycle, and it is not optional. Same hazard as the forward-dated row on `billing_invoices_by_org`.
- **One row per day per period**, so `argMax(..., updated_at)` for the latest snapshot and `soft_deleted_at IS NULL` throughout.
- **The forecast is a linear projection to period end, not the accrued charge**, and the two diverge hard on a one-off. It assumes the current burn rate continues, so a migration export or a backfill that has already finished is projected as if it runs all month, and the number decays toward the real one as the period closes. Price the metered units yourself against the tiers, and say which of the two figures you are quoting. Never hand a customer the forecast as "your bill" on an account whose spike has stopped.
- **`usage_sent_to_stripe` is cumulative period to date, not daily.** A key frozen across consecutive days means that product stopped; a key climbing daily is still running. That contrast is the cheapest way to tell a finished one-off from ongoing traffic.
- **Both halves come back empty on an account with no live subscription, and empty is an answer.** On a cancelled account the usage report still writes a daily row, but with `reported_to_period_end` NULL and `sent_to_stripe` False, and no upcoming row matches the period filter. That means "no billing period is open", never "no usage": the row still carries the usage blob. Read `sent_to_stripe` before reading the units.
- **The free tier is per plan, so read the Tier 1 quantities off `invoice-line-items` before modelling anything from published rates.** A doubled free allowance on a promotional plan changes the tier arithmetic.

The historical rows are a per-period forecast archive, so this table also answers "what did the billing page tell them it would be" for a period that has since closed.

## booked-vs-list

What PostHog books against what the customer is billed, per period.

```sql
SELECT toDate(period_end) AS period_end, round(mrr, 2) AS booked_mrr,
       round(credits_used, 2) AS credits_used, amount_refunded
FROM billing_invoices_by_org
WHERE organization_id = '<ORG_ID>' AND type = 'completed' AND period_end <= now()
ORDER BY period_end DESC LIMIT 18
```

`billing_invoices_by_org` is org-keyed and live, so no Stripe join is needed, and its booked `mrr` beside list `credits_used` is the cleanest cross-check. `credits_used` is negative for credit drawn in the period and 0 when the customer pays cash, which dates the switch onto credit. A period booking 0 against nonzero credit is a **free credit grant**, not a discount, per the two kinds of credit above.

## usage-mix

Which products drive the bill, and where it is trending.

```sql
SELECT toStartOfMonth(date) AS month,
       round(sum(event_count_in_period)) AS events,
       round(sum(enhanced_persons_event_count_in_period)) AS identified_events,
       round(sum(recording_count_in_period)) AS recordings,
       round(sum(mobile_recording_count_in_period)) AS mobile_recordings,
       round(sum(billable_feature_flag_requests_count_in_period)) AS flag_requests,
       round(sum(exceptions_captured_in_period)) AS exceptions,
       round(sum(survey_responses_count_in_period)) AS survey_responses,
       round(sum(ai_event_count_in_period)) AS ai_events,
       round(sum(rows_synced_in_period)) AS rows_synced,
       round(sum(cdp_billable_invocations_in_period)) AS cdp_invocations,
       round(sum(rows_exported_in_period)) AS rows_exported,
       round(sum(logs_mb_in_period)) AS logs_mb
FROM billing_usage_by_org_date
WHERE organization_id = '<ORG_ID>' AND date >= toDate(now() - INTERVAL <days> DAY)
GROUP BY month ORDER BY month DESC LIMIT 12
```

This replaces the dead dbt line items as the product-mix read. These are **billable volumes, not dollars**, so they show which product dominates and where a spike started, not the invoice split; pair the mix with the `money-picture` list total to talk about cost. The table's column-to-product map, its two confident-zero traps (Cloud only, no zero-filling), and the current-month partial period are owned by `per-product-usage` in `queries-account.md`.

## LLM cost (customer AI spend)

Two vantage points, same queries. **Scoped to `$group_0 = '<ORG_ID>'` in project 2** these return the customer's own **PostHog AI spend**, their `posthog_ai` billable line (cross-check Vitally `posthog_ai_last_month` / `posthog_ai_billing_limit`; the default cap is product state, read it live). **Filtered by `team_id` on the direct ClickHouse connection (either region; swap dot-access for `JSONExtractFloat(properties, ...)` per the caveat in `data-rules.md`)**, the same queries return their **product's own LLM spend**. Note the caveat: some orgs emit `$ai_generation` with a null `$ai_total_cost_usd` (cost not derivable for that event); treat null cost as "events present, cost not recorded", not zero spend.

Rules: always **sum `$ai_total_cost_usd`** (never the components; that drops request + web-search fees); always include **`$ai_embedding`** alongside `$ai_generation` (a taxonomy warning that `$ai_embedding` is not in project 2 is expected and harmless); aggregate cost on those two event names only. **The two you exclude fail in opposite directions, so name the right one when a total looks wrong.** `$ai_span` carries no rollup cost and **sums to zero**, which turns real spend into an apparent nothing; `$ai_trace` **does** carry `$ai_total_cost_usd` from some SDK wrappers and is the one that double-counts. `$ai_evaluation` also carries cost and sits outside the stock rollups: include it only when the user asks for evaluation spend. Cost, token, and model props live on the **events table** (only message content needs `posthog.ai_events`).

### llm-cost-daily

```sql
SELECT toStartOfDay(timestamp) AS day, count() AS calls,
       round(sum(toFloat(properties.$ai_total_cost_usd)), 4) AS cost_usd,
       sum(toInt(properties.$ai_input_tokens)) AS input_tokens, sum(toInt(properties.$ai_output_tokens)) AS output_tokens
FROM events
WHERE event IN ('$ai_generation','$ai_embedding') AND $group_0 = '<ORG_ID>' AND timestamp >= now() - INTERVAL <days> DAY
GROUP BY day ORDER BY day DESC LIMIT 60
```

### llm-cost-by-model

```sql
SELECT properties.$ai_model AS model, properties.$ai_provider AS provider, count() AS calls,
       round(sum(toFloat(properties.$ai_total_cost_usd)), 4) AS cost_usd,
       round(avg(toFloat(properties.$ai_total_cost_usd)), 6) AS avg_cost_per_call
FROM events
WHERE event IN ('$ai_generation','$ai_embedding') AND $group_0 = '<ORG_ID>' AND timestamp >= now() - INTERVAL <days> DAY
GROUP BY model, provider ORDER BY cost_usd DESC LIMIT 30
```

### llm-top-spenders

The `distinct_id != $ai_trace_id` guard drops rows where distinct_id was defaulted to the trace id.

```sql
SELECT distinct_id, count() AS calls, countDistinct(properties.$ai_trace_id) AS traces,
       round(sum(toFloat(properties.$ai_total_cost_usd)), 4) AS cost_usd
FROM events
WHERE event IN ('$ai_generation','$ai_embedding') AND $group_0 = '<ORG_ID>' AND timestamp >= now() - INTERVAL <days> DAY
  AND (properties.$ai_trace_id IS NULL OR distinct_id != properties.$ai_trace_id)
GROUP BY distinct_id ORDER BY cost_usd DESC LIMIT 25
```

### llm-cache-economics

Low cache-hit-rate on a caching-capable model is a cost lever; output tokens usually cost 3-5x input, cache reads ~10%.

**Branch on `$ai_cache_reporting_exclusive`, never on provider name, or the rate overstates and can exceed 1.0.** Providers report cache tokens two ways: **exclusive**, where `$ai_input_tokens` does NOT include cache tokens so the denominator has to add `cache_read` and `cache_creation` back, and **inclusive**, where it already does. Which one applies varies by SDK, by SDK version, and over time for the same provider, so ingestion auto-detects it and writes the resolved boolean onto every `$ai_generation`. The flag varies per event, so it belongs in the GROUP BY as well as the `if()`.

```sql
SELECT properties.$ai_model AS model,
       properties.$ai_cache_reporting_exclusive AS cache_exclusive,
       round(sum(toFloat(properties.$ai_input_cost_usd)), 4) AS input_cost,
       round(sum(toFloat(properties.$ai_output_cost_usd)), 4) AS output_cost,
       round(sum(toFloat(properties.$ai_total_cost_usd)), 4) AS total_cost,
       sum(toInt(properties.$ai_cache_read_input_tokens)) AS cache_read_tokens,
       round(if(properties.$ai_cache_reporting_exclusive = 'true',
                sum(toInt(properties.$ai_cache_read_input_tokens))
                  / nullIf(sum(toInt(properties.$ai_input_tokens))
                         + sum(toInt(properties.$ai_cache_read_input_tokens))
                         + sum(toInt(properties.$ai_cache_creation_input_tokens)), 0),
                sum(toInt(properties.$ai_cache_read_input_tokens))
                  / nullIf(sum(toInt(properties.$ai_input_tokens)), 0)), 3) AS cache_hit_rate
FROM events
WHERE event = '$ai_generation' AND $group_0 = '<ORG_ID>' AND timestamp >= now() - INTERVAL <days> DAY
GROUP BY model, cache_exclusive ORDER BY total_cost DESC LIMIT 30
```

Variant for skew: swap the aggregates in `llm-cost-by-model` for `quantile(0.5)(...)`, `quantile(0.95)(...)`, `quantile(0.99)(...)` on `$ai_total_cost_usd` to expose whether a few calls dominate. To debug a bill jump, diff `llm-cost-daily` week-over-week and check which of model mix, call volume, prompt size, or cache-hit-rate moved.
