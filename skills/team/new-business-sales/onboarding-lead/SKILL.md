---
name: posthog-onboarding-lead-research
description: "Research and qualify onboarding team referral leads for PostHog. Use this skill when a TAE receives a lead from the onboarding team and needs a full research brief before deciding how to engage. Triggers on 'research this onboarding lead', 'onboarding team referred [company]', 'look into [company] from onboarding', 'qualify this onboarding referral', 'what do we know about [company] from onboarding', or any request to research a company that came through the onboarding pipeline. Also trigger when a TAE pastes a company name and mentions it's from the onboarding team, or says something like 'onboarding sent me [company]', 'got a handoff for [company]', or '[name] from onboarding sent me [company]'. This skill does deep research and qualification, then drafts outreach when the recommendation is to engage."
---

# PostHog Onboarding Lead Research & Qualification

Deep-research a company referred from the onboarding team. Produces a complete brief: company overview, $2K+/month likelihood score, Vitally usage/billing analysis, onboarding team context, business growth trajectory assessment, and - when the recommendation is to engage - a draft outreach email with Slack channel guidance.

## Context

The PostHog onboarding team works with self-serve accounts that have a forecasted bill > $100 for an 8-week engagement. When accounts reach ~$1-1.5K/month and show growth potential, they hand them to the TAE via the "Sales Handoff" pipeline status in Vitally.

This skill does the research, scores the lead, and - when the recommendation is to engage - drafts the outreach. The TAE needs to understand the company, its trajectory, and the full context of the onboarding engagement before reaching out.

## Inputs

Ask the TAE for:
- **Company name** (required)
- **Any context from the referral** - e.g. a Slack message or email from the onboarding team (optional but helpful)
- **Contact name** if known (optional)

If the TAE only gives a company name, that's enough to start - pull the rest from Vitally and web research.

## Workflow

Run these five workstreams. Steps 1-2 use web search. Steps 3-4 use Vitally MCP. Step 5 combines web research with Vitally/SFDC/Harmonic data from traits. Interleave them efficiently — don't wait for one to finish before starting the next.

---

### Step 1: Company Research & Growth Trajectory

**Goal:** Understand who this company is and whether they're on a growth path that makes $2K+/month likely.

**Web searches to run:**
```
[company name] what does it do
[company name] crunchbase funding employees
[company name] series funding 2024 2025
[company name] engineering team hiring
[company name] product launch growth
```

**Gather:**
- One-sentence description of what the company does
- Industry / vertical
- Company size (employees, engineering headcount if available)
- Funding stage and recency (series, amount, date)
- Revenue estimate if available
- HQ location
- Product type — is this a software product company? SaaS? Marketplace? E-commerce?
- Recent news — launches, expansions, partnerships, hiring sprees
- Growth signals — new product lines, international expansion, increasing headcount

**Growth trajectory assessment:**
Based on the research, classify the company's growth trajectory:

| Trajectory | Description |
|-----------|-------------|
| **Accelerating** | Recent fundraise, hiring, product launches, or expansion. Usage will likely grow fast. |
| **Steady growth** | Established company, consistent hiring, stable product. Predictable growth. |
| **Flat/uncertain** | No recent funding, unclear growth signals, may be in maintenance mode. |
| **Early stage** | Seed/A, small team, product still finding market fit. High variance. |

---

### Step 2: $2K+ Monthly Spend Likelihood Score

**Goal:** Score the probability this account will cross $2K/month within 3-6 months.

Read `references/scoring-model.md` for the full scoring criteria.

**Quick summary of the scoring:**
- Positive signals: growth trajectory, multi-product usage, engineering team size, funding recency, industry fit, active user count, event volume trends
- Negative signals: flat/declining usage, no engineering growth, non-ICP industry, single product user, low user count

**Output a score from 0-100 with a tier:**
- **80-100: High confidence** — Strong growth signals, multi-product, expanding team. Will likely hit $2K+ organically.
- **60-79: Moderate confidence** — Good signals but some uncertainty. May need a nudge (e.g. new product adoption, config optimization).
- **40-59: Low confidence** — Mixed signals. Could go either way. Worth engaging but temper expectations.
- **0-39: Unlikely** — Flat usage, small team, no growth signals. May stay at current spend.

---

### Step 3: Vitally Usage & Billing Analysis

