---
id: T-904
name: "The round-trip guard's denominator reads COMMENTS as code: a comment mentioning
  aef.foo counts as a projection"
description: >
  deriveProjectedKeys() in tools/_roundtrip-serialization-cdp.mjs builds its 'dot'
  set by regexing the RAW TEXT of the projection function body (/aef\.([A-Za-z_][A-Za-z0-9_]*)/g
  at :246) - comments included. Consequence, measured live during T-889: dropping
  'authority' from the emitter's metaKeys left the guard GREEN, because a PROSE COMMENT
  three lines above said 'node.aef.authority'. Removing only that comment text (changing
  nothing executable) turned the same mutant RED with the correct message 'KEYSPEC
  contains key(s) the emitter does not project: authority'. Two directions of harm:
  (1) FALSE GREEN - a key deleted from the emitter stays 'covered' as long as any
  comment names it, which is how T-889's own mutation leg was neutralised by T-889's
  own comment; (2) FALSE RED - a comment mentioning aef.somethingNotEmitted makes
  it an orphan demanding KEYSPEC classification for a key nothing projects. This is
  the T-886 derivation, which exists precisely so the list cannot drift from the emitter
  - and it can be moved by text that the engine never runs. Fix direction: strip comments
  from the function body before matching (or parse rather than regex), then re-run
  the T-889 teeth M1 leg, which is the ready-made control.

status: work-completed
workflow_type: build
owner: agent
horizon: null
tags: [arc:designer-authoring-surface, false-green]
components: [src/aef-workflow-designer.html, tests/test_rule_dialect_axis.py, tests/test_rule_form_parity.py, tools/_roundtrip-serialization-cdp.mjs, tools/_t904-denominator-comment-blindness-teeth.sh, tools/validate-workflow.py]
related_tasks: [T-886, T-889, T-905]
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
# demo_target: true               # T-2286: optional — marks task as reserved for an orchestrated demo
#                                 # worker (e.g. arc-010 HM-A dispatches via mcp__fw__work_on). When set,
#                                 # `fw work-on T-XXX` refuses unless --i-am-demo-orchestrator (CLI) or
#                                 # FW_I_AM_DEMO_ORCHESTRATOR=1 (env) is passed. Prevents the parent
#                                 # session from consuming the captured→started-work transition the demo
#                                 # worker expects to drive. Origin OBS-057.
created: 2026-09-27T14:09:54Z
last_update: 2026-09-27T15:16:48Z
date_finished: 2026-09-27T15:16:48Z
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
  - ts: '2026-09-27T14:20:56Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 4
      D3: 3
      D4: 2
      F-RECALL: 2
      F2: 0
      F4: 0
      F3: 4
      F1: 1
    rationale: 'D1=4 (body:structural-gate); D2=4 (body:fw-audit-or-doctor); D3=3
      (body:component-discoverability); D4=2 (body:env-class-handled); F-RECALL=2
      (body:lightly-promoted); F2=0 (no-signal); F4=0 (basis: task body — no hypothesis,
      so this score has no claim to be wrong about,L0: no signal); F3=4 (basis: task
      body — no hypothesis, so this score has no claim to be wrong about,L4:keyword=round-trip);
      F1=1 (basis: task body — no hypothesis, so this score has no claim to be wrong
      about,L1:keyword=designer)'
    rubric_sha: e4a00f38e801
  - ts: '2026-09-27T14:37:51Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 4
      D3: 3
      D4: 2
      F-RECALL: 2
      F2: 0
      F4: 0
      F3: 4
      F1: 2
    rationale: 'D1=4 (body:structural-gate); D2=4 (body:fw-audit-or-doctor); D3=3
      (body:component-discoverability); D4=2 (body:env-class-handled); F-RECALL=2
      (body:lightly-promoted); F2=0 (no-signal); F4=0 (basis: task body — no hypothesis,
      so this score has no claim to be wrong about,L0: no signal); F3=4 (basis: task
      body — no hypothesis, so this score has no claim to be wrong about,L4:keyword=round-trip);
      F1=2 (basis: task body — no hypothesis, so this score has no claim to be wrong
      about,L1:keyword=designer)'
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-09-27T14:38:01Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      blast_radius:
      tier: 2
      effort: 8
    rationale: blast_radius=? (no-components-UNMEASURED-not-zero); tier=2 
      (workflow:build); effort=8 (lines=289,acs=7)
    rubric_sha: e4a00f38e801
  - ts: '2026-09-27T14:39:38Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      blast_radius: 3
      tier: 2
      effort: 8
    rationale: blast_radius=3 (3-components); tier=2 (workflow:build); effort=8 
      (lines=289,acs=7)
    rubric_sha: e4a00f38e801
