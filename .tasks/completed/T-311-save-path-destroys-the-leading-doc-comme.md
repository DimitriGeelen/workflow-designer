---
id: T-311
name: "Save path destroys the leading doc comment: agent-authored rationale block
  lost on first UI save"
description: >
  AEF field report (rail 332), confirmed against our source. The leading XML comment
  child of <bpmn:definitions> - which their corpus_spec treats as SEMANTIC and carries
  into the promoted spec - is dropped on the first UI save and every save after inherits
  the loss. Two independent confirmations their side: draft-knowledge-leveling v5
  -> v6/v7, and draft-trigger-handling v1 -> v2..v6. Verified our side: src/aef-workflow-designer.html
  has no COMMENT_NODE handling anywhere in the parse path, and buildBpmnXml unconditionally
  emits one hardcoded comment at :9363 ('BPMN DI (visual layout) omitted in this demo;
  AEF generates it from node coordinates'). So the doc comment is dropped at parse
  and never re-emitted; the only comment on output is our own boilerplate. Nothing
  else is harmed - AEF reports uid set, flow topology, names and aef:meta notes all
  round-trip byte-faithfully. Compounding effect their side (already owned there):
  their parse_map takes the FIRST comment child as 'doc' with no guard, so it silently
  adopts our boilerplate as the rationale - the field never reads empty, it reads
  plausible-and-wrong; 5 of their 11 maps carry our boilerplate as their doc and 2
  are PROMOTED corpus maps. Open decision AEF raised: preserve comment children through
  the round-trip, or carry the doc as an aef: extension attr on workflowMeta instead
  - the latter survives any DOM round-trip but is a schema question to settle before
  more maps are promoted.

status: work-completed
workflow_type: build
owner: agent
horizon:
tags: [designer, fidelity, data-loss, aef-seam]
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-07-29T20:46:02Z
last_update: '2026-08-16T13:58:52Z'
date_finished: 2026-07-29T22:02:59Z
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
  - ts: '2026-08-16T12:33:49Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 0
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=0 
      (no-signal); F-AUTONOMY=0 (no-signal); F3=0 (no-signal); F1=0 (no-signal);
      F2=0 (no-signal)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:20Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 7
    rationale: blast_radius=7 
      (paths:src/aef-workflow-designer.html,tests/fixtures/aef-bpmn/doc-comment.bpmn,tests/run-bridge-tests.sh,tests/run-validator-tests.sh);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T13:58:52Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 5
    rationale: blast_radius=5 
      (paths:src/aef-workflow-designer.html,tests/fixtures/aef-bpmn/doc-comment.bpmn,tests/run-bridge-tests.sh,tests/run-validator-tests.sh);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-311: Save path destroys the leading doc comment: agent-authored rationale block lost on first UI save

## Context

The leading XML comment child of `<bpmn:definitions>` carries the map's authored
rationale. AEF's `corpus_spec` treats it as SEMANTIC and their `fw corpus explain`
prints it. Our save path destroys it, and every save after inherits the loss.

**Mechanism, confirmed by reading our own source (not inferred from the report):**

| Stage | Site | Behaviour |
|---|---|---|
| parse | `parseBpmnXml` src:9433 | **zero** comment handling — `grep -c 'COMMENT_NODE\|nodeType === 8\|createComment'` over the whole file returns 0. The comment is never read, so it is absent from `state` from the first import. |
| state | src:9731 | `result = {pool, workflowMeta, lanes, nodes, edges}` — no carrier for it. |
| export | `buildBpmnXml` src:9284 | re-synthesises the document from `state` line by line. Emits exactly one comment, hardcoded at src:9417: `<!-- BPMN DI (visual layout) omitted in this demo; AEF generates it from node coordinates -->`, as the LAST child. |

So the doc is dropped at parse and never re-emitted; the only comment on our
output is our own trailer.

**Compounding effect, theirs and already owned there** (rail 332 → 334): their
`parse_map` took the FIRST comment child as `doc` with no guard, so it silently
adopted our trailer as the rationale — the field never read empty, it read
plausible-and-wrong. 5 of their 11 maps carried our boilerplate; 2 were PROMOTED.
Their side is now closed: reader guard shipped (T-2682, leading-position AND
non-boilerplate, prefix-matched so our wording can drift; 17 tests), and T-2683
restored the two promoted maps from git history predating the store squash
(aef-audit-cron D5, aef-session-lifecycle D3). Their guard is load-bearing until
this task ships.

**Schema question settled — do NOT couple it to this fix.** AEF asked whether to
carry the doc as an `aef:` attr on `workflowMeta` instead. Advised against at
rail 333 and they accepted at 334, recording it as a separate question: the
8-key import allowlist (src:9263) plus export re-synthesis (src:9111) means an
unratified `workflowMeta` attr drops SILENTLY — same loss as today, less visible,
and it needs ratification first. This task preserves the comment, which needs no
ratification. The attr remains open and independent.

Nothing else is harmed — AEF reports uid set, flow topology, names and `aef:meta`
notes all round-trip byte-faithfully.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] `parseBpmnXml` captures the leading comment child of `<bpmn:definitions>` onto the returned state as `docComment` — leading meaning it precedes the first ELEMENT child, matching AEF's guard semantics
      → `readDocComment()` walks `doc.documentElement.childNodes`, returns `null` on the first ELEMENT_NODE, skips text; wired at the parse result. Harness: `capturedLen 1398 == sourceLen 1398`, `verbatim: true`.
