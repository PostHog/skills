# PostHog customer deep dive

Research a PostHog customer account end to end, then produce the thing you actually need: an outreach email, a reply, or a full call-prep brief with a paste-ready PostHog AI notebook prompt.

It resolves the account in PostHog Customer Analytics, reads everything onboarding's own `Onboarding::` workflows and the team's emails did on it, fans out subagents to pull usage, billing, product config and competing tools in parallel, reconciles what they return, verifies every product claim against a live docs search, and writes the output into chat.

Two things it never does. It never sends, posts or writes anything to a customer, to PostHog or to Salesforce: every artifact lands in chat for you to review and act on. And it never states a number it did not query or a product fact it did not just look up, so where something cannot be verified it gives you the question to ask instead.

## The files

`SKILL.md` is the spine and the only file loaded every run. Everything else is read on demand, so a run reads the artifact file it needs and skips the others.

| File | What it is |
|---|---|
| `SKILL.md` | The spine: workflow, the five steps, artifact routing, the common header, the pre-handover checklist |
| `config.md` | Your values and tool bindings, and the only file that differs between a personal copy and a shared one. On first run the skill fills it in itself |
| `references/agent-briefs.md` | The conventions block pasted into every subagent brief, the per-role reading map, the frozen context block, and the five return rules. Main reads it once; it is what keeps gatherers out of the big reference files |
| `references/data-rules.md` | Conventions, the id kinds, regions, the direct-connection call shapes, which source answers which question, and the traps that make a wrong number look right. Main's file; read by main from Step 1, only the sections its reading-map row names |
| `references/queries-account.md` | Resolution, the always-run core, and the Customer Analytics reads: the onboarding model, the automation timeline and the email-sync comms record |
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
| Email: first touch | New account, nothing sent yet by hand or by the Email sequence | Ranked contacts, cost-first findings, a short outreach email |
| Call prep | A real future meeting is on the calendar | Full internal brief (six optimization checks) plus a ready-to-paste PostHog AI notebook prompt |
| Email: follow-up | Outreach exists, no reply | What changed since last time, what they acted on, 1 to 2 new angles |
| Email: reply | They replied with a real question | Their questions answered in order, one paragraph each |
| Account brief | Onboarding should not email the account: opted out, owned by a CSM, AE or TAM, referred to sales, not eligible, or someone else at PostHog already in touch | The research, the reason there is nothing to send, and who to loop in |
| Any other ask | Anything else | Whatever shape the ask needs, on the same verified research |

## Running it

```
/posthog-customer-deep-dive someone@theircompany.com
```

It also takes a domain, an account name, a PostHog org ID, or a Customer Analytics account ID.

Optional sources set to `none` in `config.md` are skipped without erroring, and the run tells you which ones it skipped. That is designed behavior, not a broken run.

## Install

This is a **Claude Code plugin**, published in the `PostHog/skills` GitHub repo, and the plugin is how you install it on your own machine. A copy also sits in PostHog's in-app skills store on project 2 (`us.posthog.com/project/2/skills`, or `skill-list` over the PostHog MCP), which is what PostHog's own cloud runs, like the `@PostHog` Slack app, use for that copy's owners. The store copy carries cloud-only config, so don't install from it locally. A working PostHog MCP connection is what the skill queries through once it runs; it is not how you install it.

Pick **one** of the two routes below. Doing both leaves two copies competing to fire. Restart Claude Code when you are done either way.

### Route A: the plugin marketplace (recommended)

Every command exists in two forms. Inside a Claude Code session, type the slash form. In a plain terminal, type the `claude` form. They do the same thing, so use whichever you are already sitting in.

In a Claude Code session:

```
/plugin marketplace add PostHog/skills
/plugin marketplace update PostHog-skills
/plugin install posthog-customer-deep-dive@PostHog-skills
```

In a terminal:

```bash
claude plugin marketplace add PostHog/skills
claude plugin marketplace update PostHog-skills
claude plugin install posthog-customer-deep-dive@PostHog-skills
```

Three things trip people up, all of them silent:

1. **The marketplace name is `PostHog-skills`, capitals included.** `posthog-skills` does not resolve.
2. **Run the `update` line even on a first install.** Install reads your local cached copy of the marketplace, not GitHub, so a stale cache serves an old version or reports the skill as missing entirely.
3. **Restart Claude Code afterwards.** Nothing applies until you do.

To update later, the same two lines plus a restart:

```bash
claude plugin marketplace update PostHog-skills
claude plugin update posthog-customer-deep-dive@PostHog-skills
```

