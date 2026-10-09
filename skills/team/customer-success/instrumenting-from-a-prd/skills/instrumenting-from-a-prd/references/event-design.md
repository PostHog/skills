# Event design

## Glossary for readers new to PostHog

Define each term the first time the plan uses it. Use these definitions.

- **Event:** one record that something happened, with a name and a time.
- **Property:** a detail attached to an event, a person or a group, for example `invite_method: "link"`.
- **Person:** the user an event belongs to. PostHog links events to a person through an ID that the code sends, the distinct ID.
- **Group:** an account, company or workspace that events belong to. A metric that counts accounts needs groups.
- **Action:** a saved definition that combines or renames events, for example "clicked the invite button". An action also works on past data.
- **Autocapture:** browser clicks, form submits and page changes that PostHog records with no extra code.
- **Insight:** a saved chart or number: a trend, funnel, retention table or stickiness chart.
- **Feature flag:** a switch that turns a feature on for some users. Events record which value each user saw.

## Naming

**Detect the existing convention first.** Look at the project's custom events (names that do not start with `$`). If about 70% or more follow one pattern, use that pattern and say which pattern you found. Consistency matters more than any default, because a mixed event list is hard to search.

**Default for a project with no convention** (based on PostHog's product analytics best practices):

- Format: `category:object_action`, lowercase, snake_case.
- `category`: the product area from the PRD, such as `onboarding`, `billing` or `workspace`.
- `object`: the noun the PRD uses, such as `invite`, `report` or `subscription`. Use the PRD's noun, not the code's noun, because the PM reads the insights.
- `action`: a present-tense verb from this list: `create`, `view`, `start`, `complete`, `submit`, `update`, `delete`, `send`, `accept`, `upgrade`, `cancel`, `fail`. Add a verb only with a reason.
- Name the business fact, not the screen element: `workspace:invite_send`, not `settings_page:invite_button_click`. A redesign moves the button, but the fact stays. Put the location in a `source` property.
- Make a variant a property, not a new name: `invite_method: "link"`, not `workspace:link_invite_send`.

## Properties

- Use snake_case. Use `is_` or `has_` for booleans, `_date` or `_timestamp` for dates, `<object>_id` for IDs, and a unit suffix for numbers: `_ms`, `_seconds`, `_usd`, `_count`.
- Give a text property a fixed list of values, for example `invite_method`: `email`, `link`, `slack`. Free text cannot be grouped in a chart.
- Never start a custom property with `$`. PostHog reserves that prefix.
- Put no personal data in event properties: no email, name, phone, address or free-text input. Person details belong on the person, and only if the company's policy allows them.

## Server or browser

| Capture on the server when | Capture in the browser or app when |
|---|---|
| The event is a saved fact: a record created, a payment succeeded, an email sent, a job finished | The event is intent or screen-only: opened, viewed, started, dismissed |
| The step must be counted exactly, for example revenue or a conversion | The step has no server call |

The plain reason for the plan: "Ad blockers and closed tabs drop some browser events. The server records every saved invite."

A server event must belong to the same person as the browser events. Use the same stable user ID that the browser passes to `identify`. Or pass the browser's distinct ID to the server; PostHog's own setup uses an `X-POSTHOG-DISTINCT-ID` request header for this.

## When an event fires

- After the change succeeds, once per change.
- Never on render, in a loop or on a timer.
- If the code retries, send the same event UUID on each try, so that PostHog can drop the duplicate.

## Identity

- Call `identify` at signup and at login, with the same stable user ID the server uses.
- Put first-time facts, such as the signup source, on the person with `$set_once`. Put current state, such as the plan, with `$set`.
- When an anonymous visitor becomes a known user, for example at signup or when an invitee accepts an invite, call `identify` at that moment. PostHog then joins their earlier events to the same person.
- If the product has no login, events stay anonymous. Say so in the plan.

## Events that no person triggers

Some events record something the system did, not something a person did. Handle them by what the event is about.

- **About an account**, for example usage passed 90% of the limit, or a nightly job finished: no person is involved. Send the event with the account group and with `$process_person_profile: false`, so that PostHog creates no person for it. Use a stable distinct ID such as `account_<id>`. Do not send it as the account owner: that person then shows as active and enters funnels for something they did not do. An insight counted per group still works, because the group travels with the event.
- **Sent to a person**, for example a reminder or an email: send it with that person's distinct ID, because a rate per reminder or per email needs to know who received it. Name it as the system's action (`reminder sent`, not `reminder viewed`). Measure active users only with events the person triggers, never with "all events", so that these events do not make anyone look active.

## Groups

Use groups when the metric's unit is an account, workspace, team or organization.

- Browser: call `posthog.group('<group_type>', '<group_id>')` once the account is known.
- Server: pass `groups: {'<group_type>': '<group_id>'}` with each capture call.
- Reuse the group type names the project already has. A project can have at most 5 group types.
- Group analytics can need a paid add-on. If the project has no group types, say what the plan loses without them (see `prd-mapping.md`).

## Feature flags

- The browser SDK adds `$feature/<flag-key>` to events automatically after flags load.
- A server SDK must evaluate the flag and send it with the event, for example `send_feature_flags=True` in Python or `sendFeatureFlags: true` in Node. Otherwise server events cannot be split by the flag.

## Cost

- PostHog bills per event. Estimate each event's monthly volume: people who do the step, times how often each person does it per month.
- Flag any event that fires per keystroke, per scroll, per render, on a timer or in a polling loop. Use autocapture, heatmaps or session replay for that kind of screen detail.
- Prefer one event with a property over several similar events.
