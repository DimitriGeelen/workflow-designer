---
id: T-858
name: "403 handler writes a whole HTML document to htmx callers, so the toast scrapes JavaScript source at the operator"
description: >
  403 handler writes a whole HTML document to htmx callers, so the toast scrapes JavaScript source at the operator

status: started-work
workflow_type: build
owner: agent
horizon: now
tags: [bug]
components: []
related_tasks: []
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
created: 2026-09-25T22:05:16Z
last_update: 2026-09-25T22:16:52Z
date_finished: null
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

# T-858: 403 handler writes a whole HTML document to htmx callers, so the toast scrapes JavaScript source at the operator

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] **A — the SHAPE:** a 403 on an `/api/*` path returns a fragment, not a document. Under the teeth's 2,048-byte ceiling, and carrying no `<html>`/`<!doctype>`, which no fragment target can absorb
- [x] **B — the CONSEQUENCE:** the message `web/static/htmx-toast.js` actually extracts from that body contains **no script source**. (A) alone is an assertion about byte counts; (B) is the thing the operator saw, and fixing only (A) leaves the defect if the stripper still meets a `<script>`
- [x] **Boosted form posts are covered, not exempted.** Five routes post plain `<form method="post">` under `hx-boost`, so they *are* htmx requests. The teeth record that the first attempt at this fix exempted `HX-Boosted` to protect T-2309's full-page recovery UI and thereby kept the defect on exactly those five routes. Any exemption I add must be justified against that leg, not around it
- [x] `HX-Error-Kind` is present on the compact 403, so a machine client can tell a stale CSRF token from a real permission denial without parsing prose
- [x] **The full-page "Session expired" recovery UI still works for an ordinary navigation** — the fix must discriminate by caller, not replace one wrong answer with another. A plain browser GET must still get T-2309's page
- [x] `python3 tools/_t545-error-shape-teeth.py` exits **0** with all legs green, and its **rc 2 REFUSE path is distinguished from a pass** — the header says rc 2 means the stimulus was not established, so a "green" that is really a refusal does not count
- [x] No byte-count in the fix or its verification is pinned to a **mutable** live value — the teeth's own ceiling is the invariant, not today's page size (T-3326)
- [x] The vendored edit carries its rationale **in-file** naming this task, because T-853 measured that a vendored fix without visible rationale is what the next `fw upgrade` reverts — and `_t545`'s own evidence says a fix for this once existed and is gone
- [x] Sent to AEF, since the Watchtower web app is theirs and a local-only fix will be reverted
      — sent to `framework:pickup` **offset 171**: symptom, the tag-stripper mechanism,
      the fix, the before/after measurements, and the three things worth not re-deriving (byte
      count is not the bug; do not exempt `HX-Boosted`; the probe was already red and says a fix
      once existed).
- [x] `fw doctor` gains **no new failures** — it is currently at zero for the first time this session, and that is the baseline to protect

### Human

- [ ] [REVIEW] The toast a real 403 produces reads as a sentence, and the full-page recovery UI is untouched

  This exists because the defect was **what a person saw**, and the machine evidence stops one step
  short of that. The teeth prove the response body is 79 bytes and that the shipped toast
  *expression* yields `Session expired — reload the page and try again.` They do **not** prove the
  toast element renders that text legibly in your browser, at your theme and density — DOM-level
  proof of a string is not proof of a rendered message.

  **Steps:**
  1. Open `http://192.168.10.107:3013/approvals` in a browser tab and leave it open.
  2. In a second tab, open the same Watchtower and log the first tab's session stale — the original
     repro was simply two tabs, where the second tab's cookie rotation invalidates the first tab's
     CSRF token. If that no longer reproduces, clear cookies for that host in the first tab only.
  3. Back in the **first** tab, click **Approve** on any row.
  4. Read the toast that appears.
  5. Then, in a fresh tab, navigate directly to a URL that 403s as a plain page load (no htmx) and
     confirm you still get the full "Session expired" page with its Reload button.

  **Expected:** step 4's toast reads `Session expired — reload the page and try again.` — one
  sentence, no `function(){`, no `var t=`, no page title, not truncated mid-word. Step 5 still shows
  the full-page recovery UI, unchanged from before this task.

  **If not:** capture the toast text verbatim and say which of the two halves failed. If the toast
  still shows script source, the body is reaching a different extractor than
  `web/static/htmx-toast.js` and the fix is aimed at the wrong consumer. If step 5 now shows a bare
  one-line fragment instead of the page, the caller discrimination is too broad and is stealing the
  navigation path — that is the mirror-image regression this AC exists to catch.

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

