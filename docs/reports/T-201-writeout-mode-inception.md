# T-201 — Write-out mode inception: BPMN compile emits real `.tasks/` files

**Status:** exploration (inception). **Advisory:** GO, contingent on guardrails (below).
**Decision owner:** Dimitri (832 sovereign). **Arc:** designer-authoring-surface.
**Sequence:** NEXT (Dimitri steer, 2026-07-18) — ahead of T-190 typed events, T-184 reverse-discovery.

> C-001: this file is the artifact; the dialogue is ephemeral. Updated incrementally,
> committed per segment. The recommendation here is provisional until exploration closes.

## 1. Problem

Today the BPMN toolchain is **read + propose**: a diagram forward-compiles
(`fw bpmn compile`, AEF T-2531) into a *plan* — a list of build/agent nodes a
human then acts on. The diagram never becomes governance reality; a human
re-authors the tasks by hand. **Write-out mode** closes the loop: compile emits
real `.tasks/*.md` files, so the authored diagram *is* the source of the tasks
the framework governs.

That is the arc's whole point — an author→compile→execute pipeline — but it is
also the single most sovereignty-sensitive step in it.

## 2. Why this is a sovereignty question, not a feature

The framework's Core Principle is **"Nothing gets done without a task,"** enforced
by the task-gate; the Authority Model gives agents **initiative, not authority**.
A compiler that materializes `.tasks/` files is a tool that **authors the exact
governance artifact those rules protect**. Done naïvely, an agent drawing a
diagram could conjure active, owned work with no human in the loop — precisely
the inversion the task-gate exists to prevent. AEF named it an **IW-1/IW-3**
sovereignty gate (rail offset 49) and deferred the go to Dimitri.

So the inception's question is **not** "is write-out useful" (it is) but:
**can the guardrails be made mechanical and enforceable such that write-out
never authors governance reality without human authority?** GO holds only if yes.

## 3. Guardrail design (the core of the exploration)

| # | Guardrail | Intent | Open question |
|---|-----------|--------|---------------|
| G1 | **Dry-run default; explicit `--write`** | The safe mode is the default; writing is a deliberate, logged act. | Is `--write` a Tier-2 logged bypass, or a first-class flag with its own audit line? |
| G2 | **Emitted tasks land `owner:human` + `status:captured`** | Nothing auto-activates; a human must `work-on` each before it governs anything. | Should lane authority (sovereignty→human, initiative→agent) set `owner`, or is everything forced to `human` on first write? |
| G3 | **Write seam / target root** | Where do the files get written, and by whom. | 832-emits-a-task-bundle that AEF ingests, vs AEF-compiler-writes-`.tasks/`-directly. Which repo's `.tasks/`? |
| G4 | **Idempotent re-compile** | Re-compiling an edited diagram must reconcile, not clobber or duplicate. | Key on `aef:uid`? What happens when a node is deleted from the diagram — orphan the task, or refuse? |
| G5 | **Provenance** | Every emitted task carries its source (diagram id + `aef:uid`) for traceability. | New frontmatter field, or reuse an existing one? |
| G6 | **Build-readiness (G-020)** | Emitted build tasks must not land with placeholder ACs that the gate would block. | Land as `captured` only (ACs authored later by human), or refuse to write a node lacking ACs? |

The **seam (G3)** is the load-bearing architectural fork and needs AEF input:
- **832-emits-bundle:** 832 (SoT/authoring) produces a portable task-bundle; AEF (or any framework instance) ingests it under its own governance. Keeps 832 out of the authority business; portable; extra hop.
- **AEF-compiler-writes:** AEF's `fw bpmn compile --write` writes its own `.tasks/`. Fewer moving parts; couples the write to one framework instance; puts the authoring act inside AEF's gate (arguably where it belongs).

### 3a. Seam RESOLVED — manifest-as-seam (AEF concurrence, rail 2026-07-18 08:20Z, T-2541)

AEF (joint inception T-2541, artifact `docs/reports/T-2541-writeout-promotion-inception.md`)
reads the fork as a **false binary** and proposes a hybrid at **one existing
interface** — the T-2539 proposal manifest
(`.context/bpmn-staged/<diagram>/manifest.yaml`, uid-keyed). 832 concurs:

- **CONTENT authority = 832.** What tasks, which ACs, lane/owner assignment — the
  design call lives with the source of truth. The manifest (or a 832-emitted
  bundle that lands *as proposals*) is the hand-off.
- **GATED WRITE = AEF.** `fw bpmn promote <uid|all>` reads the manifest and
  **delegates each write to `fw task create`** — the single governed `.tasks/`
  writer — forcing `owner:human` + `status:captured` and stamping provenance.

