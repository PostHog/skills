# posthog-inbound-leads

A Claude skill for triaging and responding to inbound PostHog sales leads.

## What it does

Paste in lead details from Salesforce (or describe them), and this skill will:

1. **Identify the use case** — maps the lead to one of six use cases (Product Intelligence, Release Engineering, Observability, Growth & Marketing, AI/LLM Observability, Data Infrastructure)
2. **Qualify the lead** — recommends a disposition (qualify for call, route to self-serve, route to startup plan, or disqualify) based on spend potential, engineer involvement, and use case specificity
3. **Draft a response email** — written in PostHog's voice, framed around the lead's problem, with validated doc links
4. **Validate all URLs** — fetches every link in the draft to confirm it resolves before you send

## Who it's for

PostHog Technical Account Executives (TAEs) handling inbound sales inquiries. The qualification logic follows PostHog's $20K annual spend threshold for sales-assisted deals.

## How to use it

Install the `.skill` file, then talk to Claude naturally:

- "Respond to this lead" + paste Salesforce fields
- "Triage this inbound" + describe what the lead said
- "Write a response to this lead" + any context you have

The skill handles the rest — use case mapping, qualification, email draft, and link validation.

## Dispositions

| Disposition | Criteria |
|---|---|
| **Qualify for call** | ≥$20K potential, engineers involved, specific use case |
| **Route to self-serve** | <$20K potential, vague request, no engineer involvement |
| **Route to startup plan** | Early-stage, potentially eligible for startup program |
| **Disqualify** | Not ICP, spam, or irrelevant inquiry |
| **Competitor displacement** | Currently on a competitor — surfaces BANT before qualifying |

## Skill structure

```
posthog-inbound-leads/
├── SKILL.md                          # Core workflow and qualification logic
└── references/
    ├── email-examples.md             # 9 example leads with full output (assessment, disposition, draft)
    ├── sales-context.md              # Thresholds, process overview, qualification criteria
    └── writing-style.md              # PostHog tone, formatting, and email style rules
```

## Customization

This skill is built around PostHog's specific sales motion, but the structure is adaptable. To use it for your own product:

- Update the six use cases in SKILL.md to match your product's value props
- Adjust the spend threshold ($20K) to your sales-assist cutoff
- Replace the doc URLs with your own product docs
- Rewrite the examples in `references/email-examples.md` to reflect your common inbound scenarios
- Update `references/sales-context.md` with your qualification criteria and sales process
- Update `references/writing-style.md` with your company's voice and tone
