---
name: posthog-customer-deep-dive
description: Use before emailing a PostHog customer, replying to one, or joining a call, and for any request to research a PostHog account. Fires on "/posthog-customer-deep-dive" and on natural language like "deep dive on X", "look up this customer", "help me reply to Y", "prep me for my call with Z", from an email address, domain, account name, or Vitally account id. Researches the account across Vitally and project 2 usage queries, then drafts an email (first touch, follow-up, or reply) or a call-prep brief, every recommendation carrying a live docs link.
---

# PostHog customer deep dive

Research an account, then produce an **email** (first touch, follow-up, or reply), a **call-prep brief** with its notebook prompt, or for any other ask whatever shape the ask needs on the same research. Output goes to chat. Customer and account systems are read-only: never send, never post, never write to Vitally or PostHog. The only writes are local: `config.md` during Setup, and a per-run scratchpad (`deep-dive-<account>-<HHMM>` under the session scratchpad, or `/tmp`) holding the docs cache, the context file and the gatherer digests. **The deliverable is generated once, into chat, and never also written to a file.**

**Input**: `$ARGUMENTS`, usually an email address; also a domain, an account name, or a Vitally account id (either UUID kind).

**Verify every claim before writing it.** Every number comes from a query you ran this run; every product fact and link from a docs search you ran this run. Show a derived figure's arithmetic inline (`1.72M polls/day / 2,880 per instance = ~600 instances`) so a slipped digit is visible. Nothing from memory, nothing inferred from a number you did not pull. Where a claim cannot be verified, write the question instead: an unanswered question costs a follow-up, a confident wrong fact costs the relationship. Every table in this skill tells you what to check; none is a citation.

**A claim about the customer's code or SDK config must quote that code** from the site scan's fetched page or bundle. Data shows the effect; only code shows the cause, so an identity or billing mechanism is never named from event and billing data alone. Events the SDK emits (`$identify`, `$create_alias`, an explicit `$set` event) are assertable from those events; init options and config values need the quoted code.

Read `config.md` first: every per-user value and tool binding. Then read `config.local.md` if it exists and let any key it names win; it holds this machine's personal values and git ignores it, so it is missing on most installs and that is normal. A required value still reading `<SET THIS>` after the overlay means ask before the step that needs it, or run Setup. A source set to `none` is skipped silently; that is configuration, not a skip, and a run with every optional source at `none` is complete.

| Reference | Read when |
|---|---|
| `config.md`, then `config.local.md` if present | Before Step 1, every run |
| `references/agent-briefs.md` | **First, before Round 1a.** It carries main's own reading-map row, so it decides what else main opens, plus the conventions block, the per-role map, the context file spec and the return rules |
| `references/data-rules.md` | Steps 1 and 2, by main, **only the sections main's map row names**. **Gatherers never open it**; they get its conventions inline |
| `references/queries-account.md` | Steps 1 and 2, by main (Round 1 slugs) and by the gatherers assigned to it |
| `references/queries-products.md`, `references/queries-money.md` | Step 2, by the gatherer whose map row names the section. Each file's headings are its index |
| `references/site-scan.md` | Round 1a, batch 1 for the domain and batch 2 for each further team (Round 2 on a public-provider admin email) |
| `references/levers.md` | Before drafting any recommendation, and by `docs-prewarm` to pick pages |
| `references/voice.md` | Before drafting anything a customer will see |
| `references/mode-email.md`, `references/mode-call-prep.md` | Step 5, the one file for the detected artifact. Any other ask runs the same research and takes the shape the ask needs |

Batch main's reference reads into one block. Opening `data-rules.md` whole is the largest read in the critical path and most of it belongs to gatherers, who get it inline.

Three bundled scripts. Two of them are a floor and never a ceiling: run them, then keep going wherever the account points somewhere they do not reach, and name what you ran beyond them. A run that stops exactly where the scripts stop answered the script's questions instead of the customer's.

