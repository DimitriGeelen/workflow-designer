# Value review — 04: Handoff & collaboration mechanics

**Gatherer:** G4. **Date:** 2026-09-20. **Mode:** read-only evidence collection. No
classification, no recommendation. Every row cites `path:line`, a command + its output, or a
record id. Anything not directly measured is marked **UNVERIFIED**.

**Domain:** the handoff mechanics between the operator, this project's agents, and the
999-AEF counterparty.

---

## 0. Measurement provenance

| # | Instrument | Invocation | When |
|---|---|---|---|
| M1 | TermLink MCP, read-only verbs only | `termlink_hub_status`, `termlink_channel_list`, `termlink_channel_info`, `termlink_channel_threads`, `termlink_channel_search` | 2026-09-20, this session |
| M2 | Python/YAML over repo registers | `yaml.safe_load` over `.context/inbox.yaml`, `.context/project/concerns.yaml`, `.context/project/{assumptions,decisions}.yaml`, `.context/working/.gate-bypass-log.yaml` | 2026-09-20 |
| M3 | grep/ls over `.context/handovers/` (641 entries) and `.context/episodic/` (611 entries) | see §5 | 2026-09-20 |
| M4 | Direct file reads | `docs/research/executable-workflow/*`, `.tasks/active/T-733*.md`, `.tasks/active/T-736*.md` | 2026-09-20 |

**Not run:** `fw audit` (prohibited by brief — OBS-358, hangs). No mutations, no outbound mesh
writes, no reads outside `/opt/832-Workflow-designer` except the TermLink hub's own read-only
API surface.

---

## 1. THE TRANSPORT — `docs/research/executable-workflow/aef-transport-verdict.md`

Task **T-680**, measured 2026-09-05 against hub `workstation-107-public` (192.168.10.107:9100),
probe `tools/_t680-aef-reachability.py` (file confirmed present, `ls tools/` 2026-09-20).

### 1.1 The verdicts

| Transport | Verdict | Evidence in the doc | Line |
|---|---|---|---|
| `agent-chat-arc` | **LIVE / usable** | 66 posts labelled `999-Agentic-Engineering-Framework`, offsets 100–969 | `aef-transport-verdict.md:29` |
| `dm:3bba15e681b3a078:…` | **NOT usable — "no-reader"** | 6 rows; producers `0503-codex-cli-playground` and `832-Workflow-designer` only | `aef-transport-verdict.md:30` |
| `agent-chat-arc` **across hubs** (federation) | **NOT federating** — two disjoint logs under one name | 4-hub table: `.107`=896 rows/max 1095/18 producers vs `.122`=1000/2715/6 | `aef-transport-verdict.md:81-85` |
| federation's relevance to the AEF seam | **NONE** — "AEF posts to the same `.107` hub we read, so federation was never in that path" | | `aef-transport-verdict.md:87-88` |

### 1.2 Why the DM was ruled dead — and why that is *not* a counterparty fact

`3bba15e681b3a078` resolves to `framework-agent-systemd`, *"an idle root bash prompt with no
agent consuming it"* (`:13-14`). Injection was deliberately declined because *"prose at that
prompt executes as root"* (`:15`). Corroborated repo-side at `OBS-282` ("Injected prose into a
peer PTY without first checking what was attached to it, and it was a root bash prompt") and
at rail `@873`, which states `framework-agent-systemd` is registered to `/opt/termlink`, **not**
`/opt/999-Agentic-Engineering-Framework`, and that *"prior DM/pickup requests targeted the wrong
service identity and must not count as AEF delivery."*

### 1.3 The load-bearing identity finding

`aef-transport-verdict.md:41-50`:

```
distinct sender_id on agent-chat-arc : 3
distinct producer labels             : 18
```

> "Every envelope on this mesh carries sender `d1993c2c3ec44c94` — ours. So do 001-CashWeb's,
> 010-termlink's, and 999-AEF's. … **`sender_id` cannot separate producers on this mesh.**"
> (`:41-50`)

Negative control (`:70-74`): `999-Agentic-Engineering-Framework posts on agent-chat-arc: 66`;
`of those, attributable to a non-ours sender_id: 0`; `NEGATIVE CONTROL: PASS`.

**I reproduced the consequence live, 2026-09-20.** `termlink_channel_search(agent-chat-arc,
"rather hand you a red number")` returned offset **650** — a post whose body opens
`[999-AEF -> 832-Workflow-designer]` — carrying `"sender_id": "d1993c2c3ec44c94"`, *our*
fingerprint. The producer is a self-asserted string in the payload.

Repo corroboration, independently filed: `OBS-247` (same ed25519 key both sides), `OBS-263`
(*"Every termlink session on this host shares one identity_fingerprint (d1993c2c3ec44c94) — ours,
AEF's five, and the email-archive ones"*), `OBS-286` (AEF's own statement at `agent-chat-arc`
offset 43 that `from_project` is *"SELF-ASSERTED METADATA, NOT IDENTITY"*), `G-029`
(`.context/project/concerns.yaml`, status `watching`, severity medium).

### 1.4 The doc's own meta-finding

`aef-transport-verdict.md:93-104` — what actually blocks Arc-0 is **rulings, on both sides, not
plumbing**; and `:107-121` — the false belief was *"manufactured by reading the DM thread and not
the clause register … The most recent evidence was the least complete, and recency won."*

---

## 2. TERMLINK AS THE COLLABORATION MEDIUM — live state, 2026-09-20

### 2.1 Hub

`termlink_hub_status` → `{"ok": true, "pid": 12343, "status": "running", "socket":
"/var/lib/termlink/hub.sock", "pidfile": "/var/lib/termlink/hub.pid"}`. **Hub is running.**

### 2.2 Topic store — NOT empty

`termlink_channel_list` returned **46 topics**. Selected rows:

| Topic | count | latest_offset | retention |
|---|---|---|---|
| `agent-chat-arc` | **1001** | **1567** | `messages: 1000` |
| `agent-presence` | 1059 | 49551 | messages: 1000 |
| `health:ring20-fedprobe` | 1769 | 1768 | forever |
| `framework:pickup` | 132 | 131 | messages: 5000 |
| `channel:learnings` | 194 | 193 | forever |
| `aef-install-findings` | 38 | 37 | forever |
| `aef-operator-notices` | 3 | 2 | forever |
| `dm:3bba15e681b3a078:d1993c2c3ec44c94` | **13** | 12 | messages: 1000 |
| `broadcast-chat` | **0** | — | messages: 5000 |
| `aef-s8-probe-2467346` | **0** | — | forever |

### 2.3 T-733's "empty topic store" claim — VERIFY, per the brief

**T-733 recorded (2026-09-16):** *"It came back with an **empty topic store** — `broadcast:global`
at count 0, `agent-chat-arc` absent"* (`.tasks/active/T-733-…md:41-43`), and wrote
`dangling_offsets: [602, 643, 650, 734, 737, 741, 742]` into
`docs/research/executable-workflow/arc-0-exit-clauses.yaml:77`.

**That loss does NOT persist. It was already retracted in-repo before this review, and I
re-measured it independently today.**

| Offset | Claimed dangling (`arc-0-exit-clauses.yaml:77`) | Resolves 2026-09-20? | How I verified |
|---|---|---|---|
| 602 | yes | **YES** | `channel_threads(agent-chat-arc, top=14)` — thread root, 17 replies |
| 629 | — | YES | same call, root, 15 replies |
| 639 | — | YES | same call, root, 14 replies |
| 643 | yes | **YES** | same call, root, 13 replies |
| **650** | yes | **YES** | `channel_search` hit, `msg_type: note`, payload byte-matches the quote in `arc-0-exit-clauses.yaml` incl. all four numbers |
| 734 | yes | **YES** | `channel_threads` root, 10 replies |
| 737 | yes | **YES** | `channel_threads` root, 9 replies |
| 741 | yes | **YES** | `channel_threads` root, 8 replies |
| 742 | yes | UNVERIFIED (not a thread root; inside the retained window by arithmetic — see below) |
| 744, 777, 786 | — | YES | `channel_threads` roots |
| 1536, 1537, 1552 | — | UNVERIFIED (cited by T-736; not directly read this session) |
| 1539 | — | **YES** | `channel_threads` root, 1 reply |

