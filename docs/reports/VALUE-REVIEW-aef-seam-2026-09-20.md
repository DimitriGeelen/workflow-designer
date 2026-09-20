# Value review — the AEF integration seam (JUDGE report)

**Date:** 2026-09-20 · **Role:** JUDGE (Phase 4–5) · **Inputs:** the seven evidence files in
`docs/reports/VALUE-REVIEW-aef-seam-2026-09-20/` and nothing else.

**Nothing in this report was executed.** No task was created, no status changed, no note filed, no
rail post sent, no file touched but this one. I ran **no commands at all** — not even to re-verify
a claim the evidence already makes. Every fact below is traceable to one of the seven files, cited
as `NN §S` (file number, section).

This is a proposal document. The human decides.

---

## 1. Yardstick (confirmed)

The operator's own scoping sentence, verbatim (`00`):

> *"the integration with AEF and operator AEF, agent collaboration where we go from a workflow to
> a program to incomplete execution and that handoff in between that and what we need for that."*

Read as, and confirmed by `00 §Purpose` against `README.md`, `.context/arcs/` and
`policy/value-drivers.yaml`: **the AEF integration seam — operator↔AEF and agent↔agent
collaboration — along the chain WORKFLOW → PROGRAM → EXECUTION, the handoffs between those stages,
and what is missing to make the chain work.**

The two in-scope arcs declare the two stages themselves:

| Arc | Stage | Headline mechanic (verbatim, `00`) |
|---|---|---|
| arc-001 `designer-authoring-surface` (T-175) | **workflow → program** | "A human draws a process in the browser designer and the AEF agent turns it into an approved governed task/inception graph; conversely existing AEF work is rendered back as an editable process map — over a portable BPMN↔task-YAML standard." |
| arc-002 `ewcr-governed-delivery` (T-590) | **program → execution** | "An operator opens a workflow authored in the Designer, exports it as an executable contract, and a runtime executes it — where every step is traceable to the evidence that justified it and to the operator decision that authorised it, and any step lacking either is refused rather than run." |
| arc-003 audit remediation | — | **OUT OF SCOPE** (`00`) |

Scoring axis (sovereign, not mine to change): D1 Antifragility 9 · D2 Reliability 7 · F-RECALL 6 ·
D3 Usability 5 · D4 Portability 3 (`policy/value-drivers.yaml` v3).

I judge value against that purpose. Not against taste, not against line count.

---

## 2. Data availability map (confirmed) + snapshot windows

**Snapshot: all seven gatherer legs ran on 2026-09-20.** Where a figure has a different window
(peer pin last moved 2026-07-29; bypass log spans 2026-06-05 → 2026-09-08; audit corpus first
record 2026-06-05) the row says so.

| Source | Status | Notes / what it supports |
|---|---|---|
| Task ledger `.tasks/` | EXISTS | 128 active + 611 completed = 739 (`05 §0`) |
| Arcs `.context/arcs/` | EXISTS | 3 files, 2 in scope; both `closed_at: null`, `demo_evidence: null`, `bvp_scores: {}` (`05 §1`) |
| Component fabric `.fabric/components/` | EXISTS | 378 cards; **277 of them are `tools/` probes** (`05 §5`); 0 cover vendored `.agentic-framework/` (`00`) |
| Audit records `.context/audits/` | EXISTS | 74 + 740 cron = 814 working-tree records (`05 §8`) |
| Gate bypass log | EXISTS | 148 entries, 53 tasks (`04 §4`) |
| Episodic / handovers | EXISTS | 611 / 641 (`04 §5`) |
| Observation inbox | EXISTS | 171 observations; **123 pending, 36 urgent** — not the "3 urgent" the handover prints (`04 §6.1`) |
| Concerns register | EXISTS | 47 concerns; 43 `watching`, oldest seam concern 66 days (`04 §6.3`) |
| BVP per task | EXISTS but **all proposed** | `bvp_scores:` confirmed on **0 of 739**; 596 carry `bvp_scores_proposed:` (`05 §6`) |
| **BVP realization log** | **ABSENT** | `.context/audits/bvp-realization.jsonl` does not exist; no realization artifact of any name (`05 §7`) |
| **Capability registry** | **ABSENT** | `policy/capabilities.yaml` not present (`00`) |
| Integration protocol / frozen standard / Arc-0 exit gate | EXISTS | `01 §5`, `01 §7`, `01 §1` |
| Seam corpus `examples/aef-processes/rendered/` | EXISTS | 24 `.bpmn`; AEF pins against it (`01 §8`) |
| Release manifest `dist/MANIFEST.yaml` | EXISTS | 0.12.0, src↔release sha256 identical (`01 §6`, `06 §4`) |
| TermLink rail history | **EXISTS — the earlier "LOST" claim is retracted and refuted** | Re-measured independently by G1 (`01 §2`) and G4 (`04 §2.3`): all cited offsets return full payloads on 2026-09-20 |
| **Execution traces per node** | **ABSENT — confirmed, not assumed** | Six independent searches; nothing anywhere pairs a node uid with a result (`03 §4`) |
| CI | EXISTS but **no test job** | `.onedev-buildspec.yml` declares exactly one job: push to GitHub mirror (`02 §7`) |
| Operator surface | EXISTS, probed live | ~60 routes; `/runs` `/traces` `/execute` `/run` `/workflow` `/workflows` `/workflow/run` `/ewcr` `/contracts` all **404** (`06 §2`) |

**Standing structural gap, restated because it caps almost everything:** TermLink is both the
medium of the 832↔AEF collaboration and the only record of it. There is no out-of-band observer
(`04 §2.5`, `06 §7.1`). `sender_id` cannot separate producers — 3 distinct sender_ids across 18
producer labels, and **0 of AEF's 66 posts are attributable to a non-ours sender_id** (`04 §1.3`).
Rail timestamps are unusable: four thread roots report `last_ts_ms 1789891512351` and six report
`1789853393424`, identical to the millisecond — a bulk-replay artefact (`04 §2.4`).

**Pollution disclosure (carried forward from `00`):** the gathering session ran `fw review-queue`,
a pre-push `fw audit --section structure`, `fw bvp estimate`, and made four commits before the
snapshot. G2 disclosed one incidental write (`.playwright-mcp/t258-annotation-badges.png`).
G5's audit counts are working-tree, not HEAD — many `cron/*.yaml` records were staged as deleted
(`05 §9 G5`). Counters are read after that activity, not from a clean baseline.

---

## 3. Role setup

**Separated — yes.** Stated so the reader can check the claim rather than take it:

- **GATHERERS:** the coordinating session plus five dispatched read-only workers (G1–G5), each
  writing its own evidence file and returning summaries only; the coordinator wrote `06` for the
  one domain it did not delegate (`00 §Role separation`). They gathered evidence and were
  instructed not to classify. They complied: every file ends by saying so.
- **JUDGE:** a separate worker (this one, Opus 5), whose only inputs are the seven files. I did not
  explore the repo, run `fw`, grep the tree, or read any source file. I ran zero commands.
- **HUMAN:** decides (Phase 5) and authorises execution (Phase 6).

Because role separation was maintained, **no one-level confidence penalty is applied**. Two further
things the reader should weigh when checking that claim:

1. The gatherers corrected each other and themselves in writing. `06 §4` carries a boxed
   `CORRECTED 2026-09-20 after G1/G2 evidence landed` reversing its own first reading of the audit
   PASS. `06 §3` files counter-evidence against a task the same session had filed hours earlier.
   G1 and G4 independently re-measured the rail-loss claim and independently refuted it.
   That is the behaviour of separated workers, not of one voice agreeing with itself.
2. Two gatherers overlapped deliberately on the release seam (`01 §6`, `06 §4`) and on the rail
   integrity (`01 §2`, `04 §2.3`). Their numbers agree. Those are my HIGH-confidence rows.

**Where the evidence disagrees with the brief it was given, the evidence wins and says so:** the
inbox is 123 pending / 36 urgent, not 125/3 (`04 §6.1`, and `OBS-301` records that the "3" is a
constant that "has never once been a measurement").

---

## 4. Baseline

What the chain looks like on 2026-09-20, in numbers, before any proposal:

| Dimension | Measure |
|---|---|
| Stage 1 (workflow) | **Works.** One editor, 997,254 bytes; one serializer + one deserializer; 3 export formats; 24-map rendered corpus; 24 contract/round-trip suites that pass when run (`02 §0,§1,§7`) |
| Stage 2 (program) | **Partial and broken at the wire.** `fw bpmn compile` → exit 1, `compiler not found`; `fw bpmn promote` → same; `fw corpus` → exit 2. `ls .agentic-framework/tools/` → *No such file or directory* (`02 §3`, `03 §0`) |
| Stage 3 (execution) | **Absent, by design and by measurement.** `fw workflow run` named in 16 files, implemented in 0. Every runtime component DESIGNED-ONLY. Zero execution records anywhere. Zero execution routes on the operator surface (`03 §0,§2,§4`; `06 §2`) |
| Arc-0 exit | **0 of 3 clauses satisfied.** `attestation: null` ×2, `definition_ratified: false` ×3, `blocks_arc_0_exit: true` ×3 (`01 §1`, `04 §3.4`) |
| Seam tasks | **0 of 16 Human ACs ticked across all nine** (`01 §4`); oldest 25 days |
| Whole-ledger review queue | 12 tasks >30d (oldest T-093, 77d), 23 more >14d; the **only FAIL** in the latest audit (`05 §8`) |
| Partial-complete | **38 of 128 active tasks** are agent-complete and parked on an unticked Human AC; 601 of 641 handovers reprint that state (`04 §5.3`) |
| Release seam | src ↔ dist **in step at 0.12.0**; peer pin **0.8.0, 53 days, four unadopted releases**; `/designer/app` serves **0.8.0**; the audit prints **PASS** (`01 §6`, `06 §4`) |
| CI | **None.** One job: push to mirror. Every guard runs only when a human or agent types it (`02 §7`) |
| Value ledger | **0 confirmed BVP scores of 739**; arc-002 has **0 of 27 members ranked**; no realization data (`05 §6,§7`) |
| Collaboration | `agent-chat-arc` live, 1001 messages, an AEF post landed and was answered **today**. And no distinguishable sender, no reader confirmation, no usable timestamps (`04 §2,§8.7`) |

**The one-sentence baseline:** the workflow stage is real and tested, the program stage is wired to
a file that was never vendored, the execution stage does not exist and — on the project's own frozen
standard — is not buildable as currently designed; and the thing actually holding the chain still is
not code, it is **sixteen unticked Human ACs and four unassigned operator rulings**.

---

## 5. Summary

### 5.1 Counts per class

| Class | Count |
|---|---:|
| KEEP | **28** named items (§7) |
| DELETE | **0** |
| REFACTOR | **2** |
| ADD | **20** (REPAIR 9 · WIRE 3 · SURFACE 5 · NEW/instrument 3) |
| INVESTIGATE | **9** |

**DELETE is zero, and that is a finding, not a failure of nerve.** I tested every non-use candidate
the evidence offers — the probe population, `dist/` history, the dead DM mailbox, the deferred
inceptions, `build/gallery/` — against the seven DELETE CHECKS. Every one fails check (4) *no
references anywhere* or check (5) *no external consumer*. This project has an external consumer
(999-AEF) whose side is unobservable from here (T-559), and its consumer is **currently pinned to a
three-versions-old artifact in `dist/`**. In a repo whose job is to be pinned against, "nothing
references it here" is close to worthless as an argument. Details in §6 notes and §8.

### 5.2 Top 3 per axis

**ADD**
1. **F-A1 — Ship the manifest projection.** The `{name, owner, workflow_type}` projection the whole
   seam is defined on exists exactly once, as `extract_manifest` inside
   `tests/test_promote_contract.py:137` (`02 §3`). Make it a real 832 artifact.
2. **F-A2 — Make the release-lag check tell the truth.** The audit prints `PASS — src, released
   artifact and peer pin are in step` while the pin is four releases and 53 days behind and the
   operator's own `/designer/app` serves 0.8.0 (`01 §6`, `06 §4`).
3. **F-A3 — Teach the Arc-0 gate to read the superseding block.** The counterparty's 2026-09-20
   GREEN is in the register and invisible to the only mechanical reader (`01 §1`, `01 §10`).

**REFACTOR**
1. **F-R1 — Collapse the two arc-membership sources of truth** (15/25 by `arc_id:` vs 32/27 by
   `fw arc show`; T-623's two fields name different arcs) (`05 §0`).
2. **F-R2 — Batch the twelve parked seam tasks into one decision packet** in the proven T-732
   dossier format, instead of reprinting them in 601 of 641 handovers (`04 §5.3`, `05 §2`).
3. *(no third; two is the honest count)*

**INVESTIGATE**
1. **F-I1 — Is OBS-108 still true?** The `file_send` self-embargo that has held the fixture for 25
   days rests on one measurement from T-318, never re-tested, on a channel that has since been
   restored — and the counterparty offered the channel at @1539 (`04 §8.1`).
2. **F-I2 — What is AEF's current pin?** One rail read-back closes three gaps at once (`01 §11.1`).
3. **F-I3 — Who actually produced @734/@741/@777/@786?** Their cited `PD-003`/`T-038`/`T-040`/`T-048`
   do not resolve against this repo (`04 §7.1`).

**DELETE** — none. **KEEP** — see §7.

### 5.3 The chain, stage by stage — *"what we need for that"*

This is the operator's literal question. One line each for what exists, what is missing, and the
single highest-value next move.

---

#### STAGE A — WORKFLOW → PROGRAM (arc-001)

- **Exists:** a working single-file editor with one serializer and one deserializer, three export
  formats, a 26-marker `aef:` vocabulary, a 24-map rendered corpus, the YAML→BPMN bridge, a
  1773-line validator that *does* enforce lane authority (IW-9), 24 contract and round-trip suites
  that pass when run — including a proven semantic fixed point (36/36 keys LIVE, 0 BLIND) and a
  cross-seam no-silent-drop guard with a working poison control (27/27 detected) (`02 §1,§2,§7`).
- **Missing:** (i) **no shipped tool projects a `.bpmn` into the manifest the seam is defined on** —
  it exists only inside a test as a reimplementation of AEF's read (`02 §3`); (ii) the compile and
  promote verbs route to `.agentic-framework/tools/`, **a directory that was never vendored**
  (`02 §3`, `03 §0`); (iii) the editor emits no canonical YAML although `docs/designer/schema.md:106`
  defines YAML as the source-controlled form (`02 §1`); (iv) **nothing in automation ever runs any
  guard** (`02 §7`); (v) the reverse half — AEF record → editable map — is an unstarted inception
  correctly parked to `revisit_at: 2026-10-01` (`02 §6`).
- **Single highest-value next move: ship the manifest projection as a real, pinned 832 artifact.**
  It is inside 832's declared ownership column ("import/export and round-trip constraints",
  `01 §1`), needs no counterparty permission, turns a test-private function into the seam's actual
  contract surface, gives R5 something to read back, and is the **only** thing that could ever
  constitute demo evidence for arc-001's headline mechanic.

#### HANDOFF A→B (operator↔AEF, and the bytes that cross)

- **Exists:** `dist/MANIFEST.yaml` with src↔release sha256 identity and build lag 0; **complete**
  provenance — all 15 `designer-v*` tags for 0.1.0→0.12.0; a render gate on release cut;
  `fw designer sync --from` with sha256 verification at the far end; one proven delivery (0.1.0,
  2026-07-10, 394,110 bytes); and a genuinely live rail — 1001 messages, an AEF post landed and was
  answered on the review date (`01 §5,§6`; `04 §7`; `06 §5`).
- **Missing / broken:** the peer pin is **0.8.0** and the operator's own designer page serves those
  exact bytes while the audit says PASS; `file_send` is self-embargoed on an un-re-measured defect
  the counterparty no longer objects to; the fixture envelope says `delivered: false` on a premise
  **the operator already overturned** ("That was invented… The invented gate stalled Arc 0 for three
  sessions"); no post can be attributed to AEF; AEF has no read receipt; **0 of 16 Human ACs** are
  ticked; and the two correlations Phase 4 completion is *defined* on are `UNASSIGNED` while a
  handoff has been open on them for 24 days — which the counterparty itself flagged at @1539
  ("by your manifest's own precondition we are transacting on a handoff it forbids opening")
  (`01 §3,§6,§8`; `04 §2.6,§3.1,§7`).
- **Single highest-value next move: the operator assigns the two correlations (H3).** One sovereign
  act, minutes of work. Four independent sources name it as the binding precondition, both sides
  agree it is unmet, and it gates Phase 4 completion, AEF's nine-member manifest expansion, and
  their revision cut. Nothing else on this handoff is cheaper per unit unblocked. **Assign our own
  values and publish them** — do not adopt @777's `PD-003` citation, which does not resolve against
  this repo (`04 §7.1`).

#### STAGE B — PROGRAM → EXECUTION (arc-002)

- **Exists: nothing that runs — and the project measured that itself.** Exactly three things are
  implemented, and none executes: the authoring/validation surface; the Arc-2 **negative** proof
  (T-682/683/684 — "no request path reaches an execution primitive", zero secret-pattern matches);
  and the Arc-0 fabric fence (`03 §2e`). `fw workflow run` is named in 16 files and implemented in
  zero, consistently labelled planned — the README's claim about it is **accurate** (`03 §1`).
  All nine execution routes on the operator surface 404 (`06 §2`).
- **Missing:** every `§6.2.1` field has carrier **"none"** in the frozen surface — `action`,
  `implementation.path` + `content_hash`, `interpreter`, `invocation.*`, typed `inputs`/`outputs`,
  and `controls.capability_profile` which is "none, **and must not**" (`03 §2b`). No instance model,
  no ledger, no ratification registry, no router, no dispatcher, no refusal-matrix artifact. The
  gateway condition is "**a label, not a predicate**". `callActivity` is absent from the editor
  entirely. `aef:meta@tier` is carried 77 times across 15 of 25 maps and enforced **zero** times
  (`03 §0,§2d`).
- **And the blocker that decides the stage:** `aef:endpoint` — the one attribute in the corpus that
  looks like a node→command binding, present 108 times — is classed **"Presentational (diagram
  cosmetics)"** by Part I of the project's own **frozen, normative** standard, which further states
  the forward compile MUST read **only** the semantic class. A compiler is therefore *forbidden* to
  read it. `docs/designer/schema.md:239` says the opposite ("what executes this step"). **The frozen
  standard wins. The execution stage is not buildable as designed.** (`03 §5a`)
