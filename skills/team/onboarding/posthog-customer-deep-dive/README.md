# PostHog customer deep dive

Research a PostHog customer account end to end, then produce the thing you actually need: an outreach email, a reply, or a full call-prep brief with a paste-ready PostHog AI notebook prompt.

It resolves the account across Vitally and the PostHog warehouse, fans out subagents to pull usage, billing, product config and competing tools in parallel, reconciles what they return, verifies every product claim against a live docs search, and writes the output into chat.

Two things it never does. It never sends, posts or writes anything to a customer or to Vitally: every artifact lands in chat for you to review and act on. And it never states a number it did not query or a product fact it did not just look up, so where something cannot be verified it gives you the question to ask instead.

## The files

`SKILL.md` is the spine and the only file loaded every run. Everything else is read on demand, so a run reads the artifact file it needs and skips the others.

| File | What it is |
|---|---|
| `SKILL.md` | The spine: workflow, the five steps, artifact routing, the common header, the pre-handover checklist |
| `config.md` | Your values and tool bindings, and the only file that differs between a personal copy and a shared one. On first run the skill fills it in itself |
| `references/agent-briefs.md` | The conventions block pasted into every subagent brief, the per-role reading map, the frozen context block, and the five return rules. Main reads it once; it is what keeps gatherers out of the big reference files |
| `references/data-rules.md` | Conventions, the id kinds, regions, the direct-connection call shapes, which source answers which question, and the traps that make a wrong number look right. Main's file; read first at Step 2 |
| `references/queries-account.md` | Resolution, the always-run core, and the Vitally warehouse reads |
| `references/queries-products.md` | One block per product: usage fields, admin activity, config reads |
| `references/queries-money.md` | Billing, credits, and LLM cost |
| `references/site-scan.md` | How to read the scan output, and the competing-tools map |
| `references/levers.md` | The lever table, adoption pitches, and product-facts starting points, read at draft time |
| `references/voice.md` | Email shape, verification discipline, the lever paragraph, banned phrasing. Read before anything a customer will see |
| `references/mode-email.md` | The email artifact: first touch, follow-up, and reply, one state table |
| `references/mode-call-prep.md` | Call prep: the six checks, the health flags, and the paste-ready PostHog AI notebook prompt. The longest mode |
| `scripts/phq.py` | Runs any HogQL query over the HTTP API, on four targets (`us`, `eu`, `ch-us`, `ch-eu`), with `--batch` for many at once |
| `scripts/site-scan.sh` | The whole site scan in one command |
| `README.md` | This file |

## What it produces

The skill picks a mode from the account's state, and your explicit ask always wins. Everything lands in chat.

| Mode | When it fires | Output |
|---|---|---|
| Email: first touch | New account, no outreach yet | Ranked contacts, cost-first findings, a short outreach email |
| Call prep | A real future meeting is on the calendar | Full internal brief (six optimization checks) plus a ready-to-paste PostHog AI notebook prompt |
| Email: follow-up | Outreach exists, no reply | What changed since last time, what they acted on, 1 to 2 new angles |
| Email: reply | They replied with a real question | Their questions answered in order, one paragraph each |
| Any other ask | Anything else | Whatever shape the ask needs, on the same verified research |

## Running it

```
/posthog-customer-deep-dive someone@theircompany.com
```

It also takes a domain, an account name, or a Vitally account ID.

Optional sources set to `none` in `config.md` are skipped without erroring, and the run tells you which ones it skipped. That is designed behavior, not a broken run.

## Setup, from a fresh Mac to a working run

Two things are required (the PostHog MCP and the Vitally MCP) plus their keys; everything else is optional and the skill skips what is set to `none` in `config.md`. Work top to bottom; each block ends with a check that proves it works. Vendor pages move, so if a URL or a command here is wrong, the vendor's own docs win.

**Credentials split two ways, and getting this wrong is the most common setup mistake.**

