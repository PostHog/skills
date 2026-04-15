---
name: account-handover
description: Draft structured handover notes for transitioning a PostHog account from one TAM or CSM to another. Use this skill when a TAM needs to hand over an account, prepare a transition briefing, write handover notes, create an account summary for a new owner, or any request involving account transitions between TAMs or CSMs. Triggers on "hand over this account", "transition account to", "draft handover notes", "account briefing for new TAM", "prepare account transition", or when a TAM names an account and says they're leaving or reassigning it.
---

# Account Handover Notes

Draft a structured handover document when transitioning a PostHog account from one TAM or CSM to another. The document gives the incoming owner everything they need to pick up the account without the customer noticing a gap.

**Input**: Account name (and optionally: reason for transition, any context the outgoing TAM wants to include)

## Core Workflow

1. **Ingest context** — Read what the TAM provides (account name, transition reason, anything they want to flag)
2. **Pull Vitally account data** — Account health, contacts, notes, conversations
3. **Pull PostHog usage data** — Product usage, event volume, feature adoption
4. **Pull billing context** — Spend breakdown, plan tier, billing trend
5. **Synthesize handover document** — Compile into the structured format (see Output Format)
6. **TAM review** — Present the draft for the outgoing TAM to fill in gaps the data can't capture

## Step 1: Pull Vitally Account Data

Search for the account and pull everything relevant. Run these in parallel where possible.

### 1a: Find the Account

Use `vitally:find_account_by_name` with the account name. If multiple results come back, ask the TAM which one. Then use `vitally:get_account_full` with `detailLevel: "full"` on the matching account ID.

### 1b: Extract Account Metadata

From the account record, pull:
- Account name, external ID (organization_id), creation date
- Health score
- MRR and forecasted MRR
- Plan tier (free, paid, startup program, enterprise)
- Assigned TAM/CSM (the current owner being transitioned from)
- Contract type (monthly vs. annual) and renewal date if applicable
- Key traits: industry, employee count, funding stage

### 1c: Get Key Contacts