**Goal:** Pull hard data on what this account is actually doing in PostHog and where the spend is going.

#### 3a: Find the Account

Search Vitally for the account. Try these in order:
1. `search_accounts_advanced` with the company name
2. If that fails, ask the TAE for a contact email and use it to look up via user details

#### 3b: Pull Full Account Data

Once you have the account ID, pull:

1. **`get_account_full`** (with `detailLevel: "full"`) — Gets everything: MRR, health scores, traits, product usage, billing data, team assignments
2. **`get_account_health`** — Detailed health score breakdown

**Always extract these three fields for the Quick Links section:**
- `organization_id` (in traits) → Vitally URL: `https://posthog.vitally-eu.io/customers/{organization_id}`
- `sfdc.Id` (in traits) → Salesforce URL: `https://posthog.my.salesforce.com/{sfdc.Id}`
- `usage_dashboard_link` (in traits) → direct Metabase usage dashboard link

**Extract and analyze:**

**Current billing:**
- Current MRR / monthly spend
- Which products are driving the spend (Analytics, Session Replay, Feature Flags, etc.)
- Billing plan (pay-as-you-go vs. annual)

**Usage trends (from traits):**
- Event volume (current and trend)
- Session replay volume
- Feature flag evaluations
- Active users count and trend
- Products enabled vs. products actively used

**Growth indicators:**
- Is event volume increasing month over month?
- Are new products being adopted?
- Are new users being added to the org?
- Is there a gap between products enabled and products used? (expansion opportunity)

**Trajectory projection:**
Based on the trends, project where this account lands in 3 months:
- Current monthly spend: $X
- Projected monthly spend (3 months): $X
- Key driver of growth: [product/volume/new users]
- Risk factors: [anything that could stall growth]

#### 3c: Check for Other Accounts on the Same Domain

Large companies sometimes have multiple PostHog orgs. Search for other accounts with similar names to flag consolidation opportunities.

---

### Step 4: Onboarding Team Context

**Goal:** Get the full history of what the onboarding team discussed, tried, and learned about this customer.

#### 4a: Vitally Notes

Use `get_account_notes` (with a high limit, e.g. 20) to pull all notes on the account. The onboarding team typically logs:
- Initial outreach attempts and responses
- Call notes from onboarding sessions
- Configuration changes made
- Product recommendations given
- Customer pain points and goals
- Reasons for the handoff to sales

**Summarize the onboarding narrative:**
- Did the customer engage with the onboarding team? (calls, email replies, or silence)
- What did the onboarding team help with?
- What products/features were discussed?
- What pain points or goals did the customer mention?
- Why is the onboarding team handing off now?
- Any open issues or unfinished business?

#### 4b: Vitally Conversations

Use `get_account_conversations` to pull email threads and other conversations. These often contain:
- Email exchanges between the onboarding rep and the customer
- Details the customer shared about their use case
- Commitments or follow-ups that were promised

**Extract key details:**
- Who was the primary contact on the customer side?
- What was the tone of engagement? (enthusiastic, transactional, unresponsive)
- Any specific asks or blockers the customer raised?
- Were there any promises or follow-ups left open?

#### 4c: Granola Meeting Notes (if applicable)

If the TAE or the onboarding team had calls logged in Granola, query for them:
```
Query: "[company name] onboarding" or "[company name] [contact name]"
```

This surfaces any call transcripts with additional detail beyond what's in Vitally.

---

### Step 5: Business Growth Trajectory & PostHog Spend Mapping

**Goal:** Assess how fast the company's *business* is growing, because that directly predicts how fast their PostHog usage (and spend) will grow. This is the step that catches cases where Vitally billing data lags the real trajectory — a company doubling its customer base will eventually double its event volume, even if the billing hasn't caught up yet.

**Web searches to run:**
```
[company name] Inc 5000 revenue growth
[company name] new customers partnerships 2025 2026
[company name] product launches announcements
[company name] hiring engineering jobs
```

