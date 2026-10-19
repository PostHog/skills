# Queries: money

Billing, credits, and LLM cost. The tables here are unified/central, not region-gated, so everything runs for EU accounts too. Conventions, ids, and the source rules live in `data-rules.md`; this file's headings are its index.

**The money model.** A discounted account prepays cash for a larger pool of credit (pay 65 cents for a dollar of credit at a 35% discount; the ratio is exact). Monthly usage is invoiced at **full list** and drawn down from that pool, and PostHog books the discounted share. So three different dollar figures are all true at once, and an account review states all three: the **list bill** (what the usage cost), the **credit applied** (what covered it), and the **cash billed** (what the invoice asked them to pay in cash), with the **cash outstanding** beside it (what they still owe now, 0 once paid). `money-picture` returns all of them in one read.

**Two kinds of credit, and they read identically until you check for a purchase.** Purchased credit is the arrangement above. A **free grant** (the startups programme, or goodwill) opens the same negative balance with **no `billing_reason = 'manual'` invoice behind it**, and PostHog books **$0.00** against it rather than a discounted share. That absence is the test: no manual row plus zero booked MRR across every completed period means granted, not bought, and no discount rate will ever reproduce it.

**On any credit-funded account, a booked MRR of 0.00, a `Last invoice amount` of 0, a low `paid_invoice_count` and a zero `cash_paid` are all CORRECT.** They are not stale fields and the account is not dormant, so never write them up as a data problem or a quiet account: PostHog booked nothing and the customer paid no cash, because the credit absorbed the invoice. Read the list bill and the credit balance instead, and read the trend in the list bill, which is the only figure that shows the account growing.

**A separate percentage discount can sit on top as a Stripe coupon**, which is a different mechanism from credit and lives on `billing_customer.percent_off` and the Stripe customer's `discount`. `money-picture` reads only the credit discount in the Stripe customer's metadata, so it returns `discount_pct 0.0` on a coupon account. Check `percent_off` before ever calling an account undiscounted.

Read the booked figure from `billing_invoices_by_org.mrr` rather than recomputing it. `mrr = abs(credits_used) x (1 - discount/100)` holds on a fully credit-funded period and `mrr = cash_paid + credit x (1 - discount/100)` on a mixed one, but the arrangement changes over time, so recomputing a historical period with today's rate is wrong.

**Every MRR field answers a different question, so pick deliberately** (the framing rule for what to say is in `SKILL.md`). Establish the account type first from `money-picture`: `discount_pct` carries the discount and `credit_remaining` carries the credit, both read off the Stripe customer with the caveats in its trap list below.

The dbt line-item tables (`dbt_billing_upcoming_line_items_latest`, `dbt_billing_usage_by_calendar_month`) are **dead**: they stopped writing in December 2025. The line-item table also carries one accrual snapshot per day with no snapshot-date filter, and `latest_row_in_day = 1` picks the latest row **within** each day rather than the latest day, so summing it multiplies a real bill by the number of days retained. Use the queries below: the `upcoming` row of `iwa_summary_customer_month`, under `in-flight-period`, replaces the line-item table for the current cycle.

**Those two tables only. Do not generalize "dead dbt pipeline" to the rest of the skill**, because the two tables it leans on hardest are both live and read as dead if you do. `postgres.revenue.invoice` is the live mirror of Stripe's invoices, keyed on the Stripe `customer_id` with amounts in cents, and is what `money-picture` is built on; `postgres.revenue.invoice_line_item` carries its lines. `postgres.prod.billing_customer` is a live mirror, one row per org, with `plans_map`, `admin_emails` and `custom_limits_map` populated: it is what Step 1 account resolution, `account-state`, `surveys-paid-check`, and the domain `sibling-sweep` are all built on. Its `crm_segments` and `sales_info` are a frozen copy of the retired CRM's segments, so never read them. Distrusting either is how a run reports "no billing data" on an account that has plenty.

