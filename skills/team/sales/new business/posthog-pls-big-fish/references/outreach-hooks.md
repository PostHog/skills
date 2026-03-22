# Big Fish Outreach Hooks & Examples

All outreach for big fish leads follows the same core rules from the handbook (https://posthog.com/handbook/growth/sales/getting-people-to-talk-to-you):
- Lead with an observation about *their* usage, not about you
- Value in the first sentence
- No fluff, no self-introduction, no "saw you signed up"
- No pricing, no sales language, no enterprise features
- One open question at the end

The difference between single-user and multi-user leads is priority and treatment, not tone.

---

## Single User in Account

**Priority:** Lower. One person exploring. May still be worth a light touch — especially if the company is 1000+ employees or a strong ICP fit.

**Approach:** Short, casual, one observation + one useful resource. No Slack channel.

**Example:**

```
Subject: Your PostHog setup

Hey [Name],

Noticed you got set up with PostHog recently — looks like you're starting to explore [product they're using, e.g., "Product Analytics" or "Session Replay"].

[One specific, useful resource relevant to what they're doing — e.g., "Here's a guide on connecting replay to funnel drop-offs — it's where most teams see the first real insight." or "If you're setting up event tracking, this guide on optimizing capture helps you get cleaner data from the start."]

What prompted you to check out PostHog?

[Your name]
```

---

## Multiple Users in Account (2+, Active)

**Priority:** High. This is a real evaluation. Create a Slack channel and send a support-first email.

**Approach:** The observation should reference something specific from Vitally — which products they're using, how many projects, what their team is doing. Link to one relevant resource. Mention the Slack invite naturally. End with an open question.

**Example (broad product usage):**

```
Subject: Your PostHog setup

Hey [Company] team,

Noticed your team has ramped up quickly across [specific products — e.g., "Product Analytics, Session Replay, and Feature Flags"] — that's a lot of ground covered in [timeframe, e.g., "a couple of weeks"].

Wanted to make sure you're set up to get the most out of each of those. [One relevant resource — e.g., "Here's a guide on connecting replay to your funnel analysis — it's where most teams see the biggest unlock."]

Also sent over a Slack invite — easiest way to get quick answers as things come up.

What prompted the evaluation?

[Your name]
```

**Example (analytics + replay focused):**

```
Subject: Your PostHog setup

Hey [Company] team,

Noticed your team has been building analytics insights and watching session replays across [X] projects — looks like a thorough evaluation.

If you're ramping up replay, filtering sessions from funnel drop-offs is where most teams see the first big insight — you're watching the sessions that actually matter instead of a random sample. [Link to guide on connecting replay to analytics]

Also sent over a Slack invite — easiest way to get quick answers as things come up.

What prompted the evaluation?

[Your name]
```

**Example (single power user doing everything):**

```
Subject: Your PostHog setup

Hey [Company] team,

Noticed [first name] has been putting PostHog through its paces — analytics, replay, feature flags, experiments, surveys. That's unusually thorough for a new setup.

[One relevant resource based on what they're most actively doing — e.g., "If you're running experiments, here's how to connect experiment results to your analytics funnels so you can measure downstream impact, not just the primary metric."]

Also sent over a Slack invite — easiest way to get quick answers as things come up.

What can I help with?

[Your name]
```

---

## Slack Channel Welcome Message

When you create a Slack channel for a multi-user big fish account, send a welcome message alongside the email. The Slack message can be slightly more conversational and direct than the email.

**Key framing:** It's completely OK to acknowledge that they didn't ask to talk to sales. Call it out honestly — you're not trying to sell them, you want their evaluation to go quickly. This disarms the "why is sales emailing me" resistance.

**Sample Slack welcome message:**

```
Hey [Company] team — your team has covered a lot of ground in PostHog already ([specific observation from Vitally, e.g., "analytics, replay, and feature flags across 3 projects"]). Wanted to make sure you have a direct line for questions as things come up.

Quick context: What prompted the evaluation? Are you replacing another tool, solving a specific gap, or exploring options?

Happy to help with technical questions, implementation, or just being a sounding board — async here or a call, whatever works.

[Your name]
```

**What works about this:**
- Leads with an observation about *them*, not about you
- "Direct line for questions" frames it as support, not sales
- Asks what prompted the evaluation — open, about them
- Offers multiple ways to help without being pushy
- Short and scannable

**The Slack message and the email serve different purposes.** The email should lead with a usage observation and link to something useful. The Slack message can be more conversational and directly ask what they're trying to accomplish. Send both — some people respond to email, some to Slack.

---

## Data Integrity Rule

**Only reference things you can verify.**

✓ **Safe to reference in emails** (comes from Vitally usage data or public sources):
- Which PostHog products they're actively using (from Vitally user segments)
- Number of projects in their account
- How many people are in the account and what they're doing
- What the company does and builds (from their public website)
- Recent funding rounds (from public press releases / Crunchbase)

✗ **Never reference in emails** (enrichment data that may be stale or wrong):
- Tech stack fields from Salesforce (`Company_tech__c`) — these come from Clearbit/Harmonic and are often outdated
- Competitor tools the company supposedly uses — unless you verified it on their public site or in their PostHog usage
- Employee counts from Salesforce if they don't match what you found in research
- Any "fact" about the company you can't point to a verifiable source for

If you state something in an email and it's wrong, you lose credibility instantly. When in doubt, leave it out.

---

## Anti-Patterns (Never Do These)

- **"I'm [name], your dedicated PostHog contact"** — they didn't ask for a contact. Your name is in the signature.
- **"Saw you just signed up"** — they know when they signed up. This adds nothing.
- **"I'm here if you need anything"** — too passive and generic. Say something specific or don't say it.
- **"Just checking in"** — there must be a reason for the email. If you can't find one, don't send it.
- **Feature laundry lists** — don't list every PostHog product. Reference the 1-2 they're actually using.
- **Mentioning pricing, costs, enterprise features, SSO, or volume discounts** — this is not a sales email. It's a support-first introduction.
- **Bare URLs** — always embed links in anchor text.
- **Citing enrichment data as fact** — "I noticed you're using [competitor tool]" when that came from a Salesforce tech stack field, not from verified data.
- **Sending without research** — if you can't explain what the company does in one sentence, you haven't researched enough.
