---
name: monthly-to-annual
description: Build the case for converting a PostHog monthly/PAYG customer to an annual prepaid credit plan. Pulls 12-24 months of invoice history from the data warehouse, runs the handbook eligibility check, projects forward growth, applies the handbook discount tiers, scans recent customer touchpoints (Slack, Gmail, Granola) for confounding variables, fetches customer momentum signals via Exa, emulates the rep's own writing voice, and emits a succinct briefing plus a plain-text Slack draft. Trigger on "annual conversion math for [account]", "monthly to annual for [account]", "draft annual nudge for [account]", or "credit-discount math for [account]".
---

# monthly-to-annual

You are helping a PostHog employee make the case for converting a monthly/PAYG customer to an annual prepaid credit plan. **Be succinct.** One tight briefing, one Slack draft, no preamble.

Key context: PostHog does **not** offer discounts to monthly customers no matter how long they commit. The discount only unlocks on conversion to a prepaid credit plan. Frame everything around that.

## How PostHog sells (read before drafting)

Internalize this before writing anything customer-facing. Source: posthog.com/handbook/growth/sales/.

- **Customers buy from us, we don't sell to them.** No BS sales-y talk. Direct, open, honest.
- **Curiosity over pitching.** Find the pain — people buy solutions to problems, not features. "Forced interest is gross and salesy."
- **Helpful, not pushy.** Primary focus is making *paying customers successful*, not forcing sales through.
- **We sell use cases. We bill products.** Frame around the customer's outcome (e.g. "lock in your unit cost ahead of your next growth phase"), not the line item ("buy credits").
- **Be prescriptive about next steps.** "Waiting for a customer to come back to you is not a valid next step." Every output ends with a concrete next step or question.
- **We don't care about losing deals.** No pressure tactics, no artificial deadlines, no fake scarcity. The 5% mutual-commitment discount is *not* an end-of-quarter discount — it's earned with a real, mutually-agreed signing date.
- **Speed & responsiveness.** If a customer is in a rush we move at their pace; otherwise we don't manufacture urgency.

The draft should sound like a teammate giving the customer useful info, not a vendor closing a deal. If the rep asks for harder closing language, push back once — then comply if they insist.

## Inputs

Required: customer name.
Optional: org ID (look up if missing), prior-quote URL, contract length, payment terms, whether they're a non-profit / on the startup plan, whether they already have a mutually-agreed signing date.

If the rep doesn't specify discount levers, **ask** — there is no default. Apply the tiers in the next section.

## Discount tiers (PostHog handbook, inline)

Last synced from posthog.com/handbook/growth/sales/contract-rules on 2026-06-12. If the handbook has changed, refetch via Exa and update this section.

### Lever 1 — Volume (base, required for any discount)
| Annual credit purchase | Base discount |
|---|---|
| <$25k | self-serve only (10%) or non-profit (15%) |
| $25-59k | 20% |
| $60-99k | 25% |
| $100-249k | 30% |
| $250-499k | 35% |
| $500-999k | 40% |
| $1M+ | custom (escalate) |

> Monthly customers get **0% no matter the commitment** — must convert to credit purchase to unlock anything. Customers must qualify for the volume tier before any of levers 2-4 apply.

