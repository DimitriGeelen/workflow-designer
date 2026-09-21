---
id: T-771
name: "The /approvals surface shows the operator nothing while five rulings wait in the queue"
description: >
  The /approvals surface shows the operator nothing while five rulings wait in the queue

status: work-completed
workflow_type: build
owner: agent
horizon: null
tags: []
components: [tools/_t771-approvals-overflow-probe.sh]
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-09-21T12:30:14Z
last_update: 2026-09-21T14:08:23Z
date_finished: 2026-09-21T14:08:23Z
# revisit_at: YYYY-MM-DD          # T-1451: set on DEFER decisions to enable G-055 daily revisit scan
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

# T-771: The /approvals surface shows the operator nothing while five rulings wait in the queue

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] **The waiting rulings are counted by the same predicate the surface uses, not by my
      reading of the task files.** `fw review-queue` (the canonical predicate, shared with
      the page since T-2075/T-2064) reports **67 tasks with Human ACs awaiting
      verification**. All three Arc-0 items are in it: T-596 (25d), T-732 (4d, NO-REC),
      T-736 (1d, GO).

- [x] **The page is FETCHED and its rendered body searched for those task ids — a 200 is
      not content.** Fetched: **454,423 bytes, HTTP 200**, and it contains T-732 (9
      occurrences), T-736 (3) and T-596 (4). **The page was never empty.** PL-260 is what I
      violated last session: I printed the URL, checked the status code, and reported that
      as availability. The 200 was true; what I inferred from it was not, and the operator
      paid for the difference with a wasted trip.

- [x] **Surface and predicate are compared, and whichever way they disagree is named at
      file:line with the mechanism.** They do not disagree about *what* is pending — they
      disagree about what is *shown*. Byte offsets in the fetched page settle it: the
      disclosure element opens at byte **154,010**; T-596 sits at **284,015**, T-732 at
      **370,052**, T-736 at **400,431**. All three render **inside** a `<details>` that is
      closed by default.

      Mechanism, two constants:
      - `_approvals_content.html:496` — `{% set _ac_cap = 10 %}`, a **positional** cut.
      - `approvals.py:370` — `results.sort(key=lambda t: (t["sort_priority"], -t["age_days"]))`.

      A positional cut through a sorted list is not a priority boundary. Priority group 0
      (any unchecked `[REVIEW]` AC) holds **63** of the 67 tasks, so the cut falls *inside*
      that group: **10 visible, 53 collapsed, all of the same priority.** The summary that
      hides them reads *"57 more verifications — **lower priority**, all still actionable"*.
      92% of what it calls lower-priority is the same top priority as the ten above it.

      The second-order effect is what selected *your* five. The secondary key is `-age_days`
      — **oldest first**. A ruling filed today sorts to the bottom of its group. T-736 is
      1 day old and gates Arc-0 clause 1; T-732 is 4 days old and gates clause 3. The newer
      and more urgent a ruling is, the more reliably this ordering buries it.

- [x] **The operator gets one copy-pasteable route to all five rulings that does not
      depend on the surface under investigation.** Verified by fetch — `?expand=verifications`
      renders the element as `<details class="ac-overflow" ... open>`:

      ```
      http://192.168.10.107:3013/approvals?expand=verifications
      ```

      And per-task, bypassing the list entirely: `/tasks/T-736`, `/tasks/T-732`,
      `/tasks/T-596`.

- [x] **If this is PL-261's class again it is escalated, not patched.** It is, and this is
      the **second recorded instance on this same element**. The template carries the first
      one in its own comment at `_approvals_content.html:500-502`:

      > *"Operator framing was 'rows don't render'; the rows DID render but the disclosure
      > was sub-perceptual."*

      T-2406 answered that by restyling the summary from a dashed border into a coloured CTA
      button — it made the disclosure **more visible**. The operator has now walked into it
      again with the button in place. So the remedy addressed perceptibility, and the defect
      is not perceptibility: it is that the label **asserts something false about what it
      hides**, and a more eye-catching button carrying a false claim is not an improvement.
      Escalated as **G-055**, not patched here — the fix changes what the operator's own
      queue shows and is not the agent's to decide unasked.

- [x] [REVIEWER] **The expanded view renders the Arc-0 rulings, and keeps rendering them
      after the poll cycle.** Driven in a real browser at
      `http://192.168.10.107:3013/approvals?expand=verifications`, probed twice with a
      13-second wait between — longer than the 10s poll interval that T-772 fixed.

      | property | at load | after poll |
      |---|---|---|
      | `details.ac-overflow` present | true | true |
      | `.open` | **true** | **true** |
      | `/tasks/T-736` anchor | present | present |
      | `/tasks/T-732` anchor | present | present |
      | `/tasks/T-596` anchor | present | present |
      | document title | `Approvals — Workflow designer` | `Approvals (77 pending) — …` |

      The title advancing is the proof the poll actually fired, rather than the probe
      sitting on first paint and reporting a state nothing had challenged yet.

      The cards carry their Human AC text, not just their ids — T-736 *"Rule on clause 1"*,
      T-732 *"Rule H1 — do roadmap Arcs 4–6 supersede the standing DEFERs"*, T-596
      *"Confirm the register reads H1 and H3 correctly as open"*.

      **Negative control:** the same query for `T-99999` returns absent, so the probe can
      tell a present card from a missing one rather than returning true for everything.

      **What is still wrong and is deliberately not fixed here:** the summary reads
      *"58 more verifications — lower priority, all still actionable"* over a population
      measured at 92% top-priority. That is G-055.

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
         1. Run `bin/fw reviewer T-771`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-771 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
