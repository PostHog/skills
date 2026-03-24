# SQL variables - Docs

SQL variables enable you to dynamically set values in your queries.

## Creating SQL variables

To create a variable, go to the [SQL editor](https://app.posthog.com/sql) and click the **Variables** button in the top right toolbar. Start typing in your variable name, if it doesn't exist already, select **New variable** and create it. The variable is now available in any of your project's queries.

For example, you can create a List type variable with the code name `event_names` and add events like `$pageview` and `$autocapture` as values.

![SQL variables dropdown in the toolbar](https://res.cloudinary.com/dmukukwp6/image/upload/w_1600,c_limit,q_auto,f_auto/variables_light_df4c72760f.png)![SQL variables dropdown in the toolbar](https://res.cloudinary.com/dmukukwp6/image/upload/w_1600,c_limit,q_auto,f_auto/variables_dark_f924568cd4.png)

## Using variables in SQL queries

Once created, variables can be used in queries with the `{variables.<variable-name>}` syntax like this:

SQL

[Run in PostHog](https://us.posthog.com/sql?open_query=select+*+%0Afrom+events+%0Awhere+event+%3D+%7Bvariables.event_names%7D)

PostHog AI

```sql
select *
from events
where event = {variables.event_names}
```

You can set the value for the variable in the **Variables** dropdown. For example, below we set the "event names" variable to `$autocapture` on a dashboard. This means every instance of `{variables.event_names}` in the queries on the dashboard is replaced with `$autocapture`.

![Using a variable in a SQL query](https://res.cloudinary.com/dmukukwp6/image/upload/w_1600,c_limit,q_auto,f_auto/Clean_Shot_2025_10_02_at_17_12_45_2x_0e6a9a873a.png)![Using a variable in a SQL query](https://res.cloudinary.com/dmukukwp6/image/upload/w_1600,c_limit,q_auto,f_auto/Clean_Shot_2025_10_02_at_17_12_27_2x_b5f9fcff28.png)

## Dashboard date range filter variables

Beyond the SQL variables you set up, you can access the dashboard's date range filters through the `filters.dateRange.from` and `filters.dateRange.to` variables like this:

SQL

[Run in PostHog](https://us.posthog.com/sql?open_query=select+*+%0Afrom+events+%0Awhere+event+%3D+%7Bvariables.event_names%7D%0Aand+timestamp+%3E%3D+%7Bfilters.dateRange.from%7D+and+timestamp+%3C+%7Bfilters.dateRange.to%7D)

PostHog AI

```sql
select *
from events
where event = {variables.event_names}
and timestamp >= {filters.dateRange.from} and timestamp < {filters.dateRange.to}
```

![Using dashboard filter variables in a SQL query](https://res.cloudinary.com/dmukukwp6/image/upload/w_1600,c_limit,q_auto,f_auto/Clean_Shot_2025_10_02_at_17_16_57_2x_161c9b6f38.png)![Using dashboard filter variables in a SQL query](https://res.cloudinary.com/dmukukwp6/image/upload/w_1600,c_limit,q_auto,f_auto/Clean_Shot_2025_10_02_at_17_17_11_2x_a670c7930a.png)

### Community questions

Ask a question

### Was this page useful?

HelpfulCould be better