- `scripts/phq.py` sends any HogQL query over the HTTP API on four targets (`us` project 2, `eu` EU project 1, `ch-us` / `ch-eu` the direct ClickHouse connection). `--batch <file.jsonl>` fires many at once, one JSON object per line with the keys **`name`, `target`, `sql`** and optional `connection`; any other key set is a `KeyError` before the first query runs. The MCP stays primary; this is the fallback when the gateway is down and the only path for EU.
- `scripts/site-scan.sh <domain>` runs the common shape of the site scan.
- `scripts/version-check.sh` takes no arguments and is the third: run it once alongside the `config.md` read, and relay its output verbatim if it prints anything. It compares this copy's `.claude-plugin/plugin.json` version against the published one, checks at most once a day, and stays silent when current, offline, or ahead of `main`. Silence is the normal result and needs no mention.

**Every other HTTP call**, Vitally REST included: build the JSON in Python inside a single-quoted heredoc (`python3 << 'PYEOF'`), write it to a file, send with `curl --data @file`. Bash expands `$1`, `$group_0` inside inline strings and this skill is full of `$`-prefixed names; Python's `urllib` hits `CERTIFICATE_VERIFY_FAILED`, so curl sends and Python only builds and parses.

## Setup (first run, or when the config is not yours)

Probe before asking, confirm before writing. In one pass: check the tool list for the PostHog exec gateway and the Vitally MCP; check the env for `POSTHOG_PERSONAL_API_KEY`, `POSTHOG_PERSONAL_API_KEY_EU`, `VITALLY_API_KEY`; check the tool list for each optional category in `config.md`, recording exact tool names; detect the timezone. Show one message with what was found, what is missing and the defaults you keep, ask only what cannot be probed (calendar id, booking link), then write: personal values (work calendar ID, timezone, meeting notes folder) go to `config.local.md`, creating it if it does not exist, and everything else to `config.md`. Never write a personal path or address into `config.md`; it is the shared file and it ships as-is. A missing optional tool is `none`; a missing required tool stops the run.

**When something is missing, hand the person the fix, not a diagnosis.** `README.md` carries the whole install, one numbered section per tool, each ending in a check that proves it worked, and it is never loaded at runtime, so read the section for whatever is missing and give them the commands from it inline: the shell and key setup (section 0), the MCP registration, the `op item get` command for a shared credential, or the mint URL for a personal one. Say which credentials are shared and which are theirs, since reusing someone else's PostHog personal key is the common mistake. Then re-probe and confirm before running. A first run that ends in "the Vitally MCP is missing" and nothing else is how a shared skill loses the person who was trying it.

## Step 1. Resolve to a Vitally account

