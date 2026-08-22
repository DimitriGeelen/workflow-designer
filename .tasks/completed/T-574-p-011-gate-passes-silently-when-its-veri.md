---
id: T-574
name: "P-011 gate passes SILENTLY when its Verification section is present but unreachable: 0 legs run reads identical to all legs passed"
description: >
  update-task.sh:983 extracts the verification block with sed -n '/^## Verification/,/^## /p'. When that anchor does not match, the range yields ZERO lines and line 989 does '[ -z "$verify_cmds" ] && return 0' -- a silent pass that prints NOTHING. Completion output is then byte-identical to a task whose legs all passed: 'Acceptance criteria: N/N checked', 'RCA: substantive', then straight to the status change. Found on T-572, whose own block was spliced mid-AC-list by an author error (a s.index() matching a backticked MENTION of the heading), leaving the heading glued to the end of a line. The task completed, moved to completed/, generated its episodic and reported success with all TEN legs unrun. The author error is mine and is fixed in that file; the gate half is this task. CLAUDE.md documents 'tasks without a Verification section pass through (backward compatible)', so the pass-through itself is INTENDED -- the defect is that it is indistinguishable from success and that a section which EXISTS but is unreachable by the anchor is silently treated as absent. G-034's shape exactly: an instrument reporting success having examined nothing. Fix direction: print the leg count unconditionally (0 legs must SAY 0 legs), and distinguish 'no Verification heading in the file at all' from 'heading text present but not anchored at column 0' -- the second is a malformed block and should refuse, not pass. Vendored file, so G-008 applies: fix in-tree, declare in .vendor-divergence.yaml, report upstream to AEF.

status: work-completed
workflow_type: build
owner: agent
horizon: now
tags: [bug, framework, vendored, gate]
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-20T18:19:38Z
last_update: 2026-08-22T10:15:05Z
date_finished: 2026-08-22T10:15:05Z
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

# T-574: P-011 gate passes SILENTLY when its Verification section is present but unreachable: 0 legs run reads identical to all legs passed

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Acceptance Criteria

### Agent
- [x] The gate prints its leg count UNCONDITIONALLY, so a run that executed zero commands says
      so in the same line that a run of nine says nine. Today 0 legs and 9-all-green produce
      indistinguishable completion output, which is the whole defect.
      **DONE** — all four states now print. Absent section and well-formed-but-empty both emit
      `Running 0 verification command(s)` plus `NOTE: nothing was verified. That is a
      pass-through, not a pass.` Probe legs `control-absent` and `control-wellformed` hold the
      two ends apart.
- [x] COULD-NOT-LOOK IS ITS OWN FAILURE LINE, printed separately from a defect finding — never
      an absence of complaint. "No verification command failed" and "no verification command
      ran" are different facts and only one of them is about the task.
      (Framing arrived at independently by 001-CashWeb on their own checker, agent-chat-arc
      offset 193, while fixing a PASS whose printed node count exceeded the nodes it compared.
      Adopted verbatim because it is better than "print the count": a count can still be read
      past, a separate failure line cannot.)
      **DONE** — `=== Verification Gate (P-011): COULD NOT READ THE BLOCK ===`, on its own,
      to stderr, returning 1. Its first line says explicitly that this is a finding about the
      gate's ability to look and not about the task. Leg `absent-vs-malformed` asserts the two
      cases do not render alike, which is the defect stated as a test.
- [x] A verification heading whose text is present in the file but NOT anchored at column 0 is
      treated as a MALFORMED block and REFUSES completion, distinct from a file with no such
      section at all, which keeps the documented backward-compatible pass-through.
      **DONE** — and WIDER than filed. Three unreadable shapes now refuse: mid-line only
      (T-572), a prefix heading preceding the real one (T-542, discovered 2026-08-22 and not
      known when this AC was written), and more than one exact heading. The absent case keeps
      its pass-through.
- [x] Regression test drives the three states apart — no section (passes, says 0), malformed
      section (refuses), well-formed section (runs and reports N) — against real task fixtures
      in a tmpdir, never against the live tree.
      **DONE** — `tools/_t574-p011-block-locator-teeth.py`, five fixtures, `tempfile.
      TemporaryDirectory()` only. It sources the REAL `run_verification_commands` out of the
      real gate file and calls it, rather than reimplementing the logic (PL-204: the
      instrument must run the thing it describes).
