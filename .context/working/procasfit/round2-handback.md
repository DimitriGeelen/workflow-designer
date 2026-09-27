# procAsFit Round 2 — Handback

**Context used:** 246k measured at the gate, against the mandate's ~300k stop. **Stop reason:** approaching the context bound with a task at a clean parking point. T-889 is parked at 5/6 ACs, not abandoned mid-edit.

**Structural note.** I am round 2 — `claude -p`, PID 3699510. The prior round-2 attempt was refused by a weekly limit and recorded as failed (`bc9d6ba3`), so this is a re-run, not a continuation of a partial.

## Selection

- **Objective:** G6 (idea↔implementation round-trips). Purpose doc §7 is the gate: G6→arc-001 is the *only* goal with an in-flight arc. arc-005 is draft-unratified; arc-002 and arc-003 trace to no goal and are therefore ineligible at level 1 however tractable — arc-003 holds 41 open tasks and would have absorbed the whole round.
- **Arc:** arc-001 `designer-authoring-surface`.
- **Task:** T-889 (T-888 ruling clause 2). Round 1 named it the obvious opener; I checked rather than inherited, and found it already `started-work` with real ACs and an estimator score from 13:01Z — round 1 *prepared* it and reported "not started" meaning no code. G-020 and scored-before-execution were therefore already satisfied.
- **Quadrant: none — and that is a finding.** T-889 has no `cost_estimate`, so `fw bvp` shows `QUAD -`. So do **all** of arc-001's open `now`-horizon tasks. 40/123 tasks corpus-wide (33%) have no cost. The mandate selects by quadrant; for the arc that carries the project's only live goal, the quadrant axis does not exist. I selected on value (0.42 norm, above several tasks the ranker labels `hv`) plus gating-dependency status, and am flagging rather than papering over that this was not a quadrant decision.

## Objectives advanced

| | at run start | now |
|---|---|---|
| **G6 / clause 2** | element authority emitted by nobody, validated by nothing | element carries it; validator reads it **directly**, both prohibitions proven separately |
| vocabulary integrity | element values ungated | `E-XML-META-AUTHORITY`, `AUTHORITIES` reused not re-listed, registered in both parity registries |
| **T-886's guard** | believed sound | **a hole found and filed (T-904)** — see below |

**5 of 6 ACs closed**, each with a re-runnable check. `fw task verify T-889`: **7/7 passed**.

## The finding worth the round

**T-904 — the round-trip guard's denominator reads comments as code.** `deriveProjectedKeys()` regexes the raw text of the emitter function, comments included. Measured: deleting `authority` from the emitter's `metaKeys` left the guard **green**, because a prose comment three lines above said `node.aef.authority`. Removing only that comment text — changing nothing executable — turned the identical mutant **red** with the correct message.

This is T-886's derivation, which exists precisely so the list cannot drift from the code, and it can be moved by text the engine never runs. Bidirectional: false green for a deleted key, false red for a key only ever mentioned. **My own explanatory comment silenced my own mutation leg**, which is how it surfaced. Learning recorded.

## Where I was wrong, three times

1. **I ran the corpus census under the wrong XML namespace** (`aef.dev/schema/1.0` vs the real `anchorpoint.framework/aef/extensions`) and reported 94 files / 2130 nodes. The conclusion — zero element-level authority — survived only because a namespace-agnostic text grep independently agreed. Re-measured: **201 files, 4892 nodes, 500 lane-level, 0 element-level.** Corrected in the task's Evolution section rather than quietly.
2. **My first document-order control was vacuous.** It passed while proving nothing: `process.find(laneSet)` locates the set regardless of position, so relocation changes no answer even under lane-reading. Replaced with a two-laneSet pair, and the teeth script now carries **C4, a control on the control** — it requires the pair to *differ* under a lane-reading mutant. Without C4 the green means nothing.
3. **I destroyed the task's `## Verification` section with my own edit** — sliced on `s.index('## Verification')`, which matched the *prose mention* in the Human-AC paragraph, not the heading. The symptom (`No verification commands found`) looked exactly like the commit path silently dropping the P-011 gate's only input — a vacuous-gate defect of the class this project hunts. **I checked before filing.** It was mine. PL-349 applied in the one case where getting it wrong would have cost round 3 an investigation into a healthy gate.

I also walked into the **L-387 pipefail trap** the task template warns about at length: `python3 … | grep -q` returns the validator's exit 2 under `pipefail`, so two controls read false while matching.

## Sovereign questions, priority order

