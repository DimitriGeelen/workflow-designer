---
id: T-462
name: "G-037 second axis: agent-side recursive grep skips gitignored paths, and focus.yaml is one of them"
description: >
  G-037 second axis: agent-side recursive grep skips gitignored paths, and focus.yaml is one of them

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
created: 2026-08-12T16:55:19Z
last_update: 2026-08-12T16:55:19Z
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

# T-462: G-037 second axis: agent-side recursive grep skips gitignored paths, and focus.yaml is one of them

## Context

AEF reported at rail 572 that the same harness shim I registered as G-037 has a **second**
divergence I did not find: the wrapper passes `--ignore-files`, so an agent-side `grep -r`
reads a different FILE SET than the gate's `/usr/bin/grep -r`. Their framing — semantics vs
inputs as two axes of one class, with inputs the worse one because nothing about the pattern
looks unusual — is right. This task verifies it on our tree rather than inheriting it, bounds
its scope, and extends G-037 to cover both axes.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] **The second axis is MEASURED here, not inherited from the peer.** A peer's finding
      about my own environment is still a claim about my environment until I run it. Fixture:
      a directory with `.gitignore` containing `*.log` and a matching file. Agent shell
      `grep -rl` omits it; `/usr/bin/grep -rl` finds it.
- [x] **Its scope is bounded, and the bound is the useful part.** The divergence is
      RECURSION-ONLY: an explicitly named file and a shell glob are read identically by both
      (measured 1 == 1 both ways). So `grep pattern file` is safe and only `grep -r` is
      suspect — which is a far narrower correction than "distrust every grep".
- [x] **AEF's flag attribution is corrected where it was imprecise.** They named
      `--ignore-files --hidden -I --exclude-dir=.git` as the cause. `--hidden` REDUCES the
      divergence — hidden files are included agent-side, and `.hidden.txt` appears in both
      result sets. `--ignore-files` is the flag that does the damage. Reported back, because
      an accepted finding with a wrong mechanism attached becomes folklore.
- [x] **The instance that matters on this tree is named, and it is governance state.** Only
      30 paths are gitignored here and most are `__pycache__`, but the set includes
      `.context/working/focus.yaml` and `.context/working/session.yaml`. A recursive sweep of
      `.context/working/` for the CURRENTLY FOCUSED task id returns 0 files agent-side and 2
      gate-side — both of them the files that record that focus.
- [x] **G-037 carries both axes and its gauge fails on either.** The register entry names
      semantics and inputs as one class with two faces, and `closure_check_command` returns
      NOT_READY if the agent-side grep is a function, OR its version is not GNU, OR its
      recursive sweep cannot see a gitignored file. Any one axis diverging is enough to keep
      the gap open.
- [x] **The witness records the file-set fact, written from the shell that has the shim.**
      The agent-side value cannot be obtained by spawning, because spawning is what escapes
      the shim — so it is supplied by `.context/working/.grep-witness`, which now carries
      `recursive_sees_ignored=` alongside type and version. Missing or stale is NOT_READY.

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
# NOTE ON WHAT THIS BLOCK CAN AND CANNOT SEE (the task's own subject):
# P-011 runs each line in a subshell, where `grep` is /usr/bin/grep. So the gate can
# measure the GATE side of the divergence and never the AGENT side — measuring the agent
# side requires not spawning, and the gate is a spawn. That asymmetry is not a limitation
# to work around; it is the gap. The agent-side half is therefore supplied by the witness
# file, and leg 2 checks the witness exists, is fresh, and carries the new axis.

d=$(mktemp -d) && printf 'NEEDLE\n' > "$d/x.log" && printf '*.log\n' > "$d/.gitignore" && n=$(cd "$d" && /usr/bin/grep -rl NEEDLE . | wc -l) && rm -rf "$d" && echo "gate-side recursive sweep sees the gitignored file: $n (expect 1; the agent shell sees 0)" && test "$n" -eq 1
python3 -c "import os,time;w='.context/working/.grep-witness';assert os.path.exists(w),'no witness — the agent-side value cannot be recovered by spawning';d=dict(l.split('=',1) for l in open(w).read().splitlines() if '=' in l and not l.startswith('#'));age=(time.time()-os.path.getmtime(w))/86400;print('witness age_days=%.2f type=%s recursive_sees_ignored=%s'%(age,d.get('type'),d.get('recursive_sees_ignored')));assert 'recursive_sees_ignored' in d,'witness predates the file-set axis';assert age<30,'witness stale'"
d=$(mktemp -d) && printf 'NEEDLE\n' > "$d/x.log" && printf '*.log\n' > "$d/.gitignore" && a=$(/usr/bin/grep -c NEEDLE "$d/x.log") && rm -rf "$d" && echo "named-file read: $a — the bound is recursion-only, so 'grep pattern file' is NOT suspect" && test "$a" -eq 1
git check-ignore -q .context/working/focus.yaml && git check-ignore -q .context/working/session.yaml && id=$(/usr/bin/grep -oE 'T-[0-9]+' .context/working/focus.yaml | head -1) && n=$(/usr/bin/grep -rl "$id" .context/working/ | wc -l) && echo "gate-side sweep of .context/working for the focused id $id finds $n file(s), and both are gitignored — so the agent-side sweep finds 0 while focus is recorded in two places" && test "$n" -ge 2
python3 -c "import yaml;d=yaml.safe_load(open('.context/project/concerns.yaml'));items=d if isinstance(d,list) else d.get('concerns',d);g=[c for c in items if c['id']=='G-037'][0];blob=g['context']+' '.join(g['evidence']);assert 'ignore-files' in blob or 'gitignored' in blob,'G-037 still records only the semantics axis';assert 'recursive_sees_ignored' in g['closure_check_command'],'gauge does not test the file-set axis';print('G-037 records both axes and its gauge tests the file-set one')"
python3 -c "import yaml,subprocess;d=yaml.safe_load(open('.context/project/concerns.yaml'));items=d if isinstance(d,list) else d.get('concerns',d);g=[c for c in items if c['id']=='G-037'][0];r=subprocess.run(['bash','-lc',g['closure_check_command']],capture_output=True,text=True);print(r.stdout.strip()[:500]);assert 'NOT_READY' in r.stdout,'gauge reports READY while the shim is still installed — it is not measuring what it claims'"

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

### 2026-08-12T16:55:19Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-462-g-037-second-axis-agent-side-recursive-g.md
- **Context:** Initial task creation