- [x] Our own DI trailer is never adopted as a doc, even if a hand-edit moves it to leading position: a prefix guard rejects it, so re-importing our own output yields `docComment === null` and cannot promote boilerplate to rationale (the exact defect that poisoned 5 of their maps)
      → `DI_TRAILER_PREFIX` is the shared constant the emitter builds its trailer from, so guard and trailer cannot drift apart. Harness leg 5 feeds a variant with the trailer HOISTED into leading position: `hoistedTrailerRefused: true`.
- [x] `buildBpmnXml` re-emits a captured `docComment` as the FIRST child of `<bpmn:definitions>`, ahead of `<bpmn:collaboration>`, so their leading-position reader finds the rationale and not our trailer
      → `leadsDocument: true` (asserted as `indexOf('<!--') < indexOf('<bpmn:collaboration')`, not merely "present").
- [x] Round-trip is byte-exact for the comment: import → export reproduces the original comment verbatim, including internal newlines and indentation
      → `verbatim: true` on a deliberately awkward 1398-char block: multi-line, hanging indent, blank lines, `<angle brackets>` and a bare `&` that must NOT be escaped (comment data is not parsed content). Also `roundTripStable: true` — export→re-import→export is byte-identical.
- [x] The undo/redo path preserves it — history snapshots serialise through `buildBpmnXml` (src:6895) and restore through `parseBpmnXml` (src:6900), so a doc comment must survive an edit→Ctrl+Z cycle rather than being silently dropped at the first undo
      → harness performs a real geometry edit, `commitHistory(before)`, `undo()`: `survivesUndo: true`. Goes red on the pre-fix build.
- [x] Zero export surface for maps that have no leading doc comment: full-corpus export sweep against the pre-change sha `b78fea6` shows every such map byte-identical; any map that DOES carry one is enumerated and its diff is exactly the gained comment, nothing else
      → `{ok: true, ref: b78fea6, maps: 24, identical: 24, drifted: 0}`. The enumeration is empty by measurement: 0 of the 24 rendered corpus maps carry a leading comment, so no map gains one. All 9 leading-comment files in the tree are fixtures.
- [x] A comment whose data would produce invalid XML on re-emit (trailing `-`, which yields the illegal `--->`) is emitted safely rather than corrupting the document
      → `safeCommentData()` spaces hyphen runs and pads a trailing `-`; nothing is deleted. Harness sets `state.docComment = ' danger -- double hyphen and a trailing dash -'` and re-parses the export: `nastyParses: true`. Unreachable from the parse path (a parser cannot hand back such data) — it guards a programmatically-set doc.
- [x] New CDP harness drives the REAL editor runtime against a fixture carrying a doc comment, and is TEETH-PROVEN (PL-061): run against the pre-fix build it goes red on the preservation assertions rather than erroring out
      → `node tools/_t311-doc-comment-roundtrip-cdp.mjs <b78fea6 build>` → **5 real assertions red**: not captured, export carries no leading comment, does not lead the document, lost on re-import, lost on undo. Tolerant reads (`typeof state.docComment !== 'undefined'`) keep it failing on the contract instead of dying on a ReferenceError.
- [x] Bridge suite green with the new leg added; validator suite unchanged
      → bridge **46 passed / 0 failed** (was 45; +1 new leg), geometry sweep 24 clean, validator **34 passed / 0 failed**.
- [x] **Not in the original scope — found by running the suite.** Preserving comments made exported bytes carry prose for the first time, which broke two harnesses that assert structure by regexing the whole document. Swept the class rather than the two failures.
      → T-308 counted `<aef:link >` 2→4 and typed-events counted `<bpmn:boundaryEvent >` 2→3, both from element names quoted in their own fixtures' doc blocks. Fixed at 4 harnesses (`_t308-bare-catch-render`, `_typed-events`, `_t259-eventdef-preservation`, `_t310-lane-position-conflict`) by asserting against a comment-stripped copy while leaving the raw bytes intact for byte-identity checks. The dangerous half is the false GREEN: a presence check like `indexOf('cancelActivity="true"')` would have passed on prose alone.

### Human

