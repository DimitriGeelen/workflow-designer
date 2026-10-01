# T-309 IW-1 — where validator findings surface: background, directive mapping, steelman/strawman

**Task:** T-309 (inception, GO recorded) · **Date:** 2026-10-01
**Status:** decision brief. The decision is the operator's. Every number here is measured in
this session unless marked otherwise, and the measurements that went wrong are shown as well
as the ones that held.

---

## 0. Two corrections before the argument, because they weaken my own earlier advice

**(a) "The project's own ranking puts T-309 joint first" is much weaker than it sounded.**
I used it to recommend this work. `fw bvp T-309` shows **score 4 on all nine drivers**, flagged
`PROPOSED (advisory)` — the estimator's uniform default, not a judgement. `fw bvp T-357` is
*identical*: 4 across the board, same 252, because 4 × 63 = 252. So "joint top of the ranking"
means **two tasks received the same flat estimate**, not that the project assessed them as its
two most valuable. 40 of 118 ranked tasks have no cost at all. The ranking is a useful sieve,
not an authority, and I over-weighted it.

**(b) My rule-parity count was two different measurements wearing one label.**
Revision 2 of T-309 said parity had "doubled, 7 → 14". That counted *conceptual* pairs by
stripping the `-XML-` infix. Caught when `W-LANE-NO-OWNER` — filed YAML-only by that heuristic
— fired on a `.bpmn` file. Re-measured by **class membership**, which needs no naming
convention: `Validator` emits **31** rule ids, `XmlValidator` **29**, and exactly **3** strings
are emitted by both (`E-INCEPTION-NOT-SOVEREIGN`, `W-LANE-NO-OWNER`, `W-TYPE-LANE-MISMATCH`).
Conceptual pairs: 14. Both are real; they answer different questions. Neither supports
"doubled". Corrected in the task.

**What survives both corrections** is the finding that actually unblocked this slice:
revision 1's own falsifiability control, re-run like for like. It recorded *"strip every
`conditionExpression` from a corpus BPMN map and nothing fires, exit 0"*. Re-run on
`examples/aef-processes/rendered/task-lifecycle.bpmn`, 8 blocks removed:
**4 × `W-XML-GW-AMBIGUOUS`, rc=1.** The named blocker is gone. That does not depend on any
parity count.

---

## 1. Background: what this is and why it has been open since July

T-309 asks one question — should the ~29 `XmlValidator` rules reach the person drawing the
map? Its GO is recorded, with the reasoning that the rules "already exist and are already
trusted"; what is missing is **reach**. The checks run in the bridge suite and from the CLI,
and the author never sees them.

It has been open because the GO explicitly left the cost unpriced: *"high that the feature is
worth building and will not be noisy; low on cost, because the delivery route is the expensive
unknown and it is exactly what has not been priced."* Four interlocking workstreams were
named. Their state now:

| item | question | state |
|---|---|---|
| IW-2 | delivery route: port-to-JS vs sidecar HTTP vs shared spec | **CLOSED (T-955).** Sidecar HTTP, `POST /api/validate`, no rule logic in the transport. Chosen on measured grounds: this repo already maintains a cross-form agreement harness *because* two implementations drift, and that harness is failing right now on an `E-NODE-LANE` disagreement. A third form would be strictly worse. |
| IW-3 | advisory vs blocking | **CLOSED by the operator (T-956).** *"I always want to override… it can give me friction… but I want to be the final authority."* Advisory plus friction, never a hard block. |
| IW-1 | **where** findings surface | **OPEN — this document.** |
| IW-4 | the XOR-identical-targets rule | Open, and genuinely a follow-up: a new rule, not a placement question. |
| — | reach from the editor | **CLOSED (T-961, today).** `validateCurrentWorkflow()` works end to end in a real browser, 8/8 legs, placement-independent so IW-1 stays open rather than being settled by accident. |

So IW-1 is the last thing between a recorded GO and a shipped feature, and it is the one
genuinely contested question left.

---

## 2. The measurement that should drive this decision

**On our own corpus the validator is quiet. On AEF's conventions it is not.**

- **Our 25 rendered maps: 1 map with findings, 7 findings total**, all `W-LANE-NO-OWNER` on
  `context-memory.bpmn`. Measured this session across `examples/*/rendered/*.bpmn`.
