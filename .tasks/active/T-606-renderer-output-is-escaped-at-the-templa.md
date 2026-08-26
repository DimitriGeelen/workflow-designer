---
id: T-606
name: "Renderer output is escaped at the template: /approvals and /tasks show markdown as literal HTML entities"
description: >
  Renderer output is escaped at the template: /approvals and /tasks show markdown as literal HTML entities

status: work-completed
workflow_type: build
owner: human
horizon: now
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-26T20:49:45Z
last_update: 2026-08-26T21:03:25Z
date_finished: 2026-08-26T21:03:25Z
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

# T-606: Renderer output is escaped at the template: /approvals and /tasks show markdown as literal HTML entities

## Context

OBS-318. The `/approvals` page — the operator decision surface this session prints a link
to every turn — renders acceptance-criteria markdown as literal escaped text. Measured on
our own instance before the fix: **205 escaped `&lt;code&gt;` against 2 real `<code>`, plus
78 escaped `&lt;strong&gt;` and 73 escaped `&lt;a href`**. The operator has been reading
mangled ACs while making the sovereignty calls this session asks for.

Reported by 010-termlink at rail 563 with a recommended one-line fix at the definition
site: make `web/shared.py render_markdown_safe()` return `markupsafe.Markup(html)` so no
caller can forget `| safe`. **That fix is correct and would not have fixed our page.** The
AC fields on `/approvals` are not produced by `render_markdown_safe` at all — they come
from `_render_md_inline()` / `_render_md_block()` at `web/blueprints/tasks.py:384,363`, a
second blueprint-private renderer pair carrying the same unstated caller obligation.
`render_markdown_safe`'s own docstring says it was promoted out of `tasks.py` specifically
to "break the blueprint-private parser pattern called out in the T-1575 RCA" — the
promotion happened and the private renderers survived beside it. Two definitions of one
contract, and a docstring asserting there is one.

Scope correction found while measuring: this is **not** an `/approvals`-only defect.
`_review_acs.html` marks `| safe` and is clean; `_approvals_content.html:575,580,583` and
`task_detail.html:507,513,517` do not. My first sample (`/tasks/T-604`) measured clean and
would have hidden the second consumer — that task's ACs simply had nothing to render. An
unrepresentative sample producing a false negative is the OBS-316 shape again, so the
prediction was tested against tasks with rich ACs: `/tasks/T-347` = 13 escaped, `T-597` = 9.

Vendored under `.agentic-framework/` — G-008 permits the in-tree fix and upstream.

## Acceptance Criteria

### Agent
- [x] Definition site, not call site: `_render_md_inline` and `_render_md_block`
      (`blueprints/tasks.py`) and `render_markdown_safe` (`shared.py`) each return
      `markupsafe.Markup`, so escaping-correctness is a property of the renderer rather
      than an obligation every future template author must remember. The T-569
      degradation path (markdown2 missing) returns Markup-wrapped *escaped* text — the
      fallback must keep escaping, not inherit the safety of the happy path.
- [x] `/approvals` serves **zero** escaped `&lt;code&gt;` and `&lt;strong&gt;` with a
      non-zero count of real `<code>` — asserting the bytes an operator's browser
      receives, not what the renderer believes it produced.
- [x] The second, latent consumer is fixed in the same pass: `/tasks/T-347` and
      `/tasks/T-597` serve zero escaped `&lt;code&gt;`/`&lt;strong&gt;`, non-zero real.
- [x] **Security leg — the reason this was not attempted last session.** A task body
      containing raw `<script>`, `<img onerror=>` and a javascript: URL still reaches the
      page ESCAPED. Marking a field `| safe` that is not renderer output would open XSS in
      the operator's own console; this AC proves the change did the opposite.
- [x] Control: `/review/T-597`, which rendered correctly BEFORE the change, is
      unchanged by it — 0 escaped / 15 real `<code>` on both sides, and it stays GREEN
      under the two poison arms that redden `/approvals` and `/tasks`. That
      insensitivity is the evidence; literal byte-identity is not claimed and is not
      obtainable (the CSRF token differs per request).
