---
id: T-679
name: "arc tag reassignment guard reads only arc_id:, so 26 legacy-tag-only tasks can be silently reassigned"
description: >
  MEASURED on the real corpus immediately after T-467 landed, by running the fixed verb end-to-end instead of only against fixtures. 'fw arc tag designer-authoring-surface T-590' SET the field and exited 0, though T-590 already belonged to ewcr-governed-delivery. T-467's new reassignment guard looks for a live 'arc_id:' line and T-590 records its membership in the LEGACY tag form (tags: [..., arc:ewcr-governed-delivery]) with no arc_id: at all. So the guard is blind to exactly the population it most needs to see: 26 tasks in this tree carry legacy-tag-only membership, and every one of them can be silently reassigned. This is the union problem one level down - readers (lib/arc_membership.py) union arc_id: with the legacy tag, and T-467's WRITER consults only half of that union. Second finding from the same measurement: multi-arc legacy tags exist (at least 2 tasks carry two arc: tags), and single-valued arc_id: cannot represent dual membership, so writing it would silently drop one. Damage from the probe was reverted immediately (git checkout of the single file, tree clean).

status: work-completed
workflow_type: build
owner: agent
horizon: null
tags: []
components: [tools/_t341-orphan-lane-probe.mjs]
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-09-05T10:51:14Z
last_update: 2026-09-05T10:53:28Z
date_finished: 2026-09-05T10:53:28Z
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

# T-679: arc tag reassignment guard reads only arc_id:, so 26 legacy-tag-only tasks can be silently reassigned

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] The reassignment guard consults the **same union the readers do** — a live `arc_id:`
      *and* `arc:<slug>` entries on the `tags:` line. `fw arc tag <other-arc> <task>` on a
      task whose membership is legacy-tag-only exits non-zero and changes nothing.
      T-590 is the measured instance and is the fixture shape.
- [x] Tagging a legacy-tag-only task to the arc it **already** belongs to still writes
      `arc_id:` — the upgrade path. Refusing here would break `arc_migrate` step 3, which
      exists precisely to walk legacy-tagged tasks back through this verb, and would leave
      the 26 legacy-tag-only tasks with no route to the canonical field.
- [x] A task carrying **two or more** `arc:` tags is refused with a message naming both
      arcs. Single-valued `arc_id:` cannot represent dual membership, so writing it would
      silently drop one — measured: at least 2 tasks carry
      `[arc:designer-authoring-surface, arc:ewcr-governed-delivery]`.
- [x] The `arc:` tag scan is bounded to the `tags:` line inside frontmatter. `arc:` appears
      in body prose across this corpus; a document-wide scan would refuse legitimate
      taggings on tasks that merely *discuss* arcs — the mention-is-not-membership class
      (T-669) that this whole task pair keeps circling.
- [x] `tools/_t467-arc-tag-source-of-truth.py` gains arms for each case above, and each new
      arm **fails against `78cf7d75`** (the T-467 fix as landed) — proving they fence this
      defect and not merely the original one.
- [x] The 26 legacy-tag-only tasks are counted and reported, not migrated. Bulk-upgrading
      them is a separate act with its own blast radius and is not smuggled into a bug fix.

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
         1. Run `bin/fw reviewer T-679`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-679 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
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
python3 tools/_t467-arc-tag-source-of-truth.py
python3 tools/_t517-vendor-divergence.py

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

**Symptom.** `fw arc tag designer-authoring-surface T-590` set `arc_id:` and exited 0 on a
task that already belonged to `ewcr-governed-delivery`. T-467 had shipped a reassignment
guard minutes earlier and its fence passed six arms; this case walked straight through it.

**Root cause.** The guard reads a live `arc_id:` line. T-590 records its membership in the
legacy form — `tags: [..., arc:ewcr-governed-delivery]`, no `arc_id:` at all — so `live`
was `None` and the write proceeded. **26 tasks in this tree are legacy-tag-only**, and
every one of them was exposed.

**Why structurally allowed.** This is T-467's own root cause reappearing inside T-467's
fix. Readers union `arc_id:` with the legacy tag; the new *writer* consults half that
union. I fixed a producer that had fallen behind the source-of-truth migration and then
wrote a guard that made the same assumption the migration's own leftovers violate — the
population a reassignment guard most needs to protect is precisely the un-migrated one.

**Why the fence missed it.** Every T-467 fixture was built from the modern template, which
has `tags: []` and a commented `# arc_id:`. The fence was thorough about the *behaviours*
and monocultural about the *inputs*. Fixtures generated from one template test one shape of
the world; the corpus holds two, because a migration ran and did not finish. A fence whose
fixtures all come from today's template cannot see yesterday's records.

**What caught it.** Running the fixed verb end-to-end on the real corpus instead of
stopping at a green fence. The probe damaged one file and was reverted immediately
(`git checkout` of the single path, tree verified clean). That is the argument for the
end-to-end step, not against it: the fence was green and wrong, and nothing short of real
data said so.

**Second defect from the same measurement.** At least 2 tasks carry two `arc:` tags
(`[arc:designer-authoring-surface, arc:ewcr-governed-delivery]`). The legacy list form
permitted multi-arc membership; single-valued `arc_id:` cannot represent it, so writing the
field would silently drop one. Now refused with both arcs named — the collapse is a
scope decision, not a side effect of tagging.

**Prevention.** Four new arms on `tools/_t467-arc-tag-source-of-truth.py`, two of which
fail against `78cf7d75` (the T-467 fix as landed) and two of which pass there — the second
pair guards the properties this fix could have broken. That split is deliberate: the cheap
way to satisfy "refuses legacy-tag reassignment" is to refuse *any* task carrying an
`arc:` tag, which would strand all 26 legacy-tag-only tasks and break `arc_migrate` step 3,
the one path that walks them to the canonical field. The upgrade arm is what makes the
refusal arm honest.

**Not done, deliberately.** The 26 legacy-tag-only tasks are counted and reported, not
migrated. A bulk upgrade has its own blast radius and belongs in its own task, not smuggled
into a bug fix.

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
     fw inception decide T-679 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-05T10:51:14Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-679-arc-tag-reassignment-guard-reads-only-ar.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-0df27a7f
- **Timestamp:** 2026-09-05T10:53:31Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-09-05T10:53:28Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