Updates are never automatic, and the skill tells you when you are behind: it compares its own version against the published one once a day and prints these commands if they differ.

### Route B: copy the folder

Works fine and needs no marketplace. The tradeoff is that updating means repeating it.

```bash
git clone https://github.com/PostHog/skills.git
cp -r skills/skills/team/onboarding/posthog-customer-deep-dive ~/.claude/skills/
```

The doubled `skills/skills` is correct: the repo is named `skills` and has a `skills/` directory inside it.

### After either route

Installing gets you the files, not the credentials. Work through Setup below before the first real run, or just run the skill and let it walk you through what is missing.

Your personal values (work calendar ID, timezone, meeting notes folder, tool names) go in `~/.claude/posthog-customer-deep-dive.local.md`, which the skill creates for you on first run. It sits outside the skill folder because a plugin update replaces that folder, and outside the repo, so it can never reach a pull request. `config.md` is the shared file: defaults, and the tool notes in its "Yours" column. Both are read every run and your file wins where they overlap. An older install's `config.local.md` in the skill folder still works.

## Setup, from a fresh Mac to a working run

Required: the PostHog MCP and your US personal PostHog key, plus the EU key for EU accounts; everything else is optional and the skill skips what is set to `none` in `config.md`. Work top to bottom; each block ends with a check that proves it works. Vendor pages move, so if a URL or a command here is wrong, the vendor's own docs win.

**Credentials split two ways, and getting this wrong is the most common setup mistake.**

| Credential | Where it comes from |
|---|---|
| `GONG_ACCESS_KEY` / `GONG_ACCESS_KEY_SECRET` | **Shared.** 1Password, General vault, item `Gong API Credentials` (section 2) |
| `POSTHOG_PERSONAL_API_KEY` (US) | **Yours.** Create it yourself in the PostHog web app (section 1) |
| `POSTHOG_PERSONAL_API_KEY_EU` | **Yours.** Same, on the EU instance (section 1) |

The Gong key is workspace-level, so there is one per company and copying it is correct. The PostHog keys are personal: every API call carries the identity of whoever minted the key, so using someone else's both attributes your queries to them and gives you their access instead of your own. Make your own, even if you find a colleague's in a shared vault.

### 0. The shell, so keys reach Claude Code

If a key you exported in `~/.zshrc` does not reach Claude Code's Bash tool (an `export` in one command never survives to the next), this pattern works on macOS: put every key in `~/.bash_env` (POSIX syntax only), have `~/.zshenv` export `BASH_ENV=~/.bash_env` and mirror the same `export` lines, and each Bash call starts with `source ~/.zshenv`. Skill scripts and query examples assume this.

```bash
# ~/.bash_env (create it), one line per key:
export POSTHOG_PERSONAL_API_KEY="phx_..."
export POSTHOG_PERSONAL_API_KEY_EU="phx_..."
export GONG_ACCESS_KEY="..."
export GONG_ACCESS_KEY_SECRET="..."
export GONG_API_URL="https://api.gong.io/v2"

# ~/.zshenv: the same export lines, plus
export BASH_ENV="$HOME/.bash_env"
```

Check: `bash -c 'source ~/.zshenv; echo ${POSTHOG_PERSONAL_API_KEY:0:8}'` prints the first characters of the key. Keys never go in `config.md`, in the skill folder, or in a git repo.

Skills live at `~/.claude/skills/<name>/SKILL.md`; on Route B, copy this whole folder there. MCP servers registered with `--scope user` land in `~/.claude.json` and are available in every project. Allow the tools once in `~/.claude/settings.json` so runs do not prompt per call:

```json
{ "permissions": { "allow": ["mcp__posthog__*", "mcp__gong__*"] } }
```

Restart Claude Code after any change to `~/.claude.json` or the shell files.

### 1. PostHog MCP (required) and two personal API keys

The MCP is the primary path for every project-2 query and for `docs-search`. Register the remote server, then log in when first prompted (`/mcp` in Claude Code opens the browser flow):

```bash
claude mcp add --transport http posthog https://mcp.posthog.com/mcp -s user
```

Sign in with your PostHog staff account; the auth server routes to your data region. It appears as one exec-style gateway tool: search your tool list for "posthog" or "exec", `info <tool>` then `call <tool> <json>`. A server named `posthog` with no exec command is an unauthenticated duplicate; remove it. If the gateway offers only a small read-only toolset, re-authenticate; the full set appears. If `search` reports tools hidden for missing scopes (`customer_task:read`, `customer_analytics:read`, `conversation:read`), re-authorize the connection and approve them; the skill reads the same Customer Analytics data through SQL, so it runs either way. Project 2 is PostHog's own internal project, so staff access is the real prerequisite. Docs: https://posthog.com/docs/model-context-protocol/claude-code.

