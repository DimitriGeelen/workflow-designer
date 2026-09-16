# T-732 — Arc-0 exit, clause 3: the four open operator rulings

**Assembled 2026-09-16 under T-732.** One section per question that
`docs/research/executable-workflow/operator-decisions.yaml` currently reports `status: open`
with `blocks_arc_0_exit: true`. Every recommendation below is **quoted verbatim from the
register** (PL-323 — never paraphrase a clause the operator is about to rule on). Nothing here
is a decision; this is the packet the decision is made against.

**Approvals route:** http://192.168.10.107:3013/approvals

---

## Why this is the only Arc-0 work on our side — and the one place that claim is too strong

The Arc-0 exit gate has three clauses. Two are counterparty-owned and cannot be moved from here:

| Clause | Owner | State |
|---|---|---|
| **clause-1** — topology non-empty and validated | AEF | **Answered red by AEF, 2026-08-27** (offset 650, thread T-3127): 1134 cards, 52 edgeless, 749 outside any watch pattern. They declined to attest in terms — *"I would rather hand you a red number I trust than a green one neither of us can reproduce."* `attestation: null` |
| **clause-2** — contract/refusal matrix complete | AEF | Artifact does not exist in this repository and was never the Designer side's to build. `attestation: null` |
| **clause-3** — no unresolved source-of-truth ambiguity | shared | `method: local-register` — satisfied when every blocking H-question is `resolved`. **H2, H4 resolved. H1, H3, H5, H6 open.** |

**The correction.** The task that carries this dossier was filed saying clause 3 is "the only one
on our side of the fence." Assembling the packet showed that is **not quite true, and the
exception is H6.** The register's own recommendation for H6 says it *"resolves when AEF answers
and the operator accepts the answer."* AEF has answered on clause 1; whether they have answered
**R6/R7** is not established in this register. So clause 3 is partly counterparty-blocked too,
through H6. Three of the four rulings are ours to make today; the fourth may not be.

Recorded rather than smoothed, because a dossier that overstated how much the operator could
unblock in one sitting would be selling the ruling on a false premise.

**Also not in scope, deliberately:** filing tasks for roadmap Arcs 1/3/5/6. The operator's own
GO on T-681 (2026-09-05) recommends against it — *"decomposing work whose inputs are
counterparty-blocked manufactures a backlog that measures as progress and cannot move."*

---

## H1 — Do the roadmap's Arcs 4–6 supersede the standing DEFERs (T-279/280/281/282) and AEF's T-2669 NO-GO?

**Why the operator:** *"Reversing a recorded disposition is a sovereignty act. Until answered,
treat those arcs as not actionable, whatever they score."*

**Operative state (verbatim):**

> The DEFERs and the NO-GO STAND. T-587's recorded GO decided the scope of one narrow Arc-0
> slice and explicitly declined to reverse them — its rationale names the absence directly:
> "without a superseding decision. Scheduling those would reverse recorded dispositions on a
> document's say-so." Deciding a slice's scope is not the same act as answering H1, so T-587 is
> NOT this question's source_of_truth.

**Recorded recommendation (verbatim) — RATIFIABLE AS WRITTEN:**

> Keep the DEFERs standing. Nothing has changed on the evidence side since they were recorded;
> the roadmap re-proposing the work is a document's say-so, which is the exact input T-587
> already declined to treat as superseding.

**What it costs to leave open.** T-279, T-280, T-281 and T-282 all currently sit in the **hv-lc**
quadrant at a flat **BVP 126** — the inception-abstention tie, not a real score. They are
selectable by value and unactionable by disposition at the same time. Every autonomous pass has
to re-derive that contradiction from scratch.

---

## H3 — Assign the two correlations, one for this agent and one for the initiative

**Why the operator:** *"Phase 4 completion is undefined without them (IW-9)."*

**Operative state (verbatim):**

> `ewcr-v1` (initiative) and `ewcr-v1-designer-fixture` (correlation) are already in DE FACTO
> use — in T-590's description and in the handoff envelope. Nothing records that the operator
> assigned them. In-use is not ratified: they were chosen by an agent and have been carried
> forward by repetition, which is how an unratified value acquires the appearance of a decision.

**Recorded recommendation (verbatim) — ⚠ SUPERSEDED, DO NOT RULE ON THIS ALONE:**

> Ratify the two values already in use rather than minting new ones. They are consistent across
> T-590 and the envelope, and changing them now would invalidate the envelope's correlation
> without buying anything.

**The supersession (verbatim, recorded 2026-08-29):**

> THE RECOMMENDATION ABOVE IS NOW INCOMPLETE, AND ITS OWN DIAGNOSIS IS WHY. It says "the two
> values already in use". There are now THREE. The live peer traffic with 999-AEF is transacting
> on `EWCR-ARC0-ATTEST-832` — agent-chat-arc offsets 602, 734, 737, 741, 742 — which is neither
> `ewcr-v1` nor `ewcr-v1-designer-fixture`. It is a rail THREAD NAME minted by an agent at
> offset 602 (T-610) and adopted by the counterparty because we used it, which is precisely the
> mechanism this entry already names: "carried forward by repetition, which is how an unratified
> value acquires the appearance of a decision". The entry described the disease and then the
> disease happened again, one layer out, while the entry sat open.

