---
name: posthog-pls-big-fish
description: "Research, qualify, and suggest outreach for PostHog big fish product-led leads — large companies (500+ or 1000+ employees) using PostHog on free tier without a payment method. Use this skill when a TAE needs to work a big fish alert from Salesforce. Triggers on 'work this big fish lead', 'research this product-led lead', 'big fish alert', '500+ employees no payment method', '1000+ employees no payment method', or any request involving a large-company product-led lead that needs research, qualification, and an outreach recommendation. Also trigger when a TAE pastes Salesforce lead details with matching criteria like 'Big fish alert' or '500+ employees, no payment method'."
---

# PostHog Big Fish Lead Qualification & Outreach

Research, qualify, and recommend the right play for big fish product-led leads. These are large companies (500+ employees) that have signed up for PostHog and are using it on the free tier without a payment method.

## What Makes Big Fish Leads Different

- **They didn't ask for help** — you're reaching out proactively
- **They're already using PostHog** — they have an account, possibly active usage
- **The goal is supporting their evaluation — and identifying real opportunities along the way.** The TAE's job is to help these accounts get value from PostHog quickly. If PostHog is the right fit, the commercial conversation ($20K+ annual) will happen naturally once they're dependent on the product. Other teams handle free-to-paid conversion and churn prevention.
- **You need a specific reason to reach out** — generic emails get ignored. Every outreach needs a hook grounded in what you actually know about their usage.

## Core Workflow

1. **Parse the lead** — Read Salesforce fields. Watch for the subject concatenation bug: `[Product-led] Companyemail@domain.com` often smashes the company name and email together. Split at the `@` pattern to get the real email address.
2. **Research the company** — Web search for firmographics, product, industry
3. **Check Vitally** — Account activity, users, products, conversations, notes
4. **Identify the use case** — Map to PostHog's six use cases based on company type and product usage
5. **Qualify and recommend a play** — Outreach / Skip / Nurture
6. **Draft outreach** — If outreach is recommended, write a support-first email with a specific hook
7. **Validate all URLs** — Fetch every link in the draft to confirm it resolves correctly

## Step 1: Parse the Lead

Salesforce has a known bug where the subject line concatenates the company name and the person's email without a space. For example:

- `[Product-led] AcmeCorpjane.smith@acmecorp.com` → Company: **AcmeCorp**, Email: **jane.smith@acmecorp.com**
- `[Product-led] Go Teamperson@goteam.ca` → Company: **Go Team**, Email: **person@goteam.ca**

**Always parse the subject by finding the email address pattern** (look for where `@` appears and work backwards to the start of the local part). The company name is everything between `[Product-led]` and the start of the email.

## Step 2: Research the Company

Use web search to gather:

- What the company does (one-sentence summary)
- Industry / vertical — is this ICP or not?
- Company size (employees, engineering headcount if available)
- Funding stage and recency
- **Does the company build software products with end-user UIs?** This is table stakes for PostHog relevance. A company can have 5,000 employees but if they don't build software, PostHog isn't relevant.

**Search queries to run:**
```
[company name] what does it do
[company name] crunchbase funding
[company name] engineering team
```

**Cross-check Salesforce enrichment data against your research.** The "500+ employees" matching criteria comes from Clearbit/Harmonic data in Salesforce, which frequently maps to the wrong entity — especially for companies with common names. A 10-person startup can get enriched with data from a completely different company with a similar name, showing 45,000 employees and $10B+ revenue. If your web research contradicts the Salesforce employee count, revenue, or founding year, trust your research and flag the discrepancy.

## Step 3: Check Vitally

**This is the most important step.** The Vitally data determines whether this is a real evaluation or one person poking around.

### 3a: Find the Account

Search for the account in Vitally. The most reliable lookup method is **user email** via `get_user_details`. Account name search is unreliable. If the email lookup returns the user with their account, you have everything you need.

If the lead email returns nothing, try the posthog_org_id from Salesforce as a last resort — but note the `search_accounts` externalId filter is unreliable and may return unrelated results.

### 3b: Check Users in the Account

Use `get_account_users` on the account ID. This is the single most important qualifying signal:

- **1 user** — One person exploring. Lower priority. Light touch outreach at best.
- **2+ users** — Real evaluation underway. Multiple people means someone shared PostHog internally — organizational interest, not just curiosity. Treat with urgency.
- **3+ users with diverse roles/activity** — Very strong. Active cross-functional evaluation. Prioritize.

For each user, note:
- **Email and name** — who are these people?
- **Vitally segments** — "Analytics Creator", "Replay User", "Feature Flag Creator", "Experiment Creator" etc. tell you exactly what they're doing
- **Last seen date** — how recent is the activity?
- **Who's the org Owner?** — this is usually the champion who initiated the evaluation

**Signup velocity matters.** If all users joined within a 1-2 week window, it's a coordinated evaluation. If they trickled in over months with gaps, it may have stalled.

### 3b-ii: Research Each User's Persona and Role

**Mandatory.** For every user in the account, research their actual job title and role. This changes the outreach strategy significantly — an Engineering Manager building a software product is a completely different conversation than a Marketing Ops person tracking a website.