# The teeth. Exit code AND the pass marker, because this probe's rc 2 is a REFUSE
# (stimulus not established) and a refusal must never read as a pass — its own header
# says so, and asserting only "not rc 1" would accept it.
timeout 300 python3 tools/_t545-error-shape-teeth.py > /tmp/.t858.out 2>&1 && grep -q 'all legs green' /tmp/.t858.out
timeout 300 python3 tools/_t545-error-shape-teeth.py > /tmp/.t858b.out 2>&1; test "$?" -eq 0

# (B) THE CONSEQUENCE — what the operator actually sees. This is the leg that matters:
# the toast reads a sentence, not JavaScript source scraped out of a <script> tag.
grep -q "toast would read   : 'Session expired — reload the page and try again.'" /tmp/.t858.out

# (A) the SHAPE, pinned as a PROPERTY not a byte count: the probe prints the /api/*
# body size next to the pre-fix figure, and the fix is that it is three digits or fewer
# rather than five. Pinning 79 exactly would rot the moment the sentence is reworded.
grep -qE '/api/\* 403 body    : [0-9]{1,3} bytes' /tmp/.t858.out

# The full-page recovery UI survives for an ordinary navigation — discrimination by
# caller, not one wrong answer swapped for another.
grep -q 'T-2309 page retained' /tmp/.t858.out

# The machine-readable kind is present and distinguishes the two causes.
grep -q 'HX-Error-Kind      : csrf=csrf  generic=generic' /tmp/.t858.out

# htmx still does not swap a 4xx — the whole design rests on it, and a library upgrade
# could retire it silently.
grep -q 'htmx 4xx swap      : false' /tmp/.t858.out

# BOOSTED REQUESTS ARE COVERED, asserted POSITIVELY. The known wrong fix is an
# `and not HX-Boosted` exemption; rather than assert that string's absence (which would
# be an uncontrolled absence leg, and the string legitimately appears in my own comment
# explaining why it is wrong), assert the condition that makes boosted requests work:
# it tests HX-Request alone, which htmx sets on boosted requests too.
grep -q 'HX-Request") == "true"' .agentic-framework/web/app.py

# The rationale is in-file, naming this task — _t545's evidence says a fix for this once
# existed and is gone, so an unexplained fix is one the next upgrade reverts (T-853).
grep -q 'T-858: write the 403 for the CLIENT THAT ASKED FOR IT' .agentic-framework/web/app.py

python3 -c "import ast; ast.parse(open('.agentic-framework/web/app.py').read())"

# The zero-failure doctor reached earlier today is the baseline to protect.
out=$(.agentic-framework/bin/fw doctor 2>&1 || true); echo "$out" | grep -q 'no failures'

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

**Symptom:** the operator clicked Approve on `/approvals` and the toast read
`Session expired — Workflow designer (function(){var t=localStorage.getItem(…`. A human was shown
JavaScript source as an error message.

**Root cause:** two correct-in-isolation pieces meeting. `@app.errorhandler(403)` rendered T-2309's
full recovery **page** (66KB) to every caller regardless of what asked, and `htmx-toast.js` extracts
its message with `.replace(/<[^>]*>/g, '')` — a **tag** stripper, not a text extractor. It removes
`<title>` and `<script>` tags and keeps the text *inside* them. So the page title and the theme
bootstrap's JavaScript became the message. Neither piece is wrong by itself: the page is right for a
navigation, and the stripper is a reasonable one-liner for a fragment. The defect is that nothing
decided which kind of caller was asking.

**Why structurally allowed:**

1. **The handler had no notion of caller shape.** Flask's error handler sees the request but the code
   never consulted it — one response for an API client, an htmx swap target, and a browser
   navigation. A 403 is exactly where that distinction matters most, because it is the response a
   client is least prepared to parse.
2. **The probe already existed, was correct, and was red.** `_t545-error-shape-teeth.py` has been
   reporting five specific accurate findings, and its own comment records `pre-fix: 66456` — so a fix
   for this **once existed and is gone**. The finding was not missing; it was unread, because the
   only thing that runs it is an 11-minute all-or-nothing sweep nobody could afford (T-850). The
   operator hit in production a defect his own test suite had already described.