**Why this makes G3 a gate, not a convention (the whole ballgame):** the guardrail
was never *who emits* — it is that **the `.tasks/` write never leaves the
task-gate perimeter**. If `promote` ever touched `.tasks/` directly, G3 is a
convention → NO-GO. Because `promote` delegates to `fw task create`, the write
inherits the task-gate + G-020 build-readiness *for free*. G3 becomes mechanical.
This satisfies the §6 GO criterion "the seam resolves to one option with AEF
concurrence."

Guardrail→gate map, both sides reconciled:

| # | Gate status | Owner of the remaining work |
|---|-------------|------------------------------|
| G1 dry-run default + `--write` | already a gate (T-2539) | — |
| G2 `owner:human`+`captured` | gate pending AEF Spike-1 (prove un-overridable via `fw task create`) | AEF |
| G3 write-through-task-gate | **LOAD-BEARING** — gate iff `promote`→`fw task create` (AEF Spike-1) | AEF |
| G4 idempotent re-promote (uid↔T-ID) | NOT built — needs **832's IW-2 mapping contract** (§3b) | 832 defines shape, AEF stores |
| G5 provenance (uid + source bpmn) | trivially a gate (frontmatter slot) | AEF |
| G6 build-readiness | already a gate (G-020 blocks placeholder-AC activation) — this is what makes `captured` safe | — |

Two open joints remain between the peers: (1) confirm the manifest is the seam
— **done, both concur**; (2) 832's IW-2 uid↔T-ID mapping contract for G4 — §3b below.

### 3b. IW-2 uid↔T-ID mapping contract (832's design call — 832 owns the shape)

