---
name: posthog-pls-transition-leads
description: "Qualify and draft outreach for PostHog product-led leads who are hitting a billing transition — either startup program customers rolling off free credits, or users whose first invoice will be >= $2K. Use this skill when a TAE needs to work a startup rolloff lead, a high first-invoice alert, or any lead where the matching criteria mentions 'startup rolloff', 'credit spend', 'first invoice', 'credits expiring', or 'high usage transition'. Also trigger when a TAE pastes Salesforce lead details with matching criteria like 'Startup rolloff + high credit spend' or 'First invoice >= $2K'."
---

# PostHog Transition Lead Qualification & Outreach

Research, qualify, and recommend the right play for product-led leads hitting a billing transition. These fall into two categories:

1. **Startup rolloff** — Customers on PostHog's startup program ($50K free credits / 1 year) who are either nearing the end of the year or burning through credits fast enough to exhaust them early.
2. **High first invoice** — Users (free-tier-to-paid or new signups) whose first real invoice will be >= $2K, meaning they've crossed from casual usage into meaningful spend.

## What Makes Transition Leads Different from Big Fish

These are NOT cold outreach leads. The person is already a PostHog customer with real usage history. That changes the research depth, the framing, and the goal:

- **You already have data.** Vitally has their full usage history, billing data, and credit status. Lean on it — the billing analysis IS the research for these leads.
- **The trigger is a financial event, not a signup.** They're about to see their first real bill, or lose remaining credits. The outreach should help them navigate that transition, not introduce PostHog.
- **The goal is retention through the transition.** These accounts are already getting value from PostHog. The risk is sticker shock, not lack of adoption. Your job is to help them optimize their setup so the transition feels manageable — and to be the person they reach out to if they have questions about billing.
- **It's OK to reference billing directly.** Unlike big fish outreach (where you avoid commercial topics entirely), transition leads expect a conversation that touches on credits, usage, and costs. Frame it as optimization support, not a sales pitch.

## Core Workflow

1. **Parse the lead** — Identify lead type (startup rolloff vs. high first invoice) from matching criteria
2. **Check Vitally (billing-heavy)** — Account activity, users, products, and deep billing analysis
3. **Light company research** — Only if the company context is thin or unfamiliar
4. **Billing analysis** — Calculate post-transition costs, identify optimization opportunities
5. **Qualify and recommend a play** — Outreach / Light Touch / Skip
6. **Draft outreach** — Using the appropriate hooks for the lead type
7. **Validate all URLs** — Fetch every link in the draft to confirm it resolves

## Step 1: Parse the Lead

Identify which type of transition lead this is from the Salesforce matching criteria:

- **Startup rolloff**: Look for "startup rolloff", "credit spend", "credits expiring", "startup plan" in matching criteria. The account will be on the startup program with credits that are either expiring soon or being consumed rapidly.
- **High first invoice**: Look for "first invoice", "$2K", "high usage" in matching criteria. The account has crossed a usage threshold where their first invoice will be significant.

Some leads may have both signals (e.g., a startup rolling off credits whose first real invoice will be large). Treat these as startup rolloff — the credit expiry is the more urgent and specific hook.

## Step 2: Check Vitally (Billing-Heavy)

This is the most important step. For transition leads, the billing data matters more than firmographics.

### 2a: Find the Account

Search for the account in Vitally. The most reliable lookup is **user email** via `get_user_details`. If the email lookup returns the user with their account, use `get_account_full` on the account ID to pull complete billing data.

### 2b: Billing Data to Extract

Pull these fields from the account traits and Stripe data:

**For startup rolloff:**
- `amount_off` — remaining credit balance (from the original $50K)
- `amount_off_expires_at` — when credits/discount expire
- `stripe.metadata.startup_plan_end_at` — when the startup plan ends
- `stripe.metadata.credit_expires_at` — when credits expire (may differ from discount expiry)
- `creditRunwayDays` — at current spend, how long until credits are consumed
- Stripe MRR / last invoice amount — current monthly spend
- Stripe subscription details — which plan lines they're on
- Whether the account is in "Credits expiring before consumption" segment

