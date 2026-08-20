---
id: T-572
name: "meta-parity guard checks a subset, not parity: 9 bridge keys the editor never named stayed green"
description: >
  tests/test_editor_bridge_meta_parity.py asserts ONE direction: check(editor_keys, bridge_keys) returns editor keys missing from the bridge, and the self-test at :94 confirms that is the only case it flags. Measured with the test's own extractors: editor metaKeys = 20, bridge META_KEYS = 29, and 9 keys the bridge EMITS were absent from the editor's export whitelist -- determinism, authority, endpoint, sideEffect, autoTriggerKind, restoresFrom, compensationSnapshot, compensatedBy, advisory. check() returns [] on that, so the guard has been green for the entire period in which opening a bridge-produced map in the editor and saving it destroyed up to 9 keys (T-570 measured and fixed the destruction; this task is about the guard that should have reported it). The file is NAMED parity and its assertion is SUBSET. That is the week's recurring shape once more -- a stated property standing in for a checked one, with the gap rendering as green. Note the fix is NOT simply 'assert equality': the two lists legitimately differ, because the editor now carries unlisted scalars generically rather than by name (T-570 src:9550) while the bridge enumerates its vocabulary. The guard has to assert the property that actually matters -- every key the bridge can emit survives an editor round trip -- which is a ROUND-TRIP assertion, not a set comparison, and should be measured against the editor rather than against its source text.

status: started-work
workflow_type: build
owner: agent
horizon: now
tags: [bug, designer, test-guard]
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-20T17:06:18Z
last_update: 2026-08-20T17:55:08Z
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

# T-572: meta-parity guard checks a subset, not parity: 9 bridge keys the editor never named stayed green

## Context

`tests/test_editor_bridge_meta_parity.py` guards the `<aef:meta>` scalar-attribute channel
across the JS↔Python seam. It asserts `editor_metaKeys ⊆ bridge_META_KEYS` and nothing else.

**The docstring does not merely omit the reverse direction — it argues the reverse direction
is safe, and the argument is wrong.** Lines 24-27, verbatim:

> `(⊆, not ==: the bridge legitimately emits more keys than the editor authors, e.g.`
> `determinism/endpoint/sideEffect; those flow bridge→editor via the generic absorption,`
> `so the reverse direction is not a data-loss risk.)`

"Not a data-loss risk" is a claim about a **round trip**. It was checked against the **read**
side alone. Import IS generic (src:10255, absorbs every attribute) — that half is true and
verifiable by reading the source. Export was NOT: it filtered through a 20-key whitelist
(src:9502 pre-T-570). A key was absorbed on load and destroyed on save, and the docstring
named three of the nine keys this happened to — `determinism`, `endpoint`, `sideEffect` —
as its examples of why it was safe.

Measured with the test's own extractors: editor 20, bridge 29, **9 bridge keys outside the
editor's export whitelist**: advisory, authority, autoTriggerKind, compensatedBy,
compensationSnapshot, determinism, endpoint, restoresFrom, sideEffect. `check()` returns `[]`
on that input. The guard was green for the entire period.

T-570 fixed the destruction (export now carries any scalar no other emitter claims).
**This task is about the guard, and the guard is still not checking the property.** T-570's
carriage is what makes the docstring's claim true today, and nothing holds it that way — revert
the carriage and this file goes green again while nine keys die. PL-034: a guard that checks
internal self-consistency cannot detect a broken promise.

The repair is NOT `assert equality`. The two lists now legitimately differ: the editor carries
unlisted scalars **generically** while the bridge **enumerates** its vocabulary, so `==` would
be a false constraint that forces every bridge key onto `metaKeys` for no reason. The property
that matters is a round trip — every key the bridge can emit survives editor load→save — and
it must be measured against the **editor's behaviour**, not against its source text.

**The fixture is DERIVED from `META_KEYS` at run time, not hand-written.** That is the load-
bearing design choice and it is the direct lesson of T-570: a census over what our corpus
happens to carry measures the sample; the producer's vocabulary is the population. A hand-
written fixture pins today's 29 keys and is silent on the 30th. Deriving it means the guard
covers a new bridge key the moment someone adds one, without anyone remembering to.