**Dead or broken, do not use**: `prod_postgres_invoice_with_annual_view` (**use the table `prod_postgres_invoice_with_annual` instead**: the view lags the table and carries far fewer rows, and many saved insights still read the view; the table is not authoritative on status either, because its `data` blob can freeze mid-dunning and go on reading `open` with a live `next_payment_attempt` months after the invoice went uncollectible, even while the table itself refreshes), `prod_stripe_invoice` and `stripe.prod.invoice` (months stale, failed sync), `dbt_stg_stripe_invoices` (it only holds invoices created since 11 October 2026, so every history read off it comes back nearly empty; `prod_stripe_customer` is a different table and live), `webhookstripe_invoice`, `internalstripe_invoice` (times out, duplicate rows), `internal_org_product_usage.*_mrr` (a frozen snapshot repeated identically across every month, overstates), `PostHog_Customer_Archetype.latest_mrr` (reads 0.0 while its own per-product columns are non-zero), `account_list.total_mrr` (stale per row, and inconsistently so, which is more dangerous than uniformly broken), `Experiment_Exposures_By_Organization` (one row, PostHog Inc.), all four `cdp_usage_by_team_*`, `query_log_all_initial_only`, `webhookstripe_coupon` (sync paused for months), and every `zendesk_*` source mirror (paused; PostHog Support holds tickets now, per `support-tickets`).

## credit-contract-phase

Every account on a contract or holding credit. One row per org: where the contract sits, whether the renewal is signed, and when the credit runs out, in one read. Three of its fields exist nowhere else in this skill: `contract_phase`, `sf_renewal_signed` and `sf_opp_url`.

```sql
SELECT contract_phase, contract_starts_at, contract_ends_at, contract_length_months, contract_month,
       months_to_renewal, sf_renewal_signed, sf_opp_url, sf_order_form_url, sf_contract_credit,
       stripe_account_balance, credit_runway_days, credit_expires_at, projected_credit_depletion_date,
       credit_expiry_to_depletion_months, usage_mrr, forecasted_usage_mrr, forecasted_usage_mrr_change_pct
FROM accounts_credit_props
WHERE organization_id = '<ORG_ID>'
LIMIT 1
```

`contract_phase` is set only on contract accounts, so a blank phase on a monthly self-serve account is correct and never a gap. The view holds only Customer Analytics accounts that are neither ignored nor churned, so no row means the org is outside it, not that it has no credit: `money-picture` still has the balance and the discount, and the runway is then unmeasured unless you compute it from the balance over daily spend. `forecasted_usage_mrr` is the gross figure; the forecast for the header is `forecasted_mrr` on `onboarding-state`. Credit running out before `contract_ends_at` is the header line Step 4 asks for; read `projected_credit_depletion_date` against it and show both dates.

## money-picture

The query an account review leads with: list bill, credit applied, cash billed and still outstanding, booked revenue, credit left and its runway, in one read. Dates are UTC days, the day Stripe and the invoice use.

