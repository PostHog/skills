# PostHog queries for user deep dive

All queries use `{email}` and `{days}` as parameters. Run all simultaneously via the `query-run` MCP tool.

## 1. Activity overview

Event breakdown excluding PostHog internals:

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

## 2. Page views

Where they spend their time:

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

## 3. Insight details

Which insights and dashboards they view:

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

## 4. Session replay views

Replays they have watched:

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

## 5. Error tracking usage

How they interact with error tracking in PostHog:

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

## 6. PostHog AI usage

Max and insight analysis counts:

```sql
SELECT event, count() as cnt
FROM events
WHERE person.properties.email = '{email}'
  AND event IN ('$ai_generation', '$conversations_loaded', 'insight analyzed', 'chat with data opened')
  AND timestamp >= now() - interval {days} day
GROUP BY event
ORDER BY cnt DESC
```

## 7. Where they open Max

Which pages and contexts they use Max on:

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
