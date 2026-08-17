---
id: T-556
name: "Rail sender fingerprint is host-wide, so 'has AEF replied' cannot be answered by sender"
description: >
  Rail sender fingerprint is host-wide, so 'has AEF replied' cannot be answered by sender

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
created: 2026-08-17T05:48:20Z
last_update: 2026-08-17T07:58:28Z
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

# T-556: Rail sender fingerprint is host-wide, so 'has AEF replied' cannot be answered by sender

## Context

I have reported "no reply from AEF" to the operator repeatedly, on the basis of reading
`termlink_agent_chat_arc_recent` and seeing no posts from AEF. That method is unsound, and the
reason is measurable.

`termlink_agent_dms` reports `my_id = d1993c2c3ec44c94`. That is the **same** `sender_id`
carried by arc posts from `050-email-archive` and `0503-codex-cli-playground`, and by our own
posts at offsets 2 and 5. The termlink identity lives in `/root/.termlink/` and is **host-wide**:
every project on this machine signs with it. `chat_arc_recent` resolves sender as
`metadata.agent_id -> metadata._from -> sender_id`, and these posts set none of the first two
(they set `metadata.from_project`, which that view does not surface), so every host-local
project collapses into one indistinguishable sender.

A sibling project's T-022 post inspects AEF's git worktrees live (`AEF: 4 linked trees;
MAIN=t2539-staging`), so AEF's tree is on this host — which means AEF's posts would very likely
carry this same fingerprint and be indistinguishable from ours in the view I was reading.

**The conclusion survives; the method does not.** Searching the arc payloads for the literal
`832-Workflow-designer` returns exactly two envelopes across the whole topic — offset 2 (six
findings, `thread: aef-upstream-findings-2026-08-16`) and offset 5 (the seventh,
`in_reply_to: offset-2`). Both are ours. No envelope naming this project was written by anyone
else, and a reply to seven findings that never names the project it is replying to is not a
shape worth assuming. So "AEF has not replied" is still the right answer — it was just being
reached by an argument that could not have detected the opposite.

Registered as OBS-274 (urgent). Note the write path is already correct: `_t420`'s attribution
gate requires `metadata.from_project` on our posts, and the sibling projects set it too. The
gap is entirely in the READ path.

## The likelier reason there is no reply — measured 2026-08-17, and NOT yet confirmed

Searching the arc for `999-AEF` returns exactly one envelope, offset 9, and it is
`050-email-archive` talking *about* AEF rather than AEF posting. Its payload carries the part
that matters:

> filed AEF#33. `subscribe-learnings-from-bus.sh` polls via `event poll --topic
> channel:learnings` but `channel.post` doesn't fan out to session event buses. Every AEF
> consumer running the current subscriber design is receiving 0 messages (Pen: 110d silent).
> […] verified: appended PL-033 (150-skills-manager) + **L-613 (999-AEF)**, idempotent.

Two things follow, and neither is confirmed yet:

1. **AEF publishes to `channel:learnings`, not to `agent-chat-arc`.** `channel:learnings` exists
   on the local hub with 10 messages and `retention: forever`. We have been posting findings to
   `agent-chat-arc` and reading `agent-chat-arc` for a reply. If AEF neither reads nor writes
   that topic, seven unanswered findings are not indifference — they were delivered to a room
   the recipient is not in. That would be OUR error, not theirs.
2. **There is a known fan-out bug on the channel AEF does use.** `channel.post` does not reach
   session event buses, so consumers polling with `event poll` receive nothing — one peer was
   silent for 110 days without noticing. A subscriber that reports zero messages because the
   transport never delivered them is indistinguishable from a quiet peer, which is the same
   shape as this task's own defect one layer down the stack.

**Deliberately not read yet.** `channel:learnings` holds 10 envelopes of the same prose length
as the arc posts (~2-3K tokens each). Reading them at 165K against a 170K write-block risked
learning something and then being unable to record it. That is the next session's first action
and it is cheap: read `channel:learnings`, establish whether AEF has addressed this project
there, and if so answer on the topic AEF actually uses.

**Do not conclude from this that our findings were ignored.** The evidence supports "possibly
mis-delivered", not "ignored", and the difference matters for how the next message is written.

### Checked immediately after, and it weakens the above — recorded because it does

`channel:learnings` searched for `832|workflow-designer|BPMN` (regex, case-insensitive):
**0 hits across all 10 envelopes.** So AEF has not addressed this project there either, and the
"wrong room" story does not get the corroboration it needed.

Reading the sibling's description again more carefully: `subscribe-learnings-from-bus.sh`
*appends* arriving items to a local learnings register, and what travels are learning records
(`PL-033`, `L-613`). That makes `channel:learnings` a one-way distribution feed for learnings,
not a conversation topic — so it is not where a reply to seven findings would have gone anyway.
`agent-chat-arc` is the conversational rail, it is named for exactly that, and our findings are
on it addressed to AEF with a thread id.

**So the honest state is narrower than the section above suggests.** The mis-delivery
hypothesis is not supported: we posted findings to the conversational rail, which is the right
room, and AEF has said nothing about this project on either topic. What remains genuinely
established is only the original defect — the READ method was keyed on a host-wide fingerprint
and could not have distinguished an AEF reply from our own posts. The "possibly mis-delivered"
framing was one search away from being checked, and I wrote it before running that search.

The open question is therefore unchanged and simpler than I made it: does AEF read
`agent-chat-arc`? That is answerable by enumerating `metadata.from_project` across the topic
(AC4), not by more hypotheses.

### `termlink_agent_peers` — one sender, 30 posts

The participant directory for `agent-chat-arc` returns a single row:
`{sender_id: d1993c2c3ec44c94, post_count: 30}`. Every post on that rail was signed by this
host's identity. There is no second machine on the topic.

What that does and does not establish:

- It **confirms the collapse** directly, from the tool's own participant view rather than by
  inference. A directory whose purpose is "who is here" cannot distinguish any two projects on
  this host. That is OBS-274 measured at the source.
- It **narrows AEF's position to two cases**: either AEF is on this host and its posts are among
  the 30, separable only by `metadata.from_project`; or AEF has never posted to this topic.
  A sibling's T-022 post inspects AEF's worktrees live, so the first case is possible.
- It **does not settle which**. Payload searches found no envelope authored as AEF (`999-AEF`
  appears once, in a sibling's prose about AEF) and none naming this project except our two.
  That leans toward "AEF does not post here", but leaning is not measuring, and I have already
  over-claimed once in this task on exactly this question.

**Left open deliberately.** The remaining step is mechanical — walk the 30 envelopes and
collect the distinct `metadata.from_project` values — and it belongs to AC4 with a real answer,
not to a fourth paragraph of inference. It was not run here because 30 envelopes at the prose
length on this topic is a large read and the session is at its budget ceiling.

### The census, run 2026-08-17 — four projects, one fingerprint, no AEF

The walk was performed over the topic's entire history, offsets 0–34 (35 envelopes), via
`termlink_agent_envelope` per offset. Every envelope carries `sender_id: d1993c2c3ec44c94`.
Distinct `metadata.from_project`:

| `from_project`             | envelopes | what they are                                        |
|----------------------------|-----------|------------------------------------------------------|
| `010-termlink`             | 19        | 18 hourly T-1438 heartbeats (`_from: dimitrimintdev-vendored`) + one hub registration at offset 34 (`agent_id: termlink-107`) |
| `0503-codex-cli-playground`| 7         | the T-022 worktree-reliability evidence chain (11–15, 19) and T-023 (30) |
| `050-email-archive`        | 5         | the T-1948 governance sweeps that carry metadata (8, 9, 16, 20, 22) |
| `832-Workflow-designer`    | 2         | offsets 2 (T-546, six findings) and 5 (T-547, seventh, `in_reply_to: offset-2`) — ours |
| *(absent — no metadata)*   | 2         | T-1948 sweeps #11 and #12 at offsets 31 and 33, posted unattributed |
| **`999-AEF` / any AEF id** | **0**     | **AEF has never posted to this topic**                |

**AC4 is answered, and it agrees with the inference it was meant to test.** AEF does not use
`agent-chat-arc`. Not "has not replied recently" — has never posted, across the whole 35-envelope
history of the rail. The seven findings were delivered to a room AEF has never been in.

**OBS-274 is now quantified rather than asserted.** The collapse is not two projects sharing a
fingerprint, it is **four**, and `termlink_agent_peers` renders all four as a single row whose
`post_count` is the sum. The directory is not merely imprecise about which project spoke; on this
host it cannot represent the concept of a project at all.

Two corrections to what I wrote above, both mine:

- *"There is no second machine on the topic"* is true and was the wrong thing to measure. There is
  no second **machine**, and there are four second **projects**. Reading a host-keyed directory and
  reporting a project-level conclusion is the same substitution this task was opened about, and I
  made it while writing the task about it.
- I inferred, from `termlink_agent_recent` returning no `metadata` field, that `from_project` was
  unreadable and the enumeration therefore unperformable. That was wrong, and I checked it before
  recording it: `termlink_agent_envelope` returns metadata correctly. Offset 33's `metadata: null`
  was truthful — that sibling's post genuinely carries none.

### Correction to the paragraph above, made before it hardened

I wrote that the findings "were delivered to an address that has never had a reader." **That is
not what the census measured and I am striking it.** A reader leaves no envelope. Thirty-five
posts with no AEF among them establishes that AEF has never *written* here; it says nothing
about whether AEF *reads* here. This is the fourth time in this task that the same question has
produced an over-claim from me, and the shape is identical each time: a property that was
convenient to state, standing in for one that was actually checked.

What readership evidence exists, and it is thin in both directions:

- `termlink_agent_ack_status` returns `[]` — **no receipts exist on this topic from anyone, ever.**
  The positive control is `termlink_agent_unread`, which returns `total: 35` from the same
  subsystem, so the ack machinery can see the topic and the empty result is truthful rather than
  another silent zero. It also independently corroborates the census count: 35 envelopes, 0–34.
- Because *nobody* has ever acked on this rail, the absence of an AEF receipt is not evidence
  about AEF. The receipt channel is unused, not informative.
- `termlink_agent_listeners` reports 0 listeners on `agent-presence`, including offline. I did not
  find a positive control for that one, so I am not drawing anything from it.

**So: whether AEF reads `agent-chat-arc` is not answerable from any surface I found.** The right
statement is the narrow one — AEF has never posted here, and readership is unobservable.

### AEF is live on this host right now, and reachable by a different route

`termlink_list_sessions(name: "t30")` returns **seven AEF sessions**, all
`cwd: /opt/999-Agentic-Engineering-Framework`, all `state: ready`, all heartbeating within the
last minute: `t3042-fix` (14h, `task:T-3042`), `t3047-triage-1..5` (9h, `task:T-3047`, five
parallel), `t3060-sweep` (56m, `task:T-3060`, `task-type:test`). Termlink `0.11.1411`.

Three things follow, and they matter more than the census did:

1. **AEF uses termlink, heavily.** It is not absent from the mesh — it registers tagged sessions
   per task and fans out parallel triage workers. It simply does not use the conversational rail.
   So the transport is sound and the topic was the wrong assumption, which is closer to the
   "wrong room" story I retracted yesterday than to the "right room, no answer" story I replaced
   it with. Neither was right: the room is right for a conversation and AEF has never entered it.
2. **Every AEF session carries `identity_fingerprint: d1993c2c3ec44c94`** — byte-identical to
   ours. This is OBS-274 confirmed from the peer's side rather than inferred from ours. If AEF
   ever did post to the arc, its envelopes would be indistinguishable from ours by `sender_id`,
   and only `metadata.from_project` would separate them. The defect this task was opened about is
   not hypothetical for this peer; it is exactly the peer it would have blinded us to.
3. **There is a direct route to AEF that does not depend on the arc at all** — the session
   surface (`termlink_send` / `termlink_inject` / `termlink_agent_ask` against a live session id).

**I have not used route 3 and will not without the operator.** Injecting into another project's
live agent session drives someone else's running work: seven sessions are mid-task right now, one
of them a five-way parallel triage. That is an outward-facing, consequential act on a peer, and a
pickup message we send is a proposal, not an instruction — the same rule that governs what we
accept from them (G-020, in reverse). It is also the operator's mesh. Recorded as the
recommendation for AC6, with the decision left where it belongs.

### The other half of the seam — we have never subscribed to anything (AC7)

The rail is the outbound half. Checking the inbound half found it missing entirely:

- **No subscriber runs for this project.** The host crontab contains exactly one
  `subscribe-learnings-from-bus.sh` line and it is `050-email-archive`'s. We have no cron entry,
  no `.subscribe-learnings-bus.cursor`, no log, and no `.context/project/received-learnings.yaml`.
- **No publisher either.** Nothing wires `publish-learning-to-bus.sh` into our hooks.
- **252 learnings in `learnings.yaml`, all ours. 0 received, 0 published.**

So the 832↔AEF seam is broken in *both* directions, and both breaks are the same shape: outbound,
we address a rail the peer has never written to; inbound, we are not connected to the bus the peer
publishes on. Neither could be noticed, because in both directions the absence of messages renders
exactly like the absence of anything to say.

**Then I ran the subscriber by hand, and it reproduces AEF#33 from our side.** The first attempt
failed `rc=126`, which is a finding rather than an obstacle (below). Invoked via `bash`, against a
live hub with 20 registered sessions:

```
2026-08-17T08:04:15Z target-changed old= new=pen-agent-systemd reset-cursor
2026-08-17T08:04:15Z poll target=pen-agent-systemd since_in=0 since_out=0 received=0 appended=0 \
                     skipped_self=0 skipped_dup=0 skipped_malformed=0
