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

### 2d: Check Products and Usage

From the account traits and user segments, identify:
- Which PostHog products are in active use
- The heaviest cost drivers (look at replay count, feature flag requests, event volume)
- Any obvious optimization opportunities (see Step 4)

### 2e: Check Conversations and Notes

Use `get_account_conversations` and `get_account_notes` to see if anyone from PostHog has already been in touch. For startup accounts, there's often a conversation from when they joined the startup program — note when it happened and who was involved, but it doesn't mean someone is actively working the account.

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

6. **Data warehouse / batch export optimization** — If they're exporting large volumes, there may be ways to filter or reduce what's exported.

Don't try to surface ALL of these in the outreach email — pick the 1-2 most relevant based on what's actually driving their costs. The email should feel targeted, not like a generic cost-cutting checklist.

### Framing the Billing Conversation

The point isn't to make PostHog seem cheaper — it's to help them get the same value at a cost that feels right for their stage. If a startup is burning $1,500/month on PostHog and they're at $250K ARR, that's 7% of revenue on analytics tooling. Helping them optimize to $1,000/month might be the difference between churning and staying.

Be honest about what their costs will look like. Don't hide the number — surface it and pair it with optimization suggestions.

## Step 5: Qualify and Recommend a Play

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

1. **Lead with a usage observation.** Even though this is a billing-adjacent conversation, start with what they're doing in PostHog — it shows you've looked at their account and care about their use case, not just their wallet.
2. **Be direct about the transition.** Don't bury the lede. If credits are expiring, say so. If their first invoice will be $2K, help them understand why. Transparency builds trust.
3. **Pair every cost mention with an optimization suggestion.** Don't just tell them they'll pay $X/month — tell them how to get the same value at $Y/month. Link to one specific, relevant resource.
4. **Slack invite (if multi-user).** Mention naturally, not as the centerpiece.
5. **One open question at the end.** About them and their priorities, not about PostHog.
6. **Follow PostHog's writing style.** Get to the point. No fluff. American English, Oxford comma, sentence case, en dashes with spaces. No bare URLs — always use anchor text.

### Data Integrity Rule

Same as big fish: only reference things you can verify from Vitally usage data or the company's public website. Never cite enrichment data (Clearbit/Harmonic tech stack fields) as fact. If you state something about their setup and it's wrong, you lose credibility — especially with an existing customer who knows exactly what they're using.

## Step 7: Validate All URLs

Before presenting the draft, fetch every URL in the email to verify it resolves and points to the intended content. If a URL is broken, search for the correct page. If no valid page exists, remove the link.

## Output Format

When responding to the TAE, provide:

1. **Lead type** — Startup rolloff or high first invoice (or both)
2. **Company snapshot** — Brief: what they do, size, stage. Skip the deep dive unless needed.
3. **Vitally account summary** — Users (count, active, roles), products in use, health score
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
6. **Lead with usage, not billing.** The first sentence of the email should be about what they're doing in PostHog, not about their credits or invoice.
7. **Validate URLs before presenting the draft.**
