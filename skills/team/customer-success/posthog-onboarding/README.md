# posthog-onboarding skill

A CS skill for helping existing PostHog customers improve their setup. Use this when a customer already has PostHog installed but isn't getting full value from it — tracking is incomplete, insights aren't being used, or the wrong people have access.

## When to use this

- A customer says PostHog "isn't working" for them
- You're preparing for a health check or QBR call
- Someone wants a tracking plan or data schema review
- A customer is churning or disengaged and you want to re-engage them with a concrete improvement plan
- You need a customer-facing doc to align on next steps

## How to trigger it

Just describe what you're trying to do and who the customer is:

> "Help me improve Acme Corp's PostHog setup"
> "Create an improvement plan for juicebox.ai"
> "Audit the PostHog implementation for [company]"

## What it produces

A single customer-facing **improvement plan** — conversational, direct, and actionable. It covers:

- An honest assessment of where the customer is now
- What best-in-class looks like for their business type
- Specific events and properties they should be tracking
- Insights to build, tied to their actual pain point
- A phased action plan with clear owners and goals
- Success metrics so everyone knows what "done" looks like

## What it needs from you

The skill will ask you a few questions about the customer before generating anything. The more you know going in, the better the output. Most useful things to have handy:

- What their product does and who their users are
- Their primary pain point with PostHog ("we can't see X" / "we don't know why Y")
- Which PostHog products they're using vs. ignoring
- Which teams use PostHog and which ones should but don't
- Their tech stack (web/mobile/backend)

## What it doesn't do

- It won't query live PostHog data or audit their actual events — you'll need to describe their current state yourself
- It won't produce an internal-only brief (output is customer-facing by design)
- It's not a sales tool — assumes the customer is already on PostHog and needs improvement, not onboarding from scratch

## Reference files

The skill uses several reference documents to generate accurate, tailored output:

| File | What it's for |
|------|---------------|
| `references/data-schema.md` | Person, group, and event property templates |
| `references/insights-plan.md` | Insights by problem type and analytics maturity |
| `references/business-types.md` | Events and metrics tailored by business type (B2B SaaS, E-commerce, etc.) |
| `references/writing-style.md` | PostHog tone and formatting guidelines |
