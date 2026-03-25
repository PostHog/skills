# Outreach Hooks: High First Invoice (>= $2K)

Templates and patterns for reaching out to customers whose first real invoice will be >= $2K. These fall into two sub-types:

1. **Free-tier-to-paid** — They've been on the free tier and just crossed the threshold where usage-based billing kicks in at a meaningful level. They may have added a payment method recently, or they may not have one yet (in which case they'll hit billing limits).
2. **New signup, heavy usage** — They signed up recently and immediately started generating significant usage. Their first invoice will be large and they may not have calibrated expectations yet.

The outreach goal is the same for both: make sure they understand what's coming, help them optimize, and be a resource if they have questions.

---

## Context: What the Customer Is Experiencing

Most PostHog users start on the free tier and gradually increase usage. The free tier is generous — most people don't pay anything for months. When they cross the threshold into meaningful billing, it can feel sudden:

- They may not have been tracking their usage closely
- They may not realize which products are driving the most cost
- They may not have billing limits set, meaning their invoice is uncapped
- If they're a fast-growing startup, usage can spike without warning

Your outreach should help them feel in control of their spend, not surprised by it.

---

## Multi-User Account (2+ Active Users)

**Priority:** High. A team generating $2K+ monthly usage is a real customer. Slack channel + email.

**Approach:** Lead with what their team is doing in PostHog — the specific products and usage patterns from Vitally. Then surface what their usage translates to in cost, and offer to help optimize. Don't assume they know what they're spending — many users on the free tier never look at billing until the first invoice arrives.

**Example (free-tier-to-paid, broad usage):**

```
Subject: Your PostHog setup

Hey [Company] team,

Your team has ramped up quickly in PostHog — [specific products, e.g., "product analytics, session replay, and feature flags"] across [N] users and [N] projects. Looks like a thorough setup.

As usage grows, costs can creep up in ways that aren't always obvious. [One specific, relevant optimization, e.g., "Feature flags get evaluated on every page load — if you have flags that are no longer in use, archiving them stops the charges immediately."] [Link to guide.]

[If no billing limits are set:] One thing worth doing now: setting per-product billing limits so you have a ceiling on spend. [Link to billing limits guide.]

Also sending over a Slack invite — easiest way to get quick answers on billing or anything technical.

What's your team using PostHog for primarily?

[Your name]
```

**Example (new signup, heavy usage from day one):**

```
Subject: Your PostHog setup

Hey [Company] team,

Noticed your team hit the ground running — [specific observation, e.g., "you've already got analytics, replay, and experiments set up with 5+ users active in the first couple weeks"]. That's a fast ramp.

Given the pace, wanted to make sure you have visibility into what your usage looks like. PostHog's billing is usage-based, and at your current volume, your first invoice will be in the $[X] range. [One optimization suggestion, e.g., "If you're capturing a lot of events from autocapture, tuning which events you track can meaningfully reduce costs without losing the insights that matter."] [Link.]

Also sending a Slack invite — happy to answer any billing or implementation questions as you get settled.

What prompted the move to PostHog?

[Your name]
```

---

## Single User Account (But >= $2K Usage)

**Priority:** Medium-high. A single user generating $2K+ is notable — they're likely a technical founder or lead engineer making infrastructure decisions. Email only, no Slack channel.

**Approach:** Personal, direct. This person is probably building something and chose PostHog deliberately. Respect that — be helpful, not overbearing.

**Example:**

```
Subject: Your PostHog setup

Hey [First name],

Noticed you've got PostHog set up with [specific products, e.g., "analytics, replay, and feature flags"] — looks like you're building on most of the platform.

Quick heads-up on billing: at your current usage, your next invoice will be around $[X]. [One optimization, e.g., "Setting per-product billing limits takes a couple minutes and caps your spend — here's how."] [Link.]

Happy to help if you have any questions about billing or your setup.

[Your name]
```

---

## When They Don't Have a Payment Method Yet

Some high-usage accounts hit the free tier limits and get data ingestion paused rather than generating an invoice. These accounts are valuable — they've demonstrated demand but haven't committed to paying yet.

**Approach:** The outreach should acknowledge the usage and offer to help them figure out what their costs would look like if they add a payment method. Don't push them to add one — help them understand the economics.

**Example:**

```
Subject: Your PostHog setup

Hey [Name / Company team],

Noticed your team has been actively using PostHog — [usage observation]. Looks like you've hit some of the free tier limits on [product, e.g., "session replay"].

If you're thinking about adding a payment method, your monthly spend at current usage would be roughly $[X]. [One optimization, e.g., "Replay sampling — recording a percentage of sessions instead of all of them — can cut that significantly while still giving you the sessions that matter."] [Link.]

No rush on any of this, but happy to walk through the numbers if it'd help.

[Your name]
```

---

## Key Differences from Startup Rolloff

| | Startup Rolloff | High First Invoice |
|---|---|---|
| **They know PostHog costs money** | Yes, but credits masked it | Maybe not — free tier can feel like "free forever" |
| **Billing context** | Credits expiring, transition to paid | First real invoice arriving, may be unexpected |
| **Urgency source** | Calendar (credit expiry date) | Usage growth (costs rising) |
| **Cost framing** | "Here's what you'll pay after credits" | "Here's what your usage translates to" |
| **Optimization framing** | "Control costs during the transition" | "Get visibility into what drives your bill" |
| **Open question** | About the transition | About their use case / what they're building |

---

## Anti-Patterns (Never Do These)

- **"Your bill is going to be $X"** without an optimization suggestion — feels like a threat, not help.
- **"You should add a payment method"** — pushy. They'll add one when they're ready.
- **Referencing their exact event counts or data volumes** — feels surveillance-y. Reference products and general patterns, not precise numbers.
- **"PostHog is very affordable compared to [competitor]"** — unsolicited competitor comparisons are tacky.
- **Sending the email before checking Vitally conversations** — someone may already be in touch. Don't pile on.
- **Feature laundry lists** — pick the 2-3 products they actually use. Don't list everything PostHog offers.
- **Bare URLs** — always use anchor text. Bare URLs look automated.
- **Citing enrichment data** — same rule as everywhere: only reference what you can verify from Vitally usage or public sources.
