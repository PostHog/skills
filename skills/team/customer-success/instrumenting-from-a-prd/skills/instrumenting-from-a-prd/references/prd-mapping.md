# Mapping a PRD to measures

## The measurability test

A success metric is measurable when it names four parts.

| Part | Example | If the part is missing |
|---|---|---|
| Population | "new workspaces created after launch" | Ask who counts |
| Action or state | "have 3 or more members" | Ask which behavior proves success |
| Window | "within 14 days of creation" | Propose a window that fits how often people use the product |
| Target | "45%, up from 35%" | Ask for a target. Without one, the number cannot tell the PM to keep, change or stop the feature |

"Users love the new invite flow" fails all four parts. "Increase invites" passes one part at most.

## Metric shapes

| Shape | PRD wording | PostHog insight | Needs |
|---|---|---|---|
| Conversion | "60% of users who start setup finish it" | Funnel | Start event, finish event, window |
| Time to complete | "cut time to first report to under 5 minutes" | Funnel, time to convert | Start event, end event |
| Volume | "double the number of exports" | Trends, total count | One event |
| Reach | "30% of weekly active users try X" | Trends formula: users who did X / active users | One event, plus the team's active-user definition |
| Frequency | "users use X 3 days a week" | Stickiness | One event |
| Retention | "users still use X after 4 weeks" | Retention | Start event, return event |
| Account adoption | "50 accounts adopt X" | Trends, unique groups | One event, sent with the account group |
| Failure rate | "fewer failed imports" | Trends formula: failures / attempts | Attempt and failure events, or one event with a status property |
| Revenue | "upgrades from the banner add $20k MRR" | Trends, sum of an amount property; or a funnel to the upgrade | A server-side payment event with amount and currency |
| Sentiment | "users find it easy" | A PostHog survey, not an event | A PM decision: a survey, or a behavior that stands in for it |

When a metric fits two shapes, pick the one that matches the decision the PM wants to make, and note the other.

## Unit: people or accounts

If the PRD counts accounts, companies, workspaces, teams or organizations, the unit is a group. PostHog measures groups with group analytics: each event carries the group's ID, and insights count unique groups instead of unique people.

Check that the project has group types (see `posthog-check.md`). If it has none, say what that costs: the plan can still send the account ID as a property, but funnels and retention will count people, not accounts.

Explain it to the PM in one sentence, for example: "Your metric counts workspaces, not people, so each event must say which workspace it belongs to."

## Baseline

A relative target ("from 35% to 45%") needs today's number. If the events do not exist yet, nobody measured the 35%. Write a PM question that asks where the number came from. Offer two answers: measure the baseline for two weeks before the rollout, or use a stand-in from data that PostHog already has.

## Guardrails

Map guardrail metrics the same way, at a lower priority. A guardrail often has an event already, such as errors, support tickets or cancellations. Reuse it.

## Rollout and experiments

- **Feature flag:** split every success insight by the flag value, so that the PM can compare people with and without the feature. Take the flag key from the PRD. If the PRD gives none, ask the engineer.
- **Experiment:** if the PRD asks for an A/B test, the success metric becomes the experiment's primary metric. The plan lists the events. The experiment setup is outside this skill.
- **Beta for named customers:** plan a cohort or a flag for that list, and ask which one the team uses.
- **Exposure:** the code must read the flag only where the feature can appear. If the code reads it on every page, every user counts as exposed, and the measured effect gets smaller than the real one.
- **After full rollout:** when the flag reaches 100%, the comparison group is gone. Later numbers are a before and after comparison, which cannot separate the feature from a season, a pricing change or a marketing push. Ask the PM whether they need proof that the feature caused the change. If they do, propose a holdout, for example 10% without the feature, until the readout.
- **Sample size:** estimate whether the rollout can show the target. Count the units in each group during the rollout window, from the event volumes you read in step 3. If the groups are too small, say so plainly, and name the options: run longer, give the feature to a larger share, or accept that only a bigger change will show.

## Stories

For each story, find the one step that a metric needs. Usually it is the moment when the user's intent becomes a saved fact: the invite is sent, the report is generated, the payment succeeds.

A story that feeds no metric needs no event. Write "no event needed: no metric depends on it". Do not add events "just in case". Each one costs money and makes the event list harder to search.

## Writing PM questions

- One gap per question. Ask 5 questions at most, and merge the small ones.
- Give each question a proposed answer, and say what the answer changes.
- Write for the PM. Use no PostHog term that you did not define.
- Base a proposed answer on data only when you read that data. Otherwise give the reason from the PRD or from common practice, and say which one it is.

Example:

> **Q2. Which window counts as success?** The PRD says "reach 3 members" but gives no time limit. Proposed: within 14 days of workspace creation, because the PRD's onboarding goal covers the first two weeks. A longer window makes the number higher, but you wait longer to read it after launch.
