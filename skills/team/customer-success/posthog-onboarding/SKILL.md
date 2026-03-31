---
name: posthog-onboarding
description: Help existing PostHog customers improve their PostHog instance. Triggers on "help [customer] improve their PostHog setup", "audit [company]'s PostHog instance", "create tracking plan for [company]", "design data schema for [customer]", or requests to improve analytics coverage, fix instrumentation gaps, expand PostHog usage, or build better insights for customers already using PostHog. Use when working with a customer who already has PostHog installed.
---

# PostHog CS Improvement Skill

Help existing PostHog customers get more value from their instance. This skill is for **Customer Success**, not sales — the customer already has PostHog installed, something isn't working well, and your job is to diagnose the gaps and give them a clear path forward.

**Core assumption:** Their current implementation is probably underinstrumented, inconsistently named, or not being used by the right people. Start from that baseline.

## Workflow

1. **Research** – Understand what the company builds
2. **Current State** – Ask the customer to describe their setup and pain points
3. **Customer Profile** – Synthesize into a structured profile
4. **Ideal Schema** – Design best-in-class events and properties for their business type
5. **Insights Plan** – Prescribe insights by problem + maturity (see `references/insights-plan.md`)
6. **Improvement Plan** – Prioritized, actionable recommendations
7. **Output** – Customer-facing improvement plan

**Writing Style:** Follow `references/writing-style.md` for all outputs. Conversational and direct — not corporate, not salesy.

## Step 1: Research

When triggered with a company name or domain, research:

- What they build (product/service)
- Their customers (B2B/B2C, market)
- Business model (pricing, signup flow)
- Tech signals (job postings, docs, stack)

Determine business type: B2B SaaS, B2C SaaS, E-commerce, Marketplace, Developer Tools, Fintech, Healthcare, Content/Media

See `references/business-types.md` for events and metrics by type.

## Step 2: Current State

The goal here is to understand what's broken, missing, or ignored — not to validate what's working. Ask questions that surface problems.

Ask 2–3 questions max per message. Skip anything already known from research or context.

### Must-Have

| Context | Why | Question |
|---------|-----|----------|
| Primary pain point | Drives everything | "What's the #1 thing PostHog isn't giving you right now?" |
| Key user journeys | Core of any tracking plan | "What are the 2–3 most important flows in your product?" |
| Current events | Identifies gaps | "What events are you tracking today? What do you wish you were tracking?" |
| Who uses PostHog | Shapes recommendations | "Which teams actually open PostHog — and which ones should but don't?" |
| Products in use | Finds expansion areas | "Which PostHog products are you actively using vs. ignoring?" |

### Should-Have

- How long they've had PostHog
- Whether engineers are engaged or if CS/PM are blocked waiting for instrumentation
- Any previous attempts to fix the problem that didn't stick
- Compliance constraints

## Step 3: Customer Profile

```markdown
## Customer Profile: [Company]

### Overview
- **Business Type:** [type]
- **What They Build:** [1–2 sentences]
- **Their Customers:** [B2B/B2C, who]
- **Revenue Model:** [subscription/usage/etc]
- **Stage:** [Seed/A/B, employee count]

### PostHog Setup
- **Time Using PostHog:** [months/years]
- **Products Active:** [Analytics, Replay, Flags, Experiments, Surveys, etc]
- **Analytics Maturity:** [Beginner/Intermediate/Advanced]
- **Who Uses PostHog:** [roles]
- **Who Doesn't (But Should):** [roles being left out]

### Current State
- **What They Think Is Working:** [their perception]
- **Primary Pain Point:** [the #1 problem, in their words]
- **Likely Gaps:** [based on what they told you — missing events, underused products, no dashboards, wrong people]

### Technical Context
- **Stack:** [web/mobile/backend, frameworks]
- **User Volume:** [DAU/MAU or events/month if known]
- **Compliance:** [requirements if any]

### Their Product
- **Key Journeys:** [1] [2] [3]
- **Activation Metric:** [what success looks like for their users]
```

## Step 4: Ideal Schema

Don't try to audit what they have — you don't have visibility into their data. Instead, **design the best-in-class schema for their business type and key journeys**, then use it as a benchmark. The customer can map their current tracking against it.

See `references/data-schema.md` for full property lists, group schemas, and AARRR event templates.
See `references/business-types.md` for events and metrics specific to their business type.

### What to design

**Person properties** — what you'd want to know about every user (role, plan, signup source, activation status, etc.)

**Group properties** — for B2B: org name, plan, seat count, MRR, health score

**Core events** — cover the full AARRR journey for their product type:
- Acquisition: how users arrive and sign up
- Activation: the moment they first get value
- Retention: the actions that predict they'll come back
- Referral: sharing, inviting, expanding
- Revenue: upgrade, purchase, renewal

**Key properties on each event** — include context that makes the event useful: `source`, `method`, `plan`, `is_first_time`, `duration_seconds`, etc.

