# Inbound Lead Response Examples

Each example shows the full output: use case assessment, disposition, and draft email.

---

## Example 1: Product Intelligence — Qualify for Call

**Lead context:** Senior PM at a Series C SaaS company (~200 employees). Currently using Amplitude. Message: "We're evaluating alternatives to Amplitude. Our product team needs better session replay alongside analytics, and we want to consolidate tools. We're spending about $50K/year on analytics today."

**Use case assessment:** Product Intelligence. PM buyer, mentions analytics + session replay + consolidation. Clear product team use case — understand user behavior and combine quantitative + qualitative.

**Disposition:** Qualify for call. $50K current spend indicates ≥$20K potential. Specific use case (Amplitude replacement + replay). PM likely has engineers involved for implementation.

**Draft email:**

```
Subject: Re: Evaluating PostHog as an Amplitude alternative

Hey [Name],

Good timing — replacing Amplitude with PostHog and getting session replay in the same platform is one of the most common moves we see from product teams your size. The big win is being able to click from a funnel drop-off straight into a replay of what actually happened.

Quick question before we talk: are you looking to migrate your existing Amplitude tracking, or would you start fresh with a new event schema?

If a call makes sense, [grab a time here](scheduling-link) and I'll come prepared with a migration plan.

Best,
[Your name]
```

---

## Example 2: Release Engineering — Route to Self-Serve

**Lead context:** Developer at a 15-person startup. Message: "We're looking for a feature flag tool. We want to do gradual rollouts. Right now we just deploy to everyone and hope for the best."

**Use case assessment:** Release Engineering. Developer buyer, mentions feature flags and gradual rollouts. Classic "ship faster without breaking things" job.

**Disposition:** Route to self-serve. 15-person startup is well below $20K threshold. Feature Flags free tier (1M requests/month) will cover them.

**Draft email:**

```
Subject: Re: Feature flags for gradual rollouts

Hey [Name],

PostHog Feature Flags are a good fit for this — you can gate features behind a flag, roll out to 5% of users, monitor, and expand or kill it instantly.

The free tier covers 1M flag requests/month, which at your size will go a long way. Here's the fastest path to get started:

* [Feature Flags getting started](https://posthog.com/docs/feature-flags/start-here) — SDK setup and first flag
* [Experiments](https://posthog.com/docs/experiments) — once you're rolling out behind flags, you can measure whether the change actually improved your metrics (experiments are included with flags)

If you hit any snags during setup, the in-app support button is the fastest way to get help.

Best,
[Your name]
```

---

## Example 3: AI/LLM Observability — Qualify for Call

**Lead context:** CTO at a Series B AI startup (~80 employees, $30M raised). Message: "We're building AI-powered document processing and need to track model costs, latency, and quality across different providers. Currently using Langfuse but want something that connects model metrics to user behavior."

**Use case assessment:** AI/LLM Observability (primary) + Product Intelligence (secondary). AI-native company, CTO buyer, mentions model costs/latency/quality + connecting to user behavior. The "connect model metrics to user behavior" signal points to the cross-use-case strength.

**Disposition:** Qualify for call. Series B with $30M raised, 80 employees, AI-native — clear $20K+ potential. Specific use case. Technical buyer.

**Draft email:**

```
Subject: Re: Model performance + user behavior tracking

Hey [Name],

This is exactly the gap PostHog fills — Langfuse gives you the model-level tracing, but connecting that to how users actually interact with the output (do they accept it? regenerate? leave?) requires a separate analytics tool. PostHog does both in one platform: LLM traces alongside product analytics, so you can optimize for user outcomes, not just model benchmarks.

One question: are you looking to A/B test different models or prompts against real user behavior, or is the immediate need more about cost visibility and quality monitoring?

[Grab a time here](scheduling-link) and I'll walk through how the LLM Observability and analytics layers connect.

Best,
[Your name]
```

---

## Example 4: Growth & Marketing — Route to Self-Serve

**Lead context:** Marketing manager at a 30-person DTC brand. Message: "We want to understand which ad campaigns drive actual purchases, not just clicks. Currently using GA4 but the attribution is terrible."

**Use case assessment:** Growth & Marketing. Marketing buyer, mentions attribution, campaign performance, GA4 replacement. Classic "understand what drives revenue" job.

**Disposition:** Route to self-serve. 30-person DTC brand, marketing (not engineering) buyer, likely below $20K threshold. Web Analytics + Marketing Analytics free tiers will cover initial needs.

**Draft email:**

