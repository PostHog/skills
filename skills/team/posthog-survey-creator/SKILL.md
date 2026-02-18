---
name: posthog-survey-creator
description: Create and configure surveys in PostHog through guided conversation. Use this skill when a user wants to create a survey, collect user feedback, run NPS/CSAT/CES/PMF surveys, gather product feedback, or understand user sentiment. The skill guides Product Managers through survey design by matching their goals to proven templates (or creating custom surveys), then configuring targeting and scheduling before creating via PostHog MCP tools.
---

# PostHog Survey Creator

Guide users through creating effective surveys in PostHog via conversational flow. Target audience: Product Managers who need help with survey design, question wording, and targeting strategy.

## Critical Rules

1. **One question per message.** Wait for user response before proceeding.
2. **Use PostHog MCP first.** When MCP is available, query PostHog for information instead of asking the user. Always present findings for validation.
3. **Only ask users when MCP unavailable.** Fall back to questions only if MCP tools aren't accessible.
4. **Always create as draft.** Never offer to launch immediately. Surveys are created as drafts so users can review in PostHog before launching.

## PostHog MCP Detection

At the start of conversation or when needing PostHog data, attempt to use MCP tools:
- `posthog:event-definitions-list` — Get available events
- `posthog:properties-list` — Get event or person properties  
- `posthog:surveys-get-all` — Check existing surveys
- `posthog:feature-flag-get-all` — Get feature flags for linking

**If MCP works:** Use data from PostHog and ask user to validate.
**If MCP fails/unavailable:** Ask user directly about their PostHog setup.

## Conversation Flow

### Opening: Show the Journey

When user asks to create a survey:

```
"I'll help you create a survey in PostHog. Here's what we'll figure out together:

1. **Goal** – What do you want to learn?
2. **Questions** – What to ask and how
3. **Audience** – Who should see this?
4. **Timing** – When and how often?

Let's start with the goal. **What do you want to learn from this survey?**"
```

Wait for response.

---

### Step 1: Understand the Goal

**Ask:** "What do you want to learn from this survey?"

Listen for keywords to match templates:

| Keywords | Template |
|----------|----------|
| "recommend", "loyalty", "NPS" | NPS |
| "satisfied", "satisfaction" | CSAT |
| "easy", "effort", "friction" | CES |
| "disappointed", "product-market fit" | PMF |
| "why signed up", "jobs to be done" | JTBD |
| "price", "expensive", "value" | Pricing |
| "competitor", "alternatives" | Competitive Intel |
| "not using", "adoption" | Feature Adoption |
| "beta", "new feature" | Beta Feedback |
| "trial", "upgrade" | Trial Conversion |
| "new user", "intent" | Welcome Survey |
| "onboarding", "getting started" | Activation |
| "inactive", "churned", "win back" | Dormant User |
| "cancel", "leaving" | Churn/Exit |
| "support", "ticket" | Support CSAT |

**After response:** Present matching template OR explore custom, then proceed.

---

### Step 2: Present Template or Explore Custom

#### If template matches:

```
"Based on what you're describing, a **Customer Effort Score (CES)** survey would work well. It measures how easy a task was—lower effort correlates with higher retention.

The standard approach is:
- Q1: Rating (1-7) – 'How easy was it to [task]?'
- Q2: Open text (for low scores) – 'What made this difficult?'

**Does this approach work for you, or would you like to customize it?**"
```

#### If no template matches:

```
"This sounds like a custom survey—I'll help you design one.

**What's the single most important thing you want to learn?**"
```

---

### Step 3: Finalize Questions

If customizing, ask ONE question at a time until questions are defined.

Once set, confirm:
```
"Here's what we have:
[list questions]

**Does this look right?**"
```

---

### Step 4: Define Audience (MCP-First Approach)

This is where PostHog MCP becomes critical. **Do not ask the user about events or properties if MCP is available.**

#### With PostHog MCP available:

1. **First, ask the high-level targeting question:**
   ```
   "Now let's decide who sees this survey.
   
   **Who should see it?** For example:
   - All users
   - Users on a specific page
   - A specific segment (paid users, new users, etc.)
   - Users who completed a specific action"
   ```

2. **Based on their answer, query PostHog and present options:**

   **If they mention an action/event:**
   ```
   [Use posthog:event-definitions-list to find matching events]
   
   "I found these events in your PostHog that might match:
   - `report_viewed` (1.2k times this month)
   - `report_created` (340 times this month)
   - `report_exported` (89 times this month)
   
   **Which event should trigger the survey?**"
   ```

   **If they mention a user segment:**
   ```
   [Use posthog:properties-list with type="person" to find properties]
   
   "I found these person properties you could filter by:
   - `plan` (values: free, pro, enterprise)
   - `signed_up_at`
   - `company_size`
   
   **Which property should we use, and what value?**"
   ```

   **If they mention a page:**
   ```
   "Got it—I'll target users on that page.
   
   **What's the URL or URL pattern?** (e.g., '/reports' or contains 'dashboard')"
   ```

3. **If checking for existing similar surveys:**
   ```
   [Use posthog:surveys-get-all to check for duplicates]
   
   "I noticed you already have an 'NPS Survey' running that targets the dashboard. 
   
   **Should I create a new one, or would you like to modify the existing survey?**"
   ```

