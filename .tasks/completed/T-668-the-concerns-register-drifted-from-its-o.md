---
id: T-668
name: "the concerns register drifted from its own declared schema: two field names nothing reads"
description: >
  the concerns register drifted from its own declared schema: two field names nothing reads

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
created: 2026-09-01T21:31:50Z
last_update: 2026-09-01T21:36:11Z
date_finished: 2026-09-01T21:36:11Z
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

# T-668: the concerns register drifted from its own declared schema: two field names nothing reads

## Context

`tools/_t400-schema-teeth.sh` was one of two instruments the sweep listed as `regressed`, and
between them they blocked six task closures that run the bridge suite. Measured rather than
assumed: nine of its ten legs are green. The tool is fine. Its reciprocity leg — "the real
register must pass, because a guard that reds on the live file gets reverted rather than
obeyed" — was red because `.context/project/concerns.yaml` carries two field names no code
reads: `tasks` (4 entries) and `shipped_2026_08_31` (1 entry).

This is the opposite polarity to the last four tasks and the reason it is worth its own
entry. T-663, T-665, T-666 and T-667 were all *dead instruments reporting nothing*, filed
under labels that read as benign. This is a *live instrument reporting a true positive*, filed
under a label that reads as alarming — "regressed" means "the thing this guards broke", when
what happened is "the thing this guards is fine and the data drifted". Both directions end the
same way: the report is not read as what it is.

Scope boundary held throughout: this task renames two keys and changes no value. Concern
status, severity, `decision_trigger` and every prose body are untouched — flipping a concern
is the operator's, and a key rename must not smuggle one in.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] The drift is stated as a measurement, including the evidence that this is **data drift
      and not a broken instrument**: `_t400-schema-teeth.sh`'s nine synthetic legs and its
      control all pass, and only the reciprocity leg ("the real register must pass") is red.
      A guard reporting a true positive is not a regression, and the distinction decides
      whether the fix belongs in the tool or in the data.

      **Measured before the fix** — `RAN … ok CONTROL` plus legs (a)–(h) all `ok`, then:

          FAIL: RECIPROC: the real register must pass. rc=1
          SCHEMA FAIL — 2 field name(s) nothing accounts for:
            - shipped_2026_08_31       (in 1 entry/entries)
            - tasks                    (in 4 entry/entries)

      Nine of ten legs green means the tool is healthy. The instrument was reporting a true
      positive and had been for some time; it entered the sweep's `regressed` bucket, which
      is where a correct finding about data looks identical to a broken guard.

- [x] Both unaccounted field names are gone from `.context/project/concerns.yaml`, and
      `python3 tools/concerns-schema.py` exits 0 against the live register.

      `schema ok: 44 entries, 24 distinct field name(s), all accounted for (7 read by code,
      17 prose).` rc=0.

- [x] **No semantic field is changed.** Proven by diff, not asserted: the only lines that
      differ are the key names themselves; every value — status, severity, decision_trigger,
      title, prose body — is byte-identical before and after. Concern flips are the operator's
      (constraint: agents never flip a concern), and a key rename must not smuggle one.

      `diff` against a pre-edit copy returns **exactly five changed lines**, each a bare key:
      four `tasks:` → `related_tasks:` (lines 2704, 2785, 2842, 3002) and one
      `shipped_2026_08_31: |` → `evidence_2026_08_31_T653: |` (line 2977). No value line
      appears in the diff at all. Entry count 44 before and after; YAML parses.

