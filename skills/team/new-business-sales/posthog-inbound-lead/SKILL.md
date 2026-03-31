---
name: posthog-inbound-leads
description: Evaluate and respond to inbound PostHog sales leads from Salesforce. Use this skill when any PostHog TAE needs to triage an inbound lead — deciding whether to qualify for a call, route to self-serve, or disqualify — and then draft an appropriate response email. Checks Vitally for existing account context before qualifying. Triggers on "respond to this lead", "triage this inbound", "write a response to this lead", "disposition this lead", "evaluate this Salesforce lead", or any request involving an inbound sales inquiry that needs qualification and a reply. Also trigger when a TAE pastes or describes lead details and asks what to do with them.
---

# PostHog Inbound Lead Disposition

Evaluate inbound leads from Salesforce and either draft a response email or recommend a disposition. This skill is for any PostHog TAE handling inbound sales inquiries.

## Core Workflow

1. **Ingest lead context** — Read whatever the TAE provides (Salesforce fields, email body, notes)
2. **Check Vitally for existing account context** — Search for the lead's email and email domain (see Step 0 below)
3. **Identify the use case** — Map the lead to one or more of PostHog's six use cases (see below)
4. **Qualify the lead** — Apply the disposition framework
5. **Recommend a disposition** — State the recommended action and identified use case(s) clearly
6. **Draft a response** — Write the appropriate email, framed around their use case
7. **Validate all URLs** — Fetch every link in the draft email to confirm it resolves and points to the intended content (see Step 4 below)

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

## Step 1: Identify the Use Case

Every lead maps to one or more of PostHog's six use cases. Identifying the use case determines how to frame the response, what products to highlight, and what resources to link. Evaluate the **person/persona**, **company**, and **message** to determine the match.

### The Six Use Cases

| Use Case | Job to Be Done | Core Buyer Persona | Key Signals in the Lead |
|---|---|---|---|
| **Product Intelligence** | "Help me understand what users do, why they do it, and what to build next." | PMs, designers, product engineers, founders | Mentions analytics, funnels, retention, user behavior, "why users drop off", feature adoption, NPS, surveys, session replay for UX research |
| **Release Engineering** | "Help me ship faster without breaking things." | Engineering managers, platform teams, developers | Mentions feature flags, rollouts, A/B testing releases, kill switches, progressive delivery, replacing LaunchDarkly |
| **Observability** | "Help me know when things break, understand why, and fix them fast." | SREs, platform engineers, DevOps | Mentions error tracking, bug reproduction, replacing Sentry/Datadog, logging, incident response, stack traces |
| **Growth & Marketing** | "Help me understand what drives acquisition, conversion, and revenue." | Growth engineers, marketing leads, CRO, GTM engineers | Mentions attribution, ROAS, campaign performance, replacing GA4/Segment, conversion optimization, onboarding automation, marketing stack consolidation |
| **AI/LLM Observability** | "Help me understand how my AI features perform, what they cost, and how users interact with them." | AI/ML engineers, AI PMs, AI founders | Mentions LLM, AI features, model costs, prompt testing, AI quality, replacing Langfuse/Helicone, token usage |
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

The **company type** helps narrow it:

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
- Vague "show me features" / "want a demo" → Can't determine use case; ask a clarifying question

**If the use case is ambiguous**, include a targeted clarifying question in the email to narrow it down. Frame the question around their problem, not PostHog products: "What's the main problem you're trying to solve?" is better than "Which PostHog product are you interested in?"

### Multiple Use Cases

Many leads map to more than one use case. When this happens:

- **Lead with the primary use case** — the one most closely matching their stated pain
- **Mention the secondary use case as a natural extension** — "PostHog also handles X, which tends to come up once teams are doing Y"
- **Don't try to sell the entire platform** — focus on solving the problem they came in with

## Step 2: Qualify the Lead

### Special Case: Competitor Displacement

When a lead mentions they're currently using a competitor and looking to switch (e.g., "using Heap looking to move", "replacing Amplitude", "evaluating alternatives to Sentry", "moving off LaunchDarkly"), this is a high-signal inbound. They already have budget allocated to a tool in the category, they have a defined need, and they likely have some urgency.

**However, the $20K floor still applies.** A competitor displacement lead still needs to show potential for $20K+ annual spend to qualify for a call. Don't offer a call just because they're switching from a paid tool.

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

### Disposition: Qualify for Call

All of these should be true:
- Annual spend potential ≥ $20K
- Engineers are involved or will be on the call
- Specific, defined use case (mapped to at least one of the six above)
- Company size and product needs justify sales-assisted motion

If qualified, draft a response that:
- Acknowledges their specific use case
- Asks 1–2 targeted discovery questions from the relevant use case playbook
- Offers to schedule a call

### Disposition: Route to Self-Serve

