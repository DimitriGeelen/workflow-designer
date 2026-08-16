---
id: T-537
name: "termlink_agent_chat_arc_recent returns ok:true over a source that does not
  contain the arc, so a live rail reads as silent"
description: >
  termlink_agent_chat_arc_recent returns ok:true over a source that does not contain
  the arc, so a live rail reads as silent

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
created: 2026-08-16T09:53:36Z
last_update: '2026-08-16T14:33:05Z'
date_finished:
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
bvp_scores_proposed:
  - ts: '2026-08-16T12:33:30Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 3
      F-RECALL: 1
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=3 (body:portability-abstraction); F-RECALL=1 
      (body:episodic-only); F-AUTONOMY=0 (no-signal); F3=0 (no-signal); F1=0 
      (no-signal); F2=0 (no-signal)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T14:33:05Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 3
      F-RECALL: 1
      F2: 0
      F4: 0
      F3: 4
      F1: 1
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=3 (body:portability-abstraction); F-RECALL=1 
      (body:episodic-only); F2=0 (no-signal); F4=0 (no-signal); F3=4 
      (prose:seam-fixture-or-pin); F1=1 (prose:process-enablement-incidental)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:13Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 3
    rationale: blast_radius=3 
      (paths:tools/_t352-p011-errexit-probe.sh,tools/validate-workflow.py); 
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T13:58:46Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
    rationale: blast_radius=absent (no-signal); tier=2 (no-signal); effort=8 
      (no-signal)
    rubric_sha: e4a00f38e801
---

# T-537: termlink_agent_chat_arc_recent returns ok:true over a source that does not contain the arc, so a live rail reads as silent

## Context

AEF posted at rail 11974: *"chat_arc_recent over 36h returns 0 posts… My own prior post at offset
11968 is not visible through this read path either. So I am posting into something I cannot
confirm you can read."* They had, by then, missed two of my substantive replies (11970, 11973)
and re-asked three questions I had already answered.

Reproduced from this side. The rail is **not** broken — `termlink_channel_unread` /
`termlink_channel_snippet` on `topic="agent-chat-arc"` return all 2004 envelopes, and I read
11968 and 11974 in full through them. Only the fleet-walk reader is blind.

**Filed as a record, deliberately not fixed:** termlink is not this project's code, it is shared
tooling reached through MCP. The finding, the reproduction and the fixtures belong here; the fix
does not. Measurement is complete — nothing below needs re-deriving.

## Findings (measurement complete)

Three **independent** causes, each sufficient on its own. Fixing any one leaves the reader blind.

1. **The default `msg_type` filter excludes every substantive post.** `filter_msg_type` defaults
   to `'chat'`. Both projects post with `msg_type: "note"`. The only envelopes that survive the
   default filter are the `T-1438` vendored-arc heartbeats, which happen to be typed `chat`. So
   the default view of a busy rail is: robot noise, no humans.

2. **The 30s default timeout is short for this fleet.** A defaults call returned
   `{"error": "timeout after 30s", "verdict": "timeout"}`. It completed only at
   `timeout_secs: 110` — 4 hubs scanned, `laptop-141` failing on network,
   `ring20-management` serving as fallback. A timeout is easily misread as a quiet rail.

3. **The fleet walk does not surface this topic at all — the one that matters.** With
   `all_msg_types: true`, `since_hours: 36`, `timeout_secs: 110`, `limit: 5`, it returned 5
   posts, all from `ring20-dashboard`, newest at `09:17:01Z`. **My own post at offset 11973 is
   timestamped `09:24:43Z` — newer than every row returned — and is absent.** So it is not the
   `limit` crowding it out and not the window. `channel_post` writes and `channel_unread` reads a
   topic the hub-merge path does not read.

### Cause 3, localized — 2026-08-16 (AEF's discriminating test, replicated here)

AEF replied at rail 11980 and moved this past where I had left it. They eliminated hub selection
entirely (single hub pinned, no merge, no fallback → still 0) and split the CLI along one shared
helper, `extract_recent_posts`: every blind verb wraps it, every working verb does not. They then
offered a hypothesis they explicitly declined to assert — a seconds-vs-milliseconds mismatch making
the cutoff exceed every timestamp — with a test: *run digest and timeline over the same window;
digest rows + timeline zero exonerates the transport and indicts the comparison.*

**Run here, same hub (`127.0.0.1:9100`), same topic, same 7-day window, same minute:**

| call | path | result |
|---|---|---|
| `agent_timeline` `window_secs=604800` | `extract_recent_posts` | `posts: []` |
| `agent_stats` `window_secs=604800` | `extract_recent_posts` | `total: 0`, every bucket empty |
| `chat_arc_recent` `hub=127.0.0.1:9100, all_msg_types, since_hours=168` | `extract_recent_posts` | `total_posts: 0`, `hubs_scanned: 1`, `hubs_failed: 0` |
| `channel_digest` `since_mins=10080` | other | **`posts: 283`, 4 distinct senders** |

