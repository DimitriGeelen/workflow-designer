---
id: T-591
name: "EWCR Arc-0: prove the pilot fixture is a semantic fixed point through the real editor runtime"
description: >
  EWCR Arc-0: prove the pilot fixture is a semantic fixed point through the real editor runtime

status: work-completed
workflow_type: test
owner: agent
horizon: null
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-26T12:15:11Z
last_update: 2026-08-26T12:23:39Z
date_finished: 2026-08-26T12:23:39Z
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
---

# T-591: EWCR Arc-0: prove the pilot fixture is a semantic fixed point through the real editor runtime

## Context

EWCR Arc-0 (T-590) delivers one canonical pilot fixture and asserts it "renders through
the already-shipped Part I vocabulary". What was actually checked is that
`tools/validate-workflow.py` calls it VALID and that a static grep finds no runtime
constructs. Neither of those is a round trip. The fixture has never been imported by the
editor and re-emitted, so Arc-0's central claim — that this fixture is a genuine member of
the frozen contract, not merely a well-formed file that resembles one — is **stated, not
checked**. That is the same gap this week has produced four times over.

`tools/_roundtrip-serialization-cdp.mjs` already is the right instrument: it drives the REAL
editor runtime (`parseBpmnXml` → `buildBpmnXml` → `parseBpmnXml` → `buildBpmnXml`) and
asserts a semantic fixed point on governance-bearing content, excluding presentational data.
It is hardcoded to `tests/fixtures/aef-bpmn/` (`:46`), so it cannot currently be aimed at the
EWCR fixture. Making it aimable is the whole build; the verification is the point.

This is unblocked by H2 (the counterparty question) — it asks whether our own artifact is
contract-conformant, which is true or false regardless of who receives it.

## Acceptance Criteria

### Agent
- [x] `tools/_roundtrip-serialization-cdp.mjs` accepts a fixture directory override via an
      environment variable, defaulting to `tests/fixtures/aef-bpmn` so every existing caller
      and gate is byte-for-byte unaffected.
      <br>**Evidence:** `ROUNDTRIP_FIXTURES_DIR` at `:54-57`; a relative value resolves against
      the repo root, not the cwd. Bare invocation still runs all **19** corpus fixtures,
      `pass:true` (Verification 1).
- [x] Aimed at `docs/research/executable-workflow/fixtures/`, the harness reports the EWCR
      pilot fixture as a **semantic fixed point**: `proj(m1) === proj(m2)` over the aef:uid
      multiset, per-node aef:meta key→value maps, node type + name, per-node lane authority,
      the uid-keyed edge source→target set, and workflowMeta.
      <br>**Evidence:** `projEqual: true` over 5 nodes / 4 edges / 2 lanes. `byteIdempotent:
      true` as well — the stricter string-level fixed point also holds, `len1 == len2 == 12973`.
      Arc-0's central claim is now checked rather than stated.
- [x] Every node and every edge in the parsed fixture carries an `aef:uid` (the identity
      hinge the projection is keyed on) — reported as a count, not asserted in prose.
      <br>**Evidence:** `declaredUids 9 == expectedUids 9` (5 nodes + 4 edges), `undeclaredUid
      0`. **The count that matters is the SOURCE count, not the parsed one** — see ## Evolution:
      the pre-existing `missingNodeUid` leg reads the parsed model, which the parser backfills,
      so it was incapable of failing.
- [x] `buildBpmnXml` is deterministic for this fixture: `emit(state) === emit(state)`.
      <br>**Evidence:** `deterministic: true` (two successive emits from the same state, byte-equal).
- [x] The harness **refuses rather than passes** when pointed at a directory containing no
      `.bpmn` files (PL-022 — a vacuous pass is a false green), verified by actually pointing
      it at an empty directory and observing a non-zero exit.
      <br>**Evidence:** empty dir → `{"pass":false,"error":"no *.bpmn fixtures in …"}`, rc **1**.
      Missing dir → `{"pass":false,"error":"fixtures dir missing: …"}`, rc **1**. Both run, not
      read off the source.