AEF asked 832 for its lean on the id-mapping shape ("AEF stores the mapping; you
own the shape"). 832's lean:

**The emitted task's frontmatter is the authoritative mapping; any ledger AEF
keeps is a derived, rebuildable cache.** Provenance (G5) already puts `aef:uid` +
source `.bpmn` into the task on write — so the uid→T-ID relation is *recoverable
by scanning `.tasks/`*. The tasks are self-describing; a side-ledger that
disagreed with them would be a split-brain (Reliability). Proposed frontmatter
block on every promoted task:

```yaml
aef_provenance:
  uid: <bpmn node uid>              # stable node identity — the join key
  source_diagram: <diagram id/path>
  source_bpmn_sha: <hash of the node's COMPILED content at last promote>
  promoted_at: <iso8601>
```

**G4 reconciliation rule (bounded, predictable — the §6 GO criterion for
reconciliation), keyed on `uid` + `source_bpmn_sha`:**

- **New** (uid absent from all `.tasks/` frontmatter) → `fw task create`
  (`captured`, `owner:human`). Additive; safe.
- **Unchanged** (uid maps to a T-ID, `source_bpmn_sha` equals current compiled
  hash) → **no-op**. This is what makes re-promote *idempotent* — the whole
  point of the contract.
- **Changed** (uid maps to a T-ID, hash differs) → **never clobber**. If the task
  is still `status:captured` and shows no human edit, a `--write` may refresh it;
  if it is `started-work`/human-touched, `promote` **refuses and flags** a
  proposal-diff for human review. The human's edit to a captured artifact is
  sovereign; the compiler proposes, it does not overwrite.
- **Deleted** (a T-ID carries a uid no longer present in the diagram) → **never
  auto-delete**. A task is governance reality; deletion is destructive. `promote`
  marks it **orphaned + flags for human review** (answers AEF's "orphan or
  refuse?" → orphan-and-flag, never silent-drop).

The content hash makes edit-detection bounded: re-promote is a diff over
`(uid, source_bpmn_sha)`, not a fuzzy match. No unbounded reconciliation ⇒ the
§6 NO-GO trigger ("re-compile risks clobbering human edits") is structurally
excluded.

## 4. Assumptions to validate

- **A1:** Guardrails G1–G6 are mechanically enforceable (hooks/gates), not just conventions. *(If false → NO-GO.)*
- **A2:** `owner:human` + `captured` on every emitted task is sufficient to keep write-out on the initiative side of the Authority Model. *(Sovereignty check.)*
- **A3:** Re-compile reconciliation (G4) has a bounded, unsurprising rule that a human can predict. *(Usability.)*
- **A4:** One seam (G3) is clearly better once the trade is spelled out — this doesn't need to stay a fork through build.

## 5. Exploration plan (spikes — NOT build; each time-boxed)

1. **Spike-1 (guardrail enforceability, IW-1):** sketch the `--write` path + an emit-time check that refuses to emit anything not `owner:human`/`captured`. Prove G2/G3 are gates, not docs. **→ now AEF-side (T-2541 Spike-1): prove `fw task create` is drivable with un-overridable `owner:human`/`captured` so `promote` delegation makes G3 mechanical.** *(~½ day, AEF)*
2. **Spike-2 (seam trade, IW-2):** ~~walk the 832-emits-bundle vs AEF-writes comparison~~ **RESOLVED via rail dialogue (2026-07-18 08:20Z): manifest-as-seam, content=832 / gated-write=AEF, both concur. See §3a.** No further spike needed on the fork itself.
3. **Spike-3 (idempotency rule, IW-3):** the uid-keyed reconcile rule for add/edit/delete is now **drafted (§3b)**; remaining work is to *test* it against a 2-revision diagram (add/edit/delete a node, re-promote, assert no-op / proposal-not-clobber / orphan-flag). *(~½ day — AEF stores the ledger, 832 confirms the frontmatter contract holds)*

Decompose signal: if this needs >3 spikes or splits into independent domains, it's too big — split before GO.

## 6. Go / No-Go criteria

**GO if:**
- G1–G6 each reduce to a mechanical check (a gate/hook/flag), and A1+A2 hold — write-out provably cannot author active governance work without human authority.
- The seam (G3) resolves to one option with AEF concurrence.
- Re-compile reconciliation (G4) has a predictable, documented rule.

**NO-GO if:**
- Any guardrail can only be a convention (not enforceable) — the sovereignty gate would depend on agent discipline, which the framework explicitly rejects.
- The seam stays genuinely ambiguous / both sides push authority to the other.
- Reconciliation is unbounded (every re-compile risks clobbering human edits to emitted tasks).

**DEFER if:** the capability is sound but blocked on a prerequisite (e.g. typed events T-190 needed for faithful emission) — though Dimitri sequenced this *ahead* of those, so DEFER-for-prerequisite is currently unlikely.

## 7. Recommendation (provisional)

**GO, contingent on §3 guardrails proving enforceable in §5 spikes.** The
capability is the arc's purpose and AEF's compiler is ready to build on; the only
thing standing between here and a build task is demonstrating the guardrails are
gates, not conventions. If Spike-1 shows a guardrail can only be a convention,
this flips to NO-GO and write-out stays proposal-only.

**Update 2026-07-18 (post-AEF seam reply):** The GO case is materially stronger.
Of the three §6 GO criteria, **two are now met**: the seam resolved to one option
with AEF concurrence (§3a), and re-compile reconciliation has a predictable,
documented rule (§3b). The single remaining gate to prove is G2/G3
un-overridability — that `fw bpmn promote` delegating to `fw task create` cannot
emit anything but `owner:human`/`captured` (AEF-side Spike-1). No guardrail has
been shown to be convention-only; none currently looks likely to be. The
recommendation to Dimitri will firm from *contingent GO* to *GO* iff AEF's
Spike-1 confirms the delegation is un-overridable. The go/no-go decision remains
Dimitri's.

## 8. Dialogue Log

### 2026-07-18 — Dimitri's steer (opening this inception)
- **Q (agent→Dimitri):** Should BPMN compile promote proposals → real `.tasks/` files, and in what arc sequence?
- **A:** **Inception-first**, sequenced **next** (ahead of typed events / reverse-discovery).
- **Outcome:** Inception T-201 opened. Go/no-go on the capability remains Dimitri's; agent produces the recommendation after the §5 spikes. AEF notified on the rail (offset 56) that write-out is inception-first/next and asked to weigh in on the §3 G3 seam during exploration.

### 2026-07-18 08:20Z — AEF seam reply (rail, T-2541)
- **Q (832→AEF, offset 56):** Where does the write seam live — 832-emits-bundle vs AEF-compiler-writes (G3/IW-2)?
- **A (AEF):** False binary. Hybrid at the existing T-2539 manifest interface: content=832, gated-write=AEF via `fw bpmn promote` → `fw task create`. The guardrail is "write never leaves the task-gate perimeter," which makes G3 mechanical. AEF opened its compiler-side half as joint inception T-2541 (DEFER pending spikes; decision stays Dimitri's). AEF handed 832 one joint: the uid↔T-ID mapping contract for G4 ("you own the shape").
- **832 response (this update):** Concur on manifest-as-seam (§3a). Drafted the IW-2 mapping contract (§3b): task frontmatter (`aef_provenance`) is authoritative, AEF's ledger is a derived cache; G4 reconcile keyed on `(uid, source_bpmn_sha)` — no-op / propose-not-clobber / orphan-and-flag. Relayed to AEF on the rail; asked them to confirm the frontmatter contract works from `fw task create`'s side.
- **Outcome:** Two of three open questions now closed (IW-2 seam resolved; IW-3 reconcile rule drafted, test pending). IW-1 (G2/G3 un-overridability) is AEF Spike-1. GO case strengthened — the load-bearing seam resolved to one option with peer concurrence. Go/no-go remains Dimitri's after the spikes land.
