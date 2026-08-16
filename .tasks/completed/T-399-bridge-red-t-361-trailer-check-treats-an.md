---
id: T-399
name: "Bridge red: T-361 trailer check treats an AEF-authored fixture as one of our
  exports (prefix collision)"
description: >
  Bridge red: T-361 trailer check treats an AEF-authored fixture as one of our exports
  (prefix collision)

status: work-completed
workflow_type: build
owner: agent
horizon:
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-08T21:03:58Z
last_update: '2026-08-16T13:57:22Z'
date_finished: 2026-08-09T09:13:45Z
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
  - ts: '2026-08-16T12:33:55Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 5
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 2
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4-5 (body:new-class); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=2 
      (body:lightly-promoted); F-AUTONOMY=0 (no-signal); F3=0 (no-signal); F1=0 
      (no-signal); F2=0 (no-signal)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:22Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 9
    rationale: blast_radius=9 
      (paths:src/aef-workflow-designer.html,tests/fixtures/exported/t361-trailer-witness.bpmn,tests/fixtures/third-party/PROVENANCE.md,tests/fixtures/third-party/aef-draft-inception-readiness-v2.bpmn);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-399: Bridge red: T-361 trailer check treats an AEF-authored fixture as one of our exports (prefix collision)

## Context

**The bridge suite is RED on master: 70 passed, 1 failed** (`tests/run-bridge-tests.sh`,
exit 1). Geometry sweep is clean, 24/24. Found while pre-running P-011 for T-398's census;
it is what blocks T-041 and T-101 from closing.

    [FAIL] tests/test_emitted_comment_claims.py (T-361)
           FAIL every exported document carries the approved trailer or is a pinned legacy record
                tests/fixtures/third-party/aef-draft-inception-readiness-v2.bpmn
           documents: 1 current, 106 legacy-exempt, 1 unaccounted

### It is a PREFIX COLLISION, not a missing trailer

    ours   (src:9432-9433)  BPMN DI (visual layout) omitted; node geometry travels as aef:position
    AEF's  (the fixture)    BPMN DI (visual layout) omitted in this demo; AEF generates it from node coordinates
                            └──────── shared prefix ─────────┘└──── diverges here ────┘

`test_emitted_comment_claims.py:165` scopes the walk with `if prefix not in body: continue`
— using **"contains our trailer PREFIX"** as a proxy for **"we exported this document"**.
Line 167 then requires the FULL current trailer, and line 171 allows a pinned-sha legacy
exemption. AEF's file satisfies the entry condition and neither exit, so it lands in
`offenders`.

The document has never been through our emitter. AEF wrote a comment that happens to open
with the same eight words — which is not a coincidence worth designing around so much as an
inevitability: it describes the same fact, in the same domain vocabulary, and AEF is the one
peer that shares it.

### Why the proxy was sound and then was not

`prefix in body` was a correct identity test for a corpus containing only our own output.
The T-347/T-356/T-372 third-party intake changed the population. **The check did not become
wrong; the world it was measuring did.**

This is the third instance of one shape from the same intake:

| task | check | complete for | wrong once |
|---|---|---|---|
| T-359 | validator's non-flow-node exclusion set | children *our* emitters produce | Bizagi's `<documentation>` arrived |
| T-337 | importer's node-tag allowlist | tags *we* emit | a foreign tag arrived |
| **T-399** | trailer check's "is this ours" proxy | documents *we* exported | a peer's prose collided |

**It fails in the unsafe direction.** It does not miss one of our documents that lost its
trailer; it reports a foreign document as one of ours. A reader trusting the message would
go looking for an emitter bug that does not exist.

### The fix is a judgement call — do NOT reach for the obvious two

- **Do not add it to the legacy ledger.** The ledger pins sha→path to say *"this document
  legitimately carries an OLD trailer"*. This one carries **no** trailer of ours, ever. A
  ledger entry would be a false statement, and the ledger's whole value is that its entries
  are true.
