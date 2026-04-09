---
name: posthog-inbound-leads
description: Evaluate and respond to inbound PostHog sales leads from Salesforce. Use this skill when any PostHog TAE needs to triage an inbound lead — deciding whether to qualify for a call, route to self-serve, or disqualify — and then draft an appropriate response email. Checks Vitally for existing account context before qualifying. Triggers on "respond to this lead", "triage this inbound", "write a response to this lead", "disposition this lead", "evaluate this Salesforce lead", or any request involving an inbound sales inquiry that needs qualification and a reply. Also trigger when a TAE pastes or describes lead details and asks what to do with them.
---

# PostHog Inbound Lead Disposition

Evaluate inbound leads from Salesforce and either draft a response email or recommend a disposition. This skill is for any PostHog TAE handling inbound sales inquiries.

## Core Workflow

1. **Ingest lead context** — Read whatever the TAE provides (Salesforce fields, email body, notes)
2. **Check Vitally for existing account context** — Search for the lead's email and email domain (see Step 0 below)
3. **Research the company** — Web search to understand who they are, their funding, size, and growth trajectory (see Step 1 below)
4. **Identify the use case** — Map the lead to one or more of PostHog's six use cases, informed by company research (see Step 2 below)
5. **Qualify the lead** — Apply the disposition framework, informed by company research and growth trajectory (see Step 3 below)
6. **Recommend a disposition** — State the recommended action and identified use case(s) clearly
7. **Draft a response** — Write the appropriate email, framed around their use case (see Step 4 below)
8. **Validate all URLs** — Fetch every link in the draft email to confirm it resolves and points to the intended content (see Step 5 below)

## Step 0: Check Vitally for Existing Account Context

Before qualifying or drafting anything, check Vitally to see if this lead (or their company) is already a PostHog user. This changes the disposition and email framing significantly — an existing customer asking for help is different from a cold inbound.

### What to check

Run two Vitally lookups using the lead's email address:

1. **Search by exact email** — `vitally:search_users` with `email` set to the lead's email address. This tells you if this specific person already has a PostHog account.
2. **Search by email domain** — `vitally:search_users` with `emailSubdomain` set to the domain portion of the lead's email (e.g., `acme.com` from `jane@acme.com`). This tells you if anyone at their company is already using PostHog.

If either search returns results, pull up the associated account with `vitally:get_account_full` using the `accountId` from the user record(s). Use `detailLevel: "summary"` for a quick overview.

### How to use what you find

**Lead's email is an existing user:**
- They're already in PostHog. The email should acknowledge this ("I can see you're already using PostHog") and focus on their specific ask rather than onboarding-style resources.
- Check their account's MRR and health score — this informs whether they're a self-serve user reaching out to grow, or an existing account with an expansion opportunity.

**Different person at the same company is already a user:**
- Their company is already on PostHog. Reference this in the email ("I see your team is already using PostHog") and ask how their request relates to the existing usage.
- Check who else is on the account — the lead may need to connect with the internal champion rather than start a separate evaluation.
- If the account already has a TAE assigned, flag this to avoid stepping on someone's book of business.

**No results in Vitally:**
- Net new lead. Proceed with the standard qualification workflow below.

### What to surface to the TAE

When presenting the Vitally findings, include:
- Whether the person or company was found
- Account name and current MRR (if applicable)
- Health score (if applicable)
- Assigned TAE (if any — important for routing)
- Number of users on the account
- A one-line recommendation on how this changes the response (e.g., "Existing $3K/mo account, no TAE assigned — this is an expansion opportunity, not a new lead")

## Step 1: Research the Company

**This step is mandatory for every lead.** The lead's form submission alone is not enough information to qualify or disqualify. A 10K MAU lead from a $6B startup and a 10K MAU lead from a 5-person agency require completely different dispositions.

### What to research

Run 1-3 web searches to understand the company. Start with the company name and domain:

- `web_search` for `[Company Name] [domain]` — Get the basics: what they do, who they are
- `web_search` for `[Company Name] funding employees` — Get firmographics: funding stage, headcount, growth signals
- If the company appears to be notable or well-funded, search for recent news: `[Company Name] 2026` or `[Company Name] news`

### What to extract

From the research, identify and record:

| Signal | Why It Matters | Example |
|---|---|---|
| **What they build** | Determines use case mapping and whether they're ICP | "AI tools for manufacturing" → AI/LLM Obs is relevant |
| **Funding stage and amount** | Proxy for budget and growth trajectory | Series B, $50M → likely has budget for tooling |
| **Employee count** | Proxy for spend potential and team complexity | 200 employees → multiple teams, multi-project potential |
| **Engineering team size or ratio** | PostHog's buyer is engineers; more engineers = better fit | "80% of team is engineering" → strong ICP signal |
| **Growth trajectory** | Determines whether current MAU is the ceiling or the floor | Founded 6 months ago, hiring aggressively → MAU will grow fast |
| **Recent news** | Acquisitions, launches, pivots that change context | Just acquired an AI startup → expanding product surface |
| **Business model** | SaaS, marketplace, dev tools, agency, etc. | B2B SaaS → classic PostHog ICP |

### Classify the growth trajectory

Based on the research, classify the company into one of four growth trajectories:

- **Accelerating**: Recent large funding round (especially if raised in last 12 months), aggressive hiring, early-stage with significant capital, or clear signs of rapid expansion. Current MAU is almost certainly not the ceiling. Examples: well-funded Series A+ startups, companies that just raised mega-rounds, companies with "hundreds of open roles."
- **Steady**: Established company, moderate and predictable growth. Current MAU is a reasonable proxy for near-term spend. Examples: mid-market SaaS with stable revenue, mature PLG companies.
- **Early/unknown**: New company, limited public information, hard to assess trajectory. Treat current MAU as the best available signal but note the uncertainty. Examples: pre-seed startups, stealth-mode companies with no public footprint.
- **Flat/declining**: No growth signals, layoffs, or signs of contraction. Current MAU may overstate future spend. Examples: companies with recent layoffs, shrinking teams.

**The growth trajectory classification directly affects qualification.** See Step 3 for how it modifies the $20K threshold.

### Detect multi-product signals

While researching, watch for signals that the lead's company has (or is building) multiple products. This is a spend multiplier because each product typically becomes a separate PostHog project with its own event volume.

**Signals in the lead's message:**
- "some of our products" / "multiple products" / "across our portfolio"
- "several teams" / "multiple teams" / "different business units"
- "our platform and our apps" / "our web app and mobile app"
- "integrate into our stack" (implies breadth)

**Signals from company research:**
- Company has multiple product lines or brands
- Company recently acquired other companies (each acquisition may have its own product)
- Job postings reference multiple product teams
- Company website shows multiple distinct products

When multi-product signals are present, note the estimated product count (or range) and factor it into the MAU multiplier. A company with 5 products at 10K MAU each is a 50K MAU opportunity, not a 10K one.

### Detect AI/ML company signals

If company research reveals the company is AI-native (building AI/ML products as their core business), flag AI/LLM Observability as a probable secondary use case even if the lead's message doesn't mention AI, LLMs, model costs, or prompts.

**AI-native signals:**
- Company description mentions AI, ML, LLM, or "artificial intelligence" as core to what they build
- Company is in an AI-adjacent industry (AI infrastructure, AI applications, AI research)
- Team is heavily ML/AI engineers
- Recent AI-related acquisitions or product launches

When detected, include AI/LLM Observability in the use case assessment and mention it in the email as a relevant capability, even if the lead didn't ask about it. Frame it as: "since you're building AI products, you might also find our LLM analytics useful for tracking model costs and performance."

### What to surface to the TAE

Present the company research as a brief profile including:
- What the company does (one sentence)
- Funding and valuation (if available)
- Employee count and engineering composition (if available)
- Growth trajectory classification
- Multi-product signals (if any)
- AI-native flag (if applicable)
- Any notable context (recent news, acquisitions, leadership)

This goes right after the Vitally findings and before the use case assessment.

## Step 2: Identify the Use Case

Every lead maps to one or more of PostHog's six use cases. Identifying the use case determines how to frame the response, what products to highlight, and what resources to link. Evaluate the **person/persona**, **company** (informed by your Step 1 research), and **message** to determine the match.

### The Six Use Cases