```sql
WITH cust AS (
  SELECT DISTINCT customer_id FROM all_posthog_organization
  WHERE id = '<ORG_ID>' AND customer_id != ''
),
inv AS (
  SELECT 1 AS k, round(total / 100, 2) AS list_total, round(amount_due / 100, 2) AS cash_billed,
         round(amount_paid / 100, 2) AS cash_paid, round(amount_remaining / 100, 2) AS cash_outstanding,
         toDate(toTimeZone(period_start, 'UTC')) AS period_start, toDate(toTimeZone(period_end, 'UTC')) AS period_end,
         status AS invoice_status, id AS invoice_id
  FROM postgres.revenue.invoice
  WHERE customer_id IN (SELECT customer_id FROM cust)
    AND billing_reason != 'manual' AND period_end <= now()
  ORDER BY period_end DESC LIMIT 1
),
booked AS (
  SELECT 1 AS k, round(mrr, 2) AS booked_mrr, round(abs(credits_used), 2) AS credit_applied
  FROM billing_invoices_by_org
  WHERE organization_id = '<ORG_ID>' AND type = 'completed' AND period_end <= now()
  ORDER BY period_end DESC LIMIT 1
),
stripe AS (
  SELECT 1 AS k,
         greatest(toFloatOrZero(JSONExtractString(toString(metadata), 'credit_discount_percent')),
                  toFloatOrZero(JSONExtractString(toString(metadata), 'credit-discount-percent'))) AS discount_pct,
         round(abs(least(balance, 0)) / 100, 2) AS credit_remaining
  FROM prod_stripe_customer WHERE id IN (SELECT customer_id FROM cust)
  ORDER BY balance ASC LIMIT 1
),
purchases AS (
  SELECT 1 AS k, round(sum(total) / 100, 2) AS credit_purchase_cash, max(toDate(toTimeZone(created, 'UTC'))) AS last_credit_purchase
  FROM postgres.revenue.invoice
  WHERE customer_id IN (SELECT customer_id FROM cust) AND billing_reason = 'manual' AND status = 'paid'
),
runway AS (
  SELECT 1 AS k, credit_runway_days, projected_credit_depletion_date
  FROM accounts_credit_props WHERE organization_id = '<ORG_ID>' LIMIT 1
)
SELECT inv.period_start AS period_start, inv.period_end AS period_end,
       inv.invoice_status AS invoice_status, inv.invoice_id AS invoice_id,
       inv.list_total AS list_total, stripe.discount_pct AS discount_pct,
       booked.credit_applied AS credit_applied, booked.booked_mrr AS booked_mrr,
       inv.cash_billed AS cash_billed, inv.cash_paid AS cash_paid, inv.cash_outstanding AS cash_outstanding,
       stripe.credit_remaining AS credit_remaining,
       purchases.credit_purchase_cash AS credit_purchase_cash, purchases.last_credit_purchase AS last_credit_purchase,
       runway.credit_runway_days AS credit_runway_days, runway.projected_credit_depletion_date AS credit_runs_out
FROM inv LEFT JOIN booked ON booked.k = inv.k LEFT JOIN stripe ON stripe.k = inv.k
LEFT JOIN purchases ON purchases.k = inv.k LEFT JOIN runway ON runway.k = inv.k
LIMIT 1
```

**`cash_billed` stays at the billed amount after the invoice is paid**, so it never means "owed now": what they owe now is `cash_outstanding`, which reads 0 on a paid invoice.

Traps:

- **Never filter on `status`; draft invoices are valid and the query deliberately has no status filter.** On a credit-funded account the recent cycles sit in draft and the draft **is** the real bill: its `starting_balance` plus its `total` equals the next invoice's `starting_balance` and the account's current credit balance, exactly. Filtering drafts out silently rolls the headline back to the last cash-paid month, understating the current bill by however many months the account has been on credit.
- **`invoice_status` comes from `postgres.revenue.invoice`, the live Stripe mirror, and `list_total` is the figure the customer saw.** Before any sentence about what a customer has or has not paid, still cross-check it against the `billing subscription paid` and `billing invoice payment failed` events (`invoice-history` below owns that check), because a sentence about money is the one a customer checks.
- **On a first billing period the latest closed invoice is the $0 one from signup**, so `list_total` 0 there means the first bill has not been issued yet, never a free account: say so and quote `in-flight-period` for what is coming.
- **Filter both period sources to `period_end <= now()`.** `billing_invoices_by_org` carries a forward-dated row for the next cycle holding only a small fixed add-on, so taking the newest row unfiltered headlines a few hundred dollars instead of the bill.
- **Exclude `billing_reason = 'manual'` from the usage bill.** Those rows are credit purchases (the cash prepayment), not usage, and they dwarf a monthly bill.
- **Anchor on the invoice and LEFT JOIN the rest.** An account with no Stripe customer, no booked row or no credit-view row still returns its bill; a CROSS JOIN drops the whole row and reads as "no billing data".
- `all_posthog_organization` repeats org rows, so dedupe `customer_id` before joining to Stripe. **Every amount on `postgres.revenue.invoice` and `prod_stripe_customer.balance` is in cents**, so the query divides by 100; a figure 100 times too large is this, and nothing else.
- **The credit discount sits in the Stripe customer's `metadata` under two spellings and the query reads both**, `credit_discount_percent` and `credit-discount-percent`. Reading one only reports a discounted account as undiscounted, silently. A missing key reads 0, so an absent value and a real zero look identical; confirm against `credit_applied` before calling an account undiscounted.
- `balance` is negative while credit remains, so the query returns its absolute value. `credit_purchase_cash` sums the paid `manual` invoices, which is the cash they paid for credit; the credit it bought is that divided by (1 minus the discount).
- `credit_applied` and `list_total` come from different tables with their own period attribution, so a fixed add-on can sit in the next period's row and leave a small gap between them. Reconcile with `booked-vs-list` rather than assuming either is wrong.
- `credit_runway_days` here (from `accounts_credit_props`) and `credit_days_left` (`onboarding-state`) are two different credit clocks that disagree by design: report both per the rule in `data-rules.md`.