Retention arithmetic: `count=1001`, `latest_offset=1567`, `retention messages:1000` ⇒ the oldest
retained offset is ≥ 567. Every one of the seven "dangling" offsets is > 567, i.e. inside the
window.

**In-repo retraction chain (all three are `status: pending` in `.context/inbox.yaml`):**

| id | date | what it says |
|---|---|---|
| OBS-352 | 2026-09-17 | "no AEF reply on agent-chat-arc 10h22m after our re-ask" |
| OBS-353 | 2026-09-19 | corrects OBS-352 **and T-733's premise**: the topic T-733 posted to no longer exists; the rail now serving is the **restored original log**, `count 1001, latest_offset …` |
| OBS-354 | 2026-09-19 | **corrects OBS-353**: "by re-measuring instead of re-reasoning". Root cause named: both prior findings rested on a `termlink_channel_search` whose **result `limit` truncated the hit set, read as if exhaustive** |

`.tasks/active/T-733-…md:195-234` carries a boxed `⚠ CORRECTION 2026-09-19 — READ BEFORE RULING.
THIS TASK'S PREMISE WAS WRONG TWICE.` It states the chain is *"intact and readable today — roots
`@602 @629 @639 @643 @734 @737 @741 @744 @777 @786`"* — **which is exactly the root set I
independently reproduced today**, plus `@1539`.

### 2.4 What was actually lost, and what is actually broken

| Fact | Status | Citation |
|---|---|---|
| The 2026-09-16 R6/R7 re-ask posted to a recreated `retention: forever` topic | **LOST** — the restore displaced that topic | `T-733:216-218` |
| Counterparty's cited evidence (`@602`–`@786`, `@650`) | **NOT lost** | `T-733:205-209`; reproduced §2.3 |
| `rail_citation_integrity.dangling_offsets` in the governance register | **STILL WRONG ON DISK** at `arc-0-exit-clauses.yaml:77`; the agent deliberately declined to edit it because it is under operator review | `T-733:230-233` |
| **Rail timestamps** | **NOT citable.** All eleven EWCR threads report last activity at exactly `2026-09-07 19:36`, identical to the minute — bulk-replay artefact of the restore | `T-733:226-228`; `arc-0-exit-clauses.yaml:195-197` |
| Hub runtime substrate | `/tmp/termlink-0` (message log) vs `/var/lib/termlink` (session registry) — the split is why sessions survived and the log did not | `T-733:42-43` |
| A restore silently replaced one log with another **under the same topic name**, and nothing in our tooling noticed | open | `T-733:220-224` |

Corroborating live measurement: `channel_threads` returned `last_ts_ms` `1789891512351` for
**four distinct roots** (@602/@629/@639/@643) and `1789853393424` for **six** (@734/@737/@741/
@744/@777/@786) — identical to the millisecond within each group. Timestamps are replay
artefacts, confirmed.

### 2.5 The channel cannot report its own failures — stated explicitly, per the brief

**TermLink is both the medium of the collaboration and the only record of it.** There is no
out-of-band observer. This is not a rhetorical point; it is load-bearing for every row above:

1. The only evidence that a message reached AEF is a message on the same rail.
   `T-733:278-280`: *"**What this does not establish:** whether AEF received or can read the post.
   There is no reader confirmation on this mesh — the cohort shares one identity fingerprint."*
2. `agent-chat-arc` carries exactly **one** read receipt, ours: `channel_info` →
   `receipts: [{sender_id: d1993c2c3ec44c94, up_to: 923}]`. AEF has no distinguishable receipt
   because AEF has no distinguishable identity (§1.3).
3. When the log was replaced, the detection came from an agent happening to look, not from an
   instrument. `G-022` (`concerns.yaml`, `watching`, high) is the standing register entry for
   exactly this class: *"A peer rail nobody read: 'AEF is silent' was scoped to one topic and
   reported as a fact about the peer."*
4. `OBS-261` (pending): `termlink_agent_chat_arc_recent` reports `ok:true / exit_code:0 /
   total_posts:5` over a source **that does not contain the `agent-chat-arc` topic**.
   `OBS-278` (pending, urgent): the fleet hub census *"reports ok:true regardless of how much of
   the fleet it failed to reach."* `OBS-275` (pending, urgent): `filter_sender` matches nothing
   for any value.

**DATA GAP (structural, not fixable by more reading):** no independent record of the
collaboration exists. Every claim in §7 about "what came back" is sourced either from the rail
itself or from a repo file quoting the rail. A forged, mis-attributed or replayed post is
indistinguishable from a genuine one on this mesh, by the transport doc's own negative control.

### 2.6 The AEF DM mailbox — the "no-reader" verdict re-measured today

`channel_info(dm:3bba15e681b3a078:d1993c2c3ec44c94)` →

```
count: 13   receipts: []   senders: [{sender_id: d1993c2c3ec44c94, posts: 12}]
```

**One sender. Zero inbound. Zero read receipts.** The transport doc measured 6-7 rows in
September; it is 13 now and still **100% ours**. The no-reader verdict holds and has grown.

---

## 3. OPERATOR DECISIONS — `docs/research/executable-workflow/operator-decisions.yaml` (217 lines)

Register purpose (`:1-9`): the Arc-0 exit gate (`roadmap-5be23719.md:147`) requires *"no
unresolved source-of-truth ambiguity enters Arc 1"*. Those ambiguities are H1–H6. Before T-596
they were *"a prose table at `reflection-designer.md:201-208` with no status column and no
reader"* — the gate's third clause was **unevaluable by anyone**.

Self-certification rule, PL-148 (`:17-23`): *"An entry may not assert its own resolution. Every
`status: resolved` entry MUST name a `source_of_truth` — an external artifact that independently
carries the decision."* Checked by `tools/_t596-arc0-exit-gate.sh`.

### 3.1 The full H-register

| id | Question (abridged) | Status | Owner / decided_by | `blocks_arc_0_exit` | What is blocked behind it | Lines |
|---|---|---|---|---|---|---|
| **H1** | Do roadmap Arcs 4–6 supersede the standing DEFERs (T-279/280/281/282) and AEF's T-2669 NO-GO? | **open** | operator (sovereignty act — *"Reversing a recorded disposition is a sovereignty act"*) | **true** | Arcs 4–6 not actionable "whatever they score". T-587's GO explicitly declined to reverse them, so T-587 is **not** its source_of_truth | `:40-58` |
| **H2** | Name the AEF counterparty project — 0503 (author/governance) or 999 (intended implementer)? | **resolved** 2026-08-26 | operator; `chosen: /opt/999-Agentic-Engineering-Framework`; SoT = `handoff-ewcr-v1-designer-fixture.yaml` `to_project_resolution`; recorded under T-595 | true | — but **"RATIFICATION IS SEPARATE AND STILL OPEN. T-590's H2 acceptance criterion is a Human AC and remains unticked."** | `:60-80` |
| **H3** | Assign the two correlations — one for this agent, one for the initiative | **open** | operator | **true** | **Phase 4 completion.** `source-manifest.yaml` states no peer handoff may be opened until the correlations are assigned; *"A handoff has been open since 2026-08-27 on an unassigned value, so as things stand there is no correlation on which Phase 4 read-back could be judged complete."* Also gates AEF's nine-member expansion and revision cut (`@1539`) | `:82-117` |
| **H4** | GO/NO-GO on the §5 slice | **resolved** 2026-08-26T08:55:40Z | operator; GO, narrow Arc-0 Designer slice only, explicitly NOT Arcs 4–6; SoT = `.tasks/completed/T-587-…md` `## Decision` | true | — | `:119-137` |
| **H5** | Reconcile the four governance deviations in §9 | **open** | operator | **true** | Four disclosed deviations stand unreconciled. **T-620 performed the inspection (2026-08-27)** and settled deviation 2 only (`deviation_2_hand_written_task_file: conforming`); deviations 1/3/4 are *"historical acts, not current file states, and cannot be settled by inspecting the tree"* | `:139-177` |
| **H6** | Route R6 and R7 to AEF | **open** | operator | **true** | The transport half is **done** (routed 2026-08-27, `@643`). What remains: rule that routing was correct and the §2.3 boundary held. *"It resolves when AEF answers and the operator accepts the answer as the source_of_truth clause 3 requires."* | `:179-217` |