```
Subject: Re: Campaign attribution beyond GA4

Hey [Name],

PostHog can connect the dots from ad click to actual purchase — not just pageviews. The combo of [Web Analytics](https://posthog.com/docs/web-analytics/getting-started) for traffic and [Marketing Analytics](https://posthog.com/docs/web-analytics/marketing-analytics) for campaign attribution gives you a full picture of which campaigns drive revenue.

One advantage over GA4: PostHog uses first-party tracking, so you get data from users that ad blockers would otherwise hide.

To get started, install the PostHog snippet on your site and make sure your campaign URLs have UTM parameters. [This tutorial walks through the full setup for performance marketing](https://posthog.com/tutorials/performance-marketing).

If you have questions during setup, the in-app support button or [community questions](https://posthog.com/questions) are both good resources.

Best,
[Your name]
```

---

## Example 5: Observability — Qualify for Call

**Lead context:** VP of Engineering at a fintech company (~150 employees). Message: "We're spending $80K/year on Sentry and Datadog. Looking to consolidate our error tracking and understand the business impact of incidents, not just the technical details."

**Use case assessment:** Observability (primary). VP Eng buyer, mentions error tracking, Sentry/Datadog replacement, business impact of incidents. The "business impact" signal is PostHog's key differentiator here — connecting errors to user behavior and revenue.

**Disposition:** Qualify for call. $80K current spend, 150 employees, VP Eng buyer. Specific consolidation use case.

**Draft email:**

```
Subject: Re: Consolidating error tracking + understanding business impact

Hey [Name],

The "business impact of incidents" angle is where PostHog is genuinely different from Sentry and Datadog. When an error fires, you can see the stack trace AND the user's actual session (via Session Replay), AND query how many users hit that error and whether it correlated with a drop in your conversion funnel. That's a fundamentally different conversation than "this error fired 500 times."

Quick question: is the primary driver cost consolidation, or is it the business impact visibility that's most compelling? That'll help me focus the conversation.

[Grab a time here](scheduling-link) — happy to walk through how our Error Tracking connects to the analytics layer.

Best,
[Your name]
```

---

## Example 6: Data Infrastructure — Route to Self-Serve

**Lead context:** Analytics engineer at a mid-size company. Message: "We want to export PostHog data to our Snowflake warehouse so our BI team can use it in Looker."

**Use case assessment:** Data Infrastructure. Analytics engineer buyer, mentions data export to Snowflake, BI integration. Straightforward "get PostHog data where it needs to go" job.

**Disposition:** Route to self-serve. Single, specific request (batch export setup). Doesn't require a call — the docs are clear and the free tier covers 1M rows/month.

**Draft email:**

```
Subject: Re: Exporting PostHog data to Snowflake

Hey [Name],

This is a straightforward setup — PostHog has a native [Snowflake batch export](https://posthog.com/docs/cdp/batch-exports/snowflake) that'll push your event data on a recurring schedule. The free tier covers 1M rows/month.

Once you've got PostHog data flowing into Snowflake, you might also find it useful to bring data the other direction — the [Data Warehouse](https://posthog.com/docs/data-warehouse) lets you query Stripe, HubSpot, or other sources alongside PostHog events without leaving PostHog. But the export is the right place to start.

If you run into issues with the Snowflake connection, the in-app support team can help troubleshoot.

Best,
[Your name]
```

---

## Example 7: Ambiguous Use Case — Clarifying Question

**Lead context:** "Director of Technology" at a mid-size company. Message: "We're interested in PostHog. Can someone give us a demo?"

**Use case assessment:** Cannot determine. Vague title, vague request. No specific use case, no mention of products or problems.

**Disposition:** Route to self-serve (tentatively). Need more information to qualify. Ask a clarifying question that surfaces the use case.

**Draft email:**

```
Subject: Re: PostHog demo

Hey [Name],

Thanks for reaching out. To point you in the right direction — what's the main problem you're looking to solve? For example:

* Understanding user behavior and where they get stuck
* Shipping features safely with gradual rollouts
* Tracking errors and understanding their impact
* Measuring which marketing channels drive real conversions
* Monitoring AI/LLM performance and costs

Knowing that will help me send you the right resources and docs for your specific setup.

Best,
[Your name]
```

---

## Example 8: Ambiguous Use Case, Atypical Company — Route to Self-Serve

**Lead context (Salesforce fields):**
- **Name:** [First name]
- **Email:** person@companyname.com
- **Company:** [Company name]
- **Lead Source:** Contact sales form
- **Where did you hear about PostHog?** Referral
- **Message:** "Hello, Does PostHog integrate with other tools, including CRMs? Thanks"

**Company research:** [Company name] — aerospace/defense startup, ~25 employees. Builds autonomous orbital servicing platforms for satellite maintenance and in-space compute. Has an AI/ML-enabled compute platform onboard spacecraft. Deep-tech hardware/aerospace company, not a typical SaaS or product-engineering org — though they do build software (AI-enabled compute platform, mission control).

