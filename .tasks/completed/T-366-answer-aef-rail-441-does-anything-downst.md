---
id: T-366
name: "Answer AEF RAIL-441: does anything downstream of us validate aef:uid SHAPE"
description: >
  Answer AEF RAIL-441: does anything downstream of us validate aef:uid SHAPE

status: work-completed
workflow_type: test
owner: agent
horizon:
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-04T14:29:17Z
last_update: '2026-08-16T12:33:53Z'
date_finished: 2026-08-04T14:42:40Z
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
bvp_scores_proposed:
  - ts: '2026-08-16T12:33:53Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 3
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=3 
      (body:fw-recall-or-memory-link); F-AUTONOMY=0 (no-signal); F3=0 
      (no-signal); F1=0 (no-signal); F2=0 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-366: Answer AEF RAIL-441: does anything downstream of us validate aef:uid SHAPE

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Acceptance Criteria

### Agent
- [x] **Every 832-owned site that READS an `aef:uid` value is enumerated, with the
      denominator stated, and each classified `constrains-shape` / `reads-only`.**
      The enumeration must NOT be a regex guessing the shape it is hunting — that is
      the exact instrument failure AEF reported at RAIL-441 (they matched `aef:uid=`,
      got 0 of 1081, because their uid is element syntax not an attribute, and were one
      keystroke from publishing "our corpus carries no uid"). Enumerate the *reads*,
      then inspect them; a shape constraint can be spelled `startsWith`, `length`,
      `slice(2)`, a schema `pattern`, or a prefix test, and a `^n_[0-9a-f]{8}$` grep
      sees none of those.

      **Denominator: 193 files** under `src/ tools/ tests/ examples/ docs/` (`.py .mjs
      .js .html .sh .md`, excluding `_t3*` scratch probes). **82 contain the string
      `uid`; 40 are code; 34 mention `uid` as a token distinct from `uuid`.**

      That last narrowing is the one that mattered. The first scan matched `uid` and
      swept in `workflowMeta uuid` — `bpmn-cli.py:72 _UUID_ATTR_RE`,
      `gallery-serve.py:163 _WORKFLOWMETA_UUID_RE`, the whole ghost/claim machinery.
      Those ARE shape-constrained (`len(g['uuid']) == 36`,
      `_gallery-registry-verify.py:182`) and they constrain a **different field**.
      Reporting them would have answered yes to a question about `uid` using evidence
      about `uuid`.

      **Shape operations found across the 34: zero.** Scanned for `startswith` /
      `.slice` / `substr` / `len(` / `.length` comparison / `re.match|search|compile|
      fullmatch` / `[0-9a-f]` / `^n_` / `^e_` / `.test(` / `pattern`, on lines carrying
      a `uid` token with `uuid` excluded.

      **What DOES constrain uid** (`tools/validate-workflow.py`): presence —
      `REQUIRED_NODE_FIELDS`/`REQUIRED_EDGE_FIELDS` include `"uid"` (:112, :114) — and
      uniqueness — `_check_uid_uniqueness` → `E-UID-DUP` (:409-421). Both are
      shape-agnostic: they care that a uid exists and is distinct, never what it looks
      like.

      **Corpus evidence, unasked for and stronger than the scan.** Of **511 distinct
      `aef:uid` values** across `tests/fixtures/` and `examples/`, only **76** are
      `[ne]_[0-9a-f]{8}` and **378** are semantic slugs (`e_trigger_fork`,
      `g_ac`, `ac_done_clean`). We do not merely tolerate AEF's shape — our own corpus
      is mostly not the mint shape. And `tl_work` reaches us from
      `tests/fixtures/aef-overlay/live-payload-2026-07-27.json`, an **AEF live
      payload**: their slugs are already in our test path and already green.

- [x] **The hazard is tested behaviourally, not just read.** A document carrying AEF's
      uid form (semantic slugs — `ac_cron_fire`, `tl_work`, per RAIL-441) must survive
      open→save with the value preserved and no other byte disturbed. Reading code for
      the absence of a constraint answers "did I find one"; only running it answers
      "is there one".

      `tools/_t366-uid-shape-agnostic.mjs` — one document, 9 uid values, four shape
      families, open→save through the real import/export path:

      ```
        uid value           shape       in memory   in bytes    verdict
        ac_cron_fire        aef-slug    kept        kept        PRESERVED
        tl_work             aef-slug    kept        kept        PRESERVED
        ac_done_triaged     aef-slug    kept        kept        PRESERVED
        n_1a2b3c4d          mint        kept        kept        PRESERVED
        T-2584              exotic      kept        kept        PRESERVED
        e_trigger_fork      aef-slug    kept        kept        PRESERVED
        e_0001              exotic      kept        kept        PRESERVED
        e_deadbeef          mint        kept        kept        PRESERVED
        e_last_flow         aef-slug    kept        kept        PRESERVED
      ```

      Checked in **both** places a rewrite could hide: the in-memory model (`n.uid`
      after parse) and the emitted bytes. A validator that coerced on import and one
      that coerced on export would look identical if only the bytes were compared.