**Counts: 6 questions. 2 resolved, 4 open. All 6 carry `blocks_arc_0_exit: true`.** Clause 3 is
therefore **2/6** — stated verbatim on the rail at `@643`.

### 3.2 Entries that record their own mechanism failing

- **H3 is the sharpest artefact in this domain.** Its `operative_state` (`:89-94`) diagnoses:
  *"In-use is not ratified: they were chosen by an agent and have been carried forward by
  repetition, which is how an unratified value acquires the appearance of a decision."* Its
  `superseding_observation_2026_08_29` (`:99-117`) then records: **"THE RECOMMENDATION ABOVE IS
  NOW INCOMPLETE, AND ITS OWN DIAGNOSIS IS WHY. It says 'the two values already in use'. There
  are now THREE."** The third, `EWCR-ARC0-ATTEST-832`, is *"a rail THREAD NAME minted by an agent
  at offset 602 (T-610) and adopted by the counterparty because we used it"*. The entry
  concludes: *"The entry described the disease and then the disease happened again, one layer
  out, while the entry sat open."*
- **H6 carries its own superseded text on purpose** (`:186-193`): the operative_state and
  recommendation rested on *"a send-authorisation gate that the instruction set never
  contained"*; **"The invented gate stalled Arc 0 for three sessions."** Original kept *"because
  the reason H6 sat open for three sessions is itself the evidence."*

### 3.3 Operator-facing route and dossier

`docs/reports/T-732-h-register-dossier.md` (assembled 2026-09-16) is the decision packet, one
section per open H, recommendations *"quoted verbatim from the register (PL-323 — never
paraphrase a clause the operator is about to rule on)"*. Approvals route:
`http://192.168.10.107:3013/approvals`; per-task route `http://192.168.10.107:3013/review/T-732`.

The dossier corrects its own parent task (`T-732-h-register-dossier.md:30-38`): T-732 was filed
saying clause 3 is *"the only one on our side of the fence"* — assembling the packet showed
**H6 is partly counterparty-blocked**, so *"Three of the four rulings are ours to make today;
the fourth may not be."*

### 3.4 Arc-0 exit state, 2026-09-20

| Clause | Owner | State on disk | `attestation` | `definition_ratified` | `blocks_arc_0_exit` |
|---|---|---|---|---|---|
| clause-1 topology non-empty & validated | aef | Answered **RED** `@650` 2026-08-27 (their T-3127, commit `d318223`); **superseded GREEN** `@1539` 2026-09-20 (their T-3394, commit `174f31777`) | `null` | `false` | `true` |
| clause-2 refusal matrix complete | aef | Artifact does not exist in either repo; block is upstream of AEF (their T-3389 needs 4 reviews from `0503-codex-cli-playground` into a `reviews/` dir that does not exist) | `null` | `false` | `true` |
| clause-3 no unresolved source-of-truth ambiguity | shared | `method: local-register` — **2 of 6** H-questions resolved | *(no attestation field)* | `false` | `true` |

`arc-0-exit-clauses.yaml` grep, 2026-09-20: `attestation: null` ×2 (lines 115, 289),
`definition_ratified: false` ×3 (lines 103, 276, 302), `blocks_arc_0_exit: true` ×3.
**Arc 0 is 0 of 3 satisfied.** Arc register `.context/arcs/ewcr-governed-delivery.yaml` (arc-002)
`status: in-progress`, `anchor_task: T-590`, `decision: null`, `closed_at: null`,
`bvp_scores: {}`, `demo_evidence: null`.

---

## 4. GATE FRICTION — `.context/working/.gate-bypass-log.yaml` (1011 lines)

`yaml.safe_load` → **148 entries**, 53 distinct tasks, 2026-06-05 → 2026-09-08.

### 4.1 By flag

| Flag | Count | Share |
|---|---|---|
| `FW_SWITCH_FOCUS=1` | **95** | 64.2% |
| `--skip-sovereignty` | **42** | 28.4% |
| `--switch-focus` | 7 | 4.7% |
| `--skip-rca` | 1 | 0.7% |
| `T-559-project-boundary (read-side)` (+ 2 scope extensions) | 3 | 2.0% |

**Focus-drift is the single most-bypassed gate: 102 of 148 (68.9%)** when `FW_SWITCH_FOCUS=1`
and `--switch-focus` are combined (both fire `check-active-task focus-drift`).

### 4.2 By caller

| Caller | Count |
|---|---|
| `check-active-task focus-drift` | 102 |
| `check_human_sovereignty` | 42 |
| `operator, in-session` | 2 |
| `check_rca_for_bugfix` | 1 |
| `check-project-boundary (PreToolUse:Bash) — blocked, then authorised` | 1 |

### 4.3 By month, and by the 10 heaviest days

| Month | Count | | Date | Count |
|---|---|---|---|---|
| 2026-06 | 1 | | 2026-07-04 | 22 |
| 2026-07 | **119** | | 2026-07-05 | 15 |
| 2026-08 | 12 | | 2026-07-18 | 13 |
| 2026-09 | 16 | | 2026-07-03 | 12 |
| | | | **2026-09-01** | **11** |
| | | | 2026-07-07 | 10 |
| | | | 2026-07-09 | 9 |
| | | | 2026-07-10 | 9 |
| | | | 2026-08-30 | 7 |
| | | | 2026-07-06 | 5 |

80.4% of all bypasses are in July 2026 — before the EWCR/Arc-0 seam work began (arc-002 created
2026-09-03).

### 4.4 Heaviest tasks

| Task | Bypasses | Task | Bypasses |
|---|---|---|---|
| T-041 | 28 | T-190 | 6 |
| T-016 | 16 | **T-685** | **4** |
| T-175 | 13 | T-105 / T-173 / T-230 / T-501 / T-639 / T-640 | 3 each |
| T-155 | 7 | T-040 / T-079 | 2 each |
| T-112 | 6 | | |

### 4.5 `--skip-sovereignty` reason breakdown

| Reason text | Count |
|---|---|
| `Inception decision: GO` | 26 |
| **`''` (empty — no reason recorded)** | **12** |
| `Completed via Watchtower UI (human action)` | 4 |

**11 of the 12 empty-reason sovereignty bypasses fired in a single 55-minute window on
2026-09-01** (18:45:08Z → 19:40:22Z), lines **L916, L921, L926, L931, L936, L941, L946, L951,
L956, L961, L966**, across tasks T-440, T-041, T-102, T-105, T-195, T-200, T-228, T-309, T-357,
T-501, T-041. The 12th is L848 / L853 (2026-08-20, T-501). A sovereignty-gate bypass with an
empty `reason:` field is the mechanism's own audit trail failing.

### 4.6 Does any bypass touch the seam, the arcs, or release/dist?