Use `vitally:get_account_users` on the account ID. For each user, note:
- Name, email, role/title
- Last seen date (but remember Vitally's `lastSeenTimestamp` can be stale — PostHog event data is the truth for activity)
- Whether they're the org Owner
- Any segments they belong to (indicates which products they use)

Identify these roles from the contact list:
- **Champion** — the most active user, the one who drives PostHog adoption internally
- **Decision-maker** — the person who controls budget or signs contracts (often different from the champion)
- **Technical lead** — the engineer who implemented PostHog and handles the integration
- **Day-to-day contact** — who the outgoing TAM typically communicates with

If the data doesn't make these roles obvious, mark them as "[TAM to confirm]" in the output. Don't guess.

### 1d: Get Account History

Use `vitally:get_account_notes` and `vitally:get_account_conversations` on the account ID.

From the notes and conversations, build a timeline of key events:
- When onboarding happened
- Any escalations or support issues
- Feature requests the customer raised
- QBRs or business reviews
- Expansion conversations (new products, more seats, plan upgrades)
- Any commitments made by PostHog (discounts, custom features, timelines)
- Recent billing-related support tickets

**Pay special attention to the last 90 days.** The incoming TAM needs to know what's active right now, not just the full history. Separate recent context from historical context in the output.

### 1e: Check for Open Issues

Look through recent conversations and notes for anything unresolved:
- Pending support tickets
- Feature requests that were escalated or promised
- Billing disputes or credit requests in progress
- Upcoming renewals or contract negotiations
- Any "I'll get back to you on this" items

Flag every open item clearly. These are the things that will make the transition feel broken if the incoming TAM doesn't know about them.

## Step 2: Pull PostHog Usage Data

Run these queries in parallel via the `query-run` MCP tool. Every query must be scoped to the account's project — pass the `organization_id` (externalId from Vitally) as the `project_id` parameter in the `query-run` tool call so the events table only returns data for that account.

### 2a: Event Volume Trend (last 90 days, weekly)

```sql
SELECT
  toStartOfWeek(timestamp) AS week,
  count() AS event_count
FROM events
WHERE timestamp >= now() - INTERVAL 90 DAY
  AND properties.$organization_id = '{externalId}'
GROUP BY week
ORDER BY week
```

This shows whether usage is growing, flat, or declining — critical context for the incoming TAM.

### 2b: Product Adoption — Which Features Are in Use

```sql
SELECT event, count() AS cnt
FROM events
WHERE timestamp >= now() - INTERVAL 30 DAY
  AND properties.$organization_id = '{externalId}'
  AND event NOT IN (
    '$feature_flag_called',
    '$autocapture',
    '$web_vitals',
    '$dead_click'
  )
GROUP BY event
ORDER BY cnt DESC
LIMIT 30
```

Map the top events to PostHog products:
- `$pageview`, `insight viewed`, `dashboard viewed` → Product Analytics
- `$recording_viewed`, `recording analyzed` → Session Replay
- `$feature_flag_called` (excluded from query but check separately if needed) → Feature Flags
- `$ai_generation`, `$ai_span`, `$ai_trace` → LLM Analytics
- `error tracking issue viewed` → Error Tracking
- `survey sent`, `survey shown` → Surveys
- `$export` events → Data Pipelines

### 2c: Most Active Users (last 30 days)

```sql
SELECT
  person.properties.email AS email,
  count() AS event_count,
  max(timestamp) AS last_active
FROM events
WHERE timestamp >= now() - INTERVAL 30 DAY
  AND properties.$organization_id = '{externalId}'
  AND person.properties.email IS NOT NULL
  AND person.properties.email != ''
GROUP BY email
ORDER BY event_count DESC
LIMIT 15
```

Cross-reference with the Vitally contacts from Step 1c. The most active users are who the incoming TAM should build rapport with first.

## Step 3: Pull Billing Context

Query the billing report to understand spend patterns.

```sql
SELECT date, report
FROM postgres.prod.billing_usagereport
WHERE organization_id = '{externalId}'
ORDER BY date DESC
LIMIT 3
```

From the billing reports, extract:

**Current spend breakdown by product** (using Vitally forecasted MRR fields as a cross-reference):
- `product_analytics_forecasted_mrr`
- `session_replay_forecasted_mrr`
- `feature_flags_forecasted_mrr`
- `llm_analytics_forecasted_mrr`
- `error_tracking_forecasted_mrr`
- `data_warehouse_forecasted_mrr`
- `surveys_forecasted_mrr`
- `enhanced_persons_forecasted_mrr`

**Spend trend**: Compare the last 3 billing reports to classify as growing, flat, or declining.

**SDK breakdown** (from billing report fields):
- `web_events_count_in_period`
- `node_events_count_in_period`, `python_events_count_in_period`, `go_events_count_in_period`
- `ios_events_count_in_period`, `android_events_count_in_period`
- `flutter_events_count_in_period`, `react_native_events_count_in_period`

The SDK split tells the incoming TAM what the customer's tech stack looks like without having to ask.

## Step 4: Synthesize the Handover Document

Compile everything into the format below. Read `references/handover-template.md` for the full template with guidance notes.

### Sourcing Rules

Every section in the handover document should be clearly sourced:
- **[Data]** — pulled directly from Vitally, PostHog, or billing. The incoming TAM can trust this.
- **[TAM to confirm]** — placeholder where the outgoing TAM needs to add context from memory. Leave these as clear prompts, not blank spaces.
- **[Inferred]** — derived from the data but not explicitly stated. Flag the reasoning so the incoming TAM can validate.

## Output Format

Present the handover document with these sections. Use the template from `references/handover-template.md` as the structure.

### 1. Account Snapshot
- Company name, what they build, industry
- Employee count, funding stage (if known)
- PostHog plan and MRR
- Health score
- Account age (time since first event or Vitally creation date)
- Contract type and renewal date (if applicable)
- Transition reason (from TAM input)

### 2. Key Contacts

Table format:

| Name | Role | Email | Last Active | Relationship |
|------|------|-------|-------------|--------------|
| ... | ... | ... | ... | Champion / Decision-maker / Technical lead / [TAM to confirm] |

Include a note on who the outgoing TAM typically communicated with and through what channel (email, Slack, calls).

### 3. Product Usage Summary
- Which PostHog products are actively used (with monthly spend per product)
- Event volume trend (growing / flat / declining) with weekly numbers
- SDK breakdown (what's their tech stack)
- Top features and insights they use

### 4. Billing and Spend
- Current MRR and trend direction
- Spend breakdown by product (table)
- Contract details: monthly vs. annual, renewal date, any discounts or credits
- Billing limits (if set)
- Any pending billing issues or credit requests

### 5. Account History (Timeline)

Chronological list of key events, split into:

**Recent (last 90 days):**
- [date] Event description (source: Vitally note/conversation)

**Historical:**
- [date] Event description

### 6. Open Items
- Unresolved support tickets
- Pending feature requests
- In-progress conversations
- Commitments made by PostHog (discounts, timelines, custom work)
- Upcoming deadlines (renewals, credit expiry, QBRs)

### 7. Relationship Context

This section relies heavily on TAM input. Present what the data shows, then leave clear prompts:

- **Communication preferences**: [TAM to confirm — email, Slack, calls? How often?]
- **Meeting cadence**: [TAM to confirm — weekly, monthly, ad-hoc?]
- **Internal dynamics**: [TAM to confirm — who drives decisions? Any internal politics to be aware of?]
- **Personality notes**: [TAM to confirm — any communication style preferences, pet peeves, things that build rapport?]
- **Sensitive topics**: [TAM to confirm — past incidents, pricing disputes, anything to handle carefully?]

### 8. Recommended Next Steps for Incoming TAM

Based on the data, suggest:
1. **Intro approach** — how to introduce yourself (email, Slack message, or ask the outgoing TAM for a warm intro)
2. **First meeting agenda** — what to cover in the first conversation (acknowledge the transition, review open items, confirm their priorities)
3. **Quick wins** — anything the incoming TAM can do immediately to build trust (resolve an open ticket, follow up on a feature request, share a relevant resource)
4. **Watch items** — things to monitor (declining usage, upcoming renewal, credit expiry, unresolved escalation)

## Critical Rules

1. **Always pull from Vitally and PostHog.** Never generate a handover from memory or assumptions alone. The document should be grounded in real data.
2. **Flag data gaps.** If the account has no Vitally notes, say so explicitly — that's a gap the outgoing TAM needs to fill before the transition.
3. **Mark what needs TAM input.** Use `[TAM to confirm]` for anything the data can't answer. Relationship context, communication preferences, and verbal commitments live in the TAM's head, not in Vitally.
4. **Don't fabricate relationship context.** If the notes don't mention who the champion is, don't guess. Leave it as a prompt for the TAM.
5. **Prioritize recency.** The incoming TAM cares most about the last 90 days. Historical context matters but should be secondary.
6. **Surface open items prominently.** Dropped balls during a transition are the fastest way to lose trust. Every unresolved item should be impossible to miss.
7. **Run PostHog queries in parallel** to save time.
8. **Vitally `lastSeenTimestamp` is unreliable** for activity. Always cross-reference with PostHog event data for "last active" dates.
9. **If PostHog returns 503** (busy), wait a moment and retry once before giving up on that query.

## After Presenting the Draft

Once the handover document is generated, tell the outgoing TAM:

> "This is the data-sourced draft. Please review each section — especially **Relationship Context** and **Open Items** — and fill in anything marked [TAM to confirm]. Once you've added your notes, this is ready to share with the incoming TAM/CSM."

If the outgoing TAM provides additional context, incorporate it into the document and regenerate the relevant sections.