Also cross-reference signals already gathered from Vitally traits:
- `sfdc.harmonic_headcount__c` vs `sfdc.harmonic_headcount_180d__c` — headcount delta
- `sfdc.harmonic_headcountEngineering__c` vs `sfdc.harmonic_headcountEngineering_180d__c` — eng headcount delta
- `sfdc.harmonic_web_traffic__c` vs `sfdc.harmonic_web_traffic_90d__c` / `sfdc.harmonic_web_traffic_180d__c` — traffic trends
- `sfdc.webtraffic_growth__c` — percentage growth
- `sfdc.lnkd_follower_change__c` — LinkedIn momentum
- `sfdc.eng_headcount_change__c` and `sfdc.headcount_eng_growth__c` — engineering team growth

**Gather and assess these six growth vectors:**

#### 5a: Revenue & ARR Growth
- Revenue estimates from funding announcements, Inc. 5000 rankings, press releases
- Any disclosed growth rates (e.g. "doubled ARR", "3x revenue")
- Evidence of pricing power or contract expansion (moving upmarket, bigger deals)

#### 5b: Funding & Investor Signals
- Recent fundraise amount, date, lead investor, and what the funds are earmarked for
- Repeat investors (insiders participating again = confidence)
- Are they raising a growth round (go-to-market) or an R&D round? GTM rounds drive PostHog usage faster.

#### 5c: Product Velocity
- New product launches or major features shipped in the last 12 months
- New product lines = new surfaces to instrument = more PostHog events and replays
- Platform plays (APIs, integrations, clearinghouses, marketplaces) create multiplicative event growth

#### 5d: Customer / Market Expansion
- New customer segments being targeted (enterprise, SMB, new verticals, new geographies)
- Partnership announcements (channel partners, tech partnerships, integrations)
- Each new customer on their platform = more end-user sessions flowing through PostHog

#### 5e: Headcount & Hiring Trajectory
- Total headcount delta (6-month and 12-month view using Harmonic data from Vitally)
- Engineering team growth specifically — more engineers = more features shipped = more things to instrument
- Go-to-market hiring (sales, CS, marketing) = more internal PostHog dashboard users
- Job postings on their careers page — what are they hiring for right now?

#### 5f: Web Traffic & Brand Momentum
- Web traffic trends from Harmonic/SFDC data
- LinkedIn follower growth
- Industry recognition (awards, rankings, conference appearances)
- Content marketing velocity (blog posts, reports, webinars) — indicates go-to-market investment

**Map business growth to PostHog spend growth:**

After gathering these signals, explicitly connect the company's business growth to expected PostHog usage growth. This is the key insight - it tells the TAE whether the billing trajectory in Vitally is *understating* the real growth potential.

The mapping logic:
- **More customers on their platform** → more end-user sessions → more events, replays, and flag evaluations
- **New product launches** → new surfaces to instrument → broader PostHog product adoption (analytics + replay + flags)
- **Engineering team growth** → more features shipped → more things tracked → higher event volume
- **GTM team growth** → more internal PostHog users → more dashboards and insights consumed
- **Platform/marketplace plays** → multiplicative event growth (each participant generates events)
- **Geographic expansion** → new user cohorts → step-function increases in volume

**Rate the business growth trajectory:**

| Rating | Criteria |
|--------|----------|
| 🔥 **Strong accelerating** | 2+ of: recent fundraise, 50%+ revenue growth, 3+ product launches, rapid hiring, expanding into new markets. PostHog billing likely *understates* real trajectory. |
| 📈 **Steady upward** | Consistent hiring, stable funding, 1-2 new products, growing customer base. PostHog billing trajectory is probably accurate. |
| ➡️ **Flat/stable** | No recent funding, minimal hiring, no new products. PostHog billing is what you see. |
| 📉 **Contracting** | Layoffs, funding concerns, product sunsetting. PostHog spend may *decline*. |

---

## Step 6: Recommend a Play & Draft Outreach

Based on all five research workstreams, recommend one of these plays:

### Play: Outreach (Slack Channel + Email)

Recommend when:
- Score >= 60 (High or Moderate confidence)
- 2+ active users in the account
- No one from PostHog is already actively engaged with this account

Draft an email AND a Slack channel welcome message. See Step 7 for drafting guidance.

### Play: Light Touch (Email Only, No Slack Channel)

Recommend when:
- Score 40-59 (Low confidence) but the account has interesting signals worth exploring
- Single active user but spend is meaningful (>= $1K/month)
- The account already has a relationship with PostHog (e.g. engaged with onboarding team)

Draft a short email only. No Slack channel.