_None._ Every criterion here is deterministic — byte-exactness of a round-trip,
presence/absence of a comment node, position within the document. There is no
rendering change and nothing to form a taste about, so per the template rule this
section is removed rather than padded with a rubber-stamp.

<!-- ORIGINAL TEMPLATE GUIDANCE RETAINED FOR FUTURE EDITS:
     Criteria requiring human verification (UI/UX, subjective quality). Not blocking.
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
# Lines starting with # are comments (skipped). Empty lines ignored.
# The completion gate runs each command — if any exits non-zero, completion is blocked.
#
# Toolchain hint (L-291): if you edited *.vbproj/*.csproj/*.xaml add `dotnet build`;
# *.go → `go build ./...`; Cargo.toml → `cargo check`; tsconfig.json → `tsc --noEmit`;
# pom.xml → `mvn -q compile`. P-011 runs only what you write — broken builds slip
# past otherwise (origin: 003-NTB-ATC-Plugin T-077, broken WPF DLL on master 5 days).
#
# Pipefail/SIGPIPE hint (L-387): P-011 runs each command under `set -eo pipefail`.
# `cmd | grep -q PATTERN` exits 141 (SIGPIPE) when grep matches and closes stdin
# while the upstream is still writing — verification then "fails" even though
# the pattern was present. Safe pattern: capture first, grep the capture:
#     out=$(cmd 2>&1); echo "$out" | grep -q "PATTERN"
# Or:
#     cmd > /tmp/.out 2>&1 && grep -q "PATTERN" /tmp/.out
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

# The T-311 contract: leading doc comment survives the round-trip verbatim, our own
# trailer is never adopted as a doc, the comment leads the document on export, and
# the doc survives an undo cycle.
out=$(timeout 300 node tools/_t311-doc-comment-roundtrip-cdp.mjs 2>&1); echo "$out" | grep -q '"ok": true'
# Zero export surface for maps WITHOUT a leading doc comment, against the explicit
# pre-change ref. Pinned to b78fea6 deliberately, NOT HEAD — a HEAD-relative check
# compares the change against itself once committed and can never go red (PL-061).
out=$(timeout 300 node tools/_t308-export-byte-identity-cdp.mjs b78fea6 2>&1); echo "$out" | grep -q '"drifted": 0'
out=$(timeout 900 bash tests/run-bridge-tests.sh 2>&1); echo "$out" | grep -q "0 failed"
out=$(timeout 600 bash tests/run-validator-tests.sh 2>&1); echo "$out" | grep -q "0 failed"
# The mechanism must stay dead: the parse path must actually READ comment nodes.
# Asserted against the code that does it, not against the word "COMMENT_NODE" —
# that string also appears in the explanatory prose above the fix, so grepping for
# it would pass on a build where the reader had been deleted (PL-061: a green that
# cannot go red is not evidence).
grep -q 'function readDocComment' src/aef-workflow-designer.html
grep -q 'nodeType !== 8' src/aef-workflow-designer.html
# The doc must reach the exporter through state — the inverse of T-308's discipline,
# because here the value MUST be exported. Both ends pinned: captured onto the parse
# result, and read back by the emitter.
grep -q 'docComment: readDocComment(doc.documentElement)' src/aef-workflow-designer.html
grep -q 's.docComment != null' src/aef-workflow-designer.html
# The guard against adopting our own trailer must stay prefix-based, so rewording the
# trailer's tail cannot silently re-open the defect that poisoned AEF's corpus.
grep -q 'startsWith(DI_TRAILER_PREFIX)' src/aef-workflow-designer.html
# The fixture must stay structurally VALID: a doc comment is not a schema feature,
# so no validator rule should have an opinion about it.
python3 tools/validate-workflow.py tests/fixtures/aef-bpmn/doc-comment.bpmn --format xml > /dev/null

## RCA

**Symptom:** the authored rationale block at the top of a map disappeared the first
time the map was saved through the designer UI, and every save after inherited the
loss. Worse than silence: AEF's reader then adopted our DI boilerplate in its place,
so `fw corpus explain` printed a plausible-and-wrong rationale for 5 of their 11
maps, 2 of which had already been promoted.

**Root cause:** the designer models a document as `{pool, workflowMeta, lanes, nodes,
edges}` and re-synthesises the XML from that model on every export. Comments were not
in the model — there was no COMMENT_NODE handling anywhere in the file — so the doc
block was not "lost" at save, it was never imported in the first place. The one
comment on our output was a hardcoded trailer that had nothing to do with the source.

**Why structurally allowed:** a re-synthesising exporter drops everything it does not
model, silently and by construction, and the only guard we had against that class was
the byte-identity corpus sweep. That sweep could never catch this: it compares our
export against *our own previous export*, so anything we have never emitted is
identical-to-identical. It is a self-consistency check, and PL-034 already names the
failure mode — a guard that checks internal self-consistency cannot detect a broken
promise. The promise here was to a peer's reader, and nothing in our toolchain
represented it. Both validators pass the affected maps for the same reason they
passed T-310: both are structural, and neither models comments or geometry.

