# T-835 — Authority on the element, lane as domain

**The mechanism T-685 GO'd on 2026-09-08 and nobody filed for fifteen days.**

This report proposes a mechanism and states its costs. It takes no ruling, edits no
standard, and changes no production code. T-685 named this "the operator variable" in
those words; that is still where it sits.

Everything numeric below was re-derived on 2026-09-27 against the live tree. Commands are
given so every figure can be re-run rather than believed — including the two that came back
disagreeing with the GO.

---

## 1. T-685's GO, quoted

> GO on opening the question; the mechanism is genuinely unresolved and is the operator
> variable. The status quo is not a neutral baseline:
> `examples/aef-processes/rendered/context-memory.bpmn` carries three domain lanes at
> `authority="none"`, a value absent from the standard collapse map
> (sovereignty/initiative/authority/external) and handled nowhere in the standard or
> `tools/bpmn-cli.py`, so **12 flowNodeRefs currently have no derivable owner and nothing
> detects it**. Meanwhile `aef:meta tier="0|1"` already sits ON elements in 10+ corpus maps
> (**27 tier-1, 10 tier-0**) while the standard mentions tier only 4 times and never as an
> authority carrier, so half the operator proposed design is built and undocumented. T-341
> half B is blocked on this: `lanes[0]` is positional, so authority today is decided by
> third-party laneSet serialisation order, which is exactly the defect that disappears if
> authority moves into the box. Costs are real and bound the exploration: frozen standard
> v1.1 deliberately REMOVED the node-level owner override making the lane the sole
> authority-of-record, and O-3 compile-time enforcement of the sovereignty go/no-go lane
> would need rewriting against the element.

— `.tasks/completed/T-685-should-authority-live-in-the-box-tier--o.md`, `## Decision`,
recorded `2026-09-08T09:23:42Z`, reviewer verdict CONCERN / needs-human: no.

## 2. Re-derivation — two of the four sub-claims do not survive

**Corpus scope.** "Corpus maps" means `examples/aef-processes/rendered/` — 24 `.bpmn`
files, the seam artefact AEF pins against. `build/gallery/rendered/` (25) and
`.editor-versions/` are derived and excluded; T-340 was recently found supplying a
re-derivation command with no scope filter, and this report is not repeating that.

| # | T-685 claimed | re-derived 2026-09-27 | verdict |
|---|---|---|---|
| a | 3 domain lanes at `authority="none"` | **3**, and `context-memory.bpmn` is the only file in the corpus with any | ✅ exact |
| a′ | `none` absent from the collapse map | **0 occurrences** in the frozen standard | ✅ exact (controlled) |
| b | 12 flowNodeRefs with no derivable owner | **12** (working 3 + project 6 + episodic 3) | ✅ exact |
| b′ | "**and nothing detects it**" | `W-LANE-NO-OWNER` fires **7 warnings** — and shipped **before** the GO | ❌ **false when written** |
| c | 10+ maps, **27 tier-1**, 10 tier-0 | **14 maps**, **53 tier-1**, **10 tier-0**, plus **11 tier-2** | ⚠️ tier-1 understated ~2× |
| d | standard mentions tier 4 times, never as authority carrier | **4 lines / 6 occurrences**, never as authority carrier | ✅ (counting difference only) |

```
# (a) and (a′) — with the control that makes the absence mean something
grep -c 'authority="none"' examples/aef-processes/rendered/*.bpmn | grep -v ':0'
for v in sovereignty initiative authority external none; do \
  printf '%-12s %s\n' "$v" "$(grep -ocE "\b$v\b" docs/standards/aef-bpmn-mapping-v1.md)"; done
# (c)
grep -ohE '<aef:meta[^>]*tier="[^"]*"' examples/aef-processes/rendered/*.bpmn \
  | grep -oE 'tier="[^"]*"' | sort | uniq -c
```

**On (a′) — the control matters.** A bare "`none` appears 0 times" is an uncontrolled
absence assertion and could equally mean the file moved or the grep is broken. The four
real collapse-map values return 6 / 1 / 5 / 1 from the same file in the same run, so the
zero is a fact about the standard and not about the command.