---

# T-904: The round-trip guard's denominator reads COMMENTS as code: a comment mentioning aef.foo counts as a projection

## Context

Fix landed in `deriveProjectedKeys()`: a quote-aware `stripJsComments()` runs before every regex
in the derivation, at both call sites — the `aefExtensionXml` body slice (stripped wholesale, it
is pure JS) and the `EVENT_BINDING_FIELD` read (stripped **per line**, requiring exactly one
surviving declaration; see `## Evolution` for why the whole-file form was wrong). The anchor and
the column-0 close are still located on RAW lines — a comment cannot fake either — so only the
matching is stripped, and line count is preserved.

**Quote-aware rather than `/\/\/.*$/`, deliberately.** Measured: today no string literal in the
function body contains `//` (0 occurrences), so a naive strip would be *accidentally* correct and
would silently truncate real code the first time someone wrote a URL in a string. C2 covers
strings, escaped quotes, template literals, block comments and newline preservation.

**What stripping removed from the derived set, measured:** exactly two identifiers entered `dot`
via comments only — `authority` and `emits`. Neither loses coverage. `authority` is still
projected via `metaKeys` (21 keys), and `emits` is in `EXCLUDED` (STRUCTURED, T-483) so it was
never counted toward the verdict. The guard is green on clean source (C1, rc=0). AC4's "if
stripping reveals a key KEYSPEC only covered via a comment" branch therefore did not fire — stated
because the branch was real, not because it was rhetorical.

**Two findings surfaced and were filed rather than absorbed:**
- **T-905** — chasing why `emits` was comment-only showed the structured keys are emitted through
  the *computed* access `aef[key]`, and `COMPUTED_SOURCES` misdescribes what all three of its
  declared variables iterate. Separate mechanism, separate task (one bug = one task).
- The **BVP cost axis** was reported by two prior rounds as non-existent for this arc. It is gated
  on `components:`. Measured on this task: `components: []` → `blast_radius=?`, no composite,
  `QUAD -`; three component paths → `blast_radius=3`, composite **3.20**, quadrant **hv-lc**. See
  PL-352; the ranker's own output NOTE names the cause and ticket T-3068.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] AC1 — `deriveProjectedKeys()` matches against COMMENT-FREE source text. Both JS comment
      forms found inside `aefExtensionXml` are stripped before any `aef.` / `aef[` / `metaKeys`
      regex runs. Checked by a probe that reports the derived `dot` set from raw vs stripped body
      and names every identifier that entered the set via a comment ONLY.
- [x] AC2 — FALSE GREEN killed. With a comment inside `aefExtensionXml` that DOES spell the
      dotted accessor `node.aef.authority`, deleting `authority` from the emitter's `metaKeys`
      still turns the guard RED naming `authority`. This is the T-889 M1 mutation leg run against
      the comment that previously masked it — before the fix this exact pair is GREEN.
- [x] AC3 — FALSE RED killed. A comment inside `aefExtensionXml` mentioning `aef.` followed by an
      identifier that nothing in the emitter projects does NOT make the guard red, and does NOT
      appear in the orphan/`specNotProjected` lists.