Transport exonerated on a second, independent host. The 283 envelopes carry well-formed
millisecond timestamps (`ts: 1786881141377` on 11979, `since_ms: 1786278269300`) which `digest`
reads without complaint.

**Where I diverge from AEF's hypothesis, and it matters for whoever fixes this.** "A cutoff that
always exceeds every timestamp" predicts zero rows *on every hub for every envelope*. Their own
complicating datum refutes it: the fleet walk did return 5 rows from `ring20-dashboard`, through
this same helper. A global arithmetic error cannot let some envelopes through. So the surviving
hypothesis class is **per-envelope, not global** — the reader and the writer disagree about *which
field* carries the timestamp, or about whether it is populated at all, and `ring20-dashboard`'s
producer populates whatever the helper reads.

The schemas are consistent with exactly that: `agent_timeline` documents its rows as
`{offset, ts_ms, peer_fp, ...}` while `channel_digest` documents `{offset, sender_id, ts, ...}`.
Two names for the timestamp, two names for the sender, and on this hub only one of each is
populated — 283 envelopes visible to one reader and 0 to the other, simultaneously.

**So the question to hand the termlink owner is not "seconds or milliseconds".** It is: *do
`extract_recent_posts` and the digest path read the same envelope field, and does `channel_post`
populate both?* An unpopulated field reads as `0`, which is older than any cutoff — producing
exactly zero, never a partial, at every window size, which is the shape both of us measured.

I am not asserting the internals; I cannot see termlink's source from here. What is measured is
the pair of simultaneous results above and the fact that a per-envelope cause is required.

### Why no ledger went red

The call returns `ok: true`, `exit_code: 0`, `total_posts: 5`, `hubs_scanned: 4`. It is not
erroring. It is confidently reporting on a **different set**. That was the third instance in two
days of one shape; the register now carries six, across six unrelated subsystems and two projects:

| | the stated thing | the checked thing |
|---|---|---|
| T-535 | trend key = the rendered sentence | persistence of the issue |
| T-536 | a comment claiming pre-push runs `compliance` | the section the hook passes |
| T-537 | `ok:true, total_posts:5` | whether that source contains the arc |
| T-538 | an id used as a key | whether it resolves to one control |
| T-539 | a gauge emitting prose | the JSON verdict its reader requires |
| AEF OBS-281 | a read verb returning a plausible zero | whether that verb can see anything at all |

A stated property standing in for a checked one, and in all six the failure renders as health.
The sixth is AEF's, self-reported and self-corrected at rail 11980 under their T-3033 — and it is
the one that makes the class legible: they concluded a rail was undeliverable on the strength of an
instrument they never asked whether it could see, while four of my posts sat in the topic. Five of
the six are mine, and I only found the later ones because I went looking on purpose after the
third. A register holding one instance of this class is very unlikely to hold only one.

### Cost already paid

Two substantive replies (11970, 11973) went unread, and AEF re-asked three questions I had
answered — including one whose answer gates whether their handover frontmatter change is
breaking for me. The peer-visible symptom of this defect is not silence; it is **two agents each
believing the other is unresponsive while both are posting.**

## Acceptance Criteria

### Agent
- [x] **Reproduced from this side, not taken from the peer's report.** Defaults reproduce their
      zero; the three causes are separated and each shown to be independently sufficient.
- [x] **The working read path is identified and named for the peer**, with a live witness:
      `termlink_channel_unread` reports `total: 2004, last_offset: 11974`, and
      `termlink_channel_snippet` returned 11968 and 11974 in full.
- [x] **Cause 3 is proven not to be a limit or window artefact** — an absent post strictly newer
      than every returned row is the discriminator, recorded with timestamps so the peer can
      re-run against fixed offsets (11970, 11973, 11975).
- [x] **Reported to AEF** at rail 11975, with those offsets handed over as test fixtures.
- [x] **AEF's discriminating test run here and the result recorded** — `agent_timeline` /
      `agent_stats` / hub-pinned `chat_arc_recent` all return 0 while `channel_digest` returns 283
      on the same hub, topic, window and minute. Confirms the split on a second independent host.
- [x] **AEF's proposed cause narrowed, not merely accepted.** A global seconds-vs-ms cutoff error
      predicts zero everywhere and is refuted by their own `ring20-dashboard` rows passing through
      the same helper; the cause must be per-envelope. Recorded with the reasoning that forces it,
      so the next reader can disagree with the conclusion rather than inherit it.
- [ ] **Operator decision recorded.** termlink is shared tooling outside this repo. Either the
      finding goes upstream to the termlink owner, or it is recorded that both projects
      standardise on `channel_*` with an explicit topic and treat `chat_arc_recent` as unusable
      for this rail. Blocked on the operator — this task claims no fix and builds no guard,
      because a probe asserting a third party's MCP behaviour would go red on their release
      schedule, not on a regression here.

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

### 2026-08-16T09:53:36Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-537-termlinkagentchatarcrecent-returns-oktru.md
- **Context:** Initial task creation
