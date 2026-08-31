---
id: T-645
name: "test_htmx_returns_fragment[/timeline] fails on a substring scan: task PROSE containing the characters <html"
description: >
  web/test_app.py:143 asserts '<html' not in html to prove an HX-Request returns a fragment rather than a full page. /timeline renders task and report PROSE, and one of those bodies contains the literal characters '<html' while discussing HTMX fragments. The fragment IS a fragment (the response opens with <nav>), so the assertion is a false positive: a character-level scan standing in for a structural question. The structural test is whether the response has a root <html> ELEMENT, not whether those five characters appear anywhere in the rendered body. Ninth member of the family first named in T-633. Found while verifying T-643.

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
created: 2026-08-30T18:08:53Z
last_update: 2026-08-31T11:37:51Z
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

# T-645: test_htmx_returns_fragment[/timeline] fails on a substring scan: task PROSE containing the characters <html

## Context

`web/test_app.py:143`, in `test_htmx_returns_fragment`, asserts:

```python
assert "<!DOCTYPE" not in html
assert "<html" not in html
```

The intent is structural: *an HX-Request must return a fragment, not a whole page.*
The implementation is a character scan over the entire response body.

**The first reading was wrong and is worth keeping visible.** I filed this as a false
positive — the response opens with `<nav class="wt-breadcrumb" …`, so it *is* a fragment,
and the match came from task prose discussing HTMX fragments. Then I measured what the
page actually emits:

```
GET /timeline (HX-Request)  -> 200, 13,324,594 bytes, starts with '<nav class=…'
  occurrences of '<html'    : 2
  occurrences of '&lt;html' : 0
  context: '… the SHAPE (a fragment, no <html>) and the CONSEQUENCE …'
```

Zero escaped. The page renders task prose containing `<` **as markup**. So the assertion
did not fire on nothing: it fired on a real `<html` in the delivered HTML — just not for
the reason it was written to detect. **A test can be structurally wrong and still be
right about the byte it found.**

That splits into two defects, and they belong to two tasks:

1. **This task:** the assertion answers "does this response have a root `<html>` element?"
   with "do these five characters appear anywhere?". Ninth member of the family named in
   T-633 — a character-level scan standing in for structure.
2. **T-646:** the timeline emits unescaped `<` from task bodies. That is the reason the
   characters were there, and it is a rendering defect independent of any test.

Fixing (1) alone would turn the test green while the page still emits raw tags — which is
precisely why the two are separate and why this task must not simply relax the assertion.

## Measured 2026-08-31, after T-646 closed

T-646 removed the bytes this test was firing on, so it is green today. It is still the wrong
instrument, and measurement says so in BOTH directions. Comparing the shipped scan against an
actual HTML parser (asking only "was an `html`/`head`/`body` start tag or a doctype emitted"):

| payload | substring scan | parser |
|---------|----------------|--------|
| `<HTML><BODY>x</BODY></HTML>` | **PASS** | FAIL `<html>,<body>` |
| `<!doctype html><p>x</p>` | **PASS** | FAIL `<!DOCTYPE>` |
| `<body><p>x</p></body>` | **PASS** | FAIL `<body>` |
| `<Html lang="en"><p>x</p></Html>` | **PASS** | FAIL `<html>` |
| `<!-- <html> --><p>hi</p>` | **FAIL** | PASS |
| `<script>var s = "<html>";</script>` | **FAIL** | PASS |
| `<nav class="x">hi</nav>` | PASS | PASS |

**Four ways to ship a full document past this test, and two ways to be failed by text that is
not markup at all.** Both halves are the same mistake: HTML tag names are case-insensitive and
Python's `in` is not, and a substring cannot tell whether it sits in a comment, a script body,
or an attribute value. The check is blind to the very thing it is named after.

Eleventh instance of the house failure mode — a character-level scan standing in for a
structural property — and the remedy is the one the other ten got: ask the parser.

Note on the boundary with T-646: the structural version does NOT absorb it. A raw `<html>` in
prose really is a start tag to any parser, so the new check still catches unescaped prose — it
just reports it as "a document shell was found", which is the honest thing a fragment test can
say. The escaping defect remains T-646's to detect, and T-646's own prober does.

## Acceptance Criteria

### Agent
- [x] The fragment assertion is structural: it decides whether the response has a root
      `<html>`/`<!DOCTYPE>` **element**, not whether a byte sequence occurs. Parsing the
      response, or anchoring on the start of the document, are both acceptable; a longer
      substring is not.
- [x] The new assertion is shown to still catch a genuine full-page response — a probe
      feeds it an actual rendered page (a non-HX GET of the same route) and the assertion
      must reject it. An assertion that cannot fail is not an assertion.
