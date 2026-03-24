---
name: tools-and-features-hogql
description: HogQL queries for PostHog analytics
metadata:
  author: PostHog
  version: 1.9.4
---

# HogQL queries for PostHog

This skill helps you write HogQL queries for PostHog analytics. HogQL is PostHog's SQL dialect, a wrapper around ClickHouse SQL with simplified property access and PostHog-specific functions.

## Reference files

- `references/expressions.md` - Sql expressions - docs
- `references/aggregations.md` - Supported aggregations - docs
- `references/clickhouse-functions.md` - Supported clickhouse functions - docs
- `references/data-access.md` - Accessing data using sql - docs
- `references/variables.md` - Sql variables - docs
- `references/useful-functions.md` - Useful sql functions - docs
- `references/posthog.md` - PostHog table schemas (events, persons, groups, sessions)
- `references/sessions.md` - Sessions - docs

Consult the documentation for SQL syntax, available functions, and query patterns.

## Key principles

- **Property access**: Use `properties.$property_name` for event properties and `person.properties.$property_name` for person properties
- **Null handling**: HogQL has simplified null handling compared to raw ClickHouse SQL
- **Filters placeholder**: Use `{filters}` in queries to allow UI-based filtering in PostHog dashboards
- **Aggregations**: Prefer ClickHouse aggregation functions like `count()`, `uniq()`, `avg()`, `sum()`

## Common patterns

### Event queries
```sql
SELECT event, count()
FROM events
WHERE {filters}
GROUP BY event
ORDER BY count() DESC
```

### Property breakdowns
```sql
SELECT properties.$browser AS browser, count()
FROM events
WHERE event = '$pageview' AND {filters}
GROUP BY browser
```

### Person properties
```sql
SELECT person.properties.email, count()
FROM events
WHERE {filters}
GROUP BY person.properties.email
```

## Framework guidelines

- Use properties.$name syntax for event properties, person.properties.$name for person properties
- Use bracket notation for special characters like properties['$feature/cool-flag']
- For cohorts, filter with person_id IN COHORT 'cohort-name'
- For actions, use matchesAction('action-name') in WHERE clauses
- Include {filters} placeholder in WHERE clauses to enable UI-based filtering in dashboards
- Use {variables.name} for reusable SQL variables across dashboards
- Access dashboard date range with {filters.dateRange.from} and {filters.dateRange.to}
- ALWAYS include a time range filter - shorter is faster (e.g., timestamp >= now() - INTERVAL 7 DAY)
- Prefer uniq() over count(distinct) for counting unique values - it's more efficient
- Don't scan the same table multiple times - use materialized views for reusable subsets
- Use timestamp-based pagination instead of OFFSET for large datasets
- Name queries descriptively for easier debugging in query_log
- Use dateTrunc() for time-based grouping (e.g., dateTrunc('day', timestamp))
- For funnel queries, use windowFunnel() or sequenceMatch() functions
- Test queries in the PostHog SQL editor before using them in insights or the API
