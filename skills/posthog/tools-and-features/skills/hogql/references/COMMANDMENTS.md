# Framework rules

Follow these when integrating PostHog into this framework.

- A missing PostHog configuration must never break the app — read keys optionally (never a required setting), guard init and capture behind their presence, and keep build and boot working with no PostHog environment set — but never silently: in development or debug builds fail loudly, using the language's idiomatic error, with the message "<VAR> variable required by PostHog is missing or un-configured, this causes events to be silently missed. This error stops appearing once <VAR> is configured" (substituting the actual variable name); production stays a no-op
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