- **Single highest-value next move: do not build a runtime. Get one ruling.** Ask — as a new
  R-series item to AEF, in the Part II provisional annex where new semantics belong — *what semantic
  key carries the node→action binding*. Everything downstream (typed guards, I/O, ledger, refusals)
  is unbuildable until that carrier exists and is cheap to design once it does. My recommendation on
  the substance is in **S-2**: do **not** promote `aef:endpoint`. Its 107 distinct values are the
  worst-quality data in the corpus — 9 resolve to nothing, **48 of 63 script paths resolve from no
  anchor at all**, `AGENT.md` is ambiguous across 15 candidate files, and T-298 already recorded
  these line-range pointers drifting (`03 §5b,§5c`). Making that authoritative would freeze a
  governance semantic onto free text.

---

## 6. Findings table

One row per non-KEEP item. Evidence column cites the file and section. Ranked within each class
block by value per unit of cost and risk.

**Type key:** REPAIR (wanted, broken) · WIRE (works, nothing calls it) · SURFACE (works, wired, not
findable) · EXTEND · NEW. **Reading key:** A BROKEN · B NEVER WIRED · C UNDISCOVERABLE ·
D UNMEASURED · E NOT WANTED.

| ID | Item | Location | Class | Reading | Evidence | Counter-evidence | Conf. | Proposal | Size | Rev.? | Risk if wrong | Expected effect (pre-registered) |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| **F-A1** | Manifest projection exists only inside a test | `tests/test_promote_contract.py:137` (`extract_manifest`); sole other consumer `test_two_lane_joint_contract.py` | **ADD (WIRE)** | B | `02 §3`: "no shipped 832 tool projects a `.bpmn` into the `{name, owner, workflow_type}` manifest the seam is defined on"; T-201 IW-2 ruled the seam is **manifest-as-seam**, content authority 832 | T-559 symmetry means no live end-to-end run from either side (`02 §3`), so a shipped projection still cannot be exercised jointly without AEF | **HIGH** (observed ×2: T-201 ruling + measured single definition) | Extract the projection into a shipped tool + pin a fixture and its sha256; publish projection+hash to AEF as the R5 read-back payload | small–med | yes (new file; git) | A 832-side projection drifts from AEF's actual read and gives false confidence — mitigate by pinning the fixture sha256 and asking for read-back, not by asserting agreement | A `.bpmn`→manifest projection is invocable outside `tests/`, and arc-001 has a candidate `demo_evidence` path for the first time. Check: next arc-001 owning commit; at the next release cut. |
| **F-A2** | Release-lag check prints PASS over a four-release-stale pin; `/designer/app` serves 0.8.0 | `.agentic-framework/agents/audit/audit.sh:2253-2268`; `tools/_t382-release-lag.py`; `policy/designer-pin.yaml:20-27` | **ADD (REPAIR)** | D | `01 §6` (pin 0.8.0, sha `cab3c751…`, last moved 2026-07-29 = **53d**, four unadopted releases, audit `level: PASS`); `06 §4` independently: `/designer/app` bytes **sha256-identical** to `dist/…-0.8.0.html`; G-024 `watching`; T-368 GO, **43d** in queue naming exactly this | The probe **states its own bound** ("reads a VENDORED copy… can only UNDER-report adoption lag"); protocol `:34-35` makes re-pin the consumer's act, so non-adoption may be the peer's standing choice | **HIGH** (measured sha256, two independent legs) | Re-key the check on pin-vs-`dist/MANIFEST.yaml latest`; where the peer's live pin is unreadable report **WARN/UNKNOWN, never PASS**. Strengthens the gate; weakens nothing | small | yes | Over-reporting lag creates noise on a state the consumer legitimately chose — mitigate by reporting *observable* drift (vendored pin vs our latest) and labelling the peer's live pin unknown | The next audit record shows the release-lag line as WARN/UNKNOWN, not PASS, while the vendored pin ≠ latest. Check: first audit run after the change. |
| **F-A3** | Arc-0 gate cannot see the counterparty's superseding GREEN | `tools/_t597_arc0_clauses.py`; register block at `arc-0-exit-clauses.yaml:204-252` | **ADD (WIRE)** | B, D | `01 §1` last row: `grep -n "superseding\|1539\|T-736"` → **0 hits**; "a reader running the gate sees a 2026-08-27 red and no mention of the 2026-09-20 green"; `01 §10` row 2: "the green is invisible to the only mechanical reader" | The register's own rule is that the green changes nothing until the operator rules: "attestation stays null… Arc 0 remains 0 of 3" — and AEF agrees ("not a ratification") | **HIGH** (measured grep + the register text) | Make the gate **narrate** both the RED and the superseding GREEN with dates and scope. It must **not** flip any clause — the verdict stays BLOCKED until the operator rules | small | yes | A reader mistakes narration for satisfaction — mitigate by printing the clause verdict unchanged and adding the green under an explicit "superseded-by, unruled" label; the 13/13 self-test (9 poison arms) guards the verdict | `_t596-arc0-exit-gate.sh` still exits 1, and its clause-1 narration names the 2026-09-20 answer. Check: next gate run. |
| **F-A4** | The register asserts a dangling-rail claim that is false and retracted | `arc-0-exit-clauses.yaml:45-78` | **ADD (REPAIR)** | A | Refuted **independently twice**: `01 §2` (all offsets return full payloads) and `04 §2.3` (offset-by-offset table + retention arithmetic: oldest retained ≥567, every "dangling" offset >567). Retraction already exists (OBS-354; rail @1536). Commit `116cc3b4` edited this very file **today** and left the false block | The agent **deliberately declined** to edit it because the file is under operator review (`04 §2.4`) — this is correct restraint, not neglect. Offset 742 remains UNVERIFIED directly | **HIGH** (2 independent measured re-reads + the author's own retraction) | **Operator-authorised** correction: mark the block superseded in place, keep the original visible, inline the OBS-354 retraction. **See S-3** — I propose, the operator acts | small | yes (git) | Correcting a file mid-review confuses the decision packet — mitigate by superseding in place rather than deleting, and by doing it as part of the T-733 ruling | The file the counterparty reads no longer asserts a claim its own author retracted. Check: at the T-733 ruling. |
| **F-A5** | `release-designer.sh` has no immutability guard | G-007, `watching`, **high**, 66 days, origin T-197 | **ADD (REPAIR)** | D | `04 §6.3`: re-running at an already-released VERSION "**silently mutates the artifact AEF has pinned**"; our own words at @737 — "a release is a sovereignty promise"; determinism is claimed at protocol `:55-56` and **never verified** (`01 §11.3`) | Zero bypasses of the release gate were ever logged (`04 §4.6`), so the hazard has not yet fired | **MEDIUM** (observed register entry + claimed determinism; no measured incident) | Add a guard refusing a rebuild at an already-released VERSION unless the output is byte-identical; verify by rebuilding 0.12.0 into a temp dir and comparing sha256 | small | yes | A legitimate reproducible rebuild is blocked — mitigate by allowing byte-identical rebuilds and refusing only divergent ones | `scripts/release-designer.sh` refuses a divergent rebuild at a released VERSION; determinism gap `01 §11.3` closes. Check: next release cut. |
| **F-A6** | Every seam guard runs only when a human types it — and flaps when it does | `.onedev-buildspec.yml`; `tests/run-bridge-tests.sh` (2211 ll., 94 legs) | **ADD (REPAIR → then WIRE)** | A (as a control loop), B, D | `02 §7`: CI has **one** job, `!PushRepository`, **no** `!CommandStep`, no reference to `tests/`. OBS-256 (**urgent**, 36 days): "94 legs, the standing evidence that the AEF seam is intact, and nothing runs it". OBS-250: four consecutive runs on an unchanged tree gave **different results**. The suite writes into `.context/audits/` (`:2144-2147`) | The suites genuinely pass when run — G2 ran six of them green today, with working poison controls. Last third-party full run: 69 passed / 0 failed | **HIGH** (measured CI file + 2 urgent observations) | **Order matters:** (1) make the suite side-effect-free and deterministic; (2) *then* add a scheduled/CI caller. Wiring a flapping, file-moving suite into a gate manufactures noise and a new bypass class | medium | yes | Premature wiring produces red builds nobody trusts, which trains bypass — mitigate by gating step 2 on N consecutive identical runs on an unchanged tree | Step 1: N identical consecutive runs on an unchanged tree. Step 2: the suite has a caller that is not a human. Check: OBS-256 closable. |
| **F-A7** | Human ACs found ticked on disk with no operator action | OBS-321 (pending), T-597 and T-608, three `[REVIEW]` ACs | **ADD (REPAIR)** + **SOVEREIGN** | A | `04 §6.2`, `§8.6`: "three `[REVIEW]` Human ACs on T-597 and T-608 found ticked on disk without the operator; Watchtower shows **no POST**" | `04 §8.6` also shows the surface *works* and the operator *has* used it (G-002 flipped by the operator; H2/H4 decided; 4 bypasses read "Completed via Watchtower UI (human action)") | **MEDIUM** (one observed filing, unresolved 24 days; no second source) | Instrument the tick channel so a Human-AC tick carries provenance; pending that, treat those three as **unticked**. **See S-5** — this touches authority and is the operator's call | small–med | yes | Treating a genuine operator tick as invalid wastes their time — mitigate by asking them to confirm the three, not by reverting silently | A Human-AC tick is attributable to a POST or is flagged. Check: next `[REVIEW]` tick. |
| **F-A8** | Four `fw` verbs route to a directory that was never vendored | `bin/fw:4262-4281`; `.agentic-framework/tools/` absent | **ADD (REPAIR)** | **A** (primary), B, and E *partially* | `02 §3` / `03 §0`: `fw bpmn compile` → exit 1 `compiler not found`; `fw bpmn promote` → same; `fw corpus --help` → **exit 2**; `fw corpus lint` → exit 2; `ls .agentic-framework/tools/` → *No such file or directory*. `fw designer draft` separately broken on a hardcoded `$PROJECT_ROOT/bin/fw` that does not exist here (`02 §5`). G-001 (`vendoring payload`) is the standing register home | **This is where A vs E must be split.** `test_promote_contract.py:6-11` gives a *positive* reason 832 does not run AEF's compiler ("T-559 is SYMMETRIC… no live end-to-end run from either side"). That is E for **the seam act**. It is **not** E for the vendoring: help text works, the route is live, and `fw corpus` is not a seam verb at all | **HIGH** (measured exit codes ×4, two independent legs) | **Resolve as A at the vendoring layer, not as E.** Either include `tools/` in the vendored payload, or make the dead routes fail loudly and appear in `fw doctor`. Do **not** silently create a 832-side gated-write path — **see S-10** | small | yes | Vendoring AEF's compiler could be read as 832 claiming a gated-write path T-201 IW-2 assigned to AEF — mitigate by choosing the fail-loudly option unless the operator rules otherwise | `fw doctor` reports the dead routes, or the routes work. Either way the count of verbs that print help and then fail goes 4 → 0. Check: next `fw doctor`. |
| **F-A9** | Six working verbs are absent from `fw help` | `fw help` vs `bin/fw` case statement | **ADD (SURFACE)** | **C** | `02 §0,§5`: `fw help` matches **0 lines** for `designer` or `bpmn`. `03 §1`: of 100 top-level verbs, `bpmn`, `corpus`, `designer`, `arc`, `bvp`, `orchestrator` are **all** absent from help; `arc list`/`show` work fine | These are vendored-framework surfaces; changing vendored files risks loss on re-vendor (G-008 records exactly that class) | **HIGH** (measured, two legs) | Surface the verbs in help; upstream the change to AEF rather than patching the vendored copy only (G-008) | small | yes | A vendored-only fix is lost at the next re-vendor — that *is* G-008, so upstream it | An operator running `fw help` can discover `designer` and `bpmn`. Check: next `fw help`. |
| **F-A10** | Two in-repo docs contradict each other on `aef:endpoint` | `docs/designer/schema.md:239` vs `docs/standards/aef-bpmn-mapping-v1.md:42` (**frozen, normative**) | **ADD (REPAIR, docs)** + **SOVEREIGN** | — | `03 §5a`: schema.md says "what executes this step"; the frozen standard classes it **Presentational (diagram cosmetics)**, "never authoritative", and `:36-37` forbids the forward compile from reading it. `aef:endpoint` is the **only** non-geometry entry in that presentational list | Nothing validates endpoint content anywhere, which is *consistent* with the frozen reading — the tooling already behaves as if cosmetic (`03 §5a`) | **HIGH** (both documents measured in-tree) | Correct `schema.md:239` to match the frozen partition. **Do not touch Part I** — it is not agent-editable. The substantive carrier question is **S-2** | small (doc) | yes | Correcting the doc "settles" a question the operator has not ruled — mitigate by stating the frozen classification as the *current* normative answer and linking S-2 as open | Exactly one in-repo answer to "is `aef:endpoint` authoritative". Check: at the S-2 ruling. |
| **F-A11** | The fixture envelope carries a premise the operator already overturned | `handoff-ewcr-v1-designer-fixture.yaml:320-340` | **ADD (REPAIR)** | B + E (partial) | `01 §8`: `state: prepared`, `delivered: false`, unchanged **25 days**; its stated reason is a send-authorisation gate which `arc-0-exit-clauses.yaml:18-23` records as "invented, and the operator corrected it… The invented gate stalled Arc 0 for three sessions" | A *live* E reason also exists: rail @737 §5 self-embargoes `file_send` for seam bytes pending OBS-108. But AEF said at @1539 "`file_send` is fine", and R5 is still an open ask (`01 §10`, `04 §8.1`) | **HIGH** (measured file state + the operator's recorded correction) | Strike the overturned premise; record the *actual* current reason (the OBS-108 embargo) so the envelope stops misinforming its reader. Delivery itself waits on **F-I1** and **S-8** | small | yes | The envelope looks ready and someone sends over a channel whose integrity is unretested — mitigate by replacing, not removing, the reason | The envelope's non-delivery reason matches the actual live reason. Check: at the T-590/R5 ruling. |
| **F-A12** | The Arc-0 gate's verdict is written nowhere a reader passes | `tools/_t596-arc0-exit-gate.sh` | **ADD (SURFACE)** | **C + D** (not A, not E) | `01 §10` row 1: runs fine (exit 1, coherent verdict; self-test 13/13 exit 0) but callers exist only in 2 task files, 2 handovers, 3 fabric cards and itself; **not** called by `audit.sh`, **not** in `.context/cron-registry.yaml` (6 jobs), **not** in `tests/`; `fw help` shows nothing; no run log anywhere | Explicitly **against E**: the T-732 dossier (09-16) and T-736 (09-20) both treat its clauses as the live frame. It is wanted | **HIGH** (measured caller census + measured run) | Give the verdict a reader: emit to `.context/`, surface in the audit or on the arcs page. Do **not** make it a blocking gate — it is already correct, it is just unread | small | yes | Adding a noisy recurring red — mitigate by emitting a record, not a failure | The Arc-0 verdict appears somewhere a routine reader passes. Check: next audit/handover. |
| **F-A13** | T-739's Context is wrong about its own defect | T-739, commit `13f2aec9`, filed 2026-09-20 | **ADD (REPAIR)** | A | `06 §3`: T-739 says T-155 "has never appeared on the surface that tells the operator what needs deciding" — measured **false** of Watchtower: `/inception` contains T-155 ×3, `/inception/T-155` → **200** with a decide UI (DEFER ×13, NO-GO ×11) | The defect is **real but narrower**: it holds for the `fw review-queue` CLI decisions queue | **HIGH** (live HTTP probe, same session that filed it) | Correct T-739's Context to name the CLI queue specifically, **before** it is worked | small | yes | Nothing — it narrows a scope, it does not remove a defect | T-739 scopes to the CLI. Check: before T-739's first owning commit. |
| **F-A14** | Nine `aef:endpoint` values resolve to nothing | `review-emission`, `session-handover`, `error-escalation-ladder` ×3, `task-gate`, `upgrade-process` ×2, `verification-gate` | **ADD (REPAIR, corpus)** | A | `03 §5c`: 9 of 107 distinct values resolve NO. Two are wrong commands — `fw review` → *Unknown command: review*, exit 1; `git agent commit …` is not a command (real form `fw git commit`). Seven are free prose | The frozen standard makes these **cosmetic**, so nothing breaks today; 98 of 107 do resolve, and all four watchtower routes resolve | **HIGH** (measured resolution census) | Fix the two that are wrong commands; leave prose as prose. Cheap accuracy in a corpus the counterparty reads | small | yes | Editing the rendered corpus by hand is forbidden (`rendered/README.md`) **and** regen is forbidden (T-300) — so this must go through the `.workflow.yaml` source or wait on F-I5 | 2 of 9 NO values become YES. Check: whenever the corpus next legitimately moves. |
| **F-A15** | No realization data for either arc | `.context/audits/bvp-realization.jsonl` absent | **ADD (NEW, instrument)** | **D** | `05 §7`: file absent; `find -name "*realization*"` → no output. Both arcs `bvp_scores: {}`, `demo_evidence: null`, `closed_at: null`. **0 of 739** tasks carry a confirmed score; arc-002 has **0 of 27** members ranked at all | The estimator works (84 ranked rows, exit 0); this is missing *outcome* data, not missing tooling | **HIGH** (measured absence, two sections) | Start a realization log. **Scores and weights are sovereign — see S-9.** The log itself is a mechanical artifact and agent-proposable | small–med | yes | Measuring realization on unconfirmed proposals reifies estimator noise — mitigate by logging only against confirmed scores | "Did this arc deliver?" becomes answerable for the first task that closes after the change. Check: next arc close. |
| **F-A16** | 255 Verification-block probe citations with zero evidence any still pass | `tools/_t*` (278 probes), `.tasks/**/## Verification` | **ADD (NEW, instrument)** | **D** | `05 §5`: 255 of 278 (91.7%) cited in a Verification block; `05 §9 G10`: "Reference ≠ working… no verification command was executed"; `CTL-N: T-N verification re-run: N command(s) failing` already appears in **3** audit records | The P-011 gate *does* run these at completion time, so they were green once, per task | **MEDIUM** (measured citation census; the staleness is inferred from 3 audit records) | Record a last-successful-run stamp per probe. This is the same "detector with no reader" class `04 §5.4` counts **≥5** times | small–med | yes | Adds a maintenance surface nobody reads — which would be the sixth instance of the very pattern; mitigate by surfacing it where F-A12 lands | Probe staleness becomes queryable. Check: next audit. |
| **F-A17** | T-209 is held open by one human ruling, with the evidence already in hand | `.tasks/active/T-209-…md`, Human AC 0/1 | **ADD (SURFACE)** | **E** (positive, recorded) | `02 §4`: the test T-209 proposed was **recommended against**; the coverage exists and **passes today** — G2 ran `test_promote_contract.py` and `test_two_lane_joint_contract.py`, rc 0 each. Third suite `test_typed_event_fixture_contract.py` also rc 0 | The task is `started-work` with all 3 Agent ACs ticked — it is also an instance of the CTL-029 class (4020 audit occurrences) | **HIGH** (two suites run green in this snapshot) | Hand the operator a one-page decision packet with the two rc-0 outputs. **See S-7** — I recommend *decline*, per the task's own re-measurement | small | yes | Declining a peer proposal that has since changed — mitigate by quoting the peer's offset-78 proposal verbatim alongside | T-209's Human AC becomes actionable. Check: at the next review-queue drain. |
| **F-A18** | `fw designer --help` omits two working subcommands | `designer.sh:332-336` | **ADD (SURFACE)** | **C** | `02 §5`: dispatch case carries `status`, `path`, `sync`, `url`, `draft`; `--help` advertises only the first three | `draft` is also broken here (F-A8), so documenting it without fixing it advertises a dead path | **HIGH** (measured) | Document `url`; document `draft` **only after** F-A8 | small | yes | Advertising a broken verb — hence the ordering | `fw designer --help` lists every working subcommand. Check: next help run. |
| **F-A19** | `fw bus` is documented as the dispatch protocol and has never been used | CLAUDE.md §Result Ledger; `.context/bus/` | **ADD (SURFACE)** | **B + C** | `04 §8.4`: `ls .context/bus/` → **directory does not exist**; zero channels/blobs/manifests in a **739-task** project; **zero** references in `.tasks/`, `docs/`, `.context/project/` | It is vendored framework surface with an unobservable external consumer; and the convention it formalises ("write to disk, return path + summary") *is* in active use informally | **MEDIUM** (measured absence; single source) | Either use it on the next multi-agent dispatch or mark it optional in CLAUDE.md. **Not a DELETE** — check (4) fails (CLAUDE.md references it) and check (5) cannot be established | small | yes | Removing a protocol the counterparty's framework relies on — which is exactly why this is not a DELETE | `.context/bus/` exists with ≥1 channel, or CLAUDE.md stops presenting it as the default. Check: next multi-agent dispatch. |
| **F-A20** | No semantic carrier exists for the node→action binding | frozen standard Part II (provisional annex) | **ADD (NEW)** + **SOVEREIGN** | — | `03 §2b`: **every** `§6.2.1` field has carrier "none" in the frozen surface; `03 §5a`: the only candidate attribute is forbidden to the compiler; `03 §2d`: gateway conditions are labels not predicates; `tier` carried 77× and enforced 0× | `01 §7`: Part II items are **already** "pending their own rulings" — a positive recorded reason they sit still. R1–R5b have **no answer recorded anywhere in this tree** | **HIGH** (three independent in-repo sources agree) | **Ask, do not build.** File it as a new R-series ratification request in the Part II annex. **See S-2** | needs its own design | n/a (a question) | Designing a carrier before the ruling manufactures a standard fork — which is precisely why this is an ask | An R-series item for the action carrier exists and is routed. Check: next rail post to AEF. |
| **F-R1** | Arc membership has two sources of truth that disagree | `.tasks/**` frontmatter `arc_id:` vs legacy `tags: [arc:<slug>]` | **REFACTOR** | — | `05 §0`: `arc_id:` → **15 / 25**; `fw arc show` (unions both) → **32 / 27**; the audit uses the union. 17 arc-001 members exist only via the legacy tag. **T-623's two fields name different arcs.** T-611/T-620 are dual members, double-counted | `fw arc --help` documents the union as deliberate back-compat: "legacy tags already on a task are left in place and readers still union both forms" | **HIGH** (measured both ways, one leg, corroborated by the audit record) | **Cost in data:** the audit's `26/32 (0.8125)` arc-001 ratio has not moved across 8 records, T-728 exists **solely** to record it, and `fw arc close` consumes it. Backfill `arc_id:` from legacy tags (**add only, never remove a member**); drop T-623's stale arc-001 tag — its content is EWCR. **Behaviour preserved:** the union reader must return the same set afterwards — assert that first | small | yes (git) | A membership change silently moves a completion ratio that feeds a sovereign arc-close decision — **see S-4**; do not do this while an arc close is pending without saying so | `arc_id:` count == `fw arc show` count for both arcs; the audit ratio is reader-independent. Check: first audit after the backfill. |
| **F-R2** | The review queue is the chain's throughput ceiling, and it is re-paid every session | `.tasks/active/` (38 parked); `.context/handovers/` (641) | **REFACTOR** | — | **Cost in data:** `01 §4` 0 of 16 seam Human ACs ticked, oldest 25d; `05 §2` all 12 parked seam tasks have **zero** open Agent ACs; `05 §8` D2 is the **only FAIL** in the latest audit — 12 tasks >30d, T-093 at 77d, 23 more >14d; `04 §5.3` **601 of 641** handovers reprint `partial-complete` **and** `Human AC`; `04 §5.2` T-184 reprinted in **509** handovers over 71 days, T-590's ratification in **100** consecutive handovers | The parking is **correct behaviour** — Human ACs are real verification and CLAUDE.md forbids the agent ticking them. T-681's GO warns against decomposing counterparty-blocked work: it "manufactures a backlog that measures as progress and cannot move". Several items are genuinely counterparty-blocked | **HIGH** (four independent measured sources) | **Do not touch the gate.** Batch the 12 parked seam tasks into one decision packet in the T-732 dossier format (which demonstrably works — it even corrected its own parent task). **See S-6.** No `--force`, ever | medium | yes | Batching invites rubber-stamping of ACs that deserve individual judgement — mitigate by using the `[RUBBER-STAMP]`/`[REVIEW]` split and keeping `[REVIEW]` items individually argued | Parked seam tasks fall below 12; D2's >30d count falls. Check: at the next audit after the packet is ruled on. |
| **F-I1** | Is OBS-108 still true? | `file_send` / TermLink file transfer | **INVESTIGATE** (+ ADD REPAIR if confirmed) | A vs E **unresolved** | `04 §8.1`: **A** — T-318 measured it re-serving "the SAME earliest historical transfer on every replay… while printing 'SHA-256 verified' and exiting 0". **E** — we self-embargoed it at @737 and again at T-736. **D** — "**zero** re-tests" in 7 citations, and the hub has had a restore since. **Against A** — AEF offered the channel at @1539 without caveat | — | **MEDIUM** (one measured source, months old, contradicted by a recent counterparty offer) | **Data needed:** one controlled re-test — send a known payload, verify the received bytes' sha256 against the sent bytes. Until then, do not delete the embargo and do not ignore it. **See S-8** | small | n/a | Sending over a broken channel delivers the wrong bytes under a green checksum — hence test with a disposable payload first | The embargo is either re-justified or lifted on evidence <1 week old. Check: at the S-8 ruling. |
| **F-I2** | What does AEF have pinned *right now*? | `policy/designer-pin.yaml` (theirs) | **INVESTIGATE** | D | `01 §11.1`: only a vendored copy is readable here (T-559); the probe says it "can only UNDER-report adoption lag" | — | **HIGH** (the gap is measured; the answer is unobtainable here) | **Data needed:** a rail read-back of their pin's version + sha256. One question. Closes this gap, gives F-A2 a truth to check against, and produces the first AEF read-back on record | small | n/a | None | We know the peer's live pin, or we know they did not answer — both are progress. Check: next rail exchange. |
| **F-I3** | Who produced @734, @741, @777, @786? | `agent-chat-arc` | **INVESTIGATE** | — | `04 §7.1`: their cited `PD-003`/`T-038`/`T-040`/`T-048` **do not resolve against this repo** — our PD-003 is 2026-07-03/T-037 about an M1 spec; our T-040 is the YAML→BPMN bridge; our T-048 is harvest mapping. `04 §1.3`: `sender_id` cannot separate producers. G4 states plainly: "I cannot rule out others" | These posts have been treated as AEF's throughout, including in the H3 correlation reasoning | **MEDIUM** (four falsified citations, one leg, structural attribution gap) | **Data needed:** ask the counterparty to confirm authorship of those four offsets by naming their own task ids in a form that resolves. **This is upstream of H3** — if @777's PD-003 is a third party's, the correlation values it offers must not be adopted | small | n/a | Adopting a third party's correlation values as the counterparty's would corrupt the one field Phase 4 completion is defined on | The producer of ≥1 of the four is established, or recorded as unestablishable. Check: next rail exchange. |
| **F-I4** | Should 277 probe cards sit in the Arc-0 clause-1 fabric denominator? | `.fabric/components/` (378 cards) | **INVESTIGATE** | D | `05 §5`: **277 of 378** cards are `tools/_t*` probes. `01 §1`: clause 1 turns on "enriched and validated"; AEF's RED cited 749 of 1134 cards outside any watch pattern; T-623 rebutted with "**3 of 69 not 749 of 1134**". `04 §5.4`: "a green measured over a narrow denominator" recurs **≥5** times | `05 §8`: edgeless cards are **worsening**, 4/16 → 77/378 — so the denominator question is live on our side too | **MEDIUM** (measured composition; the scope question itself is unruled) | **Data needed:** a ruling on whether one-off task probes are in-scope components. This decides whether our fabric numbers mean what both sides think. **Register the question — do not change a watch pattern to improve a number** | small (the question) | n/a | Scoping probes out to make a fence go green would be exactly the gaming this review forbids — so propose the question, never the rescope | The clause-1 denominator is defined rather than assumed. Check: at the T-671/T-732 ruling. |
| **F-I5** | Is the rendered corpus stale? | `examples/aef-processes/rendered/` | **INVESTIGATE** | D | `01 §8`: mtime says 10 of 24 `.bpmn` are older than their YAML; git says `rendered/` last moved 2026-07-29 and a `.workflow.yaml` moved 2026-07-31. `05 §4`: `examples/aef-processes/` has had **no commit in 51 days** | The README's regen command is the act T-300 proved destructive (`+2839/-3904`, reverted); hand-editing is forbidden. **Both stated remedies are closed** | **LOW** (two inferred signals that conflict; nothing measured) | **Data needed:** `bake-clean-layout.py --check` (read-only mode), not a regen. Also resolve the dangling "G-012 = regen forbidden" citation — `concerns.yaml` G-012 is a *different* gap (`01 §8`) | small | n/a | Regenerating to "fix" staleness repeats T-300 — check only, never regen | Corpus freshness becomes a measured fact; the regen rule gets a correct gap id. Check: before the corpus next moves. |
| **F-I6** | Does AEF's `/api/overlay` actually drive the annotation seam? | postMessage `aef:ready` / `aef:annotate` | **INVESTIGATE** | D | `01 §5`, `02 §6`: the contract exists on both sides on paper; `dist/MANIFEST.yaml` declares `capabilities: {annotation_seam: 1}`; our side **passes** (`test_t258_annotation_seam.py` rc 0 — handshake, badge intake, spoof rejection); a live AEF payload fixture from 2026-07-27 exists. **No live handshake observed** | This is the **one reverse-flowing artifact that shipped** — the strongest thing in the whole reverse direction | **MEDIUM** (our half measured green; the far half unobservable) | **Data needed:** a rail read-back, or AEF exercising the seam against a current build. Note they can only exercise **0.8.0** until the pin moves — so F-A2/F-I2 are upstream of this | small | n/a | None | A live handshake is observed or recorded as unobtainable. Check: after the pin moves. |
| **F-I7** | Does the peer read `framework:pickup`? | TermLink topic, 132 messages | **INVESTIGATE** | A/D unresolved | `04 §8.3`: @873 — "prior DM/**pickup** requests targeted the wrong service identity and must not count as AEF delivery". Sender/label composition **unmeasured** (G4-7) | G-020 treats pickup content as proposals needing inception scoping, so the route is deliberately non-actionable on arrival | **LOW** (one rail claim, no census) | **Data needed:** a `channel_state` census of the 132 messages by sender and `from_project` | small | n/a | None | The route is known-live or known-dead. Check: next transport review. |
| **F-I8** | The T-559 identifier collision | OBS-300 (pending, urgent) | **INVESTIGATE** | — | `04 §4`: `fw work-on` minted a **local** T-559 while T-559 is 999-AEF's task id "cited unqualified **154 times** in OUR OWN corpus as 'the T-559 boundary'" | No incident has yet been traced to the collision | **MEDIUM** (measured count, one filing, 31 days open) | **Data needed:** whether any of the 154 citations has already been mis-resolved. Same class as F-I3: **unqualified cross-project task ids** | small | n/a | A future citation resolves to the wrong task and a boundary rule is read as a local ticket | The 154 citations are qualified, or the risk is ruled acceptable. Check: next seam doc edit. |
| **F-I9** | Is `scripts/release-designer.sh` deterministic? | release path | **INVESTIGATE** | D | `01 §11.3`: claimed at protocol `:55-56` ("byte-identical artifact + checksum on every run"), **never re-run**; would need a rebuild into a temp dir + sha256 compare | src↔release sha256 are identical today, which is consistent with determinism but does not prove it | **LOW** (claimed only) | **Data needed:** rebuild 0.12.0 into a temp dir, compare sha256. This is also F-A5's verification step — do them together | small | n/a | None (temp-dir build) | The determinism claim becomes measured. Check: with F-A5. |

---

## 7. KEEP list (names only)

Earning their keep against the yardstick. No action proposed for these.

`src/aef-workflow-designer.html` · `buildBpmnXml` / `parseBpmnXml` (the single serializer/deserializer
pair) · the `aef:` extension vocabulary and `aef:workflowMeta` · `tools/yaml-to-bpmn.py` ·
`tools/validate-workflow.py` (incl. `_check_iw9_authority` lane-authority enforcement) ·
`tools/check-lane-bands.py` · `tools/bpmn-cli.py` · `tools/gallery-serve.py` · `tools/census-dead-legs.py` ·
the 24 Arc-0 contract and round-trip suites (all 28 Arc-0 set members present) ·
`tests/test_roundtrip_serialization.py` (36/36 proven, controls held) ·
`tests/test_bridge_seam_roundtrip.py` (27/27 drop detection) · `tests/test_promote_contract.py` ·
`tests/test_two_lane_joint_contract.py` · `tests/test_typed_event_fixture_contract.py` ·
`tests/test_designer_export_contract.py` · the annotation seam v0 (`src:2655-2740` +
`tests/test_t258_annotation_seam.py` + `tests/fixtures/aef-overlay/`) ·
`tools/_t596-arc0-exit-gate.sh` + `_t596_arc0_check.py` + `_t597_arc0_clauses.py` ·
`tools/_t682/_t683/_t684-*` (the Arc-2 isolation negative proof) · `tools/_t671-arc0-*` (fabric fence) ·
the **278-probe population** in `tools/` and its 277 fabric cards ·
`docs/standards/aef-bpmn-mapping-v1.md` (frozen Part I) · `docs/standards/aef-bpmn-forward-compile-v1.md` ·
`docs/aef-designer-integration-protocol.md` · `docs/research/executable-workflow/operator-decisions.yaml`
(the H-register) · `arc-0-exit-clauses.yaml` (the register itself; only `:45-78` is repaired) ·
`docs/research/executable-workflow/cannot-represent-yet.md` · `aef-transport-verdict.md` ·
`docs/reports/T-732-h-register-dossier.md` · `architecture-c9070637.md` ·
`examples/aef-processes/rendered/` (24-map seam corpus) · the pilot fixture in `fixtures/` ·
`dist/` (all 16 artifacts) + `dist/MANIFEST.yaml` + the 15 `designer-v*` tags ·
`agent-chat-arc` as the collaboration rail · T-184 (correctly parked, dated revisit 2026-10-01) ·
**the T-559 boundary discipline itself.**

Two KEEPs deserve their reason stated, because both are the traps this review was warned about:

- **The probe population.** `05 §5` measures **0** probes referenced nowhere in the repo outside
  `tools/` itself. The "9 with no `.tasks/` reference" includes `_t596_arc0_check.py` and
  `_t597_arc0_clauses.py` — the live Arc-0 gate's own modules, missed only because they use `_`
  where 276 others use `-`; and `_t258-…-cdp.mjs` / `_t259-…-cdp.mjs` are invoked by the test files
  G2 ran green today. G5's own caveat G9 says the figure is an upper bound. **DELETE check (4) fails
  for every probe.** And the converse trap is refused too: I do **not** call them valuable merely
  because 255 are cited — nobody has measured whether they still pass (G10), which is F-A16.
- **`dist/` history and `build/gallery/`.** `dist/` holds 16 artifacts and the external consumer is
  pinned to **0.8.0 right now** — deleting history would break the live consumer (check 5 fails
  hard). `build/gallery/designer.html` is 0.10.0 and drifted, and `06 §4` records the standing
  constraint that T-102/T-105 are "not to be unblocked by rebuilding `build/gallery/`". Leave it.

---

## 8. INVESTIGATE list + the data needed

| ID | Question | Data that would decide it | Who can get it |
|---|---|---|---|
| F-I1 | Is the `file_send` defect (OBS-108) still live? | One controlled send of a disposable payload; compare received sha256 to sent sha256 | Agent, on operator authorisation (S-8) |
| F-I2 | What is AEF's current `designer-pin.yaml`? | Rail read-back of version + sha256 | Counterparty only |
| F-I3 | Who authored @734/@741/@777/@786? | Counterparty confirmation naming task ids that resolve | Counterparty only |
| F-I4 | Are one-off probe cards in the clause-1 fabric denominator? | An operator/joint ruling on component scope | Operator (+ counterparty) |
| F-I5 | Is the rendered corpus stale? | `bake-clean-layout.py --check` (read-only); plus the correct gap id for "regen forbidden" | Agent |
| F-I6 | Does AEF's `/api/overlay` drive the annotation seam live? | AEF-side probe or rail read-back — **after** the pin moves | Counterparty |
| F-I7 | Does AEF read `framework:pickup`? | `channel_state` census of 132 messages by sender/label | Agent |
| F-I8 | Has the T-559 id collision already mis-resolved a citation? | Audit of the 154 unqualified citations | Agent |
| F-I9 | Is `release-designer.sh` deterministic? | Temp-dir rebuild of 0.12.0 + sha256 compare | Agent |

Two further items are **INVESTIGATE by construction** and cannot be closed by more reading:
the absence of any out-of-band observer of the seam, and the absence of reader confirmation
(`04 §2.5`, §9 below).

---

## 9. Data gaps that capped confidence — and what closing them unlocks

Each of these is an ADD candidate in its own right.

| # | Gap | What it capped | What closing it unlocks |
|---|---|---|---|
| **DG-1** | **No out-of-band observer of the 832↔AEF seam.** TermLink is both medium and sole record (`00`, `04 §2.5`, `06 §7.1`) | Every claim about "what came back" is at best *observed-on-the-medium-being-observed*. Caps the entire handoff axis at MEDIUM | An independent receipt channel would turn counterparty claims from `claimed` into `observed`, and would have caught the log replacement that "came from an agent happening to look, not from an instrument" |
| **DG-2** | **`sender_id` cannot attribute any post to AEF** — 3 sender_ids, 18 producer labels, 0 AEF posts non-ours (`04 §1.3`); zero AEF read receipts (`04 §2.5`) | F-I3 is unresolvable from here; four cited peer decisions are falsified against our registers and "I cannot rule out others" | Per-project signing keys would make the whole counterparty record citable. This is G-029, `watching`, 42 days |
| **DG-3** | **Rail timestamps are unusable** (bulk-replay; 4 roots identical to the millisecond) (`04 §2.4`) | No event on the rail can be *dated* from the rail; all dates here come from repo records | Ordering and latency on the seam become measurable |
| **DG-4** | **The far side is unobservable** (T-559) (`06 §7.2`) | Their pin, their compiler, their `fw designer sync`, their attestation artifact — all `claimed`, never `measured` | Nothing here proposes routing around T-559. What closes it is a *read-back protocol*, not a boundary breach |
| **DG-5** | **No realization data; zero confirmed BVP scores** (`05 §6,§7`) | "Did either arc deliver?" is unanswerable. arc-002 is **0 of 27** ranked | The value half of the ledger gets a ratified input for the first time (F-A15, S-9) |
| **DG-6** | **No CI; bridge suite non-deterministic** (`02 §7`, OBS-250) | Every "green" in this review is a point-in-time local measurement, never a continuously enforced gate. This caps *every* test-based row at "green when run" | Continuous evidence that the seam is intact — which is what OBS-256 has been asking for, urgent, for 36 days (F-A6) |
| **DG-7** | `fw audit` not run (OBS-358 hang) (`04 §9`, `05 §9`) | The live compliance verdict is unmeasured; §8 audit facts are saved records only | A live audit. **The hang itself is an uninvestigated defect in the primary compliance instrument** — worth a task on its own |
| **DG-8** | `tests/run-bridge-tests.sh` (94 legs) not run — its legs move files under `.context/audits/` (`02 §9.1`) | The suite's current state is unknown; last third-party report 69/0 | Fixed by F-A6 step 1: a side-effect-free suite is runnable by a reviewer |
| **DG-9** | Three documents cited by the arcs were not read by any gatherer: `docs/reports/T-201-writeout-mode-inception.md`, `T-175-child-decomposition.md`, `docs/designer/architecture.md` (`02 §9`) | T-201's G1–G6 guardrail table is cited but unchecked; arc-001's own decomposition is unread | The forward-path design intent could be checked against what shipped |
| **DG-10** | Several "last change" dates are filesystem mtimes, not commit dates — the repo has a bulk Aug-2 mtime floor (`02 §9.8`) | Any staleness argument from mtime is weak; F-I5 rests on exactly that | — |

---

## 10. Contradictions

Recorded as found. **These are the rows where the project is wrong about itself**, and I classify
them deliberately rather than as ordinary bugs: each is an artifact that misinforms a reader who is
about to decide something. Their cost is not runtime failure — it is a decision made on a false
record.

| # | Contradiction | Sources | Which side is right | Class |
|---|---|---|---|---|
| **C-1** | Two in-repo docs disagree on whether `aef:endpoint` is authoritative | `schema.md:239` vs frozen `aef-bpmn-mapping-v1.md:42` (`03 §5a`) | **The frozen standard.** Part I is normative and is not agent-editable. This single question decides whether stage 3 is buildable as designed — and the answer is **no** | F-A10 + **S-2** |
| **C-2** | The seam register asserts every cited rail offset is dangling; it is not, and its own author retracted it | `arc-0-exit-clauses.yaml:45-78` vs `01 §2`, `04 §2.3`, OBS-354, rail @1536 | **The live re-measurement.** Refuted twice independently. The register is what the counterparty reads, and commit `116cc3b4` edited it today without fixing it | F-A4 + **S-3** |
| **C-3** | The audit prints PASS on release lag over a four-release, 53-day-stale pin | `.context/audits/cron/2026-09-20-2130.yaml:59` vs `01 §6`, `06 §4` | **The measurement.** The check is not lying about a different thing — it keys on the age of the newest release and cannot see this | F-A2 |
| **C-4** | The counterparty's newest answer is recorded and invisible to the only mechanical reader | register `:204-252` vs `_t597_arc0_clauses.py` (0 hits) (`01 §1,§10`) | Both are "right" — which is the defect: the record and the instrument have diverged | F-A3 |
| **C-5** | Arc membership: 15/25 vs 32/27; T-623's `arc_id:` and `tags:` name **different arcs** | `05 §0` | Neither reader is wrong; the data is | F-R1 |
| **C-6** | The envelope's stated reason for non-delivery is a gate the operator already ruled never existed | `handoff-…-fixture.yaml:330-340` vs `arc-0-exit-clauses.yaml:18-23` (`01 §8`) | **The operator.** "That was invented… The invented gate stalled Arc 0 for three sessions" | F-A11 |
| **C-7** | T-739 says no operator surface shows T-155; `/inception/T-155` returns **200** with a decide UI | `06 §3` | **The live probe.** The defect is real but is a CLI defect | F-A13 |
| **C-8** | The rendered corpus README prescribes a regen that T-300 proved destructive and that standing rule forbids | `rendered/README.md:1-21` vs `.context/episodic/T-300.yaml` (`01 §8`) | **T-300.** Note the "G-012" citation for "regen forbidden" resolves to a *different* gap — the rule's own id is wrong | F-I5 |
| **C-9** | The handover prints "3 urgent observations"; there are **36** | `04 §6.1`, OBS-301 | **The measurement.** OBS-301: the count "is a CONSTANT and has never once been a measurement" | Out of scope here; flagged |
| **C-10** | README's "next planned slice: schema validation tooling" is overtaken by both arcs | `00 §Contradiction flagged at Phase 1` | **The arcs.** arc-002 is at contract-seam ratification | Docs staleness; low priority |
| **C-11** | Purpose vs reality: arc-001's headline mechanic requires "the AEF agent turns it into an approved governed task graph" — and **there is no live end-to-end run from either side** | `02 §3`; `03 §0` | Reality. The arc's ratio says 26/32; its *mechanic* has never fired | **S-4** |
| **C-12** | Our standing refusal of `file_send` vs the counterparty offering it without caveat | @737 §5, T-736:78 vs @1539 "`file_send` is fine" (`04 §8.1`) | Undecided — that is F-I1 / **S-8** | F-I1 |

---

## 11. Not reviewed

- **arc-003 (audit remediation)** — out of scope per the yardstick, though its 31 tasks (15 of them
  CTL-029 remediations, incl. T-722 and T-728 which exist *solely* to record arc-002 and arc-001
  stall states) are cited as **cost booked against** the in-scope stall (`05 §8`).
- **Everything inside 999-AEF** — T-559 boundary. No gatherer crossed it and neither did I. Whether
  their checkout carries `bpmn_to_tasks.py`, whether `fw designer sync` runs there, whether the
  clause-1 attestation artifact exists — all unreviewed by construction.
- **`tests/run-bridge-tests.sh`'s current pass state** (DG-8); **`scripts/release-designer.sh`
  determinism** (F-I9); **`bake-clean-layout.py`/`gen-rendered-thumbs.mjs`** (write into a
  prohibited set).
- **Three cited documents nobody read** (DG-9).
- **Live `fw audit`** (DG-7) — and the hang itself is unreviewed.
- **The 20 acceptance scenarios** in `architecture-c9070637.md:909-930` — the de-facto refusal
  specification. Statused DESIGNED-ONLY; not evaluated as a suite.
- **Product UI/UX quality, performance, and security beyond what G-048/G-049 report.** Note two
  `watching` high-severity gaps sit unreviewed here: `/api/save` has no authentication and honours
  a client-supplied `promote` flag, "so an agent can ratify a document the operator alone may
  ratify" (G-049), and its write path has no `_within_repo` containment (G-048). **These are
  in-scope-adjacent and I am flagging rather than judging them** — they were gathered as context,
  not as a security review, and they deserve their own pass.
- **The third party `0503-codex-cli-playground`** except where it collides with the seam (F-I3, and
  OBS-283: they modified our vendored `check-project-boundary.sh` and their operator approved it).
- **Orchestrator v1** (`.context/project/workflows/` does not exist) and `fw bvp`'s mutating verbs.

---

## 12. Sovereign questions

Weights, ratified workflows, gates, authority and release decisions are not mine. Each item below is
a **question with a recommendation**, never a proposal to act.

**S-1 — H3: assign the two correlations.** *(authority / ratified precondition)*
`source-manifest.yaml:19-26` says no peer handoff may be opened until they are assigned, because
Phase 4 completion is *defined* as read-back on the same correlation. A handoff has been open on an
unassigned value for **24 days**, and the counterparty said so themselves at @1539. Three values are
in circulation; one was minted by an agent as a thread name and "adopted by the counterparty because
we used it".
**Recommendation: assign our own two values now and publish them on the rail. Do not adopt @777's
`PD-003` values** — that citation does not resolve against this repo (F-I3). This is the cheapest
act in the entire review per unit of chain unblocked.

**S-2 — Is `aef:endpoint` authoritative, or does the execution stage need a new carrier?**
*(frozen standard / counterparty ratification)*
The frozen Part I classes it cosmetic and forbids the compiler from reading it; `schema.md:239` says
it is "what executes this step". This one question decides whether stage 3 is buildable as designed.
**Recommendation: keep `aef:endpoint` cosmetic — do not reclassify it.** Its 107 distinct values are
the lowest-quality data in the corpus: 9 resolve to nothing, **48 of 63 script paths resolve from no
anchor**, `AGENT.md` is ambiguous across 15 files, and T-298 already recorded these line pointers
drifting. Promoting that to a governance semantic would freeze free text into the contract. Instead
open a new R-series ask to AEF for a **typed `action` carrier in the Part II provisional annex**,
where new semantics belong and where items already sit "pending their own rulings".

**S-3 — Authorise the correction of `arc-0-exit-clauses.yaml:45-78`?** *(a file at operator review)*
The block asserts every cited rail offset is dangling. Two independent re-measurements refute it, the
author retracted it, and the counterparty reads this file. The agent correctly declined to edit it
unilaterally because it is under your review.
**Recommendation: yes — supersede in place, keep the original visible, inline the OBS-354
retraction.** A register that is false on its face is worse than a register with a visible
correction, and this one is in the packet you are about to rule from.

**S-4 — What closes arc-001?** *(release/arc-close decision)*
The audit's mitigation says "capture wire-evidence of the arc's headline_mechanic firing". That
mechanic's second half is AEF turning the file into governed work — which **cannot be witnessed from
this side**, and for which there is no live end-to-end run from either side.
**Recommendation: do not close arc-001 on the 26/32 ratio, and do not close it on a 832-half demo.
Define the demo evidence as joint** — our manifest projection (F-A1) plus AEF's read-back of its
hash. Note this interacts with F-R1: a membership backfill moves the ratio, so if you intend to rule
on arc close, rule first or backfill first, not both silently.

**S-5 — Three `[REVIEW]` Human ACs were found ticked on disk with no operator POST.** *(authority)*
If the tick channel can be written without you, the Human-AC gate's authority is in question — and
that gate is what 38 parked tasks are waiting on.
**Recommendation: treat the three on T-597 and T-608 as unticked pending your confirmation, and
authorise instrumenting the tick channel.** I am not proposing to weaken the gate; I am reporting
that its audit trail may not exist.

**S-6 — How do you want the twelve parked seam tasks presented?** *(gate / throughput)*
Zero of 16 seam Human ACs are ticked; all twelve parked tasks have **zero** open Agent ACs; D2 is the
only FAIL in the latest audit.
**Recommendation: one batched decision packet in the T-732 dossier format, with `[RUBBER-STAMP]` and
`[REVIEW]` separated and every `[REVIEW]` argued individually. No `--force`, on anything.** Several
of these are genuinely counterparty-blocked and should be *recorded as blocked*, not closed.

**S-7 — T-209: decline the peer's offset-78 producer-contract proposal?** *(a counterparty-facing
ruling)* The test it proposed was recommended against; the coverage exists under two other names and
**both passed in this snapshot** (rc 0 each), as did the third suite.
**Recommendation: decline, citing the two rc-0 runs.** Evidence is in hand; this is a one-minute
ruling that has been open since 2026-07-19.

**S-8 — Re-open `file_send` for seam bytes?** *(a standing self-embargo)*
Our refusal rests on one months-old measurement never re-tested, on a channel that has since been
restored, and the counterparty has since offered the channel without caveat.
**Recommendation: re-measure first (F-I1), then rule.** Do not lift the embargo on the counterparty's
offer alone, and do not keep it on a stale measurement alone.

**S-9 — BVP: zero confirmed scores in 739 tasks; both arcs unscored and arc-002 unranked.**
*(value-driver weights and score confirmation are sovereign)*
**Recommendation: confirm scores for the twelve parked seam tasks only** — a bounded set that would
make the in-scope arcs visible in the ranking for the first time — **and authorise a realization log**
(F-A15). I propose no change to any weight. Note the ranking structurally excludes `work-completed`
tasks, so confirming scores will not by itself surface them.

**S-10 — Should `.agentic-framework/tools/` be in the vendored payload?** *(boundary / authority)*
Vendoring it would give 832 a local BPMN→tasks compile path. T-201's IW-2 ruling assigns content
authority to 832 and **gated-write to AEF**.
**Recommendation: do not vendor it to gain a compile path. Make the four dead routes fail loudly and
report in `fw doctor` instead** (F-A8). If you want the compiler locally for *diagnosis*, say so
explicitly, because the boundary reading changes.

**S-11 — Release immutability (G-007), `watching` and high for 66 days.**
Re-running the release script at an already-released VERSION silently mutates bytes the consumer has
pinned. Our own words to the counterparty: "a release is a sovereignty promise".
**Recommendation: authorise the guard** (F-A5). It refuses a divergent rebuild and permits an
identical one. It strengthens the release gate and weakens nothing.

---

*Judgement only. Nothing was executed, created, updated, committed or sent. One file was written:
this one.*
