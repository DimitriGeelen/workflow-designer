# Workflow Designer 0.15.3 — release notes

**Since:** `designer-v0.15.2` (2026-10-02) · **The authoring kit, revised from the second trial
round, and validated a new way.** Evergreen's iteration 2 (T-989) reported nine more places where
the kit left it guessing (K9-K17). Every resulting lesson went through the learning ledger, and
this time none was confirmed by asking the operator to vouch for it (T-1006). A lesson became a
rule only when its evidence re-ran green against the shipped kit AND reviewers from three vendors
other than the author's (OpenAI codex, Z.AI GLM, Google Antigravity) agreed, each of which had
first rejected two planted-false lessons. 10 of 12 lessons passed; 2 stay open (L19, L21) with
one reviewer's dissent recorded.

The panel also corrected the previous release: a sentence 0.15.2 shipped ("a parallel fork (and
its join) says the same as the plain flows") is half wrong, and is fixed here (L26).

## Validator

- **A link catch draws no dead-end of its own** (K11, L20). A catch placed before a step whose
  successor is unrecorded drew `W-(XML-)DEADEND` on the step AND on the catch: one unknown, counted
  twice, while the guide says a catch draws no reachability warning. The step still reports it.
  A catch reached by flow (a mid-flow wait) is still assessed.

## Guide (AUTHORING.md) and rubric (v5)

- **Fork is not join** (L26). A parallel fork means what plain outgoing flows mean; a parallel
  join waits for every branch and plain converging flows do not. Draw a join only where the source
  says the next step waits for all; where it is ambiguous, keep the construct and flag it.
- **K16 — hand-overs to two processes** (L24): the K2 rule applies; the note records the source's
  silence, it does not change what the flows mean.
- **K14 — "is detailed in process X"** (L22): a task with a cited `Detailed in: X` note; a
  `callActivity` only where the source says the step invokes X.
- **K15 — two steps with the same display name** (L23): keep both names verbatim, distinct keys,
  a qualifier note only where the source gives one.
- **K17 — a citation of several source lines** (L25): one `source:` line per quote.
- **Default flow** (K10, L18): a branch the source clearly implies as "otherwise" is the gateway's
  unlabelled default, not a label the source never used.

## Conformance checklist

- **Conventions beyond BPMN 2.0.2** (L27): cross-map hand-overs drawn as link events are an AEF
  convention (BPMN link events stay inside one process); the checklist now says so and names the
  standard alternative (message flows in a collaboration).

## Loop and calibration

- **Prompt placement** (K9, L17): `loop.sh`'s header states that the prompt is the command's last
  argument, and that claude's `--allowedTools` swallows it if it ends the command.
- **Calibration maps** (K10, L18; L26): the not-exceeded branch is the gateway's default in both
  maps. **The fork and join after shipment are gone:** the source never says completion waits for
  both delivery and invoicing, and once the fork/join correction was in the rubric, both calibrated
  reviewers rightly flagged the join on the CLEAN map — the first 0.15.3 calibration failed on it.
  Delivery and invoicing now follow collection directly and converge on the end event. The planted
  map also lost a note that contradicted its own planted wiring (GLM flagged it; T-991 rule:
  planting artefacts go, the scoring is not widened).
- **A new kit is released only with a calibration of its own bytes** (L16):
  `scripts/release-designer.sh` refuses a new kit version unless
  `docs/authoring-kit/calibration-records/<version>.yaml` records a PASS calibration whose kit
  hash matches the kit the tree builds now. 0.15.3's record: see that file.

## Open (not in this release)

- **L19** — reachability per connected component (K12, the 29 -> 80 warnings): two vendors agree,
  codex still refines the algorithm; it will be built behind tests rather than settled in prose.
- **L21** — the clean map's end event name vs its `source: unstated` citation (K13): a real 2-1
  split on whether an outcome conveyed only by the last activities is "stated". The control map is
  unchanged until it is settled.