| Use Case | Job to Be Done | Core Buyer Persona | Key Signals in the Lead |
|---|---|---|---|
| **Product Intelligence** | "Help me understand what users do, why they do it, and what to build next." | PMs, designers, product engineers, founders | Mentions analytics, funnels, retention, user behavior, "why users drop off", feature adoption, NPS, surveys, session replay for UX research |
| **Release Engineering** | "Help me ship faster without breaking things." | Engineering managers, platform teams, developers | Mentions feature flags, rollouts, A/B testing releases, kill switches, progressive delivery, replacing LaunchDarkly |
| **Observability** | "Help me know when things break, understand why, and fix them fast." | SREs, platform engineers, DevOps | Mentions error tracking, bug reproduction, replacing Sentry/Datadog, logging, incident response, stack traces |
| **Growth & Marketing** | "Help me understand what drives acquisition, conversion, and revenue." | Growth engineers, marketing leads, CRO, GTM engineers | Mentions attribution, ROAS, campaign performance, replacing GA4/Segment, conversion optimization, onboarding automation, marketing stack consolidation |
| **AI/LLM Observability** | "Help me understand how my AI features perform, what they cost, and how users interact with them." | AI/ML engineers, AI PMs, AI founders | Mentions LLM, AI features, model costs, prompt testing, AI quality, replacing Langfuse/Helicone, token usage. **Also inferred from company research** — if the company is AI-native, this use case is relevant even if the lead didn't mention it. |
| **Data Infrastructure** | "Help me unify product data with business data and get it where it needs to go." | Data engineers, analytics engineers, product ops | Mentions data warehouse, Snowflake/BigQuery, data pipelines, batch exports, combining PostHog data with Stripe/CRM, replacing Segment/Fivetran |

### Mapping Persona to Use Case

The **person's role** is one of the strongest signals:

- **PM, Head of Product, UX Researcher, Designer** → Product Intelligence
- **Engineering Manager, VP Eng, Platform Engineer, Developer** → Release Engineering (or Observability if they mention errors/incidents)
- **SRE, DevOps, Infrastructure Engineer** → Observability
- **Growth Engineer, Marketing Lead, CRO, GTM Engineer, Demand Gen** → Growth & Marketing
- **AI/ML Engineer, AI PM, AI Founder** → AI/LLM Observability
- **Data Engineer, Analytics Engineer, Head of Data, RevOps** → Data Infrastructure
- **Founder/CTO (early stage)** → Usually Product Intelligence or AI/LLM Obs depending on the product; may span multiple use cases

### Mapping Company to Use Case

The **company type** (from your Step 1 research) helps narrow it:

- **AI-native startup** → AI/LLM Observability is almost always relevant, often alongside Product Intelligence
- **PLG SaaS** → Product Intelligence + Growth & Marketing are the most common pair
- **Enterprise with multiple teams** → Often starts as one use case but the expansion potential spans several
- **E-commerce / marketplace** → Growth & Marketing (conversion, attribution) + Product Intelligence (user behavior)
- **Developer tools / infrastructure** → Release Engineering + Observability

### Mapping Message to Use Case

The **specific ask** confirms or overrides the persona/company signal:

- "We want to understand user behavior" → Product Intelligence
- "We need feature flags" or "replacing LaunchDarkly" → Release Engineering
- "We need error tracking" or "replacing Sentry" → Observability
- "We want attribution" or "replacing GA4" → Growth & Marketing
- "We're building AI features" or "LLM costs" → AI/LLM Observability
- "We need to get data into Snowflake" → Data Infrastructure
- Vague "show me features" / "want a demo" → Can't determine use case from the message alone; **use company research to infer the most likely use case(s)**, then ask a targeted clarifying question to confirm

**If the use case is ambiguous even after company research**, include a targeted clarifying question in the email to narrow it down. Frame the question around their problem, not PostHog products: "What's the main problem you're trying to solve?" is better than "Which PostHog product are you interested in?"

### Multiple Use Cases

Many leads map to more than one use case. When this happens:

- **Lead with the primary use case** — the one most closely matching their stated pain
- **Mention the secondary use case as a natural extension** — "PostHog also handles X, which tends to come up once teams are doing Y"
- **Don't try to sell the entire platform** — focus on solving the problem they came in with

## Step 3: Qualify the Lead

### Growth Trajectory Override

**The $20K annual spend threshold is the default qualification bar, but growth trajectory can override it.**