-->

_No Human AC. The one criterion originally filed here was converted to an Agent AC — see
`[REVIEWER]` in the section above. Its Expected clause was entirely deterministic (an
element exists, a boolean is true, three anchors are in the DOM), which is the T-1811 /
T-1878 conversion rule. Routing it to the operator was a classification error on my side,
not a judgement that the check needed their eyes._

_The genuine operator judgement in this area is **G-055** — whether a cap of 10, an
oldest-first secondary sort and the label "lower priority" are the right design for their
own queue. That stays theirs and is not touched here._


## Verification

curl -sf "$(cat .context/working/watchtower.url)/approvals?expand=verifications" -o /tmp/.t771y.html && python3 -c "import sys; h=open('/tmp/.t771y.html',encoding='utf-8').read(); m=[t for t in ('T-736','T-732','T-596') if ('/tasks/'+t) in h or ('/review/'+t) in h]; sys.exit(0 if len(m)==3 and 'T-99999' not in h else 1)"
./tools/_t771-approvals-overflow-probe.sh --self-test
curl -sf "$(cat .context/working/watchtower.url)/approvals?expand=verifications" -o /tmp/.t771x.html && grep -q 'ac-overflow" style="margin:0.75rem 0;" open' /tmp/.t771x.html
grep -q '_ac_cap = 10' .agentic-framework/web/templates/_approvals_content.html
grep -q 'G-055' .context/project/concerns.yaml
./tools/_t771-approvals-overflow-probe.sh > /tmp/.t771probe.txt 2>&1 && grep -q 'expand=verifications' /tmp/.t771probe.txt

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

**Symptom:** the operator opened `/approvals` to rule on five items gating Arc-0 exit and
reported there was nothing to act on. The page was 454KB and contained all five.

**Root cause:** the visible list is cut **positionally** at 10 (`_approvals_content.html:496`)
through a list sorted by `(sort_priority ASC, age_days DESC)` (`approvals.py:370`). Priority
group 0 holds 63 of 67 tasks, so the cut lands inside a single priority group: 10 shown, 53
hidden, identical in priority. The disclosure hiding them is labelled *"lower priority"*.
Because the secondary key is oldest-first, the newest rulings sort to the bottom of their
group — which is exactly where the two Arc-0 rulings (1 and 4 days old) ended up.

**Why structurally allowed:** the summary's text is generated from **position** in the list
and never from the **composition** of what it hides. Nothing compares the two, so the label
cannot be wrong in any way the code can notice. Compounding it, PL-261: this surface's
healthy state and its failed state are visually identical — a disclosure concealing 53
top-priority rulings looks exactly like one concealing 53 pieces of trivia. And the
repeat is on record: T-2406 fixed the *visibility* of this same summary after the operator
reported the same confusion, which means the wrong property was treated as the defect.

**Prevention:** `tools/_t771-approvals-overflow-probe.sh` measures the priority composition
of the hidden region and is re-runnable (5 legs, 2 negative controls). That is **detection,
not prevention** — nothing calls it on a schedule and the label still says what it said.
G-055 carries the unclosed half, with the closure condition written so it cannot be
satisfied by making the button prettier a second time.

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

### SQ-9 (open) — the local gap register and the vendored framework's share one id space

- **The question for the operator:** how should this project's gap ids be namespaced
  against the vendored framework's, given that both use `G-NNN` and both are cited bare in
  the same documents?
- **Why it surfaced now:** the local register had reached G-052, so T-771's gap was due
  G-053. `G-053` is the vendored framework's revisit-scan gap and is cited **217 times** in
  this tree; `G-054` 56 times; `G-067` 201 times. A local G-053 would have been a different
  gap from the G-053 every existing citation points at, in the same sentences.
- **What I did instead, and its limit:** skipped to **G-055** and recorded the skip in the
  entry's `id_note`. That steps around the collision once. It does not fix it — the next
  local gap is due G-056, and nothing checks the peer space before allocating.
- **Why this is not the agent's to settle:** the options are a prefix change to the local
  register (touches every existing local citation), a reserved block, or accepting the
  collision and disambiguating by context. All three are conventions the operator and AEF
  have to share, and a convention one side adopts alone is not a convention.
- **Containment meanwhile (PL-124):** none. This is recorded honestly rather than
  mitigated. The register has no allocator to guard, so the next gap will be allocated by
  whoever writes it next, from the same sequence, with the same blind spot.

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-771 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-21T12:30:14Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-771-the-approvals-surface-shows-the-operator.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-ff5ae5ba
- **Timestamp:** 2026-09-21T14:08:27Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-09-21T14:08:23Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