- **Do not exclude `tests/fixtures/third-party/`.** That is an allowlist-shaped patch to an
  allowlist-shaped defect — the exact move T-337's `## Decisions` warns about. It also fails
  the moment a peer document is vendored anywhere else.

The real question is **what positively identifies a document as our export**, given that the
current answer is prose and prose collides. Whatever is chosen needs mutation teeth in the
T-359 style: prove the check still goes RED on a genuine one of our documents with a stale
trailer, or the fix has removed the check rather than repaired it.

### Provenance is already documented — the ledger just was not told

`tests/fixtures/third-party/PROVENANCE.md:200` already carries a section titled *"foreign,
but NOT by this directory's test (T-372)"*, recording that this file fails the directory's
provably-foreign fingerprint because AEF legitimately uses the `aef:` namespace they define.
So T-372 identified that **one** identity test misfires on this file and documented it — and
a **second** identity test, in a different suite, misfires on the same file for a closely
related reason and went unnoticed. Worth carrying into the fix: the question is not "is this
file foreign" but "how many checks in this tree infer authorship from a string".

Landed 2026-08-08 in `ee2d8217` (T-372). The suite has been red since.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] Bridge suite green: `tests/run-bridge-tests.sh` reports `0 failed` and exits 0.
      — **71 passed, 0 failed, exit 0** (was 70 passed / 1 failed).
- [x] The repair identifies our exports by something a peer's PROSE cannot collide with, and
      the choice is recorded in `## Decisions` with the two rejected shapes named (ledger
      entry — states a falsehood; directory exclusion — an allowlist patch on an allowlist
      defect, and it moves the moment a peer file is vendored elsewhere).
      — the standard `exporter` attribute on `<definitions>` (forward) ∪ ledger PATH
      (historic). Both rejected shapes named in `## Decisions`.
- [x] **Mutation teeth, T-359 style.** Take a genuine document of ours, give it a STALE
      trailer, and prove the repaired check still reports it. A fix that silences the one
      false positive by narrowing the net until nothing is caught has removed the check, not
      repaired it — and would look identical in the suite output.
      — `_t361-guard-teeth.py` case 8 mutates the REAL exported witness (bytes produced by
      the real editor in a real browser), not a synthetic document. Red on the right check.
      Case 7 is the anti-narrowing case: strip producer identity from every document and the
      guard must report a narrowed net rather than a clean tree. 8/8 red, control green.
- [x] The reciprocal control: with the repair in place, AEF's fixture is NOT reported, and
      the reason it is not reported is the new identity mechanism rather than a path skip.
      — `RECIPROC` control in the teeth harness copies the fixture to
      `vendored/somewhere-else/peer-document.bpmn`, a path no rule mentions, so a pass
      cannot be a path skip in disguise. Guard green, fixture not named.
- [x] Census of the same shape: how many other checks in the tree infer authorship or
      provenance from a string match? Reported (not necessarily fixed) — T-372 found one such
      misfire on this exact file and this is a second, so a third is the working assumption
      until counted.
      — **The working assumption was right: there is a third, and it is live.** See
      `## Census` below. Filed as T-406, not fixed here.
- [x] T-041 and T-101 re-run: their bridge-suite verification lines pass.
      — bridge line PASS (both), plus T-101's geometry line (`0 known-legacy, 0 new-fail`)
      and validator line (`passed, 0 failed`).

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

# --- T-399 commands ---
out=$(bash tests/run-bridge-tests.sh 2>&1); echo "$out" | grep -q "passed, 0 failed"
# The collision itself, asserted directly: the fixture must NOT be named as an offender.
out=$(python3 tests/test_emitted_comment_claims.py 2>&1); ! echo "$out" | grep -q "aef-draft-inception-readiness-v2"
# Anti-vacuity: the check must still be CAPABLE of reporting. If the repair narrowed the
# net to nothing, the line above passes and means nothing — same failure the fix must avoid.
out=$(python3 tests/test_emitted_comment_claims.py 2>&1); echo "$out" | grep -q "documents:"
# The teeth. Its own exit code is the verdict (no chaining, so the errexit note above
# cannot apply): control green, 8 mutations each red on their OWN check, and the
# reciprocal control proving the peer document is not reported for the right reason.
python3 tools/_t361-guard-teeth.py
# Producer identity in REAL produced bytes, not just in src. This witness came out of the
# actual editor in a real browser (tools/_t361-export-trailer-cdp.mjs). A source-only
# assertion would prove the constant was edited, which is the exact gap T-361 was about.
grep -q 'exporter="aef-workflow-designer"' tests/fixtures/exported/t361-trailer-witness.bpmn
# The forward arm must actually resolve: 0 current would make the guard vacuous.
out=$(python3 tests/test_emitted_comment_claims.py 2>&1); echo "$out" | grep -q "forward identity arm resolves"

