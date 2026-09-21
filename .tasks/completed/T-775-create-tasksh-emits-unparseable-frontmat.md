---
id: T-775
name: "create-task.sh emits unparseable frontmatter when a name or description contains a line break"
description: >
  create-task.sh emits unparseable frontmatter when a name or description contains a line break

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
created: 2026-09-21T14:30:24Z
last_update: 2026-09-21T14:35:50Z
date_finished: 2026-09-21T14:35:50Z
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

# T-775: create-task.sh emits unparseable frontmatter when a name or description contains a line break

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] **The defect is reproduced against the shipped script, on both fields, before
      anything changes.** Two reproductions, two different YAML exceptions — which is the
      evidence that these are two mechanisms and not one bug described twice:

      ```
      --name 'line one\nowner: injected'   ->  name: "line one
                                                owner: agent      <- the injected line
                                                ...               <- captured the substitution
                                                owner:            <- real field EMPTY
                                            yaml.safe_load: ParserError

      --description 'first line\nsecond line'
                                            ->  description: >
                                                  first line
                                                second line       <- unindented, block ended
                                            yaml.safe_load: ScannerError
      ```

      The first case is the one that matters most: it is OBS-363's symptom reached by a
      different route, and it is the single input that defeats T-774's line anchoring. The
      anchor honours lines, so an input that manufactures a line wins.

- [x] **A line break in the name is refused, loudly, at the input boundary.** Guard added
      beside the script's existing refusals, before any substitution runs. Live output:

      ```
      ERROR: Task name contains a line break — refused (T-775, OBS-364).
      ERROR:   A name becomes a YAML scalar, an H1 and a filename slug; a break makes it
      ERROR:   none of those, and the injected line can capture a frontmatter substitution.
      ERROR:   Put the detail in --description, which is a folded block and may span lines.
      ```

      Refused, not silently stripped. Stripping would rewrite the operator's input without
      telling them, which is the same class of defect as the substitution bug this guard
      sits next to — and the refusal names where the text should go instead, so it is a
      redirect rather than a wall.

- [x] **A multi-line description is CORRECTLY EMITTED, not refused.** Every line now
      carries the block indent, so `description: >` stays a folded scalar. Round-tripped:

      ```
      --description 'first line\nsecond line\n\nafter a blank'
        ->  description: >
              first line
              second line

              after a blank
        yaml.safe_load -> 'first line second line\nafter a blank\n'
      ```

      Folding and the paragraph break both survive. Refusing a multi-line description would
      have been the easier fix and the wrong one: it is the one field where a user has a
      real reason to write more than one line, so refusing it fixes the bug by removing the
      feature.

- [x] **The result parses.** Every leg feeds the emitted frontmatter to `yaml.safe_load`
      and compares the round-tripped value against what was passed in — not just "the file
      exists" or "the text appears". A file that parses but has lost or folded away the
      value is still a failure, and is caught as one.

- [x] **The T-774 bypass is closed and proven closed.** The attack was: put a break in
      the name so the second half becomes a real line starting with a frontmatter key, and
      the anchor itself then hands it the substitution. With the guard in place the task is
      never created, so there is nothing to capture. Asserted directly (leg 1), and the
      pre-fix control (leg 5) shows the same input still producing ParserError against the
      genuine old script.

- [x] **Negative controls on every new leg, driven from the real pre-fix code.** The
      controls run the ACTUAL previous script, retrieved with
      `git show fcc9904c:.agentic-framework/agents/task-create/create-task.sh`, not a
      reconstruction of what it used to do — a reconstruction only proves the
      reconstruction behaves as written. Both reproduce the original exceptions:

      ```
      PASS  pre-fix script reproduces the name defect (PARSE-FAIL:ParserError)
      PASS  pre-fix script reproduces the description defect (PARSE-FAIL:ScannerError)
      ```

      Plus a control on the guard itself: an ordinary single-line name must STILL be
      accepted and round-trip. Without that leg, a guard that refused every name would have
      scored green on leg 1. That is the exact shape of the three false negatives T-774's
      first blast-radius sweep produced, so it is checked for rather than hoped against.

      `tools/_t775-create-task-linebreak-probe.sh` — 6 legs, 6 pass. T-774's probe re-run
      as a regression: 13 pass.

