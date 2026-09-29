---
id: T-826
name: "Emit the diagram-kind marker: the resolving pointer AEF named as the missing
  piece"
description: >
  T-213 dispositioned aef:workflowMeta diagram-kind (documentation|work-plan) GO on
  2026-07-21. It was never built: grep -c diagramKind src/aef-workflow-designer.html
  returns 0. AEF independently named the same field at agent-chat-arc @1644 answering
  T-798 Q2, verbatim: 'Your designer distinguishing the two shapes (a diagram-kind
  marker - we already have an open corpus gap on exactly that, T-2556) is what would
  let a resolver pick the right join.' WHY IT MATTERS. AEF claimed the instance/execution-tracking
  layer as theirs at @1644 Q1 ('YES... Design nothing'), so the Designer builds no
  instance model. But their join CANNOT be picked without knowing the diagram's shape:
  for a LIFECYCLE design one run is one task passing through nodes as states and the
  instance record already exists (status transitions, Updates, episodic YAML) so instantiation
  is a JOIN; for a PIPELINE design the instance is the compiled task SET and a run
  id must be stamped at compile time. The marker is the discriminator. It is the single
  piece of the workflow-to-execution chain that is unambiguously on our side of the
  seam, and the only new arc-002 work an agent can do. SCOPE: emit the marker in the
  exporter, surface it in the properties panel, classify the corpus, and carry it
  through the round-trip. The frozen standard docs/standards/aef-bpmn-mapping-v1.md
  Part I must NOT be edited - if the marker needs a home the standard does not give
  it, that is a question for AEF, not an edit. Check T-213's disposition for the agreed
  value vocabulary before choosing one.

status: issues
workflow_type: build
current_node: frw_4_enter
owner: agent
horizon: now
tags: []
components: []
related_tasks: []
arc_id: ewcr-governed-delivery
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-09-22T19:18:37Z
last_update: 2026-09-29T08:09:08Z
date_finished:
# revisit_at: YYYY-MM-DD          # T-1451: set on DEFER decisions to enable G-053 daily revisit scan
# revisit_evidence_needed:        # T-1451: one-line description of what evidence makes the revisit actionable
# ── BVP scoring fields (T-1918, arc-006). See docs/reports/T-1915-bvp-inception.md for semantics. ──
# bvp_scores:                     # confirmed per-driver scores 0-5, set by `fw bvp confirm` (T-1924).
#                                 # Sovereignty boundary — only set after human or agent confirmation.
#                                 # Shape: {D1: <int 0-5>, D2: <int 0-5>, D3: <int 0-5>, D4: <int 0-5>, [<free-driver-id>: <int>]...}
# bvp_scores_proposed:            # estimator-proposed scores (T-1922 worker). Persists when ≥2 delta
#                                 # from bvp_scores: on any driver (M3 v2-delta). Shape: list of timestamped entries.
# cost_estimate:                  # F8 composite: 0.6×blast_radius + 0.3×tier + 0.1×effort.
#                                 # Q2 fallback: T-shirt S/M/L/XL mapped to 2/4/6/8 when blast_radius is not yet computable.
bvp_scores_proposed: []
cost_estimate_proposed:
  - ts: '2026-09-22T21:45:32Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 3
    rationale: blast_radius=3 
      (paths:docs/standards/aef-bpmn-mapping-v1.md,tools/_t820-rule-axes.sh); 
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
  - ts: '2026-09-29T07:46:14Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      blast_radius:
      tier: 2
      effort: 8
    rationale: blast_radius=? (no-components-UNMEASURED-not-zero); tier=2 
      (workflow:build); effort=8 (lines=176,acs=10)
    rubric_sha: e4a00f38e801
bvp_scores:
  D1: 4
  D2: 0
  D3: 2
  D4: 2
  F-RECALL: 0
  F2: 0
  F4: 0
  F3: 4
  F1: 3
confirmed_by: agent:auto (BVP_AUTO_CONFIRM)
confirmed_at: '2026-09-29T07:46:14Z'
---

