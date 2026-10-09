# Checking what PostHog already records

## With the PostHog MCP

Recent versions of the PostHog MCP server expose one `exec` tool. It takes commands such as `search <words>`, `info <tool>` and `call <tool> <json>`. Older versions expose one named tool per command. The command names below are the current ones. If a name is not found, `search` for it. Follow the server's own rules too: it asks you to load its skills first and to read the schema before any query.

Read, in this order:

1. **`project-get`:** confirm that the active project is the production project for this product. Ask the user if you are not sure. A check against the wrong project gives confident wrong answers.
2. **`metric-list`:** the governed metric catalog. If an approved metric already defines the PRD's metric, reuse its definition and say so.
3. **`read-data-schema` with `{"query": {"kind": "events"}}`:** all events. Match each needed event by meaning, not by exact name. "invite sent", "invitation_created" and "team:invite_send" can all record the same fact.
4. **`read-data-schema` with `kind: "event_properties"`** for each candidate event: check that the properties the plan needs exist and are filled.
5. **`$lib` values** for each candidate (`kind: "event_property_values"`, property `$lib`): they show which SDK sends the event.
   - `web`: the browser.
   - `posthog-ios`, `posthog-android`, `posthog-react-native`, `posthog-flutter`: a mobile app.
   - `posthog-python`, `posthog-node`, `posthog-ruby`, `posthog-go`, `posthog-php`, `posthog-java` and similar: a server.
6. **`actions-get-all`:** an action can already define a step, for example an autocapture click on the invite button.
7. **Group types:** `execute-sql` on `system.group_type_mappings`.
8. **Volume:** a trends query for the 30-day count of each candidate event. Zero volume means the event is defined but does not fire now.

## Statuses

| Status | Meaning | The plan says |
|---|---|---|
| Exists | Right meaning, right properties, fires from the right place | Reuse it |
| Exists, missing property | Right event, but a needed property is absent or mostly empty | Add the property |
| Exists, wrong place | An outcome sent from the browser, or sent before the save succeeds | Move it (engineer) |
| Exists, other name | Same meaning, but the name breaks the convention | Reuse the name; do not rename a shipped event |
| Missing | Nothing records it | Add an event, or define an action if autocapture covers it |
| Not checked | No PostHog access and no export | Check before the build starts |

## An export from the user

If the user pastes or attaches an export of events, use it in place of the MCP. Write "checked against the export from <source or date>" in the plan. An export can be old, so treat its volumes as approximate.

## History for a shipped feature

- A new custom event has data only from the day it deploys.
- An action on autocapture or pageviews also works on past data, if autocapture was on for that page and the element is easy to identify by stable text or a selector. Check that `$autocapture` events exist for that page before you promise history.
- Tell the PM which metrics have history and which start on the deploy date.

## Do not rename a shipped event

A rename splits the history in two. Keep the old name. If the name must change, rename the event and create an action that matches both names, so that the insight keeps its history.

## Identity check for server events

People who send a server event usually also appear with browser events. If they do not, the server sends a different distinct ID, and funnels that mix browser and server steps break. Run this in `execute-sql`, after you confirm the event names in the schema:

```sql
SELECT count() AS persons, countIf(has_browser = 1) AS also_in_browser
FROM (
  SELECT person_id,
         max(event = '<server_event>') AS has_server,
         max(properties.$lib = 'web') AS has_browser
  FROM events
  WHERE timestamp > now() - INTERVAL 30 DAY
    AND (event = '<server_event>' OR properties.$lib = 'web')
  GROUP BY person_id
)
WHERE has_server = 1
```

Expect less than 100% when some users only use the API or a mobile app. A share near zero means the IDs do not match.
