---
name: weekly-pr-retrospective
description: Weekly PR retrospective for an engineer or team, categorized against goals defined in a source (GitHub issue or website). On first run it walks the user through a one-time setup that persists their goals source and team-member list to a config file. Run locally where `gh` is authenticated.
---

Produce a weekly PR retrospective covering the last 7 days of GitHub activity, categorized against a list of goals/objectives stored in a per-user config file.

## Configuration file

This skill is driven by a config file at:

```
~/.config/weekly-pr-retrospective/config.json
```

Schema:

```json
{
  "goals_source": "<github-issue-shorthand-or-url-or-website-url>",
  "team": ["handle1", "handle2", "..."]
}
```

- `goals_source` — required. One of:
  - A GitHub issue shorthand: `owner/repo#NUM` (e.g. `acme/infra#42`)
  - A GitHub issue URL: `https://github.com/<owner>/<repo>/issues/<num>`
  - Any other `https://` URL pointing to a public web page that lists goals
- `team` — required (can be an empty array). The list of GitHub handles whose PRs are pulled in **team mode**. The invoking user is resolved separately and unioned in at runtime, so omit yourself.

## Arguments

This command takes one optional argument:

- _no argument_ → **single-user mode**: report only on the invoking user's PRs.
- `team` → **team mode**: include the saved `team` handles from the config file in addition to the invoking user.
- `setup` → force re-run the setup flow even if the config file already exists.

Treat any other argument as invalid and ask the user to clarify.

## Steps

### Step 0 — Setup (only when needed)

1. Check whether `~/.config/weekly-pr-retrospective/config.json` exists.
2. **Skip the rest of this step entirely if the file exists** and the user did not pass `setup`. Read the file and proceed to Step 1.
3. If the file is missing, or the user passed `setup`, run the setup flow:
   - Ask the user, exactly: _"What's the source of your goals? Paste a GitHub issue (`owner/repo#NUM` or a `https://github.com/.../issues/NUM` URL) or a public `https://` website URL."_
   - Validate the answer matches one of the three accepted shapes. If not, ask again. Do not invent or default a value.
   - Ask the user, exactly: _"Which GitHub handles should `team` mode include? Comma-separated list, no `@`. Leave blank if you only want single-user mode."_
   - Parse into an array of handles, trimmed, lowercased only if the user wrote them lowercased — keep their original casing otherwise. Empty input → empty array.
   - Ensure `~/.config/weekly-pr-retrospective/` exists, then write the config file as pretty-printed JSON.
   - Confirm in chat: "Saved config to `~/.config/weekly-pr-retrospective/config.json`. You can re-run setup any time with `/weekly-pr-retrospective setup`."

After setup, continue to Step 1 with the freshly-saved values.

### Step 1 — Validate the loaded config

- `goals_source` must be present and match one of: `owner/repo#NUM`, GitHub issue URL, or a generic `https://` URL. If it doesn't, prompt the user to re-run setup (`/weekly-pr-retrospective setup`) and stop.
- `team` must be an array (possibly empty). If the user invoked `team` mode and the array is empty, tell them they need to re-run setup to add team handles, and stop.

### Step 2 — Identify the invoking user

Run `gh api user --jq .login` via Bash. If `gh` is not authenticated, stop and tell the user to run `gh auth login`.

### Step 3 — Resolve the author list

- Single-user mode: `authors = [<invoking user>]`.
- Team mode: `authors = unique([<invoking user>, ...config.team])`. Deduplicate so the invoking user isn't double-counted if already listed in `team`.

### Step 4 — Fetch the goals from `goals_source`

- **GitHub issue shorthand** (`owner/repo#NUM`): run `gh issue view <NUM> --repo <owner>/<repo> --json title,body,labels`.
- **GitHub issue URL**: parse out `<owner>`, `<repo>`, and `<num>`, then run the same `gh issue view ...` command.
- **Generic web URL**: use the WebFetch tool to retrieve the page contents. Prompt WebFetch to extract the list of goals/objectives/initiatives from the page.

Parse the result and extract the listed goals. Treat each distinct goal/bullet as a target category. Keep the original goal phrasing so categories are recognizable.