- [x] **The instrument is proven able to fail on THIS fixture, not merely in principle:** a
      poisoned copy of the pilot fixture is rejected, and rejected for the right reason.
      A green leg nobody has watched go red is not evidence.
      <br>**Evidence:** `tools/_t591-roundtrip-teeth.sh`, **4/4** — clean copy accepted (rc 0),
      poisoned copy rejected (rc 1), clean declares 9/9, and the poison is *attributed*
      (`undeclaredUid == 1`) so a red for an unrelated reason cannot satisfy the leg.
      <br>**AC amended mid-task, honestly:** it originally said "one `aef:meta` value altered".
      That poison does **not** break a fixed point — the round trip carries the altered value
      faithfully, which is correct behaviour. The AC named a poison that could not work. The
      poison used instead deletes one `<aef:uid>`, which attacks the identity hinge the
      projection is actually keyed on. Recorded rather than quietly substituted.
- [x] The default-path run over `tests/fixtures/aef-bpmn/` still passes, so the shared
      harness is not regressed for its existing consumers.
      <br>**Evidence:** 19 fixtures, `pass:true`, **0** with undeclared uids. That zero is also
      what made gating `undeclaredUid` safe — measured across the corpus *before* the gate was
      added, not after. `test_editor_bridge_meta_parity.py` and
      `test_mapping_standard_conformance.py` both still pass.
- [x] T-590's recorded fixture sha256 `b6a9afd7…` is unchanged by this task — the fixture is
      measured, never edited to make a leg pass.
      <br>**Evidence:** `sha256sum` → `b6a9afd7eb03abeaba43513f45176dd439838887b588901f5a2aa2a83da1685b`,
      matching T-590's record and `source-manifest.sha256` line 4 exactly; `sha256sum -c` **6 of
      6 OK**. The teeth script poisons a copy under `mktemp -d` and never writes the tracked file.

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

# 1. The shared harness is NOT regressed: default path, all 19 corpus fixtures, pass:true.
node tools/_roundtrip-serialization-cdp.mjs > /tmp/.t591-corpus.json 2>&1 && python3 -c "import json,sys; d=json.load(open('/tmp/.t591-corpus.json')); sys.exit(0 if d['pass'] and len(d['fixtures'])>=19 else 1)"

# 2. Every corpus fixture declares all of its own identities (the precondition that made
#    gating undeclaredUid safe — if this ever fails, the gate below is the wrong shape).
python3 -c "import json,sys; d=json.load(open('/tmp/.t591-corpus.json')); bad=[f['fixture'] for f in d['fixtures'] if f.get('undeclaredUid')]; print('undeclared in:', bad) if bad else None; sys.exit(1 if bad else 0)"

# 3. The EWCR Arc-0 pilot fixture is a SEMANTIC FIXED POINT through the real editor runtime,
#    deterministic, with all 9 identities declared in the source rather than minted on import.
ROUNDTRIP_FIXTURES_DIR=docs/research/executable-workflow/fixtures node tools/_roundtrip-serialization-cdp.mjs > /tmp/.t591-ewcr.json 2>&1 && python3 -c "import json,sys; f=json.load(open('/tmp/.t591-ewcr.json'))['fixtures'][0]; sys.exit(0 if (f['projEqual'] and f['deterministic'] and f['undeclaredUid']==0 and f['declaredUids']==f['expectedUids']==9 and f['nodes']==5 and f['edges']==4) else 1)"

# 4. TEETH. The harness must go RED on a poisoned copy of this same fixture, and red for the
#    RIGHT REASON (undeclaredUid 1), not merely exit non-zero. Poisons a copy; never the tracked file.
bash tools/_t591-roundtrip-teeth.sh > /tmp/.t591-teeth.out 2>&1 && grep -q "^4/4 T-591 teeth legs passed" /tmp/.t591-teeth.out

