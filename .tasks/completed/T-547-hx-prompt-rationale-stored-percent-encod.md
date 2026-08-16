---
id: T-547
name: "HX-Prompt rationale stored percent-encoded: server ignores htmx's URI-AutoEncoded companion header"
description: >
  HX-Prompt rationale stored percent-encoded: server ignores htmx's URI-AutoEncoded companion header

status: work-completed
workflow_type: build
owner: agent
horizon: null
tags: []
components: [tools/_t547-hx-prompt-decode-teeth.py]
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-16T16:32:42Z
last_update: 2026-08-16T16:56:10Z
date_finished: 2026-08-16T16:56:10Z
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

# T-547: HX-Prompt rationale stored percent-encoded: server ignores htmx's URI-AutoEncoded companion header

## Context

Two Watchtower routes take an operator rationale from the browser via htmx's
`hx-prompt` and store it as the audit record for a policy decision:

- `web/blueprints/bvp.py:750` — `fw bvp driver --remove` (**Sovereign**; the
  rationale IS the record of a policy edit)
- `web/blueprints/bvp.py:910` — proposal reject (not Sovereign, still the record)

XHR forbids non-ASCII in header values, so htmx handles it (htmx.min.js, `Cn`):

```js
function Cn(t,n,r){ if(r!==null){
  try{ t.setRequestHeader(n,r) }
  catch(e){ t.setRequestHeader(n, encodeURIComponent(r));
            t.setRequestHeader(n+"-URI-AutoEncoded","true") } }}
```

It percent-encodes on failure **and sets a companion header declaring it did**.
htmx is not at fault. Both server routes read `HX-Prompt` raw, never look at
`HX-Prompt-URI-AutoEncoded`, and never `unquote`.

Observed in `.context/bvp-driver-proposals.jsonl` — three rejected rows carry:

```
"rationale_decision": "Reject%20rationale%20(%E2%89%A530%20chars%20%E2%80%94%20why%20is..."
```

One em-dash, curly apostrophe, arrow or accented letter is enough to trigger it.
Pure-ASCII rationales round-trip cleanly, which is why it has gone unnoticed.

Vendored AEF code — fixable in-tree and upstreamable under G-008.

## Acceptance Criteria

### Agent
- [x] Both `HX-Prompt` read sites (`bvp.py` ~750 remove, ~910 reject) decode the
      value when `HX-Prompt-URI-AutoEncoded: true` is present
- [x] Decoding is **conditional on the companion header**, not unconditional: a
      rationale a human literally typed as `covers 50%20 of cases`, sent with no
      companion header (it is pure ASCII, so htmx does not encode), is stored
      verbatim and NOT corrupted to `covers 50  of cases`
- [x] Decode happens **before** the `len(...) < 30` gate, so the floor measures
      the real rationale and not its inflated encoded form
- [x] `tools/_t547-hx-prompt-decode-teeth.py` pins both directions (encoded+header
      → decoded; literal-percent without header → untouched) and asserts the
      length gate sees the decoded string
- [x] Teeth are mutation-verified: reverting the fix turns the probe red, and the
      probe names which route regressed
- [x] Wired into `tests/run-bridge-tests.sh`; full suite green
- [x] Divergence declared in `.agentic-framework/.vendor-divergence.yaml`

**Deliberately out of scope:** the three already-mangled rows in
`.context/bvp-driver-proposals.jsonl` are an append-only audit ledger. Rewriting
history to make a past record look better than it was is the wrong repair; the
rows stay as they are and this fix applies to new decisions only.

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

python3 tools/_t547-hx-prompt-decode-teeth.py
python3 tools/_t517-vendor-divergence.py
python3 -c "import ast,sys;ast.parse(open('.agentic-framework/web/blueprints/bvp.py').read())"
# The "every reader goes through the helper" property is leg 6 of the teeth
# script above, not a shell one-liner here: it has to name WHICH new route read
# the header raw, and a `-c` that greps a count cannot. My first draft of it as
# a one-liner was also simply wrong — `_hx_prompt()` matches its own def line
# and its docstring, so the count it asserted could never hold.

