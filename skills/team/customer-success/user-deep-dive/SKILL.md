---
name: user-deep-dive
description: Deep dive on a PostHog user by email address. Analyze what they do, where they spend time, and what products they use.
---

Deep dive on a PostHog user by email address. Analyse what they do, where they spend time, and what products they use.

**Input**: $ARGUMENTS (email address, e.g. `artis.conka@enlabs.com`)

## Process

### Step 0: Ask for time window

Before running any queries, ask the user:

> "What time window would you like to analyse? (default: last 14 days)"

If they don't respond or say "default", use **14 days**. Use their answer to set `{days}` in all queries below.

---

### Step 1: Run queries in parallel

Run all of the following queries simultaneously via the `query-run` MCP tool.

**1. Activity overview** — event breakdown (excluding PostHog internals):
```sql
SELECT event, count() as cnt
FROM events
WHERE person.properties.email = '{email}'
  AND timestamp >= now() - interval {days} day
  AND event NOT IN (
    '$feature_flag_called',
    '$ai_span',
    '$ai_trace',
    '$autocapture',
    '$web_vitals',
    'react_framerate',
    'spinner_unloaded',
    'replay_parse_timing',
    '$dead_click'
  )
GROUP BY event
ORDER BY cnt DESC
LIMIT 30
```

**2. Page views** — where they spend their time:
```sql
SELECT properties.$current_url as url, count() as cnt
FROM events
WHERE person.properties.email = '{email}'
  AND event = '$pageview'
  AND timestamp >= now() - interval {days} day
GROUP BY url
ORDER BY cnt DESC
LIMIT 25
```

**3. Insight details** — which insights/dashboards they view:
```sql
SELECT properties.insight as insight_type, properties.insight_name as name, count() as views
FROM events
WHERE person.properties.email = '{email}'
  AND event = 'insight viewed'
  AND timestamp >= now() - interval {days} day
GROUP BY insight_type, name
ORDER BY views DESC
LIMIT 20
```

**4. Session replay views** — replays they've watched:
```sql
SELECT
  properties.session_id as session_id,
  properties.$current_url as url,
  timestamp
FROM events
WHERE person.properties.email = '{email}'
  AND event = '$recording_viewed'
  AND timestamp >= now() - interval {days} day
ORDER BY timestamp DESC
LIMIT 20
```

**5. Error tracking usage** — how they interact with error tracking in PostHog:
```sql
SELECT event, properties.issue_id as issue_id, properties.issue_name as issue_name, count() as cnt
FROM events
WHERE person.properties.email = '{email}'
  AND event IN ('error tracking issue viewed', 'error tracking issue resolved', 'error tracking issue assigned', 'error tracking issue suppressed', 'error tracking list viewed')
  AND timestamp >= now() - interval {days} day
GROUP BY event, issue_id, issue_name
ORDER BY cnt DESC
LIMIT 20
```

**6. PostHog AI usage** — Max and insight analysis counts:
```sql
SELECT event, count() as cnt
FROM events
WHERE person.properties.email = '{email}'
  AND event IN ('$ai_generation', '$conversations_loaded', 'insight analyzed', 'chat with data opened')
  AND timestamp >= now() - interval {days} day
GROUP BY event
ORDER BY cnt DESC
```

**7. Where they open Max** — which pages/contexts they use Max on:
```sql
SELECT
  properties.$current_url as url,
  count() as cnt
FROM events
WHERE person.properties.email = '{email}'
  AND event = '$conversations_loaded'
  AND timestamp >= now() - interval {days} day
  AND properties.$current_url LIKE '%posthog.com/project%'
GROUP BY url
ORDER BY cnt DESC
LIMIT 20
```

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
- **Where do they open Max?** — Summarise the URLs from query 7. Extract the product area from each URL (e.g. `/dashboard/` → "dashboards", `/sql` → "SQL editor", `/insights/` → "insights", `/persons/` → "person profiles") and list the top contexts with counts. This tells us what they're trying to get help with.
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