Two personal API keys, for `scripts/phq.py`: the direct ClickHouse reads, which every run needs, and the fallback when the MCP is down. **Create both yourself in the web app. Do not reuse one from a shared vault**, however convenient: a personal key carries the identity of whoever made it, so PostHog attributes every call to that person, and you inherit their access rather than exercising your own.

- **US key**: `https://us.posthog.com/settings/user-api-keys`, "+ Create a personal API Key", read-only preset (or `query:read` plus `project:read` at minimum), scoped to the organization. Copy it once; PostHog shows it once. Store as `POSTHOG_PERSONAL_API_KEY`.
- **EU key**: the same at `https://eu.posthog.com/settings/user-api-keys`, minted while logged into the EU instance. US and EU are separate hosts with separate logins, so a US key is rejected by `eu.posthog.com`. Store as `POSTHOG_PERSONAL_API_KEY_EU`. Without it, EU accounts still run but their raw-event reads (event mix, identity mix, replay volume) and experiment definitions come back as unavailable rather than measured. Docs: https://posthog.com/docs/api/personal-api-keys, regions at https://posthog.com/docs/api.

Check: `python3 <skill folder>/scripts/phq.py us 'SELECT 1'` and the same with `eu` both return a row. The skill folder is `~/.claude/skills/posthog-customer-deep-dive` on Route B and the versioned folder under `~/.claude/plugins/cache/` on Route A.

### 2. Gong MCP (default transcript source)

Everyone at PostHog records to Gong, including calls you did not run, so it is the skill's default for call transcripts and summaries. A notetaker that keeps your own recordings on your machine can be added as a fallback in `config.local.md`.

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
  sh -c 'export PATH=/opt/homebrew/bin:/usr/local/bin:$PATH; set -a; . "$HOME/.bash_env" >/dev/null 2>&1; set +a; exec node "$HOME/Code/gongio-mcp/dist/index.js"'
```

The wrapper sources `~/.bash_env` so the keys reach the server; the redirect keeps shell noise out of the MCP JSON stream. Re-apply the one-line patch after any `git pull` that touches `src/gong.ts`. Check: `mcp__gong__search_calls` with your email in `participantEmails` and a two-week window lists your calls; `get_call_transcript` on one of them reports "showing 1-10000 of N", and paging by `offset` reaches N.

### 3. Work calendar (optional)

**Optional. Set it to `none` in `config.md` and the only thing you lose is the booking-form answers in a call-prep brief.** Everything else in the skill runs without it.

The default needs no install: the **Google Calendar MCP** (the claude.ai Google Calendar connector, enabled from the Connectors page and inherited by Claude Code). Call `list_events` with `calendarId`, `startTime`/`endTime` and `orderBy: startTime`; the event `description` carries the Calendly answers verbatim. Do not reach for `search_events`: it takes no time window, which is what made a CLI look necessary here.

The rest of this section is for `gog`, which reads Gmail as well. The skill reads Gmail for one thing, the full body of a thread the email sync already tied to the account, and the claude.ai Gmail connector does that with no install: https://github.com/steipete/gogcli (module now `github.com/openclaw/gogcli`; quickstart at https://gogcli.sh/quickstart.html).

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

Publish the OAuth app on the audience page (`console.cloud.google.com/auth/audience`) or the test-user token expires weekly. Tokens live in the macOS Keychain. Check: `gog calendar events --account you@posthog.com --from <YYYY-MM-DD> --to <YYYY-MM-DD>` lists events. Put your work email in your personal config as the Work calendar ID.

### 4. Clay (optional enrichment)

Clay's official Claude path is a claude.ai connector, not a local MCP: add it from the claude.ai Connectors page (an org admin enables it first), sign in with your Clay account, and Claude Code inherits it (toggle per project under `/mcp`). The endpoint under the hood is `https://api.clay.com/v3/mcp` via OAuth; a direct `claude mcp add` of that URL is reported to fail on Clay's client-name check, so use the connector. Enrichments cost Clay credits (roughly 20 to 100 per call), and admins can cap credits per rep from the MCP section in Clay's side nav. Docs: https://www.clay.com/guides/clay-mcp. Set the tool names in `config.md`; `none` skips it.

### 5. GitHub CLI (optional, for reading PostHog source)

```bash
brew install gh
gh auth login -h github.com -p https -w -s repo
gh repo view PostHog/requests-for-comments-internal      # check: private org repo readable
```

