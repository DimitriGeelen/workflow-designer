---
id: T-733
name: "Contact AEF on R6/R7 after the rail came back empty: re-establish the ask and record that the cited offsets no longer resolve"
description: >
  Operator instructed hub start + AEF contact on R6/R7 (H6). Hub started clean: topic store holds only broadcast:global, agent-chat-arc absent. Every rail offset cited in arc-0-exit-clauses.yaml and operator-decisions.yaml (602/643/650/734/737/741/742) is now dangling. Re-post the R6/R7 ask stating the discontinuity explicitly, with producer attribution, and annotate the registers so the lost citations are visible rather than silently broken.

status: work-completed
workflow_type: build
owner: human
horizon: now
tags: [arc-002, ewcr, termlink, h6, counterparty]
components: []
related_tasks: []
arc_id: ewcr-governed-delivery
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-09-16T19:13:53Z
last_update: 2026-09-16T19:17:35Z
date_finished: 2026-09-16T19:17:35Z
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

# T-733: Contact AEF on R6/R7 after the rail came back empty: re-establish the ask and record that the cited offsets no longer resolve

## Context

The operator instructed: start the TermLink hub, contact AEF about R6/R7.

**The hub had been `not_running`, so this was a start, not a restart of a live conversation.**
It came back with an **empty topic store** — `broadcast:global` at count 0, `agent-chat-arc`
absent. 54 sessions re-registered from `/var/lib/termlink`; the message log did not, because the
hub runtime lives under `/tmp/termlink-0`.

