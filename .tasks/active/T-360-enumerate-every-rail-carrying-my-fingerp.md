---
id: T-360
name: "Enumerate every rail carrying my fingerprint before claiming a peer is silent"
description: >
  A second DM topic went unread for ~24 days while I repeatedly reported 'AEF is silent' from a one-topic measurement. termlink_agent_inbox cannot distinguish all-clear from an untracked cursor store, so the natural check is uninformative. Need a rail sweep that enumerates all topics carrying my fingerprint and refuses to report all-clear from an empty cursor store.

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
created: 2026-08-03T18:26:59Z
last_update: 2026-08-03T19:02:14Z
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

# T-360: Enumerate every rail carrying my fingerprint before claiming a peer is silent

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] A sweep exists that enumerates **every** topic carrying my fingerprint and
      reports per-topic unread — not just the rail I habitually watch.
      `tools/rail-sweep.py`. DM coverage is **exhaustive** (every `dm:` shape carrying
      `6a646ce8b1bc6560`); found 2, including the one I was not watching.
      **Scope stated rather than implied:** non-DM topics are *watchlist-scoped*, and
      the sweep prints the denominator (`2 watched of 549`) plus `547 NOT swept.
      Absence from this report is not evidence of quiet.` Claiming "every topic" over a
      watchlist would have been G-022 one level up — the same silence, better formatted.
- [x] The sweep **refuses to report all-clear from an untracked cursor store.** This
      is the whole point: `termlink agent inbox` returns `unread_topics: []` both when
      nothing is unread and when `subscribe --resume` has never run, so its reassuring
      answer and its uninformative answer are byte-identical. The sweep must report
      UNKNOWN and exit non-zero rather than inherit that ambiguity.
      Live, 2026-08-03T21:27Z: exit **3 UNTRUSTED**. Measured simultaneously, same
      `my_id`, both `ok: true` — `agent_dms` 2 topics / **99 unread**, `agent_inbox`
      **0 topics / 0 unread**. The two instruments disagree by 99 messages.
- [x] Teeth, by mutation rather than by reading: with the cursor store absent or
      empty the sweep must NOT print all-clear — demonstrated, not asserted.
      `tools/_t360-rail-sweep-teeth.py`: **18 mutations, each moved the verdict as
      predicted.** Critically it also proves **ALL-CLEAR is reachable** (3 cases) —
      without that the refusal would be a constant, and a constant discriminates
      nothing. One over-broad matcher was caught and narrowed by these teeth: keying
      the frontier flag on `total>0` fired on a topic whose only envelope sits *at*
      offset 0, manufacturing a finding; it now keys on `last_offset > ack_up_to`.
- [x] The sweep is proven to rediscover the topic that was actually missed
      (`dm:6a646ce8b1bc6560:d1993c2c3ec44c94`, unread from offset 1 for ~24 days).
      A sweep that cannot find the known miss is not evidence of coverage.
      Found. And the discriminator is asserted explicitly: the cursor store misses
      **both** topics the content walk sees. Had the two sources agreed, this sweep
      would be measuring a difference that is not there and would pass for the wrong
      reason — so that agreement is itself a failing case.
- [x] G-022 stays `watching` until prevention exists — reading the backlog was
      mitigation, and this task is not done when the inbox is merely empty.
      Still `watching`. I have **not** flipped it: concern state is operator-only.
      Prevention now exists (this sweep + its teeth), so the flip is *available* to the
      operator — see the recommendation in `## Decisions`.

**Assertion the root cause demanded, and where it lives:** check 3 (IDENTITY) fails the
sweep (exit 4) unless `identity.fingerprint == dms.my_id == inbox.my_id`. Three teeth
cases drive it, one of which is exactly the trap: an enumeration scoped to the CLI
fingerprint `d1993c2c3ec44c94` instead of mine.

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

# The teeth harness IS the gate. Its own exit code is the verdict, so no chaining
# and no context question arises (see the errexit warning above). It asserts every
# mutation moves the verdict, that ALL-CLEAR is reachable, that the known miss is
# rediscovered, and that the two sources actually disagree on live data.
python3 tools/_t360-rail-sweep-teeth.py

# The sweep must still REFUSE on the live snapshot (exit 3, not 0). `! cmd` is the
# whole verdict, so this line is judged on the thing it names.
! python3 tools/rail-sweep.py --max-age-min 999999 > /dev/null 2>&1

# Identity coherence in the captured snapshot — the assertion the root cause demanded.
python3 -c "import json; d=json.load(open('.context/working/rail-snapshot.json')); assert d['identity']['fingerprint'] == d['dms']['my_id'] == d['inbox']['my_id'], 'identity incoherent'"

## RCA

**Symptom:** For ~24 days I reported "AEF is silent" to the operator and on the rail.
At the moment of writing this, the peer DM rail held **95 unread past my ack frontier**
and a second DM topic held 4 more, unread from offset 1.