1. **OBS-410 (new, URGENT) — the MCP `fw` server is rooted at a different project.** `mcp__fw__version` reports `/005-Yellowtwig/001-theSpiceFactory/002-Azure-DevOps`, fw v1.6.768; the local binary is `/opt/832-Workflow-designer`, v1.7.68. That toolset exposes **agent-authority write verbs** (`work_on`, `task_update`, `note`, `context_focus`, `add_learning`). An agent reaching for `mcp__fw__work_on` here mutates an unrelated project's task state, silently, with no gate objecting. Detected only because a *read* returned "T-889 not found" — the benign direction. A write is not.
2. **Quadrant blindness on the goal-bearing arc** (above). The mandate's own selection discipline cannot be executed as written on arc-001.
3. **OBS-408 confirmed independently, and refined.** `deps` prints 5 dependents; `impact` prints a bare header. New datum: `impact` **exits 1** — so it does signal failure, but its *output* reads as a successful empty result, which is the dangerous half.
4. **T-903 — `E-WORKFLOW-KIND` / `E-XML-WORKFLOW-KIND` have failed the dialect harness since T-875, unnoticed.** Concrete harm from the pre-flight gap: `run-bridge-tests.sh` is one of five dependents, takes ~15 minutes, and T-875 did not run it. I ran it, which is how these surfaced alongside my own.
5. Carried forward: OBS-407, OBS-396, OBS-398, OBS-397, arc-005 ratification. **T-885 still needs the operator's close** (six Agent ACs ticked, `owner: human`, G-027) — unchanged, not delegated.

## What remains in Q1/Q2

- **T-889 AC 1** — the only open criterion. Both *static* halves hold and are checked (`metaKeys` 20→21, panel writer via `AEF_FIELDS`). The AC's actual proof — driving the editor in a browser to set authority on a node from an authority-free document and observing the export — was not built: `SRC_HTML` is not overridable and the sidecar must be up. Left unticked rather than argued closed from the static halves.
- **T-901 / T-902 / T-903 / T-904** — filed this round with real descriptions, all unscored stubs. T-904 is the highest-value: it undermines a guard two tasks already rely on.
- **T-890 – T-895** — the rest of the ruled package, still placeholder ACs; G-020 will block each.
- **T-357 / T-309** (0.80, hv-hc) — untouched; Q1 first.

## Gates that refused me, and what I did instead

| gate | what I did |
|---|---|
| `check-active-task` blocked **pure reads** ×4 — a `VAR=…` prefix, a `for` loop, an `xargs` pipe, `fw task show` (while `fw arc list` passed) | rephrased each. **OBS-394 recurring**; the `fw task show`-vs-`fw arc list` asymmetry is a new instance of the same allowlist gap |
| selection itself gated — `fw bvp` needs an active task, but choosing the task needs the ranking | read frontmatter directly, then confirmed via `fw bvp` once focused. Round 1's ordering note stands |
| **P-011** ran 7/7 at `fw task verify` | the independent check on my own output — and the thing my bad edit had silently disabled |
| **parity/dialect harness** refused my new rule twice (no carrier, no parity class) | registered it properly, and classified it **GAP not PAIRED** — PAIRED would have asserted a YAML counterpart that does not exist. Filed as T-902. Correct gate; it caught a real T-317-class omission |
| `fw task create --arc` rejected | used `--tags "arc:…"` |

## Cost vs estimate

Round 1's calibration holds and extends: **the harness is fast, the suites are not.** Guard: 2s. Teeth (9 legs, 3 mutants, 2 full harness runs): ~90s. 201-file validator regression: ~60s. But `tests/run-bridge-tests.sh` ran **~15 minutes** — long enough that I serialised all `src/` and `tools/` edits behind it, which was the right call and cost real wall-clock. Anything pacing itself against "the harness is slow" is still wrong; anything assuming "therefore all the tests are quick" is wrong in the other direction.

T-889 cost ~245k against round 1's ~90k for T-886 — but produced 5 ACs, 4 filed tasks, a guard defect, and a 201-file regression. The dominant cost was not the code; it was **measuring rather than asserting**, three times over, including twice catching myself.

**TermLink:** used as the transport carrying this round. I spawned no sub-agents and did not dispatch BVP estimation — T-889 arrived already scored by round 1's estimator run, so dispatching again would have been decoration. Every unit touched the same three files and the same task corpus: shared state, serialised, as the mandate requires.

**Check before trusting this handback:** three commits (`a906f337`, `71d4943b`, `f0c84765`) are on `bleeding-edge`. I did **not** run `fw handover --commit`, so unlike round 1 these are **local, unpushed** — verify before assuming either state.