**On (b′) — the claim that fell.** `W-LANE-NO-OWNER` emits seven warnings on
`context-memory.bpmn`, each naming the defect precisely:

> `node 'wrk_2_context': serviceTask is a task but its lane authority 'none' has no compiled
> outcome; mapping-v1 §3 makes the lane the sole authority-of-record, so this task has no
> derivable owner and a downstream compiler must invent one`

It is not new. `git show b0999337:tools/validate-workflow.py | grep -c W-LANE-NO-OWNER` →
**3**, at the commit immediately preceding the GO. It shipped under T-331/T-309. So the
GO's "nothing detects it" was **incorrect at the moment it was written**, not made stale by
the fifteen days.

Seven, not twelve, because the rule fires only on tasks. The twelve refs are 6 serviceTask,
1 scriptTask, 2 startEvent, 2 endEvent, 1 exclusiveGateway — **7 task-like, all 7
detected**; the remaining 5 are events and a gateway, which arguably need no owner at all.

**On (c) — the understatement.** The corpus is **byte-identical** to its state at the GO
(`git archive b0999337 examples/aef-processes/rendered` → same 24 files, same 53/11/10), so
this is not drift. Counted with an XML parser rather than grep, **74 elements** carry
`aef:meta tier` — 10 tier-0, 53 tier-1, 11 tier-2 — on scriptTask (48), serviceTask (17),
userTask (7), subProcess (2). T-685 scoped itself to `tier="0|1"`, which excludes the 11
tier-2, but 27 against 53 remains roughly half.

**The corrections do not reverse the GO — they sharpen it in opposite directions.** The
element-level carrier is about twice as established as claimed (argues *for*), and the
"undetected hole" is detected and has been all along (argues the urgency was overstated).
What survives untouched is the part that actually motivates the change, and it is in §3.

## 3. The evidence T-685 did not name, and it is the strongest

The three lanes in `context-memory.bpmn` are:

| lane id | name |
|---|---|
| `working` | Working Memory · session-local |
| `project` | Project Memory · durable cross-task |
| `episodic` | Episodic Memory · completed histories |

These are **memory types**. They are not authorities, they were never going to be
authorities, and no value in `sovereignty / initiative / authority / external` could
honestly have been written in that slot. The author wanted a *domain* grouping, the schema
demanded an authority, and `none` is what that collision produced.

`authority="none"` is therefore not corrupt data and not an authoring error. **It is the
corpus already reaching for lane-as-domain and having no vocabulary to say so.** The
operator's direction is not a proposal the corpus is waiting for; it is a description of
what one map already does, in the only way the current schema let it.

That is the argument for the change, and it is measured rather than asserted.

## 4. The mechanism, concretely

A direction is not a mechanism. Named parts:

**The carrier.** `authority` becomes an attribute of `aef:meta` on the flow node's
`extensionElements`, taking the existing four-value vocabulary unchanged:

```xml
<bpmn:serviceTask id="prj_1_add" name="Add learning">
  <bpmn:extensionElements>
    <aef:meta authority="initiative" tier="1"/>
  </bpmn:extensionElements>
</bpmn:serviceTask>
```

The precedent is not hypothetical: 74 elements in 14 maps already carry `aef:meta` with a
governance attribute in exactly this position. The element-level extension point is built,
exercised, and round-trips today. What is missing is one attribute name.

**`tier` is NOT that carrier, and conflating them would lose a distinction the framework
depends on.** `tier` is the enforcement ladder — 0 consequential/human-approval, 1
standard, 2 situational authorization, 3 pre-approved. `authority` is who acts. They are
orthogonal: a Tier-0 action is typically *agent-initiated* and *human-approved*, which is
one element holding `authority="initiative"` and `tier="0"` simultaneously. Collapsing
authority into tier would make that unsayable. T-685's "half the design is already built"
is right about the **mechanism** (element-level `aef:meta` governance attributes) and
should not be read as "tier already is authority" — the standard's four mentions never say
that, and neither does the corpus.

**The lane becomes a domain.** `aef:laneMeta` keeps `abbr` and `height`; its `authority`
attribute either disappears or degrades to a *default*. Two variants, and the choice
between them is most of the cost:

- **M1 — element declares, lane defaults.** Element `aef:meta authority` wins; lane
  authority supplies the default when the element is silent. No corpus migration, every
  existing map keeps its current meaning, `authority="none"` becomes legal and means "this
  domain asserts no default". **Cost:** it re-introduces the node-level override that v1.1
  deliberately removed (§4).
- **M2 — element only.** Authority lives solely on elements; lanes carry none. Coherent and
  one-directional. **Cost:** migrate all 14 maps that carry tier plus every lane-authority
  map, rewrite O-3 against the element, and re-cut AEF's collapse map.

M1 is the cheaper and the less honest; M2 is the reverse. This report does not choose.

## 5. Frozen-standard impact — stated, not acted on

`docs/standards/aef-bpmn-mapping-v1.md` Part I is frozen and is **not edited by the agent
under any circumstance**. Nothing in this task touched it. What it says, precisely:

- **§3 / line 97:** *"**owner is the lane (IW-9, v1.1):** a node's `owner` MUST be its lane
  — there is **no** node-level `owner` override. The Lane (its `aef:laneMeta authority`) is
  the sole authority-of-record."*
- **line 9:** the node-level override is *"**removed** (§2 table + conformance fence, §3)"*;
  `owner` *"now derives from the lane authority (T-189)"*.
- **line 68:** the `owner` table row is struck through — *"derived from the node's lane
  (Axis 1); no node-level override"*.
- **line 137 (O-3):** an inception's go/no-go boundary *"**MUST** sit in a sovereignty
  (human) lane, machine-checked at compile time"*.

This must be said plainly: **v1.1 did not omit the element-level carrier, it removed it on
purpose.** Both M1 and M2 propose reversing a deliberate decision of a frozen standard. M1
reverses it outright. M2 reverses it and relocates O-3's compile-time MUST as well. Neither
is a clarification and neither should be presented to AEF as one.

## 6. Downstream unblocks — named and checked

T-835's own AC insists "appear to be" is not good enough. Per task, which criterion
dissolves and which survives:

### T-358 — importer fabricates 3 lanes + 1 participant

Blocking criterion: *"Choose the lane/pool fabrication repair: A · B · C · AB · no repair"*.

- **Dissolves:** option A's *invalidity*. A (don't fabricate) today yields a document our own
  validator rejects with `E-XML-LANES-EMPTY`. Under lane-as-domain a third-party file with
  no lanes **declares no domains** — nothing is absent, so nothing needs inventing, and the
  error's premise is gone.
- **Survives:** the **participant/pool** half. The measured defect is `lanes 0→3` *and*
  `participants 0→1`; a pool is not a lane, and no reading of lane-as-domain says anything
  about fabricating a participant. That remains a real choice.
- **Also survives:** what the exporter writes for a document with no domains — omit the
  `laneSet` entirely, or emit an empty one. A ruling is still required; it is just no longer
  a ruling between one valid option and one the validator refuses.

### T-341 — unresolvable `flowNodeRef` silently reassigns to the human lane

Blocking criterion: *"Rule on the default-lane policy for an orphaned flow node."*

- **Dissolves:** the authority half, completely. `lanes[0]` is positional, so today a third
  party's **laneSet serialisation order** decides who owns a node. Once authority is on the
  element, serialisation order cannot reach it. This is the single clearest win in the
  proposal.
- **Survives:** the **placement** half. An orphaned node still has to render in some
  swimlane box, and "which domain does an unassigned node belong to" is a live question with
  no authority content. It becomes a layout decision rather than a governance one — much
  cheaper, not free.

Both tasks' Agent ACs are explicitly marked *BLOCKED on the Human AC*, so neither can
progress on any path that does not run through the operator. This report does not change
that and is not intended to.

## 7. `E-XML-LANES-EMPTY` re-examined — it is wrong in both directions today

`tools/validate-workflow.py:1050` — *"no `<bpmn:lane>` declared; section 3 requires at least
one lane"*. The rule exists because §3 makes the lane the authority carrier; if authority
moves, the rationale moves with it.

Measured, and this is the part worth attention: **the rule already fails at its own job.**