Any of these are true:
- Spend potential clearly below $20K based on company size and what they describe
- Low volume explicitly stated (e.g., "1,000 MAU", "small team", "just getting started")
- Vague request with no specific use case ("show me all the features")
- No engineer involvement mentioned or expected
- Generic "learn more" or "get a demo" with no substance behind it

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

- **Below Sales Assist Threshold - Pass**: Below $20K potential and no realistic growth path to get there. Use for small companies routed to self-serve.
- **Below Sales Assist Threshold - Prospect**: Below $20K now but company shows signals it could grow into threshold (e.g. recent funding, growing team). Worth revisiting later.
- **BAA / DPA Request**: Lead requires a BAA or DPA. Note: BAAs are available starting at the Boost add-on ($250/month + usage-based pricing) for standard (no redlines) BAAs, or Enterprise ($2K/month paid annually) for custom/redlined BAAs. Use this reason when the lead's primary need is HIPAA/BAA and they've been given the relevant pricing info.
- **No Technical Resource**: The contact is non-technical and no engineer is mentioned or expected to be involved.
- **Startup Plan / YC**: Early-stage company routed to the startup plan application.
- **Support Request**: They're asking a support question, not evaluating PostHog for purchase.
- **Existing customer inquiry**: Already a PostHog customer with a product/billing question - not a new sales opportunity.
- **No Product Fit**: What they need isn't something PostHog does well (e.g. self-hosted requirement, industry mismatch).

**Disqualification notes must be specific and copy-pasteable.** Include the key data points that justify the disqualification.

Good DQ notes:
- "30-employee e-commerce agency, $1M-$10M revenue. Marketing role, no engineer. 250K MAUs on free tier. Feature flag question answered, routed to self-serve."
- "Bay Area nonprofit, 20K MAUs, ICP -5. Sr Dir Product, strong use case but well below $20K threshold. BAA available via Boost ($250/mo). Routed to self-serve with HIPAA + funnel guidance."
- "15-person seed startup. Developer asking about feature flags. Free tier covers their needs. Pointed to docs + in-app support."

Bad DQ notes:
- "Not a good fit" (too vague)
- "Small company" (which signal matters?)
- "Routed to self-serve" (why?)

## Step 3: Write the Response Email

Read `references/writing-style.md` before drafting. Key rules:

- **Get to the point.** No long intros, no fluff, no corporate jargon.
- **Be helpful, not sales-y.** Solve their problem with specific guidance.
- **Be opinionated.** Don't hedge with "it depends" — recommend a path.
- **Frame around their use case, not PostHog products.** Talk about solving their problem, not about product names.
- **Embed links in anchor text.** Never paste bare URLs or use "click here."
- **Minimal formatting.** Use bullet points only when listing resources or steps. Keep it conversational.
- **One question max** per email to avoid overwhelming the recipient.

### Email Structure

1. Brief, friendly greeting
2. Acknowledge their specific situation and use case
3. Provide the answer, guidance, or resources mapped to their use case
4. Clear next step (self-serve action, schedule link, or "reply if you have questions")
5. Simple sign-off

## Step 4: Validate All URLs

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

1. **Use case assessment** — Which of the six use cases this lead maps to, and why (based on persona, company, and message)
2. **Disposition recommendation** — Qualify / Self-serve / Startup plan / Disqualify
3. **Disqualification reason** — From the available list (required for all dispositions except Qualify for Call)
4. **Disqualification notes** — 250 characters or fewer, specific and copy-pasteable (required for all dispositions except Qualify for Call)
5. **Draft email** — The response to send, framed around the identified use case

## Reference Files

Read these before drafting responses:
- `references/email-examples.md` — Example emails for common inbound scenarios
- `references/sales-context.md` — Sales process, thresholds, qualification criteria
- `references/writing-style.md` — PostHog tone, formatting, and style rules

## Critical Reminders

1. **Always check Vitally first** — Search for the lead's email and email domain before doing anything else. An existing customer changes everything about the response.
2. **$20K threshold is firm** — Do not offer calls below this, regardless of how politely the lead asks
3. **Always identify the use case** — This is the foundation for everything: the disposition, the framing, and the resources you link
4. **Always recommend a disposition** — Don't just write an email; state the qualification decision explicitly so the TAE can update Salesforce
5. **Always mention in-app support** for product questions — it's the fastest path to help
6. **PostHog is built for product engineers** — If no engineer is involved, that's a red flag for qualification
7. **Frame around problems, not products** — "Here's how to understand why users drop off" not "Here's our Product Analytics feature"
8. **Match specificity to specificity** — Vague inbound gets pointed to resources with a clarifying question; specific technical questions get specific answers tied to their use case
9. **Always validate URLs before presenting the draft** — Fetch every link to confirm it resolves and points to the right content. Never send a broken link.
10. **Always provide a DQ reason and DQ notes** — For every disposition except Qualify for Call, include the disqualification reason from the available list and copy-pasteable notes (250 chars or fewer). Be specific - name concrete signals, not generic language.