# T-826: Emit the diagram-kind marker: the resolving pointer AEF named as the missing piece

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
<!-- T-826 ROUND-3 DISPOSITION. Five of these eight were DELIVERED UNDER OTHER TASK
     IDS between this task's capture (2026-09-22) and now: T-875 shipped the schema,
     both validator rules and the exporter; T-911 the panel/canvas surface; T-877 told
     AEF; T-886 the round-trip denominator. None of them names T-826, and this task's
     own staleness probe could never notice, because it greps for `diagramKind` while
     the field shipped as `kind` (still 0 occurrences of `diagramKind`, exactly as the
     description says — and the marker is fully built).
     ONLY the boxes closed by this task's own re-runnable legs are ticked. The rest
     carry what IS proven, what is not, and which task owns the remainder. -->

- [x] T-213's disposition is read FIRST and its agreed value vocabulary used verbatim — a second vocabulary for a field already dispositioned is the T-786 error, and this time AEF is waiting on the field
      **CLOSED.** `tools/validate-workflow.py:90` — `WORKFLOW_KINDS = {"documentation", "work-plan"}`,
      one module-scope copy read by BOTH forms (T-322), with T-213 IW-2 (closed enum) and
      IW-3 (absent is legal) quoted in the comment above it at `:70-74`. No second
      vocabulary was introduced. Legs 1/2/4 of the teeth exercise the enum from both
      sides: a bogus member is rejected on both forms, a legal member accepted on both.

- [ ] The marker is emitted by the exporter and survives a full round-trip: export → re-import → export is byte-identical, so authoring a kind does not make every later save carry noise
      **PROVEN IN PART, NOT TICKED.** Emission is delivered: `src/aef-workflow-designer.html:10782`
      pushes `kind` into `wmAttrs`, additive-only (absent when unset). Coverage is
      structural rather than declared: T-886 closed the `aef:workflowMeta` round-trip hole
      with a denominator DERIVED from the emitter (`deriveEmittedAttrs`, shared under
      T-910), so `kind` is inside it by construction with no list for anyone to forget —
      teeth leg 15 pins that coupling, with a control.
      **WHAT IS MISSING:** leg 15 is a coupling check and says so. The byte-identity itself
      is T-886's separately-verified property and the browser guard was NOT re-run this
      round. Closing this box wants one green run of
      `tools/_roundtrip-serialization-cdp.mjs` over a fixture that carries a kind.

- [ ] The marker is authorable — visible and settable in the properties panel, not a value only a file editor can reach. An unreachable authored value is F-11, which this session already had to fix once
      **DELIVERED BY T-911, NOT TICKED HERE.** `src/aef-workflow-designer.html:493, 2994,
      3177, 3190, 5972` — the canvas badge and the setter. T-911 is work-completed with its
      own verification. NOT ticked because this is a rendered-UI claim and CLAUDE.md
      §Visual Verification is unambiguous: a screenshot must be taken and READ before a
      visual AC is checked. I did not look at one. Citing another task's delivery is not
      the same as verifying it, and the whole point of that rule is that DOM-level evidence
      (a grep, here) is weaker than a rendered pixel.

- [ ] Every map in `examples/aef-processes/rendered/` carries a kind, and the classification of each is stated with its reason — lifecycle vs pipeline is the distinction AEF's resolver depends on, so a wrong classification is worse than an absent one
      **BLOCKED — and not by me.** This is T-876 verbatim (arc-005 S1/B2), and T-876 is held
      by a recorded PEER decision: `decisions.yaml:2549` **PD-343**, *"hold T-876 (backfill
      `kind` across 24 corpus maps) pending AEF's answer"*, filed 2026-09-28 under T-877.
      Measured now: `grep -l 'workflowMeta[^>]*kind=' examples/aef-processes/rendered/*.bpmn`
      returns **0 of 24**. Doing this here would be executing a held task under another id.

