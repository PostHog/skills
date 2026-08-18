# Config (per user)

The only file you edit to make this skill yours, and on first run the skill fills it in for you: it probes the tool list and the env, confirms what it found in one message, asks only what it cannot detect, and writes this file back (Setup in `SKILL.md`). A required value reading `<SET THIS>` means ask before the step that needs it. Optional rows set to `none` (or a missing tool) are skipped silently, never logged as an error.

## Required tools

| Tool | Needed for | How to find it |
|---|---|---|
| PostHog MCP with access to project 2 (PostHog App + Website) | product-usage and app-database queries, except an EU customer's raw product events, which go over the API with `POSTHOG_PERSONAL_API_KEY_EU` (the direct-connection section in `references/data-rules.md`) | surfaces as ONE exec-style gateway tool (search your tool list for "posthog" or "exec"); usage is `info <tool>` then `call <tool> <json>`. Ignore a server literally named "posthog" that lacks the exec command (usually an unauthenticated duplicate). If the gateway tool is unreachable in a session, fall back to the direct API with `POSTHOG_PERSONAL_API_KEY` (see "Execution fallback" in `references/data-rules.md`); the MCP stays primary |
| Vitally MCP | account resolution and workflow data | [PostHog/vitally-mcp-cs](https://github.com/PostHog/vitally-mcp-cs); tools named `mcp__vitally__*`, auth via `VITALLY_API_KEY`. Temporary by design: it retires with the Vitally contract (October 2026) |

## Keys (env vars)

| Key | Needed for | Required? |
|---|---|---|
| `VITALLY_API_KEY` | the Vitally MCP, and the REST fallback for conversation bodies | Yes |
| `POSTHOG_PERSONAL_API_KEY` | the direct-API fallback when the MCP gateway is down; set it before you need it | Recommended |
| `POSTHOG_PERSONAL_API_KEY_EU` | Two things, both on EU project 1: experiment definitions, and the **direct ClickHouse connection** that returns an EU customer's own raw product events (per-event volumes, autocapture share, identity mix). The US key 403s on `eu.posthog.com`, so mint this one in the EU instance. Without it, report both as unavailable rather than reading the gap as zero | For EU accounts, and it is what makes an EU deep dive as complete as a US one |

## Values

Defaults hold unless changed; only the first two are personal.

| Key | Value | If unset |
|---|---|---|
| Work calendar ID | `<SET THIS>` | ask on the first call prep |
| Booking link (call CTA) | `https://calendly.com/d/cvth-7jj-ks9/` | ask on the first outreach draft |
| Timezone | `<SET THIS>` | detect from the system |
| Email sign-off | `Cheers,` | default |
| Email sign-off (billing and payment threads) | `Thank you,` | default |
| Post-onboarding survey (graduation CTA) | `https://us.posthog.com/external_surveys/019c523d-0d90-0000-65ba-4b976e24c83e` | ask before any graduation or wrap-up draft |

## Optional context sources

One row per job, tool-agnostic: the skill asks for "meeting transcripts" and this table says which tool answers on this machine. Swap the "Yours" cell for whatever you run (examples in the middle column), naming the exact tools so a session can call them without guessing; `none` skips the source.

| Category | Examples | Yours |
|---|---|---|
| Slack search | Slack MCP | Slack MCP: `slack_search_public_and_private`, `slack_read_channel` |
| Meeting transcripts | Gong (default; everyone at PostHog records there), Wispr Flow, Quill, Granola | Gong MCP (`mcp__gong__*`), the default. **One probe: `search_calls_by_account` on the domain. Zero hits ends the source, and "searched Gong, zero calls" is the finding.** Measured: a no-result search that ran eight rolling sweeps plus keyword searches spent 64 calls establishing what the first one already showed. Only on a hit do the rest apply: `search_calls` with `customerName` (account name, email domain, or title substring) or `participantEmails` plus a `fromDateTime`/`toDateTime` window and `scope: External`, then `get_call_summary` for the AI outline and `get_call_transcript` for verbatim speaker-attributed text. **The transcript tool pages at 10KB: loop on `offset` until the "showing X of Y" total is reached, or the run reads the first third of a call and thinks it read it all.** Attendees can appear twice (a bare first name with role Unknown beside the email with role External); treat them as one person and verify attribution against notes. Fallback when a call is not in Gong: Wispr Flow MCP (`mcp__wisprflow__*`), `search_meetings` by keyword or `attendee_emails`, then `get_meeting` with `view_transcript={}`; timestamps UTC; `has_transcript: false` still usually carries a summary |
| Meeting notes folder | any local folder of call notes | `none` |
| Work calendar | `gog` CLI (the `use-gog` skill) | Exact command, copy it rather than deriving the flags: `gog calendar events --account <your-posthog-email> --all --from YYYY-MM-DD --to YYYY-MM-DD --max 50 --sort start --timezone <your-timezone>`. The window flags are `--from` / `--to`; `--start` / `--end` do not exist and cost a round trip each to discover. `--all` is needed or team calendars are missed, and the shared calendar floods the result with `OOO -` entries, so filter those out before reading. The MCP `search_events` takes no window and returns nothing useful for call prep |
| Enrichment | Clay | Clay MCP: `search-companies` + `get-task-context` (UUID prefix); enrichments cost credits, ~20-100 per invocation |
| Source and docs repos | GitHub CLI | `gh`, authenticated with `repo` scope. Reads the billable-meter definitions in `PostHog/posthog` and the docs source in `PostHog/posthog.com`, and checks whether a customer's request has an open issue or PR. Never the citation for a customer-facing claim (see the GitHub section in `references/data-rules.md`) |

> Publishing note: only three things in this file are personal, and the shared copy already has them blanked: the work calendar ID, the timezone, and the meeting notes folder. **Do not blank the other "Yours" cells.** The Gong paging procedure, the `gog` flag list, the Slack tool names and the Clay and `gh` notes are the same for everyone at PostHog, and each one records a mistake somebody already made, so wiping them makes the next person rediscover it. Personalise a cell only where it names your machine.
