---
id: T-544
name: "Watchtower session cookie is named for the DEFAULT port, not the bound one, so two instances on one host destroy each other's sessions"
description: >
  app.py sets SESSION_COOKIE_NAME = f'fw_session_{Config.PORT}' to stop two Watchtowers on one host sharing a cookie (RFC 6265 does not scope cookies by port). Config.PORT reads FW_PORT or defaults to 3000; the --port CLI flag sets only the local variable passed to app.run() and never updates Config.PORT. So this project's instance on :3012 and AEF's on :3000 BOTH emit fw_session_3000 for the same host, each overwriting the other, and each signs with its own .fw-secret-key so the other cannot even decode it — session is silently empty, session.get('_csrf_token') is None, every state-changing POST 403s as 'Session expired'. Operator hit this clicking Approve on /approvals. The port suffix is the exact defence that fails.

status: work-completed
workflow_type: build
owner: agent
horizon: null
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-16T14:45:03Z
last_update: 2026-08-16T15:17:03Z
date_finished: 2026-08-16T15:17:03Z
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

# T-544: Watchtower session cookie is named for the DEFAULT port, not the bound one, so two instances on one host destroy each other's sessions

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] The session cookie name is derived from the port the server ACTUALLY
      binds, not from `Config.PORT` — verified by observing `Set-Cookie` on
      the running :3012 instance name itself `fw_session_3012`
- [x] The two instances on this host emit DIFFERENT cookie names, so neither
      can overwrite the other (measured against both :3000 and :3012)
- [x] `FW_PORT` and the `--port` flag agree — setting either produces the same
      cookie name, and neither silently wins over the other
- [x] A probe asserts the property that a server bound to port N names its
      cookie for N, wired into `tests/run-bridge-tests.sh`, and it goes red
      against a build that reads the default instead
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

# Boots a real instance on a real non-default port and reads the real Set-Cookie.
# rc 2 is a REFUSAL (never answered / set no cookie), not a pass.
python3 tools/_t544-session-cookie-port-teeth.py
# Vendored divergence declared (G-008) — app.py is AEF's code and this bug is AEF's too.
python3 tools/_t517-vendor-divergence.py

## RCA

**Symptom:** Operator clicked Approve on `/approvals` and got a page reading
"Session expired — Workflow designer" followed by raw JavaScript text. The page
had just been loaded and Watchtower had been up 2d03h with no restart, so
nothing had in fact expired. Reproduced with a CSRF-less POST: HTTP 403,
`Content-Type: text/html`, 67632 bytes. The JS the operator saw is literally
`base.html` line 12 (the `<title>`) followed by line 14 (the theme bootstrap
script) — the top of that document, surfaced as text because the Approve control
is an htmx POST and the 403 handler answers `/api/*` with a full HTML page.

**Root cause:** `web/app.py` sets `SESSION_COOKIE_NAME = f"fw_session_{Config.PORT}"`.
That line exists (T-2278) precisely because RFC 6265 does not scope cookies by
port, so two Watchtowers on one host otherwise share one cookie slot and
overwrite each other. `Config.PORT` reads `FW_PORT` or falls back to 3000, and
the `--port` CLI flag never updates it — `--port` moves the listening socket and
nothing else. `create_app()` also runs at module import, before argparse exists.
Measured, not inferred: AEF's Watchtower on :3000 and this project's on :3012
BOTH emitted `fw_session_3000`. Because each signs with its own
`.fw-secret-key`, neither could even decode the other's cookie, so `session`
came back empty, `session.get("_csrf_token")` was None, and every
state-changing POST 403'd.

**Why structurally allowed:** the guard against this failure was itself the
thing that failed, and it failed by naming the wrong port. That is worse than
having no guard at all — it reads as protection in code review *and* in its own
explanatory comment, so every subsequent reader confirms the defence is present
without checking which port it names. Nothing anywhere asserted the relationship
between the port bound and the cookie emitted; the property is about a live
socket, so no static check of the source could have established it. The defect
WAS source that looked correct. Compounding it, the failure surfaces to the user
as "Session expired" — a message that names a cause that did not occur and sends
the reader toward re-authentication rather than toward collision.

**Prevention:** `tools/_t544-session-cookie-port-teeth.py`, wired into
`tests/run-bridge-tests.sh`. It boots a real instance on a real, deliberately
non-default port with `FW_PORT` unset and reads the actual `Set-Cookie`, because
that is the only way to observe the property. Leg 0 REFUSES (rc 2, not a pass)
if the discrimination it relies on ever collapses — if `Config.PORT`'s fallback
stops being 3000, if the OS hands out 3000, or if `SESSION_COOKIE_NAME`
disappears entirely. Leg 2 is separated from leg 1 so the report distinguishes
"named something else" from "fell back to the default", the latter being the
regression with the known blast radius. Mutation-verified rather than asserted:
reverting the fix makes it emit `fw_session_3000` on a port in the 57000s and
both legs go red naming the collision consequence.

**Not fixed here, deliberately:** the 403 handler returning 67KB of HTML to a
JSON/htmx client is a second, independent defect with its own root cause. One
bug, one task — filed separately rather than folded in.

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

### 2026-08-16T14:45:03Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-544-watchtower-session-cookie-is-named-for-t.md
- **Context:** Initial task creation

### 2026-08-16T14:45:15Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

## Reviewer Verdict (v1.5)

- **Scan ID:** R-73583b71
- **Timestamp:** 2026-08-16T15:17:16Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-16T15:17:03Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