- [x] The validator rejects an unknown kind value, and that rule satisfies ALL FIVE axes via `tools/_t820-rule-axes.sh` — T-816 passed its own gate with three of five unsatisfied and only the full suite caught it
      **CLOSED, and the named instrument could not have closed it.** `tools/_t820-rule-axes.sh`
      reads no argument: proven by control that a real rule, a different real rule and a
      rule id that does not exist gave BYTE-IDENTICAL output. So it cannot say anything
      about *this* rule, in either direction. It now REFUSES an argument (rc=2) rather than
      implying otherwise (teeth leg 13); per-rule modes for the five suites are **T-927**.
      The five axes, rule-scoped, for BOTH kind rules:
      · **dialect** — already satisfied by T-903.
      · **form parity** — `E-WORKFLOW-KIND` classified PAIRED; 56 rules classified. Axis is
        red on `E-META-AUTHORITY` (T-902's), not on ours.
      · **pass reachability** — was red on both kind rules ("fire on NO corpus document and
        NO fixture"). Now witnessed by two PERSISTENT fixtures, which is what that axis
        demands: *"A control probe that mutates a throwaway copy does not satisfy this…the
        witness has to outlive the run that made it."* Unwitnessed set 6 → 4; the 4 left are
        T-889/T-890/T-894/T-902's.
      · **anchorability** — `E-XML-WORKFLOW-KIND` was unclassified. Now `DOC-META`, a new
        class, because the honest answer is not in the old five (see `## Decisions`).
      · **cross-form agreement** — `E-WORKFLOW-KIND` was PAIRED in the parity table but
        **absent from `PAIRS`**, so "the two forms agree on kind" was a claim no comparison
        had ever made. Now in `PAIRS`, compared, and its outcome declared.
      Every one of those four is verified RULE-SCOPED by `tools/_t826-kind-rule-axes-teeth.sh`
      (15/15, 0 fail), and each absence leg carries a presence control aimed at a rule that
      is still red — so a leg that stops measuring fails instead of passing.

- [ ] CONTROL: a map with no kind, and a map with a bogus kind, are each proven to fail the validator — and the guard is proven to pass on the corpus, or the failures prove nothing
      **TWO OF THREE CLAUSES PROVEN; THE THIRD IS REFUTED BY THE RATIFIED DESIGN, SO THIS BOX
      IS NOT MINE TO TICK OR TO REWRITE.**
      · *bogus kind fails* — PROVEN on BOTH forms, exactly one finding each
        (teeth legs 1–2, rc=2).
      · *the guard passes on the corpus* — PROVEN: 24 maps, **0 ERRORs**, 0 `WORKFLOW-KIND`
        findings. And since 0 of 24 carry a kind, the corpus simultaneously proves absence is
        inert on real documents.
      · *a map with NO kind fails* — **REFUTED.** T-213 IW-3, re-derived under T-875 at
        `tools/validate-workflow.py:72-75`: *"ABSENT IS LEGAL AND IS NOT A WARNING…the default
        is UNSET so the marker stays an explicit author decision and no map is silently
        reclassified by its own tooling."* Both rules implement it (`:339` guards on
        `"kind" in _wm`; `:1119` on `_kind is not None`), and T-876's own load-bearing AC says
        the same from the other side. Teeth leg 3 proves absence goes clean on both forms.
        This clause contradicts AC 1 of this very task, which requires T-213's disposition be
        used *verbatim*. It was written 2026-09-22, six days before the build settled it.
        **I did not edit it to something I could pass** — that is Sovereign question 1 in the
        round-3 handback.

- [x] `docs/standards/aef-bpmn-mapping-v1.md` Part I is NOT edited. If the marker has no home the frozen standard gives it, that is a question for AEF on the rail, not an edit
      **CLOSED.** `git log --since=2026-07-21 -- docs/standards/aef-bpmn-mapping-v1.md`
      returns nothing: the frozen standard has not been touched since the day T-213 GO'd.
      T-875 handled the homelessness the right way — it RE-DERIVED frozen-v1 safety
      (`aef:workflowMeta` appears 0 times in the standard, against a 1–8 control for the
      attributes it does classify; §1's partition is NODE-level and §6's clauses do not reach
      document metadata) and recorded the missing document-level class as a gap to report to
      AEF via T-877, not as licence.

- [ ] AEF is told the field exists, with its vocabulary and an example document — they named it as the missing piece at @1644 and cited their own open gap T-2556; shipping it silently would leave the join unbuilt on their side
      **OWNED BY T-877, NOT TICKED.** T-877 is *"Tell AEF the kind marker exists and what
      their promote path can now read"*, work-completed 2026-09-28, and PD-343 (their pending
      answer) is evidence the rail conversation happened. NOT ticked because a rail post is
      an outbound act to a peer and I have not read the rail this round; asserting someone
      was told, on inference, is the kind of claim that is worst to get wrong.