4. **If linking to feature flags:**
   ```
   [Use posthog:feature-flag-get-all if user mentions beta/feature flags]
   
   "I found these feature flags that might be relevant:
   - `new-reporting-feature` (currently 30% rollout)
   - `beta-dashboard-v2` (10% rollout)
   
   **Should the survey only show to users with one of these flags enabled?**"
   ```

#### Without PostHog MCP (fallback):

If MCP tools fail or aren't available, ask the user directly:

```
"I don't have access to query your PostHog directly.

**Do you know the event name for when users [complete the action]?** 
(If not, we can target by page URL instead)"
```

Or for properties:
```
"**What's the property name for [plan/segment] in your PostHog?**
(e.g., 'plan', 'subscription_tier', etc.)"
```

---

### Step 5: Configure Timing

**Ask:**
```
"**Should this survey show once per user, or repeat over time?**

- Once is good for most feedback surveys
- Recurring works for NPS (e.g., every 90 days)"
```

If recurring, follow up:
```
"**How often should it repeat?**"
```

---

### Step 6: Confirm and Create

Summarize and ask for final confirmation:

```
"Here's the survey I'll create:

**Name:** [name]
**Questions:**
1. [Q1]
2. [Q2]

**Audience:** [targeting details]
**Schedule:** [once/recurring]

I'll create this as a draft so you can review and adjust the styling in PostHog before launching.

**Ready to create it?**"
```

Wait for confirmation, then use `posthog:survey-create` with `start_date: null` (draft).

---

### Step 7: After Creation

```
"Done! Here's your survey: [link]

It's saved as a draft. From PostHog you can:
- Preview how it looks
- Adjust colors and styling
- Launch when you're ready

**Anything else you'd like help with?**"
```

---

## MCP Query Patterns

### Finding events for targeting

```
1. User says: "Users who created a report"
2. Query: posthog:event-definitions-list with q="report"
3. Present matches: "I found `report_created`, `report_viewed`, `report_shared`. Which one?"
4. User confirms
```

### Finding person properties

```
1. User says: "Paid users only"
2. Query: posthog:properties-list with type="person"
3. Look for: plan, subscription, tier, pricing-related properties
4. Present: "I found a `plan` property with values free/pro/enterprise. Should we target `plan` is not `free`?"
5. User confirms
```

### Checking existing surveys

```
1. Before creating, query: posthog:surveys-get-all
2. Check for similar names or targeting
3. If found: "You have an existing [survey name] with similar targeting. Create new or modify existing?"
```

### Finding feature flags

```
1. User mentions beta/feature rollout
2. Query: posthog:feature-flag-get-all
3. Present relevant flags: "I found `beta-feature-x`. Link the survey to this flag?"
```

---

## Example Conversation (With MCP)

**User:** "I want to create a survey"

**Claude:** "I'll help you create a survey in PostHog. Here's what we'll figure out together:

1. **Goal** – What do you want to learn?
2. **Questions** – What to ask and how
3. **Audience** – Who should see this?
4. **Timing** – When and how often?

Let's start. **What do you want to learn from this survey?**"

---

**User:** "I want to know if the new export feature is easy to use"

**Claude:** "Great! This is perfect for a **Customer Effort Score (CES)** survey.

Here's the standard approach:
- **Q1 (Rating 1-7):** 'How easy was it to use the export feature?'
- **Q2 (Open text, for low scores):** 'What would make it easier?'

**Does this work, or would you like to customize it?**"

---

**User:** "That works"

**Claude:** "Perfect. Now let's decide who should see this.

**Who should see the survey?** For example:
- Everyone
- Users who've used the export feature
- A specific segment"

---

**User:** "People who have used the export feature"

**Claude:** [Queries posthog:event-definitions-list with q="export"]

"I found these export-related events in your PostHog:
- `export_completed` (2.3k times this month)
- `export_started` (2.8k times this month)
- `export_failed` (145 times this month)

**Which event should trigger the survey?** I'd recommend `export_completed` so users have finished the action."

---

**User:** "Yes, export_completed"

**Claude:** "Got it—survey shows after `export_completed`.

**Should this survey show once per user, or repeat over time?**"

---

**User:** "Once"

**Claude:** "Here's the survey I'll create:

**Name:** Export Feature CES
**Questions:**
1. Rating (1-7): 'How easy was it to use the export feature?'
2. Open text (low scores): 'What would make it easier?'

**Audience:** Users who trigger `export_completed`
**Schedule:** Once per user

I'll create this as a draft so you can review it in PostHog before launching.

**Ready to create it?**"

---

**User:** "Yes"

**Claude:** [Creates survey via posthog:survey-create with start_date: null]

"Done! Here's your survey: [link]

It's saved as a draft. You can preview it, adjust the styling, and launch when ready.

**Anything else you'd like help with?**"

---

## Example Conversation (Without MCP)

**User:** "People who have used the export feature"

**Claude:** [MCP query fails or unavailable]

"I can't query your PostHog directly. **Do you know the event name for when someone completes an export?**

If not, we can target by URL instead (e.g., show on the exports page)."

---

**User:** "I think it's called export_done"

**Claude:** "Got it—I'll use `export_done` as the trigger event.

**Should this survey show once per user, or repeat?**"

---

## Question Design Reference

See [references/question-examples.md](references/question-examples.md) for:
- 22 survey templates with proven questions
- Targeting recommendations per survey type
- Branching logic examples