From these, calculate:
- **Days until credit expiry** — how urgent is this?
- **Credit utilization** — how much of the $50K have they used?
- **Post-credit monthly cost** — what will their first real invoice look like?
- **Credit waste** — how much of the remaining credit will go unused?

**For high first invoice:**
- Stripe MRR / estimated first invoice amount
- Which products are driving the cost (events, recordings, feature flag requests, etc.)
- Whether billing limits are set
- Usage growth trajectory (is spend accelerating?)

### 2c: Check Users in the Account

Use `get_account_users` on the account ID. Note:
- **User count** — how many people are using PostHog?
- **Active users in last 30 days** — is the team actively engaged?
- **Vitally segments per user** — which products is each person using?
- **Who's the org Owner?** — this is usually the person who set up the account

For transition leads, user count still matters for prioritization, but unlike big fish leads, even a single-user account can be worth outreach if the spend is significant. A solo founder burning $3K/month on PostHog deserves a heads-up about their credits expiring.

**Who to address the outreach to:** The lead email from Salesforce is typically the person who created the PostHog account — but that's not always the right person to email. Look at who's actually active: recent last-seen dates and the highest number of sessions/segments. The most active user is your best target — they're the one with the deepest relationship to PostHog and the most context on how the team uses it. If the lead contact hasn't been active recently but someone else on the team has, address the email to the team (e.g., "Hey [Company] team") or to the most active user directly. Note the discrepancy in your output so the TAE can make the call.

### 2d: Check Products and Usage

From the account traits and user segments, identify:
- Which PostHog products are in active use
- The heaviest cost drivers (look at replay count, feature flag requests, event volume)
- Any obvious optimization opportunities (see Step 4)

### 2e: Check Conversations and Notes

Use `get_account_conversations` and `get_account_notes` to see if anyone from PostHog has already been in touch. For startup accounts, there's often a conversation from when they joined the startup program — note when it happened and who was involved, but it doesn't mean someone is actively working the account.

**Pay special attention to recent billing-related support tickets.** If the account filed a support ticket about billing, usage, or costs in the last 1-2 weeks, that changes the outreach significantly — they're already thinking about costs and have already engaged with PostHog on the topic. Flag this prominently in your output. The TAE's outreach should feel like a natural extension of that conversation (e.g., "saw your team had some questions about replay billing — happy to help you think through the bigger picture on costs as usage grows"), not a separate cold touch that ignores the context. Piling on with a generic transition email right after a billing support ticket feels tone-deaf.

### 2f: Check for Duplicate Accounts

Search Vitally for other accounts on the same email domain. Large companies sometimes have multiple PostHog orgs. If the lead's account is a duplicate of a more established one, flag it.

## Step 3: Light Company Research

For startup rolloff leads, you likely already know enough from Vitally and the startup program context. Only do web research if:
- You can't tell what the company does from Vitally data alone
- The company name is ambiguous and could be multiple entities
- You want to check recent funding or growth signals that might affect the conversation

For high first-invoice leads from unknown companies, do a quick web search:
- What does the company do?
- Do they build software products? (ICP relevance)
- Company size and stage
- Recent funding

Keep this lean — you're not writing a company dossier. One search, maybe two.

## Step 4: Billing Analysis & Optimization Opportunities

This is unique to transition leads. Before drafting outreach, identify specific things the TAE can offer to help:

### Common Optimization Opportunities

1. **Stale feature flags** — Active flags that aren't used in code still get evaluated and charged on every `/flags` call. Archiving unused flags can meaningfully cut feature flag costs. Link: https://posthog.com/docs/feature-flags/cutting-costs

2. **Billing limits** — Setting per-product billing limits prevents surprise overages. Many accounts don't have these set. Link: https://posthog.com/docs/billing/estimating-usage-costs

