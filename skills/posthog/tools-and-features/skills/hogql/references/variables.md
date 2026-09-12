> AI agents: this is one page from PostHog's docs. Full index of Markdown docs for LLMs: https://posthog.com/llms.txt

# SQL variables - Docs

Copy page

# SQL variables - Docs

SQL variables enable you to dynamically set values in your queries.

## Creating SQL variables

To create a variable, go to the [SQL editor](https://app.posthog.com/sql) and click the **Variables** button in the top right toolbar. Start typing in your variable name, if it doesn't exist already, select **New variable** and create it. The variable is now available in any of your project's queries.

For example, you can create a List type variable with the code name `event_names` and add events like `$pageview` and `$autocapture` as values.

![SQL variables dropdown in the toolbar](https://res.cloudinary.com/dmukukwp6/image/upload/w_1600,c_limit,q_auto,f_auto/variables_light_df4c72760f.png)![SQL variables dropdown in the toolbar](https://res.cloudinary.com/dmukukwp6/image/upload/w_1600,c_limit,q_auto,f_auto/variables_dark_f924568cd4.png)

## Using variables in SQL queries

Once created, variables can be used in queries with the `{variables.<variable-name>}` syntax like this:

SQL

[Run in PostHog](https://us.posthog.com/sql?open_query=select+*%0Afrom+events%0Awhere+event+%3D+%7Bvariables.event_names%7D)

PostHog AI

```sql
select *
from events
where event = {variables.event_names}
```

You can set the value for the variable in the **Variables** dropdown. For example, below we set the "event names" variable to `$autocapture` on a dashboard. This means every instance of `{variables.event_names}` in the queries on the dashboard is replaced with `$autocapture`.

![Using a variable in a SQL query](https://res.cloudinary.com/dmukukwp6/image/upload/w_1600,c_limit,q_auto,f_auto/Clean_Shot_2025_10_02_at_17_12_45_2x_0e6a9a873a.png)![Using a variable in a SQL query](https://res.cloudinary.com/dmukukwp6/image/upload/w_1600,c_limit,q_auto,f_auto/Clean_Shot_2025_10_02_at_17_12_27_2x_b5f9fcff28.png)

## Applying dashboard filters

Adding the `{filters}` placeholder to your query's `where` clause applies the dashboard or insight date range, property filters, and test account filtering to your query:

SQL

[Run in PostHog](https://us.posthog.com/sql?open_query=select+*%0Afrom+events%0Awhere+event+%3D+'%24pageview'%0Aand+%7Bfilters%7D)

PostHog AI

```sql
select *
from events
where event = '$pageview'
and {filters}
```

This works when selecting from PostHog tables: `events`, `sessions`, `persons`, `groups`, logs, and traces. The date range applies to `timestamp` on events, logs, and traces, to `$start_timestamp` on sessions, and to `created_at` on groups and persons.

Property filters resolve in the scope that fits the table. A query selecting only from `persons` takes person properties. Event properties show an error, because the query has no events to filter. A query that joins `persons` to `events` keeps event behavior: the date range applies to `timestamp` and properties resolve in event scope.

If person scope isn't what you want, bind the columns yourself instead.

### Binding filters to columns

For any other table, view, or join (or to override the defaults above), tell PostHog which of your columns each filter applies to by binding them:

SQL

[Run in PostHog](https://us.posthog.com/sql?open_query=select+*%0Afrom+my_revenue_view%0Awhere+%7Bfilters%28day+AS+timestamp%2C+account_id+AS+'account_id'%29%7D)

PostHog AI

```sql
select *
from my_revenue_view
where {filters(day AS timestamp, account_id AS 'account_id')}
```

Each argument binds one of your query's expressions to a filter key with `AS`:

-   The reserved key `timestamp` receives the date range.
-   Any other key, written as a string like `'plan'`, receives the dashboard and insight property filters on that key. Operators and multiple values work like they do elsewhere in PostHog.
-   `null AS key` opts the query out of filtering on that key. For example, `null AS timestamp` opts out of date filtering.

If a filter is active but not bound, the query shows an error instead of silently ignoring the filter. This way a filtered dashboard never shows unfiltered data. Cohort filters and SQL expression filters can't be bound and show an error too.

[Test account filtering](/docs/product-analytics/trends/filters.md#filtering-internal-and-test-users) works the same way: when it's on for the insight, or forced on by the dashboard's own toggle, the properties your test account filters use need bindings too.

### Applying the dashboard interval

Use `{filters.interval}` where a time unit goes, for example in `dateTrunc`:

SQL

[Run in PostHog](https://us.posthog.com/sql?open_query=select+dateTrunc%28%7Bfilters.interval%28'week'%29%7D%2C+timestamp%29+as+period%2C+count%28%29+as+event_count%0Afrom+events%0Awhere+%7Bfilters%7D%0Agroup+by+period%0Aorder+by+period)

PostHog AI

```sql
select dateTrunc({filters.interval('week')}, timestamp) as period, count() as event_count
from events
where {filters}
group by period
order by period
```

The placeholder becomes the dashboard's interval as a string constant, like `'week'`. The argument sets your default for when the dashboard doesn't set an interval. Without an argument, the default is `'day'`. Valid intervals are `second`, `minute`, `hour`, `day`, `week`, `month`, `quarter`, and `year`.

### Applying the dashboard breakdown

When the dashboard sets a breakdown, `{filters.breakdown(...)}` becomes the expression you bound to that breakdown key:

SQL

[Run in PostHog](https://us.posthog.com/sql?open_query=select+%7Bfilters.breakdown%28properties.plan+AS+'plan'%29%7D+as+breakdown%2C+count%28%29+as+event_count%0Afrom+events%0Awhere+%7Bfilters%7D%0Agroup+by+breakdown)

PostHog AI

```sql
select {filters.breakdown(properties.plan AS 'plan')} as breakdown, count() as event_count
from events
where {filters}
group by breakdown
```

Bindings work like the column-bound form above: bind an expression to each breakdown key you support, or `null AS 'plan'` to opt out of one. Without a breakdown set, the placeholder becomes `null` and the query returns a single group, so it still runs outside the dashboard. A breakdown on an unbound key shows an error.

The placeholder supports a single plain breakdown. Cohort breakdowns, numeric binning, and multiple breakdowns show an error. The breakdown value shows up as a regular column in your results. Chart series don't split on it automatically.

The filter placeholders combine. This query takes its date range, property filters, interval, and breakdown from the dashboard:

SQL

[Run in PostHog](https://us.posthog.com/sql?open_query=select+dateTrunc%28%7Bfilters.interval%28'week'%29%7D%2C+day%29+as+period%2C%0A+++++++%7Bfilters.breakdown%28account_plan+AS+'plan'%29%7D+as+breakdown%2C%0A+++++++count%28%29+as+order_count%0Afrom+my_revenue_view%0Awhere+%7Bfilters%28day+AS+timestamp%2C+account_id+AS+'account_id'%29%7D%0Agroup+by+period%2C+breakdown)

PostHog AI

```sql
select dateTrunc({filters.interval('week')}, day) as period,
       {filters.breakdown(account_plan AS 'plan')} as breakdown,
       count() as order_count
from my_revenue_view
where {filters(day AS timestamp, account_id AS 'account_id')}
group by period, breakdown
```

## Dashboard date range filter variables

Beyond the SQL variables you set up, you can access the dashboard's date range filters through the `filters.dateRange.from` and `filters.dateRange.to` variables like this:

SQL

[Run in PostHog](https://us.posthog.com/sql?open_query=select+*%0Afrom+events%0Awhere+event+%3D+%7Bvariables.event_names%7D%0Aand+timestamp+%3E%3D+%7Bfilters.dateRange.from%7D+and+timestamp+%3C+%7Bfilters.dateRange.to%7D)

PostHog AI

```sql
select *
from events
where event = {variables.event_names}
and timestamp >= {filters.dateRange.from} and timestamp < {filters.dateRange.to}
```

![Using dashboard filter variables in a SQL query](https://res.cloudinary.com/dmukukwp6/image/upload/w_1600,c_limit,q_auto,f_auto/Clean_Shot_2025_10_02_at_17_16_57_2x_161c9b6f38.png)![Using dashboard filter variables in a SQL query](https://res.cloudinary.com/dmukukwp6/image/upload/w_1600,c_limit,q_auto,f_auto/Clean_Shot_2025_10_02_at_17_17_11_2x_a670c7930a.png)

## How date ranges are resolved

When you use `{filters.dateRange.from}`, `{filters.dateRange.to}`, or `{filters}`, PostHog resolves date values with day-level semantics to match how other insight types handle date ranges:

-   **Relative day-or-coarser `date_from` values** like `mStart` (start of month), `-7d` (last 7 days), or `wStart` (start of week) snap to the **start of the day** (midnight). This honors your project's week start day setting.
-   **Open-ended ranges** (where `date_to` is not set, like "This month" or "Last 7 days") resolve `date_to` to the **end of today**, preventing future-dated rows from being included.
-   **Date-only `date_to` values** (like `2024-01-15`) snap to the **end of that day**.

**Exceptions:**

-   **Explicit datetimes** (like `2024-01-15T14:30:00`) are used exactly as provided.
-   **Sub-day rolling windows** (like `-1h` or `-30M`) keep their exact timestamps and remain open-ended.
-   **"All time"** (`date_from="all"`) remains fully unbounded with no upper or lower limits.

When using the `{filters}` placeholder, snapped end-of-day upper bounds are compared inclusively (`<=`) while explicit datetime bounds use strict `<`.

### Still have questions?

Ask PostHog AI

### Was this page useful?

HelpfulCould be better