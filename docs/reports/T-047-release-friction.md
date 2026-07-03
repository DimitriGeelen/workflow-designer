# T-047 — Friction-dry analysis: release-pipeline (fw release)

**Subject:** `examples/aef-processes/release-pipeline.workflow.yaml`
**Ground truth:** `.agentic-framework/lib/release.sh` (`release_tag_and_release`, L.69-146)
**Method:** friction-dry — map a real AEF process with the Workflow Designer schema and
record where the schema strained, where known frictions recurred, and where they sharpened.
Dogfood mapping #14 — the largest map to date (17 nodes, 17 edges).

## Verdict

**Schema expressivity: all constructs available, 0 blocking gaps — but the richest friction
yield yet.** The release flow mapped faithfully: 4 exclusive gateways, 3 success terminals,
1 error terminal, a cross-host push, a best-effort external call, and — the headline — a
**loop over a runtime collection** (push the tag to every git remote). One new headline
candidate (FC-5), one new terminal-semantics candidate (FC-6), and a sharpening of the
soft-fail idea (FC-1) into two distinct flavors.

## Recurrences (frictions seen before, seen again)

- **F3 (determinism).** Every node `deterministic`. NO human, NO stochastic — third
  consecutive autonomous-automation map (after cross-host-dispatch). Reinforces a workflow
  *taxonomy*: the framework's cron-class flows (release, dispatch, revisit-scan) are
  human-free, in contrast to inception/promotion which centre a human sovereignty gate.
- **F7 (side-effect annotation).** Four side effects: create local tag, push to each remote
  (cross-host), GitHub Release. All free-text `aef.sideEffect`. Recurs.
- **FC-3 (participant flattened to a lane, from T-046).** Recurs and strengthens: this map
  has TWO external participants (git remotes; GitHub) in a single `external` lane. Confirms
  the T-046 recommendation to document `authority: external` ⇒ separate participant.

## New candidate frictions

### FC-5 — multi-instance / loop activity  ⭐ headline
`release_tag_and_release` pushes the new tag to **every** remote in a `while read remote`
loop (L.116-127). The set of remotes is unknown at author time — it is a **runtime
collection**. BPMN expresses this with a *multi-instance* activity (the ‖ / ≡ marker: "run
this activity once per item in a collection"). The schema has **no multi-instance marker**
and no loop construct. The workflow therefore cannot *unroll* the loop (N unknown) nor mark
"this one node runs N times."

**Mitigation used:** a single `n_push` scriptTask carrying `aef.multiInstance: true` +
`aef.collection: git remotes (runtime set)`. It draws and validates, but the *marker* is
free-text in the passthrough bag, not a first-class visual (no ‖ glyph on the node). A reader
of the diagram cannot see that this step iterates.

**Recommendation:** a first-class `multiInstance` node property with a rendered marker is the
cleanest fix, and it recurs elsewhere (any "for each X" step — batch review emission, harvest
over sessions). Worth a schema-enhancement inception if a second loop map confirms demand.
This is the first corpus instance; register the candidate, do not build yet (PD-002).

### FC-6 — data-dependent terminal exit code
`n_done` is a single success terminal, but its exit status is `return $failed` (L.145): **0**
if every remote push succeeded, **1** if any push WARNed. One end node, variable exit code
computed from an accumulator. The schema's `endEvent` has no way to express "this terminal's
status depends on runtime state." Carried as a note in `aef.terminalKind: success` + the label
"(exit = failed)". Semantic, not a construct gap — but distinguishes a *fixed* terminal
(dry-run always 0, no-tag always 1) from a *computed* one. Note; don't fix.

## Sharpenings

### FC-1 (soft gate, from promotion T-045) → TWO soft-fail flavors
Promotion's FC-1 was a single "advisory gate" (warn, rejoin happy path). Release shows the
distinction has two sides:
- **Advisory (pure):** `n_gh` — a failed GitHub Release WARNs and **never** changes the exit
  code (L.136-140, "non-fatal"). Marked `aef.softFail: advisory`.
- **Accumulating soft-fail:** the per-remote push — a failed push WARNs, the loop **continues**
  to the next remote, but sets `failed=1`, which **does** surface in the final exit code
  (L.121-126 + L.145). Marked `aef.softFail: accumulating`.

Same visual (a step that doesn't abort on failure) but opposite consequence for the terminal.
A future first-class "soft gate / advisory activity" concept should carry this axis:
*does the soft failure affect the outcome, or only the log?*

## Terminal taxonomy note
Four terminals, three kinds of meaning: error (no-tag → exit 1), fixed-success (no-op,
dry-run → exit 0), computed-success (released → exit `$failed`). The schema draws all four as
identical `endEvent` glyphs; the distinction lives only in `aef.terminalKind` free text. A
rendered success/error terminal distinction (green vs red ring, already partly present in the
editor's endEvent styling) plus a `terminalKind` field would make intent visible. Candidate,
low priority.

## Product finding (feeds T-043)
No clipping this time — labels were kept short deliberately after the T-046 fit-to-view
finding. bbox `x=28 … right=1816` inside viewBox `[0,1846]`. Confirms the T-046 mitigation
(short node names) is a reliable authoring workaround until fit-to-view measures text extent.

## Outcome
Release pipeline mapped, validated, geometry-clean, round-trips (bridge suite 15/15), renders
faithfully **and legibly** (Playwright-verified — loop node dips correctly into the `external`
lane, both external participants and all four terminals visible). Second `external`-lane
member. No schema changes (consistent with PD-002). Registered: FC-5 (multi-instance loop —
headline, first instance), FC-6 (data-dependent terminal), FC-1 sharpening (advisory vs
accumulating soft-fail), and a terminal-taxonomy note.