- [x] Each replacement name is **justified against the schema's own declared conventions
      rather than invented**: it is either already listed in `PROSE`, or it matches the
      existing `DATED_EVIDENCE` append-only pattern. A name chosen because it looks nice is
      the defect (G-027), not the fix.

      - `tasks` → **`related_tasks`**, already in `PROSE` as *"near-synonym of `related`;
        neither is read"*. The register was carrying a **third** synonym for one idea
        (`related`, `related_tasks`, `tasks`); this removes one rather than adding a fourth.
      - `shipped_2026_08_31` → **`evidence_2026_08_31_T653`**, matching
        `DATED_EVIDENCE = ^evidence_\d{4}_\d{2}_\d{2}(_[A-Za-z0-9]+)?$` — the schema's
        existing append-only convention, whose stated purpose ("a later measurement must not
        overwrite an earlier one") is exactly what the dated `shipped_` key was reaching for.
        T-653 is the task that wrote the block (`.context/episodic/T-653.yaml:28`).

- [x] **`PROSE` did not grow.** This is the anti-cheap-fix criterion and the one most worth
      failing on: adding `tasks` and `shipped_2026_08_31` to the declared-prose list would
      turn the guard green in one edit while institutionalising exactly the drift it exists
      to catch — and `shipped_YYYY_MM_DD` is a dated name, so the next one would fail again.
      Verified by counting the `PROSE` entries before and after.

      **14 keys before, 14 after** — and the stronger form of the same claim:
      `tools/concerns-schema.py` does not appear in `git status` at all, so `PROSE` is
      byte-identical rather than merely equinumerous.

      *Correction to my own first measurement:* I initially counted 15 by matching lines
      beginning with a quote (`^\s*"`), which also catches the `context` entry's continuation
      line. The key count is 14. The AC's claim is unaffected — the count was stable across
      the edit either way — but the number cited here is now the number of entries, which is
      what the criterion is about. The verification line counts keys at 4-space indent.

- [x] `bash tools/_t400-schema-teeth.sh` exits 0, with the reciprocity leg green for its
      stated reason (the real register passing), not because the leg was weakened.

          ok  RECIPROC the real register passes over all 44 entries (count derived, not restated)
          TEETH PASS — 10/10 legs recorded (control + 8 cases + reciprocal on the live register)

      The leg cannot have been weakened to achieve this: `git status` shows **no file under
      `tools/` changed by this task** — the single modified path is
      `.context/project/concerns.yaml`. The guard is byte-identical to the one that was red.

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
         1. Run `bin/fw reviewer T-668`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-668 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
-->

## Verification

# The guard passes on the live register. This is the deliverable.
python3 tools/concerns-schema.py

# The full teeth, including the reciprocity leg that was red. 10/10.
timeout 280 bash tools/_t400-schema-teeth.sh

# Neither retired field name is back. Asserted per-name so the failure says WHICH returned —
# a combined grep would report "something came back" and leave the reader to find out which.
sh -c 'for k in "  tasks:" "  shipped_2026_08_31:"; do case "$(cat .context/project/concerns.yaml)" in *"$k"*) echo "RETIRED FIELD NAME IS BACK: $k"; exit 1;; esac; done'

# PROSE did not grow. The cheap fix for this task was to declare the two drifted names as
# prose, which goes green while blinding the guard to the class — so the count is pinned.
# Counts KEYS (entries at exactly 4-space indent), not lines beginning with a quote: the
# `context` entry wraps onto a continuation line, and a line count reads 15 for 14 keys.
sh -c 'test "$(awk "/^PROSE = \{/,/^\}/" tools/concerns-schema.py | grep -c "^    \"")" -eq 14'

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

**Symptom.** `tools/_t400-schema-teeth.sh` exited 1 and appeared in the instrument sweep's
`regressed` bucket alongside a genuinely broken instrument. Nine of its ten legs were green;
the red one was RECIPROC — "the real register must pass".

**Root cause.** Not in the tool. `.context/project/concerns.yaml` carried two field names no
code reads: `tasks` (4 entries) and `shipped_2026_08_31` (1 entry). This is the G-027 shape
the guard exists to catch — a plausible, readable field name that nothing consumes, so the
entry looks complete while the tooling behaves as if it were empty.

Each arose the same way: someone reached for a convention that already existed and landed one
step off it. `related_tasks` was already declared prose for exactly the ids `tasks` holds, and
`evidence_YYYY_MM_DD_Txxx` was already the declared append-only pattern for exactly the dated
note `shipped_2026_08_31` holds. The register did not lack a convention; it drifted off one.

**Why structurally allowed.** Two layers:

1. **The guard was working and nobody was reading it.** This is the inverse of the last three
   tasks and worth stating plainly, because I nearly mis-filed it. T-663/T-665/T-666/T-667
   were all *dead instruments reporting nothing*. This one was a *live instrument reporting a
   true positive into a bucket labelled "regressed"* — a word that means "the thing this
   guards broke", when what actually happened is "the thing this guards is fine and the data
   it watches drifted". A correct finding filed under a misleading label is not read as a
   finding. Same family as T-666, opposite polarity: there the benign label hid a broken
   guard, here an alarming label hid a working one.
2. **Nothing keeps the register's vocabulary convergent.** The schema declares 17 prose fields
   including two admitted near-synonyms (`related` / `related_tasks`, `description` /
   `detail`). Synonym pairs are tolerated by design, and each tolerated pair makes the next
   ad-hoc name feel normal. `tasks` was the third member of one such family.

**Prevention.** The guard already is the prevention and it worked — it named both fields, both
entry counts, the remedy, and the exact list of fields the code reads, inline rather than
behind another command. What this task adds is that the register now *passes* it, so the next
drift is a state change from green rather than one more line in a standing red.

Not done, and deliberately: no new PROSE entry was added. The cheap fix — declare `tasks` and
`shipped_2026_08_31` as prose — would have been one edit, would have gone green, and would
have made the guard permanently unable to see this class. `shipped_YYYY_MM_DD` is a *dated*
name, so it would also have failed again on the next one.


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
     fw inception decide T-668 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-01T21:31:50Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-668-the-concerns-register-drifted-from-its-o.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-3379b39e
- **Timestamp:** 2026-09-01T21:36:13Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-09-01T21:36:11Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