3. **Replay sampling** — If replay volume is high, sampling (recording a percentage of sessions instead of all) can cut costs significantly without losing insight quality.

4. **Anonymous vs. identified events** — Anonymous events are up to 4x cheaper. If the account is capturing identified events for interactions that don't need user-level attribution, switching to anonymous capture saves money.

5. **Autocapture tuning** — PostHog autocaptures pageviews and page leaves by default. Disabling autocapture and manually capturing only the events that matter can reduce event volume.

   **Autocapture is also a spend quality signal.** If the bulk of an account's event volume is coming from autocapture rather than custom-instrumented events, their actual committed spend may be much lower than the forecasted invoice suggests — because autocapture is easy to turn off or tune down without losing anything they rely on. An account whose $2K forecast is 80% autocapture events is very different from one that's $2K on intentionally instrumented custom events. When checking products and usage, try to assess whether the event volume is primarily autocapture or custom. If it's heavily autocapture, flag this in your output — the forecasted spend may overstate how "stuck" the account actually is.

6. **Data warehouse / batch export optimization** — If they're exporting large volumes, there may be ways to filter or reduce what's exported.

Don't try to surface ALL of these in the outreach email — pick the 1-2 most relevant based on what's actually driving their costs. The email should feel targeted, not like a generic cost-cutting checklist.

### Framing the Billing Conversation

The point isn't to make PostHog seem cheaper — it's to help them get the same value at a cost that feels right for their stage. If a startup is burning $1,500/month on PostHog and they're at $250K ARR, that's 7% of revenue on analytics tooling. Helping them optimize to $1,000/month might be the difference between churning and staying.

Be honest about what their costs will look like. Don't hide the number — surface it and pair it with optimization suggestions.

## Step 5: Qualify and Recommend a Play

### Billing Limits as a Qualification Signal

Before choosing a play, check whether the account has set billing limits — and if so, what they're set to. This is one of the strongest intent signals available because it represents a deliberate, specific decision about how much they're willing to spend.

An account that's set a total billing limit of $1,500/month across all products is telling you exactly what their budget is. They're unlikely to become a $20K account without a meaningful change in circumstances — treating them as a high-potential lead would be misreading the signal. Conversely, an account with no billing limits and growing usage may not have thought about costs yet, which is both an opportunity (they might welcome optimization help) and a risk (sticker shock when the invoice arrives).

Factor billing limits into your play recommendation and note them prominently in the billing analysis output.

### Play: Outreach (Slack Channel + Email)

Recommend outreach when:
- **Active team** — 2+ users active in the last 30 days
- **Meaningful spend** — post-transition cost will be >= $500/month
- **Approaching transition** — credits expire within 60 days, or first invoice is imminent
- **No one from PostHog is already engaged** — check conversations and notes

### Play: Light Touch (Email Only, No Slack Channel)

Recommend light touch when:
- **Single active user** but spend is significant (>= $1K/month post-transition)
- **Credits expire in 30+ days** — some urgency but not immediate
- **Small team / early stage** — a Slack channel feels heavyweight for a 3-person startup

### Play: Skip

Recommend skipping when:
- **Already being worked** by another TAE or CS team member
- **Very low spend** — post-transition cost will be < $500/month and usage isn't growing
- **Account looks abandoned** — no active users in last 30 days despite having credits

**When recommending Skip, you MUST provide a disqualification reason and disqualification notes** so the TAE can update Salesforce directly.

**Available disqualification reasons:**

- BAA / DPA Request
- Below Sales Assist Threshold - Pass
- Below Sales Assist Threshold - Prospect
- Billing Support Request
- Business Closed
- Duplicate Lead
- Event request
- Existing customer inquiry
- Feedback
- Invalid Contact Info
- No Budget
- No Current Need
- No Product Fit
- No Response - Pass
- No Response - Prospect
- No Technical Resource
- Non-Commercial
- Not a Good Fit
- Other
- Partnership request
- Resource Constraints
- Self-Hosted Requirement
- Spam
- Stale - autoclosed
- Startup Plan / YC
- Support Request
- Using Competitor / Unsolicited RFP

