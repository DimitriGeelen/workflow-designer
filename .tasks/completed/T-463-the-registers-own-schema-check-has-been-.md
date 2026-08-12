---
id: T-463
name: "The register's own schema check has been red since G-029 was registered, and the one measurement that would have caught it was taken on a file that does not exist"
description: >
  The register's own schema check has been red since it shipped, and the one measurement that would have caught it was taken on a file that does not exist

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
created: 2026-08-12T17:01:56Z
last_update: 2026-08-12T17:07:24Z
date_finished: 2026-08-12T17:07:24Z
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

# T-463: The register's own schema check has been red since G-029 was registered, and the one measurement that would have caught it was taken on a file that does not exist

## Context

`python3 tools/concerns-schema.py` returns **rc 1 with a SCHEMA FAIL**: the field `context`
is carried by 9 entries (G-029..G-037) and read by no code — the G-027 shape, sitting in the
register that catalogues G-027.

It was found by accident. T-462 ran the validator, got rc 1, and that contradicted T-457's
recorded measurement of "rc 2, one line of output". The only `sys.exit(2)` in the script is
`PyYAML unavailable`, and PyYAML imports fine in every interpreter on this host — so rc 2
could not have come from the script at all. It came from `python3` refusing to open a path
that does not exist: `python3 .agentic-framework/tools/concerns-schema.py` returns **rc 2,
one line**, and that is the path T-457 guessed.

So T-457's AC — *"the register's own schema check is no worse than before the edit… identical
before and after my edit"* — is true and worthless: it was identical because the checker never
ran, both times. This is the class already named in `tools/_t350-teeth.sh`'s header ("a leg
that accepts any non-zero exit banks syntax errors as evidence", T-338/T-343/T-348) and it is
the fourth instance on this arc — this time inside a task whose entire subject was correcting
a number taken from memory rather than measurement.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] **How long the check has been red is MEASURED, not asserted.** The task title says
      "since it shipped" and that is a hypothesis until the validator is run against the
      register as it stood at the validator's own introducing commit (`c7d0dedd`, T-400) and
      at each commit that changed the `context` field count. If it was green at introduction
      the title is wrong and gets corrected rather than quietly kept.
- [x] **The measurement runs the script against historical registers WITHOUT clobbering the
      live one.** Earlier in this window I twice overwrote `.context/project/concerns.yaml`
      with a historical version and restored it, verifying the sha256 both times. It worked
      and it was still the wrong shape: a check that requires damaging the artefact it
      inspects will eventually be run by someone who skips the restore. Copy the script and
      the historical register into a scratch tree instead — the script derives `REGISTER`
      from its own `__file__`, so relocating it is sufficient.
- [x] **The `context` FAIL is resolved by the validator's own prescribed route, and which
      route is a judgment recorded here.** The script offers two: rename to a field code
      reads, or add to `PROSE` with a one-line note saying what it is for. `context` is
      genuinely explanatory prose for a human reading the register — same standing as
      `evidence`, which is already in `PROSE`. So `PROSE` is the honest answer and renaming
      would be making the field pretend to a readership it does not have.
- [x] **The fix is falsified before it is believed.** With `context` added to `PROSE` the
      validator must return rc 0; with the line reverted it must return rc 1 naming `context`
      again. A green that cannot be made red proves nothing, which is the whole T-350 teeth
      lesson applied to a one-line change.
- [x] **Whether anything CALLS this validator is established and stated.** If no gate, hook,
      audit section or P-011 block invokes it, then fixing the FAIL changes nothing that runs
      and the entry belongs in G-035's population (instrument with no live caller) — and that
      must be said plainly rather than left implied by a green.
- [x] **T-457 is corrected by APPENDING, not by editing its checkbox.** Its AC text and its
      `[x]` stay exactly as they are; a dated correction goes underneath recording that the
      rc-2 baseline was `python3` failing to open a nonexistent path. Same treatment T-459
      received in this window and for the same reason: a completed task that silently changes
      its findings is a worse artefact than one carrying its own retraction.

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