- [x] AC4 — No regression: the guard is GREEN on unmutated source after the fix, and the T-889
      teeth script passes in full (all legs + controls, including C4). If stripping comments
      removes a key that KEYSPEC only ever "covered" via a comment, the guard goes red — that is
      a real finding to be recorded and filed, NOT absorbed by loosening the fix.
- [x] AC5 — The T-889 workaround comment at `src/aef-workflow-designer.html:10052-10055` (which
      exists solely to avoid spelling the accessor and cites T-904 as the reason) is removed, and
      its removal is itself the AC2 fixture — i.e. the accessor is spelled in prose and the
      mutation leg still bites. A load-bearing comment is retired by the fix, not left in place.

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
# ── Mutable-corpus anchor (T-3326) ────────────────────────────────────────────
# Do NOT anchor a verification line (or a unit test it runs) to MUTABLE corpus
# state — an exact live count, or a grep of live `fw audit`/`fw doctor` output
# for a specific corpus entity (a named arc, a task count, a census number).
# The corpus moves under the check, and the line rots: it goes red (or vanishes
# its pattern) for reasons unrelated to the code under test, blocking closes.
# Pin the INVARIANT (categories sum, count > 0, property holds) or run the code
# against a COMMITTED FIXTURE — never the live count or a live-audit line.
# Origin: T-2969 line grepping live audit for one arc's status; T-2871's census
# test pinning exact live counts (56→74 files) — both blocked closes (OBS-377).
#
# ── Pipefail/SIGPIPE: grepping a command's output (L-387, T-2090, T-2743, T-2738) ──
#
# THE DEFAULT — redirect to a file, then grep the file:
#     cmd > /tmp/.out 2>&1 && grep -q "PATTERN" /tmp/.out
#     curl -sf "$(bin/fw watchtower url)/page" -o /tmp/.out && grep -q "PAT" /tmp/.out
# Correct at any output size, and `&&` keeps the PRODUCING command's exit code in
# the verdict. Reach for this first; the alternative below is the special case.
#
# Why not `cmd | grep -q PAT` (L-387): P-011 runs each line with PIPEFAIL LIVE
# (errexit is not — see below). When grep matches it exits and closes stdin while cmd is still
# writing, cmd takes SIGPIPE, the pipeline exits 141 — verification "fails" with
# the pattern present. Captured 4× (T-1716, T-1838, T-1862, T-1863).
#
# THE EXCEPTION — capture first, grep the capture:
#     out=$(cmd 2>&1); echo "$out" | grep -q "PATTERN"
# Valid ONLY while "$out" fits the 65536-byte pipe buffer, and it is on you to
# know that it does. Above that the form inverts and becomes the very failure
# L-387 describes: echo blocks on the full pipe, grep -q exits, echo takes
# SIGPIPE, rc=141 (T-2743 — measured on a 146,366-byte Watchtower page, 3/3 runs,
# deterministic not racy; rendered routes run 50-200KB, so anything that curls a
# page is over the line). It also discards cmd's exit code, so a 404 yields an
# empty capture that grep merely fails to match rather than a failed line.
# If you do use it: single pipe only, no intermediate tail/awk/sed stage between
# capture and grep (T-2090) — the middle stage is what `grep -q` slams its stdin
# on, and grep scans the whole captured string anyway, so the `tail -3` was
# cosmetic. `echo "$out" | grep -q PAT`, nothing between.
#
# TEST RUNNERS need a guard either way (T-2738). `set -e` is suppressed inside the
# `if` condition the gate runs each line in, so in `cmd1; cmd2` only cmd2 is the
# verdict — and the pass marker you grep for survives a partial failure: a suite
# printing "3 failed, 9 passed" satisfies `grep -q "9 passed"`, and generalising
# to `grep -qE "[0-9]+ passed"` matches the same output. Keep the exit code:
#     python3 -m pytest <file> -q > /tmp/.out 2>&1 && grep -q passed /tmp/.out
# or add the guard the exit code used to supply:
#     out=$(python3 -m pytest <file> -q 2>&1); echo "$out" | grep -q passed && ! echo "$out" | grep -q failed
#     out=$(bats <file> 2>&1); echo "$out" | grep -q '^ok 1 ' && ! echo "$out" | grep -q '^not ok'
# The close gate refuses the unguarded form. Bypass: FW_ALLOW_UNJUDGED_TEST_RUN=1.
#
# ── A SKIPPED BATS TEST REPORTS `ok` (T-3217) ─────────────────────────────────
#
# `! grep -q "^not ok"` does NOT mean the suite ran. Bats emits a skip as
#     ok 6 <name> # skip <reason>
# which is not a `not ok`, so the gate passes and the report says ok while the
# thing the test covers was measured NOWHERE. Origin: T-3213 guarded a test with
# `[ "$(id -u)" -eq 0 ] && skip` — the suite runs as root here and in CI, so it
# skipped on every run that mattered, for as long as it existed.
#
# Add a skip clause to any bats verification line. `# skip` is the marker bats
# writes; counting it is the whole check:
#     timeout 300 bats <file> > /tmp/.out 2>&1 && ! grep -q "^not ok" /tmp/.out
#     test "$(grep -c '# skip' /tmp/.out)" -eq 0
# Two lines, because they answer different questions — "did anything fail" and
# "did everything run". If some skips are legitimate on your host (an optional
# dependency is genuinely absent), assert the COUNT you expect rather than zero,
# and say in the task why that number is right.
#
# Corpus-wide, the same check runs from `bin/fw test lint`
# (tools/bats-silent-skip-lint.py): static mode flags guards that are fixed for
# a deployment rather than probing an optional dependency, and `--tap FILE`
# reports the skips a real run actually fired.
#
# REHEARSING A LINE BY HAND DOES NOT REHEARSE THE GATE (T-2743). Your interactive
# shell has no pipefail. A line has returned 0 by hand and 141 under P-011, from
# the same directory, the same second. To rehearse for real:
#     bash -c 'set -o pipefail; <your verification line>'
#
# NOTE THE MISSING `-e` — it is not a typo (T-3203). This file used to prescribe
# `set -eo pipefail` here, which is NOT the gate: it adds errexit the gate does
# not have, so it FAILS lines the gate PASSES. Measured, 10 lines, 3 diverged:
#     line                            gate    set -eo (old)   set -o (this)
#     false; true                     PASS    FAIL  wrong     PASS  ok
#     cd /nonexistent; echo ok        PASS    FAIL  wrong     PASS  ok
#     grep -q MISS file; true         PASS    FAIL  wrong     PASS  ok
# The divergence is one-directional and that is the trap: the old rehearsal only
# ever fails lines the gate accepts, so it produces false REDS, and an author
# who "fixes" a line to satisfy it is fixing something that was never broken —
# while the line that actually is broken (`cmd1; cmd2` where cmd1 fails) passes
# both. Re-derive rather than trust this table — it is pinned, not asserted:
#     bats tests/unit/t3203_p011_gate_semantics.bats
#
# ── `cmd1; cmd2` IS JUDGED ONLY ON cmd2 (T-3203) ──────────────────────────────
#
# The gate runs each line as the CONDITION of an `if` (update-task.sh:1215), and
# POSIX suppresses errexit for a compound command in an `if` condition — through
# the subshell. So pipefail applies and `set -e` does not, and in a sequence only
# the LAST command's status reaches the verdict. `cd /nonexistent; echo ok` passes.
# 2,644 of 10,997 verification lines in this corpus contain `;` (re-derive with
# the query in docs/reports/T-3203-p011-gate-semantics.md).
#
# SAFE SHAPES — both verified biting, each against a passing control:
#   A. one command whose own status is the verdict (prefer this):
#        out=$(cmd 2>&1); echo "$out" | grep -q PAT && ! echo "$out" | grep -q BAD
#      the leading assignments are setup; the trailing `&&` chain is the verdict.
#   B. an explicit sub-shell, whose errexit the outer `if` cannot reach into:
#        bash -c 'set -eo pipefail; cmd1; cmd2'
#      use when you genuinely need every command in the sequence to count.
#
# The rule of thumb: put the assertion LAST, and make sure it is an assertion.
#
# Enforcement-baseline hint (L-398, T-1886): if you edited `.claude/settings.json`
# (added/removed/reorganised hooks), add `bin/fw enforcement baseline` to your
# Verification block. Otherwise the canonical hash diverges and `fw doctor`
# reports a FAIL ("Enforcement baseline CHANGED") that accumulates silently.
# Origin: T-1849/T-1730/T-1731 each added a legitimate hook without refreshing
# the baseline — FAIL sat for multiple sessions until T-1886 cleaned up.

