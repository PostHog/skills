# Outreach Hooks: Startup Rolloff

Templates and patterns for reaching out to startup program customers whose credits are winding down. These accounts already know PostHog — the outreach is about helping them navigate the transition to paid, not introducing the product.

---

## Context: What the Customer Is Experiencing

Startup program customers got $50K in free credits valid for 1 year. They've been using PostHog without thinking about cost. Now one of two things is happening:

1. **Time-based rolloff** — The year is ending and they have unused credits that will expire. They may not realize how much they'll lose, or what their first real invoice will look like.
2. **Spend-based rolloff** — They've burned through credits faster than expected and will hit $0 before the year is up. They may already be seeing charges they didn't expect.

Either way, the transition can feel abrupt. Your outreach should make it feel manageable.

---

## Multi-User Account (2+ Active Users)

**Priority:** High. The team is embedded in PostHog. Create a Slack channel and send an email.

**Approach:** Lead with a genuine observation about their team's adoption breadth. Reference the credit transition directly but pair it with a specific optimization suggestion. The observation should come from Vitally data — which products, how many users, how many projects.

**Example (broad adoption, credits expiring soon):**

```
Subject: Your PostHog setup

Hey [Company] team,

Your team's been putting PostHog to serious use — [specific products from Vitally, e.g., "analytics, session replay, feature flags, experiments, and error tracking"] across [N] projects. That's broad adoption for a team your size, and it's clear PostHog is core to how you're building [product/company].

Your startup credits are winding down over the next [few weeks / couple months]. Given how embedded PostHog is in your workflow, it's worth getting ahead of the transition — things like [one specific optimization with link, e.g., "archiving inactive feature flags" or "setting billing limits per product"] can help you control costs without changing how you work.

Happy to walk through your usage breakdown and help optimize before credits roll off. Also sending over a Slack invite — easiest way to get quick answers as things come up.

What's top of mind for your team as you think about the transition?

[Your name]
```

**Example (high spend rate, credits running out early):**

```
Subject: Your PostHog usage

Hey [Company] team,

Noticed your team is getting serious mileage out of PostHog — [specific observation, e.g., "90K+ session recordings and nearly 500K feature flag requests this month alone"]. That's a sign you're using it the way it's meant to be used.

Heads up: at your current usage rate, your startup credits will run out [before the year mark / in the next few weeks]. Your monthly spend is sitting around $[X], which is what your first real invoice will look like once credits are exhausted.

A couple quick wins that can bring that down without changing your workflow: [one specific optimization, e.g., "archiving stale feature flags stops them from being evaluated on every page load — here's how"]. [Link to relevant doc.]

Also sending over a Slack invite — happy to walk through your billing dashboard and help you plan for the transition.

What are your priorities as you think about the next phase?

[Your name]
```

---

## Single User Account (But Meaningful Spend)

**Priority:** Medium. One person, but they're spending real money. Email only — no Slack channel.

**Approach:** Shorter, more personal. Address by first name. Same structure: usage observation, credit heads-up, one optimization, open question.

**Example:**

```
Subject: Your PostHog setup

Hey [First name],

Noticed you've got a solid PostHog setup going — [specific observation, e.g., "analytics and session replay across 2 projects, plus feature flags"].

Quick heads-up: your startup credits are winding down in [timeframe]. At your current usage (~$[X]/month), that's roughly what your first invoice will look like after the transition. [One optimization suggestion with link, e.g., "Setting per-product billing limits is the easiest way to avoid surprises — here's the guide."]

Happy to help you think through the transition if anything comes up.

[Your name]
```

---

## Urgent: Credits Expire in < 14 Days

**Priority:** High regardless of user count. Time pressure changes the tone — be more direct.

**Example:**

```
Subject: PostHog credits expiring [date]

Hey [Name / Company team],

Quick heads-up: your PostHog startup credits expire on [date] — that's [N] days from now. After that, billing switches to usage-based at your current run rate of ~$[X]/month.

If you haven't already, [one high-impact optimization, e.g., "setting billing limits per product is the fastest way to cap spend — takes about 2 minutes"]. [Link.]

Let me know if you want to walk through your usage or have any questions about what the transition looks like.

[Your name]
```

---

## Slack Channel Welcome Message (Multi-User Only)

Send alongside the email. Can be more conversational and direct than the email.

```
Hey [Company] team — your PostHog usage has been growing steadily, and with your startup credits winding down in [timeframe], wanted to make sure you have a direct line for questions about the transition.

Happy to help with billing questions, optimization tips, or anything technical — async here or a quick call, whatever works.

[Your name]
```

---

## Key Differences from Big Fish Outreach

| | Big Fish | Startup Rolloff |
|---|---|---|
| **First sentence** | Usage observation | Usage observation (same) |
| **Billing mention** | Never | Yes — direct and helpful |
| **Costs/pricing** | Never mention | Reference their actual monthly spend |
| **Optimization links** | Optional (nice to have) | Required (pair every cost mention with a way to reduce it) |
| **Slack channel** | Always (if multi-user) | Multi-user only |
| **Tone** | "Supporting your evaluation" | "Helping you plan the transition" |
| **Open question** | "What prompted the evaluation?" | "What's top of mind for the transition?" |

---

## Anti-Patterns (Never Do These)

- **"Your free ride is ending"** — condescending. They earned those credits by being in the startup program.
- **"I'm reaching out because your credits are expiring"** — leads with you, not them. Lead with their usage.
- **"Let me know if you want to discuss pricing options"** — too sales-y. Offer specific optimization help, not a pricing conversation.
- **Listing every product they use** — reference the 2-3 most notable. Laundry lists feel automated.
- **Vague optimization advice** — "there are ways to optimize" is useless. Name the specific thing and link to the guide.
- **Panic-inducing language** — "you're about to lose $38K in credits" makes them feel bad, not helped. Focus on what they'll pay going forward, not what they're losing.
- **Citing enrichment data as fact** — same rule as big fish. Only reference what you can verify from Vitally or their public website.