### Human
<!-- Criteria requiring human verification (UI/UX, subjective quality). Not blocking.
     Remove this section if all criteria are agent-verifiable.
     Each criterion MUST include Steps/Expected/If-not so the human can act without guessing.

     ── Prefix routing (T-1811, T-1878): default to [REVIEWER] if Expected is grep-able ──
     If your Expected clause is grep-able / file-exists / structural (a deterministic
     shell check), prefer [REVIEWER] — that AC should be an Agent AC with the reviewer
     command in `## Verification` instead of a Human AC here. Only keep [REVIEW] if
     verification genuinely needs human taste (tone, feel, layout rhythm).
     See CLAUDE.md §AC Classification Guidance for the conversion rule.

     [REVIEW] example (genuine human judgment):
       - [ ] [REVIEW] Dashboard renders correctly
         **Steps:**
         1. Open https://example.com/dashboard in browser
         2. Verify all panels load within 2 seconds
         3. Check browser console for errors
         **Expected:** All panels visible, no console errors
         **If not:** Screenshot the broken panel and note the console error

     [REVIEWER] example (static-scan-verifiable — convert to Agent AC + Verification):
       - [ ] [REVIEWER] Block message names both bypass mechanisms
         **Steps:**
         1. Run `bin/fw reviewer T-826`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-826 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
-->

## Verification