- [x] `tools/_t606-render-escaping.py` is a real verifier: three arms — unwrap Markup in
      `_render_md_inline` (reddens L2/L3), in `_render_md_block` (reddens L2/L3), and
      disable `safe_mode='escape'` (reddens the SECURITY leg L4) — each restore the whole
      pre-fix state, verified by sha256 before and after. Arms are scoped per FUNCTION,
      not by literal needle: the two renderers end in byte-identical lines, so a literal
      patch would poison both and prove neither. The first run caught this itself and
      reported SKIP rather than a false PROVEN.
- [x] `ac.text` is checked and dispositioned explicitly rather than silently: it is raw
      task-file markdown that reaches six templates unrendered, which is a DIFFERENT root
      cause from this one and is registered as its own observation, not folded in here.

### Human

I first wrote "None" here, arguing the operator is the subject of this change rather than a
reviewer of it. The P-013 gate (T-1766) rejected that, and it was right: three render fixes
have shipped on tests alone before, and "the counts are zero" is not the same claim as "this
reads correctly". The judgement below is real, and it is the one I cannot make for you.

- [ ] [REVIEW] The approvals surface now reads the way it was written — and you rule on the
      one thing I deliberately did not fix
  **Steps:**
  1. Open http://192.168.10.107:3013/approvals
  2. Look at any card's **Steps** / **Expected** block. Commands should appear as inline
     code, emphasis as bold, task refs as links — not as `&lt;code&gt;` text.
  3. Now look at the AC *headline* line (the bold sentence beside the Review badge) on the
     T-449 and T-575 cards. Some still show literal `**asterisks**` and `backticks`.
     That is OBS-319: a DIFFERENT defect — that field is raw task-file text that never
     reaches a renderer, so fixing it means rendering it, and explicitly NOT marking it
     safe. I kept it out of this task to keep one root cause per task.
  4. Decide: fix OBS-319 next, or leave headlines as plain text deliberately.
  **Expected:** Steps/Expected blocks render as markup; you record a call on OBS-319.
  **If not:** If any block still shows `&lt;code&gt;`, the running Watchtower predates the
  fix — restart it with
  `.agentic-framework/bin/fw serve --port 3013` and recheck.

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


# 1. Full verifier: 6 legs on served content + 3 poison arms, each restoring the tree.
timeout 420 python3 tools/_t606-render-escaping.py
# 2. Independent of the verifier's own harness: what the operator's browser receives.
#    Fails closed if curl fails (&&), and requires REAL <code> present so an empty or
#    error page cannot pass by merely lacking the escaped form.
cd /opt/832-Workflow-designer && curl -sf --max-time 30 "$(cat .context/working/watchtower.url)/approvals" > /tmp/t606-approvals.html && grep -q "<code>" /tmp/t606-approvals.html && ! grep -q "&lt;code&gt;" /tmp/t606-approvals.html
# 3. The second consumer, on an AC-rich task (T-604 has nothing to render and measures
#    clean either way — sampling it is how this defect stayed hidden).
cd /opt/832-Workflow-designer && curl -sf --max-time 30 "$(cat .context/working/watchtower.url)/tasks/T-347" > /tmp/t606-task.html && grep -q "<code>" /tmp/t606-task.html && ! grep -q "&lt;code&gt;" /tmp/t606-task.html
# 4. Security direction: hostile task-file HTML must still arrive escaped.
cd /opt/832-Workflow-designer/.agentic-framework && python3 -c "import sys; sys.path.insert(0,'.'); from web.shared import render_markdown_safe as r; h=str(r('<script>alert(1)</script>')); assert '<script>' not in h and '&lt;script&gt;' in h, h; print('escaped')"

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


**Symptom:** `/approvals` — the operator decision surface this session links every turn —
served 205 escaped `&lt;code&gt;` against 2 real `<code>`, plus 78 escaped `&lt;strong&gt;`
and 73 escaped `&lt;a href`. `/tasks/T-XXX` carried the same defect. The operator has been
reading mangled acceptance criteria while making sovereignty calls on them.

**Root cause:** all three markdown renderers returned a plain `str` while their own
docstrings placed the escaping obligation on the caller — "the caller must mark returned
strings safe". Correctness lived in each template author's memory instead of in the value.
Two of the four AC templates forgot, so Jinja autoescaped renderer output into entities.