| Credential | Where it comes from |
|---|---|
| `VITALLY_API_KEY` | **Shared.** 1Password, General vault, item `Vitally API` (section 2) |
| `GONG_ACCESS_KEY` / `GONG_ACCESS_KEY_SECRET` | **Shared.** 1Password, General vault, item `Gong API Credentials` (section 3) |
| `POSTHOG_PERSONAL_API_KEY` (US) | **Yours.** Create it yourself in the PostHog web app (section 1) |
| `POSTHOG_PERSONAL_API_KEY_EU` | **Yours.** Same, on the EU instance (section 1) |

The Vitally and Gong keys are workspace-level, so there is one per company and copying it is correct. The PostHog keys are personal: every API call carries the identity of whoever minted the key, so using someone else's both attributes your queries to them and gives you their access instead of your own. Make your own, even if you find a colleague's in a shared vault.

### 0. The shell, so keys reach Claude Code

Claude Code's Bash tool does not read `~/.zshrc`, and an `export` in one command does not survive to the next. The pattern that works on macOS: put every key in `~/.bash_env` (POSIX syntax only), have `~/.zshenv` export `BASH_ENV=~/.bash_env` and mirror the same `export` lines, and each Bash call starts with `source ~/.zshenv`. Skill scripts and query examples assume this.

```bash
# ~/.bash_env (create it), one line per key:
export POSTHOG_PERSONAL_API_KEY="phx_..."
export POSTHOG_PERSONAL_API_KEY_EU="phx_..."
export VITALLY_API_KEY="sk_live_..."
export VITALLY_API_SUBDOMAIN="posthog"
export VITALLY_DATA_CENTER="EU"
export VITALLY_USER_EMAIL="you@posthog.com"
export GONG_ACCESS_KEY="..."
export GONG_ACCESS_KEY_SECRET="..."
export GONG_API_URL="https://api.gong.io/v2"

# ~/.zshenv: the same export lines, plus
export BASH_ENV="$HOME/.bash_env"
```

Check: `bash -c 'source ~/.zshenv; echo ${VITALLY_API_KEY:0:8}'` prints the first characters of the key. Keys never go in `config.md`, in the skill folder, or in a git repo.

Skills live at `~/.claude/skills/<name>/SKILL.md`; copy this whole folder there. MCP servers registered with `--scope user` land in `~/.claude.json` and are available in every project. Allow the tools once in `~/.claude/settings.json` so runs do not prompt per call:

```json
{ "permissions": { "allow": ["mcp__posthog__*", "mcp__vitally__*", "mcp__gong__*"] } }
```

Restart Claude Code after any change to `~/.claude.json` or the shell files.

### 1. PostHog MCP (required) and two personal API keys

The MCP is the primary path for every project-2 query and for `docs-search`. Register the remote server, then log in when first prompted (`/mcp` in Claude Code opens the browser flow):

```bash
claude mcp add --transport http posthog https://mcp.posthog.com/mcp -s user
```

Sign in with your PostHog staff account; the auth server routes to your data region. It appears as one exec-style gateway tool: search your tool list for "posthog" or "exec", `info <tool>` then `call <tool> <json>`. A server named `posthog` with no exec command is an unauthenticated duplicate; remove it. If the gateway offers only a small read-only toolset, re-authenticate; the full set appears. Project 2 is PostHog's own internal project, so staff access is the real prerequisite. Docs: https://posthog.com/docs/model-context-protocol/claude-code.

Two personal API keys, for the HTTP fallback (`scripts/phq.py`) and the direct ClickHouse reads. **Create both yourself in the web app. Do not reuse one from a shared vault**, however convenient: a personal key carries the identity of whoever made it, so PostHog attributes every call to that person, and you inherit their access rather than exercising your own.

