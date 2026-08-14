---
id: T-492
name: "termlink sender id drift: my rail posts now sign as the shared host key, defeating sender attribution"
description: >
  termlink sender id drift: my rail posts now sign as the shared host key, defeating sender attribution

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
created: 2026-08-14T06:51:51Z
last_update: 2026-08-14T06:57:45Z
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

# T-492: termlink sender id drift: my rail posts now sign as the shared host key, defeating sender attribution

## Context

On the AEF DM rail (`dm:0e7ee6cad65137fc:6a646ce8b1bc6560`) my posts at offsets 606,
607, 608 and 610 are signed `6a646ce8b1bc6560`. My post at offset 613 is signed
`d1993c2c3ec44c94` — which is the fingerprint **AEF's own messages arrive under**
(605, 609). Both were posted through the same MCP surface in the same session.

So on a shared record, sender-based attribution between the two peers is currently
defeated: their messages and mine carry one id. The only thing still separating us is
the `from_project` metadata that `tools/_t420-rail-attribution-gate.py` (PreToolUse)
requires on every content post.

**This is not a new class.** PL-138 (T-418, 2026-08-09) already named the exact
mechanism: *"Unforgeable is not identifying: a signed sender_id names a key the process
had in scope (TERMLINK_IDENTITY_FILE env precedence), not a host, project or session —
so 'cannot be forged' must never be promoted to 'can be relied on to attribute'."*
A drift in which key was in scope is the predicted consequence of exactly that.

The interesting question is therefore not "what broke" but the T-491 question: T-418
understood this in August and the change still happened unannounced — so is there an
instrument that should have caught it, and is it watched, unwatched, or unrunnable?

**Hard constraint on how this is measured.** `TERMLINK_IDENTITY_FILE` **auto-creates**
a keypair when its path does not exist, and `TERMLINK_AGENT_ID=<guess>` therefore
**mints** rather than reads. Any probe that "checks whether id X exists" by asking for
it brings X into existence. This task may not enumerate identities; it may only read
what is already on disk and what the running process reports about itself.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] The direction of the drift is established by **reading existing state only** —
      which identity file the MCP process signs from now, and what on-disk evidence
      exists for what it signed from at rail 610 — with the inference stated as an
      inference wherever the evidence does not close it. No guessed `TERMLINK_AGENT_ID`,
      no `TERMLINK_IDENTITY_FILE` pointed at a non-existent path.