Consequence: every rail offset our registers cite is dangling — 650 (AEF's clause-1 refusal),
643 (the original R6/R7 routing), and 602/734/737/741/742 (H3's supersession evidence).

**The content survives; the re-readability does not.** AEF's refusal is quoted verbatim in
`arc-0-exit-clauses.yaml`, so the fact is preserved. What is gone is anyone's ability to go to
the rail and check that our file reports it faithfully. That is the same shape as an inception
rationale asserting "Confirmed:" with no referent — the defect T-704/T-705 reconstructed two
artifacts to repair.

So the post was written to **state the discontinuity** rather than read as a thread continuation.
A message that looks continuous but shares no history is how an unratified value acquires the
appearance of a decision — precisely what H3 documents, one layer out.

Live AEF sessions observed on this host include `ewcr-r6-policy-cards` (task T-3350,
cwd `/opt/999-Agentic-Engineering-Framework`), so R6 may already be in flight on their side.
The post asks rather than assumes.

Per roadmap §2.3 the post is **transport evidence, not collaboration completion**. It does not
close H6 and nothing here ratifies anything.

## Acceptance Criteria

### Agent
- [x] Hub started at operator instruction; `agent-chat-arc` recreated with `retention=forever` (it did not exist)
- [x] R6/R7 ask posted via the MCP surface with producer attribution `from_project: 832-Workflow-designer` — the Bash `termlink channel post` path was not used
- [x] The post states the rail discontinuity explicitly and disclaims being a thread continuation, rather than presenting itself as one
- [x] `arc-0-exit-clauses.yaml` carries `rail_citation_integrity` naming all seven dangling offsets, and **no clause state was changed** — verified by re-parse

### Human
- [ ] [REVIEW] Rule on the rail substrate: is a hub whose runtime sits in `/tmp` an acceptable source for citations the Arc-0 register treats as evidence? Options recorded in the register, none actioned.
  **Steps:** read the `rail_citation_integrity` block in `docs/research/executable-workflow/arc-0-exit-clauses.yaml`
  **Expected:** a ruling on recovery vs re-pinning clauses to quoted content only
  **If not:** the registers keep citing offsets that silently do not resolve

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

# The register must still parse, must name the dangling offsets, and must NOT have moved any
# clause verdict. The last assertion is the load-bearing one: this task edited a governance
# register, and the check exists to prove the edit was additive.
python3 -c 'import yaml,sys;d=yaml.safe_load(open("docs/research/executable-workflow/arc-0-exit-clauses.yaml"));r=d["rail_citation_integrity"];cs=[(c.get("attestation"),c.get("definition_ratified")) for c in d["clauses"]];ok=(sorted(r["dangling_offsets"])==[602,643,650,734,737,741,742] and r["clause_state_changed"] is False and cs==[(None,False)]*3);print("offsets",r["dangling_offsets"],"| clause states",cs);sys.exit(0 if ok else 1)'

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

### 2026-09-16 — The task was filed as a transport act and turned into an evidence-integrity finding

- **What changed:** At filing this was "post the R6/R7 ask to AEF." Checking the rail *before*
  posting — rather than posting and then citing it — showed the hub's topic store was empty and
  `agent-chat-arc` did not exist. The ask was never the hard part. The finding is that seven
  offsets our Arc-0 register treats as evidence no longer resolve, including the one carrying
  AEF's clause-1 refusal.
- **Plan impact:** "Contact AEF" alone would have produced a post at offset 0 of a fresh topic
  that read as a continuation of `EWCR-ARC0-ATTEST-832`. Later citing that as "the thread" would
  have manufactured continuity that does not exist — the exact mechanism H3 already documents
  ("carried forward by repetition, which is how an unratified value acquires the appearance of a
  decision"). The post was rewritten to open by disclaiming continuity instead.
- **Triggered:** `rail_citation_integrity` block added to `arc-0-exit-clauses.yaml` (additive
  only — the verification leg asserts all three clause verdicts are unmoved, so a later edit that
  changed one goes red). Sovereign question surfaced as this task's Human AC: is an offset into a
  `/tmp`-backed log an acceptable identifier for a governance citation? Not answered here.
- **What I nearly got wrong:** the reflex fix is "move the hub off /tmp." That prevents the next
  loss and repairs none of the existing dangling citations, while feeling like a resolution.
  Recorded in the Recommendation as the reason for DEFER rather than a GO on the ops change.

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

## Recommendation

> ### ⚠ CORRECTION 2026-09-19 — READ BEFORE RULING. THIS TASK'S PREMISE WAS WRONG TWICE.
>
> **Do not rule on the rationale below without reading this first.** The recommendation
> still stands, but two of the facts it was argued from do not.
>
> **What this task recorded:** the hub came back empty, so every rail offset the Arc-0
> register cites is dangling, and the R6/R7 ask had to be re-sent to a new topic.
> **Then OBS-353 recorded:** the re-ask is *gone*, the rail round-tripped to a restored
> log, and AEF was never in a position to read it.
> **Both overstated the loss.** Re-measured 2026-09-19 by enumerating threads rather than
> searching: the `EWCR-ARC0-ATTEST-832` chain is **intact and readable today** — roots
> `@602 @629 @639 @643 @734 @737 @741 @744 @777 @786`, one linear chain. **`@643` — the
> R6/R7 routing post this register cites — reads back right now.** So
> `rail_citation_integrity.dangling_offsets` in `arc-0-exit-clauses.yaml` is wrong on its
> face, and the clause-3 evidence was never actually unreachable.
>
> **Root cause, and it is the same defect in both observations:** each rested on a
> `termlink_channel_search` whose result **limit** truncated the hit set, read as though it
> were exhaustive. A search returning N hits under `limit=N` has said nothing about hit N+1.
> Filed as **OBS-354**.
>
> **What survives and is still true:** the 2026-09-16 re-ask I posted to the recreated
> `retention: forever` topic *is* lost, because the restore displaced that topic. One post
> of mine is gone; the counterparty's cited evidence is not.
>
> **What this does to the ruling in front of you.** The sovereign question gets *narrower*,
> not weaker. It is no longer "is a volatile log fit to hold our governance citations" —
> the citations survived. It is: **a restore silently replaced one log with another under
> the same topic name, and nothing in our tooling noticed.** The ops fix (move the hub off
> `/tmp`) still repairs none of that.
>
> **Also found:** all eleven EWCR threads report last activity at exactly `2026-09-07 19:36`,
> identical to the minute — a bulk-replay artefact of the restore. **Offsets and content on
> this rail are citable; timestamps are not.**
>
> **Not yet done, and deliberately not done by me:** `arc-0-exit-clauses.yaml` still carries
> the incorrect `rail_citation_integrity` block. It is a governance register and correcting
> it is your call, not mine — the exact edit needed is listed in the operator actions.
> **AEF has been told of this correction** (agent-chat-arc `@1536`, threaded under their `@786`).


**Recommendation:** DEFER the substrate ruling; no action needed on the post itself.

**Rationale:**

Two separable things happened. The ask was re-sent and needs nothing from you — it is transport,
it carries producer attribution, and per roadmap §2.3 it ratifies nothing and closes nothing.
The substrate question is the one that needs a ruling, and it should NOT be answered today
because the cheap answer is wrong in a specific way.

The tempting fix is "move the hub runtime off /tmp so this cannot recur." That prevents the next
loss and does nothing about the citations already dangling — and those are the ones doing
evidentiary work right now. Arc-0 clause 1 rests on AEF's refusal at offset 650. We quote it
verbatim, so the content is safe; what we cannot do any more is let a third party check that our
quotation is faithful. Relocating the runtime would leave that exactly as broken while producing
the feeling that it was handled.

The narrower and more useful question is whether an offset into a volatile log was ever an
appropriate identifier for a governance citation. If the answer is no, the repair is to re-pin
these clauses to quoted content plus a counterparty-held reference, which survives a hub restart
by construction — and that is a register-schema decision, not an ops change.

Recommending DEFER rather than GO because choosing between those two is a sovereignty act about
what this project accepts as evidence, and an agent picking the ops fix because it is closer to
hand would be answering the easier question and reporting it as the harder one.

**Evidence:**

- Hub restarted at operator instruction 2026-09-16; came back with `broadcast:global` count 0 and
  no `agent-chat-arc`. Measured via `termlink_channel_list` on the live hub, not inferred.
- `termlink_doctor --strict`: 7 pass, 1 warn, 0 fail. Sessions survived (54 registered, all
  responding, from `/var/lib/termlink`); the message log did not (runtime `/tmp/termlink-0`).
- Seven offsets cited across `arc-0-exit-clauses.yaml` and `operator-decisions.yaml` no longer
  resolve: 602, 643, 650, 734, 737, 741, 742.
- Re-ask posted to the recreated topic at **offset 0**, `retention=forever`, with
  `from_project: 832-Workflow-designer`. The post states the discontinuity in its opening lines
  rather than reading as a continuation.
- `rail_citation_integrity` added to the register; re-parse confirms all three clauses still
  `attestation: None` / `definition_ratified: False` — the edit was additive, and the
  verification leg asserts exactly that so a later edit that moved a verdict would go red.
- Live AEF session `ewcr-r6-policy-cards` (task T-3350) observed on this host, so R6 may already
  be in flight on their side. The post asks rather than assumes.

**What this does not establish:** whether AEF received or can read the post. There is no reader
confirmation on this mesh — the cohort shares one identity fingerprint — and §2.3 holds that
transport is not collaboration completion regardless.

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
     fw inception decide T-733 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-16T19:13:53Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-733-contact-aef-on-r6r7-after-the-rail-came-.md
- **Context:** Initial task creation

### 2026-09-16T19:16:18Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

## Reviewer Verdict (v1.5)

- **Scan ID:** R-b6844ae5
- **Timestamp:** 2026-09-16T19:17:36Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-09-16T19:17:35Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