**Prevention:** the round-trip contract is now pinned by a browser-level harness with
teeth (`_t311-doc-comment-roundtrip-cdp.mjs`, red on 5 assertions against the pre-fix
build) wired into the bridge suite, so a future re-synthesis change cannot quietly
drop the doc again. The guard against re-adopting our own trailer is prefix-based off
the same constant the emitter uses, so the two cannot drift. What this does NOT
prevent is the general class — the next unmodelled thing we drop will be just as
invisible. That is a real remaining hole and it is registered as such below rather
than being claimed as closed.

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

### 2026-07-29 — the schema question resolved itself before the build started

- **What changed:** at filing, AEF had an open decision — preserve comments, or carry
  the doc as an `aef:` attr on `workflowMeta`. I advised against the attr at rail 333
  (the 8-key import allowlist plus export re-synthesis would drop it SILENTLY: same
  loss, less visible, and it needs ratification first) and they accepted at 334,
  recording it as a decoupled question.
- **Plan impact:** the build had exactly one shape to implement instead of a fork, and
  no ratification dependency. The attr question stays open and independent.
- **Triggered:** nothing new — this removed a branch rather than adding one.

### 2026-07-30 — preserving comments put prose into exported bytes for the first time

- **What changed:** not anticipated at filing. Once the doc block survives the
  round-trip, exported XML can legitimately contain text that NAMES elements. Four
  harnesses assert structure by regexing the whole exported document, and two of them
  went red immediately: T-308 counted `<aef:link >` 2→4 and typed-events counted
  `<bpmn:boundaryEvent >` 2→3, both because those fixtures' own doc blocks quote the
  element they are explaining.
- **Plan impact:** the fix was correct and the tests' assumption was wrong — "the
  export contains only structure" was true only because we destroyed comments. The
  false-red was the cheap half; the latent false-GREEN is the dangerous one, since a
  presence check like `indexOf('cancelActivity="true"')` can be satisfied by prose
  with no such attribute emitted anywhere.
- **Triggered:** swept the class rather than the two failures (G-009: a copy-paste
  defect class needs a tree sweep, not a single-site fix). Four harnesses now assert
  against a comment-stripped copy while byte-identity checks keep reading raw bytes.
  Also caught myself introducing a fresh instance mid-fix: a backtick inside an
  explanatory comment closed the probe's template literal — the harnesses embed
  browser code in template strings, which makes prose in comments load-bearing there
  too.

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

### 2026-07-30 — keep emitting the DI trailer

- **Chose:** leave the hardcoded trailer at the end of the document exactly as it is,
  and defend against it with a prefix guard instead.
- **Why:** it is the string that poisoned AEF's corpus, so removing it is tempting —
  but the poisoning was caused by their guardless reader taking the FIRST comment, and
  both halves of that are now fixed (their T-2682 guard, our leading-position doc).
  Removing it would change the bytes of all 24 corpus maps for a cosmetic reason,
  costing a full re-bake and a re-pin on their side to buy nothing.
- **Rejected:** deleting the trailer (churn without benefit); rewording it to something
  less stale than "omitted in this demo" (same churn, and the wording is only visible
  to someone reading raw XML). If it is ever reworded, the prefix guard survives it by
  construction — that is why the prefix is a shared constant rather than a literal.

### 2026-07-30 — strip comments in harnesses rather than narrow the fix

- **Chose:** make the four affected harnesses assert against a comment-stripped copy
  of the export.
- **Why:** the product behaviour is right — the doc block belongs in the output. The
  tests were relying on an accident of the bug. A structural assertion should be made
  against structure.
- **Rejected:** emitting the doc only on explicit save rather than on every export
  (would have kept the harnesses untouched, but makes the export path conditional and
  the round-trip untestable); stripping inside `buildBpmnXml` for "internal" callers
  (there is no such distinction — history snapshots use the same exporter, which is
  precisely why undo had to be tested).

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

### 2026-07-29T20:46:02Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-311-save-path-destroys-the-leading-doc-comme.md
- **Context:** Initial task creation

### 2026-07-29T21:12:14Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

## Reviewer Verdict (v1.5)

- **Scan ID:** R-60377b81
- **Timestamp:** 2026-07-29T22:03:52Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Needs Human:** no
- **Findings:** 1

**Verification-level findings:**

  1. **empty-output-success** (partial, heuristic) @ Verification:line 59
     - evidence: `python3 tools/validate-workflow.py tests/fixtures/aef-bpmn/doc-comment.bpmn --format xml > /dev/null`

### 2026-07-29T22:02:59Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