**Root cause — two layers, and the second is the dangerous one.**

*Layer 1, the instrument.* `termlink agent inbox` derives unread from a local cursor
store. When that store has no entry for an identity it returns `unread_topics: []` with
`ok: true` — byte-identical to a genuine all-clear. Its own documentation says so. An
absent measurement is rendered in the vocabulary of a clean bill of health, and absence
cannot carry a decision.

*Layer 2, the verification path.* The obvious cross-check — "just confirm from the CLI" —
**is the trap, not the fix.** Probed 2026-08-03:

| surface | identity file | fingerprint |
|---|---|---|
| MCP `agent_identity` | `/root/.termlink/identity.json` | `6a646ce8b1bc6560` |
| shell `termlink agent identity` | `/root/.termlink/identity.key` | `d1993c2c3ec44c94` |

and the path the MCP surface names **does not exist in the shell's view of the
filesystem at all**. So the two surfaces do not merely hold different keys, they do not
share a coordinate system in which one could be pointed at the other. The CLI answers
fluently, correctly, and **about a different agent**. A wrong answer that is
indistinguishable from a right one, produced by the very tool you would reach for to
check the first tool.

**Why structurally allowed:** nothing anywhere asserted that the identity *asking* the
question was the identity the answer was *about*. Every component behaved correctly in
isolation. The defect lived in the seam, which is precisely where no component's tests
look. And the failure mode was agreement — the instrument failed toward the reassuring
answer, so it produced no symptom to investigate. Compare a wrong `LOST`: that sends you
to debug working code and gets caught within the hour. A wrong all-clear gets published
and becomes a citation.

**Prevention (distinct from the fix):** `tools/rail-sweep.py` check 3 makes identity
coherence a *failing condition* (exit 4), so an enumeration scoped to someone else can
no longer be reported as mine. Check 5 refuses an all-clear that rests on an untracked
cursor store (exit 3) rather than inheriting its ambiguity. Check 7 refuses one that
rests on an unset ack frontier. Check 8 prints the non-DM denominator so watchlist scope
cannot pass itself off as exhaustive. `tools/_t360-rail-sweep-teeth.py` holds all of it
in place by mutation — including the case that matters most, that ALL-CLEAR is still
*reachable*, since a refusal that can never lift is a constant and a constant
discriminates nothing.

**Not yet prevented, stated plainly:** 547 non-DM topics are unswept. The sweep says so
in its own output rather than going quiet about it, but saying so is disclosure, not
coverage.

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

### 2026-08-03 — the sweep verifies a capture, it does not gather one
- **Chose:** capture through the MCP termlink surface, verify with a Python script that
  takes the capture as input.
- **Why:** the shell cannot reach my identity's rails *at all* — different fingerprint,
  and the identity path the MCP surface reports is not present in the shell's
  filesystem view. A shell script that shells out to `termlink` would sweep
  `d1993c2c3ec44c94` and report it as mine. That is the exact defect, rebuilt.
- **Rejected:** (a) shell script calling the CLI — reproduces the bug; (b) pointing the
  CLI at the MCP identity via `TERMLINK_IDENTITY_DIR` — the file it would need is not
  there; (c) letting the sweep both gather and verify — impossible from one process,
  and pretending otherwise would hide the seam that caused this.

### 2026-08-03 — UNTRUSTED is a louder verdict than BACKLOG, and does not lift on mitigation
- **Chose:** exit 3 (UNTRUSTED) when the cursor store is untracked, distinct from exit 1
  (BACKLOG). It keeps firing after the backlog is drained.
- **Why:** draining 99 messages is mitigation. The instrument is still unable to tell
  quiet from untracked, so an all-clear from it is still worthless. A guard that goes
  green once the mess is cleaned up teaches that cleaning up was the fix. Teeth case
  `backlog drained but cursor store STILL untracked -> UNTRUSTED` pins this.
- **Rejected:** folding it into BACKLOG — it would go silent the moment I caught up,
  which is exactly when I would stop thinking about it.

### 2026-08-03 — recommendation to the operator on G-022 (not actioned)
- **Chose:** leave G-022 at `watching` and recommend, rather than flip it.
- **Why:** concern state is operator-only under the Authority Model, and a broad
  autonomous directive delegates initiative, not authority.
- **What the operator may now weigh:** prevention exists and has teeth. What is *not*
  covered is the 547 unswept non-DM topics and the fact that the identity split itself
  is unrepaired — the sweep detects the split, it does not close it. My reading: G-022
  is narrower than it was but not closed, because the seam that produced it is intact.

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

### 2026-08-03T18:26:59Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-360-enumerate-every-rail-carrying-my-fingerp.md
- **Context:** Initial task creation

### 2026-08-03T18:59:53Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
