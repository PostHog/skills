# Account Handover Template

Use this template when generating the handover document. Each section includes guidance on what to include and where the data comes from.

---

## 1. Account Snapshot

| Field | Value |
|-------|-------|
| **Company** | {company name} |
| **What they build** | {one-sentence description of their product/service} |
| **Industry** | {industry} |
| **Employees** | {count, if known} |
| **Funding stage** | {seed / Series A / Series B / etc., if known} |
| **PostHog plan** | {free / paid / startup program / enterprise} |
| **MRR** | ${amount} |
| **Health score** | {score}/10 |
| **Account age** | {time since creation} |
| **Contract** | {monthly / annual} — renewal {date, if applicable} |
| **Transition reason** | {from TAM input} |

*Source: Vitally `get_account_full`, TAM input for transition reason.*

---

## 2. Key Contacts

| Name | Role/Title | Email | Last Active | Relationship Role |
|------|-----------|-------|-------------|-------------------|
| {name} | {title} | {email} | {date from PostHog events} | {Champion / Decision-maker / Technical lead / Day-to-day / [TAM to confirm]} |

**Primary contact**: {name} — {how the outgoing TAM typically communicates with them: email / Slack / calls}

**Communication channel**: {email / shared Slack channel / scheduled calls / ad-hoc}

*Source: Vitally `get_account_users` for contact list, PostHog events for last active dates. Relationship roles should be confirmed by outgoing TAM.*

---

## 3. Product Usage Summary

### Active Products

| Product | Monthly Spend | Status |
|---------|--------------|--------|
| Product Analytics | ${amount} | {Active / Light use} |
| Session Replay | ${amount} | {Active / Light use} |
| Feature Flags | ${amount} | {Active / Light use} |
| LLM Analytics | ${amount} | {Active / Light use} |
| Error Tracking | ${amount} | {Active / Light use} |
| Surveys | ${amount} | {Active / Light use} |
| Data Warehouse | ${amount} | {Active / Light use} |

### Event Volume Trend (last 90 days)

{Include weekly event counts. Classify as: Growing / Flat / Declining.}

| Week | Events |
|------|--------|
| {week} | {count} |

**Trend**: {Growing / Flat / Declining} — {one sentence of context, e.g. "Steady growth of ~10% week-over-week since onboarding" or "Flat at ~50K events/week for the last 3 months"}

### SDK Breakdown (Tech Stack)

| SDK | Events/Period | Share |
|-----|--------------|-------|
| {sdk name} | {count} | {%} |

*Source: PostHog `query-run` for usage data, Vitally forecasted MRR fields for spend, billing report for SDK breakdown.*

---

## 4. Billing and Spend

| Field | Value |
|-------|-------|
| **Current MRR** | ${amount} |
| **MRR trend** | {Growing / Flat / Declining} |
| **Forecasted MRR** | ${amount} |
| **Contract type** | {Monthly / Annual} |
| **Renewal date** | {date, or N/A for monthly} |
| **Billing limits set?** | {Yes — ${limit}/month / No} |
| **Active discounts or credits** | {description, or None} |
| **Pending billing issues** | {description, or None} |

### Spend by Product

| Product | Current Spend | % of Total |
|---------|--------------|------------|
| {product} | ${amount}/mo | {%} |
| **Total** | **${total}/mo** | **100%** |

*Source: Vitally account traits, `postgres.prod.billing_usagereport`.*

---

## 5. Account History

### Recent (last 90 days)

- **{date}** — {event description} *(source: {Vitally note / conversation / inferred from data})*

### Historical

- **{date}** — {event description} *(source: {Vitally note / conversation})*

*Source: Vitally `get_account_notes` and `get_account_conversations`. If no notes exist, flag: "No Vitally notes found — outgoing TAM should document key history before transition."*

---

## 6. Open Items

List every unresolved item. Each entry should have enough context for the incoming TAM to pick it up without asking the outgoing TAM for clarification.

| Item | Status | Owner | Next Step | Deadline |
|------|--------|-------|-----------|----------|
| {description} | {In progress / Waiting on customer / Waiting on PostHog / Stalled} | {who's responsible} | {what needs to happen next} | {date, if any} |

If no open items are found in the data: "No open items found in Vitally notes/conversations. **[TAM to confirm]** — are there any verbal commitments, pending requests, or follow-ups in email/Slack that aren't captured in Vitally?"

*Source: Vitally notes and conversations, filtered for unresolved items.*

---

## 7. Relationship Context

This section depends on the outgoing TAM's knowledge. Present whatever the data reveals, then leave clear prompts for what's missing.

**Communication preferences**: {What the data shows, or: [TAM to confirm — does the customer prefer email, Slack, or calls? How responsive are they? Any preferred meeting times?]}

**Meeting cadence**: {What the data shows, or: [TAM to confirm — regular check-ins? QBRs? Purely ad-hoc?]}

**Internal dynamics**: [TAM to confirm — who really drives decisions? Are there competing stakeholders? Is there an internal champion for PostHog? Anyone resistant?]

**Personality and style**: [TAM to confirm — any communication style preferences? Things that build rapport? Topics to avoid?]

**Sensitive topics**: [TAM to confirm — past incidents, pricing disputes, features they were promised, things they're frustrated about, anything to handle carefully?]

**Competitive context**: [TAM to confirm — are they evaluating alternatives? Do they use other analytics tools alongside PostHog? Any migration history?]

---

## 8. Recommended Next Steps

Based on the data, here's what the incoming TAM should do first:

1. **Introduction**
   - {Recommended approach: warm intro from outgoing TAM / direct email / Slack message}
   - {Suggested timing: before or after the outgoing TAM's last interaction}

2. **First meeting agenda**
   - Acknowledge the transition openly
   - Review open items from Section 6
   - Confirm their current priorities and any upcoming milestones
   - Ask what's working well and what they'd change about their PostHog experience

3. **Quick wins**
   - {Specific actions: resolve a pending ticket, follow up on a feature request, share a relevant doc or feature announcement}

4. **Watch items**
   - {Things to monitor: declining usage, upcoming renewal, credit expiry, unresolved escalation, team changes at the customer}
