---
id: T-545
name: "The 403 handler answers /api/ htmx clients with a 67KB HTML page, so a CSRF failure renders as raw markup inside the caller's page"
description: >
  The 403 handler answers /api/ htmx clients with a 67KB HTML page, so a CSRF failure renders as raw markup inside the caller's page

status: started-work
workflow_type: build
owner: agent
horizon: now
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-16T15:17:24Z
last_update: 2026-08-16T15:17:24Z
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

# T-545: The 403 handler answers /api/ htmx clients with a 67KB HTML page, so a CSRF failure renders as raw markup inside the caller's page

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] A 403 on an `/api/*` path returns a compact machine-readable body, not a
      rendered page — measured by response size and `Content-Type`, with the
      pre-fix size named in the probe so the improvement is a measurement
      rather than an assertion. (The probe pins 66456 bytes — today's
      reproduction. The 67632 recorded on T-544 was the same defect measured
      against a different page state a session earlier; both are the document,
      neither is a fragment.)
- [x] The body a failing Approve produces, run through `htmx-toast.js`'s actual
      extraction expression, yields an actionable sentence — specifically it
      contains no `<script>` or `<title>` text and no JavaScript source. This is
      the operator-visible symptom and is checked against the real regex from
      the shipped file, not a re-typed copy of it
- [x] A 403 on a normal page navigation still renders the full T-2309 "Session
      expired" page with its Reload button — the friendly-recovery path added by
      T-2309 is not traded away to fix the API path
- [x] The CSRF-vs-generic-403 distinction T-2309 introduced survives on BOTH
      branches: an API client can still tell a stale token from a real
      permission denial
- [x] A probe asserts all of the above, is wired into `tests/run-bridge-tests.sh`,
      and is mutation-verified — reverting the handler change must turn it red
      with the operator-visible symptom named, not merely a size assertion
- [x] The divergence is declared in `.agentic-framework/.vendor-divergence.yaml`
      (G-008) — this is vendored AEF code and the bug is AEF's too

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

# Pins the SHAPE and the CONSEQUENCE: a fragment, and what htmx-toast.js's own
# extraction expression produces from it. rc 2 is a REFUSAL (app would not import,
# or the stimulus could not be established), not a pass.
python3 tools/_t545-error-shape-teeth.py
# Vendored divergence declared (G-008) — app.py is AEF's code and this bug is AEF's too.
python3 tools/_t517-vendor-divergence.py

## RCA

**Symptom:** clicking Approve on `/approvals` produced a toast reading
`Session expired — Workflow designer (function(){var t=localStorage.getItem('wt-theme');`
— a page title followed by raw JavaScript source, in place of an error message.

**Root cause:** the 403 handler chose its response body by *why* the request
failed and never by *who was asking*. T-2309 split CSRF failures from generic
403s — a real improvement — but both branches render `_wrapper.html`, which
extends `base.html` and is therefore always a complete HTML document. An
`hx-post` to `/api/bvp/driver/approve`, whose target is a `<div>`, received
66456 bytes of document.

**The mechanism, measured — and it is not the one T-544 recorded.** T-544's
note assumed the browser rendered that document into the page. It did not.
htmx 2.0.4 ships `responseHandling: [{code:"204",swap:false},
{code:"[23]..",swap:true},{code:"[45]..",swap:false,error:true}]` — a 4xx is
**never** swapped. The body reached only `web/static/htmx-toast.js`, whose
`htmx:responseError` listener builds its message with
`.replace(/<[^>]*>/g,'').trim().substring(0,100)`. That is a **tag** stripper,
not a text extractor: it removes `<title>` and `<script>` *tags* and keeps the
text *inside* them. Reproduced byte-for-byte against the running instance. The
lines T-544 identified were right; the reason they reached the operator was not,
and the difference matters because the earlier framing pointed at the swap path
rather than at the handler.

**Why structurally allowed:** nothing in the request pipeline distinguished a
document consumer from a fragment consumer, so "render the error" had exactly
one meaning. The failure was then *invisible in the only place anyone looks* —
the server logged a correct 403, the handler was correct, the template was
correct, and the corruption happened in a client-side regex written for a
different kind of body. Two components each behaving reasonably produced
JavaScript source in an error toast.

**Prevention:** `tools/_t545-error-shape-teeth.py`, wired into
`tests/run-bridge-tests.sh`. It pins two properties rather than one, because
fixing either alone leaves the defect: the **shape** (a fragment, no `<html>`)
and the **consequence** (running the shipped toast expression over the body
yields no script source). The consequence leg reads the real regex out of
`htmx-toast.js` rather than re-typing it, so it cannot keep passing after the
real one changes. Leg 6 re-reads htmx's `responseHandling` default every run,
because the entire design rests on 4xx never being swapped and a library
upgrade could retire that silently. Mutation-verified against three mutants —
removing the branch reproduces the operator's string verbatim.

**The first draft of the fix was wrong, and measuring the corpus is what caught
it.** It exempted `HX-Boosted` requests, reasoning that `base.html` sets
`hx-boost="true"` on `<body>` so ordinary navigation also carries `HX-Request`,
and that exempting boosts protected T-2309's full-page Reload UI. But five
routes post a plain `<form method="post">` under that boost
(`/arcs/*/close`, `/assumptions/*/resolve`, `/inception/*/decide`,
`/inception/*/add-assumption`, `/review/*/pause/*/resolve`) — boosted POSTs,
which the exemption would have left carrying the exact defect this task exists
to remove. The library's own default settled it: since htmx never swaps a 4xx,
the full page is never *displayed* for any htmx request, only scraped. T-2309's
page stays reachable by the one thing that displays it — a genuine non-htmx
navigation. Leg 5 is the anti-regression for that reasoning, not for the code.

**Not fixed here, reported instead:** `htmx-toast.js`'s tag-stripping regex is a
separate defect with its own root cause, latent for any HTML body from any
endpoint — a 500 on a non-API route still feeds it a document. The remedy is a
choice about AEF's client contract, not ours.

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

### 2026-08-16T15:17:24Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-545-the-403-handler-answers-api-htmx-clients.md
- **Context:** Initial task creation
