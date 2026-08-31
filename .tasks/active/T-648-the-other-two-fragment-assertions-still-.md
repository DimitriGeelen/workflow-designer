---
id: T-648
name: "the other two fragment assertions still use the substring scan, and are weaker than the one T-645 fixed"
description: >
  the other two fragment assertions still use the substring scan, and are weaker than the one T-645 fixed

status: started-work
workflow_type: refactor
owner: agent
horizon: now
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-31T11:49:45Z
last_update: 2026-08-31T11:49:45Z
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

# T-648: the other two fragment assertions still use the substring scan, and are weaker than the one T-645 fixed

## Context

T-645 replaced one fragment assertion with a parser and closed with an explicit admission:

> *"the identical `<!DOCTYPE`/`<html` substring pattern may exist in other test files; I did
> not sweep for it."*

Swept. It does, twice:

| site | assertion |
|------|-----------|
| `web/test_app.py:854` `test_cockpit_htmx_returns_fragment` | `assert "<!DOCTYPE" not in html` |
| `web/test_costs.py:240` `test_costs_htmx_returns_fragment` | `assert "<!DOCTYPE" not in html` |

Same intent as the one T-645 fixed — *this HX response is a fragment, not a document* — and
**both are weaker than the version T-645 started from**, because neither carries the `<html`
half at all. So on top of the case-sensitivity hole (`<!doctype html>` in lowercase sails
past a `"<!DOCTYPE"` scan), these two also admit a bare `<HTML><BODY>…` shell with no doctype
in front of it. Three ways through each, where the fixed one had four.

This is the twelfth and thirteenth instances of the house failure mode. There is now a tested
detector, so the fix is to call it rather than to write a third variation of the check.

**Why one task and not two:** one deliverable — *the fragment assertions in this suite all use
the tested detector*. Two identical call-site swaps against one shared helper is a single
refactor, not two bugs with two root causes.

The helper currently lives in `test_app.py`. `test_costs.py` importing from a sibling test
module would be the wrong shape, so it moves to `conftest.py`, which both already load.

## Acceptance Criteria

### Agent
- [x] `document_shell_constructs()` lives in `web/conftest.py`; `test_app.py` and `test_costs.py` both use that one definition, and no copy of the logic remains in either
- [x] Both `test_cockpit_htmx_returns_fragment` and `test_costs_htmx_returns_fragment` decide via the detector — no `<!DOCTYPE`/`<html` substring assertion survives anywhere in the web test suite
- [x] Both now reject what they used to admit: a lowercase `<!doctype html>` document AND a bare `<HTML><BODY>` shell with no doctype (demonstrated by feeding both payloads to the detector, not asserted in prose)
- [x] The detector's own nine tests move with it and still pass
- [x] Both refactored tests still pass against the real routes, and their failure messages name which shell construct was found
- [x] Suite total no worse than the post-T-645 baseline of 4 failed / 150 passed on `test_app.py`, and `test_costs.py` unchanged in pass count
- [x] A grep proving the pattern is gone from the suite is recorded in the evidence — the same grep that found these two

**Evidence.**

The two sites used the WEAKER form — only `"<!DOCTYPE" not in html`, no `<html` half — so they
admitted more than the one T-645 fixed. Fed the detector the payloads each used to let through:

```
<!doctype html><html><body>x</body></html>   old=ADMITTED   now=REJECTED ['<!DOCTYPE>','<html>','<body>']
<HTML><BODY>x</BODY></HTML>                  old=ADMITTED   now=REJECTED ['<html>','<body>']
<nav class="x">hi</nav>                                     now=ADMITTED []
<script>var s = "<html>";</script>                          now=ADMITTED []
```

Both directions, on the shared definition both call sites now use.

The sweep that found them, re-run after the change — the only surviving hits are inside the
helper's own docstring, where it quotes the code it replaced:

```
conftest.py:69:        assert "<!DOCTYPE" not in html
conftest.py:70:        assert "<html" not in html
```

No live assertion of that shape remains in the web suite.

`test_costs.py` → **24 passed**. `test_app.py` → **4 failed / 150 passed**, identical to the
post-T-645 baseline, same four known `@pytest.mark.framework_repo` failures. Targeted run of
every affected class → **24 passed**.

**One thing worth naming, since it nearly went wrong.** The helper moved into `conftest.py`
and my first instinct was to have `test_costs.py` do `from conftest import ...`. That works
only by accident of pytest's sys.path insertion. A plain function in `conftest.py` is not
importable *because* it lives there — pytest auto-loads conftest for fixtures and hooks, not
for names. So it is exposed as a fixture, which is what actually makes it shared. The
reasoning is in the fixture's docstring rather than left as a trap for the next person who
adds a third call site.

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

## Recommendation

**Recommendation:** CLOSE — a two-call-site refactor onto an instrument that was already
tested when it landed. No ruling needed.

**Rationale:** T-645 closed with a written admission that it had not swept for siblings. This
is the sweep, and it found two — both weaker than the original. That is the whole task: the
admission is now discharged rather than standing in a completed task where nobody would look
for it again.

**What this says about the family.** Instances 12 and 13 were found by grepping for the exact
shape of instance 11, in the same repository, minutes later. The failure mode is not that
these checks are hard to spot — it is that nobody looks until one of them fires. A grep is
cheap; the reason it does not happen is that a green test suite gives no prompt to run one.

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

python3 -m pytest .agentic-framework/web/test_costs.py -q 2>&1 | tail -1 | grep -q "24 passed"
python3 -m pytest .agentic-framework/web/test_app.py -q -k "htmx_returns_fragment or document_shell or merely_mentions or full_page_has_wrapper" 2>&1 | tail -1 | grep -q "24 passed"
grep -q "def document_shell_constructs" .agentic-framework/web/conftest.py
test 0 -eq "$(grep -c 'def document_shell_constructs' .agentic-framework/web/test_app.py)"
test 0 -eq "$(grep -rn '\"<!DOCTYPE\" not in\|\"<html\" not in' --include=*.py .agentic-framework/web/ | grep -vc conftest.py || true)"

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

### 2026-08-31T11:49:45Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-648-the-other-two-fragment-assertions-still-.md
- **Context:** Initial task creation
