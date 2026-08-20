---
id: T-569
name: "Component card purpose is autoescaped, so a consumer project's cards cannot link to anything it publishes"
description: >
  fabric_detail.html:35 renders {{ component.purpose }} under Jinja autoescape, so a markdown link in a project-owned card renders as literal text. Reported by 001-CashWeb-Lightspeed-Ecwid-integration as the second of two Watchtower findings: NAV_GROUPS is a hardcoded list of blueprint endpoints, /file/<dir>/ has no index and /search does not index docs/reports, so the fabric card is the only project-owned surface the nav already reaches — and an autoescaped purpose makes it unlinkable. Their framing is the substantive part: AEF's Carrier Discipline guidance requires an artefact be reachable without instructions, and that clause is currently unsatisfiable by any consumer project. Fix: render purpose through web/shared.py:662 render_markdown_safe (markdown2 safe_mode=escape) using the established blueprint-side *_html + | safe pattern (arcs.py:600, review.py:179, tasks.py:831), NOT a template filter — markdown2 emits block-level <p> which would nest inside the template's own <p>. Same task closes render_markdown_safe's ImportError branch, which returns RAW text and is harmless only while no caller marks it safe. Bonus already present: that helper auto-links T-XXX refs, bare URLs and T-1722 artefact paths, so docs/reports/* in a purpose becomes clickable with no markdown syntax at all.

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
created: 2026-08-20T12:53:55Z
last_update: 2026-08-20T13:36:09Z
date_finished: 2026-08-20T13:36:09Z
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

# T-569: Component card purpose is autoescaped, so a consumer project's cards cannot link to anything it publishes

## Context

Second of two Watchtower findings from **001-CashWeb-Lightspeed-Ecwid-integration**
(agent-chat-arc, thread T-064). T-568 was the first.

`fabric_detail.html:35` renders `<p>{{ component.purpose | default(...) }}</p>` under Jinja
autoescape, so a markdown link written into a project-owned card renders as literal text.
They verified it empirically rather than by reading — wrote a link into a purpose, forced
a cache reload, fetched the page, got no anchor and a literal `[the index](...)`.

Their framing is the part worth keeping, and it is larger than the fix: a consumer project
has **no project-owned nav seam at all**. `NAV_GROUPS` (web/shared.py:136) is a hardcoded
Python list whose leaves are Flask blueprint endpoints, so a project can neither add an
entry nor point one at a URL; `/file/<dir>/` has no directory index; `/search` does not
index `docs/reports`. The fabric component card is the only project-owned surface that the
nav already reaches — and an autoescaped `purpose` makes it unlinkable. AEF's own Carrier
Discipline guidance requires an artefact be "reachable without instructions", and that
clause is therefore currently **unsatisfiable by any consumer project**.

This task does the cheap half: make the card linkable. It deliberately does **not** design
NAV_GROUPS merging, a `nav:` block in `.framework.yaml`, or a `/file/<dir>/` index — those
are AEF's calls and were relayed upstream as such, not proposed as a shape.

Not one line, and the naive one line is wrong twice:

1. The safe renderer already exists — `web/shared.py:662` `render_markdown_safe`, markdown2
   with `safe_mode="escape"`, so raw HTML in a card is escaped rather than injected. The
   established pattern is blueprint-side: the view computes `*_html`, the template marks
   `| safe` (arcs.py:600, review.py:179, tasks.py:831). Done as a template filter instead,
   markdown2's block-level `<p>` nests inside the template's own `<p>`.
2. `render_markdown_safe` has an `ImportError` branch returning the **raw** text. That is
   harmless only while no caller marks the result `| safe` — which this task changes. A
   degradation path that turns escaping off when a dependency is missing is the same shape
   as the rest of this week: the failure renders as health.

**Correction, made during the work rather than after it.** The paragraph that stood here —
and the sentence I sent CashWeb on-thread — said that bare artefact paths like
`docs/reports/T-064-….md` would auto-link once `purpose` rendered through the shared
helper, giving them the seam with no markdown syntax at all. **That is false in a consumer
project.** Measured rather than re-asserted: `render_markdown_safe` turns a bare `T-568`
into an anchor and leaves an EXISTING `docs/standards/aef-bpmn-mapping-v1.md` as plain
text, because `_auto_link_files` (shared.py:650) gates on `(PROJECT_ROOT / path).exists()`
and `PROJECT_ROOT` here is the `.agentic-framework` directory. True in AEF's own tree,
false in ours and in CashWeb's. Filed as **OBS-305** (urgent), corrected on the thread, and
deliberately not fixed under this task — one bug, one task.

What IS true and does land here: explicit markdown link syntax works, and bare `T-NNN`
refs and bare URLs auto-link. That is enough for the card to point at anything, which is
what the report asked for; it just is not free of syntax yet.