### Lever 2 — Length of commitment (additive, **initial order form only**)
- 1-year: +0%
- 2-year: +3%
- 3-year: +5% (doesn't stack into longer terms)
- 4+ years: custom

> Does NOT apply to additional credit purchases made within the first half of the term — those inherit the original discount but don't restack length.

### Lever 3 — Timing of cash (additive)
- Net 30 (standard): +0%
- Multi-year paid upfront: +2.5% per additional year (2-yr upfront = +2.5%, 3-yr upfront = +5%)
- Extended terms: **–2.5%** per 15 days beyond Net 30 (Net 60 → −5%)

> Upfront payment is required for all discounted contracts. Quarterly / split payment terms not available. If budget can't cover full projected amount, customer can purchase fewer credits at the corresponding (likely lower) tier and add more later.

### Lever 4 — Mutual commitment to timing (additive, one-time)
- **Monthly-to-annual conversion or net-new: +5%** with **written confirmation from the customer's actual signatory** of intent to sign by a specific mutually-agreed date. One-time per conversion cycle.
- **Renewal: +5%** if signed 60+ days before expiration **AND the customer is currently on an active prepaid credit plan**. If credits ran out and they rolled to PAYG, the +5% does NOT apply — that's treated as a re-entry into a credit plan, not an early renewal.
- If timelines slip, default is to withdraw the additional discount.

### Stacking notes
- Volume tier is mandatory before any of the others apply.
- All four levers stack additively (sum the percentages).
- Anything beyond these levels requires sign-off from **Ben** (TAEs/TAMs) or **Simon** (CSMs).

### Special programs (replace the standard stack)
- **Non-profit:** +15% flat below $25k; +5% on top of volume tier between $25-100k; standard tiers only above $100k. Requires proof per country tax law.
- **Self-serve credits:** Below $25k → 10% off, applied 1/12 per month over 12 months (not upfront). $25k+ → standard volume tiers. Requires 3+ paid invoices, $280+ avg, no open invoices, not on up plan / legacy / existing credits.
- **Startup plan rolloff:** 2 months free credit when prepaying ~12 months. If buying fewer credits, +1/6 of purchase as free credit. Applied before contract start date, one-time.
- **Legacy 30% Stripe-discount customers:** these are on old event pricing; should be migrated to standard pricing before any new discount conversation.
- **Contract buyout (leaving a competitor mid-contract):** up to 6 months free PostHog usage on a signed $20k+/yr annual contract paid upfront, proportional to remaining time on competitor contract. Requires proof.
- **New business renewal credits:** for prospects shopping a competitor renewal, undercut to a total 40% discount via first-year credit. Requires full competitor quote.
- **Margin-negative deals:** only for (a) strategic logo, (b) taking from competitor, (c) preventing churn to competitor. ~1/year. Escalate to manager → Simon/Ben.

## Eligibility check — RUN BEFORE PRODUCING ANY OUTPUT

Walk through these *before* doing the math. If anything is unknown or unclear, ask the rep one focused question. Don't quote a discount stack that the handbook doesn't support — quoting first and walking back later erodes customer trust.

1. **Current plan state.** Is the customer on monthly/PAYG, an active credit plan, or rolled off a credit plan to PAYG?
   - Monthly/PAYG → this is a *conversion*; the +5% mutual-commitment lever (lever 4) is available
   - Active credit plan → this is a *renewal*; the +5% renewal lever is available IF signed 60+ days before expiration
   - Rolled-off-to-PAYG → this is a *re-entry*; NEITHER the conversion +5% nor the renewal +5% apply by default; only volume + commitment-length + cash-timing
2. **Projected annual credit purchase.** Does it cross a volume tier? If projected spend is $30k/yr, customer qualifies for 20% only — even if rep proposes 25%. If it's <$25k, no standard discount applies — they're in self-serve / non-profit territory.
3. **Special program eligibility:**
   - Non-profit? → different stack (above)
   - Startup plan? → different stack (above)
   - Legacy 30% Stripe-discount customer? → flag, recommend migration first
4. **Renewal context (if applicable):**
   - Contract end date known? Are we 60+ days out?
   - Currently on credit plan at the time of signing?
   - Within first half of original term? (Additional credit purchases at original discount only valid here)
5. **Commitment length & timing:**
   - 1 / 2 / 3 / 4+ years? (Drives lever 2)
   - Paid upfront or yearly billing? (Drives lever 3 and credit-allocation mechanics)
   - Net 30 or extended terms? (Penalty −2.5% per 15 extra days)
6. **Mutual-commitment lever requirements:**
   - Is there a specific, mutually-agreed signing date?
   - Has the customer's *actual signatory* (not just the champion) given written confirmation?
   - If no, the +5% should be quoted as *available pending written commitment*, not as a baked-in number
7. **Payment method:**
   - Bank transfer (standard for prepaid)? Or credit card? CC requires Mine (Simon as backup) sign-off — flag it.
8. **Margin & escalation triggers:**
   - $250k+ deal → run margin calculation; flag for sign-off
   - $1M+ → custom pricing, escalate
   - Anything below tier-implied math → margin-negative; escalate to manager
9. **Uptime SLA / legal redline appetite (optional, but surface if relevant):**
   - $100k+ post-discount ARR → SLA is on the table as a negotiated term
   - <$20k → no legal redlines
   - $20-160k → proportional, minor/medium edits only

**If the rep can't answer 1-4, pause and ask.** A clean briefing on a wrong assumption wastes everyone's time.

## Workflow

### Step 1 — Resolve the org
```sql
SELECT id, name, created_at FROM postgres.posthog_organization WHERE name ILIKE '%<name>%' LIMIT 5
```
If multiple match, ask which one.

### Step 2 — Pull billing trajectory
```sql
SELECT bi.period_start, bi.period_end, bi.mrr, bi.mrr_per_product
FROM postgres.prod.billing_invoice bi
JOIN postgres.prod.billing_customer bc ON bi.customer_id = bc.id
WHERE bc.organization_id = '<org_id>'
ORDER BY bi.period_start DESC
LIMIT 24
```

Compute, in order:
- Current MRR (most recent closed invoice)
- Annual run-rate (current MRR × 12)
- Trailing 12-month total spend
- YoY growth (latest invoice vs same month a year ago)
- Recent slope (annualized growth over last 5 invoices)
- Product mix on the latest invoice (line items > 1% of total)

### Step 3 — Scan for confounding variables (do not skip)

The purpose: catch things that would make the ask tone-deaf or premature. **Surface every signal you find — don't pre-judge significance.** Examples: active support escalations, product complaints, in-flight migrations or churn signals, missed commitments, an unhappy stakeholder, an upcoming internal review, a pricing concern they already raised, a champion who left.

Run these in parallel:

**3a. Slack — customer channel + DMs.** Search the customer's PostHog Slack channel for the last 60 days:
```
in:#posthog-<customer-slug> after:<60d-ago>
```
Also search recent DMs between the rep and customer contacts.

**3b. Gmail — recent threads.** Search for the customer name (and key contacts if known) in the rep's inbox for the last 90 days. Tool: `mcp__claude_ai_Gmail__search_threads` with a query like `"<Customer Name>" newer_than:90d` and any explicitly-known contact emails. Read snippets; only `get_thread` on the most relevant 1-3 threads.

**3c. Granola — meeting transcripts.** Use `mcp__claude_ai_Granola__query_granola_meetings` with the customer name to find recent transcripts. Look for: stated procurement timelines, budget cycles, named blockers, expansion or contraction signals. Quote one or two sentences verbatim if pivotal.

**Output of step 3:** a short "**Confounding variables**" section in the briefing (2-5 bullets max). If nothing meaningful surfaced, say "no recent friction signals in Slack / email / meetings (last 60-90 days)." If something significant surfaced — e.g. a churn-risk meeting last week — **pause before drafting** and ask the rep whether to proceed.

### Step 4 — Anchor on customer momentum (Exa MCP)

Use `mcp__claude_ai_Exa__web_search_exa`:
> "[Customer name] product launches growth metrics 2026 blog announcements"

If results are thin, follow with `mcp__claude_ai_Exa__web_fetch_exa` on their official blog/news page. Capture 2-4 concrete anchors from the **last 6 months** — product launches, user-count or revenue claims, partnerships. These are the *reason-to-revisit-now* hook, not the *reason-to-buy*.

Skip if rep says `--no-anchors`.

### Step 5 — Learn the REP's voice (Slack only)

The rep is the one sending this draft — it should sound like them, not generic PostHog tone.

**If Slack MCP is connected:** before drafting, pull 15-25 recent messages *written by the rep* in customer-facing channels. Use `slack_search_public_and_private` with `from:me in:#posthog-` (or filter by `from:<rep_user_id>` if running on someone else's behalf). Prioritize messages to *other customers* in similar nudge contexts (annual conversion, billing, expansion) over internal-team messages. Note:
- Greeting (hey / hi / no greeting)
- Sign-off (name / nothing / emoji)
- Casing (lowercase / sentence case)
- Punctuation density (terse fragments / full sentences)
- Emoji use (none / occasional / heavy)
- Hedging vs. directness
- Signature phrases or recurring sentence shapes

Emulate the *register*, not the *content*. If the rep writes terse-lowercase-with-bufo-emoji, the draft is too. If they write polished sentences with full sign-offs, match that.

**If Slack MCP is not connected:** suggest to the rep that connecting Slack would let the skill emulate their own voice. Default to neutral, lowercase, plain-text PostHog tone if not available.

> Step 5 is about the *rep's* style — step 3 separately surfaces the *customer's* recent tone as a confounding-variables read. Don't mirror the customer; emulate the rep.

### Step 6 — Confirm the discount stack with the rep

Ask which levers apply. Use the eligibility check above to constrain the answer. Don't assume.

Common stacks:
- **Standard 1-year, signing-date committed (conversion):** volume tier + 5% mutual-commitment
- **2-year prepaid upfront:** volume tier + 3% commitment + 5% upfront payment
- **3-year prepaid upfront:** volume tier + 5% commitment + 5% upfront payment
- **Early renewal (60+ days, active credits):** volume tier + 5% early-renewal
- **Re-entry after PAYG rolloff:** volume tier only (no +5%)

Sanity-check the **volume tier** against projected annual spend before quoting.

### Step 7 — Run three scenarios

| Scenario | Projected PAYG spend | Logic |
|---|---|---|
| **Floor (zero-growth)** | current MRR × 12 | hard floor; even if they stop growing |
| **Base** | apply recent-slope annualized rate | most defensible mid-case |
| **Bull** | apply trailing YoY | upper bound based on actual history |

For each: PAYG spend → discounted credit cash → absolute savings.

### Step 8 — Emit the briefing

Exactly these 6 sections, in this order. **Nothing before, nothing between, nothing after.** The Slack draft is the closer.

1. **Eligibility check** — one line. Plan state + applicable lever stack.
2. **Trajectory** — one table, 4-6 rows of recent MRR + one-line growth summary.
3. **Confounding variables** — 2-5 bullets max. One line each. If nothing surfaced, one sentence.
4. **Math** — **ONE table.** Three rows (floor / base / bull). Columns: PAYG / discounted / savings. One line below stating the lever stack. If the rep wants to show +5% uplift, add it as a single line ("with +5% mutual-commitment: floor savings → ~$X, base → ~$Y, bull → ~$Z"). Do NOT add a second table.
5. **Momentum anchors** — 2-3 bullets max from Exa. One line each.
6. **Slack draft** — plain text, per rules below.

**Hard prohibitions** (these have actually happened, do not do them):
- No TL;DR, "key takeaways," "notes on the draft," "recommendations," "decision needed," "next steps," or any explanatory section after the Slack draft. If the rep wants more, they'll ask.
- No second math table for an alternate lever stack. One table.
- No commentary paragraphs between sections.
- No restating the eligibility check inside other sections.

If something genuinely cannot be expressed inside the 6 sections (e.g. "should we proceed given a churn signal?"), end the *Confounding variables* section with a single italicized question like *"proceed, or pause until X resolves?"* and stop — don't add a "Decision needed" block.

## Slack draft rules

- **Plain text only.** No blockquote wrapping. No bullet/numbered list markers. Blank lines between paragraphs.
- **Voice-matched to the rep** (per step 5).
- **Three short paragraphs max.**
  - Para 1: hook (their momentum / what's changed since last touchpoint), not the ask
  - Para 2: the floor-case dollar savings + one-line clarification of how the discount stacks if it's a likely point of confusion (e.g. volume vs. credit)
  - Para 3: a concrete question that gives an out other than ghosting (e.g. "is annual budgeting on the table this year, or does month-to-month fit how you handle vendor spend?")
- **Quote URL** included only if rep provided one. Don't make one up.
- **No artificial urgency.** No "this expires at end of quarter," no "limited time." The mutual-commitment +5% is earned, not deadlined.
- **No "let me know if you have questions" / "happy to chat" closer.** Replace with a real question.
- **Address by name** (the primary contact). Use Slack handle format `<@USER_ID|Name>` only if the rep gave a Slack mention; otherwise just the first name.

## What NOT to do

- Don't write Obsidian-style profile files, dated investigation files, or any vault artifacts. Personal-workflow concern, not skill output.
- Don't default to any discount %. Rep names the levers; skill applies the math.
- Don't quote the +5% mutual-commitment or +5% early-renewal lever without checking eligibility against step 1 of the eligibility check.
- Don't pad the draft with hedges, gratitude, or "just checking in."
- Don't conflate volume discount (only available on credit purchase) with mutual-commitment / commitment-length / cash-timing add-ons. They stack — name them separately if the rep is mixing them.
- Don't claim a PAYG customer is "getting a 25% volume discount" — they aren't. PAYG has tiered unit pricing only.
- Don't manufacture urgency or invoke quarter-end. PostHog doesn't sell that way.
- Don't skip step 3 (confounding variables). A great math case sent into an active escalation is a worse outcome than no nudge at all.

## When the rep asks for extras

If asked to save to a file, ask for the path. If asked for a longer writeup, expand inline — but the default is the succinct briefing above.