When all of the following are true, qualify for a call even if current MAU alone wouldn't hit $20K:

1. **Growth trajectory is "Accelerating"** — Recent large funding, aggressive hiring, early-stage with significant capital
2. **High-value company signals** — At least two of: $10M+ in funding, 50+ employees, engineering-heavy team, multi-product, AI-native
3. **Reasonable path to $20K within 12 months** — Based on growth trajectory and multi-product multiplier, it's plausible they'll reach the threshold as they scale

When the override applies, note it explicitly in the disposition: "Current MAU of 10K is below the $20K threshold, but growth trajectory is Accelerating ([$X funding, Y employees, etc.]) with multi-product potential. Qualifying for call based on trajectory."

**When the override does NOT apply:**
- Growth trajectory is Steady, Early/unknown, or Flat — stick to the $20K threshold based on current signals
- The company has funding but the lead's use case is narrow and unlikely to expand (e.g., a well-funded company asking about feature flags for one internal tool)
- The lead is from a large company but the team using PostHog would be tiny with no expansion path

### Multi-Product Spend Multiplier

When multi-product signals are detected (from the lead's message or company research), adjust the MAU estimate:

- **Stated MAU × estimated product count = adjusted MAU estimate**
- Use the adjusted estimate for qualification, not the raw stated MAU
- Note the multiplier in the disposition: "10K MAU stated, but 'some of our products' + company research suggests 3-5 products → 30-50K adjusted MAU"

This multiplier is an estimate, not a guarantee. It shifts the disposition from "definitely below threshold" to "plausibly above threshold, worth a call to confirm."

### Special Case: Competitor Displacement

When a lead mentions they're currently using a competitor and looking to switch (e.g., "using Heap looking to move", "replacing Amplitude", "evaluating alternatives to Sentry", "moving off LaunchDarkly"), this is a high-signal inbound. They already have budget allocated to a tool in the category, they have a defined need, and they likely have some urgency.

**However, the $20K floor still applies (unless the growth trajectory override kicks in).** A competitor displacement lead still needs to show potential for $20K+ annual spend to qualify for a call. Don't offer a call just because they're switching from a paid tool.

**For competitor displacement leads, the initial response should surface BANT signals** before offering a call or routing to self-serve. Ask targeted discovery questions that uncover:

- **Budget:** What's driving the switch? Cost, missing features, data ownership, or something else? (If cost, that implies existing budget.)
- **Authority:** Who's involved in the decision? Is this an engineering-led eval or a top-down mandate?
- **Need:** What are you hoping PostHog solves that [competitor] doesn't? Are you looking to replace just [product], or are you interested in consolidating with additional capabilities (replay, flags, experiments, etc.)?
- **Timeline:** How soon are you looking to make a decision? (Don't ask this in the first email — let it emerge naturally or ask in a follow-up.)

**You don't need all four BANT signals in the first email.** Ask 1–2 questions that surface the most important unknowns — typically Budget (why are you switching?) and Need (what do you want beyond what you have?). Let Authority and Timeline emerge in the reply.

**After the lead replies with BANT context:**
- If the answers confirm $20K+ potential and a real use case → Qualify for call, and offer your calendar
- If the answers reveal a small team / low spend / simple replacement → Route to self-serve with specific migration resources
- If the lead asks for a call before you have BANT context → It's OK to offer the calendar, but also point out that everything needed to evaluate PostHog is publicly available (pricing, docs, free signup), so they can start evaluating in parallel

### Special Case: Vague Request from a High-Value Company

When the lead's message is vague (e.g., "want to start a review process", "looking to learn more", "interested in PostHog") BUT company research reveals a high-value account, **do not default to self-serve routing.**

Instead, treat vague requests from high-value companies as "needs discovery" rather than "not serious enough for a call." The disposition should be "qualify for call with discovery questions."

**High-value company indicators** (any two or more qualifies):
- $10M+ in total funding
- 100+ employees
- Engineering team >40% of headcount
- Multi-product signals
- AI-native company
- Growth trajectory classified as "Accelerating"
- Well-known brand or notable founders/leadership

The email for these leads should:
- Acknowledge their interest without making assumptions about the use case
- Ask 1-2 discovery questions to understand what they're trying to solve
- Mention 1-2 PostHog capabilities most relevant to their company type (informed by research)
- Offer a call to walk through how PostHog fits their stack

### Disposition: Qualify for Call

All of these should be true:
- Annual spend potential ≥ $20K (based on current MAU, OR adjusted MAU with multi-product multiplier, OR growth trajectory override)
- Engineers are involved or will be on the call
- Specific, defined use case (mapped to at least one of the six above) — OR vague request from a high-value company (see special case above)
- Company size and product needs justify sales-assisted motion

If qualified, draft a response that:
- Acknowledges their specific use case (or, for vague requests from high-value companies, their company context and likely use cases)
- Asks 1–2 targeted discovery questions from the relevant use case playbook
- Offers to schedule a call

### Disposition: Route to Self-Serve

Any of these are true:
- Spend potential clearly below $20K based on company size, research, AND growth trajectory does not justify the override
- Low volume explicitly stated (e.g., "1,000 MAU", "small team", "just getting started") AND company research confirms this is the ceiling (small company, flat trajectory)
- Vague request with no specific use case AND company research does not reveal a high-value account
- No engineer involvement mentioned or expected
- Generic "learn more" or "get a demo" with no substance behind it AND company research doesn't change the picture

Draft a helpful email that:
- Answers their question with use-case-specific resources
- Provides links to the most relevant product docs for their identified use case
- Directs them to self-serve channels (in-app support, community)
- Does NOT offer a call

### Disposition: Route to Startup Plan

- Company is early-stage and potentially eligible for the startup plan
- Direct them to the [startup plan application](https://posthog.com/startups)
- Disqualify as an immediate sales opportunity

### Disposition: Disqualify

- Clearly not ICP (wrong industry vertical, no product-engineering use case)
- Spam or irrelevant inquiry
- No response needed, or a brief polite decline

### Disqualification Reasons & Notes

When recommending any disposition other than "Qualify for Call," you MUST provide a **disqualification reason** (from the list below) and **disqualification notes** (250 characters or fewer, specific and copy-pasteable into the Salesforce disqualification notes field).

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

**How to choose the right reason:**

- **Below Sales Assist Threshold - Pass**: Below $20K potential, no growth trajectory override, and no realistic growth path to get there. Use for small companies routed to self-serve.
- **Below Sales Assist Threshold - Prospect**: Below $20K now but company shows signals it could grow into threshold (e.g. recent funding, growing team). Worth revisiting later. Use when the growth trajectory is promising but doesn't meet the override criteria yet.
- **BAA / DPA Request**: Lead requires a BAA or DPA. Note: BAAs are available starting at the Boost add-on ($250/month + usage-based pricing) for standard (no redlines) BAAs, or Enterprise ($2K/month paid annually) for custom/redlined BAAs. Use this reason when the lead's primary need is HIPAA/BAA and they've been given the relevant pricing info.
- **No Technical Resource**: The contact is non-technical and no engineer is mentioned or expected to be involved.
- **Startup Plan / YC**: Early-stage company routed to the startup plan application.
- **Support Request**: They're asking a support question, not evaluating PostHog for purchase.
- **Existing customer inquiry**: Already a PostHog customer with a product/billing question - not a new sales opportunity.
- **No Product Fit**: What they need isn't something PostHog does well (e.g. self-hosted requirement, industry mismatch).

**Disqualification notes must be specific and copy-pasteable.** Include the key data points that justify the disqualification, including relevant findings from company research.

Good DQ notes:
- "30-employee e-commerce agency, $1M-$10M revenue. Marketing role, no engineer. 250K MAUs on free tier. Feature flag question answered, routed to self-serve."
- "Bay Area nonprofit, 20K MAUs, ICP -5. Sr Dir Product, strong use case but well below $20K threshold. BAA available via Boost ($250/mo). Routed to self-serve with HIPAA + funnel guidance."
- "15-person seed startup. Developer asking about feature flags. Free tier covers their needs. Pointed to docs + in-app support."
- "5-person pre-revenue startup, no funding found. 2K MAU. Vague 'want to learn more.' Routed to self-serve, suggested startup plan application."

Bad DQ notes:
- "Not a good fit" (too vague)
- "Small company" (which signal matters?)
- "Routed to self-serve" (why?)
- "Low MAU" (did you check if the company is actually small, or is the product just early?)

## Step 4: Write the Response Email

Read `references/writing-style.md` before drafting. Key rules:

- **Get to the point.** No long intros, no fluff, no corporate jargon.
- **Be helpful, not sales-y.** Solve their problem with specific guidance.
- **Be opinionated.** Don't hedge with "it depends" — recommend a path.
- **Frame around their use case, not PostHog products.** Talk about solving their problem, not about product names.
- **Use company research to personalize.** If you know what they build, reference it. "Since you're building AI tools for manufacturing" is better than "Since you're evaluating analytics."
- **Embed links in anchor text.** Never paste bare URLs or use "click here."
- **Minimal formatting.** Use bullet points only when listing resources or steps. Keep it conversational.
- **One question max** per email to avoid overwhelming the recipient.

### Email Structure

1. Brief, friendly greeting
2. Acknowledge their specific situation and use case (informed by company research)
3. Provide the answer, guidance, or resources mapped to their use case
4. Clear next step (self-serve action, schedule link, or "reply if you have questions")
5. Simple sign-off

## Step 5: Validate All URLs

**This step is mandatory.** Before presenting the draft email, fetch every URL included in the email using `web_fetch` to verify:

1. **The URL resolves** — It returns a 200 status, not a 404 or redirect to a generic page
2. **The content matches the intent** — The page actually covers what you're linking it for (e.g., a link labeled "Feature Flags getting started" should land on the Feature Flags getting started page, not a generic docs index)

**If a URL fails validation:**
- Search posthog.com for the correct page using `web_search` (e.g., "posthog docs feature flags getting started")
- Replace the broken link with the correct one
- If no valid page exists for that resource, remove the link rather than send a broken one

**Why this matters:** PostHog's docs structure changes. URLs from the resource list below are a starting point, but they may have moved. A broken link in a sales email undermines credibility. Always verify before sending.

## Use-Case-Specific Resources to Link

### Product Intelligence
- [Product analytics docs](https://posthog.com/docs/product-analytics)
- [Funnels](https://posthog.com/docs/product-analytics/funnels)
- [Session Replay](https://posthog.com/docs/session-replay)
- [Surveys](https://posthog.com/docs/surveys/creating-surveys)
- [Experiments](https://posthog.com/docs/experiments)

### Release Engineering
- [Feature Flags getting started](https://posthog.com/docs/feature-flags/start-here)
- [Experiments](https://posthog.com/docs/experiments)
- [Session Replay](https://posthog.com/docs/session-replay) (for debugging rollouts)

### Observability
- [Error Tracking](https://posthog.com/docs/error-tracking)
- [Session Replay](https://posthog.com/docs/session-replay) (for error context)

### Growth & Marketing
- [Web Analytics](https://posthog.com/docs/web-analytics/getting-started)
- [Marketing Analytics](https://posthog.com/docs/web-analytics/marketing-analytics)
- [Data Pipelines](https://posthog.com/docs/cdp)
- [Workflows](https://posthog.com/docs/workflows/start-here)

### AI/LLM Observability
- [AI Engineering / LLM Observability](https://posthog.com/docs/ai-engineering)
- [Experiments](https://posthog.com/docs/experiments) (for prompt/model testing)

### Data Infrastructure
- [Data Warehouse](https://posthog.com/docs/data-warehouse)
- [Batch Exports](https://posthog.com/docs/cdp/batch-exports)
- [Realtime Destinations](https://posthog.com/docs/cdp/destinations)

### General (all use cases)
- [Installation guide](https://posthog.com/docs/getting-started/install)
- [Pricing page](https://posthog.com/pricing)
- [Community questions](https://posthog.com/questions)
- [HIPAA compliance guide](https://posthog.com/docs/privacy/hipaa-compliance)
- [BAA generator](https://posthog.com/baa)
- In-app support button (always mention for product questions)
- Free tier: 1M events/month, all core features included

## BAA / HIPAA Pricing Reference

When a lead mentions HIPAA, BAA, or healthcare data, use this pricing info:

**Standard BAA (no redlines):**
- Available on the **Boost add-on** at **$250/month** + usage-based pricing
- Also available on Scale and Enterprise add-ons
- The BAA can be generated at posthog.com/baa for PostHog to countersign

**Custom/redlined BAA:**
- Requires the **Enterprise plan** at **$2K/month** (paid annually) + usage-based pricing
- Only needed if the customer wants to modify the standard BAA terms

**Key framing:** Lead with Boost as the standard path. $250/month is accessible for most organizations, including nonprofits and smaller companies. Don't default to "enterprise pricing" - that scares off leads who could easily afford Boost.

**Practical note for leads with mixed PHI/non-PHI data:** If only some of their funnels or data flows touch PHI, they can start tracking non-PHI activity on the free tier immediately while sorting out the BAA for the PHI-touching portions.

## Non-Profit Discount Reference

PostHog offers non-profit discounts on credit purchases:

- **Credit purchases below $25K:** 15% discount
- **Credit purchases $25K-$100K:** additional 5% on top of standard volume discount
- **Credit purchases above $100K:** standard volume discounts apply (no additional non-profit discount)

To qualify, the customer needs to provide proof they fit their country's definition of a non-profit entity (tax law in country of origin).

**Note:** At low MAU volumes where usage stays within the free tier, the non-profit discount won't matter yet - their main cost would be the platform add-on (e.g. Boost for BAA). Mention the discount so they know it exists for when they grow into it.

## Output Format

When responding to the TAE, always provide:

1. **Vitally findings** — Whether the lead or their company was found in Vitally, and what that means
2. **Company research** — Brief profile from web research: what they do, funding, headcount, growth trajectory, multi-product signals, AI-native flag
3. **Use case assessment** — Which of the six use cases this lead maps to, and why (based on persona, company research, and message)
4. **Disposition recommendation** — Qualify / Self-serve / Startup plan / Disqualify
5. **Disqualification reason** — From the available list (required for all dispositions except Qualify for Call)
6. **Disqualification notes** — 250 characters or fewer, specific and copy-pasteable (required for all dispositions except Qualify for Call)
7. **Draft email** — The response to send, framed around the identified use case and informed by company research

## Reference Files

Read these before drafting responses:
- `references/email-examples.md` — Example emails for common inbound scenarios
- `references/sales-context.md` — Sales process, thresholds, qualification criteria
- `references/writing-style.md` — PostHog tone, formatting, and style rules

## Critical Reminders

1. **Always check Vitally first** — Search for the lead's email and email domain before doing anything else. An existing customer changes everything about the response.
2. **Always research the company** — Never qualify or disqualify based solely on stated MAU and the lead's message. A 5-minute web search can turn a "pass" into a whale.
3. **Growth trajectory can override the $20K threshold** — An accelerating company with strong signals should be qualified even if current MAU is low. Document the override reasoning.
4. **Multi-product signals are spend multipliers** — "Some of our products" means the stated MAU is a floor, not a ceiling. Adjust your estimate.
5. **AI-native companies get AI/LLM Obs as a secondary use case** — Even if they didn't mention it. It's almost always relevant.
6. **Vague requests from high-value companies need discovery, not self-serve** — Don't punt a $6B startup to the docs because they didn't write a detailed form submission.
7. **$20K threshold is firm for non-override cases** — Do not offer calls below this for companies with steady/flat trajectories and no high-value signals.
8. **Always identify the use case** — This is the foundation for everything: the disposition, the framing, and the resources you link.
9. **Always recommend a disposition** — Don't just write an email; state the qualification decision explicitly so the TAE can update Salesforce.
10. **Always mention in-app support** for product questions — it's the fastest path to help.
11. **PostHog is built for product engineers** — If no engineer is involved, that's a red flag for qualification.
12. **Frame around problems, not products** — "Here's how to understand why users drop off" not "Here's our Product Analytics feature."
13. **Use company research to personalize the email** — Reference what they build, not just what they asked. It shows you did your homework.
14. **Match specificity to specificity** — Vague inbound gets pointed to resources with a clarifying question; specific technical questions get specific answers tied to their use case.
15. **Always validate URLs before presenting the draft** — Fetch every link to confirm it resolves and points to the right content. Never send a broken link.
16. **Always provide a DQ reason and DQ notes** — For every disposition except Qualify for Call, include the disqualification reason from the available list and copy-pasteable notes (250 chars or fewer). Be specific — name concrete signals from both the lead's message AND your company research.
