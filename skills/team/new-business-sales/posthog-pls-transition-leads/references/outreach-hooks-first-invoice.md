# Outreach Hooks: High First Invoice (>= $2K)

Templates and patterns for reaching out to customers whose first real invoice will be >= $2K. Two sub-types:

1. **Free-tier-to-paid** - They've been on the free tier and crossed into meaningful usage-based billing.
2. **New signup, heavy usage** - Signed up recently and immediately started generating significant usage.

---

## Context: What the Customer Is Experiencing

Most PostHog users start on the free tier and gradually increase usage. When they cross into meaningful billing, it can feel sudden:

- They may not have been tracking usage closely
- They may not realize which products are driving cost
- They may not have billing limits set
- If they're growing fast, usage can spike without warning

Your outreach should help them feel in control of their spend, not surprised by it. But the email itself should be brief - the Slack channel is where the real help happens.

---

## Multi-User Account (2+ Active Users)

**Priority:** High. A team generating $2K+ monthly usage is a real customer. Slack channel + email.

**Approach:** Lead with the Slack channel and ground it in something specific about their setup. Use your research to make a tight connection between what they're doing and why a direct line to PostHog engineering support is useful for them. End with a question that's interesting enough to answer in Slack.

**Example (broad usage, first invoice incoming):**

```
Subject: Slack channel for [Company] <> PostHog

Hey [Company] team,

Setting up a shared Slack channel for you - [reason grounded in their usage, e.g., "you've got analytics and flags running across [N] projects with [N] people in the account, so a direct line for technical questions will save you time"].

One thing worth flagging: enhanced person profiles are driving about [X]% of your forecasted spend right now. If there are interactions where you don't need user-level attribution, [capturing those as anonymous events](https://posthog.com/docs/data/anonymous-vs-identified-events) can cut that by up to 4x. Happy to dig into the specifics in Slack.

[Conversation starter, e.g., "What's the main thing your team is trying to learn from the analytics?"]

[Your name]
```

**Example (new signup, heavy usage from day one):**

```
Subject: Slack channel for [Company] <> PostHog

Hey [Company] team,

Sending a Slack channel invite - [reason, e.g., "with the pace you're ramping at, it'll be the fastest way to get answers on implementation or billing as things come up"].

PostHog billing is usage-based, and at your current volume your first invoice will be in the $[X] range. Happy to walk through what's driving that in Slack - there are usually a few quick wins.

[Conversation starter, e.g., "Are you instrumenting events manually or mostly using autocapture right now?"]

[Your name]
```

---

## Single User Account (But >= $2K Usage)

**Priority:** Medium-high. A single user generating $2K+ is notable - likely a technical founder or lead engineer. Email only, no Slack channel.

**Approach:** Short and direct. This person chose PostHog deliberately. Respect that.

**Example:**

```
Subject: Your PostHog billing

Hey [First name],

Quick heads-up - at your current usage, your next invoice will be around $[X]. [One specific optimization with link, e.g., "Setting per-product billing limits takes a couple minutes and caps your spend - [link]."]

Happy to help if questions come up.

[Your name]
```

---

## When They Don't Have a Payment Method Yet

Some high-usage accounts hit free tier limits and get data ingestion paused. These accounts are valuable - they've demonstrated demand but haven't committed to paying.

**Approach:** Acknowledge the usage, surface what costs would look like, and offer a specific optimization. Don't push them to add a payment method.

**Example:**

```
Subject: Your PostHog setup

Hey [Name / Company team],

Looks like you've hit some free tier limits on [product, e.g., "session replay"]. If you're thinking about adding a payment method, your monthly spend at current usage would be roughly $[X].

[One optimization, e.g., "Replay sampling - recording a percentage of sessions instead of all of them - can cut that significantly. [Link.]"]

No rush, but happy to walk through the numbers.

[Your name]
```

---

## Key Differences from Startup Rolloff

| | Startup Rolloff | High First Invoice |
|---|---|---|
| **They know PostHog costs money** | Yes, but credits masked it | Maybe not - free tier can feel like "free forever" |
| **Urgency source** | Calendar (credit expiry date) | Usage growth (costs rising) |
| **Cost framing** | "Credits winding down, here's what you'll pay" | "Here's what your usage translates to" |
| **Slack pitch** | "Direct line for the transition" | "Direct line as you scale" |
| **Conversation starter** | Tied to their heaviest usage or transition | Tied to what they're building or how they're instrumenting |

---

## Anti-Patterns (Never Do These)

- **"Your team's ramped up fast!" / "That's impressive"** - patronizing. State what you know without cheerleading. These are engineers, not interns.
- **"Your bill is going to be $X"** without context or an optimization - feels like a threat.
- **"You should add a payment method"** - pushy.
- **Long emails with multiple optimization suggestions** - save it for Slack. The email gets them in the door.
- **Referencing exact event counts or data volumes** - feels surveillance-y. Reference products and patterns, not precise numbers.
- **"PostHog is very affordable compared to [competitor]"** - unsolicited competitor comparisons are tacky.
- **Feature laundry lists** - pick 1-2 products relevant to the hook.
- **Bare URLs** - always use anchor text.
- **Citing enrichment data** - only reference what you can verify from Vitally usage or public sources.
