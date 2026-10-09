# Analytics plan template

Use this structure for the plan in chat and for the Linear issue body. The sections run in the order a reader needs them: the PM reads the top three, and the engineer reads the rest. Keep table cells short. Put a long reason in one sentence below the table.

```markdown
# Analytics: <feature name>

**PRD:** <link or title>
**Status:** draft, waiting for PM answers | ready to build
**Checked against PostHog:** <project name, date> | an export from <source> | not checked

## Summary
- After this ships, the team can answer: <one or two lines>.
- Waiting on the PM: <n> questions, below.
- Events: <n> reused, <n> changed, <n> new.

## PRD to measures
| PRD item | Measure (PostHog insight) | Events | Status |
|---|---|---|---|
| Metric: "<verbatim>" | Funnel, counted per workspace, 14-day window | a > b > c | Exists / Missing / Not checked |
| Story ENG-412: "<title>" | Feeds the metric above | b {invite_method} | Exists, missing property |
| Story ENG-418: "<title>" | No metric depends on it | No event needed | - |
| Rollout: flag `<key>` | Split each insight by flag value | (flag value on events) | - |

## Questions for the PM
1. **<Question>** <Context>. Proposed: <answer>, because <reason>. <What the answer changes>.

## Events to add or change
| Event | Fires when | Where | Properties | Answers | Why |
|---|---|---|---|---|---|
| `workspace:invite_send` | After the invite is saved, once per invitee | Server | `invite_method` (email, link, slack), `workspace_id` | Metric 1, ENG-412 | Ad blockers drop some browser events; the server records every saved invite |

## What you will see in PostHog
- **<Insight name>:** <type>, <what it shows>, <split by flag or not>.

## Notes for engineering
1. <Identity, groups, flag reads, retries, anything the code must get right.>

## Not checked
- <Anything the plan assumes but did not verify, and how to check it.>

## Terms used in this plan
- **<Term>:** <one-line definition from the glossary in event-design.md>.
```

## Rules for the plan

- Quote each PRD metric verbatim in the first table.
- Every row in "Events to add or change" names at least one PRD item in "Answers".
- Put the terms list last. If a reader needs a term before the list, define it in a few words where it first appears.
- Mark each proposed metric "proposed, needs PM sign-off".
- The status "draft, waiting for PM answers" stays until the PM answers every question that changes an event.