# ── T-904 ─────────────────────────────────────────────────────────────────────
# The differential teeth: C1 unmutated-copy-clean (the guard is green on clean
# source), C2 stripper-handles-literals (6 cases), D1 false-green-killed,
# D2 false-red-killed. Each D leg runs the SAME mutant twice — shipped guard vs
# a mechanically un-stripped copy — and FAILS if the two agree, so a vacuous
# differential cannot read as a kill. Covers AC1, AC2, AC3.
bash tools/_t904-denominator-comment-blindness-teeth.sh

# AC4 regression: the T-889 control+mutation set, run against the fixed guard AND
# the comment that now spells the accessor. 9 legs including C4 (the control on
# the order control). Before T-904 the M1 leg was GREEN with this comment present.
bash tools/_t889-authority-on-the-element-teeth.sh --mutation

# AC1 structural: both derivation reads go through the stripper. Two separate call
# sites — the function-body slice and the whole-file EVENT_BINDING_FIELD read.
grep -q "const body = stripJsComments(html.slice" tools/_roundtrip-serialization-cdp.mjs
# The EVENT_BINDING_FIELD read is stripped PER LINE and requires exactly one survivor. It is NOT
# a whole-file strip: that form ate 61% of the HTML (see ## Evolution) and this line asserted it
# until the gate caught the staleness. The `!= 1` guard is the load-bearing half — without it the
# read silently takes the first regex match, which is what a commented-out copy would give.
grep -q ".map(l => stripJsComments(l))" tools/_roundtrip-serialization-cdp.mjs
grep -q "expected exactly 1 live EVENT_BINDING_FIELD declaration" tools/_roundtrip-serialization-cdp.mjs
# The absence of the whole-file form is asserted POSITIVELY, not by negation. Two `! grep` legs
# stood here and the T-560 absence census refused the close: nothing established that either
# pattern could have matched, so a typo in the pattern and a satisfied assertion produce the
# identical green. Correct refusal. The positive legs above pin the narrow read (the per-line map
# AND the exactly-one-survivor guard, which is the load-bearing half), and teeth C3 proves the
# narrow read returns the live values while recording that a whole-file strip IS destructive.
# That is strictly stronger evidence than "the old string is gone".
# T-907: prose must stay OUT of the metaKeys array literal — an apostrophe inside it reads as a
# key to the parity checker. This asserts the parity checker itself is green.
python3 tests/test_editor_bridge_meta_parity.py

