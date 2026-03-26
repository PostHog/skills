# Outreach Hooks: Startup Rolloff

Templates and patterns for reaching out to startup program customers whose credits are winding down. These accounts already know PostHog - the outreach is about helping them navigate the transition to paid, not introducing the product.

---

## Context: What the Customer Is Experiencing

Startup program customers got $50K in free credits valid for 1 year. They've been using PostHog without thinking about cost. Now one of two things is happening:

1. **Time-based rolloff** - The year is ending and they have unused credits that will expire. They may not realize how much they'll lose, or what their first real invoice will look like.
2. **Spend-based rolloff** - They've burned through credits faster than expected and will hit $0 before the year is up. They may already be seeing charges they didn't expect.

Either way, the transition can feel abrupt. Your outreach should make it feel manageable. Unlike big fish or first-invoice leads, it's OK to mention pricing options or discounts here - these customers have been using PostHog for free and could be staring down a significant bill. Offering to discuss pricing is a natural and expected part of supporting the transition.

---

## Multi-User Account (2+ Active Users)

**Priority:** High. The team is embedded in PostHog. Create a Slack channel and send an email.

**Approach:** Lead with the Slack channel - it's the most tangible value you're offering. Use what you know from Vitally to explain why it'll be useful for *them* specifically (e.g., if they're heavy on feature flags, mention getting help with flag management as credits wind down). Keep it short. The goal is to get them into Slack, not to deliver a billing briefing via email.

**Example (broad adoption, credits expiring soon):**

```
Subject: Slack channel for [Company] <> PostHog

Hey [Company] team,

Setting up a shared Slack channel for you - [specific reason it's useful for them, e.g., "given you're running analytics, replay, flags, and experiments across 2 projects, it'll be the fastest way to get help with any of it"].

Your startup credits wind down in [timeframe], so this is also a good place to talk through billing, optimization, or pricing options as you transition.

Invite incoming - [conversation starter, e.g., "curious what you're using feature flags for - the 500K requests/month caught my eye"].

[Your name]
```

**Example (high spend rate, credits running out early):**

```
Subject: Slack channel for [Company] <> PostHog

Hey [Company] team,

Sending over a shared Slack channel invite - easiest way to get quick answers from someone technical on our side.

Heads up: at your current run rate (~$[X]/month), your startup credits will run out [before the year mark / in the next few weeks]. Happy to dig into what's driving that in Slack - whether that's optimizing usage or talking through pricing options for the transition.

[Conversation starter tied to their heaviest usage, e.g., "Are the 90K replays intentional or would sampling work for what you're doing?"]

[Your name]
```

---

## Single User Account (But Meaningful Spend)

**Priority:** Medium. One person, but they're spending real money. Email only - no Slack channel.

**Approach:** Short and direct. Address by first name. Credit heads-up, one specific optimization, and an easy way to get help.

**Example:**

```
Subject: Your PostHog credits

Hey [First name],

Quick heads-up - your startup credits are winding down in [timeframe]. At your current usage (~$[X]/month), that's roughly what your first invoice will look like.

[One specific optimization with link, e.g., "If you haven't set per-product billing limits yet, it's the fastest way to cap spend - [link]."]

Happy to help if anything comes up.

[Your name]
```

---

## Urgent: Credits Expire in < 14 Days

**Priority:** High regardless of user count. Time pressure changes the tone - be more direct.

**Example:**

```
Subject: PostHog credits expiring [date]

Hey [Name / Company team],

Your PostHog startup credits expire on [date] - [N] days from now. After that, billing switches to usage-based at your current run rate of ~$[X]/month.

[One high-impact optimization, e.g., "Setting billing limits per product is the fastest way to cap spend - takes about 2 minutes. [Link.]"]

Let me know if you want to walk through your usage.

[Your name]
```

---

## Slack Channel Welcome Message (Multi-User Only)

Send alongside the email. Can be more direct and conversational than the email.

```
Hey [Company] team - [your name] from PostHog. This channel is a direct line for anything technical, billing, or otherwise as your startup credits wind down over the next [timeframe].

[Conversation starter grounded in their usage, e.g., "I noticed you're running experiments alongside feature flags - are you using flags to control experiment rollouts, or are those separate workflows?"]

Async here or a quick call, whatever works.
```

---

## Key Differences from Big Fish Outreach

| | Big Fish | Startup Rolloff |
|---|---|---|
| **Lead with** | Usage observation | Slack channel + why it's useful for them |
| **Billing mention** | Never | Yes - direct, one sentence |
| **Costs/pricing** | Never mention | Reference their actual monthly spend |
| **Slack channel** | Mentioned, not centerpiece | The centerpiece - get them in there |
| **Tone** | "Supporting your evaluation" | Engineer-to-engineer, "here's a direct line" |
| **Length** | Medium | Short - save the details for Slack |
| **Goal** | Get them to respond | Get them into Slack |

---

## Anti-Patterns (Never Do These)

- **"Your team's ramped up fast!"** or **"That's impressive adoption"** - patronizing. These are competent engineers, not kids who drew a nice picture. State what you know without cheerleading.
- **"Your free ride is ending"** - condescending. They earned those credits by being in the startup program.
- **"I'm reaching out because your credits are expiring"** - leads with you, not value.
- **"Let me know if you want to discuss pricing options"** as the only value prop - pricing is fine to mention for startup rolloffs (they're facing a real billing change), but it shouldn't be the *only* thing you're offering. Pair it with something technical.
- **Long emails with multiple optimization suggestions** - save it for Slack. The email is a door, not the room.
- **Listing every product they use** - reference 1-2 that are most relevant to the hook.
- **Vague optimization advice** - "there are ways to optimize" is useless. Name the specific thing.
- **Panic-inducing language** - "you're about to lose $38K in credits" makes them feel bad, not helped.
- **Citing enrichment data as fact** - same rule as big fish. Only reference what you can verify from Vitally or their public website.