- [x] The T-572 fixture is one of the test cases: a heading preceded on the same line by a
      backticked mention of itself is the exact shape that produced this, and a fix that passes
      only on a synthetic case has not been shown to catch the real one.
      **DONE** — fixture `t572-inline` is that exact shape. The mutant leg `mutant-kills-t572`
      shows the pre-fix gate passing it SILENTLY with rc=0, so the fixture is demonstrated to
      reach the defect rather than assumed to.
- [x] Mutation teeth: reverting the fix must redden the malformed-section leg and ONLY that leg;
      a control run on unmutated source comes first (T-560).
      **DONE** — control runs first and must be green before any mutant is built. The mutant
      reverts the locator, restores the silent early return and disables the refusal;
      `mutant-spares-wellformed` and `mutant-spares-absent` assert it reddens only what it owns.
      **The teeth caught a real error in my own fixtures on the first run:** `mutant-spares-
      wellformed` went red, and the cause was not the mutant being broad — it was that I had
      put the block LAST in the fixture, where the old code's `sed '$d'` ate a command. That
      is now its own fixture and its own leg rather than a fixture bug I quietly corrected.
- [x] Wired into a standing runner in the SAME commit, not left callable only from this task's
      own verification block (T-568 — which would reproduce the class this task is about).
      **DONE** — `tests/run-bridge-tests.sh`, same commit. **Stated limitation, at the wiring
      site and here:** that suite has no scheduled caller — no cron, no git hook, no CI, already
      on file as an observation. Registering there is strictly better than verification-block-
      only and is still not a thing that runs on its own. Recording that is the point; a wiring
      AC ticked without it would be this task's own defect in miniature.
