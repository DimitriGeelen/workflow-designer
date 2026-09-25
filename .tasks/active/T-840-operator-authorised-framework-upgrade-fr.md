---
id: T-840
name: "Operator-authorised framework upgrade from pinned 1.6.354; verify designer and termlink versions"
description: >
  Operator instruction 2026-09-25: 'Can we please upgrade to latest bleeding edge from AEF? Check we have the latest version of Workflow Designer and Termlink.' The bump is the operator's call per AEF's DM 536 section 1 ('The bump is your operator's call, not mine and not yours') and they have now made it - this task records that authorisation as the reason fw upgrade is being run at all. State at start: fw v1.6.354 vendored and pinned 1.6.354; termlink CLI 0.12.13 while live hub sessions report termlink_version 0.11.1766 (CLI/session skew); designer VERSION 0.13.0 with dist/ carrying 0.12.0 and 0.13.0 but vendor/designer/ holding only 0.12.0 and 0.8.0, so the vendored consumer pin is one release behind its own dist - independently found by the T-838 value review round 2. Expected to land AEF's T-3444 (commit d325112a5, CTL-029 narrowing), after which the .vendor-divergence.yaml entry for audit.sh can drop per AEF's own message. NOTE the upgrade rewrites PreToolUse hooks that govern this session, so it is dry-run first and the delta reported before anything is written.

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
created: 2026-09-25T06:37:14Z
last_update: 2026-09-25T06:37:14Z
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

# T-840: Operator-authorised framework upgrade from pinned 1.6.354; verify designer and termlink versions

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Finding — the upgrade could not run, and the reason is worth more than the upgrade

**Status: BLOCKED on one operator action. No framework file was written. `fw upgrade --dry-run`
refused and made no changes.**

### The defect: two readers of `upstream_repo` disagree

`lib/upstream.sh:22` resolves the field with a line-anchored pipeline:

```bash
repo=$(grep '^upstream_repo:' "${PROJECT_ROOT}/.framework.yaml" | sed 's/upstream_repo: *//' | tr -d '"')
```

Our `.framework.yaml`, via `cat -A`:

```
line 8:  upstream_repo: $
line 9:    https://github.com/DimitriGeelen/agentic-engineering-framework.git$
```

Valid YAML — a plain scalar continued on the next line, which is what any editor or yaml
round-trip produces for a long URL. `grep` matches line 8, `sed` strips the key, result is empty.

| reader | result |
|---|---|
| `lib/upstream.sh:22` pipeline | `[]` — **length 0** |
| `fw config get upstream_repo` | the URL — length 66 |
| `python3 yaml.safe_load` | the same 66-char string |

**Control** (because a measurement that only agrees with the bug proves nothing): the same
`grep|sed` pipeline against a file with the value on ONE line returns the URL correctly. So the
pipeline is not broken in general — it is broken on continuation lines specifically, which
isolates the cause instead of restating the symptom.

**Why this is worse than a parse bug.** `fw config get` reads the field fine. So the framework
holds two readers of one config key that disagree, and the upgrade path is wired to the weaker
one. A consumer who runs `fw config get` sees upstream configured; `fw upgrade` tells them it is
not, and prints a remediation instructing them to add a value already on line 8. PL-304 in a
config reader rather than a gate: the tool names a cause that is false, and the fix it suggests
cannot work.

**It also silently gated us off upgrades.** We sat at pinned 1.6.354 with no visible reason —
including for AEF's T-3444 (`d325112a5`, the CTL-029 narrowing) which they told us we could adopt
"on your next `fw upgrade`". There was no next upgrade available, and nothing said so.

`lib/upstream.sh:108-116` has the **mirror-image defect in the writer**: `--set` does
`sed -i "s|^upstream_repo:.*|upstream_repo: $set_repo|"`, which leaves an orphaned continuation
line behind when rewriting a wrapped value — so the writer can corrupt the file it is fixing.

Sent to AEF as a pickup request: `framework:pickup` **@148**. Second of the day; @147 carries the
T-2054 commit-exemption pair. Unrelated in mechanism, identical in shape — a tool naming a cause
it never checked.

### What I did NOT do, and why

**Did not pass `--from-upstream` with the URL.** Upstream auth resolves to the operator's own `gh`
identity and is not delegated. And they asked for **bleeding edge**: `--from-upstream` clones a
default branch, so if that GitHub mirror defaults to `master` — the consumer install surface under
the fast-forward release train (PD-309) — it would have pulled STABLE while reporting bleeding
edge, rewriting this session's PreToolUse hooks in the process.

**Did not edit `.framework.yaml`.** Collapsing the value onto one line unblocks us in one edit and
hides the defect from the next consumer. The defect is worth more than our upgrade.

### The two version answers the operator asked for

**Workflow Designer — the vendored copy is a DELIBERATE PIN and it is stale.**
`.agentic-framework/policy/designer-pin.yaml:105` declares
`vendored_path: "vendor/designer/aef-workflow-designer-0.12.0.html"`. So 0.12.0 is not drift; it
is AEF's declared pin. Audit concurs: `[WARN] Release lag: peer pin behind: 0.12.0 -> 0.13.0
(our release is 2 days old)` — "A fix a consumer cannot get is not shipped (G-024)". Advancing the
pin means AEF adopting our release; it is a declared value in **their** policy file, not ours, and
it is already one of the four open seam questions at sidecar @19.

**TermLink — the CLI is current, the running hub is a release behind.** CLI reports **0.12.13**;
the hub is running (PID 3071124) and all 73 live sessions carry `termlink_version: 0.11.1766` in
their metadata. The binary is newer than the process: the hub has not restarted since the 0.12.x
build landed. **Not restarted** — prohibited, and it would kill every session on this box
including four other projects' live workers.

### Open question only the operator or AEF can answer

Is AEF's **bleeding-edge** branch reachable on the GitHub mirror at all, or only on the OneDev
origin? If the mirror carries `master` only, `--from-upstream <that URL>` can never deliver
bleeding edge — and the error's own remediation text is misleading for a second, independent
reason.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [ ] **The delta was shown BEFORE anything was written.** `fw upgrade --dry-run` output is
      recorded in this task, and the operator saw it. The upgrade rewrites PreToolUse hooks that
      govern this session — running it unseen would change the gates enforcing the run, mid-run.

- [ ] **The pinned version moved UP, or the upgrade was a no-op, and which is stated.**
      `fw version` before and after are both recorded. `--force-downgrade` is NOT used: a lower
      pin is refused by T-1839 and that guard is not the agent's to bypass.

- [ ] **Every one of the 51 declared vendor divergences is re-checked after the upgrade, not
      assumed.** `fw audit --section structure` must still report all diverged paths declared.
      An upgrade that silently reverts a local fix, or leaves a now-redundant divergence entry
      standing, is the failure mode this criterion exists for.

- [ ] **AEF's T-3444 is verified present or absent by reading the code, not by trusting the
      version number.** AEF stated the CTL-029 narrowing landed in their commit `d325112a5`:
      the WARN must skip when `owner: human` AND at least one unticked `### Human` criterion
      exists, while still firing for abandoned agent-owned tasks, `owner:human`-all-ticked, and
      `owner:human`-no-Human-section. If present, the local `audit.sh` divergence entry is
      redundant and that is recorded — **dropping it is a separate decision, not this task's.**

- [ ] **The designer version question is answered with a measurement, not a version string.**
      `vendor/designer/` holds 0.12.0 and 0.8.0 while `dist/` and `VERSION` are at 0.13.0. Either
      the vendored copy is a deliberate pin (and the release-lag audit WARN is correct and
      expected) or it is drift. State which, with evidence. **Do not write `dist/` or bump
      `VERSION`** — a release is a sovereignty promise over immutable bytes (G-007).

- [ ] **The termlink CLI/session skew is measured and reported, not fixed.** CLI reports 0.12.13;
      live hub sessions report `termlink_version: 0.11.1766` in their metadata. Whether the hub
      is restarted to pick up the newer build is NOT an agent action — restarting the shared hub
      is prohibited, and it would kill every other project's sessions on this box.

- [ ] **`fw doctor` and `fw audit --section structure` are run after the upgrade and their
      before/after counts compared.** A regression from pass→warn or warn→fail is reported as a
      finding, not smoothed over. The baseline before this task was 20 pass / 6 warn / 0 fail.

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
         1. Run `bin/fw reviewer T-840`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-840 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
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
     fw inception decide T-840 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-25T06:37:14Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-840-operator-authorised-framework-upgrade-fr.md
- **Context:** Initial task creation
