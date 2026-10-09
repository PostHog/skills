# Code modes (engineers)

This path needs the repo open and the PostHog SDK installed. If the SDK is missing, stop. Tell the engineer to run `npx @posthog/wizard`, which installs and initializes it, and then to come back.

Start from an approved Analytics plan. If the Linear project already has an "Analytics" issue, read it instead of writing a new plan.

## Pick the mode per story

Find each story's code with `linear.md` > "Trace a story to code".

| Story state | Mode |
|---|---|
| No pull request, no code | Build |
| Code, but no capture call for its step | Retrofit |
| Code with capture calls | Verify |

Show the list of stories and modes, and let the engineer confirm it. The trace can be wrong in a codebase you have not seen, so this check comes before any edit.

## One home for event names

Put every event name and its property types in one module, for example `analytics/events.ts` or `analytics/events.py`. Capture calls import names from it. A typo in a string event name creates a new event without any error, and a typed module stops that at build time. If the codebase already has a tracking wrapper, extend it instead.

## Build and retrofit

1. Find where each step saves its result: the handler, mutation or job, not the button.
2. Add the capture call after the success path, not before an `await` or a call that can fail. If the save runs in a database transaction, capture after the commit, not inside the transaction, because a rollback after the capture leaves an event for data that does not exist.
3. Make sure an analytics error can never fail the user's request. The capture call now runs after the save, so an error there returns a failure for data that was saved, and a retry creates a duplicate. If the codebase wraps the SDK, the wrapper catches and logs its own errors.
4. Add the properties from the plan. Check that each value is available at that point in the code.
5. On the server, use the same distinct ID as the browser (`event-design.md` > "Server or browser").
6. Add groups and flag values as the plan says. Read a feature flag only in the code path where the feature can appear (`prd-mapping.md` > "Exposure").
7. In a serverless function or a short job, flush the PostHog client before the handler returns, for example `await posthog.shutdown()` in Node or `posthog.flush()` in Python. Otherwise the events drop with no error.
8. Change only instrumentation lines, the events module and tests. A small diff gets a fast review, and a refactor hides the change that matters.

## Verify

Score each existing capture call against the plan:

- **covered:** right event, right moment, right properties;
- **wrong place:** for example it fires before the save, so it also fires on failure, or an outcome fires from the browser;
- **missing properties;**
- **missing:** no call records the step;
- **extra:** the call answers no PRD item.

Add a "Status" and a "Fix" column to the Analytics table. Fix only after the engineer approves.

## Tests

- Write one test per PRD flow, not one per event. Three to five tests usually cover a feature.
- Mock the PostHog client at the module boundary, run the flow's handler, and assert the event names in order plus the properties that carry the PRD's meaning.
- Do not assert the whole payload. A new property must not break an unrelated test.
- Name each test after its story, for example `test_invite_by_link_records_invite_send`.
- Use the project's own test framework and patterns.
- Prove that each test can fail. Put back the bug it guards, for example move the capture call before the save, run the test, see it fail, then restore the fix. A test that passes with the bug in place proves nothing.

## Live check

1. Use a dev or staging PostHog project. Do not send test events to production.
2. Ask the engineer to run each flow once.
3. Read the events for the engineer's distinct ID from the last hour, through the PostHog MCP. Check that:
   - each planned event arrived;
   - the required properties are filled;
   - `$lib` shows the planned side, server or browser;
   - browser and server events belong to one person;
   - flag values are present where the plan needs them.
4. Report each check as pass, fail or not run. "Not run" is not a pass.

## Pull request

- Put the Analytics issue ID in the title, so that Linear links the pull request.
- In the body, include the Analytics table with a status per row, the tests you added and the live check result.

## A feature that already shipped

- Do not rename shipped events (`posthog-check.md` > "Do not rename a shipped event").
- Verify on production data, read-only: volume against the expected traffic, property fill rates, the identity check and flag values.