# Shell commands that MUST pass before work-completed. One per line.
# Lines starting with # are comments (skipped). Empty lines ignored.
# The completion gate runs each command — if any exits non-zero, completion is blocked.
#
# Toolchain hint (L-291): if you edited *.vbproj/*.csproj/*.xaml add `dotnet build`;
# *.go → `go build ./...`; Cargo.toml → `cargo check`; tsconfig.json → `tsc --noEmit`;
# pom.xml → `mvn -q compile`. P-011 runs only what you write — broken builds slip
# past otherwise (origin: 003-NTB-ATC-Plugin T-077, broken WPF DLL on master 5 days).
#
# ⚠ ERREXIT WARNING (T-352) — READ BEFORE USING THE CAPTURE PATTERN BELOW.
# P-011 runs each command under `-o pipefail` but NOT under an effective `-e`.
# Measured, not assumed (tools/_t352-p011-errexit-probe.sh): the gate runs each line as
# `if ( … eval "$cmd" ); then` (update-task.sh:1018) and that subshell is the CONDITION
# of an `if`, which neutralises errexit inside it. pipefail survives; errexit does not.
# CONSEQUENCE: a line of the form `a; b` IS JUDGED ON `b` ALONE. `a`'s exit code is
# discarded, so a command that fails outright can still leave the line green.
#   Proven false green:
#     out=$(python3 tools/validate-workflow.py BROKEN.bpmn 2>&1); echo "$out" | grep -q "VALID"
#   -> PASSES on a document the validator exits 2 on and labels INVALID, because
#      `grep -q "VALID"` matches INVALID as a SUBSTRING. Two defects stacked.
# PREFER a single command whose own exit code is the verdict — then no context question
# arises. When you must chain, the LAST command has to be the one that can fail, and its
# pattern must not be matchable by the earlier command's FAILURE output.
# Note `set -e` re-issued inside the subshell does NOT fix this: the suppressed context is
# inherited and re-setting the option does not clear it. See T-352 for the remedy.
#
# Pipefail/SIGPIPE hint (L-387): `cmd | grep -q PATTERN` exits 141 (SIGPIPE) when grep
# matches and closes stdin while the upstream is still writing — verification then
# "fails" even though the pattern was present. The capture pattern below fixes THAT,
# and creates the errexit exposure described above; the file form fixes both:
#     cmd > /tmp/.out 2>&1 && grep -q "PATTERN" /tmp/.out     # PREFERRED: && not ;
#     out=$(cmd 2>&1); echo "$out" | grep -q "PATTERN"        # SIGPIPE-safe, errexit-blind
# Origin: L-387, captured 4× (T-1716, T-1838, T-1862, T-1863) before this hint.
#
# Single pipe only — no intermediate tail/awk/sed stages between capture and grep
# (T-2090): `echo "$out" | tail -3 | grep -q PAT` re-introduces the SIGPIPE risk
# the capture step closed off — the middle stage is what `grep -q` slams its
# stdin on. `echo "$out"` is small and immediate; grep scans the whole captured
# string anyway, so the tail-3 was cosmetic. Drop it: `echo "$out" | grep -q PAT`.
#
# Enforcement-baseline hint (L-398, T-1886): if you edited `.claude/settings.json`
# (added/removed/reorganised hooks), add `bin/fw enforcement baseline` to your
# Verification block. Otherwise the canonical hash diverges and `fw doctor`
# reports a FAIL ("Enforcement baseline CHANGED") that accumulates silently.
# Origin: T-1849/T-1730/T-1731 each added a legitimate hook without refreshing
# the baseline — FAIL sat for multiple sessions until T-1886 cleaned up.


# T-826 round 3. Rule-scoped by necessity: tools/_t820-rule-axes.sh is whole-suite
# and 4 of its 5 axes are red on FIVE rules belonging to T-889/T-890/T-894/T-902/
# T-909 (OBS-440). A gate that demanded those axes go green would demand this task
# fix five other tasks' rules, which is how T-816's corner got cut.
#
# 1. The two kind rules against all five axes, rule-scoped, every absence leg paired
#    with a presence control aimed at a rule that is still red.
bash tools/_t826-kind-rule-axes-teeth.sh
#
# 2. The whole-suite runner refuses a rule argument instead of handing back a verdict
#    about other people's rules (exit 2 is the PASS here).
bash tools/_t820-rule-axes.sh E-WORKFLOW-KIND; test $? -eq 2
#
# 3. ...and still runs with no argument. Its exit is 1 today (the foreign red), so this
#    asserts it is NOT the refusal code — a green suite would also satisfy it.
bash tools/_t820-rule-axes.sh >/dev/null 2>&1; test $? -ne 2
#
# 4. The corpus: 0 ERRORs over all 24 rendered maps, and 0 of them carry a kind — so
#    the same command proves the guard passes AND that absence is inert on real
#    documents. Pinned as an invariant (0), not as a live count (OBS-377).
python3 -c "import subprocess,glob,sys; f=sorted(glob.glob('examples/aef-processes/rendered/*.bpmn')); assert len(f)==24, 'corpus is %d maps, not 24' % len(f); n=sum(subprocess.run(['python3','tools/validate-workflow.py',x],capture_output=True,text=True).stdout.count('ERROR ') for x in f); print('corpus ERRORs:', n); sys.exit(0 if n==0 else 1)"
#
# 5. The frozen standard is untouched since T-213's GO date.
test -z "$(git log --since=2026-07-21 --oneline -- docs/standards/aef-bpmn-mapping-v1.md)"
#
# 6. Both fixtures still exist AND are still the sole witnesses their axis needs. A
#    deleted fixture would make leg 5 of the teeth fail, but naming them here means
#    the gate says WHICH file went missing.
test -f tests/fixtures/invalid/E-WORKFLOW-KIND.yaml
test -f tests/fixtures/invalid/E-XML-WORKFLOW-KIND.bpmn
#
# 7. T-820's own controls still pass — the argument refusal must not have broken the
#    runner's ability to detect a broken axis (7 legs, including exit 3 on a missing file).
bash tools/_t820-axes-controls.sh 2>&1 | grep -q "PASS=7 FAIL=0"