### Naming conventions

- `snake_case` for everything
- `is_` prefix for booleans
- `_count` suffix for numbers
- `_at` suffix for timestamps
- Be specific: `subscription_upgraded` not `upgrade`

Present this as: *"Here's what great looks like for a company like yours — let's figure out how close you are."*

## Step 5: Insights Plan

Prescribe insights based on their pain point and maturity. See `references/insights-plan.md` for full detail.

### Maturity Levels

**Beginner:** No analytics or just GA, no custom events, no dashboards
**Intermediate:** Some events, knows funnels/cohorts, has used Mixpanel or Amplitude
**Advanced:** Mature tracking, warehouse integration, running experiments

### By Problem

| Problem | Beginner | Intermediate | Advanced |
|---------|----------|--------------|----------|
| Churn | Retention chart, replays of churned users | Behavioral cohorts, correlation analysis | LTV analysis, churn prediction experiments |
| Trial conversion | Signup funnel, replays | Breakdown by source/plan | Exit surveys, A/B test CTAs |
| Onboarding | Step funnel, replays | Paths, device breakdown | A/B test flows, in-product surveys |
| Feature adoption | Usage trends, stickiness | Feature retention, power users | Correlation with retention |
| PMF | 12-week retention, WAU/MAU | Power user cohorts | Sean Ellis survey |

Always suggest 2–3 capabilities they're probably not using:
- Session Replay with filters (most underused)
- Correlation analysis
- Feature flags for safe rollouts
- In-product surveys
- User paths
- Group analytics for B2B accounts

## Step 6: Improvement Plan

Prioritize by what unblocks the most value fastest. Frame as three phases:

**Fix first (Days 1–7):** Broken or missing events that are blocking any meaningful analysis. Naming fixes. Enabling products they already have access to.

**Strengthen (Week 2–3):** Add tracking for key journeys identified in Step 2. Build 2–3 core dashboards tied directly to their pain point. Get the right people in PostHog.

**Expand (Week 3+):** Add PostHog products they're not using (Flags, Experiments, Surveys). Deepen with group analytics or warehouse if relevant.

### SDK reference (for instrumentation fixes)

| Stack | SDK | Notes |
|-------|-----|-------|
| React/Next.js | `posthog-js` + Provider | Use `PostHogProvider` |
| Vue/Nuxt | `posthog-js` | Manual init |
| React Native | `posthog-react-native` | Handles persistence |
| Flutter | `posthog-flutter` | Dart |
| iOS | `posthog-ios` | Swift/ObjC |
| Android | `posthog-android` | Kotlin/Java |
| Node.js | `posthog-node` | Server-side |
| Python | `posthog-python` | Django/Flask/FastAPI |

### Watch-outs

- No engineering bandwidth to implement fixes — flag this early, don't build a plan that requires it
- Pain point is vague — keep asking until it's specific and measurable
- Tracking exists but no one looks at it — this is an insights gap, not a data gap; solve differently
- The champion isn't actually using PostHog — whoever you're talking to needs to be a real user

## Step 7: Output — Customer Improvement Plan

One document, shared with the customer. Conversational and direct — written like a PostHog doc, not a sales deck.

```markdown
# PostHog improvement plan – [Company]

## What we're trying to fix
[One or two sentences. Name the problem specifically — not "improve analytics" but "understand why users churn in week 2" or "know which features drive retention."]

## Where you are now
[Honest, kind assessment. What's working, what isn't, and what's missing. Don't sugarcoat but don't be harsh. 3–5 sentences.]

## The ideal setup for a company like yours
[Brief description of what best-in-class looks like for their business type — reference the ideal schema from Step 4. Frame as "here's where you want to get to."]

## What we recommend

### Fix first
[2–3 specific, immediately actionable fixes. Name the event or property. Explain what it unlocks in one sentence.]

### Events to add
[Key missing events from the ideal schema. For each: event name, why it matters, one key property to include.]

### Insights to build
[3–5 specific insights tied to their pain point. Name the insight type, what question it answers.]

### Products to start using
[Any PostHog products they have access to but aren't using. One sentence on why each is relevant to their problem.]

## Your action plan

### Week 1
**Your team:**
- [ ] [Specific action + who owns it]

**We'll handle:**
- [ ] [What PostHog CS will do]

**End of week 1 goal:** [What "done" looks like]

### Week 2–3
[Next phase actions, same format]

## How we'll know it's working
| What | Target | How to check |
|------|--------|--------------|
| [Metric] | [Specific number or outcome] | [Where to look in PostHog] |
```

## Reference Files

- `references/data-schema.md` – Person/group/event properties with stakeholder value
- `references/insights-plan.md` – Insights by problem and maturity
- `references/business-types.md` – Events and metrics by business type
- `references/writing-style.md` – PostHog writing guidelines