## quota-limits

**Run on every account carrying any billing limit.** This is the only source that says a limit was actually REACHED, which product it cut off, and on what date. Everything else in this skill infers it from a volume series falling to zero, and a volume series cannot tell a cut-off apart from a customer who stopped.

The event is `org_quota_limited_until`. **It fires on every quota state change, not only while a limit holds**, so four fields are needed and the inner `event` property is the one that decides what the row means: `resource` (the product), `event` (the state change), `current_usage`, and `quota_limited_until` (a unix int).

Observed `event` values, and only one of them means data was being dropped:

| `quota_event` | Means |
|---|---|
| `suspended` | Approaching the limit, still ingesting. A warning, not a cut-off |
| `suspension not expired` | Grace period, still ingesting. Often hundreds of fires over days |
| `suspended expired` | Grace period ended, at the flip into `already limited`. A transition marker, not the drop itself |
| **`already limited`** | **Cut off while `quota_limited_until` is still ahead: data is being dropped, and for recordings it is gone permanently.** Batch exports are the exception: `rows_exported` can read `already limited` every period while every run completes, so read the run history (`batch-exports`) before calling an export cut off. With a `quota_limited_until` already past, it is a release that has not been recorded yet, so read the next state change |
| `suspension removed` | Released, usually at the billing-period rollover |
| `limit removed` | Housekeeping after someone cleared the limit. Carries a live counter and a stale date |
| `ignored` | Seen in the wild on events and on feature flag requests. Not documented |

Treat this list as observed rather than exhaustive: read the distinct values on the account rather than assuming these are all of them.

**Two property-name traps.** The resource property is `resource`, not `quota_limited_until_by_resource`; that name does not exist and the taxonomy warning is the only thing that catches it. And the event's own `event` property collides with the table's `event` column, so alias it (`properties.event AS quota_event`) or the query silently reads the wrong one.

