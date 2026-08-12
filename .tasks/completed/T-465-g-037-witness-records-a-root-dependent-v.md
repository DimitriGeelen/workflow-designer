---
id: T-465
name: "G-037 witness records a root-dependent verdict without recording its search root"
description: >
  G-037 witness records a root-dependent verdict without recording its search root

status: work-completed
workflow_type: build
owner: agent
horizon: null
tags: []
components: [tools/_t465-witness-shape.sh]
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-12T19:15:33Z
last_update: 2026-08-12T19:21:44Z
date_finished: 2026-08-12T19:21:44Z
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

# T-465: G-037 witness records a root-dependent verdict without recording its search root

## Context

`.context/working/.grep-witness` records `recursive_sees_ignored=no` as a bare verdict.
That verdict is **root-dependent**, and the file does not say from which root it was taken —
so it disagrees with itself and nothing notices.

Peer-reported by AEF at rail 575 §3-ii, then **measured here rather than inherited**. Same
string, same tree, same agent-side `grep`, differing only in start directory:

    grep -rla 'census' tools/    ->  5 hits under tools/__pycache__/
    grep -rla 'census' .         ->  0 hits under tools/__pycache__/
    /usr/bin/grep, either root   ->  5 and 6 respectively

`tools/__pycache__/` is path-anchored in the ROOT `.gitignore`. ugrep applies ignore files
at or below the search root and never above it, so rooting the sweep at `tools/` puts the
rule out of scope and the files reappear. The witness's single `no` is therefore an answer
to a question it does not state.

**Second, narrower correction — the predicate.** T-462 recorded the instance as
"`focus.yaml` and `session.yaml` are both gitignored". On this tree that is TRUE (measured:
both untracked, both `check-ignore` IGNORED, rule sourced from `.context/working/.gitignore`),
so the number in T-462 stands. But the REASON was under-general. AEF measured the general
predicate on their tree, where the same two files are **tracked** and `git check-ignore`
reports them not-ignored, and they are still invisible agent-side: ugrep applies ignore
*patterns* textually and knows nothing about git's index. The predicate is not *is it
gitignored* — it is *does any in-scope ignore pattern match it*. Our two conditions happen
to coincide; that is a property of this tree, not of the mechanism.

Consequence for the gauge: `recursive_sees_ignored` is not a property of the tree. It is a
property of (tree, search root), and a witness that omits the second half cannot be compared
against a later reading of itself — which is the entire job the witness was built to do.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] **The witness records the search root it was taken from**, as a first-class field
      alongside the verdict. A verdict whose question is unstated cannot be compared to a
      later reading, and comparison is the only thing the witness exists for.
- [x] **The witness records BOTH roots, not one.** A single root plus a root label would
      still be a one-sided reading that happens to be labelled; the divergence is only
      visible when the same probe is taken from a root where the ignore rule is in scope and
      one where it is not. Verified by the file carrying two distinct verdicts.
- [x] **The root-dependence is measured by the probe, not asserted by me.** The probe builds
      its own fixture (an ignore rule above the search root plus a matching file), sweeps it
      from both roots, and records what it observed — so a future tree where the mechanism
      has changed produces a different witness rather than the same sentence.
- [x] **The probe fails loudly if its own fixture is vacuous** — if the fixture file is not
      found by EITHER root, the sweep proved nothing and the verdict must be refused rather
      than recorded as `no` (PL-084; a false `no` here is indistinguishable from a real one).
- [x] **The predicate correction is recorded against G-037**, stating that gitignore-status
      is not the test and that this tree's two conditions coincide by accident. Appended, not
      rewritten — T-462's measured numbers are correct and stay as written.
- [x] **G-037's `closure_check_command` still runs and still fails**, since neither axis is
      closed by this task. A gauge change that accidentally turned the gap green would be
      G-034's shape applied to this gap's own check.

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
#
# T-465 note: every grep below is spelled /usr/bin/grep on purpose. P-011 runs GNU grep
# anyway, but writing it explicitly means this block reads identically in the tool shell,
# where bare `grep` is the ugrep shim. T-464's leg 4 passed at the gate and failed on
# manual replay for exactly that reason — removing the bet is cheaper than winning it.