| Question | Answer | Evidence |
|---|---|---|
| Does any bypass name an **arc-002 / EWCR / Arc-0 governance task** (T-590/595/596/597/608/609/610/623/671/728/732/733/736)? | **NO — zero.** | regex over `task:` field returned only T-681, T-685 |
| Does any bypass touch **arc-003** (`T-681`)? | **YES — 2:** L971–975 (2026-09-05, `--skip-sovereignty`, `Inception decision: GO`) and L1007 (2026-09-08, T-685, same) | `.gate-bypass-log.yaml:971-975, 1007-1011` |
| Does any bypass touch **release / dist / VERSION**? | **NO release gate was ever bypassed.** The 6 grep hits are commit-message text inside `FW_SWITCH_FOCUS` entries about release tasks (L541, L613, L666, L683, L699-700) and the T-685 peer-VERSION read (L994-995). `G-007` (release immutability guard) has **zero** bypass entries | grep `-niE "release\|dist/\|VERSION\|promote"` over the log |
| Does any bypass touch the **project boundary** (T-559)? | **YES — 3, all on T-685, all read-only, all operator-authorised in-session, all with full rationale** | L976-988, L989-996, L997-1006 |

### 4.7 The T-559 boundary blocks — the brief asked me to record any I hit

**I hit none this session.** All my reads stayed inside `/opt/832-Workflow-designer`; the only
outside-boundary surface I touched is the TermLink hub's read-only API, which is the hub's own
state and not a peer project's files.

The three historical blocks are the model for how a block should be recorded. Verbatim from
`.gate-bypass-log.yaml:980-988`:

> *"Tier 2 situational authorisation, operator-granted in-session and scope-limited by them to a
> READ-ONLY sweep (\"I meant read only sweep\"). … Bash was blocked by T-559 with \"Outside-path
> argument … not in read-side allowlist\"; **the block was substantive, not a text
> false-positive, so it was surfaced to the operator rather than routed around.** Executed with
> the Read tool ONLY … NOTHING was written to any peer project; no other peer file was read; no
> termlink dispatch into a peer session was used."*

Scope extension 2 (L1001-1006) records that the agent read **one** file of the ten the grant
allowed, *"because it was decisive on its own and the rest would have spent context for no
additional evidence."* Both extensions record the hypothesis as **DISPROVED**.

**Related collision hazard, filed:** `OBS-300` (pending, urgent) — *"`fw work-on` minted T-559
for a new local task, and T-559 is 999-AEF's task id cited unqualified 154 times in OUR OWN
corpus as 'the T-559 boundary'."* The identifier for the boundary rule and a local task id are
the same string.

---

## 5. RECURRING BLOCKERS across `.context/handovers/` (641) and `.context/episodic/` (611)

### 5.1 Seam-term frequency (files containing the term)

| Term | Handover files | Episodic files |
|---|---|---|
| `AEF` | **638 / 641** | 389 / 611 |
| `ratif` | 434 | 32 |
| `handoff` | 423 | 16 |
| `termlink` | 263 | 30 |
| `from_project` | 255 | 6 |
| `arc-0` | 172 | 24 |
| `agent-chat-arc` | 115 | 14 |
| `EWCR` | 100 | 14 |
| `counterparty` | 95 | 6 |
| `H3` | 92 | 1 |
| `attestation` | 81 | 6 |
| `file_send` | 33 | 12 |
| `dangling` | 11 | 10 |
| `R6/R7` | 10 | 1 |

**Caution on `AEF`=638/641:** that is near-total saturation and is partly structural — `AEF`
appears in product paths (`aef-workflow-designer.html`, `aef:` namespace) and in the standing
pending-review list every handover reprints. It is *not* evidence of 638 sessions of seam work.
Sampled context confirms the mix (`grep -o ".\{0,50\}AEF.\{0,50\}"` over the 3 newest handovers
returns both `aef:meta` product strings and live `/review/T-736` seam rows).

### 5.2 The real recurrence signal: how many *sessions* re-carried the same unclosed item

Method: `grep -rl "<task-id>" .context/handovers/S-*.md`, sorted, first/last filename.
Each hit = one session that reprinted the item as still-pending.

| Task | Handovers carrying it | First session | Last session | Span |
|---|---|---|---|---|
| **T-184** — child-3 reverse discovery, AEF record (DEFERRED by operator 2026-07-11) | **509** | S-2026-0711-0732 | S-2026-0920-2049 | **71 days** |
| **T-365** — fixtures/aef-bpmn as v1.2 standard delta — *"PENDING AEF ruling"* | **298** | S-2026-0804-1519 | S-2026-0920-2049 | **47 days** |
| **T-422** — check-arc-id: register the hook or delete | 252 | S-2026-0810-2143 | S-2026-0920-2049 | 41 days |
| **T-424** — T-357 step 3, retire `aef:position` | 249 | S-2026-0810-2240 | S-2026-0920-2049 | 41 days |
| **T-443** — rename fixtures/aef-bpmn as v1.2 standard delta | 235 | S-2026-0812-0029 | S-2026-0920-2049 | 39 days |
| **T-580** — decide: take AEF `5c33f7208`, the two fabric… | 112 | S-2026-0824-2021 | S-2026-0920-2049 | 27 days |
| **T-590** — EWCR Arc-0 designer contract inventory (H2 ratification lives here) | **100** | S-2026-0826-1156 | S-2026-0920-2049 | **25 days** |
| **T-596** — Arc-0 exit gate is uncheckable / the operator register | 92 | S-2026-0826-1925 | S-2026-0920-2049 | 25 days |
| **T-597** — both remaining Arc-0 exit clauses are counterparty-owned | 92 | S-2026-0826-1925 | S-2026-0920-2049 | 25 days |
| **T-608** — draft the AEF attestation request for Arc-0 clauses 1 & 2 | 81 | S-2026-0827-0928 | S-2026-0920-2049 | 24 days |
| **T-609** | 81 | S-2026-0827-0928 | S-2026-0920-2049 | 24 days |
| T-671 — component fabric does not meet the Arc-0 … | 43 | S-2026-0903-0832 | S-2026-0920-2049 | 17 days |
| T-681 — EWCR arc holds only Arc-0 | 32 | S-2026-0906-2044 | S-2026-0920-2049 | 14 days |
| T-728 — RA-032 arc-001 is 26 of 32 complete | 15 | S-2026-0916-1551 | S-2026-0920-2049 | 4 days |
| T-732 / T-733 | 10 each | S-2026-0919-2303 | S-2026-0920-2049 | 1 day |
| T-736 | 8 | S-2026-0920-1007 | S-2026-0920-2049 | <1 day |

**Every one of these has `last = S-2026-0920-2049`, the newest handover. Nothing in this table
has ever closed.** T-595 and T-610 are the only two seam tasks whose recurrence *stopped*
(last = S-2026-0905-1310) — both are `completed/` and both are the ones that closed.

### 5.3 The structural cause of the recurrence, measured

| Fact | Value | How measured |
|---|---|---|
| Active tasks | **128** | `ls .tasks/active/*.md \| wc -l` |
| Active tasks that are `owner: human` **and** `status: work-completed` (partial-complete, awaiting a Human AC tick) | **38** (29.7%) | `grep -l '^owner: human' .tasks/active/*.md \| xargs grep -l '^status: work-completed' \| wc -l` |
| Handovers containing the string `partial-complete` | **601 / 641** | grep |
| Handovers containing `Human AC` | **601 / 641** | grep |
| Handovers containing `operator ruling` | 265 | grep |
| Handovers containing `approvals` | 299 | grep |

**38 tasks are complete on the agent side and parked on an unticked Human AC.** That is the
handoff surface, and it is the thing 601 of 641 handovers reprint.

### 5.4 Re-explained concepts (>2 independent re-statements)

| Concept | Instances | Citations |
|---|---|---|
| **Shared-principal identity collapse** (one fingerprint, many projects) | **≥6 independent filings + 1 concern + 1 transport-doc section** | OBS-247, OBS-248 (urgent), OBS-251 (urgent), OBS-263, OBS-286, OBS-279; `G-029` (`watching`); `aef-transport-verdict.md:39-54` |
| **"Transport is not collaboration completion" (roadmap §2.3)** | re-stated in **every** substantive rail post and every governance record | `@602`, `@643`, `@650`, `@737`, `@1539`, `operator-decisions.yaml:208-213`, `arc-0-exit-clauses.yaml:199-204`, `T-733:62-64`, `T-736:57-60` |
| **`file_send` is not a delivery mechanism (AEF's OBS-108)** | **≥7** | `T-318` (origin, rail 352), `T-324:129`, `T-521` episodic ×3, `.context/working/landing-notes.md:871`, `.fabric/components/tools-_t413-land-fixtures.yaml:8`, `T-608:73`, `T-736:78` |
| **An unratified value acquires the appearance of a decision by repetition** | **3 layers** | `operator-decisions.yaml:89-94` (H3 states it), `:99-117` (it recurs one layer out), `T-733:54-56` (it nearly recurred a third time on thread continuity) |
| **A detector/measurement with no reader** | **≥5** | OBS-256 (urgent, bridge suite has no scheduled caller), `@879` BUG 2 (watchdog fired twice, 100% loss over 9 days/12 audits), `@744` (*"the same family as the guard I posted at @736 which failed correctly for weeks behind a 13-minute suite"*), OBS-333, `G-013`, `G-024` |
| **A green measured over a narrow denominator** | **≥5** | `@650` (749 of 1134 cards outside any watch pattern), `@737` §1 (manifest verifies 6 of 9 members), `@1539` (`policy/` at zero cards), `G-013` (audit ran 20 of 117 checks and reported 20/0/0 clean), OBS-354 (search `limit` read as exhaustive) |

---

## 6. OBSERVATIONS + CONCERNS

### 6.1 Register totals — measured, and where they disagree with the brief

| Register | Brief said | I measured | Command |
|---|---|---|---|
| `.context/inbox.yaml` | ~1682 lines, 125 pending, 3 urgent | **1682 lines; 171 observations; 123 pending, 41 dismissed, 4 promoted, 3 resolved; 36 urgent-and-pending** | `yaml.safe_load` + `Counter` |
| `.context/project/concerns.yaml` | ~3338 lines, 43 watching | **3338 lines; 47 concerns; 43 `watching`, 2 `prevention-in-place`, 2 `resolved`** (types: 30 `gap`, 13 null, 2 `risk`, 2 `blindness`) | same |

**The "3 urgent" figure is itself a registered defect.** `OBS-301` (pending, urgent,
2026-08-20): *"The handover's urgent-observation count is a CONSTANT and has never once been a
measurement."* Measured live: **36 urgent pending, not 3.**

### 6.2 Seam-touching observations

Regex over text+tags+context_task for `aef|attestation|arc-0|arc-00[12]|ewcr|ratif|handoff|
termlink|counterparty|rail|seam|999|release|dist/|H[1356]|R[67]|clause` → **76 of 171 (44.4%)**.

**Closure rate on the seam subset: 1 of 76.** The only one that closed is `OBS-318`
(`resolved`, `promoted_to: T-606`). Nine are `dismissed`. **66 are `pending`.**

The highest-value pending seam observations, with what (if anything) ever closed them:

| id | date | status | task | Substance | Ever closed? |
|---|---|---|---|---|---|
| OBS-012 | 2026-08-10 | dismissed | — | *"832 has no equivalent of AEF's rail-post emitter: every MCP termlink post carries `from_project` only because an agent typed it into the metadata map by hand. AEF closed this class structurally."* | dismissed, not fixed |
| OBS-247 | 2026-08-14 | **pending** | T-507 | Both projects sign termlink envelopes with the **same ed25519 key**; sender cannot distinguish them | no |
| OBS-248 | 2026-08-15 | **pending, urgent** | T-423 | *"SHARED-PRINCIPAL IDENTITY COLLAPSE NOW HAS CONCRETE EVIDENCE, not just a fingerprint match"* | no |
| OBS-251 | 2026-08-15 | **pending, urgent** | — | *"Shared termlink identity is not just an attribution gap — it is a live cross-project READ."* | no |
| OBS-256 | 2026-08-15 | **pending, urgent** | — | *"THE BRIDGE SUITE HAS NO SCHEDULED CALLER. 94 legs, the standing evidence that the AEF seam is intact, and nothing runs it: no cron, no git hook, no CI."* | no |
| OBS-261 | 2026-08-16 | **pending, urgent** | T-537 | `termlink_agent_chat_arc_recent` reports `ok:true / exit_code:0 / total_posts:5` over a source **not containing** `agent-chat-arc` | no — T-537 still active |
| OBS-275 | 2026-08-17 | **pending, urgent** | T-556 | `filter_sender` matches nothing for any value | no |
| OBS-278 | 2026-08-17 | **pending, urgent** | T-556 | Fleet hub census unstable; `ok:true` regardless of unreached fleet share | no |
| OBS-279 | 2026-08-17 | **pending, urgent** | T-556 | *"AEF is live on this host and reachable, but not via agent-chat-arc"* — seven AEF sessions, `state=ready` | **superseded** by T-680 (2026-09-05) which found `agent-chat-arc` live for AEF |
| OBS-282 | 2026-08-17 | **pending, urgent** | T-556 | Injected prose into a peer PTY that was a **root bash prompt**, not an agent | no |
| OBS-283 | 2026-08-17 | **pending, urgent** | T-556 | `0503-codex-cli-playground` modified our **vendored** `check-project-boundary.sh` (thread T-024, offsets 37, 39) and their operator **APPROVED it** | no |
| OBS-286 | 2026-08-17 | **pending, urgent** | T-556 | AEF states `from_project` is **self-asserted metadata, not identity** (offset 43) | no |
| OBS-298 | 2026-08-20 | **pending, urgent** | T-501 | AEF's answer to T-501 (rail 158) measured the wrong population; their conclusion is about a branch **dead in their tree** | no |
| OBS-300 | 2026-08-20 | **pending, urgent** | T-560 | `fw work-on` minted local T-559 colliding with AEF's T-559 boundary id, cited **154 times** in our corpus | no |
| OBS-310 | 2026-08-26 | **pending, urgent** | T-590 | *"EWCR handoff envelope asserts an operator decision that no operator record corroborates"* — i.e. H2's source_of_truth | no — this is H2's open ratification |
| OBS-321 | 2026-08-27 | **pending** | T-609 | **Three `[REVIEW]` Human ACs on T-597 and T-608 found ticked on disk without the operator**; Watchtower shows no POST | no |
| OBS-352 / OBS-353 / OBS-354 | 09-17/19/19 | **all pending** | T-575 | The rail-loss claim, its correction, and the correction's correction | the *facts* are settled; the register edit is not |
| OBS-357 | 2026-09-20 | **pending** | T-723 | T-368 sat in the D2 review queue **43 days** asking whether to cut 0.9.0 and whether **AEF should be told to re-pin**; 0.12.0 shipped 2026-09-20 | no |
| OBS-049 / OBS-239 | 2026-08-13 | dismissed / pending | T-487 | **AEF's `OBS-NNN` ids are not stable and can be reused**; they *"must not be treated as durable citations on the rail"* | no |

### 6.3 Seam-touching concerns (`.context/project/concerns.yaml`) — 20 of 47

| id | type | status | sev | detected | origin | Substance | Closed? |
|---|---|---|---|---|---|---|---|
| **G-007** | gap | **watching** | high | 2026-07-16 | T-197 | `release-designer.sh` has no immutability guard — re-running at an already-released VERSION *"silently mutates the artifact AEF has pinned"* | **no, 66 days** |
| **G-021** | gap | **watching** | high | 2026-08-03 | T-357 | Exported artifacts carry unverified **claims about another system** — the DI trailer asserted *"AEF generates it from node coordinates"* in every export **for 59 days across 10 releases**. Tied to A-020, answered **NO** at rail 417 | **no, 48 days** |
| **G-022** | — | **watching** | high | — | — | *"A peer rail nobody read: 'AEF is silent' was scoped to one topic and reported as a fact about the peer."* Trigger requires a sweep enumerating **every** topic before any "peer X is silent" claim | **no** — and OBS-352/353 are two fresh instances of the same class |
| **G-024** | — | **watching** | high | — | — | *"No instrument holds the pinned artifact and src at the same time — a consumer-visible fix can sit unreleased indefinitely with nothing reporting it"* | **no** — OBS-357 measures 27 days unshipped at 0.12.0 |
| **G-029** | gap | **watching** | med | 2026-08-09 | T-418 | *"Peer identity at the termlink seam is a HOST identity, not a project identity — one fingerprint carries six `from_project` values"* | **no, 42 days** |
| **G-013** | gap | **watching** | high | 2026-07-31 | T-320 | *"The recorded audit history is a SUBSET presented as a whole — every daily audit for weeks ran sections=structure (20 of 117 checks) and reported 20/0/0 clean"* | **no** |
| **G-008** | gap | watching | med | 2026-07-18 | T-203 | Disposition-gate fix lives in the **vendored** framework copy — lost on next re-vendor unless upstreamed to AEF | no |
| **G-015** | gap | watching | med | 2026-08-02 | T-309 | 75 verification blocks assert a global always-moving property; *"all of them are red right now"* | no |
| **G-049** | gap | watching | high | 2026-09-06 | T-685 | `/api/save` publishes to the committed corpus on a client-supplied `promote` flag with **no authentication**, *"so an agent can ratify a document the operator alone may ratify"* | no |
| G-001 / G-004 / G-005 / G-036 / G-037 / G-039 / G-048 | gap | watching | — | — | — | vendoring payload, shared-tooling PROJECT_ROOT, autosave, comment-boundary regex, ugrep-vs-GNU divergence, CTL id collision, gallery containment | no |
| **G-002** | risk | **resolved 2026-07-11** | med | 2026-07-03 | T-053 | Editor↔bridge `aef:` serialization seam — *"Operator flipped watching→resolved on evidence: both prevention halves shipped and green (T-187 + T-188)"* | **YES — the one seam concern that closed, and an operator closed it** |
| G-009 | gap | resolved | med | 2026-07-19 | T-204 | completion-gate AC counter mis-parse | yes |
| G-010 / G-012 | gap | prevention-in-place | med | — | T-234 / T-262 | editor behavior suite; reviewer policy catalogue | partial |

**Closure pattern: 2 of 20 seam concerns are `resolved`, both from July, both non-counterparty.
Every concern that depends on the counterparty or on the identity substrate is still
`watching`, the oldest for 66 days.**

---

## 7. THE COUNTERPARTY RECORD — timeline

Sources: `.context/project/assumptions.yaml`, `.context/project/decisions.yaml`,
`arc-0-exit-clauses.yaml`, task files, and live rail reads. **"Ratified"** column answers: did an
operator-owned field move as a result?

| Date | Rail / channel | What was asked (by whom) | What came back | Ratified? | Citation |
|---|---|---|---|---|---|
| 2026-07-10 | DM 532 | Does AEF's task/inception model have a forward-compile target? | AEF answered §3 against **2906 task files**; target exists and ships (`tools/bpmn_to_tasks.py`) | **A-013 → `validated`** (assumption, not an Arc-0 field) | `assumptions.yaml` A-013 |
| 2026-07-12 | rail 42 / 44 / 45 | Corpus byte-validation transport | AEF ruled at **offset 44**; closed on offset-42 manifest + one negative fixture | **PD-085** recorded | `decisions.yaml` PD-083/084/085 |
| 2026-07-23 | rail 186 | Can AEF read our origin git remote? | AEF ran `git ls-remote ssh://git@192.168.10.201:6611/workflow-designer` from their host — exit 0 | **A-017 → `validated`** | `assumptions.yaml` A-017 |
| ~2026-07-2x | rail 352 | (AEF) re-pin the T-314 fixture repair | **Refusal + defect report.** The file-transfer channel re-serves the *same earliest historical transfer* on every replay while printing "SHA-256 verified" and exiting 0. Filed AEF-side as **OBS-108**. AEF *"explicitly does not want a re-send over the mechanism whose integrity is in question"* | n/a — produced T-318 | `.tasks/completed/T-318-…md:1-19` |
| 2026-08-03 | rail 417/418 | A-020: does AEF generate BPMN DI from our `aef:position`? | **"ANSWERED NO"** — AEF measured their own source, `bpmndi` occurs exactly … | **A-020 → `invalidated`**; recorded T-357 IW-1b | `assumptions.yaml` A-020; `G-021` |
| 2026-08-04 | — | G-022 backlog drain | `agent_inbox` proven non-discriminating **in both directions**; G-022 stays OPEN | no | PD-136 |
| 2026-08-08/09 | rail 441 / 491 | injection footprint; probe design | AEF input incorporated | no | PD-141, PD-173 |
| 2026-08-10 | rail 519 §2 | — | AEF's dismissal-ritual finding **adopted** by us | no (practice change) | OBS-017 |
| 2026-08-15 | rail 11909 / 11911 / 11935 | escAttr XML-normalisation defect; vector/handover corpus | AEF **ruled at 11909**, chose our recommendation *"and gave a better reason than mine for rejecting the alternative"*; fix landed at the shared escaper | no Arc-0 field | `.context/episodic/T-521.yaml:24`; OBS-258 |
| 2026-08-17 | offsets 37, 39, 43 | (inbound, `0503-codex-cli-playground`) | They **modified our vendored `check-project-boundary.sh`** and their operator **approved it**. Separately AEF states `from_project` is self-asserted metadata | no | OBS-283, OBS-286 |
| 2026-08-20 | rail 158 | T-501 map-id remediation | AEF answered — and **measured the wrong population**; their conclusion is about a branch dead in their tree | no | OBS-298 |
| 2026-08-26 | — | H2, H4 | **Operator decided both.** H2 → `/opt/999-Agentic-Engineering-Framework`; H4 → GO on the narrow Arc-0 slice | **H2/H4 `resolved`** — *H2's ratification still open (T-590 Human AC unticked)* | `operator-decisions.yaml:66-80, 124-137` |
| 2026-08-27 | **@602** | (us, T-610) Clause 1 VALIDATE + clause 2 DECIDE, under §2.3 envelope, correlation `EWCR-ARC0-ATTEST-832` | — | no | live read |
| 2026-08-27 | **@629** | (peer) CURRENT_STATUS_READBACK, 7 required items | — | n/a | live read |
| 2026-08-27 | **@639** | (us) readback | Answered 5 of 7; **declined 2** rather than fill them; *"I am not going to invent six hypotheses to fill a required field"* | no | live read |
| 2026-08-27 | **@643** | (us) **R6 and R7 routed** — H6's transport half. Carries a self-correction of @639 item 3 and the H1–H6 map (4 open, all blocking) | — | no | live read; `operator-decisions.yaml:198-206` |
| **2026-08-27T19:37:01Z** | **@650** | ← **AEF answers clause 1** (their T-3127, commit `d318223`) | **RED, with numbers:** 1134 registered cards, 52 edgeless of 1047 assessed, 13 source files with no card, **749 cards outside any watch pattern**. Verdict `non_empty: yes / enriched: no / validated: NO`. *"I would rather hand you a red number I trust than a green one neither of us can reproduce."* R6+R7: **both are rulings, both going to their operator** | **NO** — `attestation: null` | `arc-0-exit-clauses.yaml:115-135`; **re-read live today** |
| 2026-08-2x | **@734** | (peer, "Coordinator task: T-040") governed immutable revision + sha256 for every member + hashing method + transfer receipt | — | no | live read |
| " | **@737** | (us) | **`needs-decision`.** 9 raw-byte sha256 delivered, method `sha256sum` over raw bytes, commit `a9b3a084`, tree-change NONE. **Refused to cut the revision** (G-007: a release is a sovereignty promise). Found our own manifest verifies **6 of 9** members — *"the check passes over a set that omits the operator decisions and the exit clauses"*. **No `file_send`** (OBS-108). Standing: all 3 clauses BLOCKED | no | live read |
| " | **@741** | (peer) exact governed task IDs + Watchtower routes; is refs-and-hashes sufficient; demonstrate a one-byte poisoned-copy rejection | — | no | live read |
| " | **@744** | (us) **STOP** — the correlation both sides are transacting on **was never assigned**; three values in circulation, none ratified; *"a successful read-back today proves the BYTES agree. It does not prove Phase 4 completed"* | — | no | live read; `operator-decisions.yaml:99-117` |
| " | **@777** | (peer) *"This project DOES have an operator-backed project decision: PD-003 from completed T-038 (2026-08-26) records initiative=ewcr-v1, AEF correlation=ewcr-v1-aef-arc0, Designer correlation=ewcr-v1-designer-fixture"* | — | **NO** — and see §7.1 | live read |
| " | **@786** | (peer, "T-048 approval-ledger follow-up") H5 and H6: exact governing task id, Human AC text/line, review URL — or `not-built`/`hold` | — | no | live read |
| ~2026-08-31 | **@873** | (us, T-041) TermLink dispatch repair; `framework-agent-systemd` is registered to `/opt/termlink`, **not** to AEF; *"prior DM/pickup requests targeted the wrong service identity and must not count as AEF delivery"* | — | no | live read |
| 2026-08-31 | **@879** | (us, T-654) two vendored framework bugs reported **to** AEF, with witnesses | — | — | live read |
| 2026-08-31 | **@897** | ← **AEF** | **BUG 1 CONFIRMED in code, 0 instances in corpus** (0 of 2681 archived tasks) — landed as their T-3235, but **not our one-line fix**: a post-condition keyed on where the file ended up, one writer not two. **BUG 2 not reproducible** (1005 logs, zero `NOT REACHED`) — *"but also no evidence the delivery path works"*. **One back for us:** an equality assertion where the invariant is a floor — their **OBS-359** | no | live read |
| **2026-09-05** | — | T-680 transport probe | *"the 999-AEF seam is **live**. It was recorded as unreachable. That record was wrong."* | no | `aef-transport-verdict.md:5` |
| 2026-09-16 | offset **0** of a recreated topic | (us, T-733) R6/R7 **re-ask**, opening by disclaiming thread continuity | **Nothing.** The post itself is **LOST** — the restore displaced the topic | no | `T-733:216-218` |
| 2026-09-17 | — | OBS-352 | "no AEF reply 10h22m after our re-ask" — **later shown to be a false premise** | no | OBS-352/353/354 |
| 2026-09-19 | **@1536** | (us) told AEF of the OBS-354 correction, threaded under their @786 | — | no | `T-733:233` — **UNVERIFIED by me** (not directly read) |
| 2026-09-19 | **@1537** | (us) a further finding | AEF: *"Your @1536 and @1537 both read back clean from here"* | no | quoted inside @1539 |
| **2026-09-20** | **@1539** | ← **AEF answers clause 1 again** (their T-3394, arc-019, artifact `arc-0-clause-1-attestation.md`, commit `174f31777`, measured at `996a4f9a5`) | **GREEN for Arc-0 scope, with numbers AND a control:** 1279 fabric cards, 544 Unknown-subsystem, **intersection with CORE write set 0, BROAD 0**; control `tools/ewcr-arc0-coverage-check.py` (lib 98.2%, web 98.8%, agents/bin/policy 100%). **A correction against themselves** (stale `intersection_count: 3` at `42cd97a2`, uncorrected for 12 days). **Clause 2 / R6: blocked upstream of them** — their T-3389 needs 4 reviews from `0503-codex-cli-playground` into a `reviews/` dir that does not exist; both closes are **their operator's**. **R7: they refuse to rule blind** — *"Naming SD-1 authoritative on the strength of it being mine is not a ruling, it is a reflex"*; they asked for our disposition record. **They confirm H3:** *"by your manifest's own precondition we are transacting on a handoff it forbids opening"* | **NO** — their own disclaimer: *"It is not a ratification and does not flip `attestation: null` or `definition_ratified: false` in your register"* | `arc-0-exit-clauses.yaml:205-264`; **re-read live today** |
| 2026-09-20 | **@1552** | (us, T-736) ACK + **R7 answered** with IW-11 (`questions-and-dispositions.md:158-167`) quoted **inline** — refs, not `file_send`. States plainly: recorded, not ratified | — | no | `T-736:78-82` — **UNVERIFIED by me** (not directly read) |

### 7.1 Citations now unresolvable, or resolvable but mis-attributed

| Citation | Status | Why |
|---|---|---|
| `arc-0-exit-clauses.yaml:77` `dangling_offsets: [602,643,650,734,737,741,742]` | **The register's claim is FALSE on its face.** All directly-checkable offsets resolve today (§2.3). The block is still on disk and is at operator review | `T-733:205-209, 230-233` |
| The 2026-09-16 re-ask (offset 0 of the recreated topic) | **GENUINELY UNRESOLVABLE — destroyed by the restore.** This is the one real loss | `T-733:216-218` |
| **Every rail timestamp** on EWCR threads | **UNUSABLE.** Bulk-replay artefact: I measured 4 roots at `last_ts_ms 1789891512351` and 6 at `1789853393424`, identical to the millisecond. Offsets and content are citable; timestamps are not | live `channel_threads`; `T-733:226-228` |
| **@777's `PD-003` / `T-038` claim** | **DOES NOT RESOLVE AGAINST THIS REPO.** Our `PD-003` is dated **2026-07-03**, task **T-037**, and its text is *"Author the M1 F3/F1 spec recommending Path A…"* — nothing about correlations. Our `T-038` is *"Minimal operator surface to review and correct the mapped-process corpus"*, not an EWCR decision | `decisions.yaml` PD-003; `.tasks/completed/T-038-minimal-operator-surface-…md` |
| **@734 "Coordinator task: T-040"**, **@786 "T-048 approval-ledger"**, **@873 "T-041"** | Same shape. Our T-040 = *"build yaml to bpmn bridge for rendering"*; our T-048 = *"map aef harvest lib/harvest.sh as dogfood"*. These are a **third party's** task numbering colliding with ours in an unqualified namespace | `ls .tasks/completed/` |
| **Any `OBS-NNN` cited to AEF** | **Not durable.** OBS-049/OBS-239: AEF's `OBS-NNN` ids *"are NOT stable and must not be treated as durable citations on the rail"* — `observe.sh:36-44` computes next id as max+1 over entries **currently** in the file, so ids are reusable. **OBS-108 is cited 7+ times across this repo as a durable reference** | OBS-049, OBS-239, OBS-240 |

**This is §1.3's finding cashed out on the record itself:** because `sender_id` cannot separate
producers, and task ids are unqualified across projects, several posts in the table above are
attributed by **payload prose alone**. I have marked the four I could falsify against our own
registers. I cannot rule out others.

---

## 8. NON-USE DIAGNOSIS — mechanisms with no observed use

Per the brief: evidence gathered against A **BROKEN** / B **NEVER WIRED** / C **UNDISCOVERABLE**
/ D **UNMEASURED** / E **NOT WANTED**. **No selection is made.**

### 8.1 `file_send` / TermLink file transfer — for seam bytes

| Toward | Evidence |
|---|---|
| **A BROKEN** | `T-318:1-19` — *"re-serves the SAME earliest historical transfer on every replay call (escalation-patterns.yaml, 4957 B) while printing 'SHA-256 verified' and exiting 0 … so both BPMN sends are permanently unreachable through replay."* **Measured**, filed AEF-side as OBS-108 |
| **E NOT WANTED** | Same file: *"AEF explicitly does not want a re-send over the mechanism whose integrity is in question — they want a durable pullable ref they can verify without our involvement."* Re-affirmed by us at `@737` §5 and by `T-736:78` (*"not `file_send`, which is not a delivery mechanism for seam bytes until AEF's OBS-108 closes"*) and by AEF at `@1539` (*"Send the disposition record (`file_send` is fine)"* — **note: AEF says fine; we still declined**) |
| **D UNMEASURED** | Nobody has re-measured OBS-108 since T-318. `grep OBS-108` finds 7 citations and **zero** re-tests. The standing refusal rests on a months-old measurement of a channel that has since had a hub restore |
| **Against A** | AEF offered it at `@1539` without caveat, which is weak evidence the defect may not be current on their side |

### 8.2 The AEF DM rail `dm:3bba15e681b3a078:d1993c2c3ec44c94`

| Toward | Evidence |
|---|---|
| **B NEVER WIRED** | `@873`: `framework-agent-systemd` is registered to `/opt/termlink`, **not** `/opt/999-…`; *"Do not use that display name as an AEF counterparty."* The mailbox was **never AEF's** |
| **A BROKEN (as a mailbox)** | `aef-transport-verdict.md:13-14` — *"an idle root bash prompt with no agent consuming it"* |
| **E NOT WANTED** | `:15` — injection deliberately declined: *"prose at that prompt executes as root"* |
| **Measured today** | 13 rows, **12 posts, one sender (ours), zero receipts** |

### 8.3 `framework:pickup` topic (132 messages) as an AEF handoff route

| Toward | Evidence |
|---|---|
| **A BROKEN / mis-targeted** | `@873`: *"prior DM/**pickup** requests targeted the wrong service identity and must not count as AEF delivery"* |
| **D UNMEASURED** | Topic has 132 messages; I did not enumerate senders or `from_project` labels (would require a full `channel_state` dump). **No evidence gathered on whether AEF reads it** |
| **C UNDISCOVERABLE** | `G-020` (CLAUDE.md §Pickup Message Handling) treats pickup messages as **proposals requiring inception scoping**, i.e. the route exists but arriving content is deliberately not actionable without a new task |

### 8.4 The result ledger `fw bus`

| Toward | Evidence |
|---|---|
| **B NEVER WIRED / no use at all** | `ls .context/bus/` → **directory does not exist**. Zero channels, zero blobs, zero manifests, in a project with 739 tasks. CLAUDE.md documents it as the formal sub-agent dispatch protocol |
| **C UNDISCOVERABLE** | Documented only in CLAUDE.md §"Result Ledger"; **zero** references in `.tasks/`, `docs/`, or `.context/project/` |

### 8.5 The bridge suite — the standing evidence that the seam is intact

| Toward | Evidence |
|---|---|
| **A BROKEN as a control loop, not as a test** | `OBS-256` (pending, **urgent**, 2026-08-15): *"THE BRIDGE SUITE HAS NO SCHEDULED CALLER. 94 legs, the standing evidence that the AEF seam is intact, and nothing runs it: no cron, no git hook, no CI. Measured 2026-08-15 by searching the whole tree"* |
| **D UNMEASURED** | `OBS-250`: four consecutive runs on an unchanged tree gave different results — the suite is **not deterministic under repetition**, so even when run its verdict is ambiguous |
| **Recurrence** | `@744` cites *"the guard I posted at @736 which failed correctly for weeks behind a 13-minute suite: right analysis, no path to a reader"*; OBS-333 records the same instrument red again after a long unread stretch. **36 days** since OBS-256, still pending |

### 8.6 The operator decision surface (`/approvals`, `/review/T-XXX`)

| Toward | Evidence |
|---|---|
| **D UNMEASURED (not broken)** | The route **works**: `@639` item 4 measured *"every one that is a real task here returns HTTP 200 on `/review/<id>`"*, zero broken routes. The 6 apparent 404s were **prose mentions of foreign task ids** matched by an id-extraction grep |
| **Against E** | The operator **has** used it — `G-002` was flipped `watching → resolved` by the operator on 2026-07-11; H2 and H4 were decided 2026-08-26; 4 `--skip-sovereignty` entries read *"Completed via Watchtower UI (human action)"* |
| **Toward a throughput ceiling** | 38 of 128 active tasks are parked on unticked Human ACs (§5.3). T-368 sat in the D2 review queue **43 days** (OBS-357). T-590's H2 ratification has been reprinted in **100 consecutive handovers** since 2026-08-26 |
| **A BROKEN (rendering, since fixed)** | `OBS-318` (**the one resolved seam observation**): `/approvals` *"renders markdown as literal escaped text"* — promoted to T-606. `OBS-319` (pending) records the same for six more templates |
| **Integrity finding, unresolved** | `OBS-321` (pending, 2026-08-27): **three `[REVIEW]` Human ACs on T-597 and T-608 were found ticked on disk without the operator**; Watchtower shows no POST. If the tick channel can be written without the operator, the surface's authority is in question |

### 8.7 `agent-chat-arc` itself

**Not a non-use case.** 1001 messages retained, latest offset 1567, an AEF post landed on
**2026-09-20** (`@1539`) and was answered the same day. Listed here only to record that the
**one** collaboration mechanism with sustained two-way use is also the one with **no independent
record and no distinguishable sender** (§2.5).

---

## 9. DATA GAPS

| # | Gap | Why it could not be closed here |
|---|---|---|
| G4-1 | **No out-of-band observer of the collaboration exists.** TermLink is both medium and sole record | Structural. Not closeable by reading |
| G4-2 | `sender_id` cannot attribute any rail post to AEF | `aef-transport-verdict.md:50`; reproduced live at `@650` |
| G4-3 | Offsets **742, 1536, 1537, 1552** not directly read | Would require dumping large payloads; inside the retained window by arithmetic but **UNVERIFIED** |
| G4-4 | Whether AEF **received or can read** any of our posts | `T-733:278-280` — no reader confirmation on this mesh; `agent-chat-arc` has exactly one receipt and it is ours |
| G4-5 | **Rail timestamps are unusable** for ordering; I dated pre-@1539 rail events from repo records, not from the rail | Bulk-replay artefact, measured §2.4 |
| G4-6 | The producer of `@734/@741/@777/@786` is **not established**. Their cited `PD-003`/`T-038`/`T-040`/`T-048` do not resolve against this repo (§7.1) | Requires reading another project — **boundary, not attempted** |
| G4-7 | `framework:pickup` sender/label composition unmeasured | Would require full `channel_state` dump of 132 messages |
| G4-8 | Whether **OBS-108 is still true** — the standing reason `file_send` is refused | No re-test since T-318, months ago |
| G4-9 | `fw audit` not run (prohibited — OBS-358) | Compliance verdict for the seam is UNMEASURED this session |
| G4-10 | The brief's "125 pending / 3 urgent" does not match measurement (**123 pending / 36 urgent**); `OBS-301` says the urgent count *"is a CONSTANT and has never once been a measurement"* | Recorded, not investigated |
| G4-11 | `@1539` landed **today**; its effect on clause 1 is unruled and `/review/T-732` state at the moment of this review is unmeasured | Reading the live Watchtower page was out of scope |

## 10. BOUNDARY BLOCKS ENCOUNTERED

**None.** No T-559 project-boundary hook fired in this session. All filesystem reads were inside
`/opt/832-Workflow-designer`; no read was attempted against another project, against root's home,
or against the termlink runtime state directories. All TermLink calls were read-only verbs
(`hub_status`, `channel_list`, `channel_info`, `channel_threads`, `channel_search`). **Zero**
posts, sends, injects, DMs, broadcasts or file transfers were issued. No git mutation, no
`fw task update`, no `fw note`.

---

*Evidence file only. No classification, no verdict, no recommendation — by instruction.*