```sql
SELECT properties.resource AS resource, toDate(toTimeZone(timestamp, 'UTC')) AS day,
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
- **The earliest `already limited` day in the run of consecutive days ending now is the cut-off date**, not the earliest such day in the window: an isolated fire weeks earlier is a stale counter, not a cut-off. Everything after it is lost data.
- **`current_usage` is a daily step function, so read it across days and never within one.** It refreshes at the UTC day boundary and holds that value for the rest of the day, so frozen across CONSECUTIVE DAYS confirms a cut-off, while a figure that climbs between two days inside an unbroken `already limited` window is the step function doing its job and is NOT evidence the limit lifted. On a cut-off less than a day old the field cannot confirm anything yet: route on `quota_event` alone and date it from the hourly fire pattern.
- **`quota_limited_until` goes stale and cannot be trusted alone.** It usually holds the billing period end, so a value equal to the CURRENT period end means limited right now and a PAST one means already released. When it matches neither, read `quota_event`.
- **A resource absent from the result is NOT limited**, whatever its volume did. That is how you tell a billing cap apart from a customer-side change, and it is the finding that matters most: a product whose volume collapsed with no row here changed on their end, and nobody at PostHog knows why until you ask.
- Resource names are the metered unit (`events`, `recordings`, `exceptions`, and the credit products such as PostHog Desktop's), not the product name, so read the distinct `resource` values on the account rather than expecting a list.

**The product analytics limit caps more than the product analytics line**: on real invoices it has held the product analytics, identified events and group analytics lines together to the limit (two months landing at $1,000.01 and $1,750.00 against limits of $1,000 and $1,750). So compare it with the sum of those three lines in `invoice-line-items` or `in-flight-period`, and confirm on the account's own invoice before saying how close they are.

**Credit products are capped in credits, not dollars**: `custom_limits_map` holds the dollar limit, while the cap billing enforces for PostHog Desktop, PostHog AI, signals and Replay Vision sits in credits on `postgres.posthog_organization.usage` (`eu_postgres_posthog_organization` on EU) (`posthog_code_credits`, `ai_credits`, `signals_credits`, `replay_vision_credits`, each with its used count). Read both before saying how close a credit product is to its limit. The `billing subscription invoice projected` event carries billing's own per-product projection, a cross-check on the `in-flight-period` forecast that can lag it.

**A limit set to $0 can vanish from `custom_limits_map`**: the update has fired `limit removed` seconds later and left no key, so where `billing-limit-updates` shows a recent $0, quote that as the latest limit and say the map disagrees.

**Pair every hit with `billing-limit-updates` (who set it, when) and `custom_limits_map` (what it is now). `billing-limit-updates` returning zero rows is common and is not a failure**: the event has never fired for some orgs whose limits are plainly set, so `custom_limits_map` on `account-state` is the list of current dollar limits and this query only ever adds who and when. It is not every quota: the org usage report can carry a row quota the map does not list (a batch-export row limit, for one), and the invoice can cap the same quantity at another number, so say which source each limit came from. Read the whole map rather than the products you expected: `inbox`, `replay_vision` and `posthog_code_usage` carry limits that the older product lists here do not mention.

## invoice-history

**`postgres.revenue.invoice` is the source of truth for invoice status.** It is the live mirror of Stripe and carries `status`, `amount_paid`, `amount_remaining`, `attempt_count`, `next_payment_attempt` and `billing_reason`, which is what actually settles whether a customer paid. The older mirrors went stale in both directions, reading a paid invoice as a never-attempted draft and an uncollectible one as cleared, and both readings reached customers, so a payment claim still gets the events cross-check below.

**Cross-check with the events, which no mirror can contradict.** `billing invoice payment failed` carries `total_usd` and fires once per attempt, so several of them against an invoice the table calls never-attempted proves the table wrong. `billing subscription paid` does the same for the paid direction.

The check is one query:

```sql
SELECT toDate(toTimeZone(timestamp, 'UTC')) AS day, properties.total_usd AS total_usd, count() AS fires
FROM events
WHERE event = 'billing subscription paid' AND $group_0 = '<ORG_ID>'
  AND timestamp >= now() - INTERVAL 200 DAY
GROUP BY day, total_usd ORDER BY day DESC LIMIT 20
```

The event fires several times per invoice, so read one row per period only after grouping by `total_usd`, as the query does, with `total_usd` matching that period's invoice. Sum them and they should equal the sum of `cash_paid` in the history below; when they do not, say which periods disagree. A truly uncollected invoice has no matching paid event. Never escalate an unpaid invoice, and never mention one to a customer, on the mirror's columns alone.

What the customer was actually billed, and when they bought credit.

```sql
SELECT toDate(toTimeZone(i.created, 'UTC')) AS invoice_date, toDate(toTimeZone(i.period_start, 'UTC')) AS period_start,
       toDate(toTimeZone(i.period_end, 'UTC')) AS period_end,
       i.billing_reason AS reason, i.status AS status,
       round(i.total / 100, 2) AS invoice_total, round(i.amount_due / 100, 2) AS cash_billed,
       round(i.amount_paid / 100, 2) AS cash_paid, round(i.amount_remaining / 100, 2) AS cash_outstanding,
       round(i.starting_balance / 100, 2) AS credit_before, round(i.ending_balance / 100, 2) AS credit_after,
       i.attempt_count AS attempt_count, i.next_payment_attempt AS next_payment_attempt, i.id AS invoice_id