- [x] The new assertion does **not** silently absorb T-646: with the raw `<html>` still
      present in task prose, this test passes (it is a fragment) while T-646's own check
      fails (the page escapes nothing). The two must be independently observable.
- [x] All ten parametrised routes pass: `pytest -k test_htmx_returns_fragment`.
- [x] All four documents the old assertion ADMITTED are now rejected: `<HTML><BODY>`, lowercase `<!doctype html>`, a bare `<body>`, mixed-case `<Html>`
- [x] Both non-markup cases are ADMITTED: a tag name inside an HTML comment, and a tag name inside an inline `<script>` body
- [x] The detector has its own tests in `test_app.py`, positive and negative, so the new instrument is not itself unverified
- [x] The failure message names WHICH shell construct was found and on which path, rather than asserting a bare absence
- [x] `test_full_page_has_wrapper` — which asserts the OPPOSITE for non-HX responses — still passes, so the change did not simply weaken the pair
- [x] Suite total no worse than the post-T-646 baseline of 4 failed / 141 passed, with the 4 being the known `@pytest.mark.framework_repo` ones
- [x] The 13.3 MB `/timeline` fragment is recorded as an observation if it is not already
      one — it is not this task's to fix, but a 13 MB HTMX swap is worth someone knowing
      about.

**Evidence.**

`document_shell_constructs()` replaces the two substring assertions; `test_htmx_returns_fragment`
now calls it and reports what it found. Nine new parametrized tests cover the detector itself —
four shells it must catch, five payloads it must not.

Fed REAL rendered pages through the new detector (not synthetic strings):

```
/timeline   full-page GET -> ['<!DOCTYPE>', '<html>', '<head>', '<body>']
/timeline   HX-Request    -> clean (fragment)
/tasks      full-page GET -> ['<!DOCTYPE>', '<html>', '<head>', '<body>']
/tasks      HX-Request    -> clean (fragment)
/           full-page GET -> ['<!DOCTYPE>', '<html>', '<head>', '<body>']
/           HX-Request    -> clean (fragment)
```

So the assertion can still fail, on the real thing, for the real reason.

Suite: **4 failed / 141 passed → 4 failed / 150 passed.** Same four known
`@pytest.mark.framework_repo` failures; +9 from the new detector tests. Targeted run of the
affected classes: **24 passed**.

**On independence from T-646, stated precisely rather than waved at.** Each defect is
observable without the other: T-646's prober tests `linkify_tasks` as a function and its teeth
leg fails on the pre-fix source with no page served at all; T-645's four detector rows fail on
the old substring logic with no escaping involved. Neither hides the other. What is *not* true
is that the new fragment check ignores unescaped prose — a raw `<html>` in a page body is a
start tag to any parser, so it would still be reported here, as "a document shell was found".
That is the honest limit of what a fragment test can say about an escaping bug, and it is
written into the helper's docstring rather than left for the next reader to discover.

OBS-330 filed for the 13.3 MB fragment.

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

**Recommendation:** CLOSE — the change is an instrument swap with measured before/after in both
directions, and needs no ruling.

**Rationale:** The old assertion was wrong twice over and both are now demonstrated, not argued:
four document shells it admitted are rejected, two non-markup payloads it rejected are admitted.
The new detector is itself tested rather than trusted, and it is shown rejecting real rendered
pages, so it can still fail. Nothing here is taste or policy.

**Not done, deliberately:** the identical `<!DOCTYPE`/`<html` substring pattern may exist in
other test files; I did not sweep for it. Widening this task into a codebase-wide scan would
make it a second deliverable, and the sweep is the kind of thing that deserves its own
no-widening discipline rather than being tacked onto a fix.

## Verification

# Shell commands that MUST pass before work-completed. One per line.
# Lines starting with # are comments (skipped). Empty lines ignored.
# The completion gate runs each command — if any exits non-zero, completion is blocked.
python3 -m pytest .agentic-framework/web/test_app.py -q -k "htmx_returns_fragment or document_shell or merely_mentions or full_page_has_wrapper" 2>&1 | tail -1 | grep -q "24 passed"
python3 -c "import sys,importlib.util; spec=importlib.util.spec_from_file_location('t','.agentic-framework/web/test_app.py'); m=importlib.util.module_from_spec(spec); spec.loader.exec_module(m); assert m.document_shell_constructs('<HTML><BODY>x</BODY></HTML>')==['<html>','<body>']; assert m.document_shell_constructs('<script>var s = \"<html>\";</script>')==[]"
grep -q "document_shell_constructs(resp.data.decode())" .agentic-framework/web/test_app.py
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
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-08-30T18:08:53Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-645-testhtmxreturnsfragmenttimeline-fails-on.md
- **Context:** Initial task creation

### 2026-08-30T18:23:09Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