# 5. PL-022: an empty fixtures directory REFUSES rather than vacuously passing.
#    `test` is deliberately last — P-011 judges `a; b` on `b` alone (T-352).
D=$(mktemp -d); ROUNDTRIP_FIXTURES_DIR="$D" node tools/_roundtrip-serialization-cdp.mjs >/dev/null 2>&1; rc=$?; rmdir "$D"; test "$rc" -ne 0

# 6. The fixture was measured, never edited to make a leg pass: T-590's recorded sha256 holds.
sha256sum -c docs/research/executable-workflow/source-manifest.sha256
grep -q "^b6a9afd7eb03abeaba43513f45176dd439838887b588901f5a2aa2a83da1685b  docs/research/executable-workflow/fixtures/ewcr-pilot-human-gate-script-human-gate.bpmn$" docs/research/executable-workflow/source-manifest.sha256

# 7. The existing editor/bridge seam guards still pass (the harness edit touches a shared tool).
python3 tests/test_editor_bridge_meta_parity.py
python3 tests/test_mapping_standard_conformance.py

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

### 2026-08-26 — the identity gate in the shared corpus harness could not fail

Found while proving the instrument had teeth, which is the only reason it was found at all.

`_roundtrip-serialization-cdp.mjs` gated on `missingNodeUid===0 && missingEdgeUid===0`, and
its header comment reads *"every node and every edge in m1 carries an aef:uid (identity
hinge)"*. But `m1 = parseBpmnXml(text)`, and `parseBpmnXml` **mints** an identity for anything
arriving without one — `src/aef-workflow-designer.html:10284`, deliberate, so third-party BPMN
can be imported at all. The counters therefore read a model the parser has already repaired,
and are zero **by construction**.

Measured, not inferred: deleting one of the pilot fixture's nine `<aef:uid>` elements still
produced `missingNodeUid: 0`, `ok: true`, `pass: true`. That leg has never been capable of
going red in the entire life of the harness, on any fixture, including all 19 corpus members.

**Fixed by measuring the source instead.** `declaredUids` counts `<aef:uid ` in the fixture
text; `undeclaredUid = (nodes + edges) - declaredUids` is the number of identities the editor
had to invent. It is now gated — but only after measuring all 19 corpus fixtures first and
finding **0** undeclared across every one, so the new gate turns nothing red today and can only
fire on a fixture that starts relying on minting. Gating before measuring would have been a
decision disguised as a check.

Why this matters beyond one leg: a fixture whose identities are minted round-trips *fine* —
the uid is stable within the run — but the uid is different on the next run, so the identity
the seam is keyed on is not the same identity twice. The old leg would have called that clean.

### 2026-08-26 — and my own replacement leg was blind on its first run, for the same reason

Recording this because it is the failure I had just spent the day describing to two other
projects, committed inside the fix for it.

The first version counted with `text.match(/<aef:uid\s+value="/g)`. That expression lives
inside a **JS template literal**, where `\s` collapses to `s` before the browser sees it — so
the pattern shipped as `/<aef:uid s+value="/` and matched nothing. It reported
`declaredUids: 0` on a fixture carrying nine, which is **the same number it would report for a
fixture that genuinely had none.** An instrument that cannot see its subject, returning a
plausible value.

Caught only because I had a known-good expectation (9) to compare against. Had I introduced
this leg without one, `declaredUids 0 / undeclaredUid 9` would have looked like a finding
about the fixture rather than a defect in the ruler. Replaced with
`text.split('<aef:uid ').length - 1` — no escapes, nothing for the template literal to eat.

999-AEF described this exact shape at rail offset 473 ("nine zeros from an instrument that
could not see its subject, indistinguishable from nine zeros from one that looked") the same
morning. I read it, then did it.

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

### 2026-08-26T12:15:11Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-591-ewcr-arc-0-prove-the-pilot-fixture-is-a-.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-990c91ba
- **Timestamp:** 2026-08-26T12:23:45Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-26T12:23:39Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