**How to research:**
1. Check Vitally user traits first — `roleAtOrganization`, `sfdc.Role__c`, and `vitally.custom.calculatedTitle` sometimes have useful data
2. Check their LinkedIn profile URL if available in Vitally traits (`sfdc.Linkedin_Profile__c`)
3. Web search: `"[first name] [last name]" "[company name]" LinkedIn`
4. If the company has divisions or sub-brands, note which division the person works in — this can completely change the ICP assessment (e.g., an engineer on a SaaS product team within a services company is very different from a project manager in the services delivery business)

**What to look for:**
- **Exact job title** — "Senior Software Engineer" vs. "AV Project Manager" tells you everything about ICP fit
- **Department / team** — Engineering, Product, Data, Marketing, IT, Operations?
- **Which product or division they work on** — especially important at large companies with multiple business units. The division they're in determines whether PostHog is relevant.
- **Seniority level** — IC engineer, engineering manager, director, VP? This affects who you address the email to and how you frame the ask.

**Report what you find for each user** in the output. If you can't find someone's title, note that as an unknown.

**Why this matters:** Knowing that both users are engineers on a software platform team (strong ICP) vs. marketing analysts tracking a corporate website (weak ICP) is the difference between a Slack channel + outreach email and a skip. The persona research often overrides the company-level ICP assessment — a non-tech company can still have a strong PostHog use case if the right team is evaluating it.

### 3c: Check for Other Accounts on the Same Email Domain

**Mandatory.** Large companies often have multiple PostHog accounts on the same email domain. Search Vitally for other accounts that share the same domain using `search_accounts` or `find_account_by_name` with the company name, and check whether any other accounts have admin emails on the same domain.

**Why this matters:** Sometimes a user signs up and creates a new PostHog org when they actually meant to join an existing one that their colleagues already set up. This is especially common at large companies where one team is already using PostHog and a new person from a different team signs up independently.

**What to look for:**

- **Another account on the same domain that's more established** (more users, more usage, already paying, has a TAE assigned) — If this exists, the new account may be a duplicate. The lead contact may have accidentally created a new org instead of joining the existing one. Flag this in your output — the right play might be connecting this person to the existing account rather than treating them as a new lead.
- **Multiple accounts with active, independent usage** — Different teams evaluating PostHog separately. This is a strong organizational signal. Note which account is most active, which the lead contact belongs to, and whether there's an opportunity to connect the teams.
- **An existing account that's already being worked by another TAE** — If the domain already has an account in someone else's book, coordinate with that TAE before reaching out. Don't create a competing relationship.

**Report what you find:** List all accounts on the domain, their user counts, activity levels, and whether they have a TAE assigned. If the lead's account looks like an accidental duplicate, recommend connecting the user to the existing org instead of outreaching to the new one.

### 3d: Check Conversations and Notes (Last 45 Days)

**Mandatory.** Use `get_account_conversations` and `get_account_notes` before deciding on a play.

- If someone from PostHog has already reached out → coordinate, don't pile on
- If the onboarding team has notes → read them for intel
- If there are support conversations → learn what they're working on
- **If zero conversations and zero notes** → flag this. The account is completely untouched. You're the first human contact.

### 3e: Check Gmail

Search for the company domain in Gmail to see if there's any prior email contact outside of Vitally.

## Step 4: Identify the Use Case

Map to PostHog's six use cases based on what they're using and what the company does:

| Vitally Segments / Products Active | Likely Use Case |
|---|---|
| Analytics Creator, Analytics User, Surveys User | Product Intelligence |
| Feature Flag Creator, Experiment Creator | Release Engineering |
| Error Tracking User | Observability |
| Web Analytics usage | Growth & Marketing |
| LLM Observability usage | AI/LLM Observability |
| Data Warehouse, Batch Exports | Data Infrastructure |

If usage data is thin, infer from company type:
- **AI-native** → AI/LLM Observability + Product Intelligence
- **PLG SaaS** → Product Intelligence + Growth & Marketing
- **Developer tools** → Release Engineering + Observability
- **E-commerce / marketplace** → Growth & Marketing + Product Intelligence

## Step 5: Qualify and Recommend a Play

### Play: Outreach (Slack Channel + Support-First Email)

When the account has **2+ users AND active usage**, they get the full treatment:
- Create a shared Slack channel
- Send a support-first email (see Step 6)

Also recommend outreach when:
- The company is a reasonable ICP fit (builds software, has engineers)
- $20K+ annual spend potential based on company size
- No one from PostHog has already contacted them

### Play: Skip

Recommend skipping when:
- **Not ICP.** Company doesn't build software products (traditional retail, manufacturing, dealerships, etc.)
- **Account already being worked** by another TAE or team.
- **Company size is misleading.** "500+ employees" but they're a non-tech company where the engineering team is 3 people maintaining a website.

### Play: Single User — Check Back (Don't Skip Immediately)

**Do NOT disqualify a lead just because there's only 1 user right now.** Big fish accounts often start with one person setting things up before inviting the team. It can take days or even a couple of weeks for additional users to show up.