- [x] **The structural blindness is registered as a gap, not just fixed.** **G-061**,
      severity high, status watching.

      The common factor across OBS-363, OBS-364 and OBS-365 is not the substitutions. It is
      that `create-task.sh` writes the file and exits 0 without ever parsing what it
      produced, so a task whose frontmatter does not load is indistinguishable at creation
      time from one that does. The failure surfaces later and elsewhere — ownership
      resolution, the audit's compliance checks — where it reads as an authoring problem
      rather than a generator problem. Three defects of one family in one path in two days,
      none found by any check; the first was found by a human reading a task file.

      The closure condition explicitly does **not** accept a fix to any individual
      substitution bug: G-061 is about the absence of the read-back. Its containment
      section states plainly that the two probes are probes and not gates — nothing runs
      them automatically. A probe described as a guard is how a gap gets closed while still
      open.

      **Gap id, second incident.** G-056 to G-060 are all vendored AEF ids already cited in
      this tree, so a sequential id would have collided again. G-061 was chosen by scanning
      G-056..G-090 for an id with zero references anywhere. That is the second time an id
      has had to be hand-picked this way — which is what turns SQ-9 from a tidiness concern
      into a live defect. The scan command is recorded in the entry's `id_note` so it is
      reproducible; writing the method down is containment, not a fix (PL-124). The
      namespace ruling is the operator's.

- [x] **The vendor divergence is declared.** Appended as `T-775`, `upstream: fix`, third
      entry for this path after T-660 and T-774 — one entry per task is the file's
      convention. `python3 tools/_t517-vendor-divergence.py` -> *"OK — every diverged path
      is declared, and every declared path still diverges"* (51 declared, 51 diverged).

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
         1. Run `bin/fw reviewer T-775`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-775 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
-->

## Verification

./tools/_t775-create-task-linebreak-probe.sh
./tools/_t774-create-task-substitution-probe.sh
bash -n .agentic-framework/agents/task-create/create-task.sh
python3 tools/_t517-vendor-divergence.py
python3 -c "import yaml; d=yaml.safe_load(open('.context/project/concerns.yaml')); c=d['concerns']; g=[x for x in c if isinstance(x,dict) and x.get('id')=='G-061']; assert len(g)==1 and g[0]['status']=='watching'"
test -f .fabric/components/tools-_t775-create-task-linebreak-probe.yaml

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

**Symptom:** a task created with a line break in `--name` or `--description` produced
frontmatter that `yaml.safe_load` refuses, and the script reported success.

**Root cause:** user-supplied text is injected into YAML without regard for line structure.
A break in the name splits a quoted scalar across two lines and manufactures a new line that
starts with a frontmatter key — which then captures a substitution. A break in the
description leaves continuation lines unindented, terminating the folded block scalar.

**Why structurally allowed:** the generator never reads back what it writes. There is no
point in the path where the emitted frontmatter is parsed, so a broken file is written,
moved into `active/`, and reported as created. Registered as **G-061**, because this is
wider than the two bugs fixed here and a fix to either does not close it.

**Why T-774 did not prevent it:** T-774 anchored the substitutions to lines. That removes
the mid-line capture class completely, and is defeated by exactly one thing — an input that
creates a line. The two fixes are complementary rather than one superseding the other: T-774
stops a key inside a value from capturing, T-775 stops a value from becoming a line. Stating
this because "the previous fix was incomplete" and "the previous fix has a precisely
identified boundary" are different claims, and only the second one is true here.

**Prevention:** `tools/_t775-create-task-linebreak-probe.sh`. Its controls run the genuine
pre-fix script out of git rather than a reconstruction, so the probe is anchored to real
prior behaviour rather than to my account of it. It is a probe, not a gate — nothing runs it
automatically, and G-061 carries that limitation rather than this task claiming it away.

**Method note.** The pre-fix control is pinned to commit `fcc9904c`. That is durable against
further commits and NOT durable against history rewriting; if the hash disappears the probe
fails loudly with "could not retrieve the pre-fix script", which is the correct behaviour —
a control that cannot be built must not be silently skipped.

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
     fw inception decide T-775 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-21T14:30:24Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-775-create-tasksh-emits-unparseable-frontmat.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-8815cf41
- **Timestamp:** 2026-09-21T14:36:09Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-09-21T14:35:50Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
