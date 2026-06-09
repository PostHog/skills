# impersonation-toolkit

Run safer impersonation-scoped audits against a customer's PostHog project via Claude Code + the PostHog MCP plugin.

**What it gives you:**
- One command to spin up an impersonation audit folder per customer
- A permissions config that auto-approves reads and creates but always prompts on updates, deletes, or archives — so Claude can investigate freely without ever silently mutating a customer's project
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

Then create a tiny shim in `~/bin/` so the wrapper script always picks up the latest installed version of the plugin (run this once — no need to re-run after `claude plugin update`):

```bash
mkdir -p ~/bin && cat > ~/bin/impersonate-audit <<'EOF'
#!/usr/bin/env bash
LATEST=$(ls -1d ~/.claude/plugins/cache/PostHog-skills/impersonation-toolkit/*/ 2>/dev/null | sort -V | tail -1)
if [[ -z "$LATEST" ]]; then
  echo "impersonation-toolkit plugin not installed. Run: /plugin install impersonation-toolkit@PostHog-skills" >&2
  exit 1
fi
exec "${LATEST}scripts/impersonate-audit.sh" "$@"
EOF
chmod +x ~/bin/impersonate-audit
```

Confirm `~/bin` is on your PATH (add `export PATH="$HOME/bin:$PATH"` to your `~/.zshrc` or `~/.bashrc` if not).

## Usage

```bash
impersonate-audit <customer-slug>
```

For example:

```bash
impersonate-audit givebutter
```

The script will:

1. Create (or reuse) `~/impersonate/<customer-slug>/` and refresh the permissions config from the plugin's template
2. Pause and remind you to impersonate the customer's user in Django Admin (manual step — pick **read-only** by default; only pick read+write if you'll actually need to create something in the customer's account during the audit, e.g. an example experiment or dashboard)
3. Launch Claude Code in the folder
4. Inside Claude Code: run `/mcp`, find the `posthog` plugin, **clear authentication** then **authenticate** — this binds a fresh token from your active impersonation session
5. Sanity check by asking Claude `what project am I in?` — should be the customer's project, not yours
6. Run the audit by asking e.g. `audit <customer>'s experiment named "<experiment name>"` — the `experiment-audit` skill auto-triggers
7. On exit, the script auto-disables the posthog plugin if it's still connected and reminds you to log out of Django Admin

## Security model

The toolkit relies on two independent layers of defense — both have to fail for an unwanted mutation to land in a customer's account:

1. **Impersonation token scope (server-side).** When you impersonate a user in Django Admin and select **read-only**, PostHog's OAuth authorization server downgrades every `:write` scope to `:read` before minting the access token. Even if a client requests broad scopes, the resulting token literally cannot write. This is enforced server-side, not by the client. Default to read-only impersonation; only escalate to read+write when you need to create something in the customer's account.

2. **Claude Code permission rules (client-side).** `assets/settings.local.json` is copied into every customer folder on each run as `.claude/settings.local.json`. It defines two lists:

   - **`allow`** — auto-approved patterns. Strictly reads — list/get/retrieve/search/query/stats/counts/etc.
   - **`ask`** — patterns that always prompt for explicit confirmation: updates, deletes, archives, creates (`*-create`, `create-*`), and `execute-sql`. The skill itself is read-only by design — creates and SQL are user-driven (e.g. spinning up an example experiment during a demo, or running an ad-hoc HogQL query), and require an explicit one-click approval each time. 7 specific exact-name overrides for destructive `*-create` tools (e.g. `feature-flags-bulk-delete-create`) remain even though the broad `*-create` pattern now covers them — they serve as documentation of the known-destructive set.

   Anything not matched by either list falls through to Claude Code's default behavior (prompt).

The combination means: every mutative operation surfaces as a prompt before it fires (client-side defense), AND if a tool somehow slipped through, the read-only impersonation token rejects the write at the API layer (server-side defense). Both have to fail for an unwanted change to land.

Updates to the permission template ship via `claude plugin update`.

## Updating

```
claude plugin update
```

The shim in `~/bin/impersonate-audit` always discovers the newest installed version — no manual re-symlinking needed.

## File layout

```
impersonation-toolkit/
├── .claude-plugin/plugin.json        # Plugin manifest (discovered by marketplace)
├── SKILL.md                          # Audit playbook — auto-triggers on "audit X's experiment"
├── README.md                         # This file
├── scripts/
│   └── impersonate-audit.sh          # Wrapper invoked by ~/bin/impersonate-audit shim
└── assets/
    └── settings.local.json           # Permissions template, copied into each customer folder
```

## Caveats

- The Django Admin impersonation step is intentionally manual (security boundary). The script can't bypass it.
- The PostHog MCP plugin's tool-name prefix is assumed to be `mcp__plugin_posthog_posthog__*`. If permission rules don't seem to apply, run the first audit, watch for unexpected prompts on read tools, and check the actual tool names exposed via `/mcp`.
- Permission template pattern coverage is broad but not exhaustive across all 300+ PostHog MCP tools. New tool names that don't follow conventional `-create` / `-update` / `-delete` suffixes will default to "ask" — safe, but you may get unexpected prompts. PR additions to `assets/settings.local.json` in this plugin's directory.

## Maintainer

Sebastian Muriel — ping in `#project-customer-analytics` with feedback, gaps, or PRs.