FROM postgres.revenue.invoice AS i
WHERE i.customer_id IN (
  SELECT DISTINCT customer_id FROM all_posthog_organization
  WHERE id = '<ORG_ID>' AND customer_id != ''
)
ORDER BY i.created DESC LIMIT 24
```

`invoice_total` is the figure the customer saw. A `draft` invoice past its `period_end` on a credit account is normal (the draft is the real bill), and an `open` one with `attempt_count` above zero and a `next_payment_attempt` is a payment in dunning: confirm it against the `billing invoice payment failed` events before saying a word about it. `billing_reason` splits the two stories: `subscription_cycle` is the usage bill at list, `manual` is a credit purchase carrying the discounted cash amount. Dividing a `manual` total by the credit it adds to the balance recovers the discount ratio and cross-checks `discount_pct`. `ending_balance` is null until an invoice finalizes, so chain `credit_before` plus `invoice_total` to get the balance after a draft.

## invoice-line-items

**The per-product cost split, from the invoice itself. Run this before modelling anything from published tiers.** `postgres.revenue.invoice_line_item` carries one row per product per pricing tier, with the tier's unit price in `description` and the quantity billed at it, and the rows sum to the invoice subtotal (`total` is after discounts and tax), so it says what this customer pays for and how much of each with no arithmetic and no assumptions. The window is the last 120 days of invoices, which keeps it fast.

```sql
SELECT toDate(toTimeZone(i.period_end, 'UTC')) AS period_end, round(i.total / 100, 2) AS invoice_total,
       li.description AS line_item, li.quantity AS quantity,
       round(li.amount / 100, 2) AS amount_usd
FROM postgres.revenue.invoice_line_item AS li
JOIN postgres.revenue.invoice AS i ON i.id = li.invoice_id
WHERE i.customer_id IN (
  SELECT DISTINCT customer_id FROM all_posthog_organization
  WHERE id = '<ORG_ID>' AND customer_id != ''
)
  AND i.billing_reason != 'manual' AND i.period_end <= now() AND i.period_end >= now() - INTERVAL 120 DAY
ORDER BY period_end DESC, amount_usd DESC
LIMIT 200
```

- `amount` is in **cents**; the query divides by 100.
- `billing_invoice_line_items_by_org` is a lighter per-product view of the same thing (`cleaned_description` is the product, `amount` in cents) when the tier detail is not needed.
- The `description` carries the tier and unit price in plain text, for example `30000000 event x Identified events (add-on) (Tier 4 at $0.000036 / month)`. Sum the rows per product to get that product's cost, and read the quantities to get billed volume per product, which is the figure a customer recognizes.
- **Tier 1 rows at $0.00 are the free allowance**, so they show each product's free tier as the customer's invoice states it, with no docs lookup.
- **A product billed at exactly its `custom_limits_map` figure was capped**, and the gap between the quantity billed and the volume the usage report recorded is data the customer paid nothing for and lost. Cross-check with `quota-limits` for the dates.
- One line per **add-on** appears too, for example a flat monthly `1 x Scale add-on (at $750.00 / month)`, which no usage table will ever show you.

This is the source that makes the pricing-model rule in `SKILL.md` a cross-check rather than the method: model from published tiers only when no invoice exists yet, and reconcile against these rows whenever one does.

## in-flight-period

**The current cycle's bill, before it is invoiced. Run it whenever the question is about money the customer can see today**, because every other query in this file filters to `period_end <= now()` and so answers with the last closed invoice. A charge that started this cycle reads as a flat zero everywhere else, including on `invoice-line-items`, which is how a real spend gets reported as "never billed for that".

Two reads, both fast. The live billing tables behind the billing page (`postgres.prod.billing_usagereport`, `postgres.prod.billing_upcominginvoice` and their `prod_postgres_*` copies) hit the execution ceiling on every account, so never read them directly.

**Units used this cycle, per product**, from the daily usage table summed since the cycle began:

```sql
SELECT min(d.date) AS first_day, max(d.date) AS last_day, count() AS days_reported,
       sum(d.event_count_in_period) AS events, sum(d.enhanced_persons_event_count_in_period) AS identified_events,
       sum(d.recording_count_in_period) AS recordings, sum(d.mobile_recording_count_in_period) AS mobile_recordings,
       sum(d.billable_feature_flag_requests_count_in_period) AS billable_flag_requests,
       sum(d.exceptions_captured_in_period) AS exceptions, sum(d.survey_responses_count_in_period) AS survey_responses,
       sum(d.rows_synced_in_period) AS dwh_rows_synced, sum(d.ai_event_count_in_period) AS ai_events,
       sum(d.cdp_billable_invocations_in_period) AS cdp_invocations, sum(d.logs_mb_in_period) AS logs_mb,
       sum(d.replay_vision_credits_used_in_period) AS replay_vision_credits, sum(d.ai_credits_used_in_period) AS ai_credits