bash tools/_t465-witness-shape.sh
/usr/bin/grep -q '^recursive_sees_ignored_search_root=' .context/working/.grep-witness
/usr/bin/grep -q '^recursive_sees_ignored_root_a=no' .context/working/.grep-witness && /usr/bin/grep -q '^recursive_sees_ignored_root_b=yes' .context/working/.grep-witness
D=$(mktemp -d) && /usr/bin/grep -v '^recursive_sees_ignored_search_root=' .context/working/.grep-witness > "$D/w" && ! WITNESS="$D/w" bash tools/_t465-witness-shape.sh >/dev/null 2>&1
D=$(mktemp -d) && sed 's/^recursive_sees_ignored_root_b=yes/recursive_sees_ignored_root_b=no/' .context/working/.grep-witness > "$D/w" && ! WITNESS="$D/w" bash tools/_t465-witness-shape.sh >/dev/null 2>&1
/usr/bin/grep -q '^  evidence_2026_08_12_T465:' .context/project/concerns.yaml
python3 tools/concerns-schema.py > /tmp/.t465-schema.txt 2>&1 && /usr/bin/grep -q "schema ok: $(/usr/bin/grep -c '^- id: ' .context/project/concerns.yaml) entries" /tmp/.t465-schema.txt
bash tools/_t400-schema-teeth.sh
python3 -c "import yaml,subprocess,json; c=[x for x in yaml.safe_load(open('.context/project/concerns.yaml'))['concerns'] if x['id']=='G-037'][0]; r=subprocess.run(['bash','-lc',c['closure_check_command']],capture_output=True,text=True); o=json.loads(r.stdout); raise SystemExit(0 if o['verdict']=='NOT_READY' else 1)"

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

**Symptom:** `.context/working/.grep-witness` recorded `recursive_sees_ignored=no` as a bare
verdict. Measured here: the same needle, the same tree, the same agent-side `grep`, swept from
two different start directories, gives 5 hits and 0 hits. The witness was answering a question
it did not state.

**Root cause:** I modelled the INPUTS axis as a property of the TREE ("this repo's gitignored
files are invisible agent-side"). It is a property of **(tree, search root)**. ugrep applies
ignore files at or below the search root and never above it, so a rule anchored in the root
`.gitignore` is simply out of scope when the sweep starts one directory down. One variable of
the pair was never recorded, so two readings of the witness taken from different roots would
disagree with no way to tell that they had asked different questions.

**Why structurally allowed:** the witness was built in T-462 to answer *"do agent and gate see
the same files?"*, and every measurement I took to build it happened to start from the repo
root. A constant that is never varied looks exactly like a constant that cannot vary. Nothing
in the design forced the probe to sweep from a second root, so the dependence could not show
up — this is the same shape as T-464's stale literal one level up: not a wrong value, but a
value whose governing condition lives outside the artefact that records it.

Second, smaller: I stated the predicate as "gitignored" and it held on this tree. It held
because this tree's two conditions coincide, not because the mechanism says so. A claim that is
true for the wrong reason survives every test you run on your own tree, which is why AEF's
falsification arrived from theirs and not from mine.

**Prevention:** `tools/_t465-witness-shape.sh` refuses a witness whose verdict carries no search
root, refuses one where both roots report the same answer (the probe would not have varied the
thing it claims to vary), and re-measures the gate-side half live so a witness that drifts from
reality on its checkable claim goes red. Falsified four ways against mutated copies; the subject
path is overridable precisely so falsification never requires writing to the live witness.

**NOT prevented, stated rather than implied:** nothing runs this checker on a schedule — it is
G-035's population, same as T-464's harness. And the checker cannot verify the agent-side numbers
at all; it runs `/usr/bin/grep`, so measuring them from there would produce a GNU number wearing
a ugrep label. That limit is recorded as its own leg so a green is never mistaken for coverage.
G-037 remains open on both axes, verified by a leg in this task.

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

### 2026-08-12T19:15:33Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-465-g-037-witness-records-a-root-dependent-v.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-576f3a3b
- **Timestamp:** 2026-08-12T19:21:48Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Needs Human:** no
- **Findings:** 2

**Verification-level findings:**

  1. **empty-output-success** (partial, heuristic) @ Verification:line 56
     - evidence: `D=$(mktemp -d) && /usr/bin/grep -v '^recursive_sees_ignored_search_root=' .context/working/.grep-witness > "$D/w" && ! WITNESS="$D/w" bash tools/_t465-witness-shape.sh >/dev/null 2>&1`
  2. **empty-output-success** (partial, heuristic) @ Verification:line 57
     - evidence: `D=$(mktemp -d) && sed 's/^recursive_sees_ignored_root_b=yes/recursive_sees_ignored_root_b=no/' .context/working/.grep-witness > "$D/w" && ! WITNESS="$D/w" bash tools/_t465-witness-shape.sh >/dev/null `

### 2026-08-12T19:21:44Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