## Census — checks that infer authorship or provenance from a string

Searched `src/`, `tests/`, `tools/`, `lib/`, `web/` for namespace constants, provenance and
authorship vocabulary, and every reader of `DI_TRAILER_PREFIX`. Not searched:
`.agentic-framework/` (vendored, different owner).

**Members of the class — three, not two:**

| # | site | infers | status |
|---|---|---|---|
| 1 | `tests/test_emitted_comment_claims.py:165` | trailer PREFIX in body ⟹ "we exported this" | **fixed here** |
| 2 | `tests/fixtures/third-party/PROVENANCE.md:12-25` | `exporter=` + absence of our fingerprints ⟹ "provably foreign" | sound; documented misfire on this exact file (T-372) |
| 3 | `src/aef-workflow-designer.html:9474` (`readDocComment`) | leading comment starts with our prefix ⟹ "our own boilerplate, discard" | **live, unfixed → T-406** |

**#3 is the same collision failing in the other direction, and it is worse.** T-399's
instance mislabels a foreign document; #3 *destroys content*. A peer whose leading rationale
opens with those eight words has their doc block silently dropped on import — the T-347
loss shape, from a mechanism we built ourselves. No document in the corpus triggers it today
(AEF's fixture carries its DI comment at line 349, not leading), so this is a live code path
with no live witness — which is precisely the condition under which T-399's own instance sat
undetected until the population changed.

**#2 deserves a note, because it is the one that got it right.** T-372 wrote, one day before
this task needed it: *"the test is a property no fixture we could write would honestly have —
**the exporting tool's own signature on `<definitions>`**"*, and tabulated `exporter=` for
all five third-party fixtures. Every real emitter in the population stamps it. Ours was the
only producer that stayed silent, which is why "who wrote this?" had no answer to give. The
repair is not a new mechanism; it is adopting the one this tree had already written down.

**Checked and NOT members** (recorded so the next census does not re-derive them):

- `tools/rail-sweep.py:168` — membership by ed25519 fingerprint. Cryptographic identity, not
  prose. This is the shape the other three want to be.
- `tests/test_rule_dialect_axis.py` — partition derived from the frozen standard
  (`_standard_partition`), explicitly with "no corpus term in it".
- `tests/test_corpus_fixture_pins.py` — explicit paths, no inference.
- ~20 `AEF_NS` / `xmlns:aef` constants across `tools/` and `tests/` — these select a
  VOCABULARY, they do not claim authorship. A namespace says which dictionary a field comes
  from; it says nothing about who wrote the document. Conflating the two is exactly what made
  the AEF fixture ambiguous, so the distinction is worth stating rather than assuming.
- `tools/_t366-uid-shape-teeth.py` — models shape-based identity (`^n_[0-9a-f]{8}$`) as a
  HAZARD to be proven against; no live code does it.

## RCA

**Symptom:** `tests/run-bridge-tests.sh` red on master since `ee2d8217` (2026-08-08),
70 passed / 1 failed. `test_emitted_comment_claims.py` named
`tests/fixtures/third-party/aef-draft-inception-readiness-v2.bpmn` as an exported document of
ours missing the approved trailer. It has never been through our emitter.

**Root cause:** the guard needed to answer "did we export this document?" and had nothing to
answer it with, because **our exports carried no producer identity at all**. It substituted
"the body contains `DI_TRAILER_PREFIX`" — using a claim about DI as a proxy for authorship.
That was a correct identity test for a corpus containing only our own output. The
T-347/T-356/T-372 third-party intake ended that precondition; AEF authored a document to our
own mapping standard and opened its DI comment with the same eight words, describing the same
fact in the same domain vocabulary. **The check did not become wrong — the population it
measured did.**

Prose was the proximate carrier, but no other marker we emit would have worked either: a peer
conforming to the mapping standard produces the same namespaces, the same `targetNamespace`
and the same `Definitions_<id>` shape, *because conforming is the point of the standard*. The
deeper cause is that we asked an identity question of a corpus in which every real emitter
answers it via `exporter=` and only ours declined to.

**Why structurally allowed:** three things, and the third is the general one.

1. Nothing required a produced artifact to identify its producer. The one guard that needed
   the answer invented a proxy locally, and a proxy in one file is invisible to everything.
2. `prefix in body` was load-bearing for scope while reading as a cheap pre-filter. Its
   failure mode is silent widening — it can only ever pull MORE documents in, and every
   document it wrongly pulls in becomes an accusation.
3. **It fails in the unsafe direction and the suite output cannot show that.** A red naming a
   file reads as "this file is broken"; it never reads as "the check misidentified whose file
   this is". A reader would have gone looking for an emitter bug that does not exist.

Third instance of one shape from one intake: T-359 (validator's exclusion set, complete for
children *our* emitters produce), T-337 (importer's tag allowlist, complete for tags *we*
emit), T-399 (trailer check's identity proxy, complete for documents *we* exported). All
three were correct-and-total over a population defined by our own output, and all three were
falsified by the same event.

**Prevention** (distinct from the fix):

- The forward arm is a STANDARD field, so the next peer to arrive answers it themselves
  rather than colliding with us. Adopting the standard's carrier is what makes this scale
  past AEF — the fix is not "handle AEF", it is "stop guessing".
- `_t361-guard-teeth.py` case 7 is an anti-narrowing test: if the identity mechanism ever
  resolves nothing, the guard reports a narrowed net instead of a clean tree. The failure
  mode of *this repair* now has teeth, not just the failure mode it repaired.
- Two anti-vacuity checks inside the guard assert each arm independently, because a break in
  one is invisible while the other still resolves something.
- The `RECIPROC` control pins the false-positive direction, which no mutation case can cover:
  every other case proves the guard can go red, and only this one proves it stopped going red
  about somebody else's file.
- The census above turned a "working assumption" into a filed task (T-406) rather than a
  worry.

## Evolution

### 2026-08-09 — the answer was already in the tree, written down the day before

- **What changed:** I expected to have to invent an identity mechanism and weigh it against
  alternatives. `tests/fixtures/third-party/PROVENANCE.md` (T-372, landed 2026-08-08) had
  already named the right one — *"the exporting tool's own signature on `<definitions>`"* —
  and tabulated `exporter=` for all five third-party fixtures. The same file's §200 records
  that the AEF fixture carries **"no `exporter=`"**, which is the precise fact that makes the
  repair work, sitting in a section written to explain a *different* misfire on the *same*
  file.
- **Plan impact:** the design question collapsed from "what should identity be" to "why is
  our own output the only thing in this corpus that does not answer it". That reframed the
  root cause from a test defect to an emitter omission, and moved the fix into `src/`.
- **Triggered:** T-406 (third census instance, `readDocComment`). Also the observation that
  T-372 and T-399 are two checks misfiring on ONE file for related reasons within 24 hours —
  the tell was there, and only one of the two was noticed at the time.

### 2026-08-09 — the harness failed the fix, which is the harness working

- **What changed:** my first anti-vacuity check (`legacy_ok > 0`) asserted a property of the
  full tree against the deliberately minimal tree the teeth harness builds. CONTROL went red.
- **Plan impact:** the fix was right and the test tree was wrong — `build_tree` did not
  represent both identity generations, because until this task there was only one. Corrected
  by materialising two ledgered documents (two, not one, so the case that tampers with the
  first still leaves the historic arm resolving).
- **Triggered:** nothing filed; recorded because the sequence is the point — the teeth caught
  a defect in the repair itself within a minute of the repair existing. (workflow_type=build with bug-tag, OR title matches
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

### 2026-08-09 — identity: the standard's `exporter` attribute, not prose

- **Chose:** emit `exporter="aef-workflow-designer"` on `<bpmn:definitions>` (BPMN 2.0's own
  producer field), and scope the guard to `exporter matches` **OR** `path is in the legacy
  ledger`.
- **Why:** the question is "who produced these bytes", and BPMN already defines the field for
  it — so we answer with the standard's carrier rather than inventing one (Portability). It
  is the one marker a conforming peer cannot collide with by accident: everything else we
  emit (namespaces, `targetNamespace`, `Definitions_<id>`) is *shared on purpose*, because
  conforming to the mapping standard is the point of having one. To collide on `exporter` a
  peer must assert our identity — a lie about provenance, not an overlap of vocabulary. This
  tree already relies on exactly this property: `PROVENANCE.md` calls it "a property no
  fixture we could write would honestly have".
- **Rejected — add the fixture to the legacy ledger.** The ledger pins sha→path to say *"this
  document legitimately carries an OLD trailer of ours"*. This document carries no trailer of
  ours and never did. The entry would be a false statement, and the ledger's entire value is
  that its entries are true.
- **Rejected — exclude `tests/fixtures/third-party/`.** An allowlist-shaped patch to an
  allowlist-shaped defect (the move T-337's Decisions warns about), and it relocates the bug
  rather than fixing it: the collision returns the moment a peer document is vendored
  anywhere else. The `RECIPROC` control puts the fixture at
  `vendored/somewhere-else/peer-document.bpmn` specifically so this shape cannot creep back in
  and still pass.

### 2026-08-09 — scope keyed on PATH, exemption keyed on SHA

- **Chose:** the historic identity arm asks whether the document's PATH is in the ledger; the
  exemption asks whether its SHA matches.
- **Why:** it preserves the ledger's own stated design — *"Changing the bytes moves the sha,
  drops it out of the ledger, and puts it back under the live rule"*. A re-export at a
  ledgered path stays in scope by path and loses its exemption by sha, so it lands in
  offenders exactly as before.
- **Rejected — key scope on sha too.** Tempting (one mechanism, not two) and wrong: changed
  bytes would leave scope entirely instead of falling back to the live rule, so a re-export
  carrying a false trailer would escape the guard rather than be caught by it. The exemption
  would become a silence with a filename — the precise thing `_t361-guard-teeth.py` case 5
  exists to forbid, and it would have gone on passing while meaning nothing.
- **Accepted limit, stated rather than hidden:** a legacy document hand-edited to a path not
  in the ledger leaves scope. Those are no longer bytes we produced, and no signal
  distinguishes them from a foreign document without reintroducing prose matching.

### 2026-08-09 — `exporterVersion` deliberately NOT emitted

- **Chose:** emit `exporter` only.
- **Why:** `src/` carries no version constant, so sourcing a version would mean a second copy
  of `VERSION` living inside the emitter, kept in step with the real one by good intentions.
  That is the duplicate-constant class T-361 exists to prevent — it would be introduced ten
  lines below its own tombstone. Identity does not need the version.
- **Rejected — add a version constant now.** Doing it properly needs build-time substitution
  plus a guard that the two cannot drift, which is a separate deliverable, not a rider on a
  red-suite fix.

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

### 2026-08-08T21:03:58Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-399-bridge-red-t-361-trailer-check-treats-an.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-a5df59ad
- **Timestamp:** 2026-08-09T09:15:16Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Needs Human:** no
- **Findings:** 1

**Verification-level findings:**

  1. **l387-sigpipe-risk** (partial, heuristic) @ Verification:line 51
     - evidence: `out=$(python3 tests/test_emitted_comment_claims.py 2>&1); ! echo "$out" | grep -q "aef-draft-inception-readiness-v2"`

### 2026-08-09T09:13:45Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