- **US key**: `https://us.posthog.com/settings/user-api-keys`, "+ Create a personal API Key", read-only preset (or `query:read` plus `project:read` at minimum), scoped to the organization. Copy it once; PostHog shows it once. Store as `POSTHOG_PERSONAL_API_KEY`.
- **EU key**: the same at `https://eu.posthog.com/settings/user-api-keys`, minted while logged into the EU instance. US and EU are separate hosts with separate logins, so a US key is rejected by `eu.posthog.com`. Store as `POSTHOG_PERSONAL_API_KEY_EU`. Without it, EU accounts still run but their raw-event reads (event mix, identity mix, replay volume) and experiment definitions come back as unavailable rather than measured. Docs: https://posthog.com/docs/api/personal-api-keys, regions at https://posthog.com/docs/api.

Check: `python3 scripts/phq.py us "SELECT 1"` and `python3 scripts/phq.py eu "SELECT 1"` both return a row.

### 2. Vitally MCP (required until October 2026)

Source: https://github.com/PostHog/vitally-mcp-cs (private to the PostHog org; `gh auth` first, section 6).

```bash
git clone https://github.com/PostHog/vitally-mcp-cs.git "$HOME/Code/vitally-mcp-cs"
cd "$HOME/Code/vitally-mcp-cs" && npm install && cd vitally && npm run build
```

The API key is workspace-level rather than per user, so **take PostHog's shared key from 1Password rather than creating a second one**. The item is **`Vitally API`** in the **General** vault of the PostHog account, category API credential:

```bash
export VITALLY_API_KEY=$(op item get "Vitally API" --vault General --fields credential | tr -d '"[:space:]')
export VITALLY_API_SUBDOMAIN=posthog
export VITALLY_DATA_CENTER=EU
export VITALLY_USER_EMAIL=you@posthog.com
```

That item also carries `hostname` (`https://rest.vitally-eu.io`) and a prebuilt `Basic Auth Header`, which is the value to use for raw curl against the REST API.

**One decoy to know about.** A second item, `Vitally REST API`, sits in the same vault as a plain secure note holding the same token in clear text alongside its URL and auth header. It is not a different key and not a backup: it is a duplicate, and a note is a worse home for a live credential than an API-credential item, because it cannot be revealed field by field and gets pasted whole. Use `Vitally API` and treat the note as something to retire.

Only if the key is ever revoked, and it needs a Vitally admin: Vitally Settings (account logo, top left) > Integrations > "Vitally REST API", toggle on, create a named key. The workspace is `posthog` on the EU data center. Docs: https://docs.vitally.io/en/articles/9880649-rest-api-overview.

Register it with the credentials as env vars on the server (so the launch is cwd-independent) and a `cd` into `vitally/` so its cache writes land inside the repo:

```bash
claude mcp add --scope user --transport stdio \
  -e VITALLY_API_KEY="$VITALLY_API_KEY" -e VITALLY_API_SUBDOMAIN=posthog \
  -e VITALLY_DATA_CENTER=EU -e VITALLY_USER_EMAIL=you@posthog.com -e NODE_ENV=production \
  vitally -- sh -c 'cd "$HOME/Code/vitally-mcp-cs/vitally" && exec node build/server.js'
```

Update with `./update.sh` in the repo (pulls, installs, rebuilds) at the start of any Vitally-heavy week. Check: after restart, `mcp__vitally__health_check` returns ok, and `mcp__vitally__get_user_details` on a known customer email returns an account. Temporary by design: the Vitally contract ends October 2026, when the account layer moves to PostHog Customer Analytics.

### 3. Gong MCP (default transcript source)

Everyone at PostHog records to Gong, so it is the skill's default for call transcripts and summaries; Wispr Flow, Quill or Granola stay as fallbacks in `config.md`.

**Key: take it from 1Password, do not mint a new one.** The item is **`Gong API Credentials`** in the **General** vault of the PostHog account, category API credential. Map its two fields straight across:

```bash
export GONG_ACCESS_KEY=$(op item get "Gong API Credentials" --vault General --fields "label=Access key" | tr -d '"[:space:]')
export GONG_ACCESS_KEY_SECRET=$(op item get "Gong API Credentials" --vault General --fields "label=Secret key" | tr -d '"[:space:]')
export GONG_API_URL="https://api.gong.io/v2"
```

