# Evidence — the operator surface (GATHERER, coordinator leg)

Domain not delegated to G1–G5: what the **operator** can actually see and do about the
workflow → program → execution chain. Facts only, no classification.

Snapshot: 2026-09-20, Watchtower live at `http://192.168.10.107:3013`
(`.context/working/watchtower.url`). All probes are read-only HTTP GETs.

## 1. Operator route inventory

Enumerated from `.agentic-framework/web/blueprints/*.py` (`@*.route(...)`), then probed live.

| Route | HTTP | Kind | Note |
|---|---|---|---|
| `/` | 200 | dashboard | structure |
| `/approvals` | 200 | decision | 143 distinct task ids present in body |
| `/inception` | 200 | decision | lists 78 inception task ids |
| `/inception/<id>` | 200 | decision | **carries a decide UI** — see §3 |
| `/inception/<id>/decide` | route exists | decision | `blueprints/inception.py` |
| `/review/<task_id>` | route exists | decision | `/review` bare = 404 |
| `/arcs`, `/arcs/<id>`, `/arcs/<id>/close`, `/arcs/<id>/review` | 200 | decision | |
| `/bvp`, `/costs`, `/decisions`, `/discoveries`, `/gaps` | 200 | evidence | |
| `/orchestrator`, `/orchestrator/parallel` | 200 | dispatch | |
| `/designer` | 200 | **authoring** | title: "Workflow Designer — Corpus" |
| `/designer/app` | 200 | **authoring** | serves the editor; see §4 |
| `/designer/ghosts` | 200 | authoring | |
| `/designer/draft/new` | 405 | authoring | POST-only |
| `/designer/overlay` | 404 | authoring | route exists in code; needs `map_id` |

## 2. There is no execution surface — measured, not inferred

| Probed route | HTTP |
|---|---|
| `/runs` | **404** |
| `/traces` | **404** |
| `/execute` | **404** |
| `/run` | **404** |
| `/workflow` | **404** |
| `/workflows` | **404** |
| `/workflow/run` | **404** |
| `/ewcr` | **404** |
| `/contracts` | **404** |

Across ~60 enumerated operator routes, **zero** concern executing an authored workflow or
displaying a run. The operator surface covers *authoring* (`/designer*`) and *governing*
(`/approvals`, `/inception`, `/arcs`, `/bvp`), and stops there. Stage 3 of the chain has no
operator surface at all.

Kind: structure. Window: live, 2026-09-20.

## 3. COUNTER-EVIDENCE against this session's own T-739 filing

T-739 (filed earlier today, commit `13f2aec9`) states that T-155 "has never appeared on the
surface that tells the operator what needs deciding." That is **true of `fw review-queue` and
false of Watchtower.** Measured:

| Probe | Result |
|---|---|
| `curl /inception` → `grep -c T-155` | **3 occurrences** — T-155 IS listed |
| `curl -o /dev/null -w %{http_code} /inception/T-155` | **200** |
| decision vocabulary in that page body | `DEFER` ×13, `NO-GO` ×11, `decide` ×4, `pending` ×8, `GO` ×1 |

So the operator has had a working, reachable decision page for T-155 the whole time. T-739's
defect is real but **narrower than filed**: it is a defect in the *CLI* decisions queue, not an
absence of any operator surface. Both data points recorded side by side per the review's
conflicting-evidence rule. T-739's Context section should be corrected before it is worked.

Kind: structure / friction. Window: live.

## 4. Release seam — three live versions at once, and the check cannot see it

| Artifact | Bytes | sha256 (first 16) | Relation |
|---|---|---|---|
| `src/aef-workflow-designer.html` | 997,254 | `2b448b61b7fa6c33` | source of truth |
| `dist/MANIFEST.yaml` → `latest` | — | `2b448b61b7fa6c33` | **exact match to src** |
| `dist/aef-workflow-designer-0.12.0.html` | 997,254 | — | the release |
| `build/gallery/designer.html` | 953,047 | `76bf20fb4a3ababc` | **byte-exact match to `dist/aef-workflow-designer-0.10.0.html`** |

**CORRECTED 2026-09-20 after G1/G2 evidence landed.** This section first read the audit line
`[PASS] Release lag: src, released artifact and peer pin are in step`
(`.context/audits/2026-09-20-structure.yaml`) as establishing that the peer pin is current. It does
not. Measured directly:

| Thing | Version | sha256 (first 16) | Bytes |
|---|---|---|---|
| `src/` + `dist/MANIFEST.yaml` `latest` | **0.12.0** | `2b448b61b7fa6c33` | 997,254 |
| `.agentic-framework/policy/designer-pin.yaml` — **the peer pin** | **0.8.0** | `cab3c75183979b0e` | 903,600 |
| `build/gallery/designer.html` | **0.10.0** | `76bf20fb4a3ababc` | 953,047 |
| **what `/designer/app` actually serves** | **0.8.0** | `cab3c75183979b0e` | **903,600** |