rc=0    →  received: []
```

`channel:learnings` holds 10 envelopes at `retention: forever`. The poller received none of them.
Every skip counter is zero, so this is not filtering — nothing arrived. **This is an independent
reproduction of AEF#33 from a second project**, which is worth more to the peer than agreement:
they had one data point and a 110-day-silent consumer.

And the interesting part is where the assumption sits. The script's own design comment states the
property its fix depends on:

> Events broadcast to `channel:learnings` fan out to every registered session's private event bus;
> polling any one session gets the full stream. (v1 used `event collect` which only delivers
> events broadcast by the collector's own session — missed cross-session traffic entirely.)

That is T-1219's repair of T-1217's bug, and it rests on a transport property that was written down
rather than checked. **A stated property standing in for a checked one, inside the repair for the
previous bug** — the same shape as T-448, T-541 and T-552 this week, now found in the vendored
framework rather than in our own instrumentation. The failure renders as health: exit 0, all
counters zero, a log line indistinguishable from a successful poll of an empty topic.

**`rc=126` — the defensive script that cannot defend against not starting.** Both bus scripts are
mode `100644` in git, while the subscriber's header line 25 recommends
`*/5 * * * * /path/to/subscribe-learnings-from-bus.sh` — a direct invocation, which cannot execute.
The script is unusually careful about silent failure (`Non-fatal: any error path exits 0 —
cron-safe`, `Silent no-op when termlink missing, hub down, or no sessions`), but `rc=126` is
produced by the shell before line 1 runs, and the install idiom appends `>/dev/null 2>&1`. The one
failure mode its error handling cannot reach is the one its own documented install produces.
Vendored, so G-008 applies: fixable in-tree and upstreamable (OBS-281).

**Not installed.** Adding a cron entry writes outside `/opt/832-Workflow-designer`, which is the
T-559 boundary, and it would install a subscriber that is currently known to receive nothing.
Recommended to the operator as a pair: fix the mode, then install — in that order, because
installing first produces a healthy-looking log either way.

### Four defects in the read surface, measured on the way

These are what made the question resist three sessions. None of them announce themselves; all four
return success.

1. **`termlink_agent_chat_arc_recent`'s `filter_sender` matches nothing, for any value.**
   `dimitrimintdev-vendored` → 0 posts. `d1993c2c3ec44c94` → 0 posts. Both are strings the *same
   tool* prints in its own `sender` field, in the same 720h window, on a hub it reported as
   scanned; an unfiltered call in the same minute returns both. Every filtered call returns
   `ok: true, total_posts: 0` — a silent empty indistinguishable from "that sender never posted."
   **Had I answered AC4 with this filter, I would have gotten a clean, confident, wrong "no AEF"** —
   the right answer by luck, from a control that cannot produce any other answer (PL-206). The
   negative arm is only meaningful because the positive control was run first and also failed.
2. **`termlink_agent_envelope` returns an empty payload while reporting `found: true`.**
   `payload_b64: ""` and `payload_decoded: ""` on all 35 offsets, including offset 33, which
   `termlink_agent_recent` returns with a full 1.5KB payload seconds earlier. The tool documented
   for forensics — *"what exactly was at offset X with all fields"* — answers "found it, here it
   is: nothing." Its metadata half is sound, which is why the census was possible.
3. **`termlink_agent_recent` documents a `metadata` field it does not return.** Docstring promises
   `(offset, ts, sender_id, msg_type, payload_b64, metadata, signature)`; the record contains
   `artifact_ref, msg_type, offset, payload_b64, sender_id, topic, ts`. No `metadata`, no
   `signature`. The two readers are exact complements — `recent` has payload without metadata,
   `envelope` has metadata without payload — and neither alone can answer "who said what".
4. **The fleet hub census is unstable and reports `ok: true` regardless.** Across five consecutive
   calls `hubs_failed` was 1, 2, 1, 3, 2, with `laptop-141` never reachable ("network") and the two
   `ring20-*` hubs intermittently timing out. The default 30s timeout is insufficient — two calls
   failed outright; `timeout_secs: 110` succeeded. **A "who is here" answer computed while a hub is
   unreachable is reported identically to one computed over the whole fleet.** The census above is
   therefore complete only for `workstation-107-public`, which is where all 35 envelopes live.

### The recipe, written down (AC1)

The enumeration is not re-derivable from either reader alone, so it is recorded here rather than
rediscovered next session:

```
# Who has spoken on agent-chat-arc, by project rather than by host:
#   1. termlink_agent_chat_arc_recent(limit=50, since_hours=720, timeout_secs=110)
#      -> newest ts and the post count. Read `summary.failed_hubs` FIRST: a non-empty
#         list means the answer is partial, and the call still returns ok: true.
#   2. termlink_agent_recent(limit=1) -> the newest offset N. (Its `metadata` is absent
#         despite the docstring; do not key on it.)
#   3. termlink_agent_envelope(offset) for offset in 0..N -> metadata.from_project.
#         Payloads come back empty, which is a defect and also what makes this cheap:
#         a full 35-envelope census costs ~10 lines per call and no prose.
# Do NOT use filter_sender. It returns 0 for every value, including ones the tool itself
# prints, and it says ok: true while doing it.
```

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] The "has the peer replied" check keys on `metadata.from_project`, not on `sender`, and
      the helper that answers it is written down rather than re-derived per session.
      DONE 2026-08-17: recipe recorded under "The recipe, written down (AC1)". It is a recipe
      rather than a script because the only surface that returns `from_project` is the MCP
      deep-fetch, which a repo tool cannot call; and because two of the three steps carry a
      documented-but-false promise that the next session would otherwise walk into again.
- [x] A probe demonstrates the collapse: two envelopes from different `from_project` values
      with identical `sender_id` are shown to be indistinguishable under a sender-keyed filter
      and distinguishable under a project-keyed one. Without the second arm this is a claim,
      not a check.
      DONE 2026-08-17: both arms measured over all 35 envelopes. Sender-keyed — every envelope
      returns `sender_id: d1993c2c3ec44c94`, and `termlink_agent_peers` renders the four
      projects as one row. Project-keyed — the same 35 separate cleanly into 010-termlink (19),
      0503-codex-cli-playground (7), 050-email-archive (5), 832-Workflow-designer (2), plus 2
      unattributed. The discrimination is real, not a decoration: it also surfaced the two
      posts that carry no attribution at all, which the sender view cannot represent.
- [x] The negative result is re-derived by the new method and agrees with the payload-search
      finding recorded above (exactly two envelopes naming this project, both ours).
      DONE 2026-08-17: exactly two, offsets 2 (T-546) and 5 (T-547, `in_reply_to: offset-2`).
      Agrees with the payload search on both count and identity. Two independent methods over
      different fields — prose text vs envelope metadata — reaching the same pair.
- [x] Whether AEF actually posts to this arc at all is answered from evidence — an enumeration
      of the distinct `from_project` values present on the topic — rather than left as the
      inference drawn in Context.
      DONE 2026-08-17: four distinct values over offsets 0–34, none of them AEF. The finding is
      stronger than the inference it replaces — not "AEF has not replied" but "AEF has never
      posted to this topic," across its entire history.
- [x] `channel:learnings` (10 envelopes, retention forever) is searched and it is established
      whether AEF has addressed this project there. DONE 2026-08-17: 0 hits for
      `832|workflow-designer|BPMN`. It is also a one-way learnings feed, not a conversation
      topic, so it was never where a reply would land.
- [ ] If AEF does not use `agent-chat-arc`, the seven findings are re-delivered on the topic
      AEF actually reads, with the mis-delivery stated plainly as ours. Re-posting the same
      content to the same unread topic is not a remedy. NOTE: now contingent on AC4 rather
      than expected — the mis-delivery hypothesis did not survive the search above.
      2026-08-17: AC4 resolved the contingency to YES — AEF has never posted here — and the
      route is identified but **blocked on the operator, not on me**. AEF is live on this host
      with seven ready sessions, so the reachable surface is `termlink_send`/`termlink_inject`/
      `termlink_agent_ask` against a session id, not a topic. Driving a peer's running agent is
      an outward-facing act on someone else's work-in-progress and is not delegated by "proceed
      as you see fit". The recommendation is written up under "AEF is live on this host right
      now"; the decision is the operator's. What is NOT recommended is re-posting the seven
      findings to `agent-chat-arc` — that is the remedy this AC already names as no remedy.
- [x] The `channel.post` fan-out bug (AEF#33 — consumers polling `event poll` receive nothing;
      one peer silent 110 days) is checked against OUR subscriber, if we run one. A reader that
      reports zero because the transport never delivered is this task's defect one layer down.
      DONE 2026-08-17: we run no subscriber — no cron entry, no cursor, no log, no
      `received-learnings.yaml`. So the answer to "if we run one" is no, and the bug does not
      affect us, for a worse reason than if it did. Ran it by hand to answer the question
      properly; see "The other half of the seam" below. It reproduces, and two further defects
      were measured on the way (OBS-280, OBS-281).

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

### 2026-08-17T05:48:20Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-556-rail-sender-fingerprint-is-host-wide-so-.md
- **Context:** Initial task creation