| Input | Path |
|---|---|
| Email | `mcp__vitally__get_user_details`. Take `accounts[0].id` and `accounts[0].externalId` (the PostHog org id) |
| Domain | the `sibling-sweep` queries. The MCP `search_users` ignores `limit` and returns hundreds of KB; avoid it |
| Account name | `billing_customer WHERE name ILIKE '%...%'`. Self-serve signups share company names: prefer the row with non-null `crm_segments` / `plans_map`. The Vitally name tools are unreliable (`search_accounts_advanced` returns 0 for exact names, `search_accounts` ignores `showAllAccounts`, `find_account_by_name` is filtered to the caller's CSM) |
| Account ID | use directly |

If all fail, ask for the account name. An id handed in can be either UUID kind: the Vitally MCP resolves both, the warehouse matches org ids on `vitally.accounts.external_id` only.

**One customer carries a different name in each system, so check what the name you were handed refers to.** Vitally's account name, `stripe.name` (often a legal entity), `zendesk.name`, `sfdc.Website` and the per-project names in `resolve-teams` are five independent fields that sometimes disagree, and the name you were given can turn out to be a near-empty second project rather than the account. State in the header which name maps to what whenever they diverge, and report on the project carrying the volume.

`get_user_details` hits two limits. It can **filter** on large accounts (stripping custom traits, printing "Removed N trait fields"; a small account can come back complete, so the warehouse traits read is the authority either way) and can **overflow** on a several-hundred-user account. Split the read by source; custom traits carry a `vitally.custom.` prefix.

| Read from | Fields |
|---|---|
| **`vitally.accounts.traits`** in the warehouse (`WHERE id = '<VITALLY_ACCOUNT_ID>'`), which `get_user_details` filters out | `onboardingPipeline`, `onboardingMinimumEligibility`, `onboardingUsageOutreachSentDate`, `onboarding_invoice_count`, `usEuInstance`, `csmId`, `accountExecutiveId` |
| **`get_user_details`** | `healthScore`, `nextRenewalDate`, `contractRenewalDate`, `usersCount`, `usage_mrr`, `forecasted_mrr`, `forecasted_usage_mrr`, `diff_dollars`, `paidProducts` + `payingFor<Product>` + `<product>_forecasted_mrr`, `replayCountLast30DaysIfSendingData`, `group_types_total`, `active_hog_destinations`, `active_batch_exports`, `firstSeenTimestamp`, `roleAtOrganization` |

**Always run the domain sibling sweep, both halves.** A sibling org is a duplicate paying twice, a consolidation question, or an account a teammate owns. The two queries see different populations (`vitally.users` and `billing_customer`) and neither alone is complete; skipping one is how a duplicate-billing sibling stays hidden. Flag any sibling in the header: one org with multiple projects usually beats parallel orgs.

**Then probe usage across every org the sweep returned and build the context on the one carrying the volume.** `get_user_details` returns `accounts[0]`, whichever account Vitally lists first, and on a multi-org customer that is routinely not the live one, so every downstream figure would describe a dead org. **This gates the Round 2 launch: no gatherer starts until it has resolved**, because a gatherer given the wrong org id does perfect work on the wrong company.

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

Detect the region from `vitally.custom.usEuInstance` (an array, e.g. `["US"]`), populated far more widely than `cloudRegion`; fall back to `cloudRegion`, then `traits.site_url`, where `eu.posthog.com` means EU. Project 2 answers almost everything for both regions; the exceptions are EU experiment definitions and the EU direct connection, both on the EU key and EU project 1.

### How to fan out

**Fan the gathering out, reconcile in one head, then fan the verification out separately.** The two fan-outs are not interchangeable: gathering happens before there are claims, verification after.

A round costs what its deepest agent costs, and an agent costs its longest chain of dependent calls. So **batch first** (every read depending only on the context goes out in one block; on the HTTP path one `phq.py --batch`), **widen second** (one grouped query per org and region rather than one per team, per `data-rules.md`), **split last** and only along a true dependency. No brief carries a serial chain longer than 8 to 10 reads: count the chain, not the calls.

- **Budget in tool calls, never seconds. Cap each gatherer at 12 to 15**, and split the brief BEFORE launching if the list runs past 15. Nobody can estimate an agent's seconds; everyone can count reads in a brief.
- **The budget caps shape, never scope.** Never drop, defer or narrow a read to fit it. The move when a brief is too big is to split it, and a read that still will not fit runs over budget and is named in the closing note.
- **Split by call count; never merge briefs by topic.** Concurrent agents are near-free in wall clock; calls inside one agent serialize into one chain. Merging trades a cheap resource for an expensive one, so the instinct to reduce agent count is backwards.
- **8 to 10 concurrent agents, each batching 4 wide.** Past that ClickHouse returns 202 and the HTTP path returns 429, and the forced serial retries are slower than not splitting. The cap is machine-wide, so expect an occasional refusal and retry rather than shipping without the refused brief. **The binding limit is concurrent QUERIES, not agents**: 8 agents batching 4 wide is already ~32 in flight, which is why the agent count looks low. A wave of short, query-light roles can run wider than a wave of heavy ones.
- **Splitting stops paying below about 12 calls**, because every agent carries a fixed startup cost whatever you give it. Split down to 12 to 15, then stop.
- **One wave is the default. A wave boundary is for a DEPENDENCY, never for headcount, and a wave costs its slowest member.** Staging by topic importance is the live failure mode: it strands a long role in wave two where it idles and then becomes the critical path alone. When the set genuinely exceeds the cap, **stage by expected duration and put the long poles in wave one.**
- **Rough order, longest first**, measured once on a two-project EU account so beat it with what you observe: `usage-trend`, `change-point`, `definitions-and-hygiene`, `internal-context`, `clay` · `event-mix`, `site-scan`, `replay-and-errors`, `flags-and-experiments`, `money-quotas` · `data-platform`, `identity-and-sdks`, `app-engagement`, `money-invoices`, `docs-prewarm`. Two are placed on judgment rather than that clock: `clay` and `internal-context` both finished early only because their tools were absent, and a run where Clay polls for credits or Gong pages a transcript is far slower. `money-quotas` is promoted above its length, because what a limit actually cut off reframes every other finding. `docs-prewarm` goes last and never takes a required gatherer's slot.

| Round | Who | Does what |
|---|---|---|
| 1a. Unblock | Main, three ordered batches | Everything deciding **who** to research and **which batch** to run, because both are wrong to guess. **Batch 1**: the Vitally resolve, `resolve-teams`, BOTH halves of `sibling-sweep`, **and the `site-scan` subagent on the admin email domain, in this same block**. **Batch 2**: the multi-org volume probe, which names the live org, **plus one further `site-scan` per team beyond the first, each handed its own `api_token` from `resolve-teams`**. **Batch 3, and only now that the live org is known**: the scope probe, the stage trait, `get_account_conversations` and the calendar read. Then write the context file (`agent-briefs.md`), detect the mode, and launch Round 2. **The three batches are ordered, not one block.** Running the scope probe beside the sweep profiles whichever org `accounts[0]` happened to return, and on the multi-org account this gate exists for that is the dead one, so its numbers land in the context file every gatherer then trusts |
| 1b. Resolve | Main, one block, concurrent with Round 2 | `get_user_details`, the `vitally.accounts.traits` read, `account-state`, `account-spine`, `onboarding-state`, `other-account-tables`, `conversation-bodies`, **`change-timeline`**, **`billing-limit-updates`**, `account-context`, `touchpoint-timeline`. Naming these is what stops them being silently skipped. `billing-limit-updates` is one query, it names the actor behind every limit, and a limit moved before a call reframes the money picture |
| 2. Gather | The roles below, in ONE wave where the cap allows, else staged longest-first | Every role the mode requires, `docs-prewarm` last |
| 2. (concurrently) | Main | Reading the conversation bodies, Step 4 roster, refining mode detection as `internal-context` returns |
| 3. Reconcile | Main, in ONE parallel block | The roll call, the hedge sweep, the named pairs, then re-run the header figures and the number driving the top recommendation. List every claim the output will make. Surface any disagreement between two sources with both figures, never resolve it |
| 4. Verify | Main where the cache covers the claim, one subagent per uncovered cluster, **capped at ~5 claims each** | A live docs search per claim, returning the URL and the verbatim line that proves it |
| 5. Write | Main | The output |

**There is no separate pre-resolve round, and there is one site scan per TEAM rather than one per account.** The domain scan needs only the admin email domain, which Step 1 has before it queries anything, so it goes in batch 1 beside the resolve rather than in front of it. An org with several teams runs several tokens, so one scan reads one project's `init()` and leaves the rest unknown: `resolve-teams` returns `api_token` for exactly this, and every team beyond the first gets its own scan in batch 2. Rescan on top of that only when Step 1 returns a different domain.

This is a correctness rule, not a speed one. **A gatherer cannot be asked to recommend a config change on a project whose config is unread**, and the unscanned project is repeatedly the one holding the findings: on a two-project account the scanned project had already been optimized and the unscanned one held every remaining lever.

Give every subagent **the path to the context file**, the conventions block, its reading-map row, and the return rules, all from `agent-briefs.md`. **The context is resolved once by main and no gatherer re-resolves any of it**; a gatherer missing a value reports the gap rather than querying for it. The `site-scan` agents are the exception, because they run before the context file exists: the batch-1 scan gets only the domain, and each batch-2 scan gets the domain plus its own team id and `api_token`.

**Probe an optional source once.** Gong, Slack and Clay share a shape: emptiness is knowable in one call, and a zero ends that source. Report "searched X, zero results", which is a finding and not a skip.

**The role roster, what each owns and which sections each opens, is one table in `agent-briefs.md`.** It lives there because that is the file main reads to write the briefs, and two tables listing the same roles in two always-loaded files is how they drift apart.

`agent-briefs.md` holds the exact sections each role opens, and that map is what the brief carries. **Ask each gatherer 3 to 4 questions, not six**: six numbered questions invite six investigations and turn a 12-call role into a 30-call one.

Probe an unfamiliar property in the block you are already firing, never in its own round: add `JSONExtractKeys(assumeNotNull(properties))` for that event.

### The scope probe, and its three guards

The Round 1a scope probe (one `per-product-usage` aggregate) knows which products carry volume. Pass it into each product brief as known state, each line carrying its own proof (`billable_feature_flag_requests_count_in_period = 0 in billing_usage_by_org_date over the window`, never a bare "flags are zero"). **It changes what a brief says, never whether it runs.** Three guards, and it is unsafe without all three:

1. Write `unmeasurable, no source` for every product the probe has no column for. Experiment volume and web analytics volume have no source anywhere; heatmap volume lives only on the usage report's `teams` map; `ff_count` lives on the org usage report.
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

**Cap a verifier at about 5 claims and add agents rather than claims.** The cap is about blast radius, not depth: verification is the last step of the run, so a twelve-claim verifier is a single point of failure at the moment there is no time left to redo it, and one has stalled mid-stream having written nothing. When a verifier does die, resume it from its transcript rather than restarting it, and tell it to **write its file first and reply second** and to mark every claim it never reached as NOT REACHED. An omitted claim reads as a verified one, which is the failure this whole round exists to prevent. Searching from `paidProducts` before the findings exist verifies levers you predicted and misses the ones the data produced, so build the claim list first (the pre-draft check in `voice.md`), then verify every lever and product fact it states.

Three lines govern the cache, and every Round 4 brief states them verbatim: a cached page is evidence only for a claim whose OWN live search returned that URL; the cache supplies a page body, never a verdict and never a citation; the cache is per run, never a page a previous run fetched. A verifier returns the verdict, the canonical URL and the verbatim sentence. `not found` is permitted, and a claim that comes back that way is cut or rewritten as a question, never shipped with the nearest-looking link. Cite `posthog.com/docs` first, a PostHog-authored `posthog.com/tutorials` page when no docs page covers it, never Community Questions or GitHub issues. If `docs-search` is unreachable, verify each URL with a plain HTTPS fetch.

### The closing note

Nothing accumulates across runs, so this note is the only record. At Step 5, after the output, add a short note in chat: which agents ran long, any brief that overran its cap, and any fix this run revealed that belongs in the skill. Suggestion only. Two figures belong in it because both are correctness checks, not telemetry:

- **Claims whose own citation URL you fetched, against total claims.** Count it from a list you append to as each verification happens, never from memory at the end of the run: a number reconstructed at the end is a number you will inflate, and an inflated count is worse than none, because the ratio is the only thing standing between a real Round 4 and a warm cache. Count fetched citations rather than searches run, because a search that returned a confident, adjacent page is exactly the failure this is watching for and it looks identical to a search that answered the question.
- **Roles launched against roles required, and Round 1 slugs returned against Round 1 slugs required.** Print both halves. A dropped role is the loud half and gets noticed anyway; a Round 1 slug that quietly never ran is the silent half, and it is the one that reaches the output as an absence nobody questioned.
- **Hedges found, closed, and carried**, as three numbers from the Round 3 list.

### What main covers beyond the roles

Round 2 subagents own the reads in the table; main does not re-run them. Beyond it: Vitally's `get_account_conversations` (limit 20; metadata only, `source: "google"` is Gmail or calendar, `zendesk` is support), `get_account_feature_requests`, `get_account_health`. Conversation bodies, notes and tasks come from the warehouse (`vitally.messages`, `vitally.notes`, `vitally.tasks`), avoiding the MCP calls that overflow on large accounts. **Every email with the account syncs to Vitally, so that pair of reads is the whole comms record and a mailbox search adds nothing.** Do not reach for one: a `gog gmail search` on a contact's first name matched a different customer's personal address at another domain and nearly put that account's failed payment into this brief. If you search a mailbox anyway, read the recipient domain before treating a message as this account's. Keep both the Vitally traits and the postgres reads where they overlap and cross-check them. The calendar runs every run with an explicit start/end window (unbounded text searches return nothing), by attendee name from the `Accepted:` subject, else by account name and admin emails.

**Four names main needs by hand, because main verifies numbers without opening a query file.** The event saying a limit actually cut a product off is **`org_quota_limited_until`**; who changed a limit is **`billing limits updated`**; the live forecast is **`billing_customer` joined to `billing_upcominginvoice` on `customer_id`**; current limits are **`custom_limits_map`**. A guessed column here returns an empty result that reads exactly like "nothing was limited", the inverse of the truth. **These are pointers, not recipes: open `quota-limits` and `in-flight-period` in `queries-money.md` before writing either query**, because both carry filters and aliases that decide whether the result means anything, and writing SQL from this paragraph alone has produced a column of nulls and a hard 400.

Call prep runs every role. An email run drops the roles whose product the account does not implicate, and names each one dropped. In every mode, skip an individual read only when it cannot apply, and name each skip. Lookback 30 days; re-run a single query at 14 days (follow-up) or 7 (same-week call prep) only where the shorter window changes the conclusion.

## Step 3. Mode detection

**This step flags, it never blocks; any mode or request runs on any account.** The skill only drafts, so a human weighs every output; raise contradictions loudly, never withhold work.

Flag at the top when the account looks already-handled: `onboardingMinimumEligibility` false, a terminal stage (`3. Onboarding Completed`, `6c. Sales Handoff`, `7. Paid Call Purchased`), or a teammate's recent message on the same topic. An assignment is never a flag; only an active thread is.

The user's explicit ask always wins: "draft outreach for X" produces the draft whatever the account state, flag leading, never a refusal. The signals below decide only when the ask is open. A pasted inbound is a reply; a named call is call prep.

| | Signal | Read from | Watch for |
|---|---|---|---|
| stage | Pipeline stage | `vitally.custom.onboardingPipeline` | The only field carrying the stage, and every live value carries a numeric prefix: `1. New Account`, `2. Onboarding Initiated`, `3. Onboarding Completed`, `6c. Sales Handoff`, `7. Paid Call Purchased`. Match the full string including the prefix; a bare `New Account` matches nothing, and neither does the unprefixed trait key. Retired values still in the wild (`3. Customer Engaged`, `3a.`/`3b. Engaged`, `6a.`/`6b. Onboarded`, `6d. Churned`) get flagged rather than routed on. **Absent** means never entered the pipeline: it routes like `1. New Account` only when the account is eligible with no AE or CSM. Absent beside an assigned **AE or CSM** means sales has it: note it, still draft, put the loop-in in the framing. An assigned **OS** says nothing here |
| outreach | Initial outreach sent | `vitally.custom.onboardingUsageOutreachSentDate` | Fall back to `vitally.custom.initialOutreach`, often null even when outreach went out |
| threads | Onboarding-team conversations | `vitally.messages.from` admin ids | AE and support threads do not count |
| meeting | Booked FUTURE meeting | conversation `source: "google"` with an acceptance subject (`Accepted:`, localized, e.g. `Angenommen:`) | A hint only. Confirm the date on the calendar and fall through if the meeting is past, declined or not found, or a stale acceptance routes to call prep forever |
| inbound | Inbound after outbound | `lastInboundMessageTimestamp` vs `lastOutboundMessageTimestamp` | Counts AE, CSM and support threads and fires on system messages, so it is often true off a calendar acceptance. A prompt to read the actual latest inbound body, never a reason to route alone. If the latest inbound is a calendar or system message, or is addressed to another owner, the signal is not satisfied |

Read the stage from the trait, not from `crm_segments` / Vitally `segments`. Those are a different field with a different vocabulary (`Onboarding Lead`, `Onboarding referral`, `CSM Managed`, `TAM`, `Top 20`, `Annual Plan`), carry no `New Account` and no `Sales Handoff`, and no value matches the trait's exactly. Segments corroborate the stage and hold the durable sales-referral record; they never define the stage.

Routing, for an open ask only:

0. **Terminal stage, or a live thread on the same topic held by a teammate OR by the sender**: the flag leads, the research is still full, and the recommendation is a note or a loop-in rather than cold outreach. **This sets the framing and never the mode, so carry on down the list**; a run that stops here has a flag and no output. The sender's own recent thread is a collision exactly like a teammate's: not a reason to withhold a draft, but the thing the draft must not repeat.
1. **inbound true** and the latest inbound is a real customer question: **email, reply state**
2. else **meeting present**: **call prep**
3. else stage is `1. New Account`, or absent with `onboardingMinimumEligibility` true and no AE or CSM, outreach null, threads 0: **email, first-touch state**. An absent stage beside an assigned AE or CSM falls through to 4
4. else **email, follow-up state**

Read the conversation history before finalizing; thread context outranks any single signal. Flag and keep going on: outreach exists but stage still `1. New Account`; stage `2. Onboarding Initiated` with no outreach trace; terminal timestamps on a non-terminal stage, the signature of a sales-disqualification reset.

## Step 4. People on the account (report it, do not route on it)

Report the roster in the header every run, assigned or not: `OS <name or NONE> · CSM <name or NONE> · AE <name or NONE>`. Middle dots, never pipes, which break the table cell.

**An assignment is roster data, never a warning; an active thread earns the flag.** An OS stays assigned after onboarding completes and an AE or CSM is often simply unassigned, so `NONE` is common and correct. Never turn either into "this belongs to X, check first": it reads as a blocker, is usually wrong, and buries the research. A teammate who recently messaged the account on the topic at hand IS a collision: read the conversation history for that, not the ownership fields.

Sources in order: the Vitally `key_roles` array (the `keyrole` rows in `account-context`) carries role label, email and name together; `accounts_replacement_v2.csm_name` / `ae_name` and Vitally `csmId` / `accountExecutiveId` corroborate; `billing_customer.sales_info.owner_*` and `crm_segments` are the fallback. `Top 20` is an account tier, not a person. A set `sfdc.last_task_disqualified__c` with no AE or CSM means sales passed and onboarding has the account again: note the date.

**To answer "was this account ever referred to sales", read the `Onboarding referral` segment, not the stage.** Adding that segment fires the handoff playbook and it persists after the stage moves on, so a referred account routinely shows another stage. Read it with `sfdc.last_task_disqualified__c`: segment present and disqualified means it came back and is yours; segment present and not disqualified means sales still has it.

On annual plans read `purchasedCreditAmount`, `stripe.accountBalance`, `creditRunwayDays`, `projectedCreditExpiryDate`, `creditExpiryVsAnnualPlanExpiry`. Credits projected to run out before the plan ends go in the header, since they change the conversation rather than the draft.

## Step 5. Output

No em dashes, en dashes or double hyphens in any output, the internal brief included.

Read `references/voice.md` before drafting anything a customer will see, `references/levers.md` before stating any recommendation, and the one mode file for the artifact.

Common header for every email and every call-prep brief, and for any other ask whose artifact is an account brief. Render it as a real markdown table, never inside a code fence (the fence below is only the template's source). Drop a row that does not apply rather than writing `n/a`.

```
# <Account> | <Artifact: first touch / follow-up / reply / call prep>

> **Flag:** <only when one applies: a teammate's live thread on this topic, a stage mismatch, a sibling org. Never a roster name.>

| | |
|---|---|
| **Pipeline** | <stage> |
| **Health** | <X>/10 |
| **Renewal** | <date> (<n> days, monthly cycle or contract) |
| **MRR** | $<actual> booked to $<forecast> forecast (<±delta>) |
| **Paid** | <products> |
| **Limits set** | <product $each>. Mark any at or near its forecast; say NONE where the largest line has no limit |
| **Limits biting** | Which products a limit has ACTUALLY cut off, from `quota-limits`, each with its start date and whether it is dropping now. NONE is an answer and is written out. A limit that is set and a limit that is destroying data are different facts |
| **People** | OS <name or NONE> · CSM <name or NONE> · AE <name or NONE> |
| **Users** | <total> listed, <n> with seats, <n> with real activity |
| **Org** | <link> |
```

Header field rules, since several traits collide:

| Field | Rule |
|---|---|
| Renewal | On an annual plan `nextRenewalDate` is the monthly billing-cycle end, not the contract renewal: use `contractRenewalDate` (or `numberOfDaysUntilEndOfContract`). On a monthly account they are the same |
| MRR | `usage_mrr` is actual, `forecasted_mrr` is forecast, both net of any credit discount (`forecasted_usage_mrr` is the gross figure, do not mix them). Delta is `forecasted_mrr - usage_mrr`; a negative delta on an annual account is usually the annual-vs-usage artifact, not churn. `diff_dollars` is a different comparison |
| Health | `healthScore` from `get_user_details`. Two warehouse columns share the name and neither belongs here: `vitally.accounts.health_score` is a stale copy, `account_health_scores.health_score` is PostHog's own engagement model |
| Users total | `usersCount` from `get_user_details`; per-query counts can differ |
| Org link | `https://us.posthog.com/project/2/groups/0/<ORG_ID>` (organization is group type 0) |

Before handing the output over, confirm all eight and send anything unchecked back to the round that owns it: every claim traces to this run's queries or live searches; every skip is named per subagent with its reason; every trap hit is reported, and a run reporting none was interrogated; every source disagreement shows both figures unresolved; the header is a real table with the People row present; **no section shipped as settled while an agent owning its subject was still running**; the Round 3 roll call ran and any shortfall is named; the closing note states both figures.

**The write gate is the one traded away under time pressure, so it is explicit: a still-running agent owns its subject until it returns.** Wait for it, or write the section and mark it provisional in the output. Marked provisional satisfies the checklist; shipped as settled does not. A confident section a pending agent then contradicts costs the user a correction on work they have already read, and may have already acted on.

## Pipeline reminder

A reminder to raise with the user, never a write to perform unless they ask for that write in so many words. Once they say they acted: outreach sent means `Onboarding Pipeline` moves to `2. Onboarding Initiated`; passed to sales means `6c. Sales Handoff`. Suggest a Vitally note only when the research concluded "do not reach out", recording why. A draft-only run needs no write.

## Improving the skill

When a run reveals a fix, ask whether to fold it in. Write the rule into the file that owns it, in the fewest words, and fix the rule that failed rather than adding an exception. Two rules keep these files honest. **Every line changes what the model does**; provenance, measurements and orientation go to `README.md`, which is never loaded at runtime, or get cut. **The shape of the data is durable and gets written down** (a join key, a column that does not exist, an id that collides across regions); **the state of the product is perishable and belongs nowhere** (which SDKs support a feature, what a tier costs, where a setting lives), so search for it every time and never record the answer.