# AC5: the accessor the T-889 workaround comment refused to spell is now spelled in prose —
# which is exactly the fixture AC2's mutation leg runs against. Asserted positively for the
# T-560 reason above: what matters is that the accessor IS named and the leg STILL bites (teeth
# D1), not that a particular old sentence is gone. No pipes (L-387): grep's status is the verdict.
grep -q "node.aef.authority could only ever have come from the source document" src/aef-workflow-designer.html
# T-907 guard rail: the explanation for keeping prose OUT of the metaKeys literal must stay with
# the code, or the next author re-adds an apostrophe and the parity checker blames the bridge.
grep -q "THIS COMMENT SITS OUTSIDE THE metaKeys LITERAL DELIBERATELY" src/aef-workflow-designer.html

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

### 2026-09-27 — my own fix reintroduced the class it was fixing, one level over

- **What changed:** The first cut applied `stripJsComments()` to the WHOLE of `SRC_HTML` to find
  `EVENT_BINDING_FIELD`. `SRC_HTML` is an HTML document; `stripJsComments` is a JS stripper.
  Measured: it took the file from **1,013,174 to 393,293 bytes — 61% eaten**, because CSS `/* */`
  blocks and apostrophes in prose desync a JS quote scanner. The derived `bindFields` came back
  `["errorStatus","timerSpec","busTopic"]`, identical to the live literal — so every check was
  green and the guard passed. It was **luck, not correctness**: the declaration happened to sit
  outside the mangled regions. Had it not, `bindFields` would have come back short, those keys
  would have shown as `specNotProjected`, and the guard would have gone red for a reason having
  nothing to do with the emitter.
