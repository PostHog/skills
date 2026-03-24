# Useful SQL functions - Docs

Our SQL flavor includes many functions to aggregate and manipulate queried data. Below are some examples of some of the most popular SQL functions you can use in your insights.

## Aggregate functions

These aggregate results for columns across all rows. They include:

-   `avg()`: Calculates the average numeric value of a column.
-   `sum()`: Calculates the total (sum) numeric value of a column.
-   `max()`, `min()`: Finds the maximum or minimum value of a column.

SQL

[Run in PostHog](https://us.posthog.com/sql?open_query=SELECT+%0A+++avg%28properties.%24screen_height%29%2C+%0A+++sum%28properties.%24screen_height%29%2C+%0A+++max%28properties.%24screen_height%29%2C+%0A+++min%28properties.%24screen_height%29%0AFROM+events%0AWHERE+event+%3D+'%24pageview'+AND+properties.%24screen_height+IS+NOT+NULL)

PostHog AI

```sql
SELECT
   avg(properties.$screen_height),
   sum(properties.$screen_height),
   max(properties.$screen_height),
   min(properties.$screen_height)
FROM events
WHERE event = '$pageview' AND properties.$screen_height IS NOT NULL
```

You can find a full list of these in [supported aggregations](/docs/sql/aggregations.md).

### Count

Use `count()` to count the number of rows in a particular column. `count(*)` counts all rows, while `count(column_name)` counts the number of non-null values in a column.

## Regular functions

Our SQL flavor provides many functions for accessing, modifying, and calculating data from queries. Along with the ones listed below, many basics include calculation operators (`+`, `-`, `/`, `*`), type conversions (`toInt`, `toString`), conditional statements (`if`, `multiIf`), and rounding (`floor`, `round`).

You can find a full list of these in [supported ClickHouse functions](/docs/sql/clickhouse-functions.md).

### Date and time

-   `now()`, `today()`, `yesterday()`: Returns the current time, date, or yesterday’s date respectively.
-   `interval`: A length of time for use in arithmetic operations with other dates and times.
-   `toDayOfWeek`, `toHour`, `toMinute`: Converts date number of day of week (1-7), hour in 24-hour time (0-23), and minute in hour (0-59).
-   `toStartOfYear`, `toStartOfMonth`, `toMonday`, `toStartOfDay`, `toStartOfMinute`: rounds date down to the nearest year, month, Monday, day, hour, or minute respectively
-   `dateDiff('unit', startdate, enddate)`: Returns the count in `unit` between `startdate` and `enddate`.
-   `formatDateTime`: Formats a time according to a [MySQL datetime format string](https://dev.mysql.com/doc/refman/8.0/en/date-and-time-functions.html#function_date-format).
-   `parseDateTimeBestEffort`: Converts most human-readable dates into a datetime.

SQL

[Run in PostHog](https://us.posthog.com/sql?open_query=SELECT+%0A+++formatDateTime%28now%28%29%2C+'%25a+%25b+%25T'%29+AS+current_time%2C%0A+++toDayOfWeek%28now%28%29%29+AS+current_day_of_week%2C%0A+++dateDiff%28'day'%2C+timestamp%2C+now%28%29%29+AS+days_since_event%2C%0A+++parseDateTimeBestEffort%28'4-Dec-2023'%29+AS+converted_date%0AFROM+events%0AWHERE+timestamp+%3E+now%28%29+-+interval+1+day)

PostHog AI

```sql
SELECT
   formatDateTime(now(), '%a %b %T') AS current_time,
   toDayOfWeek(now()) AS current_day_of_week,
   dateDiff('day', timestamp, now()) AS days_since_event,
   parseDateTimeBestEffort('4-Dec-2023') AS converted_date
FROM events
WHERE timestamp > now() - interval 1 day
```

If you want to access dashboard or insight date filters, you can use the [variables](/docs/data-warehouse/sql/variables.md) `filters.dateRange.from` and `filters.dateRange.to`.

> Read more examples in [How to do time-based breakdowns (hour, minute, real time)](/tutorials/time-breakdowns.md) and [Using SQL for advanced time and date filters](/tutorials/hogql-date-time-filters.md).

### String

-   `extract`: Extracts a fragment of a string using a regular expression.
-   `concat`: Concatenates strings listed without separator.
-   `splitByChar`, `splitByString`, `splitByRegexp`, `splitByWhitespace`: splits a string into substring separated by a specified character, string, regular expression, or whitespace character respectively.
-   `match`: Return whether the string matches a regular expression pattern.
-   `replaceOne`, `replaceRegexpOne`: Replace the first occurrence of matching a substring or regular expression pattern respectively with a replacement string.
-   `trim`: Remove specified characters (or whitespace) from the start or end of a string.
-   `upper`, `lower`: Converts a string to uppercase or lowercase.

SQL

[Run in PostHog](https://us.posthog.com/sql?open_query=select+%0A+++extract%28elements_chain%2C+'%5B%3A%7C%22%5Dattr__class%3D%22%28.*%3F%29%22'%29+as+class_name%2C%0A++++concat%28properties.%24os%2C+'+version%3A+'%2C+properties.%24os_version%29%2C%0A++++replaceRegexpOne%28properties.%24current_url%2C+'%5E%2F'%2C+'site%2F'%29+AS+modified_current_url%0Afrom+events%0Awhere+event+%3D+'%24autocapture')

PostHog AI

```sql
select
   extract(elements_chain, '[:|"]attr__class="(.*?)"') as class_name,
    concat(properties.$os, ' version: ', properties.$os_version),
    replaceRegexpOne(properties.$current_url, '^/', 'site/') AS modified_current_url
from events
where event = '$autocapture'
```

> Read more in [How to analyze autocapture events with SQL](/tutorials/hogql-autocapture.md).

### JSON

You can access nested data in JSON and objects directly.

SQL

[Run in PostHog](https://us.posthog.com/sql?open_query=select+properties.%24set.%24geoip_country_name%0Afrom+events)

PostHog AI

```sql
select properties.$set.$geoip_country_name
from events
```

You can parse JSON with `JSONExtractRaw()` to return a value.

SQL

[Run in PostHog](https://us.posthog.com/sql?open_query=SELECT%0A++JSONExtractRaw%28properties.%24set%29+as+set_properties%0AFROM+events%0AWHERE+properties.%24set+IS+NOT+NULL)

PostHog AI

```sql
SELECT
  JSONExtractRaw(properties.$set) as set_properties
FROM events
WHERE properties.$set IS NOT NULL
```

Specialized `JSONExtract` functions exist for different data types including:

-   `JSONExtractFloat`
-   `JSONExtractArrayRaw`
-   `JSONExtractString`
-   `JSONExtractBool`

### Array

-   `arrayElement(arr, n)`: Retrieves the element with the index of n from the array `arr`.
-   `arrayJoin(arr)`: Takes a row and generates multiple rows for the number of elements in the array. It copies all the column values, except the column where this function is applied. It replaces the applied column with the corresponding array value.

SQL

[Run in PostHog](https://us.posthog.com/sql?open_query=SELECT+flag%2C+count%28%29%0AFROM+%28%0A+++SELECT+arrayJoin%28JSONExtractArrayRaw%28assumeNotNull%28properties.%24active_feature_flags%29%29%29+as+flag%0A+++FROM+events%0A+++WHERE+event+%3D+'%24pageview'+and+timestamp+%3E+'2023-08-01'%0A%29%0AGROUP+BY+flag%0AORDER+BY+count%28%29+desc)

PostHog AI

```sql
SELECT flag, count()
FROM (
   SELECT arrayJoin(JSONExtractArrayRaw(assumeNotNull(properties.$active_feature_flags))) as flag
   FROM events
   WHERE event = '$pageview' and timestamp > '2023-08-01'
)
GROUP BY flag
ORDER BY count() desc
```

> Read more in [How to filter and breakdown arrays with SQL](/tutorials/array-filter-breakdown.md).

### Sparkline

A sparkline is a tiny graph contained in one cell of your query result. As an argument, it takes an array of integers.

SQL

[Run in PostHog](https://us.posthog.com/sql?open_query=SELECT+sparkline%28range%281%2C+10%29%29+FROM+%28SELECT+1%29)

PostHog AI

```sql
SELECT sparkline(range(1, 10)) FROM (SELECT 1)
```

You can use it to visualize queries, such as a 24-hour `$pageview` count for different `$current_url` values.

SQL

[Run in PostHog](https://us.posthog.com/sql?open_query=SELECT%0A++++pageview%2C%0A++++sparkline%28arrayMap%28h+-%3E+countEqual%28groupArray%28hour%29%2C+h%29%2C+range%280%2C23%29%29%29%2C%0A++++count%28%29+as+pageview_count%0AFROM%0A%28%0A++++SELECT%0A++++++++properties.%24current_url+as+pageview%2C%0A++++++++toHour%28timestamp%29+AS+hour%0A++++FROM%0A++++++++events%0A++++WHERE%0A+++++++++timestamp+%3E+now+%28%29+-+interval+1+day%0A+++++++++and+event+%3D+'%24pageview'%0A%29+subquery%0AGROUP+BY%0A++++pageview%0AORDER+BY%0A++++pageview_count+desc)

PostHog AI

```sql
SELECT
    pageview,
    sparkline(arrayMap(h -> countEqual(groupArray(hour), h), range(0,23))),
    count() as pageview_count
FROM
(
    SELECT
        properties.$current_url as pageview,
        toHour(timestamp) AS hour
    FROM
        events
    WHERE
         timestamp > now () - interval 1 day
         and event = '$pageview'
) subquery
GROUP BY
    pageview
ORDER BY
    pageview_count desc
```

You can also use it for art.

SQL

[Run in PostHog](https://us.posthog.com/sql?open_query=select+%0A++++sparkline%28arrayMap%28a+-%3E+cos%28toSecond%28timestamp%29+%2B+a%2F4%29%2C+range%28100+%2B+5+*+toSecond%28timestamp%29%29%29%29+%0Afrom+events)

PostHog AI

```sql
select
    sparkline(arrayMap(a -> cos(toSecond(timestamp) + a/4), range(100 + 5 * toSecond(timestamp))))
from events
```

### SemVer

If you have a SemVer version number, you can use the `sortableSemVer()` function to get a version number that you can use for sorting purposes.

SELECT DISTINCT properties.$lib\_version FROM events WHERE event = '$pageview' AND timestamp >= now() - INTERVAL 1 DAY ORDER BY sortableSemVer(properties.$lib\_version) DESC LIMIT 10

### Session replays

You can create a button to view the replay for a session by using the `recordingButton()` function with the `session_id`. For example, to get a list of recent replays, you can use:

SQL

[Run in PostHog](https://us.posthog.com/sql?open_query=SELECT%0A++++person.properties.email%2C%0A++++min_first_timestamp+AS+start%2C%0A++++recordingButton%28session_id%29%0AFROM%0A++++raw_session_replay_events%0AWHERE%0A++++min_first_timestamp+%3E%3D+now%28%29+-+INTERVAL+1+DAY%0A++++AND+min_first_timestamp+%3C%3D+now%28%29%0AORDER+BY%0A++++min_first_timestamp+DESC%0ALIMIT+10)

PostHog AI

```sql
SELECT
    person.properties.email,
    min_first_timestamp AS start,
    recordingButton(session_id)
FROM
    raw_session_replay_events
WHERE
    min_first_timestamp >= now() - INTERVAL 1 DAY
    AND min_first_timestamp <= now()
ORDER BY
    min_first_timestamp DESC
LIMIT 10
```

### Actions

You can use actions in SQL by using the `matchesAction()` function with the name of your action. For example, to get a count of the action clicked homepage button, you can do:

SQL

[Run in PostHog](https://us.posthog.com/sql?open_query=SELECT+count%28%29+%0AFROM+events+%0AWHERE+matchesAction%28'clicked+homepage+button'%29)

PostHog AI

```sql
SELECT count()
FROM events
WHERE matchesAction('clicked homepage button')
```

### Translation

You can translate a language code to a language name using the `languageCodeToName()` function. You can see what the mapping looks like [in our codebase](https://github.com/PostHog/posthog/blob/master/posthog/hogql/language_mappings.py)

SQL

[Run in PostHog](https://us.posthog.com/sql?open_query=SELECT%0A++++languageCodeToName%28'en'%29+AS+english%2C+--+English%0A++++languageCodeToName%28'fr'%29+AS+french%2C+--+French%0A++++languageCodeToName%28'pt'%29+AS+portuguese%2C+--+Portuguese%0A++++languageCodeToName%28'ru'%29+AS+russian%2C+--+Russian%0A++++languageCodeToName%28'zh'%29+AS+chinese+--+Chinese)

PostHog AI

```sql
SELECT
    languageCodeToName('en') AS english, -- English
    languageCodeToName('fr') AS french, -- French
    languageCodeToName('pt') AS portuguese, -- Portuguese
    languageCodeToName('ru') AS russian, -- Russian
    languageCodeToName('zh') AS chinese -- Chinese
```

### HTML tags and links

These HTML tags are currently supported, but for security reasons, none of them support attributes right now:

-   `<div>`, `<p>`, `<span>`, `<pre>`, `<code>`
-   `<em>`, `<strong>`, `<b>`, `<i>`, `<u>`
-   `<h1>`, `<h2>`, `<h3>`, `<h4>`, `<h5>`, `<h6>`
-   `<ul>`, `<ol>`, `<li>`
-   `<table>`, `<thead>`, `<tbody>`, `<tr>`, `<th>`, `<td>`
-   `<blockquote>`, `<hr>`

Most useful is the `<a>` tag for creating links. URLs are automatically clickable in the **Table** visualization, but you can also set a custom link using an `<a>` tag.

SQL

[Run in PostHog](https://us.posthog.com/sql?open_query=select+%0A++++properties.%24pathname%2C%0A++++%3Ca+href%3D%7Bf'https%3A%2F%2Fposthog.com%2F%7Bproperties.%24pathname%7D'%7D+target%3D'_blank'%3ELink%3C%2Fa%3E+as+link%0Afrom+events%0Awhere+event+%3D+'%24pageview')

PostHog AI

```sql
select
    properties.$pathname,
    <a href={f'https://posthog.com/{properties.$pathname}'} target='_blank'>Link</a> as link
from events
where event = '$pageview'
```

### Text effects

Plain text is so boring, so we added some text effects to make it cooler. Wrap any text in `<blink>` to make it blink, `<marquee>` to make it horizontally scroll, and `<redacted>` to hide it unless hovered.

SQL

[Run in PostHog](https://us.posthog.com/sql?open_query=select%0A++++%3Cspan%3Eis+this+%3Cblink%3E%7Bevent%7D%3C%2Fblink%3E+real%3F%3C%2Fspan%3E%2C%0A++++%3Cmarquee%3Eso+real%2C+yes!%3C%2Fmarquee%3E%2C%0A++++%3Credacted%3Ebut+this+one+is+hidden%3C%2Fredacted%3E%0Afrom+events)

PostHog AI

```sql
select
    <span>is this <blink>{event}</blink> real?</span>,
    <marquee>so real, yes!</marquee>,
    <redacted>but this one is hidden</redacted>
from events
```

### Community questions

Ask a question

### Was this page useful?

HelpfulCould be better