- [x] **The probe has a negative control: it must be shown to FAIL when a shape
      constraint exists.** Inject a constraint (temp copy, never the real source) that
      rejects or rewrites a non-`n_8hex` uid, and require the probe to catch it.
      Without this, a green means "no constraint" and "the probe cannot see
      constraints" identically — see [[checks-that-discriminate-nothing]].

      `tools/_t366-uid-shape-teeth.py` injects the hazard in its most plausible form —
      not a crash, not a rejection, but a **silent rewrite** of any uid failing
      `^n_[0-9a-f]{8}$`. Nobody writes a validator that throws on a peer's identity
      key; they write one that "normalises" it.

      ```
      control : rc=0  NONE=True   FOUND=False
      teeth   : rc=1  NONE=False  FOUND=True
      ```

      **Two assertions, and the second is the one worth having.** The probe must go
      red, AND it must report the result as shape-**SELECTIVE** — the mint-shaped
      control surviving while the slugs are rewritten. A probe that reddens for any
      reason cannot separate "a shape validator exists" from "uids are broken
      generally", and those two findings send the reader to different code and the peer
      a different message. The teeth assert the split is named.

- [x] **The frozen standard is checked for a uid format clause.**
      `docs/standards/aef-bpmn-mapping-v1.md` is the seam contract and must NOT be
      edited under agent control. If it mandates a uid shape, that is a downstream
      constraint binding on BOTH sides and the answer to AEF changes from "no" to "yes,
      and it is in the document we both signed".

      **No format clause exists, and the standard goes further than "no" — it
      forbids one.** §5 (frozen, Part I):

      > `aef:uid` is **externally assignable** — the reference editor's import path
      > honors arbitrary `aef:uid` values, so a reverse renderer needs no editor
      > change for identity.

      A shape validator would put us out of conformance with a document we both
      signed, not merely inconvenience AEF. And §5's reverse rule — *"each rendered
      element MUST set `aef:uid = <task-id>`"* — means **their semantic slugs are the
      prescribed form and our `n_8hex` is the accident**. `ac_cron_fire` is closer to
      what the contract asks for than `n_49d94bba` is.

      **A tension worth naming, which cuts against their own recommendation.** §5 also
      says *"Every node and edge MUST carry a stable `aef:uid`"*, and §6.3 makes it a
      **conformance requirement**: an implementation is v1-conformant iff *"it carries
      a stable, externally-assignable `aef:uid` on every node and edge"*. AEF's
      RAIL-441 proposal — derive in memory, persist only on authorship — produces
      emitted documents with no `aef:uid`, which reads as non-conformant under §6.3.
      Escape hatch: the standard's stated subject is *"a BPMN process diagram (with an
      `aef:` extension layer)"*, so a foreign document arguably never enters scope.
      That reading needs AEF to confirm it, and it is **their** call — the document is
      frozen and must not be edited under agent control.

- [x] **The answer is posted to AEF stating method and denominator**, not just the
      verdict. A bare "no, nothing validates shape" is the shape of claim this whole
      thread is about.

      Posted at RAIL-442.

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
         1. Run `bin/fw reviewer T-XXX`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-XXX 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
-->

## Verification

# Shell commands that MUST pass before work-completed. One per line.

# every uid shape survives open->save, in memory AND in the emitted bytes.
# NOT redirected to /dev/null: the gate prints `head -5` of a failed command's output,
# and `> /dev/null 2>&1` throws away exactly that diagnostic. This line failed once with
# a bare "exit 2" and no reason, because I had suppressed the reason myself.
node tools/_t366-uid-shape-agnostic.mjs
# and that probe can SEE an injected shape validator, and names it shape-SELECTIVE
python3 tools/_t366-uid-shape-teeth.py
# the frozen standard still forbids shape validation (this is what makes the answer binding,
# not merely true today) — externally-assignable clause, Part I frozen, must not be edited
out=$(grep -c "externally assignable" docs/standards/aef-bpmn-mapping-v1.md); [ "$out" = "1" ]
# the validator constrains uid presence + uniqueness and nothing about its shape
out=$(grep -c "E-UID-DUP" tools/validate-workflow.py); [ "$out" -ge "1" ]
# no leg lost (the probe synthesises BPMN, so T-327 harness fidelity is in scope)
bash tests/run-bridge-tests.sh > /tmp/.t366-bridge.out 2>&1 && grep -q "bridge round-trip: .* 0 failed" /tmp/.t366-bridge.out

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

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-08-04T14:29:17Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-366-answer-aef-rail-441-does-anything-downst.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-4ee03f06
- **Timestamp:** 2026-08-04T14:44:15Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-04T14:42:40Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