### Play: Skip / Close as Not Qualified

Recommend when:
- Score 0-39 (Unlikely)
- Non-ICP industry with no offsetting signals
- Usage declining with no business growth to suggest recovery
- Account shows churn risk (past due billing, declining spend)
- Customer explicitly declined engagement (said "no thanks" or similar) - unless their spend is high enough that hearing about discounts from a TAE would be genuinely useful to them

**When recommending Skip, you MUST provide a DQ Reason** - a plain-text summary of why this lead is not qualified. The DQ reason must be 250 characters or fewer so the TAE can copy-paste it directly into the Salesforce disqualification field. Be specific - name the concrete signals, not generic language.

**Important: Non-response is NOT a disqualification signal.** If the onboarding team reached out and the customer simply didn't reply, that is not evidence they don't want to hear from PostHog - they may have been busy, missed the email, or the timing wasn't right. Do not cite "no engagement" or "didn't respond to onboarding" as a DQ reason. The only engagement-related DQ signal is an *explicit* opt-out - the customer actively responded to say they're not interested. Even then, if their spend is meaningful and a TAE could offer genuine value (e.g. volume discounts, billing optimization), an explicit opt-out from onboarding doesn't necessarily mean they'd reject a TAE with a different angle.

Good DQ reasons:
- "MRR declining $1,763->$696 forecast. Single product (analytics). 8 employees, 3 engineers. No growth signals despite $9.1M revenue. Group Analytics likely unnecessary."
- "Non-ICP: school bus routing company (founded 1977). Analytics-only, $1,369 flat MRR. 4.78 health. No expansion signals. Govt/education customer base."
- "Past due billing. MRR forecast drops 49% ($2,130->$1,086). 7-person seed startup. Likely cash-constrained despite Khosla backing."
- "Explicitly declined onboarding engagement. $380 MRR, single product, no growth trajectory. No value angle for TAE outreach."

