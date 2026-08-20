---
id: T-566
name: "Make aef:note readable and writable in the inspector (CashWeb T-064, AEF T-2974 defect 1)"
description: >
  The Extensions panel iterates AEF_FIELDS (src:1827) and silently drops every aef: key not on it. 'note' is in the export metaKeys set (src:9425) so it round-trips faithfully through save/load, but no node type lists it, so nothing can read or write it. Confirmed independently at v0.10.0; reported by 999-AEF (T-2974 defect 1) and independently by 001-CashWeb (their T-064, 27 nodes of API references, auth rules and pseudo code invisible). Standard §2 explicitly places 'note' outside the frozen v1 governance-scalar contract, so this needs no standard bump. Two things to decide rather than inherit from the request: which node types (T-197's principle is that a field appears where it is AUTHORABLE, not everywhere it can be stored), and whether the fix is one more whitelist entry or a general fallback branch for unlisted aef: keys — 'note' is the key that bit two consumers, but a panel that iterates a whitelist and drops the rest is the shape that bit them.

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
created: 2026-08-20T09:56:32Z
last_update: 2026-08-20T15:03:40Z
date_finished: 2026-08-20T15:03:40Z
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

# T-566: Make aef:note readable and writable in the inspector (CashWeb T-064, AEF T-2974 defect 1)

## Context

The Extensions panel iterates `AEF_FIELDS[n.type]` (src:5669) and renders one control per
listed key. Any `aef:` key NOT on that list is dropped from the panel silently — no readout,
no hint, no "N more". `note` is in the export `metaKeys` set (src:9424-9429), so the build
stores and re-emits it faithfully; it is the one thing the editor is careful about and the
one thing nobody can see.

Reported independently twice: 999-AEF (T-2974 defect 1) and 001-CashWeb (their T-064 —
27 nodes of API references, auth rules, call lines and pseudo code). CashWeb built a
parallel read surface on the `/file/` seam rather than keep waiting, which makes the
Designer canvas the ONE place that content cannot be read. Confirmed at our HEAD (v0.10.0),
not inherited from their 0.8.0 pin.

Standard §2 places `note` outside the frozen v1 governance-scalar contract explicitly
("MAY change without a standard bump"), so the rendering needs no standard change. Whether
`note` is PROMOTED INTO the v1 contract is a separate standards question and is the
operator's ruling — deliberately not answered by shipping a field.

**Two scopes, and the second is the one that matters.** `note` is the key that bit two
consumers. The SHAPE that bit them is a panel that iterates a whitelist and silently drops
the rest — fix only `note` and the next project files the same report about a different key.
Counts measured over the corpus are recorded in Decisions below.

T-197 constrains the general fix: some unlisted keys are DERIVED (`owner`, from lane
authority) or STRUCTURAL (`gatewayKind`, `scopeOf`), and an edit box on those would be a
lie. So the general branch discloses read-only; only `note` becomes authorable.

## Acceptance Criteria

### Agent
- [x] `note` is an editable multi-line field in the Extensions panel — on ALL 13 node types,
      not just task-like and event (see Decisions), with `FIELD_META.note.textarea === true`
- [x] Editing `note` in the panel writes through to `n.aef.note` and reaches the exported
      bytes (probe leg `note-writes` asserts BOTH the model and the XML)
- [x] Multi-line content survives the round trip — `note` rides an XML attribute, where a
      literal newline normalises to a space; asserted on the bytes via `&#10;` (leg
      `multiline-roundtrip`)
- [x] Every `aef:` key present on a node but absent from `AEF_FIELDS[n.type]` is DISCLOSED
      read-only rather than dropped silently (leg `disclosure`)
- [x] The disclosure offers no edit control, so derived (`owner`) and structural
      (`gatewayKind`, `scopeOf`) keys are not misrepresented as authorable — T-197
      (leg `disclosure-readonly`)
- [x] A CDP probe drives the real page rather than reading source (PL-148): 6/6 legs
- [x] Teeth harness with a control run first; 3 mutants, each reddening exactly its own
      legs and no others: 4/4
- [x] Bridge meta-parity still passes with `metaKeys` unchanged at 20 — this task adds no
      `aef:` key and touches no wire format
- [x] Whole bridge suite passes with a count floor: 122 → 123 passed, 0 failed

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
node tools/_t566-note-field-cdp.mjs
python3 tools/_t566-note-field-teeth.py
python3 tests/test_editor_bridge_meta_parity.py
# Positive counts, not absence assertions (T-560): an "no inline whitelist remains" leg
# passes just as readily when the pattern is mis-quoted. 13 node types, 13 note entries.
python3 -c "import sys;s=open('src/aef-workflow-designer.html',encoding='utf-8').read();i=s.index('const AEF_FIELDS = {');j=s.index(chr(10)+'};',i);sys.exit(0 if s[i:j].count(chr(39)+'note'+chr(39))==13 and s.count('Other extensions')==1 else 1)"
# The suite is the leg, with a floor — "0 failed" is also what deleting legs produces.
bash tests/run-bridge-tests.sh > /tmp/.t566-suite.out 2>&1 && python3 -c "import re,sys;m=re.search(r'bridge round-trip: (\d+) passed, (\d+) failed',open('/tmp/.t566-suite.out').read());sys.exit(0 if m and int(m.group(1))>=123 and int(m.group(2))==0 else 1)"

# Enforcement-baseline hint (L-398, T-1886): if you edited `.claude/settings.json`
# (added/removed/reorganised hooks), add `bin/fw enforcement baseline` to your
# Verification block. Otherwise the canonical hash diverges and `fw doctor`
# reports a FAIL ("Enforcement baseline CHANGED") that accumulates silently.
# Origin: T-1849/T-1730/T-1731 each added a legitimate hook without refreshing
# the baseline — FAIL sat for multiple sessions until T-1886 cleaned up.

## RCA

**Symptom:** `note` set on a node is stored, re-exported byte-faithfully, and displayed
nowhere. 001-CashWeb had 27 nodes of API references, auth rules, call lines and pseudo code
that could be read on every surface except the editor that owns them.

**Root cause:** the Extensions panel is a whitelist renderer — it iterates
`AEF_FIELDS[n.type]` (src:5669) and has no branch for a key the whitelist does not name.
The export path is a DIFFERENT whitelist (`metaKeys`, src:9424) and `note` is on that one.
Two lists, one of which decides what is stored and the other what is seen, with nothing
holding them in correspondence.

**Why structurally allowed:** the panel's failure mode is silence. An unlisted key produces
no readout, no count, no console warning — the panel looks complete because completeness is
defined by the whitelist it is iterating. This is the week's recurring shape once more: the
degradation renders as health. Nothing in the corpus tooling measured "values carried vs
values displayable" until this task did (305 of 714, 42.7%).

**Prevention:** the disclosure branch converts the silent case into a visible one — a key
nobody listed now appears under "Other extensions" instead of vanishing, so the NEXT key
reports itself rather than waiting for a consumer project to notice. Leg `disclosure` in
`tools/_t566-note-field-cdp.mjs` holds it, wired into the bridge suite in the same commit.
Distinct from the fix: the fix makes `note` authorable; the prevention is that no future
key needs a task to become visible.

**Not fixed here (T-570):** import reads EVERY `<aef:meta>` attribute into `n.aef`
(src:10183) while export emits only `metaKeys` — so a key in neither list is loaded, hidden,
and DROPPED on re-export. `determinism` (12 occurrences) is exactly that. The disclosure
makes such a key visible on the way past; it does not make it survive. One bug, one task.

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

### 2026-08-20 — Both scopes, not one: `note` AND a general disclosure

- **Chose:** add `note` as an editable field, AND add a read-only disclosure branch that
  renders every `aef:` key the node carries but `AEF_FIELDS[n.type]` does not name.
- **Why:** measured over 91 bpmn files / 714 `aef:meta` values — 305 (42.7%) sit outside
  AEF_FIELDS across 14 distinct keys, of which `note` is 92. Shipping only the whitelist
  entry fixes 92 and leaves 213 in the same condition, at which point the next consumer
  files the same report about `terminalKind` (60) or `state` (56). `note` is the key that
  bit two projects; a panel that iterates a whitelist and silently drops the rest is the
  SHAPE that bit them. Mutant A makes the point mechanically: with `note` unlisted, the
  disclosure branch is what catches it.
- **Rejected:** whitelist-entry-only (mutant B — satisfies both reporters, leaves the
  shape). Also rejected: making the disclosure editable (mutant C) — T-197 establishes
  that `owner` is DERIVED from lane authority and `gatewayKind`/`scopeOf` are structural,
  so an edit box on them would be overwritten on the next render and is a lie.

### 2026-08-20 — `note` on all 13 node types, not "task-like and event"

- **Chose:** list `note` on every type in AEF_FIELDS, including gateways.
- **Why:** 001-CashWeb asked for "task-like and event types" and I told them a blanket add
  was "the tempting version and probably the wrong one". On reading the table that was
  wrong, and the correction is worth stating rather than quietly shipping. Every other key
  in AEF_FIELDS is type-specific because it carries type-specific SEMANTICS — `emits` on a
  startEvent is meaningless, a `timerSpec` on a task has nothing to bind to. `note` carries
  no semantics a node type could contradict: it is author prose. T-197's principle is that
  a field appears where it is AUTHORABLE, and prose is authorable everywhere. Restricting it
  would have produced this same report from the next author who put a note on a gateway.
- **Rejected:** the requested narrower set — it would have needed a defensible reason to
  exclude gateways and there is none.

### 2026-08-20 — Multi-line asserted on the bytes, not on the textarea

- **Chose:** a probe leg that round-trips through `parseBpmnXml(buildBpmnXml(state))` and
  requires the newline back, plus the presence of `&#10;` in the emitted XML.
- **Why:** `note` is serialised as an XML ATTRIBUTE, and attribute-value normalisation
  collapses a literal newline to a space. "Multi-line note" is therefore a claim about
  `escAttr`, not about the panel — a textarea that renders three lines and re-loads as one
  would satisfy any panel-level assertion. `escAttr` already emits `&#10;` (src:9437) and
  the comment beside it shows the author knew the rule; this leg pins that behaviour so a
  later "simplification" of escAttr cannot silently flatten the reporter's content.

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

### 2026-08-20T09:56:32Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-566-make-aefnote-readable-and-writable-in-th.md
- **Context:** Initial task creation

### 2026-08-20T14:43:48Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

## Reviewer Verdict (v1.5)

- **Scan ID:** R-e237c94d
- **Timestamp:** 2026-08-20T15:12:28Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-20T15:03:40Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