**Use case assessment:** Cannot confidently determine. The message is too vague — "integrations, including CRMs" could point toward Data Infrastructure (pushing data to a CRM) or Growth & Marketing (connecting product data to sales pipeline), but there's no signal about what problem they're solving. The persona is unknown (no title listed). The company is aerospace/defense hardware, which is outside PostHog's typical ICP, though their software components (AI-enabled compute, mission ops) could be a fit.

**Disposition:** Route to self-serve. The message is vague with no defined use case, no title or role is listed, the company is a small aerospace startup outside PostHog's typical ICP, and there's no signal of $20K+ spend potential. Answer the integration question directly, ask one clarifying question to surface the use case, and point to self-serve resources. Do not offer a call.

**Example response:**

```
Subject: Re: PostHog integrations

Hey [First name],

Yes — PostHog integrates with CRMs and a wide range of other tools. You can push PostHog event data to HubSpot, Salesforce, and other destinations via Data Pipelines, and pull data from external sources (Stripe, Postgres, etc.) into PostHog's Data Warehouse for unified querying.

Here's the full list of available integrations:

* [Realtime destinations](https://posthog.com/docs/cdp/destinations) (CRM, Slack, ad platforms)
* [Data sources you can connect](https://posthog.com/docs/cdp/sources)

To point you to the right setup — what's the main problem you're looking to solve with PostHog?

The free tier covers 1M events/month with all features, so you can get set up and explore integrations without any commitment. If you hit specific questions during setup, the in-app support button is the fastest way to get help.

Best,
[Your name]
```

---

## Example 9: Competitor Displacement (Heap) — Surface BANT Before Qualifying

**Lead context:**
- **Name:** [First name]
- **Email:** person@companyname.com
- **Company:** [Company name] (business messaging platform, ~50-100 employees)
- **Lead Source:** Contact sales form
- **Where did you hear about PostHog?** "Using Heap looking to move"
- **Message:** "Using Heap looking to move"

**Company research:** [Company name] — omnichannel business messaging platform. SaaS product with CRM integrations (Salesforce, HubSpot), shared inboxes, automated messaging, campaign management. SOC 2 Type 2 compliant. Mid-market SaaS company with enterprise customers.

**Use case assessment:** Product Intelligence (primary). They're on Heap, which is a product analytics tool with auto-capture and session replay. The competitor signal tells us they're already doing product analytics and likely want to continue. Secondary use cases (Release Engineering, Growth & Marketing) are possible but not signaled yet.

**Disposition:** Competitor displacement — surface BANT before qualifying or routing. They have existing budget (they're paying for Heap), a defined need (product analytics at minimum), and some urgency (they're actively looking to move). But we don't yet know what's driving the switch or what they want PostHog to solve beyond what Heap does. Ask discovery questions to surface Budget and Need before offering a call.

**Example initial response:**

```
Subject: PostHog

Hi [First name],

Thanks for your interest in PostHog, and thanks for reaching out. I'm [Your name], and I'll be helping you assess if PostHog is the right fit. A couple of quick questions before I point you in the right direction:

What's driving the switch? Is it cost, missing features, data ownership, or something else with Heap that's frustrating you?

What are you hoping PostHog solves that Heap doesn't? Are you mostly looking to replace product analytics, or are you also interested in things like session replay, feature flags, or A/B testing?

Knowing what's broken and what you're trying to build toward will help me figure out the best path forward for your team.

[Your name]
```

**Why this works:**
- Doesn't offer a call immediately — surfaces BANT first
- Asks about Budget driver (cost? features? data ownership?) and Need (replace analytics only, or expand scope?)
- Keeps it to two questions — both focused on understanding the switch, not selling PostHog
- Doesn't mention pricing, free tier, or docs yet — waits to hear what they need before pointing them anywhere
- The "what's broken and what you're trying to build toward" framing positions the TAE as an advisor, not a salesperson

**What happened next (illustrative scenario):**

The lead replied: cost was the primary driver, and they also wanted Session Replay in addition to analytics. They then followed up asking to jump on a call to discuss.

The TAE responded by offering a calendar link but also noting that everything needed to make a decision is publicly available (pricing, discounts, free signup), encouraging the lead to start evaluating in parallel. This is the right pattern when a lead asks for a call before you've fully qualified — don't gate-keep the call, but make sure they know they can self-serve the evaluation.

---

## Patterns and Anti-Patterns

### Always do:
- Identify the use case before writing the email
- State the disposition recommendation before the draft
- Frame the response around the lead's problem, not PostHog products
- Provide links to use-case-specific resources (not generic "check our docs")
- Mention in-app support for product questions
- Embed all links in anchor text

### Never do:
- Offer a call to a lead below $20K threshold
- Use bare URLs in the email body
- Hedge with "it depends" or "it's complicated"
- Write a long intro before getting to the point
- Ask more than one question per email
- Try to pitch all six use cases at once — lead with the one that matches their pain
