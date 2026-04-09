# posthog-inbound-leads

A Claude skill for triaging and responding to inbound PostHog sales leads.

## What it does

Paste in lead details from Salesforce (or describe them), and this skill will:

1. **Check for an existing account** — searches Vitally by email and domain to see if the lead (or their company) is already a PostHog user
2. **Research the company** — web searches to understand who they are, their funding, headcount, growth trajectory, and whether they're building multiple products or AI-native software
3. **Identify the use case** — maps the lead to one of six use cases (Product Intelligence, Release Engineering, Observability, Growth & Marketing, AI/LLM Observability, Data Infrastructure), informed by both the lead's message and the company research
4. **Qualify the lead** — recommends a disposition (qualify for call, route to self-serve, route to startup plan, or disqualify) based on spend potential, growth trajectory, engineer involvement, and use case specificity
5. **Draft a response email** — written in PostHog's voice, framed around the lead's problem and personalized with company context, with validated doc links
6. **Validate all URLs** — fetches every link in the draft to confirm it resolves before you send

## Who it's for

PostHog Technical Account Executives (TAEs) handling inbound sales inquiries. The qualification logic follows PostHog's $20K annual spend threshold for sales-assisted deals, with overrides for high-growth companies where current MAU understates future spend.

## How to use it

Install the `.skill` file, then talk to Claude naturally:

- "Respond to this lead" + paste Salesforce fields
- "Triage this inbound" + describe what the lead said
- "Write a response to this lead" + any context you have

The skill handles the rest — Vitally check, company research, use case mapping, qualification, email draft, and link validation.

## Dispositions

| Disposition | Criteria |
|---|---|
| **Qualify for call** | ≥$20K potential (current or projected via growth trajectory override), engineers involved, specific use case or high-value company needing discovery |
| **Route to self-serve** | <$20K potential with no growth trajectory override, vague request from a non-high-value company, no engineer involvement |
| **Route to startup plan** | Early-stage, potentially eligible for startup program |
| **Disqualify** | Not ICP, spam, or irrelevant inquiry |
| **Competitor displacement** | Currently on a competitor — surfaces BANT before qualifying |

## Qualification logic

The $20K threshold is the default bar, but three mechanisms can modify the qualification decision:

- **Growth trajectory override** — companies classified as "Accelerating" (recent large funding, aggressive hiring, early-stage with significant capital) can qualify even if current MAU is low. Requires at least two high-value signals (e.g., $10M+ funding, 50+ employees, engineering-heavy, multi-product, AI-native).
- **Multi-product spend multiplier** — when the lead or research indicates multiple products, the stated MAU is multiplied by estimated product count before applying the threshold. "Some of our products" at 10K MAU with 5 products = 50K adjusted MAU.
- **Vague request from high-value company** — prevents auto-routing to self-serve when company research reveals a high-value account but the form submission was short. These leads get "qualify for call with discovery questions" instead of self-serve.

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
- Tune the growth trajectory override criteria to match your ICP signals
- Replace the doc URLs with your own product docs
- Rewrite the examples in `references/email-examples.md` to reflect your common inbound scenarios
- Update `references/sales-context.md` with your qualification criteria and sales process
- Update `references/writing-style.md` with your company's voice and tone