When a big fish lead has only 1 user:
1. **Check back in 1 week.** Look at the account again — have more users been added? Has usage increased?
2. **If still 1 user after 1 week, check back 1 more week.** Same check.
3. **If still 1 user after 2 check-backs (3 weeks total), then decide:** send a light-touch single-user email, or deprioritize based on the overall picture (ICP fit, company size, activity level).

Tell the TAE when each check-back is due so they can set a reminder.

### Play: Nurture (Watch, Don't Email Yet)

Recommend nurture when:
- Good fit company but usage is very early — they signed up days ago and have barely done anything. Give them a week to get set up before reaching out.
- The evaluation appears stalled (users signed up months ago, no recent activity). A different approach may be needed (LinkedIn, in-app survey, etc.).

## Step 6: Draft the Outreach Email

Read `references/outreach-hooks.md` before drafting.

### Key Principles (from https://posthog.com/handbook/growth/sales/getting-people-to-talk-to-you)

1. **Your initial outreach isn't about you, it's about them.** Do NOT lead with who you are, that you're attached to their account, or that you're "here to help." Lead with an observation about *their* usage. Your name goes in the signature — that's enough.
2. **Lead with value in the first sentence.** Make a specific observation about their setup drawn from Vitally data. If it takes a paragraph to get to the point, you won't get a response.
3. **Avoid fluff.** "I'm just reaching out to", "I just wanted to", "I'm here if you need anything", "Saw you just signed up" — cut all of it.
4. **Ask yourself: if this landed in the sales@ inbox, would I even give it a second look?** If not, rewrite.
5. Do NOT mention pricing, costs, volume discounts, enterprise features, SSO, or anything commercial. They opted to not talk to sales by self-serving. Respect that.
6. **Mention the Slack invite naturally** — not as the opening or centerpiece.
7. **One open question at the end** — easy to answer, about them.

### Data Integrity Rule

**Only reference things you can verify from Vitally usage data or the company's public website.** Never cite enrichment data (tech stack fields from Clearbit, Harmonic, or Salesforce `Company_tech__c`) as fact in outreach. These fields are often stale, wrong, or refer to a different part of the org. If you state something about their stack in an email and it's wrong, you immediately lose credibility.

✓ OK to reference: Products they're using in PostHog, number of projects, which Vitally segments their users are in, what the company does (from their public website)
✗ NOT OK to reference: Tech stack enrichment fields, competitor tools from Salesforce data, anything you can't verify from actual usage or public information

### Email Structure

1. Brief greeting ("[Company] team" or first name)
2. **Specific observation about their usage** — the first real sentence. Something from Vitally data.
3. One useful resource or suggestion connected to that observation
4. Slack invite mention (natural, not the hook)
5. One open question about them
6. Sign-off (name only)

## Step 7: Validate All URLs

**Mandatory.** Before presenting the draft, fetch every URL in the email using `web_fetch` to verify it resolves and points to the intended content. If broken, search for the correct page. If no valid page exists, remove the link.

## Output Format

When responding to the TAE, always provide:

1. **Lead parsing** — Corrected company name and email (note if the Salesforce subject bug applied)
2. **Company research summary** — What they do, size, funding, industry, ICP fit assessment
3. **Vitally account summary** — Users (count, roles, activity, last seen), products in use, health score, signup velocity, conversations/notes status
4. **Use case assessment** — Which of the six use cases this maps to
5. **Recommended play** — Outreach / Skip / Nurture, with reasoning
6. **Draft email** — If outreach is recommended

## Critical Reminders

1. **Parse the Salesforce subject carefully.** The concatenation bug is common — always look for the email address and split there.
2. **User email is the most reliable Vitally lookup.** Account name search is unreliable. Always try the user email first.
3. **User count is the #1 qualifying signal.** 1 user = low priority. 2+ users = real evaluation. This overrides everything else.
4. **Always check conversations and notes.** Don't pile on if someone is already engaged.
5. **Lead with an observation about them, not about you.** Re-read the handbook: https://posthog.com/handbook/growth/sales/getting-people-to-talk-to-you
6. **Never cite enrichment data as fact in outreach.** Only reference what you can verify from Vitally usage or public sources.
7. **The goal is not sales — it's supporting their evaluation.** These people signed up for PostHog on their own. They chose to self-serve. They did not ask to talk to a salesperson. Your job is to help their evaluation go well — answer technical questions, unblock implementation issues, point them to the right resources, and make sure they can make a good decision about whether PostHog fits their needs. If PostHog is the right fit, the commercial conversation will happen naturally once they're dependent on the product. If it's not the right fit, helping them figure that out quickly is also a win. Never mention pricing, volume discounts, enterprise features, annual contracts, SSO, or anything commercial in the first outreach. No "your dedicated contact," no "I'm here to help you get started," no framing that sounds like a sales motion. It's completely OK to acknowledge that they didn't ask to talk to sales — being upfront about that disarms resistance.
8. **Always validate URLs before presenting the draft.**
9. **Always research each user's persona and role.** Don't draft an email without knowing who these people are and what they do. The persona research often changes the entire play.
