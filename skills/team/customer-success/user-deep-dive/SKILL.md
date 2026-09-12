---
name: user-deep-dive
description: "Analyse a PostHog user by email address — queries event history, maps product area usage, identifies feature adoption patterns, and cross-references Vitally CRM data to produce a structured profile with outreach angles. Use when preparing for a call with a specific user, investigating engagement changes, looking up user activity or behavior, doing an account review, or identifying power users and product gaps."
---

Deep dive on a PostHog user by email address. Queries their event history, maps which product areas they use, identifies feature adoption patterns, and cross-references Vitally CRM data to produce a structured profile with outreach angles.

**Input**: $ARGUMENTS (email address, e.g. `artis.conka@enlabs.com`)

## Process

### Step 0: Ask for time window

Before running any queries, ask the user:

> "What time window would you like to analyse? (default: last 14 days)"

If they don't respond or say "default", use **14 days**. Use their answer to set `{days}` in all queries below.

---

### Step 1: Run queries in parallel

Run all 7 queries from [references/queries.md](references/queries.md) simultaneously via the `query-run` MCP tool. Each query uses `{email}` and `{days}` as parameters.

The queries cover:
1. **Activity overview** — top events excluding PostHog internals
2. **Page views** — most visited URLs for product area mapping
3. **Insight details** — specific insights and dashboards viewed
4. **Session replay views** — recordings watched with timestamps
5. **Error tracking usage** — triaging activity vs browsing
6. **PostHog AI usage** — Max opens, AI generations, insight analyses
7. **Where they open Max** — pages and contexts for Max usage

### Step 2: Cross-reference with Vitally

Use Vitally tools to look up the user by email — get their role, title, account name, and any CRM data available.

---

## Output Format

### Executive Summary
2–3 sentences capturing who this person is, what they primarily use PostHog for, and the single most interesting or actionable thing about their usage. Write it as if briefing someone before a call with this user.

---

### Profile
- Name, email, role/title, LinkedIn (if available)
- Location (from timezone or geo data)
- Account they belong to

### Activity Summary (last {days} days)
- Total events, key event types
- How many queries run, insights viewed, dashboards checked, exports done

### Where They Spend Time
- Which PostHog projects (extract project IDs from URLs)
- Which product areas (analytics, replay, flags, LLM analytics, data management, error tracking, etc.)
- Specific dashboards or insights they revisit

### What They're Doing
- Interpret the insight names and patterns — what business questions are they answering?
- Are they building things (creating insights, actions, destinations) or consuming (viewing dashboards, exporting)?
- Error tracking: are they actively triaging errors (resolving, assigning, suppressing) or just browsing?

### Session Recordings
- Link directly to PostHog session replay filtered to this user:
  `https://us.posthog.com/replay?filters={"type":"AND","values":[{"type":"AND","values":[{"key":"email","value":["{email}"],"operator":"exact","type":"person"}]}]}`
- Summarise any patterns from the replays they've watched (query 4): which parts of the product, how recently

### PostHog AI Usage
- How often do they open Max (`$conversations_loaded` count) and make AI calls (`$ai_generation` count)?
- Do they use insight analysis (`insight analyzed`)?
- Summarise the top contexts from query 7 where they open Max, with counts.
- Are they looking at LLM Analytics?

### Outreach Angles
- Based on their usage, suggest 2-3 conversation starters for the user's outreach
- Flag any pain points (query failures, rage clicks, error tracking spikes, etc.)
- Note any products they're NOT using that would be relevant

---

## Important
- Ask for the time window **before** running any queries.
- Use the PostHog MCP `query-run` tool, NOT curl. Fall back to curl only if MCP is unavailable.
- Vitally `lastSeenTimestamp` data is stale — do NOT rely on it for activity. Always use PostHog event data.
- Run all PostHog queries in parallel to save time.
- If PostHog returns 503 (busy), wait a moment and retry once before giving up on that query.
- The session replay link should use the user's actual email in the filter parameter.