- **Why it is worth writing down:** the whole point of this task is that a check can be *green for
  a reason unrelated to the thing it claims to check*. I wrote a fix whose green was exactly that.
  It was caught by asking "does the value survive?" rather than "is the suite green?" — the only
  question that separates the two. The byte count is what exposed it; the value comparison alone
  said IDENTICAL and would have let it ship.
- **Plan impact:** the `EVENT_BINDING_FIELD` read is now narrow — strip candidate LINES, then
  require **exactly one** surviving declaration. That is strictly stronger than the original
  whole-file read: a commented-out copy strips to nothing and drops out, and zero / two / a
  multi-line literal all fail loud instead of silently taking the first regex match. The
  function-body slice is unchanged (pure JS, correct to strip wholesale).
- **Triggered:** teeth control **C3 bindfields-read-is-narrow**, which pins both properties — the
  narrow read equals the live literal, AND a whole-file strip is measurably destructive — so the
  wrong approach cannot be reintroduced as an apparently-harmless simplification. C3 also prints a
  NOTE if a whole-file strip ever stops being destructive, rather than passing on a stale premise.

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

## Recommendation

<!-- T-2945: same shape as inception.md's block — the gate that reads it
     (audit_inception_recommendation, lib/task-audit.sh:117) is shared, so the
     shape is copied rather than reinvented.

     REQUIRED once this task reaches partial-complete: Agent ACs done, at least
     one `### Human` AC still unticked. `lib/review.sh:205-211` (T-2421) BLOCKS
     `fw task review` emission for build/refactor/test/decommission tasks in that
     state with no substantive block here — the operator would otherwise open
     /review/<id> to a blank Recommendation card and be asked to approve a form.

     Not required while every Human AC is ticked or the task has none: the gate
     only fires on the partial-complete transition. It is here from the start so
     you write it while you still have the evidence, not when the gate refuses.

     Format (the parser wants the `**Recommendation:**` line at the start of a
     line; a leading `-` or `*` bullet is also accepted):
     **Recommendation:** GO / NO-GO / DEFER
     **Rationale:** Why (cite evidence — what shipped, what was proven, what remains)
     **Evidence:**
     - Finding 1
     - Finding 2

     DEFER is for evidence gaps, not confidence gaps (CLAUDE.md §Presenting Work
     for Human Review). If the artefact is complete and you still don't want to
     commit, that is a calibration failure — recommend GO or NO-GO.
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

### 2026-09-27T14:09:54Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-904-the-round-trip-guards-denominator-reads-.md
- **Context:** Initial task creation

### 2026-09-27T14:20:55Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

## Reviewer Verdict (v1.5)

- **Scan ID:** R-396f1cf4
- **Timestamp:** 2026-09-27T15:17:02Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-09-27T15:16:48Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