## Measured

Full bridge suite after the change: **106 passed, 0 failed, 452s wall-clock**.

Mutation results — four mutants, each caught by exactly the leg that owns it:

| Mutant | Behaviour | Result |
|---|---|---|
| never-decode (the pre-fix state) | `return raw` | legs 1, 3, 4 red |
| always-decode (the over-correction) | `return unquote(raw)` | leg 2 red |
| remove-route-only regression | raw header at `bvp_driver_remove` | leg 4 red |
| third route reads raw | a new function calling `request.headers.get("HX-Prompt")` | leg 6 red, naming line 76 |

The third mutant is the one that matters for trust: the probe **localises** to
the single regressed route rather than reporting a blanket failure. The fourth
is what stops this being T-509's shape yet again — legs 1 and 4 prove the two
routes that exist today decode, and would have said nothing about a third route
added next month.

## RCA

**Symptom.** Three proposal rejections in `.context/bvp-driver-proposals.jsonl`
record the operator's stated reason as
`Reject%20rationale%20(%E2%89%A530%20chars%20%E2%80%94%20why%20is...`.

**Root cause.** XHR forbids non-ASCII header values. htmx handles this correctly
and *announces* that it did — on a rejected `setRequestHeader` it retries with
`encodeURIComponent` and sets `HX-Prompt-URI-AutoEncoded: true`. Both server
routes read `HX-Prompt` and never read the declaration sitting next to it. The
defect is not a missing decode; it is **a protocol with two headers, consumed as
if it had one.**

**Why structurally allowed.** Three things had to line up:

1. *The failure is invisible in the common case.* A pure-ASCII rationale never
   triggers htmx's encode path, so the routes worked correctly for every
   rationale anyone happened to type without an em-dash. Correctness that depends
   on the character set of free-form human input will hold right up until it
   doesn't, and will look like it always held.
2. *The gate that should have noticed was measuring the wrong thing.* R6's ≥30
   floor exists to force a real reason. Percent-encoding **inflates** length, so
   the encoding pushed rationales *further* past the gate. A 26-character
   rationale encodes to 44 and clears a 30-character floor. The gate was not
   merely blind to the corruption — it was made more permissive by it.
3. *Nothing reads the field back.* The rationale is written to an audit ledger
   and never re-parsed, compared, or displayed anywhere that would make mojibake
   obvious. A field that is only ever written has no reader to complain.

**Prevention.** Leg 6 of the teeth, which is the part distinct from the fix:
exactly one raw read of `HX-Prompt` may exist in the file — the one inside the
helper. Legs 1 and 4 pin the two routes that exist today and would have stayed
green through a third route added later reading the header raw. That is T-509's
shape (an exemption or repair granted to the case that prompted it, never
generalised to the class) and this is the fourth encounter with it in a week, so
it is pinned at the population level deliberately rather than noted as a risk.

**The wider version, not fixed here.** Point 2 generalises past this bug: any
length floor applied to a value that may arrive transport-encoded measures the
encoding, not the content, and always errs toward permissiveness. R6 is enforced
in at least two places (this route and `fw bvp driver --propose`). Only the route
is fixed here. Whether the CLI path can receive an encoded rationale at all is
unmeasured, and I am not asserting it cannot.

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

### 2026-08-16T16:32:42Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-547-hx-prompt-rationale-stored-percent-encod.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-d8ded1c7
- **Timestamp:** 2026-08-16T16:56:12Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Needs Human:** no
- **Findings:** 1

**Per-AC findings:**

- **AC#6 (Agent)** — Wired into `tests/run-bridge-tests.sh`; full suite green
  - **AC-verify-mismatch** (narrow, heuristic) — `path=tests/run-bridge-tests.sh in: Wired into `tests/run-bridge-tests.sh`; full suite green`

### 2026-08-16T16:56:10Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