Three things about that item, each of which costs an afternoon if you meet it cold.

**The `tr -d` is not optional.** Two separate things add characters. The stored access key carries a **leading space**, so it is one longer than the real key. And `op --fields` wraps whatever it returns in double quotes and appends a newline, so a bare `$(op item get ...)` hands you a key with a quote at each end. Both values are alphanumeric (the secret is a JWT), so stripping quotes and whitespace is safe and gets you the exact key. Skip it and Gong will authenticate you anyway on some calls, which is worse than a clean failure, because the bad value only breaks later and somewhere else.

**Ignore the item's `url` field.** It reads `https://us-26000.api.gong.io`, which is the Gong web host, not the API host, and every request against it 404s. The working base is `https://api.gong.io/v2` and that is what `GONG_API_URL` takes.

**Four other Gong items in that vault are the wrong ones.** `Gong` is the web login and carries no API fields. `Gong Claude MCP Server` holds an OAuth client id and secret, a different auth scheme entirely. `Gong API Key for PostHog DW` and `Gong API Key` are both valid access-key pairs for other consumers, so they look right and fail against the roles this skill needs.

Only if the key is ever revoked: Gong left sidebar > Admin center > Settings > Ecosystem > API > "+ Get API key", which needs the Tech admin role and shows the secret once. Docs: https://help.gong.io/docs/receive-access-to-the-api.

Server: a local build of https://github.com/JustinBeckwith/gongio-mcp, chosen because its `get_call_transcript` pages through the full transcript (`offset`/`maxLength`), which the alternatives do not. Build from source rather than `npx`: `main` yields 15 tools instead of the published 12, and one line needs patching so the base URL is configurable.

```bash
git clone https://github.com/JustinBeckwith/gongio-mcp.git "$HOME/Code/gongio-mcp"
cd "$HOME/Code/gongio-mcp"
# in src/gong.ts, change the hardcoded base to:  process.env.GONG_API_URL || 'https://api.gong.io/v2'
npm install && npm run build
claude mcp add --scope user --transport stdio gong -- \
  sh -c 'export PATH=/opt/homebrew/bin:$PATH; set -a; . "$HOME/.bash_env" >/dev/null 2>&1; set +a; exec node "$HOME/Code/gongio-mcp/dist/index.js"'
```

The wrapper sources `~/.bash_env` so the keys reach the server; the redirect keeps shell noise out of the MCP JSON stream. Re-apply the one-line patch after any `git pull` that touches `src/gong.ts`. Check: `mcp__gong__search_calls` with your email in `participantEmails` and a two-week window lists your calls; `get_call_transcript` on one of them reports "showing 1-10000 of N", and paging by `offset` reaches N.

### 4. Google Calendar and Gmail, via `gog`

The calendar read (booking-form answers in the event description) uses the `gog` CLI: https://github.com/steipete/gogcli (module now `github.com/openclaw/gogcli`; quickstart at https://gogcli.sh/quickstart.html).

```bash
brew install openclaw/tap/gogcli        # or: go install github.com/openclaw/gogcli/cmd/gog@latest
gog auth setup you@posthog.com --gcloud-project my-gog-project --enable-apis --open-console
```

The guided setup walks the Google Cloud side: create a project, enable the Calendar and Gmail APIs, an External OAuth consent screen, a Desktop OAuth client, download its JSON. Then:

```bash
gog auth credentials ~/Downloads/client_secret_*.json
gog auth add you@posthog.com --services gmail,calendar
gog auth doctor --check
```

Publish the OAuth app on the audience page (`console.cloud.google.com/auth/audience`) or the test-user token expires weekly. Tokens live in the macOS Keychain. Check: `gog calendar events --account you@posthog.com --from 2026-08-01 --to 2026-08-31` lists events. Put your work email in `config.md` as the calendar id.

### 5. Clay (optional enrichment)

