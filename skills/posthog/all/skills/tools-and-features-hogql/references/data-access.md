# Accessing data using SQL - Docs

## Strings and quotes

Quotation symbols work the same way they would work with ClickHouse, which inherits from ANSI SQL:

-   **S**ingle quotes (`'`) for **S**trings literals.
-   **D**ouble quotes (`"`) and **B**ackticks (\`) for **D**ata**B**ase identifiers.

For example:

SQL

[Run in PostHog](https://us.posthog.com/sql?open_query=SELECT+*+FROM+events+WHERE+properties.%60%24browser%60+%3D+'Chrome')

PostHog AI

```sql
SELECT * FROM events WHERE properties.`$browser` = 'Chrome'
```

## Types

Types (and names) for the accessible data can be found in the [database](https://us.posthog.com/data-management/database), [properties](https://us.posthog.com/data-management/properties) tabs in data management as well as in the [SQL tab](https://us.posthog.com/sql) for external sources. They include:

-   `STRING` (default)
-   `JSON` (accessible with dot or bracket notation)
-   `DATETIME`(in `ISO 8601`, [read more in our data docs](/docs/data/timestamps.md))
-   `INTEGER`
-   `FLOAT`
-   `BOOLEAN`

For example:

SQL

[Run in PostHog](https://us.posthog.com/sql?open_query=SELECT+round%28properties.%24screen_width+*+properties.%24screen_height+%2F+1000000%2C+2%29+as+%60Screen+MegaPixels%60+FROM+events+LIMIT+100)

PostHog AI

```sql
SELECT round(properties.$screen_width * properties.$screen_height / 1000000, 2) as `Screen MegaPixels` FROM events LIMIT 100
```

This works because `$screen_width` and `$screen_height` are both defined as numeric properties. Thus you can multiply them.

To cast a string property into a different type, use type conversion functions, such as`toString`, `toDate`, `toFloat`, `JSONExtractString`, `JSONExtractInt`, and more.

## Property access

To access a property stored on an event or person, just use dot notation. For example `properties.$browser` or `person.properties.$initial_browser`. You can also use bracket notation like `properties['$feature/cool-flag']`.

Nested property or JSON access, such as `properties.$some.nested.property`, works as well.

> PostHog's properties include always include `$` as a prefix, while custom properties do not (unless you add it).

Property identifiers must be known at query time. For dynamic access, use the JSON manipulation functions from below on the `properties` field directly.

Some queries can error when accessing null values. To avoid this, use the `COALESCE` function to replace null values with a default value or filter `NULL` values with `IS NOT NULL` and use `assumeNotNull` to cast a column to a non-null type.

## Actions

To use [actions](/docs/data/actions.md) in SQL insights, use the `matchesAction()` function. For example, to get a count of the action `clicked homepage button`, you can do:

SQL

[Run in PostHog](https://us.posthog.com/sql?open_query=SELECT+count%28%29+%0AFROM+events+%0AWHERE+matchesAction%28'clicked+homepage+button'%29)

PostHog AI

```sql
SELECT count()
FROM events
WHERE matchesAction('clicked homepage button')
```

For more customization when using actions, start by selecting you action in the [actions tab](https://us.posthog.com/data-management/actions) under data management.

In the action details under "Matching events," click the export dropdown and select "Edit SQL directly."

![Action SQL](https://res.cloudinary.com/dmukukwp6/image/upload/v1714065991/posthog.com/contents/images/docs/product-analytics/action-sql-light.png)![Action SQL](https://res.cloudinary.com/dmukukwp6/image/upload/v1714065992/posthog.com/contents/images/docs/product-analytics/action-sql-dark.png)

This opens an SQL insight using the action. You can then copy parts of the SQL, like the `WHERE` filter or columns under `SELECT`, to use in your own insights.

## Cohorts

To use [cohorts](/docs/data/cohorts.md) in SQL insights, simply filter where `person_id IN COHORT '{name}'`.

For example, to get a count of users in the `Power user` cohort:

SQL

[Run in PostHog](https://us.posthog.com/sql?open_query=select+count%28%29%0Afrom+persons%0Awhere+id+IN+COHORT+'Power+users')

PostHog AI

```sql
select count()
from persons
where id IN COHORT 'Power users'
```

To get a count of events for users in the `Power user` cohort:

SQL

[Run in PostHog](https://us.posthog.com/sql?open_query=select+count%28%29%0Afrom+events%0Awhere+person_id+IN+COHORT+'Power+user')

PostHog AI

```sql
select count()
from events
where person_id IN COHORT 'Power user'
```

### Community questions

Ask a question

### Was this page useful?

HelpfulCould be better