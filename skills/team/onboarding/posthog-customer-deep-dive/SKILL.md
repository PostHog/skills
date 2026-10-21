---
name: posthog-customer-deep-dive
description: Use before emailing a PostHog customer, replying to one, or joining a call, and for any request to research a PostHog account. Fires on "/posthog-customer-deep-dive" and on natural language like "deep dive on X", "look up this customer", "help me reply to Y", "prep me for my call with Z", from an email address, domain, account name, PostHog org id, or Customer Analytics account id. Researches the account across Customer Analytics, the onboarding model and its Onboarding:: workflows, the email sync, and project 2 usage and billing queries, then drafts an email (first touch, follow-up, or reply) or a call-prep brief, every recommendation carrying a live docs link.
---

# PostHog customer deep dive

Research an account, then produce an **email** (first touch, follow-up, or reply), a **call-prep brief** with its notebook prompt, or for any other ask whatever shape the ask needs on the same research. Output goes to chat. Customer and account systems are read-only: never send, never post, never write to PostHog (no account property, note, task, tag or workflow) or to Salesforce. The only writes are local: your personal config file during Setup, and a per-run scratchpad (`deep-dive-<account>-<HHMM>` under the session scratchpad, or `/tmp`) holding the docs cache, the context file and the gatherer digests. **The deliverable is generated once, into chat, and never also written to a file.**

**Input**: `$ARGUMENTS`, usually an email address; also a domain, an account name, or an id (a PostHog org id or a Customer Analytics account id).

**Verify every claim before writing it.** Every number comes from a query you ran this run; every product fact and link from a docs search you ran this run. Show a derived figure's arithmetic inline (`1.72M polls/day / 2,880 per instance = ~600 instances`) so a slipped digit is visible. Nothing from memory, nothing inferred from a number you did not pull. Where a claim cannot be verified, write the question instead: an unanswered question costs a follow-up, a confident wrong fact costs the relationship. Every table in this skill tells you what to check; none is a citation.

**A claim about the customer's code or SDK config must quote that code** from the site scan's fetched page or bundle. Data shows the effect; only code shows the cause, so an identity or billing mechanism is never named from event and billing data alone. Events the SDK emits (`$identify`, `$create_alias`, an explicit `$set` event) are assertable from those events; init options and config values need the quoted code.

Read `config.md` first: the shipped defaults and tool bindings. Then read your personal config if it exists and let any key it names win: `~/.claude/posthog-customer-deep-dive.local.md`, else `config.local.md` in this folder on an older install. It lives outside the skill folder because a plugin update replaces that folder; it is missing on a first run and that is normal. A required value still reading `<SET THIS>` after the overlay means ask before the step that needs it, or run Setup. A source set to `none` is skipped silently; that is configuration, not a skip, and a run with every optional source at `none` is complete.

| Reference | Read when |
|---|---|
| `config.md`, then the personal config if present | Before Step 1, every run |
| `references/agent-briefs.md` | **First, before Round 1a.** It carries main's own reading-map row, so it decides what else main opens, plus the conventions block, the per-role map, the context file spec and the return rules |
| `references/data-rules.md` | Steps 1 and 2, by main, **only the sections main's map row names**. **Gatherers never open it**; they get its conventions inline |
| `references/queries-account.md` | Steps 1 and 2, by main (Round 1 slugs) and by the gatherers assigned to it |
| `references/queries-products.md`, `references/queries-money.md` | Step 2, by the gatherer whose map row names the section. Each file's headings are its index |
| `references/site-scan.md` | Round 1a, batch 1 for the domain and batch 2 for each product host and sub-app (Round 2 on a public-provider admin email) |
| `references/levers.md` | Before drafting any recommendation, and by `docs-prewarm` to pick pages |
| `references/voice.md` | Before drafting anything a customer will see |
| `references/mode-email.md`, `references/mode-call-prep.md` | Step 5, the one file for the detected artifact. Any other ask runs the same research and takes the shape the ask needs |

Batch main's reference reads into one block. Opening `data-rules.md` whole is the largest read in the critical path and most of it belongs to gatherers, who get it inline.

Three bundled scripts. Two of them are a floor and never a ceiling: run them, then keep going wherever the account points somewhere they do not reach, and name what you ran beyond them. A run that stops exactly where the scripts stop answered the script's questions instead of the customer's.