- [x] Declared in `.vendor-divergence.yaml` with upstream intent, and the divergence checker is
      green (G-008: this is a vendored framework file and the defect exists in AEF's tree too).
      **DONE** — entry 42, `upstream: fix`, and `python3 tools/_t517-vendor-divergence.py`
      exits 0.
- [x] Population checked, not assumed unique: every other `sed -n` style heading-range
      extraction in the vendored tree is enumerated and each is either shown safe or filed.
      **DONE — 12 distinct heading ranges swept mechanically, not by eye.** Four carry a real
      prefix collision: `## Decisions` (episodic.sh) vs `## Decisions Made This Session`;
      `## Gotchas` (post-compact-resume.sh) vs `## Gotchas / Warnings for Next Session`;
      `## Open Questions` (audit.sh and resume.sh) vs `## Open Questions / Blockers`. **All
      four were RUN against the live handover and all four resolve correctly today**, because
      each prefix currently has exactly one match. Latent, not broken. Deliberately NOT fixed
      here — widening a bounded fix to twelve call sites is how it becomes unbounded — and
      reported in the divergence entry so the next reader inherits the measurement.

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

# One command per line. P-011 runs each under -o pipefail but NOT an effective -e (T-352),
# so each line below is a SINGLE command whose own exit code is the verdict.
# HAZARD found while writing these legs (2026-08-22): the gate runs each line with
# `eval` IN ITS OWN SCOPE, so a verification command that mentions a gate-internal
# variable gets it substituted. A leg here referencing $verify_cmds had the gate's
# entire command list spliced into it and died on a SyntaxError. Legs that must name
# such a string build it with chr() inside a SINGLE-quoted shell argument.
# Second hazard, same leg: the first version of it matched the fix's OWN COMMENT, which
# quotes the defective line in order to explain it. An absence-assertion over a file that
# documents what it removed will always find its own prose. The leg now reads only
# non-comment lines. Sibling of G-041's closure-check caveat.
python3 tools/_t574-p011-block-locator-teeth.py
python3 tools/_t517-vendor-divergence.py
bash -n .agentic-framework/agents/task-create/update-task.sh
grep -q "_t574-p011-block-locator-teeth.py" tests/run-bridge-tests.sh
python3 -c 'import sys; bad="[ -z "+chr(34)+chr(36)+"verify_cmds"+chr(34)+" ] && return 0"; live=[l for l in open(".agentic-framework/agents/task-create/update-task.sh",encoding="utf-8") if not l.lstrip().startswith("#")]; sys.exit(0 if not any(bad in l for l in live) else 1)'
python3 -c "import sys; s=open('.agentic-framework/agents/task-create/update-task.sh',encoding='utf-8').read(); sys.exit(0 if 'COULD NOT READ THE BLOCK' in s else 1)"
python3 -c "import yaml,sys; d=yaml.safe_load(open('.agentic-framework/.vendor-divergence.yaml')); sys.exit(0 if any(e['path'].endswith('task-create/update-task.sh') and e['task']=='T-574' for e in d['entries']) else 1)"

## RCA

**Symptom:** `fw task update T-572 --status work-completed` reported success. All ten of its
verification legs had run zero times. The output contained no line saying so — it was
byte-identical to a run that executed every leg and found no fault.

**Root cause:** `run_verification_commands` located its block with
`sed -n '/^## Verification/,/^## /p'` and then `[ -z "$verify_cmds" ] && return 0`. Two
independent weaknesses compounding:

1. `^## Verification` is a **prefix** match on a heading whose exact text matters.
2. An empty extraction returned **success, silently** — the gate could not distinguish
   "nothing to check" from "I could not find what to check."

Either alone is survivable. Together, any accident that breaks the locator converts into a
green completion record.

**Why structurally allowed:** the failure **rendered as health**, which is the shape running
through six tasks this week (T-562, T-566, T-568, T-569, T-570, T-572). Nothing the gate
printed was false. `Acceptance criteria: 10/10 checked ✓` was true. The absent line was the
information, and an absence is not something a reader notices. This is PL-257 sharpened: a
misleading *count* beside a PASS is worse than a misleading *name*, because a name is a claim
a reader can doubt while a number reads as a measurement — and here even the number was
missing, so there was not even a wrong figure to distrust.

The deeper permission: **a gate's own liveness was asserted by nothing.** PL-148 says an
instrument's registration must be asserted by something other than the instrument; this is
the same rule one level down — the instrument's *ability to see its subject* was asserted by
the instrument, by way of it not complaining.

**Prevention:**
- **Could-not-look is now its own failure line**, refusing completion, printed separately from
  any finding about the task. Not "print the count" — a count can be read past; a refusal
  cannot. Framing taken verbatim from 001-CashWeb (agent-chat-arc offset 193), who reached it
  independently on their own checker the same week.
- **The count is now printed unconditionally**, so zero says zero in the same line nine says
  nine, and a pass-through is labelled `not a pass`.
- **Exact-match location plus anchored extraction**, so neither known shape can steer it.
- **`tools/_t574-p011-block-locator-teeth.py`**, 10 legs, control-first, carrying the *real*
  T-572 and T-542 fixtures and a mutant that must redden only its own legs. Wired into
  `tests/run-bridge-tests.sh` in the same commit (T-568).
- **Population swept**: 12 sibling heading-ranges enumerated; the four with real prefix
  collisions were *run* against the live handover and shown to resolve correctly today.
  Latent, recorded, not fixed here.

**What prevention does NOT cover, stated because a gap closed on paper is worse than one left
open (G-019):**
- The standing runner it is wired into **has no scheduled caller** — no cron, no git hook, no
  CI. This guard executes when somebody types the command.
- **PL-115 inverted: fixing the gate does not replay what it skipped.** Every task completed
  before today whose block was unreadable is still recorded as verified, and this fix does not
  find them. T-572 was repaired and re-run by hand because it was caught; nothing enumerates
  the others. That is a real open exposure and it is not closed by this task.
- The four latent prefix collisions are one added handover heading away from mattering.


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

### 2026-08-20T18:19:38Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-574-p-011-gate-passes-silently-when-its-veri.md
- **Context:** Initial task creation

### 2026-08-20T18:29:48Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

## Reviewer Verdict (v1.5)

- **Scan ID:** R-39484edc
- **Timestamp:** 2026-08-22T10:15:07Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-22T10:15:05Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
