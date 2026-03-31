# PostHog Transition Lead Qualification & Outreach

A Claude skill that helps PostHog TAEs research, qualify, and write outreach for product-led leads hitting a billing transition — startup program rolloffs and high first-invoice customers.

## What it does

When a TAE receives a startup rolloff or high first-invoice alert from Salesforce, this skill runs a billing-focused qualification workflow:

1. **Parses the lead** — Identifies lead type (startup rolloff vs. high first invoice)
2. **Checks Vitally (billing-heavy)** — Account activity, users, products, and deep billing analysis (credits remaining, expiry dates, monthly spend, post-transition cost estimates)
3. **Light company research** — Only when needed (these are existing customers, not cold leads)
4. **Billing analysis** — Calculates post-transition costs, identifies specific optimization opportunities
5. **Recommends a play** — Outreach, light touch, skip, or urgent outreach with reasoning
6. **Drafts outreach** — Using lead-type-specific hooks that balance usage observations with billing help
7. **Validates all URLs** — Fetches every link in the draft before presenting it

## How it differs from Big Fish

Big fish leads are cold outreach to large companies exploring PostHog on the free tier. Transition leads are existing customers facing a billing event. The key differences:

- **Lighter research, heavier billing analysis** — You already know them; the question is what they'll pay
- **OK to reference billing directly** — Unlike big fish (no commercial topics), transition leads expect a billing conversation
- **Optimization suggestions are required** — Every cost mention must be paired with a way to reduce it
- **Single users still matter** — A solo founder spending $2K/month is absolutely worth outreach

## Lead types

| Type | Trigger | Hook |
|---|---|---|
| **Startup rolloff** | Credits expiring or burning fast | Help plan the transition from free credits to paid |
| **High first invoice** | First invoice >= $2K | Help them understand and optimize their spend |

## Play recommendations

| Play | When | Action |
|---|---|---|
| **Outreach** | 2+ active users, meaningful spend, transition imminent | Slack channel + email |
| **Light touch** | Single user, significant spend | Email only |
| **Urgent** | Credits expire < 14 days, or very large first invoice with no billing limits | Direct, time-sensitive email |
| **Skip** | Already being worked, low spend, or abandoned account | Note in Salesforce, move on |

## Files

```
posthog-pls-transition-leads/
├── README.md                                    # This file
├── SKILL.md                                     # Main skill instructions
└── references/
    ├── outreach-hooks-startup-rolloff.md        # Email/Slack templates for startup rolloff
    └── outreach-hooks-first-invoice.md          # Email/Slack templates for high first invoice
```

## Requirements

- **Claude** with skills support
- **Vitally MCP** — For account, user, billing, conversation, and notes lookup
- **Web search** — For light company research when needed