So **src ↔ released artifact are in step** and **nothing else is**. Three different versions are
live simultaneously: the release is 0.12.0, the gallery mirror is 0.10.0, and the pin — which is
what the operator's own Watchtower designer page serves — is **0.8.0, four releases and 49 days
behind**. The §4 "UNVERIFIED" about `/designer/app`'s provenance is hereby **RESOLVED** by exact
sha256 identity with `dist/aef-workflow-designer-0.8.0.html` and with `designer-pin.yaml`.

The audit's PASS is not a lie about a different thing; it is a check that cannot see this. G1
records that `_t382-release-lag.py` keys on release *age* (0 days — 0.12.0 shipped today), reads a
vendored copy, and says in its own output that it "can only UNDER-report adoption lag". T-368
("Release-state blindness: 8 src commits ahead of the 0.8.0 pin") has sat 43 days in the review
queue naming exactly this.

Gallery drift established by sha256 comparison against every file in `dist/`, with exactly one
match.

Standing constraint recorded, not evaluated: T-102 and T-105 are blocked on gallery mirror drift
and are not to be unblocked by rebuilding `build/gallery/`.

Releases present in `dist/`: 0.1.0 0.2.0 0.3.0 0.3.1 0.3.2 0.4.0 0.5.0 0.6.0 0.7.0 0.7.1 0.8.0
**0.9.0** 0.10.0 0.11.0 0.12.0 — 15 versions. Note **0.9.0 exists**, which bears on T-368
("Release-state blindness … 0.8.0 pin") and OBS-357, which frames T-368 as asking whether to cut
0.9.0. Fact recorded; disposition is the JUDGE's.

*(Superseded — the `/designer/app` provenance question is answered in the table above. It was
first recorded here as UNVERIFIED because the response's `<title>` carries a loaded workflow
("AEF Workflow Designer — investigate.bpmn") and I judged a byte comparison inconclusive. It was
not: the sha256 is an exact match for the 0.8.0 artifact and for the pin.)*

## 5. The AEF-side install verb, quoted from our own blueprint

`.agentic-framework/web/blueprints/designer.py:7` — *"Read-only: this blueprint never writes the
vendored artifact."* Lines 53–54 render to the operator:

```
fw designer sync --from <delivered-artifact>
```

*"It verifies the artifact's sha256 against `{sha[:16]}…` before installing."*

So the pull direction of the integration protocol has a named verb with checksum verification at
the far end. Whether that verb exists and runs on the AEF side is **not observable from this
repo** (T-559 boundary) — recorded as a data gap, not as a pass.

## 6. Phase 2 reverse map — chain step → what serves it

Decomposed from the two arcs' own `headline_mechanic` strings. "Serves it" is filled only where
this leg verified it; rows marked → G2/G3 are owned by those gatherers' evidence files.

| # | Chain step (from arc headline) | Arc | Served by | Verified here? |
|---|---|---|---|---|
| 1 | Human draws a process in the browser designer | 001 | `src/aef-workflow-designer.html`; served at `/designer/app` | **yes** |
| 2 | Designer serialises to BPMN/YAML with `aef:` extensions | 001 | → G2 | no |
| 3 | The file is handed across the project boundary to AEF | 001 | TermLink `file_send`; `fw designer sync --from` at the far end | partial — near end only |
| 4 | AEF agent turns it into an approved governed task/inception graph | 001 | → G2 | no |
| 5 | Operator approves | 001 | `/approvals` (143 ids), `/inception/<id>` decide UI | **yes** |
| 6 | Reverse: AEF record/code → editable process map | 001 | T-184 `captured`/DEFER | → G2 |
| 7 | Operator opens a Designer-authored workflow | 002 | `/designer` corpus browser | **yes** |
| 8 | Exports it as an **executable contract** | 002 | → G3 | no |
| 9 | **A runtime executes it** | 002 | **nothing on the operator surface — §2** | **yes (absence)** |
| 10 | Every step traceable to justifying evidence | 002 | → G3 | no |
| 11 | Every step traceable to the authorising operator decision | 002 | `operator-decisions.yaml` → G4 | no |
| 12 | A step lacking either is **refused** rather than run | 002 | → G3 (refusal matrix) | no |

Steps 1, 5 and 7 are demonstrably served today. Step 9 is demonstrably unserved on the operator
surface. Steps 2, 4, 6, 8, 10, 11, 12 are owned by the other gatherers.

## 7. Data gaps from this leg

1. **No out-of-band observer of the seam.** The only record of 832↔AEF collaboration is the
   TermLink rail, which is also the medium. It lost its topic store once (T-733). A channel
   cannot report its own failures.
2. **The far side is unobservable.** Whether AEF's `fw designer sync` exists, runs, or has ever
   been run cannot be established from inside this repo (T-559). Any claim about the AEF end is
   at best `claimed`, never `measured`.
3. **No realization data.** `.context/audits/bvp-realization.jsonl` is ABSENT, so "did the
   shipped seam work deliver?" is unanswerable from this repo.
4. **`/designer/app` provenance UNVERIFIED** (§4).
5. **Pollution:** this session ran `fw review-queue`, a pre-push `fw audit --section structure`,
   `fw bvp estimate`, and four commits before this snapshot.
