# user-deep-dive skill

A CS skill for generating a detailed profile of an individual PostHog user by email address. Use this before a call, during account reviews, or any time you need to quickly understand what a specific person is doing in PostHog.

## When to use this

- Preparing for a call with a specific user or champion
- Investigating why someone's engagement has dropped
- Understanding who the power users are at an account
- Identifying which PostHog products a user is adopting or ignoring
- Figuring out good outreach angles before reaching out

## How to trigger it

Just provide an email address:

> "Deep dive on luis@juicebox.ai"
> "Tell me about the user sarah@acme.com"
> "What is john@company.com doing in PostHog?"

The skill will ask you for a time window before running any queries (default is 14 days if you skip it).

## What it produces

A structured profile of the user covering:

- **Profile** — name, role, account, location (from Vitally + PostHog)
- **Activity summary** — what they're doing, how often, which events dominate
- **Where they spend time** — which product areas and specific dashboards/insights they revisit
- **What they're doing** — interpretation of their behaviour and the business questions they're trying to answer
- **Session recordings** — a direct link to their recordings in PostHog, plus a summary of any replays they've watched
- **PostHog AI usage** — how heavily they use Max, where they open it, and how many insight analyses they run
- **Outreach angles** — 2–3 conversation starters based on their actual usage, plus pain points and product gaps

## What it needs from you

Just an email address. The skill handles the rest — it runs several PostHog queries in parallel and cross-references with Vitally for role and account data.

## Queries it runs

The skill runs 7 queries in parallel against PostHog:

1. **Activity overview** — top events (excluding PostHog internals like feature flag calls and autocaptures)
2. **Page views** — most visited URLs, used to identify which product areas they use
3. **Insight details** — which specific insights and dashboards they view
4. **Session replay views** — recordings they've watched, with timestamps
5. **Error tracking usage** — whether they're actively triaging errors or just browsing
6. **PostHog AI usage** — counts of Max opens, AI generations, and insight analyses
7. **Where they open Max** — which pages/contexts they use Max on

It also looks up the user in Vitally for role, title, account data, and CRM context.

## Notes

- **Vitally `lastSeenTimestamp` is unreliable** — the skill always uses PostHog event data for activity, not Vitally's last seen field
- **Message content isn't available** — Max conversation content isn't captured in events, so AI usage is summarised by frequency and context (where they opened it), not by what they asked
- The default time window is 14 days, but you can specify any number of days at the start
