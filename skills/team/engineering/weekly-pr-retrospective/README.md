# Weekly PR retrospective

A Claude skill that produces a categorized weekly PR retrospective for an engineer or a small team, mapping each PR to a goal/objective defined in a source you set up once (a GitHub issue or a public web page).

## What it does

- Fetches your last 7 days of PRs across the PostHog GitHub org.
- Pulls a list of goals/objectives from a source you configured during setup.
- Categorizes each PR against those goals and tags it with a meta-label (`feature`, `maintenance`, `bug`, `incident`, `infra`, `docs`, `test`, `chore`).
- Writes a markdown report to `~/Development/<year-week>/pr-retrospective-<scope>-YYYY-MM-DD.md` and links to it.

## Requirements

- `gh` CLI installed and authenticated (`gh auth login`).
- For team mode: read access to the relevant PostHog repos via your `gh` auth.
- For website goal sources: outbound HTTPS access (the skill uses `WebFetch`).

## First-run setup

The first time you invoke the skill (or any time `~/.config/weekly-pr-retrospective/config.json` is missing), it walks you through a one-time setup:

1. **Goals source** — paste either:
   - A GitHub issue shorthand: `owner/repo#NUM` (e.g. `acme/infra#42`)
   - A GitHub issue URL: `https://github.com/<owner>/<repo>/issues/<num>`
   - Any public `https://` URL pointing to a page that lists goals (e.g. a Notion public page, a docs page)
2. **Team handles** — comma-separated list of GitHub handles to include in `team` mode (no `@`). You can leave it blank if you only ever want single-user mode.

The answers are written to `~/.config/weekly-pr-retrospective/config.json`. Subsequent invocations skip the setup step entirely.

To re-run setup later (e.g. to point at a new goals source or update team handles):

```text
/weekly-pr-retrospective setup
```

### Config file schema

```json
{
  "goals_source": "acme/infra#42",
  "team": ["alice", "bob", "carol"]
}
```

## Usage

```text
/weekly-pr-retrospective           # single-user mode (just you)
/weekly-pr-retrospective team      # team mode (you + saved team handles)
/weekly-pr-retrospective setup     # re-run the one-time setup flow
```

## Modes

- **Single-user (default)** — covers only the PRs you (the invoking user, resolved via `gh api user`) opened in the last 7 days.
- **Team** — adds the saved team handles from the config file and includes a per-author breakdown.

## Output

The report file lands at:

```text
~/Development/<ISO-year-week>/pr-retrospective-<user|team>-YYYY-MM-DD.md
```

It contains:

- Header with mode, authors, date range, PR count, and the goals source used.
- One section per goal pulled from the source, listing matching PRs.
- Sensibly-named "Other" sections for PRs that don't map to any listed goal.
- Summary counts (per goal, per meta-tag, and per author in team mode).

## Files

```text
weekly-pr-retrospective/
├── README.md              # This file
├── SKILL.md               # Main skill instructions
└── .claude-plugin/
    └── plugin.json        # Plugin metadata (auto-discovered by the marketplace)
```