- `scripts/phq.py` sends any HogQL query over the HTTP API on four targets (`us` project 2, `eu` EU project 1, `ch-us` / `ch-eu` the direct ClickHouse connection). `--batch <file.jsonl>` fires many at once, one JSON object per line with the keys **`name`, `target`, `sql`** and optional `connection`; any other key set is a `KeyError` before the first query runs. The MCP stays primary for project 2. `phq.py` is the only path to EU project 1 and to the direct connection (Round 1a's `customer-hosts` runs there, so the US key is required), and the fallback for project 2 when the gateway is down.
- `scripts/site-scan.sh <domain>` runs the common shape of the site scan; `--url <page>...` scans product hosts and path-mounted sub-apps alone.
- `scripts/version-check.sh` takes no arguments and is the third: run it once alongside the `config.md` read, and relay its output verbatim if it prints anything. It compares this copy's `.claude-plugin/plugin.json` version against the published one, checks at most once a day, and stays silent when current, offline, or ahead of `main`. Silence is the normal result and needs no mention.

**Every other HTTP call**, such as a PostHog REST endpoint `phq.py` does not cover: build the JSON in Python inside a single-quoted heredoc (`python3 << 'PYEOF'`), write it to a file, send with `curl --data @file`. Bash expands `$1`, `$group_0` inside inline strings and this skill is full of `$`-prefixed names; Python's `urllib` hits `CERTIFICATE_VERIFY_FAILED`, so curl sends and Python only builds and parses.

## Setup (first run, or when the config is not yours)

Probe before asking, confirm before writing. In one pass: check the tool list for the PostHog exec gateway; check the env for `POSTHOG_PERSONAL_API_KEY` and `POSTHOG_PERSONAL_API_KEY_EU`; check the tool list for each optional category in `config.md`, recording exact tool names; detect the timezone. Show one message with what was found, what is missing and the defaults you keep, ask only what cannot be probed (calendar id, booking link), then write everything Setup learned (tool names, work calendar ID, timezone, meeting notes folder) to `~/.claude/posthog-customer-deep-dive.local.md`, creating it if it does not exist. Never write to `config.md`: it is the shared file, it ships as-is, and a plugin update replaces it. A missing optional tool is `none`; a missing required tool stops the run.

**When something is missing, hand the person the fix, not a diagnosis.** `README.md` carries the whole install, one numbered section per tool, each ending in a check that proves it worked, and it is never loaded at runtime, so read the section for whatever is missing and give them the commands from it inline: the shell and key setup (section 0), the MCP registration, the `op item get` command for a shared credential, or the mint URL for a personal one. Say which credentials are shared and which are theirs, since reusing someone else's PostHog personal key is the common mistake. Then re-probe and confirm before running. A first run that ends in "the PostHog MCP is missing" and nothing else is how a shared skill loses the person who was trying it.

## Step 1. Resolve to a Customer Analytics account

Resolution runs on Customer Analytics. Every path ends holding two ids: the PostHog org id (`external_id`) and the Customer Analytics account id (`id`).

| Input | Path |
|---|---|
| Email | MCP `accounts-list` with `search` set to the email, `include_ignored: true` and `include_churned: true`. It matches any email the account knows, not only the admin's domain. **Both include flags every time**: ignored and churned accounts are hidden by default and most accounts are ignored, so the default call returns nothing for most orgs and reads as a wrong email |
| Domain | the `sibling-sweep` queries. `accounts-list` domain search only matches accounts carrying `email_domains`, which most do not, so an empty result there proves nothing |
| Account name | `postgres.prod.billing_customer WHERE name ILIKE '%...%'`, then `accounts-list` with the name as `search` and both include flags. Self-serve signups share company names: prefer the row with a non-null `plans_map` and a Customer Analytics account, then let the volume probe below decide |
| Account ID | an org id: `system.accounts WHERE external_id = '<ORG_ID>'`. A Customer Analytics account id: `system.accounts WHERE id = '<CA_ACCOUNT_ID>'`. Neither matching means ask for an email or the org id |

**An org can have no Customer Analytics account at all**, most often a recently created one, so a miss on every path above is not a wrong input. Resolve the org id from `sibling-sweep` or `billing_customer.admin_emails`, carry on with it, and write `no Customer Analytics account` in the header. If nothing resolves the org either, ask for the account name.

**One customer carries a different name in each system, so check what the name you were handed refers to.** The Customer Analytics account name, `billing_customer.name`, the Stripe customer name (often a legal entity), `salesforce.account.name` and `website`, and the per-project names in `resolve-teams` are independent fields that sometimes disagree, and the name you were given can turn out to be a near-empty second project rather than the account. State in the header which name maps to what whenever they diverge, and report on the project carrying the volume.

**The account's state is one read, `onboarding-state` in `queries-account.md`**, which returns one row for any org, with or without a Customer Analytics account: the stage, eligibility, what onboarding sent and heard back, calls, sales disqualification, money, credit and health. Everything it reads lives in PostHog; the column rules and traps are in `data-rules.md` ("Customer Analytics and the onboarding model"). Owners come from `account-roster` (Step 4), and what paying for each product means comes from `plans_map` on `account-state`.

**Always run the domain sibling sweep, both halves, once per admin email domain** when the admins sit on more than one. A sibling org is a duplicate paying twice, a consolidation question, or an account a teammate owns. The two queries see different populations (the per-person usage report and `billing_customer.admin_emails`) and neither alone is complete; skipping one is how a duplicate-billing sibling stays hidden. Flag any sibling in the header: one org with multiple projects usually beats parallel orgs.

**Then probe usage across every org the sweep returned and build the context on the one carrying the volume.** An email routinely matches several accounts, and `accounts-list` orders them newest first, not by volume, so on a multi-org customer the first row is routinely not the live one and every downstream figure would describe a dead org. **This gates the Round 2 launch: no gatherer starts until it has resolved**, because a gatherer given the wrong org id does perfect work on the wrong company.

```sql
SELECT organization_id, count() AS days, sum(event_count_in_period) AS events,
       sum(recording_count_in_period) AS recordings, sum(mobile_recording_count_in_period) AS mobile_recordings,
       sum(billable_feature_flag_requests_count_in_period) AS flag_requests
FROM billing_usage_by_org_date
WHERE organization_id IN (<every org id the sweep returned>) AND date >= today() - 30
GROUP BY organization_id ORDER BY events DESC LIMIT 20
```

An org missing from the result has no Cloud usage in the window, which is an answer. Where the resolved org and the live org differ, say so in the header, report on the live one, and treat the resolved one as a sibling finding: a paid subscription on a dead org is money leaving for nothing.

## Step 2. Parallel pull

Put the PostHog MCP on **project 2** (check its active-environment block; `switch-project` to `2` if not). It often defaults to a dev project where every query returns zero rows.

Read the region from `resolve-teams` (`app_region`); an org with teams in both regions runs each team's reads in its own region. Project 2 answers almost everything for both regions; the exceptions are EU experiment definitions and the EU direct connection, both on the EU key and EU project 1.

### How to fan out

**Fan the gathering out, reconcile in one head, then fan the verification out separately.** The two fan-outs are not interchangeable: gathering happens before there are claims, verification after.

A round costs what its deepest agent costs, and an agent costs its longest chain of dependent calls. So **batch first** (every read depending only on the context goes out in one block; on the HTTP path one `phq.py --batch`), **widen second** (one grouped query per org and region rather than one per team, per `data-rules.md`), **split last** and only along a true dependency. No brief carries a serial chain longer than 8 to 10 reads: count the chain, not the calls.

- **Budget in tool calls, never seconds. Cap each gatherer at 12 to 15**, and split the brief BEFORE launching if the list runs past 15. Nobody can estimate an agent's seconds; everyone can count reads in a brief.
- **The budget caps shape, never scope.** Never drop, defer or narrow a read to fit it. The move when a brief is too big is to split it, and a read that still will not fit runs over budget and is named in the closing note.
- **Split by call count; never merge briefs by topic.** Concurrent agents are near-free in wall clock; calls inside one agent serialize into one chain. Merging trades a cheap resource for an expensive one, so the instinct to reduce agent count is backwards.
- **8 to 10 concurrent agents, each batching 4 wide.** Past that ClickHouse returns 202 and the HTTP path returns 429, and the forced serial retries are slower than not splitting. The cap is machine-wide and shared with other sessions, so expect refusals: never retry a refused launch at once, launch it as soon as a running agent returns, and if no slot frees in time, run that role yourself in main and name it in the closing note. Never ship without the refused brief. **The binding limit is concurrent QUERIES, not agents**: 8 agents batching 4 wide is already ~32 in flight, which is why the agent count looks low. A wave of short, query-light roles can run wider than a wave of heavy ones.
- **Splitting stops paying below about 12 calls**, because every agent carries a fixed startup cost whatever you give it. Split down to 12 to 15, then stop.
- **One wave is the default. A wave boundary is for a DEPENDENCY, never for headcount, and a wave costs its slowest member.** Staging by topic importance is the live failure mode: it strands a long role in wave two where it idles and then becomes the critical path alone. When the set exceeds the cap, **stage by expected duration and put the long poles in wave one.**
- **Rough order, longest first**, measured once on a two-project EU account so beat it with what you observe: `usage-trend`, `change-point`, `definitions-and-hygiene`, `internal-context`, `clay` · `event-mix`, `site-scan`, `replay-and-errors`, `flags-and-experiments`, `money-quotas` · `data-platform`, `identity-and-sdks`, `app-engagement`, `money-invoices`, `docs-prewarm`. Two are placed on judgment rather than that clock: `clay` and `internal-context` both finished early only because their tools were absent, and a run where Clay polls for credits or Gong pages a transcript is far slower. `money-quotas` is promoted above its length, because what a limit actually cut off reframes every other finding. `docs-prewarm` goes last and never takes a required gatherer's slot.

| Round | Who | Does what |
|---|---|---|
| 1a. Unblock | Main, four ordered batches | Everything deciding **who** to research and **which batch** to run, because both are wrong to guess. **Batch 1**: the Customer Analytics resolve, BOTH halves of `sibling-sweep`, **and the `site-scan` subagent on the admin email domain, in this same block** (on an email input; otherwise launch it the moment resolution returns an admin email). **Batch 2a**, now that the org ids are known: `resolve-teams` grouped over every org the sweep returned, the multi-org volume probe, which names the live org, and `org-snapshot` on that org, whose `teams_map`, `realm` and `web_events_count_in_period` go into the context file for every role that needs them. **Batch 2b**: `customer-hosts` on the direct connection, then **one `site-scan --url` per product host or path-mounted sub-app it found off the scanned domain, each handed every `api_token` from `resolve-teams` it might carry**. **A scan token `resolve-teams` did not return belongs to another org: look it up in `all_posthog_team` by `api_token` and add that org to the siblings.** **Batch 3, and only now that the live org is known**: the scope probe, `onboarding-state`, `account-roster`, `account-spine` (its `slack_channel`), the account notes (`accounts-notebooks-list`), `onboarding-automation`, `conversation-history`, `salesforce-firmographics` and the calendar read, which between them decide the mode, **the history reads each run over every org the sweep returned**, because the email sync and Customer Analytics link a thread, note or meeting to whichever sibling an address matched, so a live org's history often sits on a sibling. Then write the context file (`agent-briefs.md`), detect the mode, and launch Round 2. **The batches are ordered, not one block.** Running the scope probe beside the sweep profiles whichever org the resolve happened to return first, and on the multi-org account this gate exists for that is the dead one, so its numbers land in the context file every gatherer then trusts |
| 1b. Resolve | Main, one block, concurrent with Round 2 | `account-state`, `org-status`, `support-tickets`, `touchpoint-timeline`, `survey-feedback`, v8's freshness (`view-list`), **`billing-limit-updates`**, `org-universe`, `signup-intent`. Naming these is what stops them being silently skipped. `billing-limit-updates` is one query, it names the actor behind every limit, and a limit moved before a call reframes the money picture |
| 2. Gather | The roles below, in ONE wave where the cap allows, else staged longest-first | Every role the mode requires, `docs-prewarm` last |
| 2. (concurrently) | Main | Reading the conversation history and the bodies that matter, Step 4 roster, refining mode detection as `internal-context` returns |
| 3. Reconcile | Main, in ONE parallel block | Assemble `change-timeline` from the returned digests, then the roll call, the hedge sweep, the named pairs, then re-run the header figures and the number driving the top recommendation. List every claim the output will make. Surface any disagreement between two sources with both figures, never resolve it |
| 4. Verify | Main where the cache covers the claim, one subagent per uncovered cluster, **capped at ~5 claims each** | A live docs search per claim, returning the URL and the verbatim line that proves it |
| 5. Write | Main | The output |

**There is no separate pre-resolve round, and there is one site scan per surface rather than one per account.** The domain scan needs only the admin email domain, so on an email input it goes in batch 1 beside the resolve rather than in front of it. An org runs a token per team and serves them from a handful of hosts and sub-apps, so one scan reads one surface's `init()` and leaves the rest unknown: batch 2b scans each further surface `customer-hosts` finds, each handed every token from `resolve-teams` it might carry. Nineteen teams behind five hosts is five scans, and a team with no public surface needs none. Rescan on top of that only when Step 1 returns a different domain, compared after redirects: a domain that redirects to one already scanned is the same surface.

This is a correctness rule, not a speed one. **A gatherer cannot be asked to recommend a config change on a project whose config is unread**, and the unscanned project is repeatedly the one holding the findings: on a two-project account the scanned project had already been optimized and the unscanned one held every remaining lever.

Give every subagent **the path to the context file**, the conventions block, its reading-map row, and the return rules, all from `agent-briefs.md`. **The context is resolved once by main and no gatherer re-resolves any of it**; a gatherer missing a value reports the gap rather than querying for it. The `site-scan` agents are the exception, because they run before the context file exists: the batch-1 scan gets only the domain, and each batch-2b scan gets its URL plus every `api_token` from `resolve-teams` it might carry.

**Probe an optional source once.** Gong, Slack and Clay share a shape: emptiness is knowable in one call, and a zero ends that source. Report "searched X, zero results", which is a finding and not a skip.

**The role roster, what each owns and which sections each opens, is one table in `agent-briefs.md`.** It lives there because that is the file main reads to write the briefs, and two tables listing the same roles in two always-loaded files is how they drift apart.

`agent-briefs.md` holds the exact sections each role opens, and that map is what the brief carries. **Ask each gatherer 3 to 4 questions, not six**: six numbered questions invite six investigations and turn a 12-call role into a 30-call one.

Probe an unfamiliar property in the block you are already firing, never in its own round: add `JSONExtractKeys(assumeNotNull(properties))` for that event.

### The scope probe, and its three guards

The Round 1a scope probe (one `per-product-usage` aggregate) knows which products carry volume. Pass it into each product brief as known state, each line carrying its own proof (`billable_feature_flag_requests_count_in_period = 0 in billing_usage_by_org_date over the window`, never a bare "flags are zero"). **It changes what a brief says, never whether it runs.** Three guards, and it is unsafe without all three:

1. Write `unmeasurable, no source` for every product the probe has no column for. The daily table carries PostHog AI and Replay Vision credits but not PostHog Desktop (`posthog_code_credits_used_in_period`), signals or sandbox compute credits, which ride on the org usage report, and their dollars on the `in-flight-period` forecast row (`posthog_code_mrr`, `replay_vision_mrr`, `inbox_mrr`). On an agent-heavy account they can be nearly the whole bill, so read them before calling a product quiet. Experiment volume and web analytics volume have no source anywhere; heatmap volume lives only on the usage report's `teams` map; `ff_count` lives on the org usage report.
2. Check `realm` on `org-snapshot` before trusting a flat zero: the table is Cloud only, so a self-hosted org reads zero everywhere while emitting usage daily, and it carries no row for a day with no usage.
3. Each brief says "verify against the product's own source and report what you found", never "confirm and move on".

**Never use the probe to skip a role the mode requires.** Skipping is where a zero and an unmeasurable become the same thing, which is the failure this skill exists to prevent. An agent that ran and confirmed a zero is not a skip.

### Round 3: roll call, hedge sweep, named pairs

Three checks before any re-run, because each catches a whole missing input rather than a wrong digit.

**The roll call.** List the roles the mode requires against the roles launched, and the Round 1 slugs required against the ones that returned. Every gatherer justifies its own skipped reads, but nothing checks the level above it, so a role dropped under time pressure disappears silently while the output reads complete. Launch the gap, or name it in the closing note. "Short of time" is a reason to state, never a reason to omit. This matters most on an ask that is neither an email nor a brief, where there is no expected section for the reader to notice missing.

**The hedge sweep, and it produces a list, not an intention.** Read every digest for the gatherers' own uncertainty ("probable not proven", "unmeasurable", "needs confirming", "worth reconciling", "the biggest skip is", "ask on the call") and **write every hit into a numbered list before closing any of them**. Each line gets a disposition: closed with the number, or carried into the output as a named open question. A hedging gatherer has almost always named the read that would close it, so each is cheap and pre-scoped.

Doing this in your head is what fails. A sweep held as an intention closes the easy hedges, and the one it drops is reliably the one sitting under the top recommendation, because that is the hedge whose answer takes work. **An unresolved hedge is how a finding dies**: the agent did its job, the signal sits in the digest, and it never becomes a sentence. Two specific shapes to catch, both of which have shipped as assertions: a hedge that would have SIZED a lever you are already recommending (you keep the recommendation and lose the number that makes it land), and a hedge naming a cause that another gatherer was holding the data to confirm.

**The named pairs**, sources that must agree:

- **A site-scan absence against the customer's own event stream.** The scan is authoritative for what it found, never for what it did not. If their team receives events carrying that host in `$current_url`, the tool is installed there whatever the scan said. One query, before any absence claim reaches the output.
- **The header's money figures against the invoice.**
- **Two gatherers against each other, wherever they touched the same object.** Reachability claims are the ones that collide: one role probes a table, gets `Unknown table` and reports unmeasurable, while another reads a near-identical name successfully and publishes a finding from it. Both digests are then true and the output carries a contradiction. Before writing, list every object more than one role touched and confirm they agree on whether it exists and what it holds.

### Round 4 verification, and the docs cache

Verification runs against the finished claim list; Round 2 pre-warming is additive and may never shrink it. **Where the cache covers a claim, verify in main; fan out only for the claims it missed.** The invariant holds either way: every claim gets its own live search, and the count of searches against claims is what proves it happened.

**Cap a verifier at about 5 claims and add agents rather than claims.** The cap is about blast radius, not depth: verification is the last step of the run, so a twelve-claim verifier is a single point of failure at the moment there is no time left to redo it, and one has stalled mid-stream having written nothing. When a verifier does die, resume it from its transcript rather than restarting it, and tell it to **write its file first and reply second** and to mark every claim it never reached as NOT REACHED. An omitted claim reads as a verified one, which is the failure this whole round exists to prevent. Searching from `plans_map` before the findings exist verifies levers you predicted and misses the ones the data produced, so build the claim list first (the pre-draft check in `voice.md`), then verify every lever and product fact it states.

Three lines govern the cache, and every Round 4 brief states them verbatim: a cached page is evidence only for a claim whose OWN live search returned that URL; the cache supplies a page body, never a verdict and never a citation; the cache is per run, never a page a previous run fetched. A verifier returns the verdict, the canonical URL and the verbatim sentence. `not found` is permitted, and a claim that comes back that way is cut or rewritten as a question, never shipped with the nearest-looking link. Cite `posthog.com/docs` first, a PostHog-authored `posthog.com/tutorials` page when no docs page covers it, never Community Questions or GitHub issues. If `docs-search` is unreachable, verify each URL with a plain HTTPS fetch.

### The closing note

Nothing accumulates across runs, so this note is the only record. At Step 5, after the output, add a short note in chat: which agents ran long, any brief that overran its cap, and any fix this run revealed that belongs in the skill. Suggestion only. Three figures belong in it because all three are correctness checks, not telemetry:

- **Claims whose own citation URL you fetched, against total claims.** Count it from a list you append to as each verification happens, never from memory at the end of the run: a number reconstructed at the end is a number you will inflate, and an inflated count is worse than none, because the ratio is the only thing standing between a real Round 4 and a warm cache. Count fetched citations rather than searches run, because a search that returned a confident, adjacent page is exactly the failure this is watching for and it looks identical to a search that answered the question.
- **Roles launched against roles required, and Round 1 slugs returned against Round 1 slugs required.** Print both halves. A dropped role is the loud half and gets noticed anyway; a Round 1 slug that quietly never ran is the silent half, and it is the one that reaches the output as an absence nobody questioned.
- **Hedges found, closed, and carried**, as three numbers from the Round 3 list.

### What main covers beyond the roles

Round 2 subagents own the reads in the table; main does not re-run them. Beyond it, main owns the account's history with PostHog: `onboarding-automation`, `conversation-history` with its two frozen archives, `touchpoint-timeline`, the notes, `support-tickets` and `survey-feedback`. **Every onboarding mailbox and every Workflows send reaches the email sync, so it is the whole comms record, and a mailbox search adds only the full body of a thread the sync already shows.** Read that body in your own Gmail by the thread's subject, and only after checking the recipient domain is the account's: a search on a contact's first name once matched a different customer's personal address at another domain and nearly put that account's failed payment into this brief. Where a v8 column and its account property disagree, keep both and show both. The calendar runs every run with an explicit start/end window (unbounded text searches return nothing), by attendee name from the `Accepted:` subject, else by account name and admin emails.

**Four names main needs by hand, because main verifies numbers without opening a query file.** The event saying a limit actually cut a product off is **`org_quota_limited_until`**; who changed a limit is **`billing limits updated`**; the forecast is **`forecasted_mrr` on `onboarding-state`**, and its per-product split is **the `upcoming` row of `iwa_summary_customer_month`**; current limits are **`custom_limits_map`**. A guessed column here returns an empty result that reads exactly like "nothing was limited", the inverse of the truth. **These are pointers, not recipes: open `quota-limits` and `in-flight-period` in `queries-money.md` before writing either query**, because both carry filters and aliases that decide whether the result means anything, and writing SQL from this paragraph alone has produced a column of nulls and a hard 400.

Call prep runs every role. An email run, and an account brief, drop the roles whose product the account does not implicate, and name each one dropped. An account brief takes the call-prep brief's shape without the notebook prompt, and ends on the loop-in draft when someone else holds the account. In every mode, skip an individual read only when it cannot apply, and name each skip. Lookback 30 days; re-run a single query at 14 days (follow-up) or 7 (same-week call prep) only where the shorter window changes the conclusion.

## Step 3. Mode detection

**This step flags, it never blocks; any mode or request runs on any account.** The skill only drafts, so a human weighs every output; raise contradictions loudly, never withhold work.

Flag at the top when the account looks already handled or held: `org_active` false on `org-status` (the org is switched off, which nothing else here knows), `onboarding_eligibility` reading `Done` or `Not eligible` (name its `eligibility_blocker`), a terminal stage (`3. Onboarding Completed`, `Sales Handoff`), `opted_out` reading `'true'` (Yes in the UI), `other_outreach_30d` at 1, a current CSM, AE or TAM, a referral tag with no later `sfdc_last_dq_at`, or a teammate's recent message on the same topic. An Onboarding specialist assignment is never a flag.

The user's explicit ask always wins: "draft outreach for X" produces the draft whatever the account state, flag leading, never a refusal. **The one exception is an opt-out**: an account reading `opted_out` = `'true'` gets no onboarding email in any mode, explicit ask included, and the output is an account brief saying the customer asked us to stop. A reply to a billing or support question the customer asked stays allowed. The signals below decide only when the ask is open. A pasted inbound is a reply; a named call is call prep.

| | Signal | Read from | Watch for |
|---|---|---|---|
| stage | Pipeline stage | `pipeline_property` on `onboarding-state`, with v8's `onboarding_stage` beside it | Five live values, copied exactly: `1. New Account`, `2. Onboarding Initiated` and `3. Onboarding Completed` carry a numeric prefix, `Sales Handoff` and `Purchased Onboarding Call` carry none, so a bare `New Account` matches nothing. `Not Eligible` exists on the definition and is rarely written: read it as `Not eligible` eligibility. Any other value is flagged and never routed on. **Empty** means never entered the pipeline. An assigned Onboarding specialist says nothing here |
| sent | What onboarding already sent | `$workflows_email_sent` in `onboarding-automation` (`send_email_1` to `send_email_4`), `sender_kind = 'onboarding'` rows in `conversation-history`, and `onboarding_history_archive` rows whose `last_outbound_by_email` is on the onboarding team (contact before 12 October 2026, and threads the live sync never picked up) | The four sequence emails are onboarding touches. Never read first contact off `onboarding_first_outbound_at`, which misses rotated sequence sends. Payment Failed (`send_email`) and `billing_thread` rows never count |
| next | What the sequence sends next, and when | the running `Onboarding:: Email sequence` invocation's last pause line (`onboarding-automation`) | Emails 2 to 4 skip an account the team emailed in the last 7 days, read from v8, so a hand-written email v8 has already seen makes the sequence skip its next send, and only one newer than v8's last run can double it. Say when the next automated email is due and draft around it. No running invocation on a stage 2 account means no automated email will come (it entered the stage before the sequence went live, or a backfill skipped it): say so, because every touch from here is a person's. An Eligible account with an empty stage has no invocation yet: `Onboarding:: Enter queue` stages it daily, and email 1 then decides on its own conditions |
| meeting | Booked FUTURE onboarding call | `onboarding_call_booked` and `next_onboarding_meeting_at` on `onboarding-state` | A hint only. Confirm the date on the calendar and fall through if the meeting is past, declined or not found. A call a teammate holds is on their calendar, not yours: read the Customer Analytics meetings in `touchpoint-timeline` for it |
| inbound | A customer message awaiting us | the newest `sender_kind = 'customer'` row in `conversation-history`, against the newest onboarding row | A calendar or system message, an out-of-office, or a message addressed to another owner does not satisfy it. Read the actual body before routing |
| collision | Someone else at PostHog writing, or about to | `posthog_other` rows in `conversation-history`, `other_outreach_30d`, the account's notes, and the shared Slack channel (`slack_channel` on `account-spine`, read when Slack is configured) | An AE or CSM mid-thread is a flag, and the draft must not repeat them. So is an owner's note planning outreach that has not gone yet: hand them the findings rather than racing them |

Read the stage only from `Onboarding Pipeline`. Segments are retired, and the sales-referral record is a tag (Step 4).

Routing, for an open ask only:

0. **Org switched off, terminal stage (`3. Onboarding Completed`, `Sales Handoff`), opted out, or a live thread on the same topic held by a teammate (anyone at PostHog but the sender, onboarding teammates included) OR by the sender**: the flag leads, the research is still full, and the recommendation is a note or a loop-in rather than cold outreach. **This sets the framing and never the mode, so carry on down the list**; a run that stops here has a flag and no output. An opted-out account never reaches 3 or 4: it gets the account brief in 5, or a reply in 1 to a billing or support question the customer asked. The sender's own recent thread is a collision exactly like a teammate's: not a reason to withhold a draft, but the thing the draft must not repeat.
1. **inbound true** and the latest inbound is a real customer question: **email, reply state**
2. else **meeting present**: **call prep**. A `Purchased Onboarding Call` account with nothing booked gets a scheduling email (first-touch state, built around booking the call they paid for) unless an AE or CSM owns it, since onboarding runs that call
3. else stage `1. New Account` or empty, `onboarding_eligibility` at `Eligible`, nothing in `sent`, no current CSM, AE or TAM, no referral tag without a later `sfdc_last_dq_at`, `other_outreach_30d` at 0, no `posthog_other` row in 30 days, and no PostHog salesperson active in the shared Slack channel in 30 days: **email, first-touch state**. Check `next` first: `Onboarding:: Email sequence` sends email 1 itself to Eligible accounts under its forecast ceiling (read the ceiling off its `chk_first` branch with `workflows-get` when it matters), so a hand-written first touch there doubles it: say so, and draft it only on an explicit ask
4. else a prior onboarding touch (by hand or by the sequence, at any stage short of terminal) and none of the owner, referral or other-outreach blockers in 3: **email, follow-up state**. A touch with the stage still `1. New Account` is the stage-mismatch flag below, and the sequence will never email it, so every follow-up is a person's
5. else an **account brief** with no draft, saying why there is nothing to send: name the blocker (`eligibility_blocker`, the owner, the referral, the other outreach, no touch on record) and, where someone else holds the account, the loop-in. Draft only on an explicit ask, flag leading

Read the conversation history before finalizing; thread context outranks any single signal. Flag and keep going on: a sequence email sent but the stage still `1. New Account`; a graduation email sent with the stage still `2. Onboarding Initiated`; `2. Onboarding Initiated` with nothing in `sent` and no onboarding row in `conversation-history`; `sfdc_last_dq_at` set on a stage 1 or 2 account, which means sales disqualified it and it came back.

## Step 4. People on the account

Report the roster in the header every run, assigned or not: `Onboarding <name or NONE> · CSM <name or NONE> · AE <name or NONE>`. Middle dots, never pipes, which break the table cell.

**An Onboarding specialist assignment is roster data, never a warning.** The specialist is cleared when an account reaches `3. Onboarding Completed` or `Sales Handoff`, so `NONE` there is correct and the ended row is who worked it. **A current CSM, AE or TAM is different**: every onboarding send skips those accounts, so Step 3 routes them to an account brief with the loop-in, and the header names who holds it. A teammate who recently messaged the account on the topic at hand IS a collision: read `conversation-history` for that, not the ownership fields.

`account-roster` (Customer Analytics relationships, current where `ended_at` is null) is the roster and nothing else is. When it reads `NONE` but Slack, Gong or Salesforce shows a PostHog person who ran the deal (an AE who closed it lost, a TAE), add `deal owner: <name> (closed lost <date>)` beside the roster, never as a current role. Any other current role it returns (Account owner, TAM, Forward deployed engineer) joins the same header row, and its ended rows are who held the account before. An org with no Customer Analytics account reads `NONE` on every role, with the header saying there is no account. A set `sfdc_last_dq_at` with no AE or CSM means sales passed and onboarding has the account again: note the date and `sfdc_last_dq_reason`.

**To answer "was this account ever referred to sales", read the account's tags, not the stage.** Any tag containing `referral` (`ae referral`, `am referral`, or the old `onboarding referral`) is a referral. `Onboarding:: Stage reactor` moves a stage 1 or 2 account to `Sales Handoff` when such a tag is added, so a tag that predates the workflow or came with an import leaves it at stage 1 or 2: flag that pair rather than assume the move happened. The tag stays after the stage moves on, so a referred account routinely shows another stage. Read it with `sfdc_last_dq_at`: referred and disqualified since means it came back and is yours; referred and not disqualified means sales still has it.

On a contract or credit account read `credit-contract-phase` in `queries-money.md`: the contract phase, whether the renewal is signed, the credit balance, the runway and the projected depletion date in one row. Credits projected to run out before the contract ends go in the header, since they change the conversation rather than the draft.

## Step 5. Output

No em dashes, en dashes or double hyphens in any output, the internal brief included.

Read `references/voice.md` before drafting anything a customer will see, `references/levers.md` before stating any recommendation, and the one mode file for the artifact.

Common header for every email and every call-prep brief, and for any other ask whose artifact is an account brief. Render it as a real markdown table, never inside a code fence (the fence below is only the template's source). Drop a row that does not apply rather than writing `n/a`.

```
# <Account> | <Artifact: first touch / follow-up / reply / call prep / account brief>

> **Flag:** <only when one applies: a teammate's live thread on this topic, a CSM, AE or TAM or a referral holding the account, a stage mismatch, a sibling org, an opt-out, a stale v8 run. Never an Onboarding specialist assignment.>

| | |
|---|---|
| **Pipeline** | <stage> · <eligibility> |
| **Onboarding** | Sent <which emails, when>. Next <what, when, or nothing scheduled>. Replied <yes, when, or no> |
| **Health** | <X>/10 (PostHog health score, <date>) |
| **Renewal** | <date> (<n> days, monthly bill or contract end) |
| **MRR** | $<last bill> last bill to $<forecast> forecast (<±delta>) |
| **Paid** | <products> |
| **Limits set** | <product $each>. Mark any at or near its forecast; say NONE where the largest line has no limit. The product analytics limit has capped the product analytics, identified events and group analytics lines together on real invoices, so compare it with the sum of the three, never with one line |
| **Limits biting** | Which products a limit has ACTUALLY cut off, from `quota-limits`, each with its start date and whether it is dropping now. NONE is an answer and is written out. A limit that is set and a limit that is destroying data are different facts |
| **People** | Onboarding <name or NONE> · CSM <name or NONE> · AE <name or NONE> |
| **Users** | <total> listed, <n> with seats, <n> with real activity |
| **Org** | <org link> · <account link> |
```

Header field rules, since several fields collide:

| Field | Rule |
|---|---|
| Renewal | `next_bill_at` is the monthly bill and never the contract renewal; on a contract account use `contract_ends_at` from `credit-contract-phase`. On a monthly account they are the same |
| MRR | The last bill is the latest closed invoice from `money-picture` (`list_total`, with `booked_mrr` beside it), and `forecasted_mrr` from `onboarding-state` is the forecast, net of any credit discount. v8's `last_bill_mrr` is a cross-check only: it has read a future-dated bill on a live account, so show both when they disagree. On a first billing period the last invoice is the $0 one from signup, so say the first bill is not issued yet and quote `in-flight-period`. Delta is forecast minus last bill; a negative delta on an annual account is usually the annual-vs-usage artifact, not churn. Never put `Forecasted usage MRR` here |
| Onboarding | From `onboarding-automation` and the sequence run: which of `send_email_1` to `send_email_4` went and when, the next wake, and the latest customer reply from `conversation-history`. Nothing sent and nothing scheduled is written out |
| Health | `health_score` from `onboarding-state`, with `health_scored_at`. It is PostHog's own model; quote it as that |
| Users total | `user_count` from `onboarding-state`; with no v8 row, the member count from `org-membership` (EU mirrors on EU); per-query counts can differ |
| Org link | `https://us.posthog.com/project/2/groups/0/<ORG_ID>` (organization is group type 0), then the account: `https://us.posthog.com/project/2/customer_analytics/accounts/by-external-id/<ORG_ID>`, left out when there is no Customer Analytics account |

Before handing the output over, confirm all eight and send anything unchecked back to the round that owns it: every claim traces to this run's queries or live searches; every skip is named per subagent with its reason; every trap hit is reported, and a run reporting none was interrogated; every source disagreement shows both figures unresolved; the header is a real table with the People row present; **no section shipped as settled while an agent owning its subject was still running**; the Round 3 roll call ran and any shortfall is named; the closing note states all three figures.

**The write gate is the one traded away under time pressure, so it is explicit: a still-running agent owns its subject until it returns.** Wait for it, or write the section and mark it provisional in the output. Marked provisional satisfies the checklist; shipped as settled does not. A confident section a pending agent then contradicts costs the user a correction on work they have already read, and may have already acted on.

## Pipeline reminder

A reminder to raise with the user. The user makes these writes; the skill never does. Most of the pipeline now moves on its own: a teammate's email from their own inbox moves a `1. New Account` account to `2. Onboarding Initiated` (`Onboarding:: Set "Onboarding Initiated" when contacted by OS`), and a referral tag moves a stage 1 or 2 account to `Sales Handoff` (`Onboarding:: Stage reactor`). So the reminder covers only what no workflow does: adding `ae referral` or `am referral` when they passed it to sales, setting `Onboarding opted out` to Yes when the customer asked us to stop, and a Customer Analytics note when the research concluded "do not reach out", saying why. A draft-only run needs no write.

## Improving the skill

When a run reveals a fix, ask whether to fold it in. Write the rule into the file that owns it, in the fewest words, and fix the rule that failed rather than adding an exception. Two rules keep these files honest. **Every line changes what the model does**; provenance, measurements and orientation go to `README.md`, which is never loaded at runtime, or get cut. **The shape of the data is durable and gets written down** (a join key, a column that does not exist, an id that collides across regions); **the state of the product is perishable and belongs nowhere** (which SDKs support a feature, what a tier costs, where a setting lives), so search for it every time and never record the answer.