- **T-325 measured `W-XML-GW-AMBIGUOUS` firing on 47 of AEF's 48 live gateways and 0 of ours.**
  Its conclusion, in its own words: *"It is not measuring gateway correctness; it is measuring
  which toolchain wrote the file."*

Those two numbers are the whole decision, because of what arc-001 commits the designer to
being: *"Workflow Designer as AEF's process-authoring surface"*, whose headline mechanic is a
human drawing a process that the AEF agent turns into governed work, **and AEF's existing work
rendered back as an editable map**. The designer will open AEF-authored maps. On those, one
rule alone produces ~47 warnings that are correct by the conventions they were written under.

**And the mechanism that would suppress that noise exists and is wired to nothing.**
`tests/test_rule_dialect_axis.py` classifies each rule as universal or dialect-relative.
`grep -c dialect tools/validate-workflow.py` → **0**. The validator does not consume it. This
is one of the four dials T-956 catalogued as "turned and connected to nothing", alongside
`workflowMeta.kind` and `tier_default`.

AEF's own L-527, quoted in T-325: **a rule that gets tuned out is weaker than no rule, because
its silence stops meaning anything.** That is the specific failure mode on the table.

---

## 3. Mapping against purpose and objectives

### The four constitutional directives — a priority order, not a weighted sum

Ties break lexicographically on D1. Weights (9/7/5/3) are for BVP arithmetic, not for
overriding the ordering.

**D1 Antifragility (9) — "system strengthens under stress; failures are learning events."**
The directive is not satisfied by *detecting* more. It is satisfied when a finding changes
something. A placement that produces 47 dismissals teaches the author to dismiss, which is
anti-antifragile: the system gets *weaker* under stress because the signal degrades. The
antifragile placement is the one where each finding shown is one the author acts on, and where
dismissals are **recorded** — T-956's M4/M5 ("navigating around a blockade is a first-class
act", "those deviations are learning inputs") applied here means a dismissed finding should be
evidence about the rule, not silence.

**D2 Reliability (7) — "predictable, observable, auditable execution; no silent failures."**
T-961 already discharged the hard part: "could not look" is structurally distinguishable from
"found nothing" (no `findings` key at all when unavailable). What D2 still demands of the
placement is that the *absence* of a finding be legible — if the panel is closed, or the check
was never run, the UI must not read as a clean bill of health.

**D3 Usability (5) — "joy to use; sensible defaults; actionable errors."**
`W-LANE-NO-OWNER`'s message is genuinely actionable. `W-XML-GW-AMBIGUOUS` on an AEF map is
not — there is nothing for the author to do about a convention difference. D3 therefore
discriminates *between rules*, not just between placements, which again points at the unused
dialect axis.

**D4 Portability (3) — "no provider/language/environment lock-in; prefer standards."**
The sidecar-HTTP choice already costs us here: the standalone `file://` build cannot validate.
T-961 made that an honest `ok:false` rather than a false green, but it is a real gap, and any
placement must degrade visibly rather than appear to pass.

### The free drivers that bear on this

| driver | weight | bearing |
|---|---|---|
| **F1 V_SDLC_ENABLEMENT** | 9 | "the yardstick driver". Findings at authoring time are upstream of every downstream gate — the cheapest place to catch a modelling error is before it becomes a governed task graph. Strongest argument for doing this at all. |
| **F3 V_AEF_INTEGRATION** | 9 | Cuts **against** aggressive placement. We are AEF's authoring surface; showing an AEF author 47 warnings about our conventions damages the integration we exist to serve. |
| **F4 V_WORKFLOW_ROUTING** | 9 | Neutral on placement. |
| **F2 V_COMPONENT_FABRIC** | 6 | Neutral. |
| **F-RECALL** | 6 | Mildly favours a placement that records what was shown and dismissed — that is recall substrate. |

### Arcs

