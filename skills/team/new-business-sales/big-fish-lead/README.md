# PostHog Big Fish Lead Qualification & Outreach

A Claude skill that helps PostHog TAEs research, qualify, and write outreach for big fish product-led leads — large companies using PostHog on free tier without a payment method.

## What it does

When a TAE receives a big fish alert from Salesforce, this skill runs the full qualification workflow:

1. **Parses the lead** – Extracts company name and email from Salesforce's concatenated subject line format
2. **Researches the company** – Web search for firmographics, product, industry, and ICP fit
3. **Checks Vitally** – Account activity, users, products, conversations, notes, and duplicate accounts on the same domain
4. **Researches each user's persona** – LinkedIn/web search for actual job titles and departments
5. **Identifies the use case** – Maps to PostHog's six use cases based on company type and product usage
6. **Recommends a play** – Outreach, skip, check-back, or nurture with reasoning
7. **Drafts outreach** – Support-first email with a specific hook grounded in usage data
8. **Validates all URLs** – Fetches every link in the draft before presenting it

## Features

- **Salesforce subject line parsing** – Handles the `[Product-led] CompanyNameemail@domain.com` concatenation bug automatically
- **Vitally-first qualification** – User count is the #1 qualifying signal. 1 user = check back later. 2+ users = real evaluation.
- **Duplicate account detection** – Searches for other accounts on the same email domain to catch accidental org creation (common at large companies)
- **Mandatory persona research** – Looks up every user's actual job title and department before drafting. Persona research can override company-level ICP assessment.
- **Enrichment data skepticism** – Never cites Clearbit/Harmonic tech stack fields as fact in outreach. Cross-checks Salesforce employee counts against web research.
- **Support-first email tone** – Leads with a usage observation, not a self-introduction. No pricing, no sales language, no "your dedicated contact." The goal is supporting their evaluation, not selling.
- **Single-user check-back logic** – Doesn't disqualify leads with only 1 user. Recommends two check-backs over 2 weeks before deciding.
- **Gmail cross-reference** – Checks for prior email contact outside of Vitally
- **URL validation** – Every link in a draft email is fetched and verified before presenting

## Requirements

- **Claude** with skills support
- **Vitally MCP** – For account, user, conversation, and notes lookup
- **Gmail MCP** – For checking prior email contact
- **Web search** – For company research and persona lookup

## Usage

Paste a Salesforce big fish alert screenshot or details:

```
"Work this big fish lead: [Product-led] AcmeCorpjane.smith@acmecorp.com
Big fish alert: 500+ employees, no payment method"
```

Claude will run the full workflow and return:

1. Corrected company name and email
2. Company research summary with ICP fit assessment
3. Vitally account summary (users, products, health score, engagement metrics)
4. Domain duplicate check results
5. Persona research for each user
6. Use case mapping
7. Recommended play with reasoning
8. Draft outreach email (if applicable) with validated URLs

## Play recommendations

| Play | When | Action |
|---|---|---|
| **Outreach** | 2+ users, active usage, ICP fit | Slack channel + support-first email |
| **Skip** | Not ICP, already being worked, misleading employee count | Note in Salesforce, move on |
| **Check-back** | 1 user, too early to tell | Revisit in 1 week, then again in 1 week |
| **Nurture** | Good fit but very early or stalled | Watch, don't email yet |

## Six use cases

| Use Case | Signals |
|---|---|
| Product Intelligence | Analytics, funnels, retention, session replay |
| Release Engineering | Feature flags, rollouts, experiments |
| Observability | Error tracking |
| Growth & Marketing | Attribution, web analytics |
| AI/LLM Observability | LLM costs, model monitoring |
| Data Infrastructure | Data warehouse, batch exports |

## Files

```
posthog-pls-big-fish/
├── README.md                     # This file
├── SKILL.md                      # Main skill instructions
├── posthog-pls-big-fish.skill    # Packaged skill (ready to upload)
└── references/
    ├── outreach-hooks.md         # Email/Slack templates, data integrity rules, anti-patterns
    └── writing-style.md          # PostHog tone and formatting guidelines
```