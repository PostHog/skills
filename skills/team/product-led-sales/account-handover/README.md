# Account Handover

Draft structured handover notes when transitioning a PostHog account from one TAM or CSM to another.

## What it does

Given an account name, the skill pulls data from Vitally (account health, contacts, notes, conversations), PostHog (product usage, event volume, feature adoption), and billing reports (spend breakdown, plan tier, trends). It synthesizes everything into a handover document with clear sections for account context, key contacts, open items, and recommended next steps.

Sections that require human knowledge (relationship dynamics, communication preferences, verbal commitments) are marked with `[TAM to confirm]` prompts so the outgoing TAM can fill in the gaps before handing off.

## When to use

- A TAM is leaving and needs to transition their accounts
- An account is being reassigned to a different TAM or CSM
- A new team member is picking up accounts and needs a briefing

## Files

- `SKILL.md` — Skill instructions (agent-consumed)
- `references/handover-template.md` — Structured template for the handover document
