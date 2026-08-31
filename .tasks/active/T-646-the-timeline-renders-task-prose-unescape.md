---
id: T-646
name: "the timeline renders task prose unescaped: raw < from a task body reaches the browser as markup"
description: >
  GET /timeline returns 2 occurrences of the literal characters '<html' and 0 of '&lt;html'. The source is task prose discussing HTMX fragments; the page emits it as markup rather than text. Measured via app.test_client() on 2026-08-30. Task bodies are authored in-repo so this is not an external injection vector, but any task text containing < renders as a tag and can silently break the page's structure. Found while investigating T-645, which fired on exactly this byte for an unrelated reason. Sibling: T-645 fixes the ASSERTION, this task fixes the ESCAPING; fixing either alone leaves the other defect standing.

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
created: 2026-08-30T18:24:16Z
last_update: 2026-08-31T11:22:15Z
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

# T-646: the timeline renders task prose unescaped: raw < from a task body reaches the browser as markup

## Context

`web/app.py:162` registers the Jinja filter as:

```python
app.jinja_env.filters["linkify_tasks"] = lambda text: Markup(linkify_tasks(text))
```

and `shared.py:1086` `linkify_tasks()` substitutes `T-\d{3,}` into `<a href=…>` over the
RAW string. So the order is *linkify, then declare trusted* — and the declaration covers
the whole string, not just the anchors the function added. Every other character of the
source prose is handed to the browser as markup.

**The source is a file on disk.** `blueprints/timeline.py:159` reads `session_narrative`
from handover frontmatter, falling back to a regex capture of the "Where We Are" section.
That is committed markdown written by sessions, i.e. arbitrary prose. Measured on the live
Watchtower at `/timeline`: 2 occurrences of a raw `<html` reach the browser as a tag, from a
task narrative that was *discussing* HTML fragments. The same paragraph also shows a live
`<a href="/tasks/T-2309">` — which is what proves the string was marked safe rather than
merely containing a stray character.

This is XSS-shaped: a narrative containing `<script>` would execute. It is not an open
door — the input is our own repository, not a network attacker — so the honest severity is
*rendering corruption with an injection shape*, and the fix is the same either way.

Two filters call it: `templates/timeline.html:23,50` and `templates/fleet.html:319`. Both
pass plain prose, so escaping is correct for both; neither is passing pre-built HTML that
escaping would break.

Fix: escape first, then linkify. The anchors are then the only markup the function created,
which is the only markup it is entitled to vouch for.

## Acceptance Criteria

### Agent
- [x] `linkify_tasks()` escapes HTML metacharacters (`<`, `>`, `&`, `"`) BEFORE inserting anchors, so the returned Markup vouches only for the anchors it added
- [x] The feature is not lost: `T-123` in prose still becomes `<a href="/tasks/T-123">T-123</a>`, and a T-ref adjacent to escaped metacharacters still links
- [x] A narrative containing `<script>alert(1)</script>` yields no `<script` element in the rendered output — it renders as visible text
- [x] Live `/timeline` (HX-Request) contains ZERO raw `<html` originating from prose; the occurrences that were raw are escaped
- [x] Exactly ONE escaping pass, not two: input `a & b` produces `a &amp; b`, never `a &amp;amp; b` (a reader sees a single `&` on screen)
- [x] A prober `tools/_t646-*.sh` pins the above and has teeth: reverting to the pre-fix `Markup(linkify_tasks(raw))` order makes it fail by naming the injected element
- [x] `python3 -m pytest .agentic-framework/web/test_app.py -q` shows no NEW failures against the pre-change baseline (the baseline is 5 known failures: 4 `@pytest.mark.framework_repo` + the T-645 assertion)

**Evidence.**

`bash tools/_t646-timeline-prose-is-escaped-before-it-is-trusted.sh` → **8 passed, 0 failed.**

Function-level, on the live code:

| input | output |
|-------|--------|
| `see T-123 for <html> and & stuff` | `see <a href="/tasks/T-123">T-123</a> for &lt;html&gt; and &amp; stuff` |
| `<script>alert(1)</script> in T-2309` | `&lt;script&gt;alert(1)&lt;/script&gt; in <a href="/tasks/T-2309">T-2309</a>` |
| `a & b` | `a &amp; b` (one pass, not `&amp;amp;`) |

Teeth: the prober extracts the REAL `linkify_tasks` source out of `shared.py`, reverses the two
tokens the fix introduced, executes that, and requires the injection back —
`'<script>alert(1)</script> in <a href="/tasks/T-2…'`. It reports COULD-NOT-MEASURE rather
than passing if the function is ever rewritten into a shape the mutation cannot find.

Live board, `/timeline` with `HX-Request`: **0 raw `<html`, 4 escaped** (was 2 raw / 2 escaped).
Watchtower had to be restarted to pick the change up — it had been running 4d 14h on pre-fix
code, and the prober's end-to-end leg said exactly that rather than going green on stale bytes.

Suite: **5 failed / 140 passed → 4 failed / 141 passed.** No new failures; one *fixed* — the
T-645 assertion `test_htmx_returns_fragment[/timeline]` was firing on these very bytes and now
passes. The remaining 4 are the pre-existing `@pytest.mark.framework_repo` ones a vendored
consumer is expected to fail. **T-645 is NOT closed by this** — its assertion is still a
substring scan, it just no longer has anything to scan. That is its own task, as filed.

## Visual Verification

`.playwright-mcp/t646-after.png` — element screenshot of the affected narrative on the live
board, read back with the Read tool. The sentence renders as
`the SHAPE (a fragment, no <html>) and the CONSEQUENCE`, with the tag visible as text.

Live DOM at the same element: `textShowsTag: true`, `noHtmlElementInside: true`,
`anchorsStillLive: 17` — the escaping took effect and the linkification survived it.

**What the reader saw BEFORE, measured rather than assumed.** Parsing the exact pre-fix output
in the browser:

```
innerHTML: 'the SHAPE (a fragment, no <html>) and the CONSEQUENCE'
textContent -> 'the SHAPE (a fragment, no ) and the CONSEQUENCE'
elements created: 0
```

So the practical harm was not the injection shape at all. **THE BROWSER ATE THE TAG AND
SILENTLY DELETED WORDS FROM THE OPERATOR'S OWN NOTES** — no error, no gap, just a sentence
that reads as if it were written wrong. A narrative describing HTML was the one kind of
narrative this page could not display, and the page said nothing about it.

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

**Recommendation:** CLOSE — mechanically verified in both directions, nothing here needs a ruling.

**Rationale:** One-line ordering defect (escape before you vouch), a prober with teeth that
reverses the real source rather than pinning a copy, a live-board before/after, and a screenshot
read back. No taste question, no policy question, no sovereignty question. The one judgement I
made without asking is recorded plainly: I called the severity *rendering corruption with an
injection shape* rather than "XSS", because the input is our own repository rather than a
network attacker — and the fix is identical under either reading, so nothing turns on it.

**Adjacent, deliberately not done here:** `blueprints/inception.py:34` and `blueprints/tasks.py`
also return `Markup(...)`. Those wrap markdown that has already been through
`render_markdown_safe()`, which is a different contract; auditing them is a separate task, not
a silent widening of this one.

## Verification

# Shell commands that MUST pass before work-completed. One per line.
bash tools/_t646-timeline-prose-is-escaped-before-it-is-trusted.sh
bash -n tools/_t646-timeline-prose-is-escaped-before-it-is-trusted.sh
python3 -W error::SyntaxWarning -c "import sys; sys.path.insert(0,'.agentic-framework'); import web.shared"
python3 -c "import sys; sys.path.insert(0,'.agentic-framework'); from web.shared import linkify_tasks as l; assert '<script' not in str(l('<script>x</script> T-1')), 'unescaped script survived'"
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
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-08-30T18:24:16Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-646-the-timeline-renders-task-prose-unescape.md
- **Context:** Initial task creation

### 2026-08-31T11:22:15Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