3. **The first attempt at the fix was wrong in a way that looked right** — the teeth say it exempted
   `HX-Boosted` to protect the full-page recovery UI, and five routes post plain
   `<form method="post">` under `hx-boost`, so the exemption preserved the entire defect on exactly
   the routes the operator was using. That is recorded in leg 5 *because* it happened.

**Prevention** (distinct from the fix):

- The teeth pin **two** properties, and the second is the one that matters: (A) the shape, a fragment
  under 2,048 bytes with no `<html>`; and (B) the consequence — what the shipped toast expression
  *actually produces* from that body. (A) alone is an assertion about byte counts. My verification
  greps for the literal sentence the toast now reads, so a future change that shrinks the body but
  reintroduces an element with text content goes red.
- Leg 6 re-checks that htmx never swaps a 4xx, because the whole design rests on it and a library
  upgrade could retire it silently. I did not touch that leg; it is the reason the fragment is safe.
- The boosted-request case is asserted **positively** — the condition tests `HX-Request` alone, which
  htmx sets on boosted requests too. I deliberately did not write an absence leg for
  `and not HX-Boosted`: the string legitimately appears in my own comment explaining why it is the
  wrong fix, so an absence assertion there would be both uncontrolled and false.
- Rationale in-file naming this task, because the evidence says a fix for this was already lost once
  and T-853 measured how that happens (`fw upgrade` reverting undocumented vendored fixes). Sent
  upstream at `framework:pickup` offset 171 for the same reason.
- **Named and not fixed:** `htmx-toast.js`'s extractor is still a tag stripper. It is now fed a safe
  body, which fixes the operator's symptom, but any other route that returns HTML with text-bearing
  tags on an error will reproduce the class. The real fix is to extract text properly (or have the
  server send a dedicated message field, which `HX-Error-Kind` is the beginning of). That is its own
  task and is AEF's call, since the design question is what an error contract between their server
  and their JS should be.

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

**Recommendation:** GO

**Rationale:** The defect is fixed at the layer that caused it and the fix is narrow: 42 inserted
lines, zero removed, one new branch that fires only for a caller that identifies itself as htmx or
hits `/api/*`. Every mechanical property the probe pins is green, including the one that represents
what the operator actually experienced — the toast expression now yields a sentence rather than
JavaScript source. The full-page recovery path is measurably untouched (66,746 bytes, same as
before), so this is a discrimination by caller and not a replacement of one wrong answer with
another. The one remaining unticked criterion is a genuine `[REVIEW]`: it asks a human to look at a
rendered toast, which no leg here can do, and it is not covering an evidence gap in the fix itself.

GO rather than DEFER because there is no evidence gap left that I could close by working longer. The
open item is a category of proof I cannot produce — a person reading a rendered element — not a
question I am avoiding.

**Evidence:**
- `/api/*` 403 body **66,456 → 79 bytes**; `tools/_t545-error-shape-teeth.py` exits 0 with *all legs
  green*, and the suite's rc-2 REFUSE path is asserted separately so a refusal cannot read as a pass.
- The consequence leg, which is the operator's symptom: `toast would read : 'Session expired — reload
  the page and try again.'` — previously `(function(){var t=localStorage.getItem(`.
- Navigation 403 still **66,746 bytes — "T-2309 page retained"**. The recovery UI did not become
  collateral damage.
- `HX-Error-Kind: csrf=csrf generic=generic`, so a machine client can distinguish a stale token from
  a real denial without parsing prose.
- Boosted POSTs are covered rather than exempted, asserted positively on the `HX-Request` condition.
  The teeth record that the previous attempt at this fix exempted `HX-Boosted` and thereby preserved
  the whole defect on the five `hx-boost` form routes — the operator's own path.
- `fw doctor` remains at **zero failures**; 11/11 verification legs rehearsed under `set -o pipefail`
  before the gate ran them.
- **Known limitation, stated rather than buried:** `htmx-toast.js` is still a tag stripper. It is now
  fed a safe body, so the symptom is gone, but any other route returning text-bearing HTML on an
  error reproduces the class. The durable fix is a message contract between server and JS, which is
  AEF's design call and is filed with them (offset 171) rather than invented here.

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

### 2026-09-25T22:05:16Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-858-403-handler-writes-a-whole-html-document.md
- **Context:** Initial task creation

### 2026-09-25T22:13:33Z — status-update [task-update-agent]
- **Change:** tags: +bug