If that returns 403 or 404 after login, authorize the GitHub CLI OAuth app for the PostHog org under your GitHub token settings (SAML SSO). Docs: https://cli.github.com/manual/gh_auth_login. The skill uses it to read billable-meter definitions in `PostHog/posthog` and the docs source; never as a citation.

### 6. Slack search (optional)

Claude Code inherits a claude.ai Slack connector, or install the plugin: `/plugin install slack` in Claude Code, which configures `https://mcp.slack.com/mcp` with browser OAuth (a workspace admin approves it once). Docs: https://docs.slack.dev/ai/slack-mcp-server/connect-to-claude/. Put the search and channel-read tool names in `config.md`.

### 7. First run

With the skill installed and the keys in place, run it on any account. Setup in `SKILL.md` probes the tool list and the env, shows what it found, asks only for the two values it cannot detect (calendar id, booking link), and writes your values to `~/.claude/posthog-customer-deep-dive.local.md`, never to `config.md`. A run with every optional source at `none` is valid; the run names what it skipped.

**The skill never impersonates and never assumes you will.** It works with the tools above and names what they cannot reach, so a gap comes back as "not readable, here is the question to ask" rather than a blocked run. A handful of reads sit outside it: their replay and heatmap tables and the unqueried-events join on US (all three read fine on EU), and Actions and property definitions on EU. If you want any of those before a call, get them yourself with the [impersonation toolkit](https://github.com/PostHog/skills/tree/main/skills/team/customer-success/impersonation-toolkit).

## What each optional source adds

| Source | What it adds | The catch |
|---|---|---|
| Gmail (connector, or `gog`) | The full body of an email thread the email sync already tied to the account | The sync keeps about 500 characters of the latest message only. Gmail reads your own mailbox, so a teammate's thread needs their copy |
| Google Calendar (connector, or `gog`) | The booking-form answers, which live in the event description and are the best input to a call brief | Needed for a complete call prep. Without it the brief still builds, with meeting details marked pending |
| Gong | Prior calls on the account, including ones a teammate hosted, with full transcripts and AI summaries | Transcript pages at 10KB; the skill loops on `offset` to the end |
| Clay | Who the company and the people actually are (Tech Stack is the highest-value signal) | Costs credits per enrichment. Returns nothing useful for solo founders and gmail admins |
| Slack, meeting notes | Prior context on the account that was never written down anywhere official | Anything left `none` is skipped |

## Maintaining this skill

Maintainer: **Daniel Danilov** (`daniel.d@posthog.com`). Report anything broken by opening an issue on this repo, or in `#team-onboarding`.

It leans on things that change without notice, so expect to fix it rather than to install it once:

- **Everything about an account lives in PostHog**: Customer Analytics, the onboarding team's `onboarding_accounts_v8` model, the email sync and the `Onboarding::` workflows. Those change as the team builds them, so when a read comes back empty, check the live columns against the v8 table in `references/data-rules.md` before believing it.
- **Warehouse tables and columns change liberally.** The skill probes rather than assumes wherever it can, and names what it could not measure, but a query that returns nothing is as likely to be stale here as absent there.
- **Product state is never recorded in this skill**, by design: prices, tiers, free allowances, SDK support and where a setting lives are searched live on every run. If you find one written down, that is a bug and deleting it is the fix.

When a run reveals a fix, `SKILL.md` closes with how to fold it back in.

### Vitally was retired on 16 October 2026

Version 2.0.0 reads nothing from Vitally. If you set up its MCP for an earlier version, remove it with `claude mcp remove vitally -s user`, drop the `VITALLY_*` lines from `~/.bash_env` and `~/.zshenv`, and take `mcp__vitally__*` out of your permissions.

**Bump `version` in `.claude-plugin/plugin.json` in every PR that changes a file here.** `claude plugin update` compares
that string and nothing else, so an unbumped release is undeliverable: an installed copy reports "already at the latest
version" and stays on the old commit forever. Verified on 2026-08-18 by installing 1.0.0, refreshing the marketplace to
a newer `main`, and watching the update refuse. `scripts/version-check.sh` reads the same field to tell users they are
behind, so it goes quiet too if the bump is skipped.

Personal values live in `~/.claude/posthog-customer-deep-dive.local.md` (or an older install's `config.local.md`), which
the skill overlays on top of `config.md` when it is present. Keep `config.md` shareable: the defaults, and the tool knowledge in its "Yours" column. Never move a personal
path or address into it, and never blank the "Yours" cells to publish, since each one records a mistake somebody
already made.

