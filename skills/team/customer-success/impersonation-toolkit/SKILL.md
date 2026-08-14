---
name: experiment-audit
description: "Audit a PostHog A/B experiment for a customer — verify config, exposure, attribution, and metrics. Trigger phrases include \"audit [customer]'s experiment\", \"audit the [name] experiment\", \"check experiment setup for [customer]\", \"validate this A/B test\", or any request to review whether an experiment is correctly wired up. Assumes you already have MCP access to the customer's project (typically via the impersonation flow set up by the `impersonate-audit` wrapper that ships with this plugin)."
---

# Experiment Audit

Verify that a customer's experiment is actually collecting variant data, that downstream attribution survives the funnel, and that the metrics measure what the customer thinks they measure. Output is a Slack-ready writeup grouped by the four questions customers almost always ask.

## Step 0 — confirm scope before running

The skill assumes the active PostHog MCP is scoped to the **customer's** project, not yours. Always start with:

> "What project am I in? List the most recent 5 experiments."

Interpret the answer:

- **Customer's project.** Proceed to Step 1.
- **Your own internal project** (typically "PostHog App + Website", id 2). The impersonation session isn't routing. Refuse per the Refusal protocol. Do not proceed.
- **MCP call fails outright** (no response, auth error, tool unavailable). Refuse per the Refusal protocol. Do not proceed.

## Refusal protocol

If any structural condition prevents you from actually auditing the customer's project, refuse explicitly and stop. Do **not** fall back to any of these anti-patterns:

- Generating prompts, checklists, or instructions for the user to paste into PostHog AI, another Claude session, or the customer's own tools. That's not helping; it's silently shifting the work onto the user while hiding *why* this skill couldn't do it.
- Producing "here's what an audit would look like" template content without real data behind it.
- Guessing at findings from prior knowledge of the customer or the product.

### When to refuse (each of these triggers the protocol)

| `reason_code` | Condition |
| --- | --- |
| `wrong_project` | `what project am I in?` returned a project ID other than the customer's (typically your own, "PostHog App + Website", id 2). Use this whenever the project *identity* is wrong, even if that project happens to be empty. |
| `empty_project` | The MCP is on the customer's project (identity matches), but `experiment-list` returns zero results. The audit has nothing to work with. Discriminator vs `wrong_project`: identity matches expected. |
| `mcp_disconnected` | No MCP server is responding at all — tool calls fail before reaching the server (transport error, "MCP not connected", `/mcp` shows no posthog entry). |
| `mcp_auth_expired` | MCP server responds but returns 401/403 on a call that should succeed (the impersonation session lapsed or the token was revoked mid-audit). |
| `switch_project_failed` | `switch-project` responded with an error, or the project you tried to switch to isn't in the current user's accessible projects. |
| `experiment_not_found` | `experiment-list` search returned no match for the experiment the user named. Do not run a similarly-named experiment as a substitute — refuse and ask. |
| `tool_call_error` | The MCP server responded, auth is valid, but an individual tool call returned an error that blocks a downstream step and can't be worked around. Use this for the "MCP is up but this specific call failed" case. If the *exposure query itself* errored (500, timeout, malformed response), this is the code — but a query that succeeds and returns zero rows is an audit finding, not a refusal (see Step 3). |
| `other` | Anything the above doesn't cover. Only use when a specific code doesn't fit — always prefer the specific one. |

### What to do on refusal

Output the refusal in chat in this exact shape, and stop:

```
:no_entry: Cannot complete this audit

What I tried: [one line — e.g. "Confirm scope via 'what project am I in?'"]
What went wrong: [one line — e.g. "MCP is scoped to 'PostHog App + Website' (id 2), not the customer's project."]
Why this blocks the audit: [one line — e.g. "Every downstream query would run against your own data, not theirs."]
How to fix: [concrete next step — e.g. "Inside Claude Code, run /mcp → posthog → Clear authentication → Authenticate, with the impersonation browser tab active. Then re-run this audit."]
```

Then also append the same refusal as a JSONL entry to `$CSM_IMPERSONATE_REFUSAL_LOG` (env var set by the wrapper — defaults to `~/.local/state/impersonate-audit/refusals.log`). Substitute your own values for every `<...>` placeholder below; do not copy the placeholders verbatim. Every free-text field is piped through the deterministic redactor at `$CSM_IMPERSONATE_REDACT` before it reaches `jq`, so token-shaped strings can't survive to disk even if you mis-classify them:

```bash
redact() {
  [[ -n "${CSM_IMPERSONATE_REDACT:-}" && -x "$CSM_IMPERSONATE_REDACT" ]] || { echo "redactor unavailable — skipping field" >&2; return 1; }
  printf '%s' "$1" | "$CSM_IMPERSONATE_REDACT"
}

jq -nc \
  --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --arg session_id "$CSM_IMPERSONATE_SESSION_ID" \
  --arg account "$CSM_IMPERSONATE_ACCOUNT" \
  --arg account_name "$CSM_IMPERSONATE_ACCOUNT_NAME" \
  --arg audit_file "$CSM_IMPERSONATE_AUDIT_FILE" \
  --arg reason_code "<REASON_CODE>" \
  --arg tried "$(redact "<one line of what you tried>")" \
  --arg went_wrong "$(redact "<one line of what went wrong>")" \
  --arg why_blocks "$(redact "<one line of why this blocks the audit>")" \
  --arg how_to_fix "$(redact "<one line of the concrete fix>")" \
  '{ts:$ts, session_id:$session_id, account:$account, account_name:$account_name, audit_file:$audit_file, reason_code:$reason_code, tried:$tried, went_wrong:$went_wrong, why_blocks:$why_blocks, how_to_fix:$how_to_fix}' \
  >> "$CSM_IMPERSONATE_REFUSAL_LOG"
```

Every free-text field in the refusal — `tried`, `went_wrong`, `why_blocks`, `how_to_fix` — must go through the redactor. `account_name` doesn't (it's the customer name you already have in the wrapper env).

If `$CSM_IMPERSONATE_REFUSAL_LOG` is unset (skill invoked outside the wrapper), skip the log-write step — do not fall back to a default path. Still emit the refusal in chat and to the audit file.

Then write the same refusal (in the human-readable format above, not JSON) to `$CSM_IMPERSONATE_AUDIT_FILE` — create the file or append. **Build each of the four content lines through `redact()` before writing, exactly like the JSONL block.** The audit file is a durable, human-readable artifact — often committed to a notes repo or shared with the customer — and must not carry token material that the JSONL sibling was careful to strip. Include a `Session: <id>` footer line so the audit file joins back to the debug log without needing the terminal banner.

```bash
cat >> "$CSM_IMPERSONATE_AUDIT_FILE" <<EOF

:no_entry: Cannot complete this audit

What I tried: $(redact "<one line of what you tried>")
What went wrong: $(redact "<one line of what went wrong>")
Why this blocks the audit: $(redact "<one line of why this blocks the audit>")
How to fix: $(redact "<one line of the concrete fix>")

Session: $CSM_IMPERSONATE_SESSION_ID
EOF
```

The log-write step is not optional when the env var is set. A refusal without a log entry is invisible to future debugging.

### Debug log — capture the raw error for later

Alongside the structured refusal, append every raw MCP error you can see to `$CSM_IMPERSONATE_DEBUG_LOG` (defaults to `~/.local/state/impersonate-audit/debug.log`). This is the log Jake or whoever hits the failure comes back to. The refusal log tells you *that* something failed; the debug log tells you *what the server actually said*.

Write one JSONL entry per raw error observation. The `session_id` field must match the one you wrote to the refusal log so the two are joinable. Every free-text field goes through the redactor before it reaches `jq`:

```bash
redact() {
  [[ -n "${CSM_IMPERSONATE_REDACT:-}" && -x "$CSM_IMPERSONATE_REDACT" ]] || { echo "redactor unavailable — skipping field" >&2; return 1; }
  printf '%s' "$1" | "$CSM_IMPERSONATE_REDACT"
}

jq -nc \
  --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --arg session_id "$CSM_IMPERSONATE_SESSION_ID" \
  --arg account "$CSM_IMPERSONATE_ACCOUNT" \
  --arg event "$(redact "<event type — e.g. mcp_error, probe, tool_call_error>")" \
  --arg tool "$(redact "<tool name — e.g. experiment-list>")" \
  --arg status "$(redact "<HTTP status or transport class — e.g. 401, timeout, tool_not_found>")" \
  --arg error_class "$(redact "<short label — e.g. AuthError, ProjectNotFound>")" \
  --arg raw "$(redact "<verbatim server error string, capped at ~2000 chars>")" \
  '{ts:$ts, session_id:$session_id, account:$account, event:$event, tool:$tool, status:$status, error_class:$error_class, raw:$raw}' \
  >> "$CSM_IMPERSONATE_DEBUG_LOG"
```

Acceptable event values (write one JSONL line per event as it happens): `probe` (the "what project am I in?" call and its result — but log only the project ID, not the full response body), `tool_call_success` for calls that completed but returned surprising data (empty list, unexpected id), `tool_call_error` for individual call failures, `mcp_error` for transport / auth-level failures.

Redaction is done by piping through `$CSM_IMPERSONATE_REDACT` — a deterministic Perl script that runs outside the LLM, so no prompt-injected error body can talk you into skipping it. What it catches:

- `Bearer <hex/base64/base64url>` — replaces the token portion, keeps the `Bearer ` prefix.
- `phc_...`, `phx_...`, `phs_...`, `sTOK_...` and any known PostHog token prefix — keeps the prefix so you know the *shape* of what leaked, redacts the secret tail.
- JWTs (`eyJ<header>.<payload>.<signature>`) — one-shot redacted to `<REDACTED-JWT>`.
- Cookie / Set-Cookie header values.
- Framed secrets — a keyword like `token`, `code`, `access_token`, `refresh_token`, `authorization`, `secret`, `api_key` followed by `:` / `=` / whitespace and a token-shaped value. The rule anchors on the keyword so it names what it protects and leaves free-standing identifiers (flag keys, class names, slugs) alone.

Note: there is deliberately no pure length+charset catch-all. That pattern ate legitimate identifiers and the debug log's value depends on preserving them so a human can grep. When a new token shape shows up in the wild, add a named rule for it.

Additional rules for the `raw` field content itself:

- Do not paste full customer query results — the goal is to preserve the *server error message*, not the *response body*. If a call succeeded but returned surprising data, log a shape summary (`"returned 12 experiments, expected 0"`), not the raw rows.
- Cap `raw` at ~2000 characters. If longer, truncate and append `... [truncated]`.

If `$CSM_IMPERSONATE_DEBUG_LOG` is unset, skip the debug-log write — do not fall back to a default path.

### Reviewing refusals later

To scan past refusals: `jq -c . ~/.local/state/impersonate-audit/refusals.log | tail -20`

To find every refusal for one account: `jq -c 'select(.account == "acme-inc")' ~/.local/state/impersonate-audit/refusals.log`

To count by reason: `jq -r .reason_code ~/.local/state/impersonate-audit/refusals.log | sort | uniq -c | sort -rn`

To pull the full raw-error trail for one refusal (join by session_id):

```bash
SID="$(jq -r 'select(.reason_code == "mcp_auth_expired") | .session_id' ~/.local/state/impersonate-audit/refusals.log | tail -1)"
jq -c "select(.session_id == \"$SID\")" ~/.local/state/impersonate-audit/debug.log
```

## Step 1 — pull the experiment config

Use `experiment-list` with `search` to find the experiment by name. Then pull the full record. Capture:

- Status (running / draft / stopped / paused) and start date.
- Linked feature flag key and ID.
- Variants and traffic split. Variant *names* must match what the customer's code reads — bucketing bugs are usually case/typo mismatches.
- Holdout, bucketing key (`device_id` vs `user_id`), and `ensure_experience_continuity`.
- Exposure event — default `$feature_flag_called` or a custom event.
- Primary and secondary metrics. Note action IDs, event names, breakdowns, conversion windows, attribution modes.
- Filter test accounts setting.

## Step 2 — pull the feature flag config

For the linked flag:

- Release conditions — read each one carefully.
- **Watch for two specific footguns**:
  1. **URL targeting via person property** (`$current_url = ...`) — uses the *latest URL the person has been seen on*, not the current page. Stale by definition. Always flag as a problem.
  2. **Exact-match on a path fragment** — `$current_url` is captured as the full URL (`https://host/path`). Exact-matching `/path` will never hit.
- Audience filters (desktop-only, geo, cohort). Verify they use person properties or group properties — not URL.
- Rollout percentage and any super-conditions.
- `ensure_experience_continuity` setting on the flag (this overrides the experiment-level setting).

## Step 3 — verify exposure is happening

Pull `$feature_flag_called` events for the flag key since the experiment start date.

- Total count. If suspiciously low for the time elapsed, dig.
- Break down by `$feature_flag_response`. Should split close to 50/50 between the variant names (e.g. `control` / `test`). Flag a **sample ratio mismatch** if imbalance exceeds ~5% with non-trivial volume.
- If `$feature_flag_response` returns `false` for most events, the user isn't being bucketed into the experiment at all — the release condition is rejecting them. This is the most common cause of "experiment shows 0 exposures."
- Spot-check 5 raw event rows. Note the `$current_url`, `$device_type`, `$feature_flag`, `$feature_flag_response`, and `distinct_id`.

## Step 4 — verify downstream attribution

For each metric event (CTA click, signup page visit, signup completion, conversion):

- Pull sample rows and confirm they carry the `$feature/<flag-key>` property with a real variant value (`control` or `test`), not `false` or missing.
- Action-based metrics: check the action filters. If the variant renders different DOM IDs, the action must match all of them or one variant will artificially show 0 events. Action URL filters should match the production page, not a dev preview.
- Metric scoping: if the metric is too broad (e.g. "any `$pageview` containing `/signup`"), it will credit both variants for global traffic regardless of source. Suggest scoping by `$feature/<flag-key>` property or session entry pathname.