## RCA

<!-- REQUIRED for bug-class tasks (workflow_type=build with bug-tag, OR title matches
     fix/bug/rca/broken/crash/error/regression/fail/hotfix).
     Non-bug-class tasks may leave this section empty or remove it.

     For bug-class, fill in:
       **Symptom:** what was observed (the user-facing manifestation).
       **Root cause:** the specific structural/logical gap — not "the code was wrong".
       **Why structurally allowed:** what in the framework/code/tooling let this go undetected.
       **Prevention:** what catches the next instance (test/lint/gate/doc/learning) — distinct from the fix itself.

     The completion gate (T-1550, G-019) blocks --status work-completed when
     bug-class AND this section is empty/template-only. Use --skip-rca to bypass (logged).
-->

## Evolution

<!-- REQUIRED for arc-tagged build tasks (tags include arc:*). Captures how
     understanding evolved during build — what was learned that wasn't known at
     filing, what in the original plan no longer fits, what triggered pivots
     or new sub-tasks. Mandatory at slice boundaries (when applicable) and
     before --status work-completed.

     Origin: T-1717 grill Q4 — "the understanding of what we need and want
     evolves with the process of materialisation." Structural counter to §ACD:
     spec-vs-build divergence is logged as soon as it happens, not lost as
     folklore.

     Format (one entry per slice boundary or significant insight):
       ### YYYY-MM-DD — [topic]
       - **What changed:** [what we learned that we didn't know at filing]
       - **Plan impact:** [what in the plan no longer fits]
       - **Triggered:** [new sub-task / pivot / scope cut, with task ID if filed]

     The completion gate (T-1718) blocks --status work-completed when this
     section exists but is empty/template-only. Use --skip-evolution to bypass
     (logged Tier-2). Non-arc tasks may leave this empty.
-->

## Decisions

<!-- Record decisions ONLY when choosing between alternatives.
     Skip for tasks with no meaningful choices.
     Format:
     ### [date] — [topic]
     - **Chose:** [what was decided]
     - **Why:** [rationale]
     - **Rejected:** [alternatives and why not]
-->


### PD (T-826, round 3) — `DOC-META`: a new anchor class rather than the green that was available

`E-XML-WORKFLOW-KIND` reached `tests/test_finding_anchorability.py` unclassified. Its
location string is `<aef:workflowMeta id='t'>`, and **measured** (not assumed) it resolves
to `node` — so declaring it `NODE` would have PASSED the axis on the first try.

It would also have been a lie. `aef:workflowMeta` is document-level metadata; the canvas
draws nothing at that position. It resolves to `node` only because `_index()`'s else-branch
turns *every* id-bearing element into a flow node (`:214`), and `aef:workflowMeta` carries an
id in all 24 rendered maps. Taking the green would have added a false gutter-able row to the
ERROR-side anchorability figure in `docs/reports/T-309-validator-surfacing.md` — a number
someone may act on, which is the exact thing that file's docstring says it exists to stop.

**Alternatives considered.**
- *Declare `NODE`* — passes, wrong, silently. Rejected.
- *Declare `DOC`* — honest in substance but fails `ACCEPTS`, because an id IS interpolated.
  (Used as teeth leg 12's control precisely because it fails.)
- *Declare `REFERENT`* — passes `ACCEPTS` (observed `{"UNRESOLVED"}` before the fixture
  existed) but means "the id the rule asserts does not resolve", which this rule never
  asserts. Rejected as a green for the wrong reason.
- *Fix `_index()` to treat the aef namespace as `document`* — the correct repair, and
  **tried in a throwaway probe**: it moved a SECOND rule, `E-XML-ID-DUP`, from `VALUE` to
  observing `['document','node']`, because a duplicated id can be carried by an extension
  element too. That is a real classification question, not a typo. Rejected **here** under
  the one-lock-at-a-time rule and filed as **T-926**.
- *Chosen:* a new `DOC-META` class, explicitly absent from `GUTTERABLE` (where the
  substantive claim lives), with `ACCEPTS` pinned `== {"node"}` rather than `<=`. The tight
  pin is deliberate: when T-926 repairs `_index`, this leg FAILS and forces the class to be
  re-read instead of letting the repair slide past.

### PD (T-826, round 3) — the bridge ERASES `workflowMeta`, so the pair is declared, not absorbed

`tests/test_harness_cross_form_agreement.py` compares the two validator forms by driving
YAML fixtures through `tools/yaml-to-bpmn.py`. **Measured:** a document with
`kind: overlord` fires `E-WORKFLOW-KIND` on the YAML form; the bridged output contains
**0** occurrences of `workflowMeta`; the XML form is silent. The bridge emits no
`<aef:workflowMeta>` at all — it reads the key only to derive `wid`/`process_id` (`:141`).

The harness offers two outcomes for that shape and neither is true. `KNOWN_DISAGREEMENTS`
demands a CARRIES-probe over bridged bytes that carry nothing. `BRIDGE_REPAIRED` calls it a
repair, and the harness's own docstring says *"Inferring it is how a real hole gets absorbed
as a repair."* Data loss is not a repair.

**Decision:** declare it under `BRIDGE_REPAIRED` — the only class whose operational test it
meets — but name the mechanism **ERASURE** in the entry, state in the entry that the class
name is wrong for it, cite **T-925**, and extend the class's own prose with a third kind
alongside RECOVERY and DEFAULT. The harness's staleness check then works FOR us: if T-925
makes the bridge emit `workflowMeta`, the XML form starts firing, the declaration goes stale
and the run FAILS, forcing a re-read. Teeth leg 14 pins the same fact from the other side.

### PD (T-826, round 3) — refuse the argument rather than implement the filter

`tools/_t820-rule-axes.sh` invites `<rule-id>` by its own docstring and has never read one.
Rather than leave a silent false-attribution hazard or build five per-rule modes inside this
task, the runner now **refuses** a positional argument with `exit 2` and a message naming the
argument it was given and pointing at the rule-scoped pattern. Zero blast radius: measured,
no `## Verification` block in the tree passes it an argument, and `_t820-axes-controls.sh`
still reports 7/0. The want it does not satisfy is filed as **T-927**.

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-826 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-22T19:18:37Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-826-emit-the-diagram-kind-marker-the-resolvi.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-0e2c8950
- **Timestamp:** 2026-09-22T19:30:18Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-09-29T07:46:19Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

### 2026-09-29T08:09:08Z — status-update [task-update-agent]
- **Change:** status: started-work → issues
- **Reason:** Round 3 closed ACs 1, 5 and 7 with re-runnable evidence (teeth 15/15, fw task verify 8/8, commit c0584cc5). CANNOT COMPLETE, two reasons, neither mine to decide: (a) AC4 is T-876 verbatim and T-876 is held by PD-343, decisions.yaml:2549, pending AEF's answer; (b) AC6's first clause demands a map with NO kind fail the validator, which T-213 IW-3 as re-derived under T-875 forbids, and AC1 of this same task requires that disposition be used verbatim. AC6 was NOT rewritten to something passable. ACs 2, 3 and 8 were delivered by T-886, T-911 and T-877 and are annotated with what is proven and what would close them. Findings filed as T-925, T-926, T-927, OBS-440, OBS-441.
