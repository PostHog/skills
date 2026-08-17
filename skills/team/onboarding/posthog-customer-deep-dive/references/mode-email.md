# Email: first touch, follow-up, reply

One artifact, three states. Step 3 picks the state; the user's explicit ask wins. `voice.md` governs everything a customer sees, and the full cost-first analysis (signal with real numbers, fix, live docs link) stays pre-draft: the draft carries only what the state's lever cap allows.

| | First touch | Follow-up | Reply |
|---|---|---|---|
| **Precondition** | none | a prior ONBOARDING touch exists (an AE, CSM or support thread is not one) | the latest inbound is a real customer question (a calendar or system message, or a thread addressed to the AE or CSM, is not one: reply to the most recent real customer message instead, or fall back to the follow-up state) |
| **Subject** | own fence, states the concrete benefit | none, rides the thread. Exception: the first email after a call starts its own thread with `🦔 PostHog Onboarding Call Recap: <Main Topic or Two Covered. Fallback is without any topics and without ':'>` | none |
| **Opening** | greeting, one-line intro, bolded dated bill line | one line on the prior thread and what changed | their questions listed verbatim |
| **Body order** | levers by impact | what they acted on, then 1 to 2 new angles, cost first | THEIR question order, one paragraph each (mechanism, share, fix); this overrides `voice.md`'s order-by-impact rule |
| **Lever cap** | 1 to 3 | 2 (an over-correction counts as one) | only what they asked, unless one finding outranks their question |
| **CTA** | exactly one, on the booking link, always | at most one, none when nothing must happen next | at most one real next step, none is fine |
| **Length** | full | shorter than a first touch | as long as the questions |

## First touch

Rank the top 4 contacts by event volume plus billing-page visits; with no billing-page visits, rank by volume and say so. Enrich the primary via Clay if configured. Two variants on the bill line: a free or near-zero account gets no bill line and leads with setup quality and value, same shape; a prepaid-credit or annual account replaces it with the usage-against-credit or renewal framing under Numbers in `voice.md`.

## Follow-up

Summarize the last interaction, then check each recommendation it made against current state: acted on, ignored, or over-corrected (a product disabled entirely instead of tuned). Acknowledge what improved before raising what did not. When the only prior contact was a teammate's thread, there is nothing of onboarding's own to follow up on: on an open ask, recommend a note or a loop-in-the-owner and say so rather than summarizing their thread as ours; when the user asked for a follow-up, draft it anyway, flag the collision, reference the teammate's thread in third person, and never repeat it. For a call follow-up, be thorough and read the actual transcript (Gong, paginated to the end, per `config.md`).

## Reply

When no open question exists and a reply is still wanted, say plainly that there is no inbound, then pick the question the account's own data is about to generate and name why you picked it: a product that just stopped ingesting, a limit raised on one product and not its neighbour, a figure that moved since the last touch. Something they already asked and never got answered beats something they have not asked yet. Never invent a question you cannot point at evidence for, and never present the reply as if it answers a real message.

Check whether one of your own outbounds already answered the question; if it did, flag that and build on it without repeating it. Take a position where you have one ("I'd reconsider this with the proper setup."). When a misconfiguration drove an unexpected charge and the sender has confirmed a credit, state it in one plain sentence.

## Binding in every state

- **Collision**: when the thread belongs to a teammate, confirm who sends before drafting; if the sender differs from the thread owner, reference the teammate's reply in third person without repeating it.
- **Diagnostic questions** ("why is X the cost", "what is driving Y"): name every plausible cause and give each an explicit verdict, ruled in or ruled out with the reason, not only the one that fits. A cause dismissed in a clause ("not identify, your flag traffic is backend") is what makes the diagnosis trustworthy; a cause the reader is quietly wondering about, left unaddressed, reads as a gap. `levers.md` lists the candidate causes for the common cost questions.
- After the draft is ready, re-check it against every rule in `voice.md`.