If the source can't be fetched (404, private, network error), report that and ask the user whether to re-run setup with a different source. Do not proceed with a guessed category list.

### Step 5 — Fetch each author's PRs from the last 7 days

Scope to the PostHog org (no per-repo filter — we want every PR the author opened anywhere in PostHog/*). For each author, run:

```
gh search prs --author "<login>" --owner PostHog --created ">=$(date -v-7d +%Y-%m-%d 2>/dev/null || date -d '7 days ago' +%Y-%m-%d)" --limit 100 --json number,title,url,repository,state,createdAt,closedAt,body,labels
```

Include both open and closed/merged PRs. If `--created` filter doesn't return enough, fall back to `gh search prs --author "<login>" --owner PostHog --limit 200 --json ...` and filter client-side by `createdAt` within the last 7 days. Tag each PR result with its author so authorship is preserved when the lists are merged.

Note: do **not** include `mergedAt` in `--json` — `gh search prs` doesn't expose that field. State (`merged`/`closed`/`open`) plus `closedAt` is enough.

### Step 6 — Categorize each PR

For each PR:
- Read its title, body, labels, and repo.
- Decide which goal from the fetched goals list it maps to. A PR can map to one primary goal (pick the best fit). If it doesn't fit any listed goal, place it in a sensibly-named "Other" group (e.g., "Developer experience", "Tooling", "Documentation") — name groups so they're useful, not generic.
- Tag each PR with one or more meta labels from this set: `feature` (new user-facing capability), `maintenance` (keep-the-lights-on, refactors, deps, cleanup), `test` (test-only changes), `incident` (incident response or hotfix), `bug` (bug fix not tied to incident), `infra` (infrastructure/IaC), `docs`, `chore`. Use PR labels and content to infer; pick the most fitting tags.

### Step 7 — Write the report

Resolve the current ISO year-week with `date +"%G-W%V"` (e.g. `2026-W17`). Ensure `~/Development/<year-week>/` exists (create it if needed), then write the markdown file to `~/Development/<year-week>/pr-retrospective-<scope>-YYYY-MM-DD.md`, where `<scope>` is `user` in single-user mode or `team` in team mode. Use today's date for `YYYY-MM-DD`.
Important: do not blame any of the team mates, this report is solely for ease of use and creating transparency for asking the right questions and not intended as any kind of performance report. 

Structure:
- Header with mode (single-user vs. team), the list of authors covered, the date range, total PR count, and the goals source used (issue ref or URL).
- One section per goal from the fetched goals source, listing matching PRs as:
  - Single-user mode: `- [#NUM repo/name](url) — title  ·  *meta-tags*`
  - Team mode: `- [#NUM repo/name](url) — title  ·  *@author*  ·  *meta-tags*` (author shown so the reader can tell who shipped what)
  Add a one-line "what it did" summary if non-obvious.
- Sections for any "Other" groups you defined, named meaningfully.
- Summary at the bottom:
  - Counts per goal.
  - Counts per meta tag.
  - **Team mode only:** counts per author (PRs shipped per person, plus a per-author goal breakdown — useful for spotting whether someone landed work outside their owned goal).
  - Any goals with zero PRs this week.
- Note any PRs that were ambiguous to categorize.

### Step 8 — Share the file

End with a `[View your retrospective](computer://...)` link to the file. Keep the chat response brief — the file is the deliverable.

## Constraints

- Use the `gh` CLI for all GitHub access; do not call the GitHub API via curl/python.
- Do not hardcode the invoking user's GitHub username — always resolve it from `gh api user`.
- Never default the goals source. It must come from the config file (or be set via setup).
- Never auto-rewrite the config file in the course of a normal run. The config is only written by the setup flow.
- If the goals source cannot be fetched (renamed, private, deleted, network error), report that and offer to re-run setup — do not silently fall back to inferred themes.
- If there are zero PRs in the last 7 days for the chosen scope, still produce the report saying so.
- In team mode, paginate carefully if any one author exceeds the `--limit 100` window — but 100 PRs/week/person can happen though, so prefer a single fetch per author and only fall back to client-side filtering if a fetch returns ≥100 items.
