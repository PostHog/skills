# Email: first touch, follow-up, reply

One artifact, three states. Step 3 picks the state; the user's explicit ask wins. `voice.md` governs everything a customer sees, and the full cost-first analysis (signal with real numbers, fix, live docs link) stays pre-draft: the draft carries only what the state's lever cap allows.

| | First touch | Follow-up | Reply |
|---|---|---|---|
| **Precondition** | nothing onboarding sent yet, by hand or by `Onboarding:: Email sequence`; `opted_out` not `'true'`; no current CSM, AE or TAM; no referral tag without a later disqualification; no other PostHog outreach in 30 days (Step 3, route 3) | `opted_out` not `'true'`, and a prior ONBOARDING touch exists: a sequence email in `onboarding-automation` or an onboarding-sent row in `conversation-history` (an AE, CSM or support thread is not one) | the latest inbound is a real customer question (a calendar or system message, or a thread addressed to the AE or CSM, is not one: reply to the most recent real customer message instead, or fall back to the follow-up state) |
| **Subject** | own fence, states the concrete benefit | none, rides the thread. Two exceptions start a new thread with a subject: a prior touch that sits in someone else's mailbox (an `Onboarding:: Email sequence` send, or a teammate's hand-sent email), which cannot be replied to from the sender's (or ask them to forward it). Read which teammate the sequence send went out under (`from_name` in `conversation-history`): when it was the sender, refer to it in first person ("my email on 2 October"); otherwise name that teammate's email in third person; and the first email after a call with `🦔 PostHog Onboarding Call Recap: <Main Topic or Two Covered. Fallback is without any topics and without ':'>` | none |
| **Opening** | greeting, one-line intro, bolded dated bill line | one line on the prior thread and what changed | the answer to their first question, each question quoted as a `>` line directly above its answer, never listed up front |
| **Body order** | levers by impact | what they acted on, then 1 to 2 new angles, cost first | THEIR question order, one paragraph each (mechanism, share, fix); this overrides `voice.md`'s order-by-impact rule |
| **Lever cap** | 1 to 3 | 2 (an over-correction counts as one) | only what they asked, unless one finding outranks their question |
| **CTA** | exactly one, on the booking link, except on an org `org-status` reads as switched off, where it offers no call | at most one, none when nothing must happen next | at most one real next step, none is fine |
| **Length** | full | shorter than a first touch | as long as the questions |

## First touch

**Check the sequence first.** `Onboarding:: Email sequence` sends email 1 itself to Eligible accounts under its forecast ceiling that are unowned, unreferred, not opted out and not contacted by anyone at PostHog in 30 days, so on one of those a hand-written first touch doubles it: say when the automated one goes (Step 3's `next` signal) and draft only on an explicit ask. The hand-written first touch is for an Eligible account above that ceiling. An account the sequence skips for an owner, a referral tag, an opt-out or other PostHog outreach gets the account brief with the loop-in (Step 3), never a first touch.

**Sending one enrols the account in the rest of the sequence.** `Onboarding:: Set "Onboarding Initiated" when contacted by OS` moves it to `2. Onboarding Initiated`, and the sequence then sends its later emails from day 14 on its own, from a rotating teammate. So never preview or duplicate those emails, and tell the user it will happen.

Rank the top 4 contacts by event volume plus billing-page visits; with no billing-page visits, rank by volume and say so. Enrich the primary via Clay if configured. Two variants on the bill line: a free or near-zero account gets no bill line and leads with setup quality and value, same shape; a prepaid-credit or annual account replaces it with the usage-against-credit or renewal framing under Numbers in `voice.md`.

## Follow-up

Summarize the last interaction from `conversation-history` and `onboarding-automation`, a sequence email included, then check each recommendation it made against current state: acted on, ignored, or over-corrected (a product disabled entirely instead of tuned). Acknowledge what improved before raising what did not. When the only prior contact was a teammate's thread, there is nothing of onboarding's own to follow up on: on an open ask, recommend a note or a loop-in-the-owner and say so rather than summarizing their thread as ours; when the user asked for a follow-up, draft it anyway, flag the collision, reference the teammate's thread in third person, and never repeat it. For a call follow-up, be thorough and read the actual transcript (Gong, paginated to the end, per `config.md`).

## Reply

When no open question exists and a reply is still wanted, say plainly that there is no inbound, then pick the question the account's own data is about to generate and name why you picked it: a product that just stopped ingesting, a limit raised on one product and not its neighbour, a figure that moved since the last touch. Something they already asked and never got answered beats something they have not asked yet. Never invent a question you cannot point at evidence for, and never present the reply as if it answers a real message.

Check whether one of your own outbounds already answered the question; if it did, flag that and build on it without repeating it. Take a position where you have one ("I'd reconsider this with the proper setup."). When a misconfiguration drove an unexpected charge and the sender has confirmed a credit, state it in one plain sentence.

## Binding in every state

- **Collision**: when the thread belongs to a teammate, confirm who sends before drafting; if the sender differs from the thread owner, reference the teammate's reply in third person without repeating it.
- **Diagnostic questions** ("why is X the cost", "what is driving Y"): name every plausible cause and give each an explicit verdict, ruled in or ruled out with the reason, not only the one that fits. A cause dismissed in a clause ("not identify, your flag traffic is backend") is what makes the diagnosis trustworthy; a cause the reader is quietly wondering about, left unaddressed, reads as a gap. `levers.md` lists the candidate causes for the common cost questions.
- **Post-onboarding survey**: the survey link in `config.md` is the graduation CTA only, for a hand-written close-out. The sequence's own graduation email (day 49) goes on its own, so never draft a second one. Keep it out of a first touch, a follow-up and a reply, and never send it alongside the booking link: it asks for feedback on work still running, and it makes a second CTA.
- After the draft is ready, re-check it against every rule in `voice.md`.