**Not assumed — to be measured:** some bridge keys are legitimately DERIVED or STRUCTURAL on
the editor side (T-197: `owner` comes from lane authority; `gatewayKind`/`scopeOf` are
structural), and `endpoint` round-trips as an ELEMENT rather than a meta attribute (T-570).
So "survives" cannot mean "comes back as a meta attribute". The exact survival channel per key
is established by running the round trip BEFORE the guard's assertion is written, and any key
that legitimately does not round-trip verbatim must be declared with its reason in the guard
itself — a silent exclusion list is the shape this task exists to remove.

## Acceptance Criteria

### Agent
- [x] A round-trip guard exists that derives its fixture keys from the bridge's `META_KEYS`
      at run time (reusing the parity test's own extractor, not a second regex), so adding a
      key to `META_KEYS` extends the guard's coverage with no other edit.
      → `tools/_t572-bridge-vocabulary-roundtrip-cdp.mjs` imports `bridge_meta_keys` from the
      parity test via `importlib`; 29 keys derived. Mutant B proves it dynamically.
- [x] The guard drives a REAL editor load→export→re-parse (CDP, headless Chromium) and asserts
      per-key survival against the exported document — not against `src/*.html` source text.
- [x] Survival channel per key is MEASURED before the assertion is written, and every key that
      does not round-trip verbatim is named in the guard with the reason it is exempt
      (derived / structural / different channel). No silent exclusions.
      → Measured over 29 keys × 15 fixture nodes × 10 distinct editor types **before** the
      assertion was written: 0 lost, 0 value changes. `EXEMPT` is empty and leg 6 asserts it.
      The measurement also settled the channel question: `endpoint` migrates to `<aef:endpoint>`
      and still lands on `node.aef` after re-parse, so the assertion is made on the re-parsed
      model, channel-agnostic. Asserting "comes back as a meta attribute" would have reported a
      defect that is not there.
- [x] Values are checked, not just key presence: at least one carried key holds a hostile value
      (ampersand, angle bracket, quote, newline) and comes back byte-identical.
- [x] A control arm runs first on unmutated source and must be green — "every mutant died" is
      equally satisfied by a harness that fails on everything (T-560). Plus leg 2 in the probe
      itself: the pre-T-570 rule reproduced in-page must LOSE 9 keys the shipped path keeps.
- [x] Mutation teeth: reverting T-570's carriage in a tmpdir copy MUST redden the new guard.
      This is the whole point — the old guard stayed green under exactly that condition.
      → Mutant A: 8 keys lost, 3 legs red. The ⊆ guard is green on that same source.
- [x] Teeth discriminate: each mutant reddens exactly its own legs, and a mutant reddening more
      than its own legs is reported as a failure, not accepted.
      → And the LOST-KEY SET is asserted too, because B and C redden identical legs and are
      separable only by which key died (`zzUnseenKey` vs `advisory`).
- [x] The false claim in `test_editor_bridge_meta_parity.py`'s docstring is corrected in place
      and points at what now checks it — the claim is discharged by a guard, not re-worded.
- [x] The existing subset assertion (editor→bridge) is PRESERVED and still green; it guards a
      real and different risk and is not replaced by the round trip.
- [x] The new guard is wired into `tests/run-bridge-tests.sh` in the SAME commit (T-568: a tool
      called only from a task's `## Verification

# The guard itself: 6 legs in headless Chromium, fixture derived from the bridge's META_KEYS.
node tools/_t572-bridge-vocabulary-roundtrip-cdp.mjs
# Control run first, then 3 mutants; each must redden exactly its own legs AND lose exactly its own keys.
python3 tools/_t572-bridge-vocabulary-teeth.py
# The subset half is PRESERVED, not replaced — it guards a real and different direction.
python3 tests/test_editor_bridge_meta_parity.py
python3 tests/test_editor_bridge_structured_parity.py
# T-570's carriage is what makes the round trip pass; if it regresses, say so here too.
node tools/_t570-meta-carriage-cdp.mjs
# Positive counts, not absence assertions (T-560): "the false claim is gone" passes just as
# readily when the pattern is mis-quoted. Assert what must be PRESENT instead — the corrected
# docstring names the probe that discharges it, and the probe derives keys through the parity
# test's extractor rather than a second regex that could drift from it.
python3 -c "import sys;d=open('tests/test_editor_bridge_meta_parity.py',encoding='utf-8').read();p=open('tools/_t572-bridge-vocabulary-roundtrip-cdp.mjs',encoding='utf-8').read();sys.exit(0 if d.count('_t572-bridge-vocabulary-roundtrip-cdp.mjs')==1 and 'PL-034' in d and p.count('bridge_meta_keys')==1 and p.count('test_editor_bridge_meta_parity.py')==2 else 1)"
# The teeth are WIRED into the suite, not merely present on disk (T-568): a tool called only
# from this block becomes an unwired guard the moment this task completes.
python3 -c "import sys;s=open('tests/run-bridge-tests.sh',encoding='utf-8').read();sys.exit(0 if s.count('_t572-bridge-vocabulary-teeth.py')==3 else 1)"
# The gap is registered and its closure check RUNS (a trigger that errors is not a trigger).
python3 -c "import yaml,subprocess,sys;d=yaml.safe_load(open('.context/project/concerns.yaml',encoding='utf-8'));c=d['concerns'] if isinstance(d,dict) and 'concerns' in d else d;g=[x for x in c if x['id']=='G-041'];sys.exit(0 if g and subprocess.run(['bash','-c',g[0]['closure_check_command']],capture_output=True).returncode==0 else 1)"
# The suite is the leg, with a floor — "0 failed" is also what deleting legs produces.
bash tests/run-bridge-tests.sh > /tmp/.t572-suite.out 2>&1 && python3 -c "import re,sys;m=re.search(r'bridge round-trip: (\d+) passed, (\d+) failed',open('/tmp/.t572-suite.out').read());sys.exit(0 if m and int(m.group(1))>=125 and int(m.group(2))==0 else 1)"

## RCA

**Symptom:** `tests/test_editor_bridge_meta_parity.py` returned `[]` — green — for 47 days
(added 2026-07-04 `2baf13ce`) while the editor destroyed nine keys the bridge emits on every
save. T-570 found the destruction by other means; this file, the one guard named for that
seam, never reported it and could not have.

**Measured, not reasoned.** Editor `metaKeys` = 20, bridge `META_KEYS` = 29, using the test's
own extractors. `check(editor, bridge)` returns editor keys missing from the bridge; the
self-test at :94 confirms that is the only case it flags. The nine keys sit in the other
direction, so the function was working exactly as written and the answer was `[]`.

**Root cause — not "the test was too narrow".** A narrow guard with no claim invites the next
person to widen it. This guard's docstring carried a written argument for its own sufficiency:

> `those flow bridge→editor via the generic absorption, so the reverse direction is not a`
> `data-loss risk`

"Not a data-loss risk" is a claim about a **round trip**, and it was checked against the
**read** side alone. Import is generic (src:10255) — true, and verifiable by reading the
source, which is presumably how it was verified. Export was not: it filtered through a 20-key
whitelist. Half a round trip read from source, stated as a property of the whole. The sentence
then named `determinism`, `endpoint` and `sideEffect` as its examples — three of the nine
casualties. Anyone who came to this file to ask "is the other direction covered?" found a
reasoned "no need", and stopped.

**Why structurally allowed.** Nothing evaluates a guard's prose. A docstring is where a reader
goes to learn what is covered, and it is the one part of a test that no test runs. The claim
was made in good faith, was true of the mechanism the author was looking at, and became false
at a distance — in a different file, in a different language, on the write side.

**Prevention (distinct from the fix).** The fix is `tools/_t572-bridge-vocabulary-roundtrip-cdp.mjs`:
the property is now evaluated rather than asserted, on a fixture DERIVED from `META_KEYS` at
run time, driving a real load→export→re-parse. Mutant A reproduces the exact state the old
guard called green and the new one reddens. But that repairs one seam and leaves every other
guard's prose unexamined, so the blindness is registered as **G-041**, whose closure trigger
explicitly refuses this task's probe, this docstring correction, and a "don't write unchecked
claims" convention as closure — the author believed the claim, so a rule against writing it
does not detect the next one.

**Not fixed here.** Whether any carried key is promoted INTO the frozen v1 contract remains the
operator's ruling (unchanged from T-570). `tools/_t364-x-tie-census.py` matched G-041's
reassurance-prose census and is unexamined — a lead, not a finding, and not this task's scope.

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

### 2026-08-20 — Round trip, not set equality
- **Chose:** Assert that every key the bridge can emit survives an editor load→export→re-parse,
  measured in the page. Left the `⊆` assertion in place alongside it.
- **Why:** The two whitelists now legitimately differ — the editor carries unlisted scalars
  *generically* (T-570) while the bridge *enumerates* its vocabulary. The property that matters
  is survival, and survival is behaviour.
- **Rejected:** `assert editor_keys == bridge_keys`. It is the obvious repair and it is a false
  constraint: it would force all 29 bridge keys onto `metaKeys` to go green, changing the
  editor's authoring surface to satisfy a test. It also still would not check a round trip —
  it would be a second set comparison standing in for one, which is the shape being removed.
- **Rejected:** replacing the `⊆` test. It guards a real and opposite risk (an editor-authored
  key the bridge drops on YAML→BPMN) that the round trip does not cover.

### 2026-08-20 — The fixture is derived from the producer, not written by hand
- **Chose:** Read `META_KEYS` from `tools/yaml-to-bpmn.py` at run time, through the parity
  test's own `bridge_meta_keys` extractor, and generate the fixture from whatever comes back.
- **Why:** The direct lesson of T-570 — a census over what the corpus happens to carry measures
  the SAMPLE; the producer's vocabulary is the POPULATION. A hand-written fixture pins today's
  29 keys and is silent on the 30th, which is how a guard goes stale without anyone noticing.
  Mutant B is the tooth: it appends a key that appears nowhere in the probe and requires the
  guard to lose exactly that key.
- **Rejected:** a second regex in the probe. Two extractors can drift into disagreeing about
  what the bridge's vocabulary IS while both claiming to check whether it survives.

### 2026-08-20 — Measured the survival channel before writing the assertion
- **Chose:** Run the round trip first — 29 keys × 15 fixture nodes × 10 distinct editor types —
  and let the result decide the assertion. Result: 0 lost, 0 changed, so `EXEMPT` is empty and
  the assertion is made on `node.aef` after re-parse, channel-agnostic.
- **Why:** The obvious assertion, "every bridge key comes back as an `<aef:meta>` attribute",
  is false for `endpoint`, which migrates to its own element and is not lost. Writing it first
  would have produced a guard reporting a defect that is not there — the same error T-570's
  first census made, and the same one my own teeth then made (expected 9 lost under mutant A,
  measured 8, `endpoint` again).
- **Rejected:** a silent exclusion filter. That is precisely the shape this task removes, so
  exemptions live in a named `EXEMPT` map with a reason string, and leg 6 asserts every entry
  carries one. It is empty today and the leg says so out loud.

### 2026-08-20 — Registered the blindness as a gap rather than closing on the fix
- **Chose:** G-041, severity high, with a closure trigger that names this task's own probe and
  docstring correction as explicitly NOT closure.
- **Why:** G-019 — mitigation is not prevention. 47 days blind is past the 7-day threshold, and
  six tasks committed on 2026-08-20 (T-562, T-566, T-568, T-569, T-570, T-572) share the shape.
- **Rejected:** folding it into G-023 (an agent citing a gate beyond its scope) or G-034
  (zero-population blindness). Both are adjacent; neither covers an artifact carrying its own
  false reassurance in the place a reader goes to find out what is covered.

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-08-20T17:06:18Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-572-meta-parity-guard-checks-a-subset-not-pa.md
- **Context:** Initial task creation

### 2026-08-20T17:55:08Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