Clay's official Claude path is a claude.ai connector, not a local MCP: add it from the claude.ai Connectors page (an org admin enables it first), sign in with your Clay account, and Claude Code inherits it (toggle per project under `/mcp`). The endpoint under the hood is `https://api.clay.com/v3/mcp` via OAuth; a direct `claude mcp add` of that URL is reported to fail on Clay's client-name check, so use the connector. Enrichments cost Clay credits (roughly 20 to 100 per call), and admins can cap credits per rep from the MCP section in Clay's side nav. Docs: https://www.clay.com/guides/clay-mcp. Set the tool names in `config.md`; `none` skips it.

### 6. GitHub CLI (optional, for reading PostHog source)

```bash
brew install gh
gh auth login -h github.com -p https -w -s repo
gh repo view PostHog/vitally-mcp-cs      # check: private org repo readable
```

If that returns 403 or 404 after login, authorize the GitHub CLI OAuth app for the PostHog org under your GitHub token settings (SAML SSO). Docs: https://cli.github.com/manual/gh_auth_login. The skill uses it to read billable-meter definitions in `PostHog/posthog` and the docs source; never as a citation.

### 7. Slack search (optional)

Claude Code inherits a claude.ai Slack connector, or install the plugin: `/plugin install slack` in Claude Code, which configures `https://mcp.slack.com/mcp` with browser OAuth (a workspace admin approves it once). Docs: https://docs.slack.dev/ai/slack-mcp-server/connect-to-claude/. Put the search and channel-read tool names in `config.md`.

### 8. First run

Copy the folder to `~/.claude/skills/posthog-customer-deep-dive/`, restart Claude Code, run the skill on any account. Setup in `SKILL.md` probes the tool list and the env, shows what it found, asks only for the two values it cannot detect (calendar id, booking link), and writes `config.md`. A run with every optional source at `none` is valid; the run names what it skipped.

**The skill never impersonates and never assumes you will.** It works with the tools above and names what they cannot reach, so a gap comes back as "not readable, here is the question to ask" rather than a blocked run. A handful of reads sit outside it: their replay and heatmap tables and the unqueried-events join on US (all three read fine on EU), and Actions and property definitions on EU. If you want any of those before a call, get them yourself with the [impersonation toolkit](https://github.com/PostHog/skills/tree/main/skills/team/customer-success/impersonation-toolkit).

## What each optional source adds

| Source | What it adds | The catch |
|---|---|---|
| Google Calendar (`gog`) | The booking-form answers, which live in the event description and are the best input to a call brief | Needed for a complete call prep. Without it the brief still builds, with meeting details marked pending |
| Gong | Prior calls on the account, including ones a teammate hosted, with full transcripts and AI summaries | Transcript pages at 10KB; the skill loops on `offset` to the end |
| Clay | Who the company and the people actually are (Tech Stack is the highest-value signal) | Costs credits per enrichment. Returns nothing useful for solo founders and gmail admins |
| Slack, meeting notes | Prior context on the account that was never written down anywhere official | Anything left `none` is skipped |

## Maintaining this skill

Maintainer: **Daniel Danilov** (`daniel.d@posthog.com`). Report anything broken by opening an issue on this repo, or in `#team-onboarding`.

It leans on things that change without notice, so expect to fix it rather than to install it once:

- The **Vitally MCP** and every `vitally.*` table retire with the Vitally contract in October 2026. The account layer moves to PostHog Customer Analytics, which is a rewrite of Step 1 and the CRM reads, not a patch.
- **Warehouse tables and columns change liberally.** The skill probes rather than assumes wherever it can, and names what it could not measure, but a query that returns nothing is as likely to be stale here as absent there.
- **Product state is never recorded in this skill**, by design: prices, tiers, free allowances, SDK support and where a setting lives are searched live on every run. If you find one written down, that is a bug and deleting it is the fix.

When a run reveals a fix, `SKILL.md` closes with how to fold it back in.

