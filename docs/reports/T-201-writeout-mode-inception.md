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

## 4. Assumptions to validate

- **A1:** Guardrails G1–G6 are mechanically enforceable (hooks/gates), not just conventions. *(If false → NO-GO.)*
- **A2:** `owner:human` + `captured` on every emitted task is sufficient to keep write-out on the initiative side of the Authority Model. *(Sovereignty check.)*
- **A3:** Re-compile reconciliation (G4) has a bounded, unsurprising rule that a human can predict. *(Usability.)*
- **A4:** One seam (G3) is clearly better once the trade is spelled out — this doesn't need to stay a fork through build.

## 5. Exploration plan (spikes — NOT build; each time-boxed)

1. **Spike-1 (guardrail enforceability, IW-1):** sketch the `--write` path + an emit-time check that refuses to emit anything not `owner:human`/`captured`. Prove G2 is a gate, not a doc. *(~½ day)*
2. **Spike-2 (seam trade, IW-2):** walk the 832-emits-bundle vs AEF-writes comparison against a single real diagram (investigate.bpmn) end to end; get AEF's read on the rail. *(dialogue + ~½ day)*
3. **Spike-3 (idempotency rule, IW-3):** define the uid-keyed reconcile rule for add/edit/delete and test it against a 2-revision diagram. *(~½ day)*

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
gates, not conventions. If Spike-1/Spike-2 show a guardrail can only be a
convention, this flips to NO-GO and write-out stays proposal-only.

## 8. Dialogue Log

### 2026-07-18 — Dimitri's steer (opening this inception)
- **Q (agent→Dimitri):** Should BPMN compile promote proposals → real `.tasks/` files, and in what arc sequence?
- **A:** **Inception-first**, sequenced **next** (ahead of typed events / reverse-discovery).
- **Outcome:** Inception T-201 opened. Go/no-go on the capability remains Dimitri's; agent produces the recommendation after the §5 spikes. AEF notified on the rail (offset 56) that write-out is inception-first/next and asked to weigh in on the §3 G3 seam during exploration.
