---
name: instrumenting-from-a-prd
description: Turns a feature PRD, usually a Linear project, into a PostHog measurement plan, and with a repo open into the capture code and tests that prove it. Use when a PM or engineer asks how to measure a feature, what to track for a PRD, spec or Linear project, whether current tracking covers a PRD's success metrics, or wants to instrument, retrofit or verify PostHog events for a feature that is planned, half-built or already shipped. Use it even when the request only says "tracking plan", "analytics for ENG-123", "how will we know this worked" or "add PostHog events for this feature". Written for people new to PostHog - it makes the PostHog decisions and explains each one in plain words.
---

# Instrumenting from a PRD

This skill connects a feature's PRD to the PostHog events that measure it. The PM owns the goal. The skill owns the PostHog decisions, and explains them so that a reader who is new to PostHog can review them.

The output is an **Analytics plan**. It links each PRD item to a measure, lists the events to add or change, and asks the PM the questions the PRD does not answer. Engineers then use the same plan to write and verify the code.

## Pick the path

| Who is asking | Repo needed? | Path |
|---|---|---|
| A PM, or anyone who wants to know what to measure | No | Plan: steps 1 to 6 |
| An engineer who builds or fixes the feature | Yes | Plan (or read the existing Analytics issue), then `references/code-modes.md` |

If the request does not make the path clear, start with the plan. Every path needs it, and the plan changes nothing until someone approves a write.

## Rules, and why they matter

1. **The PRD owns the goal.** Quote the PRD's success metrics in the PRD's own words. If a metric cannot be measured as written, do not fix it yourself. Write a question for the PM, and add a proposed metric marked "proposed, needs PM sign-off". A metric the PM did not choose will not drive the PM's decision.
2. **Every event answers a PRD item.** An event that answers no PRD item costs money and adds noise, and teams that are new to PostHog tend to track too much. Cut it, or list it as "extra" when it already exists.
3. **Reuse before you add.** Check what PostHog already records first: custom events, pageviews, and autocapture with actions. Add a custom event only for a business outcome, or for a step that needs properties that autocapture cannot give.
4. **Explain each PostHog decision in one plain sentence.** The reader must be able to defend the plan in a review. Define a PostHog term the first time you use it. The glossary is in `references/event-design.md`.
5. **Read freely. Write only after approval.** A Linear issue or comment, a PostHog insight or dashboard, and a code edit are all writes. Show the exact content first, then wait for a yes.
6. **Say what you did not check.** "Not checked" is useful. A guessed "exists" is harmful. Never say an event exists unless you read it in the PostHog schema or in an export the user gave you.

## Step 1: Read the PRD

Accept any of these: a Linear project, document or issue URL; pasted text; a file. With Linear connected, read the project overview, its documents and its issues. `references/linear.md` covers which Linear tools to use and how to find the PRD among several documents.

Build a PRD inventory. Quote, do not paraphrase:

- **Goal:** the problem, and the outcome the feature wants.
- **Success metrics:** each one verbatim, plus any guardrails, such as "without more support tickets".
- **Stories or flows:** each with its Linear issue ID when one exists.
- **Unit:** what the metric counts: people, or accounts, workspaces, teams or organizations.
- **Rollout:** feature flag, beta percentage, experiment, launch date.
- **Platforms:** web, mobile app, API, background jobs.

Mark a part "not in PRD" when it is missing. A missing part becomes a PM question in step 2.

## Step 2: Turn each PRD item into a measure

Read `references/prd-mapping.md`. For each success metric:

1. Test it. A measurable metric names a population, an action or state, a time window and a target. List the parts that are missing.
2. Find its shape (conversion, volume, reach, frequency, retention, time to complete, account adoption, failure rate, revenue, sentiment) and the PostHog insight that measures that shape.
3. List the events and properties that the insight needs.

For each story, name the one step that a metric needs. A story that feeds no metric needs no event, and the plan says so.

## Step 3: Check what PostHog already records

Read `references/posthog-check.md`. With the PostHog MCP connected, read the project's events, their properties and volumes, the actions, the group types and the governed metric catalog. Give each needed event one status: exists, exists but missing a property, exists in the wrong place, exists under another name, or missing.

If the user gives an export instead, use the export and say so. If you have neither, mark every status "not checked" and continue. The plan is still useful without the check.

For a feature that already shipped, also say which metrics have history, and which start on the day the new events deploy.

## Step 4: Design the events

Read `references/event-design.md`. It covers the naming convention, server or browser capture, identity, groups, feature flags, properties, cost and personal data. For each new or changed event, state:

- the name;
- the exact moment it fires, for example "after the invite is saved", not "on click";
- where it fires: server, or browser/app;
- its properties, each with a type and an example value;
- the PRD items it answers;
- one plain sentence that says why.

## Step 5: Write the Analytics plan

Start with a short brief for the person who asked. Keep it to about 300 words, because a PM who is new to PostHog stops reading a long wall of tables:

1. One or two sentences: what the team will be able to answer after the feature ships.
2. The decisions you made that the reader may want to change, one line each.
3. What waits on the PM, as a count of questions.

Then show the full plan, built from the template in `references/analytics-issue.md`. The plan becomes the body of the Linear issue, so it must make sense without the brief. Show it in chat before any write.

## Step 6: Hand off, after approval

- **Linear:** create one issue, "Analytics: <feature>", in the PRD's project, with the plan as its body. Post the PM questions as one comment that mentions the PM. Do not edit the PRD document or the project description, because the PM owns them. If Linear is not connected or is read-only, print the issue body in a fenced code block for the user to paste.
- **PostHog:** create insights only for metrics whose events already exist and have data. For the other metrics, list the insights to create after the events ship. Name the dashboard after the feature, and put the Linear project link in its description.
- **Code:** if an engineer wants the code, continue with `references/code-modes.md`.

## Code path (engineers)

`references/code-modes.md` covers three modes, picked per story:

- **Build:** the story has no code yet. Add the events while the feature is built.
- **Retrofit:** the code exists, with no capture calls. Find where each step saves its result, then add the calls.
- **Verify:** the code has capture calls. Score each call against the plan, then fix the gaps after approval.

Each mode ends with tests that prove the events fire, and a live check in a dev project.