Bad DQ reasons:
- "Not a good fit" (too vague)
- "Low score" (doesn't explain why)
- "Small company" (which signal matters?)
- "No engagement with onboarding" (non-response is not a signal - they may have been busy)
- "Unresponsive" (same problem - silence is not rejection)

### Play: Wait and Watch

Recommend when:
- Early-stage company with high variance - could go either way
- Score 40-59 with strong business growth signals but weak current billing
- Check back in 4-6 weeks to reassess

---

## Step 7: Draft the Outreach

When the recommended play is Outreach or Light Touch, draft the email using the guidance below. Read `references/writing-style.md` before drafting.

### Email Format

All draft emails must use this blockquoted format for easy copy-paste:

```
> **To:** [full email address - e.g. contact@acmecorp.com]
> **Subject:** [subject line]
>
> [email body]
>
> [TAE's name]
```

When the play is Outreach (Slack Channel + Email), also draft a Slack channel welcome message in the same blockquoted format after the email.

### Outreach Principles

These are the same principles used across all PostHog lead skills. Follow them exactly.

1. **Lead with the Slack channel.** For multi-user accounts, the shared Slack channel is the most valuable thing you're offering - a direct line to someone technical at PostHog. Open with it. Explain why it's useful for *their* specific situation based on your research. Don't bury it.

2. **Write like a fellow engineer, not a salesperson.** These are competent developers. The TAEs are deeply technical. Write the way you'd message a colleague - direct, concise. No praise or cheerleading about their setup. "Your team's ramped up fast!" reads as patronizing to engineers who know exactly what they've done.

3. **Start with an observation about *them*, not about you.** The first real sentence should reference something specific from Vitally or your research - which products they're using, what their team is building, a specific usage pattern. Never open with "I'm [name], your PostHog contact."

4. **Keep it short.** The initial email should be 3-5 sentences. Slack channel + why it's useful + one specific observation or optimization + a question. Save the details for Slack.

5. **One question per email.** More than one question overwhelms and reduces response rate. Pick the most interesting one.

6. **Be direct about billing when relevant.** Unlike big fish outreach, onboarding handoff leads already have meaningful spend. It's OK to reference costs - pair every cost mention with an actionable way to reduce it.

7. **Only reference what you can verify.** Safe: Vitally usage data, public website, confirmed funding rounds. Never cite enrichment data (Clearbit/Harmonic tech stack fields) as fact. If you state something about their setup and it's wrong, you lose credibility.

### Writing Style Rules

Follow `references/writing-style.md` for the full guide. Key rules:

- **Get to the point.** No "I'm reaching out because...", "I just wanted to...", "Saw you just signed up."
- **American English.** Oxford comma. Straight quotes.
- **Hyphens only** (-) for breaks in thought. Never em dashes or en dashes. Em/en dashes read as AI-generated.
- **Links in anchor text.** Never bare URLs. Never "click here." Always describe the destination: "here's a [guide on connecting replay to funnels](url)."
- **Capitalize product names.** "Session Replay", "Feature Flags", "Product Analytics."
- **Abbreviate numbers.** 10M, 100B (capital letter, no space).
- **No emojis in emails.**

### Anti-Patterns (Never Do These)

- **"I'm [name], your dedicated PostHog contact"** - your name is in the signature.
- **"Saw you just signed up"** / **"Just checking in"** - they know. This adds nothing.
- **"I'm here if you need anything"** - too passive. Say something specific or don't say it.
- **"Your team's ramped up fast!"** / **"That's impressive adoption"** - patronizing. State facts.
- **Feature laundry lists** - reference the 1-2 products they're actually using, not all of PostHog.
- **Multiple optimization suggestions in one email** - save it for Slack.
- **Bare URLs** - always embed in anchor text.
- **Citing enrichment data as fact** - "I noticed you're using [competitor]" from an unverified SFDC field.
- **Referencing exact event counts** - "you sent 4.2M events last month" feels surveillance-y. Reference products and patterns, not precise numbers.
- **More than one question per email.**

### Outreach Hook Guidance by Scenario

**Multi-user account, growing spend:**
Lead with the Slack channel. Ground it in their usage: "Setting up a shared Slack channel for you - with [N] people using [products] across [N] projects, a direct line for technical questions will save your team time." End with a question about what they're building or trying to learn.

**Multi-user account, flat or declining spend:**
Lead with a specific optimization. If you identified an issue (autocapture waste, stale flags, replay oversampling), that's the hook: "Noticed about [X]% of your events are autocapture without associated actions - [link to reducing event volume] covers how to trim that without losing anything useful." The Slack channel is where you help them act on it.

**Single user, meaningful spend:**
Short and direct. No Slack channel. One specific optimization with a link. "Quick heads-up - at your current usage, [specific optimization + link]. Happy to help if questions come up."

**Previously engaged with onboarding (had calls, completed onboarding):**
Reference the onboarding work. "Your team worked with the onboarding team on [what they covered] - wanted to make sure you have a direct line for questions now that you're past the initial setup." This creates continuity rather than feeling like a cold handoff.

**Never engaged with onboarding (unresponsive, skipped):**
Don't reference the onboarding team at all - they clearly didn't want that engagement. Lead with something useful: a specific optimization, a resource relevant to what they're building, or the Slack channel as a low-friction support resource.

### Example Outreach Drafts

**Example 1: Multi-user, high-growth, engaged with onboarding**

> **To:** team@acmecorp.com
> **Subject:** Slack channel for Acme <> PostHog
>
> Hey Acme team,
>
> Setting up a shared Slack channel for you - with 57 people in the account across analytics, replay, and error tracking, a direct line for questions will be useful as you scale.
>
> One thing that might be worth exploring: Feature Flags for safe rollouts. With your new product line launching as a platform, gradual rollouts and instant kill switches are the kind of thing that keeps deploys boring. Happy to walk through the setup in Slack.
>
> What's the main thing your team is trying to learn from the analytics right now?
>
> [TAE name]

**Example 2: Multi-user, flat spend, optimization hook**

> **To:** eng@example-payments.com
> **Subject:** Slack channel for Example Payments <> PostHog
>
> Hey Example Payments team,
>
> Sending over a Slack channel invite - with 42 people using analytics, flags, and replay, it'll be the fastest way to get answers on implementation or billing as things come up.
>
> One quick win: if your team is running A/B tests on checkout flows, [Experiments](https://posthog.com/docs/experiments) layers directly on top of your existing Feature Flags setup. For a payments product, measuring conversion impact per variant is where the real signal is.
>
> What's the team trying to optimize right now?
>
> [TAE name]

**Example 3: Single user, growing spend, never engaged**

> **To:** dev@example-ai.com
> **Subject:** Your PostHog setup
>
> Hey,
>
> Noticed you're using LLM Analytics alongside product analytics - that's a sharp setup for monitoring AI-generated content quality alongside user behavior.
>
> If you're tracking prompt-to-output quality, [this guide on LLM observability](https://posthog.com/docs/ai-engineering/observability) covers how to connect traces to user outcomes so you can see which prompts actually help students learn vs. just generate text.
>
> Happy to help if questions come up.
>
> [TAE name]

---

## Output Format

Present the research brief as a structured report with clear sections. Use the Visualizer for the growth trajectory chart if the data supports it.

```markdown
## [Company Name] - Onboarding Lead Research Brief

### Quick Links
- **Vitally:** [https://posthog.vitally-eu.io/customers/{organization_id}](https://posthog.vitally-eu.io/customers/{organization_id})
- **Salesforce:** [https://posthog.my.salesforce.com/{sfdc.Id}](https://posthog.my.salesforce.com/{sfdc.Id})
- **Usage Dashboard:** [{usage_dashboard_link}]({usage_dashboard_link}) *(or "Not available" if trait is blank)*

### Company Overview
- **What they do:** [one sentence]
- **Industry:** [vertical]
- **Size:** [employees] ([engineering count] engineers)
- **Funding:** [stage], [amount] ([date])
- **HQ:** [location]
- **Growth trajectory:** [Accelerating / Steady / Flat / Early stage]

### $2K+ Spend Likelihood
**Score: [X]/100 - [High / Moderate / Low / Unlikely]**

Key factors:
- [Factor]: [+/- impact]
- [Factor]: [+/- impact]
- [Factor]: [+/- impact]

Projection: Currently at $[X]/month - projected $[X]/month in 3 months

### Vitally Usage & Billing
- **Current MRR:** $[X]
- **Products in use:** [list]
- **Products NOT in use:** [list - these are expansion opportunities]
- **Event volume:** [current] ([trend])
- **Active users:** [count] ([trend])
- **Health score:** [X]/10

**Billing trajectory:**
[Chart or description of the trend - is spend growing, flat, or declining?]

**Expansion opportunities:**
- [Product they're not using that fits their use case]
- [Volume tier they're approaching]
- [Config optimization that could increase value]

### Onboarding Team Context
**Engagement level:** [Engaged / Partially engaged / Unengaged]
**Onboarding rep:** [Name]

**What happened:**
[Narrative summary of the onboarding engagement - what was discussed, what was done, what's left open]

**Key quotes or insights from the customer:**
- [Any notable things the customer said or asked about]

**Open items / unfinished business:**
- [Anything the onboarding team started but didn't finish]
- [Any promises made to the customer]

### Business Growth Trajectory
**Rating:** [Strong accelerating / Steady upward / Flat/stable / Contracting]

**Key growth signals:**
- **Revenue:** [what's known about ARR growth, Inc. 5000 ranking, etc.]
- **Funding:** [recent round, amount, investors, what it's earmarked for]
- **Product velocity:** [new launches, features, platform plays in last 12 months]
- **Customer expansion:** [new segments, partnerships, geographic expansion]
- **Headcount:** [total delta, eng delta, GTM hiring signals]
- **Web/brand momentum:** [traffic trends, LinkedIn growth, awards/recognition]

**How this maps to PostHog spend:**
[Explicit analysis connecting each business growth vector to expected PostHog usage growth. e.g. "More customers on their platform - more end-user sessions - event volume will grow faster than current billing suggests." This is the most actionable part - it tells the TAE whether the Vitally billing trajectory understates or accurately reflects the real growth potential.]

**Score adjustment:** [If the business growth signals are strong enough to warrant adjusting the $2K+ likelihood score from Step 2, note the adjustment and reasoning here. e.g. "Business growth trajectory bumps the score from 72 to ~80 - billing data lags customer growth."]

### Recommended Play
**[Outreach / Light Touch / Skip / Wait and Watch]**

[Reasoning for the recommendation - 1-2 sentences.]

[If Skip: include DQ Reason below]

**DQ Reason (for Salesforce):**
`[250 characters or fewer - specific, concrete, copy-pasteable]`

### Draft Outreach

[If the play is Outreach or Light Touch, include the draft email in blockquoted format. If Outreach with Slack channel, also include the Slack welcome message.]

> **To:** [full email address]
> **Subject:** [subject line]
>
> [email body]
>
> [TAE name]

[If multi-user Outreach, also include:]

**Slack channel welcome message:**

> [Slack message body]
>
> [TAE name]

**Suggested angle:** [One sentence explaining why this hook was chosen and what it's designed to accomplish.]
```

### When Processing Multiple Leads

After completing all individual research briefs, output a **Summary & Priority Stack Rank** table at the top of the combined output (or as a final summary section). Rank accounts by score descending.

```markdown
## Summary & Priority Stack Rank

| Rank | Account | Score | Tier | MRR | Trend | Action |
|------|---------|-------|------|-----|-------|--------|
| 1 | [Company] | [X]/100 | High confidence | $[X] | Growing | Outreach |
| 2 | [Company] | [X]/100 | Moderate confidence | $[X] | Flat | Light Touch |
| 3 | [Company] | [X]/100 | Unlikely | $[X] | Declining | Skip |
```

**Column guidance:**
- **Score:** The final $2K+ likelihood score (0-100) with the adjusted figure if business trajectory warranted an adjustment
- **Tier:** High confidence (80-100) / Moderate confidence (60-79) / Low confidence (40-59) / Unlikely (0-39)
- **MRR:** Current MRR from Vitally billing data
- **Trend:** Growing / Flat / Declining - based on billing trajectory, not just business signals
- **Action:** Outreach / Light Touch / Skip / Wait and Watch

---

## Reference Files

- `references/scoring-model.md` - Full $2K+ spend likelihood scoring model with weights and criteria
- `references/writing-style.md` - PostHog writing style guidelines for email drafting

## Critical Reminders

1. **Research first, then draft.** Complete all five research workstreams before recommending a play or drafting outreach. The research informs the outreach hook - without it, the email will be generic.
2. **Vitally data is the source of truth for usage and billing.** Don't guess at usage - pull it.
3. **Read every onboarding note.** The onboarding team's context is gold. Skipping it means the TAE walks into the conversation blind.
4. **Project the trajectory.** The TAE doesn't just need to know where the account is - they need to know where it's going.
5. **Flag discrepancies.** If the web research and Vitally data tell different stories (e.g. company seems to be growing but PostHog usage is flat), call that out explicitly. This is especially important in Step 5 - if the business is accelerating but PostHog billing is flat, the billing is lagging and there's upside.
6. **If Vitally data is thin, say so.** Don't invent data. If there are only 2 notes and no conversations, report that - it's useful context in itself (means the customer may not have engaged much).
7. **Business growth is the leading indicator; billing is the lagging one.** The Step 5 business growth trajectory analysis is what differentiates a good research brief from just reading Vitally numbers. A company that just raised $43M and doubled ARR is going to grow their PostHog spend - even if the current billing doesn't show it yet. Conversely, a company with declining headcount and no recent funding may be at peak spend already. Always connect the business trajectory to the expected PostHog spend trajectory.
8. **Use Harmonic data from Vitally traits.** The SFDC/Harmonic fields in the account traits contain headcount deltas, web traffic trends, LinkedIn growth, and funding details. Cross-reference these with your web research - they often tell a richer story than the web alone.
9. **Industry context matters for the growth mapping.** How a company grows affects *how* PostHog usage grows. A platform/marketplace company gets multiplicative event growth per customer. A SaaS company gets linear growth per customer. An infrastructure company may generate heavy backend events but few replays. Map the business model to the right PostHog products.
10. **DQ reasons must be copy-pasteable.** When recommending Skip, the DQ reason goes directly into Salesforce. Keep it under 250 characters, make it specific, and include the key data points that justify the disqualification.
11. **Draft outreach follows the writing style guide.** Read `references/writing-style.md`. Hyphens only (never em/en dashes). No bare URLs. No feature laundry lists. One question per email. Lead with the Slack channel for multi-user accounts.
12. **Use full email addresses.** When listing contacts or drafting outreach, always use the full email address (e.g. contact@acmecorp.com) for easy copy-paste.
13. **Validate all URLs before presenting the draft.** Fetch every link in the email to confirm it resolves. If broken, search for the correct page or remove the link.
