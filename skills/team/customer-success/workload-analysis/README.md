# workload-analysis skill

A skill for generating interactive visualizations of how a PostHog customer's spend and usage flows across products, workloads, and teams. Use this for account reviews, expansion conversations, or any time you need to quickly understand the shape of a customer's PostHog usage.

## When to use this

- Preparing for a QBR or account review
- Identifying expansion or cross-sell opportunities
- Understanding which teams own which parts of a customer's PostHog setup
- Flagging risk (declining MRR, single product dependency, no annual contract)
- Explaining a customer's usage structure to internal stakeholders

## How to trigger it

Just name the account:

> "Workload analysis for Juicebox"
> "Show me how Acme Corp uses PostHog"
> "SDK breakdown for Intercom"
> "Analyze the Stripe account"

## What it produces

An interactive React dashboard with five views:

- **Overview** — summary cards (MRR, health score, contract type, alerts), SDK breakdown bar, workload cards with products, and an opportunities table
- **Risks** — severity-ranked risks if any are present (declining MRR, no annual contract, low health score, single product dependency)
- **Tree view** — hierarchical diagram showing Account → Workloads → Products → Teams with connecting lines
- **Revenue flow** — Sankey diagram showing how spend flows from PostHog products (left) to customer workloads (right)
- **Matrix** — Products × Workloads grid with spend in each cell

## How it works

The skill pulls data from two sources in parallel:

1. **Vitally** — MRR, forecasted MRR, product spend fields, health score, contract type, employee count, funding stage
2. **PostHog billing SQL** — SDK event counts (web, Node, Python, Go, Ruby, PHP, Java, iOS, Android, Flutter, React Native), recording counts, AI events, exceptions, feature flag requests

It then maps SDK proportions to workloads (e.g. if Flutter is 80% of events, the primary workload is a Flutter mobile app), allocates product spend to each workload, and identifies opportunities and risks using standard frameworks.

## Reference files

| File | What it's for |
|------|---------------|
| `references/data-mapping.md` | Full list of Vitally and billing fields used |
| `references/spend-allocation.md` | Rules for allocating product spend to workloads |
| `references/opportunity-framework.md` | Frameworks for identifying opportunities and risks |
| `assets/workload-template.jsx` | Base React component template used for the visualization |

## Notes

- **Don't skip Flutter and React Native** — mobile-first companies often have these as their dominant SDK, and it's easy to miss them if you only check web/iOS/Android
- The skill verifies that SDK totals roughly match the total event count — a big gap usually means a missing SDK
- Status thresholds: Significant (≥$500/mo), Adopted ($100–499/mo), Experimenting ($1–99/mo), Opportunity ($0/mo)
