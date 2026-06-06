---
name: experiment-audit
description: "Audit a PostHog A/B experiment for a customer — verify config, exposure, attribution, and metrics. Trigger phrases include \"audit [customer]'s experiment\", \"audit the [name] experiment\", \"check experiment setup for [customer]\", \"validate this A/B test\", or any request to review whether an experiment is correctly wired up. Assumes you already have MCP access to the customer's project (typically via the impersonation flow set up by the `impersonate-audit` wrapper that ships with this plugin)."
---

# Experiment Audit

Verify that a customer's experiment is actually collecting variant data, that downstream attribution survives the funnel, and that the metrics measure what the customer thinks they measure. Output is a Slack-ready writeup grouped by the four questions customers almost always ask.

## Step 0 — confirm scope before running

The skill assumes the active PostHog MCP is scoped to the **customer's** project, not yours. Always start with:

> "What project am I in? List the most recent 5 experiments."

If the project name looks like your own internal project (e.g. "PostHog App + Website", id 2), STOP — the impersonation isn't routing correctly. Re-run the wizard or check `/mcp` auth before continuing.

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

- **Read-only.** Do not create insights, dashboards, actions, experiments, or modify any config. You are impersonating the customer's user — any writes land in their actual project.
- **No fabrication.** If you can't find the experiment or the data is empty, say so explicitly. Do not invent findings to fill the template.
- **Cite real numbers.** Every claim about exposure counts, sample ratios, or event volumes must come from a query you actually ran in this session.
- **Surface ambiguity.** If a setting could be intentional (e.g. low conversion window because conversion happens fast), note both interpretations and ask the customer to confirm.
- **Match the customer's writing register.** Customers using PostHog are usually technical — don't oversimplify. But avoid jargon shorthand they may not know yet.

## When the audit is done

Remind the user to:
1. Exit Claude Code
2. Log out of Django Admin impersonation in their browser
3. Optionally disable the posthog plugin: `claude plugin disable posthog`

The `impersonate-audit.sh` wrapper handles step 3 prompts automatically on exit.