- **arc-001 (designer as AEF's authoring surface)** — the constraint above. Its headline is
  bidirectional, so AEF-authored maps *will* be opened here.
- **arc-004 (hypothesis-first inceptions)** — every scored item carries a falsifiable claim.
  Whatever we ship should state what we expect and how we would know we were wrong. For this:
  *"we believe surfacing findings will change what authors do; we will know if dismissal rate
  per rule stays low."* That is measurable.
- **arc-005 (process instances)** / **T-956 maturity model** — strictness is earned, not
  declared. A validation surface that is strict on day one contradicts M3 ("early strictness is
  harmful, not merely premature").

---

## 4. The four options, steelmanned and strawmanned

### Option 1 — On-demand panel

> A "Check" action validates the current map and lists findings: rule id, severity, message,
> location. Nothing happens unless asked.

**Steelman.** It is the only option whose noise cost is **zero by construction**: you see
findings when you asked for them, so 47 dialect warnings on an AEF map are something you went
looking for rather than something thrown at you. That makes it the only option that is safe to
ship *before* the dialect axis is wired, which matters because wiring that axis is itself
unscoped work. It satisfies D1 by not training dismissal, D3 because the author has context
for why they asked, and F3 because an AEF author never sees our conventions unbidden. It is
reversible — a panel can later feed markers or a save prompt without being rewritten — and it
is the smallest thing that converts T-961's plumbing into something a human benefits from. It
also honours the maturity model honestly: the loosest possible coupling first, tightened later
on evidence, which is exactly M1/M3/M6.

**Strawman.** It is the placement most likely to be used once and never again. A check you must
remember to run is a check that competes with finishing, and the author who most needs it is
the one least likely to ask. It therefore risks delivering **reach on paper and nothing in
practice** — the same shape as the four dials T-956 found "turned and connected to nothing",
and the same shape as PL-161's 30-of-154 unwired guards. Its D2 story is also its weakest: a
closed panel is indistinguishable from a clean map, which is the exact conflation T-961 worked
to eliminate one layer down. And it leaves the operator's actual complaint — mistakes reaching
governed work — unaddressed, because nothing intervenes at the moment of persistence.

### Option 2 — Save-time prompt

> On save, validate. ERROR-severity findings produce one confirm that takes an override;
> warnings are listed but do not prompt.

**Steelman.** This is the most literal reading of the operator's own ruling: *friction, not a
block, with the human as final authority.* It fires at the one moment the author's intent is
unambiguous — they are declaring the map done — which is when a finding is most actionable and
least noisy. It targets the real harm: a bad map becoming a governed task graph. Precedent
exists in the same code path, so there is no new mechanism: `saveToProject()` already confirms
on the unedited starter example and already prompts for a version note. Severity-gating means
the 47 dialect warnings (all `WARN`) never prompt — the noise problem is dodged without
needing the dialect axis, because severity is already a per-rule property the validator emits.
It is also the placement that generates the cleanest evidence for arc-004: override rate per
rule at a known decision point.

**Strawman.** Friction at save is friction at the worst possible moment — the author is trying
to finish, and a prompt there is the one most likely to be click-throughed on reflex, which is
dismissal-training with extra steps (D1 harm). It also tells the author too late: a structural
error found at save may mean unwinding work done since the mistake. If `_apiAvailable` is
false, either save silently stops validating (a false green at the exact moment it matters) or
it nags about something the author cannot fix — and the `file://` build makes that a real
configuration, not a hypothetical. And "ERROR-severity only" sounds safe but is unmeasured:
our whole corpus produced **zero** errors, so this prompt has never been observed firing on a
real map, which means its noise profile is an assumption.

### Option 3 — Live gutter markers

> Findings annotated on the nodes themselves, updating as the map changes.

**Steelman.** It is the only option with a genuine feedback loop: the author sees the
consequence of a change next to the change, which is how authoring tools actually teach. It is
the strongest D3 answer and the strongest F1 answer, because error cost rises monotonically
with distance from the edit. Everything needed already exists — the validator returns a
`location` field (confirmed in T-961's leg 3), and the canvas already has badge layers
(`#g-badges`, `#g-badges-top`) from T-286/T-293. Done well it would make the designer visibly
better than hand-authoring BPMN, which is arc-001's actual promise.

**Strawman.** It is the one option that is **actively harmful to ship today**, and the number
says so: 47 of AEF's 48 gateways would carry a marker that is correct-by-their-convention.
That is L-527 decay delivered at maximum volume, into the integration F3 exists to protect,
and it cannot be severity-dodged because the dialect problem lives in `WARN`. It therefore has
a hard prerequisite — consuming `test_rule_dialect_axis.py` in the validator, currently zero
references — which is unscoped work on the critical path. It is also the most expensive and
least reversible: continuous validation means debouncing, caching, and a per-keystroke story in
an 11,941-line file, and it is the only option requiring the full visual-verification protocol
across every font/theme/density/language mode. Highest value, wrong order.

### Option 4 — Panel plus save-time prompt (1 + 2)

**Steelman.** It fixes each option's main weakness with the other's strength: the panel gives a
no-noise place to look deliberately, and the save prompt guarantees the check is not merely
available but *encountered*, which is the difference between a wired and an unwired guard. No
new mechanism beyond the two. Both halves consume the same `validateCurrentWorkflow()` result,
so the marginal cost over option 1 is small and mostly UI. It is also the configuration that
most faithfully implements the maturity model: advisory everywhere, friction at exactly one
consequential boundary, override always available.

**Strawman.** It is two placements shipped before either has been observed in use, which is
precisely the "decide once, measure never" pattern arc-004 was created to stop. It doubles the
surface that must degrade correctly when the validator is unavailable, and the save path is the
one where a false green is most costly. It also prejudges the question option 1 would answer
cheaply — *do authors use a validation surface at all?* — and if the answer is "only at save",
the panel is dead weight that still has to be maintained. "More work than either alone but no
new mechanism" undersells it: the save prompt changes a path that already has two confirms and
a mismatch guard, and that path is `saveToProject()`, which is load-bearing.

---

## 5. Where the directives land

Applying the priority order rather than summing:

- **D1 first.** Options 3 and, more weakly, 2 risk dismissal-training; the measured 47-of-48
  makes that concrete for 3 and speculative-but-plausible for 2 (mitigated by severity-gating).
  Option 1 cannot train dismissal because it shows nothing unbidden. **D1 favours 1, then 2.**
- **D2 next.** Option 1 is weakest here — a closed panel reads as a clean map. Options 2 and 4
  force an encounter. **D2 favours 2/4 over 1.** This is the real tension in the decision.
- **D3** favours 3 on quality of feedback, and discriminates between rules rather than
  placements — pointing at the dialect axis regardless of which option wins.
- **D4** is a constraint on all four: the `file://` build must degrade visibly.

D1 and D2 disagree, which is why this is a genuine decision and not an obvious one. The
tie-break the directives prescribe is **D1 wins** — so the safest sequencing is option 1 first,
with D2's objection answered not by also shipping the prompt immediately, but by making
"never checked" visibly different from "checked and clean" inside the panel.

---

## 6. My recommendation, and the hypothesis it carries

**Option 1 now, option 2 next, option 3 only after the dialect axis is consumed.**

Not because option 1 is best — option 4 is probably the better end state — but because option 1
is the only one that ships without a prerequisite and generates the evidence that would settle
options 2 and 3. Per arc-004, stated falsifiably:

> **We believe** an on-demand panel will be used on real maps and will change what authors do.
> **We will know we were wrong if**, after N sessions, the panel is opened rarely, or the
> dismissal rate for any single rule exceeds the rate at which findings are acted on.
> **Both are countable** without new instrumentation beyond logging what was shown.

And the one thing I would build into option 1 that is not obvious: **make "not yet checked" a
distinct state in the panel**, never an empty list. T-961 made that distinction true at the
function boundary; it must survive to the pixels, or the whole point is lost one layer up.

**What I would not do under any option:** wire rule applicability to `kind` or build the
maturity ladder. Those are T-956's open questions and they are the operator's.

---

## 7. Dialogue log

- **Operator, 2026-10-01:** *"Can you give me a little bit more background and context and map
  this against our project's purpose and objectives and steelman and strawman each option."*
- **Response:** this document. It changed two of my own prior claims in the process — the BVP
  ranking's authority (§0a) and the parity count (§0b) — and the measurement that moved the
  recommendation from "option 1 because it is cheapest" to "option 1 because D1 beats D2 in a
  genuine conflict" is the 47-of-48 figure read against arc-001's bidirectional headline.
- **Open, and the operator's:** the decision itself; T-956's four maturity questions; whether
  arc-004's hypothesis above is the one worth committing to.