**Why it is not bookkeeping:** `source-manifest.yaml` defines Phase 4 completion as read-back on
the **same** correlation, and forbids opening a peer handoff until the correlations are assigned.
A handoff has been open since 2026-08-27 on an unassigned value — so **there is currently no
correlation against which Phase 4 read-back could be judged complete.**

**The ruling needed:** which of the three — or a fourth, operator-minted — is canonical. An agent
choosing would repeat the original defect a third time.

---

## H5 — Reconcile the four governance deviations in `reflection-designer.md` §9

**Why the operator:** *"The framework CLI was unavailable; task state needs operator
reconciliation."*

**Operative state (verbatim):**

> The four disclosed deviations (reflection-designer.md §9) stand unreconciled: Phase 0 steps 2–3
> never performed mechanically, T-587 created by hand-writing a conforming task file rather than
> via `fw task create`, focus.yaml deliberately left stale, and no commit made in that session.
> All four were disclosed rather than routed around, but disclosure is not reconciliation.

**Recorded recommendation (verbatim) — RATIFIABLE AS WRITTEN:**

> Reconcile by inspection rather than replay. The three artefacts are now committed and the CLI
> is available again; the cheap check is whether T-587's hand-written file matches what
> `fw task create` would have produced, which the audit already passes.

**Evidence already measured (2026-08-27), deviation 2 only:**

> T-587 carries EVERY `## ` section the inception template defines — the set difference
> template-minus-T-587 is empty. Its frontmatter is a strict SUPERSET of default.md: no template
> key is missing, and the two extra keys (target_blast_radius, voi_score) are exactly the
> inception-scoring fields the inception path adds. So the file hand-writing produced is
> indistinguishable in shape from the generated one.

**The residue, stated by the register itself:**

> This settles deviation 2 only. Deviations 1 (Phase 0 steps 2–3 never performed mechanically),
> 3 (focus.yaml deliberately left stale) and 4 (no commit in that session) are historical acts,
> not current file states, and cannot be settled by inspecting the tree — they can only be
> accepted or replayed by the operator. Not claiming H5 is answered; claiming one of its four
> parts now has evidence.

**The ruling needed:** accept deviations 1, 3 and 4 as disclosed-and-closed, or require replay.
One of the four is already evidenced.

---

## H6 — Route R6 and R7 to AEF

**Why the operator:** *"Cross-project asks with a named decision owner."*

**Operative state (verbatim) — note this entry has itself already been corrected once:**

> ROUTED 2026-08-27. Both asks were sent to 999-AEF on agent-chat-arc offset 643, thread
> EWCR-ARC0-ATTEST-832, under the §2.3 envelope, carrying the ask text verbatim from
> designer-contract-inventory.md:306-307 — R6: disposition of the DeepSeek and Mistral findings
> (the pinned dossier carries tables for Claude §17 and Z.ai §18 only); R7: reconciliation with
> ratified SD-1 (AEF T-2663), escalated rather than averaged because the inventory names the AEF
> agent as owner. R6 is the same object as exit clause 2: "every blocker finding has a contract
> disposition" cannot be satisfied by arithmetic while two of four model families have no
> disposition table at all.

The superseded prior text claimed *"Not routed… requiring separate operator authorisation, and no
such authorisation exists."* That gate was **invented by an agent and corrected by the operator** —
the same class of error that `arc-0-exit-clauses.yaml` records as having stalled Arc 0 for three
sessions.

**Recorded recommendation (verbatim) — RATIFIABLE, BUT IT DOES NOT CLOSE H6:**

> The transport half of H6 is done and needs no decision. What remains for the operator is
> narrower than the question as filed: rule that routing was correct and that the §2.3 boundary
> was held. Per §2.3 the post is transport evidence, NOT collaboration completion — so H6 does
> NOT become `resolved` on the strength of having sent it, and the agent has not set it so. It
> resolves when AEF answers and the operator accepts the answer as the source_of_truth clause 3
> requires.

**This is the exception named at the top.** H6 needs an AEF answer on R6/R7 before it can reach
`resolved`. The operator can rule today that *routing was correct and the boundary held*; that is
worth recording, but it does not satisfy clause 3 on its own.

**Also note:** R6 is *the same object* as exit clause 2. If AEF ever dispositions the DeepSeek and
Mistral findings, it moves H6 and clause 2 together.

---

## What this dossier does not do

- It does not rule on anything. Every verdict above is the operator's.
- It does not set `definition_ratified: true` on clause 3. That happens when T-596's Human AC is
  ticked, and an agent ratifying its own proposed definition is the move the register forbids
  everywhere else.
- It does not measure AEF's side, and does not treat AEF's clause-1 post as an attestation.
  Their post was a refusal to attest, and is recorded as one.

**Research is not authorization.**