```
python3 tools/validate-workflow.py examples/aef-processes/rendered/context-memory.bpmn
→ 0 error(s), 7 warning(s)
```

Zero errors. `E-XML-LANES-EMPTY` does **not** fire on the one file in the corpus with 12
nodes that have no derivable owner — because that file *has* lanes. The rule counts lanes;
the thing anybody cares about is whether nodes have owners; and those two came apart the
moment `authority="none"` was written.

So it is simultaneously:

- **over-strict** — rejects a third-party document that is perfectly well-formed and simply
  declares no domains (this is exactly what blocks T-358 option A), and
- **under-strict** — passes the corpus's only genuinely unowned-node document.

Three dispositions, and the third is the honest one:

1. **Retire it.** Under lane-as-domain a lane-less document is conformant, so the rule has
   no premise left.
2. **Re-justify as a rendering requirement** — "a map with no lane has no swimlane to draw
   in". Defensible but much weaker than what it claims now, and it would still pass
   `context-memory.bpmn`.
3. **Re-point it at the actual hole** — error on *a node with no derivable authority*,
   which is what §3 was protecting all along. This is what `W-LANE-NO-OWNER` already
   measures as a WARN; promoting that predicate to the error and retiring the lane-count
   proxy would fix both directions at once, and would make `context-memory.bpmn` fail
   honestly instead of passing quietly.

Disposition 3 is a change to a production validator and is **not made here** (see §9).

## 8. The filing gap — it is not two coincidences, it is 26 of 30

The AC asks this to be recorded as a pattern rather than as T-685 plus T-213. It is a
larger pattern than that, and the framework has been saying so on every run:

> `[WARN] Found 26 GO-scope-not-propagated inception(s) of 30 GO-recorded completed
> inception(s) examined — GO recorded, related_tasks empty, nobody back-references, no
> unlocks_inception_decision`

**26 of 30 — 87%.** `T-685` is itself on that list
(`.context/audits/go-scope-unpropagated/LATEST.md:29`), and so is `T-213`
(diagram-kind, GO'd 2026-07-21, still unbuilt, line 39).

The uncomfortable part is not the number, it is that the number was never hidden. The audit
emits it every run, it is in the pre-push output, and the list of offenders is regenerated
to a file. Nothing acted on it for fifteen days in T-685's case and sixty-eight in T-213's.
That is the same shape as T-873 earlier today — a correct, durable, ignored signal — and
the remedy here is not another detector, because the detector exists and works.

What is missing is that a GO produces no obligation. `fw inception decide … go` records a
decision and files nothing. The structural fix would be at that verb: a GO either names its
successor tasks or records why none are needed, at the moment of the decision, when the
context is loaded. **Not proposed as work here** — it is an AEF-side change to the inception
lifecycle and belongs to them.

## 9. What was deliberately not done

- **No production change under this task id.** No exporter, importer, validator or corpus
  edit. The `E-XML-LANES-EMPTY` disposition in §7 is a recommendation; on a ruling it
  becomes its own build task.
- **The frozen standard was not touched.** §5 states impact only.
- **No ruling taken.** M1 vs M2 vs no-change is the operator's, as T-685 said in the words
  "the operator variable".
- **T-358 and T-341 were not advanced**, and their Human ACs were not ticked, discussed away,
  or reclassified.

## 10. What the operator is actually being asked

One question, three answers:

| | choice | what it costs |
|---|---|---|
| **M1** | element declares authority, lane authority becomes a default | no migration; reverses v1.1's deliberate removal of the node-level override |
| **M2** | authority on the element only, lane is purely a domain | coherent; migrate 14+ maps, rewrite O-3 against the element, re-cut AEF's collapse map |
| **M0** | keep lane-as-authority | free today; `context-memory.bpmn`'s three memory-type lanes stay unsayable, T-341's authority stays decided by serialisation order, and T-358 option A stays invalid |

M0 is a real option and is listed as one. It is worth saying that it is not the cheap
choice it looks like: it keeps two tasks blocked indefinitely and leaves one corpus map
permanently warning.

**Sequencing:** T-358's own note (2026-09-23, operator-directed) holds its ruling behind
this report. That hold is discharged by this document, not by any decision in it.