**Why structurally allowed:**
1. **The contract had two definitions.** `render_markdown_safe` was promoted into
   `shared.py` specifically, per its own docstring, "to break the blueprint-private parser
   pattern called out in the T-1575 RCA". The promotion happened; the private pair
   `_render_md_inline`/`_render_md_block` survived beside it. So a correct fix at one
   definition is invisible at the other — which is exactly what 010-termlink's
   recommendation would have hit. A contract with two definitions is one definition and
   one impostor, and the impostor is where the bug lives.
2. **Nothing asserted served content.** Every existing check looked at what a renderer
   RETURNS. No test looked at what a page SERVES, and the gap between those two is the
   entire defect — the renderer was always right.
3. **The failure rendered as health.** An escaped page is HTTP 200, correctly laid out,
   and reads as a page with oddly-typed criteria. There is no error to notice.

**Prevention:** `tools/_t606-render-escaping.py` asserts the bytes both consumer pages
serve (not the renderers' return values), on AC-rich tasks chosen because the obvious
sample measures clean over a broken page. Three poison arms prove each leg can go red,
scoped per-function because the two renderers end in byte-identical lines and a literal
needle would silently poison both. Leg L4b statically forbids `ac.text | safe` — the
tempting fix that would have converted this cosmetic defect into stored XSS.

## Visual Verification

DOM counts confirm geometry, not rendering, so both consumers were screenshotted at
element level and read (CLAUDE.md §Visual Verification for UI Changes):

- `docs/reports/T-606-evidence/t606-approvals-after.png` — /approvals, T-449 card:
  `<code>` spans, bold `(a)/(b)/(c)` and the T-2553 / fixture-path links all render as
  markup. No entities visible.
- `docs/reports/T-606-evidence/t606-tasks-after.png` — /tasks/T-347 human-AC block:
  code spans, bold, and `docs/reports/...` / T-259 / T-337 links render.

Both were read back with the Read tool, not assumed from the fact that a screenshot was
taken. The accessibility tree on /approvals independently shows `code` nodes inside the
Steps list items where escaped text stood before — and, separately, shows `ac.text` still
carrying literal `**` and backticks, which is the distinct defect registered as OBS-319
rather than folded in here.

## Recommendation

**Recommendation:** GO

**Rationale:** The defect and the fix are both measured, not argued. `/approvals` went from
205 escaped `&lt;code&gt;` / 2 real to 0 / 207 — and the arithmetic closes exactly, which is
what tells you the 205 became markup rather than disappearing. The same closure holds on the
second consumer (`/tasks/T-347` 13 escaped, 23 real → 0 / 36; `T-597` 9 / 8 → 0 / 17). The
change is two files and adds no new rendering behaviour: `markdown2 safe_mode='escape'`
still neutralises hostile task-file HTML, and the security leg proves it with an arm that
can actually turn red. The one judgement I could not make for you is in the Human AC: some
AC *headlines* still show literal markdown, which is a different defect (OBS-319) with the
opposite fix direction, and I kept it separate rather than bundling it.

**Evidence:**
- `tools/_t606-render-escaping.py` — PASS, 6/6 live legs, 3/3 arms proven failable, each
  arm restored (sha256-verified). Arms are function-scoped; the first run reported SKIP
  rather than a false PROVEN when a literal needle would have poisoned both renderers.
- P-011 gate: 4/4 verification commands passed, including two that assert served bytes
  independently of the verifier's own harness.
- `docs/reports/T-606-evidence/*.png` — element screenshots of both consumers, read back.
- Scope was cut, not grown: template `| safe` edits were made, then measured as REDUNDANT
  with the definition-site fix in place and reverted. Landed diff is `web/shared.py` and
  `web/blueprints/tasks.py` only.
- Correction worth flagging: 010-termlink's recommended one-line fix (rail 563) is correct
  and would NOT have fixed this page — the AC fields never reach that renderer. Warned
  them at rail 564 before they ship.

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

### 2026-08-26T20:49:45Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-606-renderer-output-is-escaped-at-the-templa.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-33c66305
- **Timestamp:** 2026-08-26T21:03:51Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-26T21:03:25Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
