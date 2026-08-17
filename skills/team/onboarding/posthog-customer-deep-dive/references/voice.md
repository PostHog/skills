# Voice: email shape and discipline

Read before drafting anything a customer will see, in every mode. The research is exhaustive and verified; the draft is short: pure facts and clear next steps. Wrap drafts in a code fence with inline doc links.

## Shape

For an email that starts a new thread, two code fences in this order; a reply or a follow-up riding an existing thread gets only the email fence and no subject (the mode file's rule wins). The first fence carries the subject line alone, no `Subject:` prefix, so it can be copied separately; subjects state the concrete benefit in plain colleague language ("Quick usage check before your PostHog renewal"). The second carries the email.

Open with the reader's first name; the company name when the name looks like a transcription artifact; "Hi there," when neither is reliable. Never `Dear`, never `Hope this finds you well`. Introduce yourself only on first contact, one line. On a call follow-up: one line thanking them for the call joined to a specific note about their business (a use case, a decision, a milestone), never a generic line about learning how they use PostHog; then the recording link, then one line introducing the summary.

The body is topic blocks and nothing else: a linked title, a colon, then 2 to 4 plain sentences. The first sentences say what the finding is and why it matters, with doc links riding the action verbs; the last sentence is always one concrete thing the reader does next. No markdown headings, no bullets, no bold inside the email except linked product titles in lever blocks and the dated money line. Up to seven blocks (the mode file's lever cap sets the count, never a minimum), merged rather than split, ordered by impact, never by the order things came up. An open ticket, unresolved bug, or question left hanging gets its own block with an operational action sentence.

Close on one short line offering help, then the config sign-off (billing-threads variant on billing and payment threads), and stop: no name, no title, no block, the signature auto-fills.

**Skeleton** (the shape; phrasing is yours):

> Hi <name>,
>
> <One line: the answer or what changed, with the dated money line if one exists.>
>
> **[<Product>](docs-url)** (~<X>% of your <bill or volume>): <what is happening and why it matters>. <Fix with the docs link on the verb>, then <second fix>.
>
> **[<Product>](docs-url)** (~<X>% of your <bill or volume>): <same shape>.
>
> <One short line offering help.>
>
> <sign-off>

**After a call-follow-up email**, output `## Follow-ups from the call:` for the user only. Category 1: anything worth raising with another PostHog team, each a short title, one sentence of context, and a Slack-ready blockquote with no @mentions. Category 2: what the sender committed to do, each a verb-first title and one sentence, no blockquote. Category 1 first. Leave out placeholders the user fills by hand and anything the email already resolves. Both empty: the single line `No follow-ups identified from this call.`

> Hi <names>,
>
> <Thanks for the call today, it was great learning how you use PostHog for <their specific use-case>. Here's the [full call recording](https://placeholder.com), and a summary of what we discussed:>
>
> **[<Topic>](docs-url)**: <what is happening and why it matters>. <Fix with the docs link on the verb>, then <second fix>.
>
> <sign-off>

## Verification

- **Pre-draft check.** Before writing any draft or brief section, list every fact, number and link it will state, and beside each the query or search from this run that produced it. Anything unmatched gets searched or queried now, or cut. Facts lifted from the tables in `levers.md` need this most: they read as already known, and they are the ones that ship unverified.
- **Check every lever against `change-timeline` in the same pass.** A lever the customer already applied is dropped as a recommendation and rewritten as one dated confirmation; the judgment is the first disqualifier in `levers.md`. It costs one read.
- **Check no lever is already in flight.** Read the shared Slack channel and its threads (replies, not just parents) for the levers you are about to send. Covered by a teammate or already agreed by the customer: drop it and build on what was said. Everything covered: flag it prominently and recommend a note or a loop-in-the-owner instead of a fresh draft. Not optional on an owned account where Slack search is configured (the conversation count reads zero by construction there); with Slack at `none`, say in the output that the in-flight check could not run.
- **Never commit the sender to anything they have not confirmed**: a credit, a discount, a colleague's time, a deadline, a cadence. A credit that looks warranted is proposed outside the code fence. Promises already made in the thread are fair to restate.
- Verify your own availability before promising a timeframe; read meeting dates off the calendar, never the customer's phrasing; reconcile any figure you shared earlier and report the update rather than prescribing from the stale number. Hedge inferred setup claims with "you seem to" when the signal is admin-side.
- **Every link is inline markdown on the words that carry it**, `[minimum duration](url)`: never a bare URL, never a URL in parentheses after the phrase, never "click here". A code fence is not an exception.
- In-app links use `app.posthog.com`, never a hardcoded `us.`/`eu.`. Copy a settings link from the docs page that documents it, anchor included; add `/project/<TEAM_ID>` only when several projects exist and one is the target. Never write a UI navigation path you have not seen on screen: link the page and let the customer navigate. Percent-encode parens in deep links (`(` to `%28`) so `count()` does not truncate in Gmail.

## The lever paragraph

The unit of recommendation, 1 to 3 sentences:

> **[Session replay](docs-url)** (~40% of your bill): set a [minimum duration](docs-url) of 5-10 seconds to drop the noise, then [sample by percentage](docs-url) or [filter by URL](docs-url) to record only the sessions you will actually review.

Bold the product name linked to its docs page, the signal in parentheses, then the fixes in priority order as a parallel series, each with a live docs link (3 to 5 per lever). Add a diagnostic hook before the colon only when it teaches something the signal does not imply. They already use the feature, so skip explaining it; an adoption pitch instead leads with the value fact and ends with the lowest-friction first step. Every recommendation needs the docs link on the verb and the share signal whenever the meter can produce one; a recommendation with neither is unfinished.

## Numbers

- Volumes become shares ("identified events are ~44% of your volume"); one signal number per lever, in the unit the product is metered in (the signal-unit rule in `levers.md`). A raw count only when the count itself is the lever. A share you cannot produce from this run's data gets dropped or turned into a question, never inferred.
- Money is stated plainly and never cut: the bolded dated bill line ("**~$514 on Jun 12**"), a credit amount, a limit under discussion. Hedge forecasts with "as of today". On a prepaid-credit or annual account, monthly usage is a credit drawdown, not an invoice: state it as usage against the credit ("usage is running ~$49k/mo against the $43k left on your credit") or lead with the renewal date; never "your bill", never "$X on <date>" as a charge.

## Style

- Open on the answer; say what happens and stop. No label openers ("Your question:", "On the bill:").
- Never attribute a point to a person or the conversation ("as you mentioned", "we discussed"): state the finding and the fix. One exception: owning a factual miss, one flat sentence, then move on.
- Explain by mechanism: name the misconception, validate it, correct it ("'Not using it' usually means not watching recordings, but PostHog bills for capturing them").
- Prescribe, never suggest: "set a minimum duration of 5 seconds", not "consider" or "you might want to".
- Paragraphs run 1 to 3 sentences. Plain words only, something a teen could understand.
- Warmth is earned and sparing: one empathetic line before the fix on a sensitive topic (a surprise bill), real praise when the customer acts.

## Banned

These read as machine writing or filler; none survives the review pass.

- **Templates**: the contrast frame in every variant (`it's not just X, it's Y`, `more than just`, `not only X but also Y`); significance inflation (`plays a crucial role`, `a testament to`, `game-changer`, `transformative`); epigram formulas that crown one detail (`X is the whole trick/point/game/thing/deal/idea`: name the thing plainly and stop); throat-clearing (`It's worth noting`, `Here's why:`, `Let me be clear:`); copula avoidance (`serves as`, `stands as`, `functions as`, `represents`, `boasts`: write `is` and `has`); weasel attributions (`Experts argue`, `Industry reports note`: name the source or drop the claim); false breadth (`whether you're a startup or an enterprise`); trailing participle padding (`, highlighting...`, `, underscoring...`); `in order to` for "to".
- **Hooks and cliches**: `here's the kicker`, `here's the thing`, `low-hanging fruit`, `move the needle`, `does the heavy lifting`, `at the end of the day`, `at its core`, `the reality is`.
- **Chatbot artifacts**: `Great question`, `You're absolutely right`, `you're right to push back`, `I hope this helps`, `feel free to`, `don't hesitate to`, `let me know if you need anything` as a reflex closer (the shape rules define the one specific offer), `Dear valued customer`, therapist mode (`You're not alone`, `It's completely understandable to feel...`: empathy is one plain line), credit-by-implication (`does not go unnoticed`: name what they did), restating the question before answering it, claiming an answer's status instead of giving it (`the real answer is`, `the actual fix is`: write the answer and the reader will see what it is), reassurance surplus (`no rush`, `whatever's easiest`, `sorry again`: one apology maximum, near the top), and `should now work` for anything unverified: verify, then state what was observed.
- **Vocabulary**: no AI-tell vocabulary of any kind (`leverage`, `utilize`, `robust`, `seamless`, `crucial` and their whole family); in particular `deep dive` in drafts (the skill's own name and the user's phrasing are not drafts), `learnings`, `circle back`, `moreover`/`furthermore`/`additionally` as connectors, `aligns with`, `when it comes to`, `poised to`.
- **Structure**: symmetric three-beat lists as a default rhythm, sentence fragments stacked for gravitas, arrow chains in prose (`A → B → fails`: write the causal chain as a sentence), synonym cycling to avoid repeating a plain word, hedge ladders, both-sidesing a claim the evidence settles, rhetorical questions as filler.
- **No predicted outcomes you do not control** (`the forecast should drop in a day or two`).

## Review pass

After drafting, reread and only remove: anything the reader already has, any second apology or reassurance, any sentence admiring a made point, any word that goes without changing the meaning. Then confirm the greeting, the specific business note, the closing offer, and every link, code fence and SDK string survived.
