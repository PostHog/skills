# impersonation-toolkit

Run impersonation-scoped audits against a customer's PostHog project via Claude Code + the PostHog MCP plugin.

Audits run under PostHog's read-only impersonation, which is enforced server-side — see [Security model](#security-model).

**What it gives you:**
- One command to spin up an impersonation audit folder per customer
- A permissions config that pre-approves the read tools, so an audit runs start to finish instead of stopping for approval dozens of times. One file for all your accounts, and it keeps whatever you approve mid-session
- A reusable audit playbook (the `experiment-audit` skill) that walks through experiment config, exposure, attribution, and metrics in a Slack-ready format

## Prerequisites

1. [Claude Code](https://docs.anthropic.com/claude/code) installed
2. PostHog MCP plugin installed (`claude plugin install posthog@claude-plugins-official`, or run `npx @posthog/wizard` once)
3. Django Admin impersonation access (PostHog staff)

## Install

```
/plugin marketplace add PostHog/skills
/plugin install impersonation-toolkit@PostHog-skills
```

Then drop the launcher shim into `~/bin/` so the wrapper always picks up the latest installed version of the plugin (run this once — no need to re-run after `claude plugin update`):

```bash
mkdir -p ~/bin
cp "$(ls -d ~/.claude/plugins/cache/PostHog-skills/impersonation-toolkit/*/ | sort -V | tail -1)scripts/impersonate-audit-shim.sh" ~/bin/impersonate-audit
chmod +x ~/bin/impersonate-audit
```

Confirm `~/bin` is on your PATH (add `export PATH="$HOME/bin:$PATH"` to your `~/.zshrc` or `~/.bashrc` if not).

The shim makes two separate checks before handing off: **is the plugin installed** (hard error, with the install command) and **is the copy stale** (warning only, at most once a day, with the update command). Silence the freshness warning with `CSM_IMPERSONATE_STALE_DAYS=0`, or widen it to a week with `=7`.

## Usage

```bash
impersonate-audit <account name>
```

For example:

```bash
impersonate-audit globex
impersonate-audit "Acme Inc"      # quotes optional — the words get joined
```

The script will:

1. Create (or reuse) `~/impersonate/<account-slug>/` — lowercase, with runs of spaces and punctuation collapsed to single hyphens, so `Acme Inc` and `Café Söda, Inc.` become `acme-inc` and `cafe-soda-inc`
2. Pause and remind you to impersonate the customer's user in Django Admin (manual step, and read-only — that's the default and what an audit needs)
3. Launch Claude Code at the impersonation root, with that folder ready for output
4. Inside Claude Code: run `/mcp`, find the `posthog` plugin, **clear authentication** then **authenticate** — this binds a fresh token from your active impersonation session
5. Sanity check by asking Claude `what project am I in?` — should be the customer's project, not yours
6. Run the audit by asking e.g. `audit <customer>'s experiment named "<experiment name>"` — the `experiment-audit` skill auto-triggers
7. On exit, the script auto-disables the posthog plugin if it's still connected and reminds you to log out of Django Admin

Audits are written to `<account-slug>/YYYY-MM-DD.md`, one file per account per day.

Other flags:

| Flag | What it does |
| --- | --- |
| `-d, --dir <path>` | Use a different impersonation root for this run |
| `--migrate` | Normalise an existing tree to the current layout (see [Migrating](#migrating-an-existing-tree)) |
| `--reset-settings` | Overwrite the shared permissions file from the plugin's template |
| `-h, --help` | Usage |

## Configuration

Two optional knobs, and that's the whole surface. Everything else the audit needs (account slug, folder, audit filename) is derived per run from the name you pass — there is nothing to set per account.

| Variable | Default | What it does |
| --- | --- | --- |
| `CSM_IMPERSONATE_HOME` | `~/impersonate` | Where per-account folders live |
| `CSM_CUSTOMER_CONTEXT_DIR` | `~/Documents/Obsidian Vault/Customers` if that directory exists, otherwise unset | Where your own per-account notes live. The `account-audit` skill reads the matching account's notes before writing findings. **Leave it unset and the skill skips notes entirely** rather than hunting around your filesystem for a vault you don't have |

Set them either in the config file, created (fully commented out) on first run at `${XDG_CONFIG_HOME:-~/.config}/impersonate-audit/config`:

```bash
CSM_IMPERSONATE_HOME="$HOME/work/impersonate"
CSM_CUSTOMER_CONTEXT_DIR="$HOME/notes/customers"
```

...or by exporting them from your own env file (`csm.env`, `~/.zshrc`, whatever) — the environment wins over the config file, and `--dir` wins over both.

## Migrating an existing tree

If you were on 1.0.x you have `~/impersonate/Acme Inc/audit-2026-08-11.md` and a `.claude/settings.local.json` in every account folder. One command folds all of it into the current layout:

```bash
impersonate-audit --migrate
```

It renames folders to their slug form, drops the `audit-` prefix from audit files, and merges every per-account permissions file into the shared one at the root (so the approvals you granted in each folder carry over rather than being thrown away). It prompts first and skips anything that would collide. Running a normal audit for an account whose folder still has the old name offers the same rename for just that account.

## Security model

Audits are read-only, enforced server-side by PostHog. The OAuth token minted from a read-only impersonation session has every write scope stripped before issue, and the API rejects mutating requests made with it. The toolkit mints no credentials of its own and can grant itself nothing.

## Permissions file — what it does

Purely operational: a PostHog audit calls dozens of read tools, and without an allowlist each one stops for approval. `assets/settings.local.json` pre-approves the read tools so a run goes start to finish, and leaves everything else to prompt normally.

The template also keeps an `ask` list for mutation-shaped tool names (`*-create`, `*-update`, `*-delete`, `execute-sql`). Not a safety layer — the server rejects writes with a read-only token regardless — but two useful side-effects:

- **Awareness.** A prompt during a read-only audit is a signal worth noticing, even though the request would fail.
- **Documentation of intent.** The list tells a new CSM which tools are treated as sensitive by convention.

It is merged into a single `.claude/settings.local.json` at the root of your impersonation tree. Claude launches at that root, so one file covers every account. Account folders are where output lands, not separate workspaces:

```
~/impersonate/                    <- Claude runs here
├── .claude/settings.local.json   <- the only permissions file
├── acme-inc/2026-08-11.md
└── initech-co/2026-08-13.md
```

Permissions are granted once. Anything you approve mid-session lands in that shared file and applies to every account from then on.

Two consequences worth knowing:

- Template updates are **merged**, not copied over the top, so `claude plugin update` can't wipe approvals you granted. Entries the template moves between `allow` and `ask` follow the template. Merging needs `jq`; without it an existing file is left untouched rather than clobbered. `--reset-settings` forces a clean copy from the template.
- Every session's working directory contains every account's folder, so a session for one customer can read another customer's audit if you ask it to. If you'd rather each session only see one account, that's yours to arrange — point `--dir` at a per-account root, or make the impersonation root a git repo (Claude Code resolves project settings to the repo root, which lets you launch inside an account folder and still share one settings file). The wrapper follows an existing repo root if it finds one; it won't create one for you.

## Updating

```
claude plugin update
```

The shim in `~/bin/impersonate-audit` always discovers the newest installed version — no manual re-symlinking needed. It also nudges you (once a day, non-fatally) when the installed copy has gone stale, so you don't audit on a months-old playbook without noticing.

## File layout

```
impersonation-toolkit/
├── .claude-plugin/plugin.json        # Plugin manifest (discovered by marketplace)
├── SKILL.md                          # Audit playbook — auto-triggers on "audit X's experiment"
├── README.md                         # This file
├── scripts/
│   ├── impersonate-audit.sh          # Wrapper invoked by the ~/bin/impersonate-audit shim
│   ├── impersonate-audit-shim.sh     # The shim itself — copy it to ~/bin/impersonate-audit
│   └── redact.sh                     # Deterministic token redactor for the two logs
└── assets/
    └── settings.local.json           # Permissions template, merged into the shared settings file
```

And what it creates on your machine:

```
${XDG_CONFIG_HOME:-~/.config}/impersonate-audit/config      # your two optional knobs
${XDG_STATE_HOME:-~/.local/state}/impersonate-audit/
├── refusals.log                                         # one JSONL entry per refused audit
└── debug.log                                            # raw MCP errors, joinable to refusals.log by session_id
$CSM_IMPERSONATE_HOME/                                   # default ~/impersonate, where Claude runs
├── .claude/settings.local.json                          # shared permissions
└── <account-slug>/<YYYY-MM-DD>.md                       # one audit per account per day
```

## Debugging failed audits

When the skill can't complete an audit — wrong MCP project, disconnected MCP, missing experiment, empty data — it refuses explicitly instead of falling back to producing prompts for you to paste elsewhere. Two logs get you the full picture:

- **`refusals.log`** — one JSONL entry per refused audit. Structured summary: account, timestamp, reason_code, what was tried, how to fix. This is the log to scan first.
- **`debug.log`** — verbose companion. Raw MCP error responses, tool names, HTTP statuses, and error classes. Token-shaped strings are redacted before write. Cross-reference via `session_id` (also printed in the launch banner).

Both live under `${XDG_STATE_HOME:-~/.local/state}/impersonate-audit/`. Neither rotates automatically; move old files aside when they get big.

```bash
# most recent refusals
jq -c . ~/.local/state/impersonate-audit/refusals.log | tail

# refusals for one account
jq -c 'select(.account == "acme-inc")' ~/.local/state/impersonate-audit/refusals.log

# count by reason
jq -r .reason_code ~/.local/state/impersonate-audit/refusals.log | sort | uniq -c | sort -rn

# pull the full raw-error trail for the most recent auth-expired refusal
SID="$(jq -r 'select(.reason_code == "mcp_auth_expired") | .session_id' \
       ~/.local/state/impersonate-audit/refusals.log | tail -1)"
jq -c "select(.session_id == \"$SID\")" ~/.local/state/impersonate-audit/debug.log
```

Reason codes: `wrong_project`, `empty_project`, `mcp_disconnected`, `mcp_auth_expired`, `switch_project_failed`, `experiment_not_found`, `tool_call_error`, `other`. See `SKILL.md` for the exact discriminator on each. (A query that returns *zero rows* is an audit finding, not a refusal — Step 3 of the playbook diagnoses that.)

Redaction is done by `scripts/redact.sh` — a small Perl script the wrapper points the skill at via `$CSM_IMPERSONATE_REDACT`. It runs outside the LLM, so a prompt-injected MCP error body can't talk the skill into skipping it. Every free-text field in either log is piped through the script before write. Patterns covered: `Bearer` tokens, PostHog `phc_/phx_/phs_/sTOK_` prefixes, JWTs, cookie/set-cookie header values, and any 24+ char base64url blob (catch-all for OAuth codes and unknown token shapes).

## Caveats

- The Django Admin impersonation step is intentionally manual (security boundary). The script can't bypass it.
- The PostHog MCP plugin's tool-name prefix is assumed to be `mcp__plugin_posthog_posthog__*`. If permission rules don't seem to apply, run the first audit, watch for unexpected prompts on read tools, and check the actual tool names exposed via `/mcp`.
- The read allowlist is broad but not exhaustive across all 300+ PostHog MCP tools, so a read tool with an unconventional name will still prompt. Harmless, just a bit of friction — PR additions to `assets/settings.local.json` in this plugin's directory.
- Account slugs are derived from the name you type, so `InitechCo` and `Initech Co` are different folders (`initechco` vs `initech-co`). Stay consistent, or point at the existing folder with `--dir` if you split one by accident.

## Maintainer

Sebastian Muriel — ping in `#project-customer-analytics` with feedback, gaps, or PRs.