## Acceptance Criteria

### Agent
- [x] A markdown link in a card's `purpose` renders as an **anchor** on
      `/fabric/component/<name>`, not as literal text
- [x] Raw HTML in a `purpose` is still **escaped** — the card is project-owned YAML, and
      turning a data field into rendered HTML must not turn it into a script vector
- [x] `render_markdown_safe`'s `ImportError` branch no longer returns raw text to a caller
      that marks it `| safe` (fix at the helper, not at this one call site — PL-214)
- [x] No nested `<p>` in the rendered output: the template stops wrapping what markdown2
      already wraps
- [x] The cached component dict is **not** mutated with derived HTML — T-568 just made
      that cache exact, and writing rendered output back into it would put presentation
      into the digest's payload
- [x] Teeth with a mutant arm: reverting to the autoescaped render must go **red**, and a
      mutant that renders with `safe_mode=None` must redden the escaping leg and only that
- [x] Wired into `tests/run-bridge-tests.sh` (a probe with no live caller becomes an
      unwired guard the moment this task completes — the trap T-568 hit); floor 121 → 122
- [x] Divergences declared for every framework file touched; checker green

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

timeout 900 python3 tools/_t569-card-purpose-markdown-teeth.py > /tmp/.t569-teeth 2>&1 && grep -q "3/3 teeth legs passed" /tmp/.t569-teeth
grep -qF "purpose_html | safe" .agentic-framework/web/templates/fabric_detail.html
grep -qF "purpose_html = render_markdown_safe(" .agentic-framework/web/blueprints/fabric.py
grep -qF "from markupsafe import escape as _escape" .agentic-framework/web/shared.py
python3 tools/_t517-vendor-divergence.py > /tmp/.t569-vendor 2>&1 && grep -q "every diverged path is declared" /tmp/.t569-vendor
python3 tools/_t451-unwired-guard-census.py --ratchet > /tmp/.t569-ratchet 2>&1 && grep -q "no movement" /tmp/.t569-ratchet
bash tests/run-bridge-tests.sh > /tmp/.t569-suite 2>&1 && python3 -c "import re,sys; m=re.search(r'(\d+) passed, 0 failed', open('/tmp/.t569-suite').read()); sys.exit(0 if m and int(m.group(1)) >= 122 else 1)"

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

## RCA

**Symptom.** A markdown link written into a component card's `purpose` renders on
`/fabric/component/<name>` as literal text — `[the index](/file/...)` — so a consumer
project's published artefacts cannot be reached from the one project-owned surface
Watchtower's nav already links. Reported and empirically verified by
001-CashWeb-Lightspeed-Ecwid-integration.

**Root cause.** `fabric_detail.html:35` emitted `{{ component.purpose }}` under Jinja
autoescape. Correct as a default — it is the right treatment for an untrusted string — but
wrong for the one field whose job is to describe and point at things.

**Why structurally allowed.** The nav has no project-owned seam at all: `NAV_GROUPS` is a
hardcoded Python list of blueprint endpoints, `/file/<dir>/` has no index, `/search` does
not index `docs/reports`. So the pressure to make the card linkable never existed inside
AEF's own tree, where artefacts are reachable through blueprints that ship with the
framework. The defect is only visible from a consumer project, and consumer projects had
no way to report it except by hitting it.

**A second defect surfaced while verifying the fix, and it is not fixed here.** I told
CashWeb on-thread that bare `docs/reports/*` paths would auto-link once `purpose` rendered
through the shared helper. Measured before claiming it again: they do not.
`_auto_link_files` (shared.py:650) gates on `(PROJECT_ROOT / path).exists()`, and in a
consumer project `PROJECT_ROOT` is the `.agentic-framework` directory — so **no**
project-owned artefact path resolves, on any Markdown surface. Filed as **OBS-305**
(urgent) and corrected to CashWeb rather than left standing. `fabric.py:18-21` already
carries the compensating idiom and is the model for the eventual fix. One bug, one task.

**Prevention.**
- Teeth in the gating suite with two mutants pulling opposite ways. Mutant B drops
  `safe_mode` and **the link still renders** — so "the link works" alone would have
  accepted an XSS regression as a pass.
- The `ImportError` branch of `render_markdown_safe` now escapes. Fixed at the helper, not
  at this call site (PL-214): a caller about to mark a string `| safe` cannot know whether
  the renderer degraded.
- The probe is wired into the suite in the same commit, not left as a Verification-block
  orphan — the trap T-568 hit one task earlier.

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

### 2026-08-20T12:53:55Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-569-component-card-purpose-is-autoescaped-so.md
- **Context:** Initial task creation

### 2026-08-20T13:22:08Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

## Reviewer Verdict (v1.5)

- **Scan ID:** R-409a4888
- **Timestamp:** 2026-08-20T13:44:31Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-20T13:36:09Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