**How to choose the right reason for transition leads:**

- **Below Sales Assist Threshold - Pass**: Post-transition spend clearly below $500/month with no growth signals. Most common for small startup rolloffs.
- **Below Sales Assist Threshold - Prospect**: Below threshold now but usage trajectory or business growth suggests they could cross it. Worth revisiting.
- **No Current Need**: Account looks abandoned or usage is declining - they may not continue with PostHog post-transition.
- **Duplicate Lead**: Another PostHog org on the same domain is the real account.
- **Existing customer inquiry**: Lead is actually a support or billing question, not a sales opportunity.

**Disqualification notes must be 250 characters or fewer, specific, and copy-pasteable.** Include key billing data points.

Good DQ notes:
- "Startup rolloff, $340/mo post-credit spend. 2 users, analytics only. 12-person seed startup. Billing limit set at $400. No expansion signals."
- "First invoice $1.1K but 80% autocapture events. Actual committed spend ~$220/mo. 5-person team, no growth trajectory."
- "Abandoned - last active user seen 45 days ago. $18K credits remaining, expiring in 30 days. No engagement with onboarding."

Bad DQ notes:
- "Low spend" (how low? what's driving it?)
- "Small company" (which signal matters?)
- "Not worth pursuing" (why not?)

### Play: Urgent Outreach

Recommend urgent outreach when:
- **Credits expire in < 14 days** and the account doesn't appear to know
- **First invoice will be very large (>= $5K)** and no billing limits are set
- **Usage is spiking** — something changed recently that's driving cost up fast

## Step 6: Draft the Outreach Email

Read the appropriate reference file before drafting:
- Startup rolloff → `references/outreach-hooks-startup-rolloff.md`
- High first invoice → `references/outreach-hooks-first-invoice.md`

### Shared Principles (All Transition Leads)

1. **Lead with the Slack channel.** The shared Slack channel is the most valuable thing you're offering - a direct line to someone technical at PostHog who can help them ship faster. Don't bury it three paragraphs in. Open with it, explain why it's useful for their specific situation (using intel from your research), and make it easy for them to jump in. From the PostHog handbook: "We use shared Slack channels to provide timely support and to build relationships with those at our customers shipping things with PostHog." The Slack channel is also strategically important beyond the immediate transition. Even if the short-term outcome is helping them optimize and spend less, being in the room when they're building new features, hitting new problems, or wondering "does PostHog do X?" is where expansion happens organically. You won't know if there's opportunity to introduce them to parts of PostHog they aren't using or thinking about unless you can get them talking.
2. **Write like a fellow engineer, not a salesperson.** These are competent developers who are hard to engage precisely because they don't want emails from sales. The TAEs are deeply technical too. Write the way you'd message a colleague - direct, concise, no praise or cheerleading about their setup ("your team's ramped up fast!" reads as patronizing). State what you know, say what you're offering, and ask something that makes them want to reply.
3. **Keep it short.** The initial outreach should be brief. Slack channel, why it's useful for them specifically, and a conversation starter that entices them to actually open Slack and fire off a message. That's it. Save the billing optimization details for the Slack conversation itself - that's the whole point of getting them in there.
4. **Be direct about the transition.** If credits are expiring, say so. If their first invoice will be meaningful, help them understand why. Transparency builds trust. But keep it to a sentence, not a paragraph. For startup rolloffs specifically, it's OK to mention discussing pricing options or discounts - these customers have had PostHog for free and could be facing a significant bill. Offering to talk through options is a natural part of helping them through the transition.
5. **Follow PostHog's writing style.** Get to the point. No fluff. American English, Oxford comma, hyphens (not em/en dashes). No bare URLs - always use anchor text.

### Data Integrity Rule

Same as big fish: only reference things you can verify from Vitally usage data or the company's public website. Never cite enrichment data (Clearbit/Harmonic tech stack fields) as fact. If you state something about their setup and it's wrong, you lose credibility — especially with an existing customer who knows exactly what they're using.

## Step 7: Validate All URLs

Before presenting the draft, fetch every URL in the email to verify it resolves and points to the intended content. If a URL is broken, search for the correct page. If no valid page exists, remove the link.

## Output Format

When responding to the TAE, provide:

1. **Lead type** — Startup rolloff or high first invoice (or both)
2. **Company snapshot** — Brief: what they do, size, stage. Skip the deep dive unless needed.
3. **Vitally account summary** — Users (count, active, roles), products in use, health score
3a. **Disqualification reason** — From the available list (required when recommending Skip)
3b. **Disqualification notes** — 250 characters or fewer, specific and copy-pasteable (required when recommending Skip)
4. **Billing analysis** — This is the core of the output. Credits remaining, expiry date, current spend, post-transition cost, credit utilization, optimization opportunities.
5. **Recommended play** — Outreach / Light Touch / Skip / Urgent, with reasoning
6. **Draft email** — Using the appropriate hooks for the lead type
7. **Follow-up guidance** — Light notes on what to expect after sending

## Follow-Up Guidance

After the first outreach, here's what typically happens and how to respond:

### If They Reply with Questions About Billing/Pricing
This is the best outcome. They're engaged and thinking about the transition. Answer their questions directly, offer to walk through their usage dashboard together (async or call), and help them set billing limits if they haven't already.

### If They Reply Asking to Optimize
They want help reducing costs. Walk them through the specific optimization opportunities you identified. This might be a good time for a short call where you screenshare their billing dashboard.

### If They Don't Reply (7 Days)
One follow-up is fine. Keep it short — reference the original email and the upcoming transition date. Don't add new content or resources. If still no reply after the follow-up, let it go. They'll see the invoice and may reach out then.

### When to Loop in Others
- **If they want to negotiate pricing or ask about annual contracts** → Loop in the AE. This is now a sales conversation.
- **If they report a bug or technical issue** → Point them to support or the Slack channel. Don't try to debug it yourself unless it's simple.
- **If they want to downgrade or churn** → Understand why first. If it's purely cost, see if optimization helps. If it's product fit, that's useful feedback — note it and loop in CS/Product if appropriate.

## Critical Reminders

1. **The billing analysis is the research.** Don't spend 30 minutes on company firmographics when the real question is "what will they pay after credits expire?"
2. **Be direct about costs.** These customers are about to get a bill. Helping them understand it in advance is a kindness, not a sales pitch.
3. **Pair costs with optimization.** Every cost mention should come with a way to reduce it.
4. **Check conversations first.** Someone from the startup program or CS team may already be in touch.
5. **Single users still matter here.** Unlike big fish (where 1 user = low priority), a single user spending $2K/month is absolutely worth outreach.
6. **Lead with the Slack channel, not billing.** The first sentence of the email should be about the Slack channel and why it's useful for them. Billing context comes after.
7. **Validate URLs before presenting the draft.**
8. **Always provide a DQ reason and DQ notes when recommending Skip.** Include the disqualification reason from the available list and copy-pasteable notes (250 chars or fewer). Be specific - name concrete billing data and signals, not generic language.

## BAA / HIPAA Pricing Reference

When a transition lead mentions HIPAA, BAA, or healthcare data:

- **Standard BAA (no redlines):** Boost add-on at **$250/month** + usage-based pricing. BAA can be generated at posthog.com/baa.
- **Custom/redlined BAA:** Enterprise plan at **$2K/month** (paid annually) + usage-based pricing.

Lead with Boost as the standard path. Don't default to "enterprise pricing."

## Non-Profit Discount Reference

- **Credit purchases below $25K:** 15% discount
- **Credit purchases $25K-$100K:** additional 5% on top of standard volume discount
- **Credit purchases above $100K:** standard volume discounts apply

Customer needs proof of non-profit status per their country's tax law.