- [ ] **Nothing is minted.** No call in this task sets `TERMLINK_AGENT_ID` or
      `TERMLINK_IDENTITY_FILE`, and `termlink_agent_identity` reports the same
      fingerprint/path at the end as at the start.
      *(Amended mid-task — see Decisions. The original wording asked for a directory
      inventory of `~/.termlink/`, which T-559 blocks. Recording the amendment rather
      than quietly satisfying the weaker form, because "a census that gets updated
      whenever it fires stops being a census" is a sentence I sent AEF at rail 608.)*
- [x] T-418's remedy is **located and its reachability measured, not assumed** — if it
      produced an instrument, `tools/_t451-unwired-guard-census.py` decides whether that
      instrument is watched / unwatched / unrunnable, and the verdict is recorded here.
      If T-418 produced no instrument, that is recorded as the finding instead.
- [x] `tools/_t420-rail-attribution-gate.py`'s coverage is stated as a **derived
      denominator, not a claim**: the set of termlink post verbs it matches, versus the
      set of post verbs that exist. Any verb it does not match is classified as an
      exclusion-with-a-reason or an absence (PL-181) — the two must not be left
      indistinguishable, which is the whole finding of T-490.
- [ ] AEF is told, on the rail, that the joint record now carries my messages under
      their fingerprint — because the correction is owed to the shared record, not just
      to my tree, and they cannot see it from their side without being told.

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

## Findings

### F1 — This is instance ELEVEN, not a new defect

`.context/project/concerns.yaml` `.concerns[25].context`, written 2026-08-09 by T-418:

    WRITING — ten of our own posts on the AEF rail went out under the shared key:
    offsets 75, 295, 299, 466, 469, 470, 472, 473, 474, 480.

So a post of mine signing as `d1993c2c3ec44c94` is a **recorded, measured, already-
reported** phenomenon. Rail 613 is instance eleven. The correction owed to AEF is
therefore much smaller than the one I set out to send, and materially different in
kind: not "attribution just broke" but "the thing we told you about at rail 509 is
still happening and nothing has been watching it happen."

### F2 — The drift is mid-session, and its cause is not decidable from inside T-559

T-418 measured the two surfaces as *distinct*:

    MCP   agent_identity          -> 6a646ce8b1bc6560   /root/.termlink/identity.json
    shell termlink agent identity -> d1993c2c3ec44c94   /root/.termlink/identity.key

`termlink_agent_identity` now reports `d1993c2c3ec44c94` **at `identity.json`** — the
two surfaces have converged onto one key. On the rail, my 606/607/608/610 are
`6a646ce8b1bc6560` and my 613 is `d1993c2c3ec44c94`; 610 and 613 are the same session,
so the change happened between two posts, not between two sessions.

At least two causes fit: `identity.json`'s contents were replaced with `identity.key`'s
keypair, or the MCP process re-resolved its identity path (restart, env precedence)
between the posts. **I cannot separate them**: T-559 blocks Bash from reading
`/root/.termlink/`, and that boundary is the operator's, so the inference stops here
rather than being routed around. Stated as an inference, per PL-138 — which predicted
exactly this: *a signed sender_id names a key the process had in scope, not a host,
project or session.*

### F3 — The instrument built to catch this is entirely dark

This is the finding worth having. T-418 built a detector for precisely "one fingerprint
carrying more than one `from_project`". Measured reachability of the whole apparatus:

    _t420-rail-attribution-gate.py   .claude/settings.json PreToolUse    WATCHED
    _t418-producer-attribution.py    verdict half                        dark (see below)
    _t418-capture-attribution.sh     capture half                        UNRUNNABLE
    tests/fixtures/termlink-attribution/*.jsonl   frozen 2026-08-09 23:46, no suite leg

The verdict half reads as live to `_t451-unwired-guard-census.py` for two reasons, and
neither is a caller:

1. Its name appears in `concerns.yaml` at `.concerns[25].context` — a 2,362-character
   **prose narrative** describing what it once measured. The census's `LIVE_SOURCES`
   greps that file whole-file while its own comment says *"gap closure conditions that
   RUN"*. Field-scoped check: the tool name occurs in exactly one field, and that field
   is prose. **A record of a past measurement is being counted as the capacity to
   measure.** Same defect as AEF's `next_id()` grepping `OBS-[0-9]+` over message
   bodies — the one I reported to them at rail 607, in our own file, one day later.
2. It is referenced by four other **tools**, and `tools/*` is a live source. Three of
   those four are themselves dead.

So: the gate that requires `from_project` metadata is live, which is why the two
projects are still distinguishable at all. Everything that would have *noticed* the
fingerprint collapse has not run since 2026-08-09. T-418's deliberate capture/verdict
split (adopted from T-360 to give the detector deterministic teeth) is what made the
capture the schedulable half — and only the verdict half got a home.

### F4 — Liveness is computed one-hop, so dead tools vouch for each other

Following F3.2 to its general form. The census unions "every tool named inside any
tool" into the live set, rather than computing reachability **from roots that are not
themselves tools**. Measured (`tools/*` population 165):

    roots (named by settings.json / cron / tests / agents / concerns)     40
    live by CLOSURE from those roots                                      49
    live by FLAT one-hop union (what the census does today)               71
    counted live ONLY because a DEAD tool references them                 22

Twelve of the 22 are `-teeth`/`-probe` one-shots the census excuses anyway. **Ten are
not**, and are reported as wired today:

    _gallery-claim-verify.py     _t350-verification-hygiene.py   _t353-classify.py
    _t421-enforcement-claim-drift.py   _t429-abstention-census.py   bpmn-cli.py
    concerns-schema.py   memory-application-census.py   tracked-secret-artifacts.py
    verification-hygiene.py

`_t400-schema-teeth.sh` is the clearest specimen: nine dead teeth scripts reference it,
so nine dead things make one dead thing look alive.

**This lands on yesterday's work.** T-491 generated `tools/unwired-guard-baseline.txt`
from this census's own `--json` and wired `--ratchet` as suite leg 73. The baseline's
own header says a hand-typed denominator is one nobody questions later — and I derived
it instead, and treated that as sufficient. It was not: deriving faithfully from a
source whose liveness definition is wrong just launders the error into a file that
looks authoritative. **Derived-not-typed protects against transcription error, not
against the source being wrong.** The 37 is short by up to ten.

Filed as its own task (one bug = one task); T-492 does not fix the census.

### F5 — The gate's DECLARED lists have expired, and one member fails silently

The gate is the best-built instrument in this whole apparatus: Rule 1 derived, Rules 0
and 2 declared, every exclusion carrying a reason and a remedy, and the declared halves
explicitly labelled *"a property of the tool surface on 2026-08-10/11"* with an
instruction to re-measure. AC4 is therefore not a criticism of its construction — it is
taking the re-measure the docstring asks for, four days later.

Measured against the live schemas today (2026-08-14):

    tool                          content key   attribution param   gate verdict
    channel_post                  payload       metadata            correct
    agent_post / agent_reply      text          project             correct
    ─────────────────────────────────────────────────────────────────────────────
    agent_send_auto_discover      message       (none)              ALLOW  ← silent
    emit_to                       payload       (none)              not in Rule 0
    channel_edit                  text          (none)              unfollowable remedy
    agent_edit                    text          (none)              unfollowable remedy
    chat_arc_broadcast            payload       from (unknown to gate) unfollowable remedy

**The severe one is `agent_send_auto_discover`.** `CONTENT_KEYS` is
`("payload","payload_b64","text")`; its content parameter is `message`. So `carried` is
empty and `decide()` returns 0 — allow. It posts a real envelope (its own schema says
"WRITES state", and it drives `channel.post` internally to a `dm:*` topic). That is an
unattributed content envelope on a shared topic, waved through at exit 0. It is the one
direction the gate's author called out as unrecoverable: *"an absent label cannot be
reconstructed later."*

`emit_to` is the sibling of `emit`, which IS in Rule 0 — a plain fix-one-of-N residue
(PL-145). The three edit/broadcast verbs are the T-426 unfollowable-remedy class
recurring: they get blocked with a message naming `metadata=` and `project=`, neither
of which exists on their schemas, which T-426 established converts a false positive
into an untracked bypass with an authoritative tone.

**And this is where F3 bites.** The gate documents its own fail-open as safe because
the miss is caught downstream:

    Fails OPEN on unparseable input (exit 0) ... The miss is visible afterwards to
    tools/_t418-producer-attribution.py, which is the detector this gate does not replace.

That detector has not run since 2026-08-09. **A fail-open is only as safe as the
detector it defers to, and nothing in the tree checks that the detector still runs.**
The gate's safety argument is sound and its cited compensating control is dark; from
inside the gate's source, those two situations are indistinguishable.

Filed as its own task — the declared fact expired exactly as its author predicted.

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

### 2026-08-14 — AC2 amended after T-559 blocked the check as written

- **Chose:** replace the `~/.termlink/` directory inventory with "no call in this task
  set `TERMLINK_AGENT_ID`/`TERMLINK_IDENTITY_FILE`, and `agent_identity` reports the
  same fingerprint/path at start and end", and record the amendment in the AC itself.
- **Why:** T-559 blocks Bash from reading `/root/.termlink/`. That boundary is the
  operator's security boundary, not an obstacle to route around. The amended form is
  the strongest check available inside it and still closes the actual risk, which is
  *me* minting a keypair by naming a path or id that does not exist.
- **Rejected:** satisfying the weaker form silently (this is the goalpost-move I warned
  AEF about at 608); asking the operator to lift T-559 for a diagnostic (the finding
  does not depend on it — F2 stands as an inference with the boundary named).

### 2026-08-14 — the census defect is not fixed under this task

- **Chose:** record F4 here, fix it under its own task.
- **Why:** one bug = one task, and the fix has a consequence that needs its own
  reasoning: correcting liveness grows the finding set, which makes suite leg 73's
  ratchet go red and forces a deliberate baseline regeneration. That is the ratchet
  working as designed on its first real firing, and it deserves not to be buried
  inside a task about termlink identity.
- **Rejected:** fixing it inline (hides a suite-red event inside an unrelated task);
  leaving it unrecorded until the ratchet fires on someone else (the backlog would be
  attributed to whatever change happened to be in flight).

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

### 2026-08-14T06:51:51Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-492-termlink-sender-id-drift-my-rail-posts-n.md
- **Context:** Initial task creation
