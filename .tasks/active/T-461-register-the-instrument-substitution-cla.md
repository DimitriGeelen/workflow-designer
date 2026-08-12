---
id: T-461
name: "Register the instrument-substitution class: agent shell grep is a ugrep shim, every gate runs GNU grep"
description: >
  Register the instrument-substitution class: agent shell grep is a ugrep shim, every gate runs GNU grep

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
created: 2026-08-12T14:20:11Z
last_update: 2026-08-12T14:20:11Z
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

# T-461: Register the instrument-substitution class: agent shell grep is a ugrep shim, every gate runs GNU grep

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] **The class is registered in `concerns.yaml` as a gap, not left as a task finding.**
      T-460 fixed one wrong belief; the mechanism that produced it is still live and will
      produce the next one. Completed tasks archive and become invisible; the register is what
      the audit and Watchtower read. Registered with `origin_task: T-460`.
- [x] **The closure condition names what must become TRUE, and explicitly refuses the two
      fake-progress paths.** Closing T-460 does not close this. Removing the shim by hand in
      one shell does not close this either — the gap is that agent-side measurement and
      gate-side execution can diverge *silently*, so closure requires a check that would notice
      a future divergence, not the absence of today's.
- [x] **The `closure_check_command` runs and reports NOT_READY today**, printing both sides of
      the comparison rather than a bare verdict — the G-034 lesson applied to the gap's own
      gauge. A closure check that can only say "clean" is the defect this register exists to
      catch.
- [x] **The first gauge I wrote for this gap was blind in the gap's own way, and that is
      recorded rather than quietly replaced.** It called `bash -lc 'type -t grep'` and reported
      **READY** — because spawning a shell is precisely what escapes the shim, so the check
      could only ever see the subject and never the instrument. A gauge for
      "instrument ≠ subject" that runs inside the subject can only return "they agree". The
      replacement takes the agent-side value from a **witness file written from the agent's own
      tool shell**, treats a missing or stale (>30d) witness as NOT_READY rather than READY,
      and prints both sides. Today: agent `function` / ugrep 7.5.0 versus gate `file` /
      GNU grep 3.11 → NOT_READY. Third level of the same class in one window.
- [x] **The register still parses and the schema check is no worse than before.** Entry count
      and watching count reported; `concerns-schema.py` exit code compared before and after
      rather than asserted from memory (the error T-457 corrected in itself). Measured: rc 1
      before and rc 1 after, and the ONLY output delta is the pre-existing unmodelled `context`
      field going from 8 entries to 9 — i.e. my entry inherits T-441's known schema gap and
      introduces nothing new.

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
# The register is parsed with yaml, not grepped, and every grep below is /usr/bin/grep by
# absolute path — for the reason this gap exists.
python3 -c 'import yaml,sys; d=yaml.safe_load(open(".context/project/concerns.yaml")); e=d if isinstance(d,list) else d.get("concerns",d); w=[x for x in e if x.get("status")=="watching"]; g=[x for x in e if x.get("id")=="G-037"]; print("register entries %d  watching %d  G-037 present %d" % (len(e), len(w), len(g))); sys.exit(0 if len(g)==1 and len(e)>=34 else 1)'
python3 -c 'import yaml,sys; e=yaml.safe_load(open(".context/project/concerns.yaml")); g=[x for x in e if x.get("id")=="G-037"][0]; missing=[k for k in ("type","status","severity","title","detected","origin_task","context","evidence","decision_trigger","related_tasks","closure_check_command") if not g.get(k)]; print("G-037 required fields missing:", missing); sys.exit(0 if not missing else 1)'
python3 -c 'import yaml,sys,subprocess; e=yaml.safe_load(open(".context/project/concerns.yaml")); c=[x for x in e if x.get("id")=="G-037"][0]["closure_check_command"]; r=subprocess.run(["bash","-lc",c],capture_output=True,text=True); print(r.stdout.strip()[:400]); import json; j=json.loads(r.stdout); sys.exit(0 if j["verdict"]=="NOT_READY" and j["agent_shell_grep_type"]=="function" and j["gate_shell_grep_type"]=="file" else 1)'
test -f .context/working/.grep-witness && /usr/bin/grep -q 'type=function' .context/working/.grep-witness
python3 tools/concerns-schema.py > /tmp/.t461-schema.out 2>&1; test 1 -eq "$(python3 -c 'import subprocess;print(subprocess.run(["python3","tools/concerns-schema.py"],capture_output=True).returncode)')"

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

### 2026-08-12T14:20:11Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-461-register-the-instrument-substitution-cla.md
- **Context:** Initial task creation