FROM billing_usage_by_org_date AS d
WHERE d.organization_id = '<ORG_ID>'
  AND d.date >= coalesce(
        (SELECT toDate(toTimeZone(period_start_at, 'UTC')) FROM onboarding_accounts_v8 WHERE org_id = '<ORG_ID>' LIMIT 1),
        (SELECT toDate(toTimeZone(max(billing_period_starts), 'UTC')) FROM postgres.prod.billing_customer WHERE organization_id = '<ORG_ID>'))
LIMIT 1
```

**The forecast for this cycle, per product**, from the open period's row:

```sql
SELECT period_end, selected_type, total_mrr AS forecast_total, product_analytics_mrr, enhanced_persons_mrr, group_analytics_mrr,
       session_replay_mrr, mobile_replay_mrr, feature_flags_mrr, surveys_mrr, error_tracking_mrr, data_warehouse_mrr,
       data_pipelines_mrr, batch_exports_mrr, realtime_destinations_mrr, llm_analytics_mrr, posthog_ai_mrr, logs_mrr,
       workflows_emails_mrr, inbox_mrr, posthog_code_mrr, replay_vision_mrr, boost_mrr, scale_mrr, teams_mrr,
       enterprise_mrr, platform_mrr, other_mrr, discount, credit_applied
FROM iwa_summary_customer_month
WHERE organization_id = '<ORG_ID>' AND selected_type != 'upcoming_duplicated' AND period_end > now()
ORDER BY period_end ASC
LIMIT 1
```

- **Read the one open period, never a sum.** The open cycle is normally labelled `upcoming`, but an early cycle can be labelled `completed` while it is still open, which is why the query takes the earliest row ending after now rather than filtering on the label. `upcoming_duplicated` rows are the same forecast copied into the following months, so summing across rows multiplies the bill.
- **The forecast is a linear projection to period end, not the accrued charge**, and the two diverge hard on a one-off. It assumes the current burn rate continues, so a migration export or a backfill that has already finished is projected as if it runs all month, and the number decays toward the real one as the period closes. Price the units yourself against the tiers, and say which of the two figures you are quoting. Never hand a customer the forecast as "your bill" on an account whose spike has stopped.
- **Its total can differ from `Forecasted MRR`.** This is the upcoming invoice's per-product view; the header's forecast is `forecasted_mrr` on `onboarding-state`, which adds platform add-ons after credits. Quote this one only for the per-product split, and say so when the two differ.
- **The daily table runs a day behind and fills the current day over a couple of days**, so `days_reported` of 0 in the first day or two of a cycle is correct, not missing data. `last_day` says how far it reaches. A product that stops appearing in the daily series stopped; one still climbing is still running.
- **No forecast row means no open billing period**, never no usage: a cancelled account still writes daily usage.
- **What the billing page forecast for a period that has since closed is not recoverable**: the open period's row becomes the closed row, so say so rather than quoting the final invoice as the forecast they saw.
- **The free tier is per plan, so read the Tier 1 quantities off `invoice-line-items` before modelling anything from published rates.** A doubled free allowance on a promotional plan changes the tier arithmetic.

## booked-vs-list

What PostHog books against what the customer is billed, per period.

```sql
SELECT toDate(toTimeZone(period_end, 'UTC')) AS period_end, round(mrr, 2) AS booked_mrr,
       round(credits_used, 2) AS credits_used, amount_refunded
