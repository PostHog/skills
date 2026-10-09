# Instrumenting from a PRD

A Claude skill that turns a feature PRD, usually a Linear project, into a PostHog measurement plan. With a repo open, it also writes the capture code and the tests that prove the events fire.

It is written for teams that are new to PostHog. The PM owns the goal in the PRD. The skill makes the PostHog decisions and explains each one in plain words.

## What it does

1. Reads the PRD and its stories from Linear.
2. Links each success metric to the PostHog insight that measures it, and each story to the one event that metric needs.
3. Checks what the PostHog project already records, so it reuses events instead of adding new ones.
4. Writes an Analytics plan: PRD items to measures, events to add or change, and questions for the PM where the PRD cannot be measured as written.
5. After approval, creates one "Analytics: <feature>" issue in the Linear project.
6. For engineers: builds, retrofits or verifies the capture calls per story, adds tests, and checks the events in a dev project.

It never edits the PRD document, and it writes nothing to Linear, PostHog or the code until you approve the exact content.

## Setup

### Claude Code (engineers, and PMs who use it)

```
/plugin marketplace add PostHog/skills
/plugin install instrumenting-from-a-prd@PostHog-skills
claude mcp add --transport http linear https://mcp.linear.app/mcp
npx @posthog/wizard@latest mcp add
```

### Claude app (PMs)

1. Upload the skill folder `skills/instrumenting-from-a-prd` as a skill.
2. Turn on the Linear and PostHog connectors.

The Claude app path covers the plan only. The code path needs Claude Code and the repo.

## Usage

```
Make a tracking plan for the Team Invites project in Linear: https://linear.app/acme/project/team-invites-1a2b3c
```

```
Do our PostHog events cover the success metrics in this PRD? <paste>
```

```
Instrument ENG-412 and ENG-415 from the Analytics issue, and add tests.
```

## Requirements

- Claude with skills support.
- Linear MCP or connector (optional: without it, paste the PRD).
- PostHog MCP or connector (optional: without it, the plan marks coverage "not checked").