python3 tools/concerns-schema.py
d=$(mktemp -d) && mkdir -p "$d/tools" "$d/.context/project" && cp .context/project/concerns.yaml "$d/.context/project/" && python3 -c "import re,sys;s=open('tools/concerns-schema.py').read();s2=re.sub(r'\n    \"context\":.*?\n.*?red since 2026-08-09\)\",','',s,flags=re.S);sys.exit(9) if s2==s else open(sys.argv[1],'w').write(s2)" "$d/tools/concerns-schema.py" && out=$(cd "$d" && python3 tools/concerns-schema.py 2>&1); rc=$?; rm -rf "$d"; echo "falsified: without the PROSE line rc=$rc and the message names: $(echo "$out" | /usr/bin/grep -o 'context' | head -1)"; test "$rc" -eq 1 && echo "$out" | /usr/bin/grep -q 'context'
# The historical verdict must be taken with the validator AS IT STOOD, not with today's fix
# applied. The first version of this leg copied the CURRENT script over each historical
# register and reported ab1f111b as green — because the fix was in it. That is the same
# instrument-vs-subject error the whole window is about, committed inside the leg measuring
# how long the subject went unnoticed. tools/concerns-schema.py has exactly one commit
# before today (c7d0dedd, T-400), so pinning the script to that commit is the true baseline.
d=$(mktemp -d) && mkdir -p "$d/tools" "$d/.context/project" && git show c7d0dedd:tools/concerns-schema.py > "$d/tools/concerns-schema.py" && git show c7d0dedd:.context/project/concerns.yaml > "$d/.context/project/concerns.yaml" && (cd "$d" && python3 tools/concerns-schema.py > /dev/null 2>&1); a=$?; git show ab1f111b:.context/project/concerns.yaml > "$d/.context/project/concerns.yaml" && (cd "$d" && python3 tools/concerns-schema.py > /dev/null 2>&1); b=$?; rm -rf "$d"; echo "validator pinned to its own introducing commit: at c7d0dedd rc=$a (expect 0 = GREEN at ship, 0 context-carriers); at ab1f111b, the first commit carrying a context field, rc=$b (expect 1 = RED). So 'since it shipped' was WRONG by two commits and the title was corrected to 'since G-029 was registered'"; test "$a" -eq 0 && test "$b" -eq 1
# A mention is not a call. The first version of this leg counted FILES containing the string
# and excluded the two it expected, which left tools/tracked-secret-artifacts.py looking like
# a caller when the hit is one word inside a docstring. Count INVOCATIONS instead, and print
# every reference so the classification is checkable rather than asserted.
refs=$(/usr/bin/grep -rn 'concerns-schema' --include='*.sh' --include='*.py' --include='*.json' . 2>/dev/null | /usr/bin/grep -v '^\./\.git/' | /usr/bin/grep -vE '^\./\.context/'); calls=$(echo "$refs" | /usr/bin/grep -E '(python3?|bash|sh)[[:space:]]+[^[:space:]]*concerns-schema' | /usr/bin/grep -v '_t400-schema-teeth\.sh:'); echo "references outside .context records: $(echo "$refs" | /usr/bin/grep -c .) — of which INVOCATIONS outside its own one-shot teeth: $(test -z "$calls" && echo 0 || echo "$calls" | /usr/bin/grep -c .). No gate, hook or audit section runs this validator, so fixing its FAIL changes nothing that RUNS: it belongs in G-035's population."; test -z "$calls"
/usr/bin/grep -q 'CORRECTION (T-463)' .tasks/completed/T-457-*.md && test 0 -eq "$(/usr/bin/grep -c 'rc 2, one line of output\*\* — and' .tasks/completed/T-457-*.md | /usr/bin/grep -c '^0$')" && echo "T-457 carries the dated correction and its original AC text is untouched"
python3 -c "import glob,re;p=glob.glob('.tasks/completed/T-457-*.md')[0];s=open(p).read();assert 'rc 2, one line of output' in s, 'the withdrawn claim was deleted rather than preserved';i=s.index('rc 2, one line of output');assert s[:i].rfind('- [x]') > s[:i].rfind('- [ ]'), 'the AC carrying the corrected claim is no longer ticked — it must stay exactly as it was';print('T-457 unchanged: withdrawn claim preserved verbatim, checkbox still [x]')"

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

### 2026-08-12T17:01:56Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-463-the-registers-own-schema-check-has-been-.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-24b428d4
- **Timestamp:** 2026-08-12T17:07:26Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** yes
- **Findings:** none

- **Layer-1 escalations:** 1
  1. **destructive-action** (high) — Destructive operation in verification or AC
     - matched: `rm -rf`

### 2026-08-12T17:07:24Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