FROM billing_invoices_by_org
WHERE organization_id = '<ORG_ID>' AND type = 'completed' AND period_end <= now()
ORDER BY period_end DESC LIMIT 18
```

`billing_invoices_by_org` is org-keyed and live, so no Stripe join is needed. Its booked `mrr` beside `credits_used` (the credit drawn) is the cleanest cross-check; the list bill for the same period is `invoice_total` in `invoice-history`. `credits_used` is negative for credit drawn in the period and 0 when the customer pays cash, which dates the switch onto credit. A period booking 0 against nonzero credit is a **free credit grant**, not a discount, per the two kinds of credit above.

## usage-mix

Which products drive the bill, and where it is trending. Fixed 365 day window, ignoring `<days>`: a trend needs whole months, and the newest month is partial, so compare it per day or leave it out.

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
       round(sum(logs_mb_in_period)) AS logs_mb,
       round(sum(replay_vision_credits_used_in_period)) AS replay_vision_credits,
       round(sum(ai_credits_used_in_period)) AS ai_credits
FROM billing_usage_by_org_date
WHERE organization_id = '<ORG_ID>' AND date >= toDate(now() - INTERVAL 365 DAY)
GROUP BY month ORDER BY month DESC LIMIT 13
```

This replaces the dead dbt line items as the product-mix read. These are **billable volumes, not dollars**, so they show which product dominates and where a spike started, not the invoice split; pair the mix with the `money-picture` list total to talk about cost. The table's column-to-product map, its two confident-zero traps (Cloud only, no zero-filling), and the current-month partial period are owned by `per-product-usage` in `queries-account.md`.

## LLM cost (customer AI spend)

Two vantage points, same queries. **Scoped to `$group_0 = '<ORG_ID>'` in project 2** these return the **model cost of the customer's PostHog AI use**, which is never the bill: the bill is `ai_credits_used_in_period` and the PostHog AI line in `invoice-line-items`, capped by the `posthog_ai` key in `custom_limits_map` (the default cap is product state, read it live). **Filtered by `team_id` on the direct ClickHouse connection (either region; swap dot-access for `JSONExtractFloat(properties, ...)` per the caveat in `data-rules.md`)**, the same queries return their **product's own LLM spend**. Note the caveat: some orgs emit `$ai_generation` with a null `$ai_total_cost_usd` (cost not derivable for that event); treat null cost as "events present, cost not recorded", not zero spend.

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

**Branch on `$ai_cache_reporting_exclusive`, never on provider name, or the rate overstates and can exceed 1.0.** Providers report cache tokens two ways: **exclusive**, where `$ai_input_tokens` does NOT include cache tokens so the denominator has to add `cache_read` and `cache_creation` back, and **inclusive**, where it already does. Which one applies varies by SDK, by SDK version, and over time for the same provider, so ingestion auto-detects it and writes the resolved boolean onto every `$ai_generation`. The flag varies per event, so it belongs in the GROUP BY, and the `if()` reads it through the grouped alias: reading the property again inside the aggregate errors with "not under aggregate function".

```sql
SELECT properties.$ai_model AS model,
       toString(properties.$ai_cache_reporting_exclusive) AS cache_exclusive,
       round(sum(toFloat(properties.$ai_input_cost_usd)), 4) AS input_cost,
       round(sum(toFloat(properties.$ai_output_cost_usd)), 4) AS output_cost,
       round(sum(toFloat(properties.$ai_total_cost_usd)), 4) AS total_cost,
       sum(toInt(properties.$ai_cache_read_input_tokens)) AS cache_read_tokens,
       round(if(cache_exclusive = 'true',
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