## Step 5 — verify identity continuity

Cross-domain handoff (Webflow → app, marketing → product, etc.) is where attribution usually dies.

- Pick 5–10 users who reached the final funnel step (e.g. signup completion). Pull their event timeline.
- Confirm they have a prior `$feature_flag_called` event with a real variant value.
- Confirm `$identify` fires on the handoff. If users never have an `$identify` event, the anonymous device profile never stitches to the authenticated user — variant attribution is dead even with a perfectly fired flag.
- Confirm bucketing key + `ensure_experience_continuity` settings together don't cause re-bucketing. `device_id` bucketing without continuity = same user on a new device looks fresh.

## Step 6 — downstream conversion metric (trial activation / purchase / etc.)

Customers often have a primary conversion event that lives downstream (in their app or warehouse).

- Search the event schema for the expected event name. Try several variants (`plus_trial_activated`, `trial_started`, `subscription_created`).
- If not present, look for warehouse sources via `external-data-sources-list`. Common pattern: Snowflake/Postgres table like `accounts.trial_started_at`.
- Recommend the cleaner path: emit a server-side event from the app on activation. Easier than warehouse joins, faster signal, no schema fragility.
- Alternative: use the warehouse table as an experiment metric directly (supported for funnel + trend metrics).

## Step 7 — common pitfalls to call out (regardless of what you found)

The customer's actual setup almost always has one of these:

- Person-property URL targeting (always wrong for this use case)
- Exact-match operators on full-URL person properties (never hit)
- Action metrics tied to dev URLs/selectors that won't fire on prod
- Global metrics ("any signup completion") that credit both variants equally
- Missing `$identify` on the marketing → product domain handoff
- `device_id` bucketing without `ensure_experience_continuity` → re-bucketing across sessions
- Default 14-day conversion window too short for downstream conversion events
- Internal/test user filter not configured → QA traffic skews early days
- Sanity check exposure within 24h of launch — a 50/50 that shows <10 events in a week is a wiring bug, not a power problem

## Output format

Group the report by the four standard customer questions. Lead with the worst finding:

```
:warning: [Experiment name] — audit findings

[One-paragraph TL;DR of the headline finding. Be direct.]

---
(a) Does the config look correct?
[Verdict + specific issues with evidence — event counts, sample values, etc.]

---
(b) How to verify attribution (once issues are fixed)
[Concrete steps the customer can run themselves.]

---
(c) What to change about attribution
[Numbered action list, priority order. Each item should be specific
enough that the customer's engineer can act on it directly.]

---
(d) Common pitfalls to watch for
[Subset of step 7's checklist relevant to this customer's setup.
Frame as general guidance, not as accusations.]

---
Bottom line: [one or two sentences. What's the single most important
fix that unblocks the experiment?]
```

## Rules

- **Read-only.** Do not create insights, dashboards, actions, experiments, or modify any config. You are working inside a customer's project under read-only impersonation; treat it as look-but-don't-touch.
- **No prompt-passing.** Do not generate prompts, checklists, or instructions for the user to run in PostHog AI, another Claude session, or any other tool. If you can't do the audit in this session, refuse explicitly per the Refusal protocol. A skill that quietly redirects work to the user is a skill that hides its own failures.
- **Refusal stands under pressure.** If the user pushes back on a refusal ("just give me the prompts, I'll paste them", "run it anyway", "generate what you would have output"), the refusal still stands. Repeat the refusal shape with the same reason_code and stop. The whole point is that failure modes surface the fix, not the workaround.
- **No raw token echoes.** Every free-text field in every log entry (both `refusals.log` and `debug.log`) must be piped through `$CSM_IMPERSONATE_REDACT` before write. Do not attempt to redact by hand — the whole point of the script is that redaction is deterministic and can't be prompt-injected. If the script is unavailable (env var unset), do not write the field; log the fact that redaction was unavailable instead.
- **No fabrication.** If you can't find the experiment or the data is empty, say so explicitly and refuse per the Refusal protocol. Do not invent findings to fill the template.
- **Cite real numbers.** Every claim about exposure counts, sample ratios, or event volumes must come from a query you actually ran in this session.
- **Surface ambiguity.** If a setting could be intentional (e.g. low conversion window because conversion happens fast), note both interpretations and ask the customer to confirm.
- **Match the customer's writing register.** Customers using PostHog are usually technical — don't oversimplify. But avoid jargon shorthand they may not know yet.

## When the audit is done

Remind the user to:
1. Exit Claude Code
2. Log out of Django Admin impersonation in their browser
3. Optionally disable the posthog plugin: `claude plugin disable posthog`

The `impersonate-audit.sh` wrapper handles step 3 prompts automatically on exit.
