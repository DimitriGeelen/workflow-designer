# T-055 — Friction-dry analysis: task-gate (Tier-1 / P-002 nothing-without-a-task)

**Subject:** `examples/aef-processes/task-gate.workflow.yaml`
**Ground truth:** `.agentic-framework/agents/context/check-active-task.sh` (PreToolUse hook, 610 L)
**Method:** friction-dry — map a real AEF process with the Workflow Designer schema and record
where the schema strained, where known frictions recurred, and where they sharpened.
Dogfood mapping #17 — first of the four "constitutional gate" maps identified by the T-054
coverage audit.

## Verdict

**Schema expressivity: all constructs available, 0 blocking gaps.** The task gate mapped
faithfully across the three authority lanes: agent tool-call → hook intercept → exempt/safe
gate → active-task gate → readiness gate → allow/block, with the sovereignty Tier-2 override in
the Human lane and the remediation loop in the Agent lane. Geometry gate clean on first author;
bridge round-trip validated clean; the map's own `decisionOutputs` / `contextReads` /
`artifactsWrites` / `io` survived the bridge (dogfooding the T-053 + T-059 fixes end-to-end —
pre-fix this map would have lost 8 field instances). Two recurrences sharpened; one new
rendering-side friction surfaced.

## New candidate frictions

### FC-8 — the remediation loop crosses a process boundary  ⭐ headline
The Agent-lane loop `Block (exit 2) → Create task → Write ACs → re-issue → (start)` is drawn as
an ordinary in-pool cycle. But it is not one process instance looping — the hook **already
returned exit 2 and terminated**. "Re-issue" is a *new* tool call that re-enters the hook from
the top. So the visible cycle actually stitches together (a) a terminated framework
process-instance, (b) out-of-band agent remediation, and (c) a fresh process-instance. Same
shape-class as T-049 FC-7 (a terminal that hands to a different process), but here the "other
process" is **the same process, a new instance** — the loop is temporal, not control-flow.
**Why it matters:** a reader sees a self-healing cycle; the reality is block-terminate-then-retry.
The schema (single pool, sequence flow) cannot mark "this edge is a re-entry, not a continuation."
**Recommendation:** first corpus instance of a re-entry loop — register, don't build (PD-002).
A future `aef.reentry: true` edge annotation (or a link-event pair) could carry it.

### FC-9 — edge-label collision at converging gateways (rendering, editor-side)
Visual verification (screenshot, READ) showed the three adjacent Framework-lane gateways
(`exempt?` / `active?` / `ready?`) with their branch labels — "modifies source", "no active
task (P-002)", "captured / completed / placeholder ACs (G-020)", "active task in focus" —
**overlapping** in the dense middle band. The diagram stays legible but the labels crowd. This
is an *editor rendering* friction (edge-label placement / collision avoidance), distinct from
schema expressivity — the first map dense enough with labeled branches to expose it.
**Recommendation:** candidate editor enhancement (edge-label offset / collision nudge). Register
as a product observation; do not gate this map on it. Widening horizontal gateway spacing is the
authoring-side mitigation used here.

## Recurrences

### Ambient guard rendered as a flow (recurs: tier0-escalation F11)
Like Tier-0, the task gate is an **ambient interceptor** — it fires on *every* Write/Edit/Bash,
not as a step inside one authored workflow. Rendering it with a single `startEvent` ("Agent
attempts Write/Edit/Bash") implies a bounded flow; in truth it is cross-cutting middleware. F11
now recurs 2/2 for enforcement-hook maps. The lane authority model carries the intent, but the
"ambient, not invoked" nature lives only in the header comment.

### Tier-graded bypass on a plain gateway (recurs: T-049 "Tier-2-bypassable hard gate")
Both the drift branch (`g_active → Authorise Tier-2 bypass`) and the block paths are escapable
via human authorization (`FW_SWITCH_FOCUS=1` / `FW_SAFE_MODE=1`), logged Tier-2. The schema draws
plain `exclusiveGateway`s; the "who may override, at what tier" axis is carried only in labels
and the Human-lane node. Reinforces the standing `aef.bypass` candidate (an override-authority
axis on gateways). Now seen 2×.

### Decision cascade collapsed for readability (modeling choice, not a gap)
The real hook is ~8 sequential guards (safe-mode, exempt, B-005 settings-protection,
session-stamp, focus-drift, active/status, onboarding, inception, G-020). The schema *can*
express all eight as a gateway chain; this map deliberately collapses them to three
(`exempt?` / `active?` / `ready?`) for readability, folding status+ACs into "ready?" and
session-stamp+drift into "active?". Faithful-granularity vs. legibility is a standing authoring
tension, not a schema limitation — noted so the collapse is a recorded decision, not a silent
omission.

## Outcome

Map committed to the corpus (21/21 suite, geometry sweep 17 clean). FC-8 (re-entry loop) is the
strongest new candidate and the first of its kind; FC-9 is an editor-product observation worth a
follow-up. No schema change warranted (PD-002 holds: register candidates, don't build).
