# T-1073 — Ring20 T-2250 Orchestration Concept: Round-2 Review and Reuse List

**Date:** 2026-10-06 · **From:** 832 Workflow Designer review panel · **To:** ring20-manager T-2250 orchestration initiative  
**Task:** Provide ROUND-2 review of concept v0.3, focusing on designer-facing gaps (5R.5) and the reuse list (5G) with paths to 832's existing mechanisms.

**Scope:** This review addresses sections 4R (concept v0.3), 5R (round-2 questions), 5G (reuse question), and 5B (round-1 feedback from three-vendor review).

---

## §1 Round-2 Items: Concept v0.3 Gaps and Designer Implications

### 1.1 Per-Step Worker Selection and Lane Authority — Severity: **SHOULD**

**Section 4R.1–4R.5, especially 4R.5 (per-step routing)**

Your concept states "based on that we can make a routing decision to the type of agents" where "based on that" refers to step properties (4R.2, lifecycle, binding, data class). This is sound. **Gap: the relationship between per-step routing rules and lane authority (pools/swimlanes in BPMN) is unspecified.**

In 832, this settled as: **authority (who may act) lives on the box/step; the lane is a partition whose meaning is declared by the modeller** (T-685:1056–1077; T-888 operator ruling §2.3). The box carries `aef:meta authority=` and `aef:meta tier=` (per action); the lane carries its declared meaning (e.g., customer domain, Tier-0 review, etc.). A routing decision ("send to a coder agent on Claude Opus") is an **attribute of the step**, not the lane.

**What you need:** specify whether per-step worker selection lives in a commission-attribute (on the task element), in a lane property (all steps in this band use this worker pool), or in the registry binding (the capability entry itself pre-selects which workers are eligible). Each choice has different scaling and governance implications. If it's step-level, you'll need an aef: equivalent of your `binding` extension, or you'll face the same lane-overloading defect 832 diagnosed in T-685.

**Change wanted:** State one of:
- **(a)** Per-step binding (routing in the step attributes) — maps to our `aef:meta agentType=` + extension for model/worker selection.
- **(b)** Lane-level binding (all steps in this actor band delegate to this pool) — map it to a lane attribute and state it is orthogonal to authority.
- **(c)** Registry entry binding (the capability manifest itself names eligible workers) — clarify whether that is template-time or instance-time selection.

---

### 1.2 Template vs Instance Binding — Severity: **SHOULD**

**Section 4R.2, 4R.4 (commission binding)**

Your commission binding—lifetime (one-shot vs standing), data class, credentials—appears to be evaluated at **instance time** (you commission worker X for task T against template W). 832 separates this explicitly:

- **Template level** (`kind="work-plan"`): declared intention (this step expects a coder), reference to capability version.
- **Instance level** (`kind="instance"` + task ref): actual worker assignment (coder-1 was provisioned for this run), context, actual handback.

Your v0.3 talks about "registering with a stable agent identity" (4.4.1) and "liveness that proves the agent process" (4.4.2)—both instance-side—but §4R.2 "the capability body = the arc-008 portable card" mixes the template (the card definition) with the instance (which actual worker got spun up). They are the same object in your schema, which is a problem when you need to re-run a step with a different worker, or when one worker crashes mid-run.

**Change wanted:** Separate `capability_template_ref` (pinned to content_sha at composition time) from `commissioned_worker_identity` (established at instance execution). The instance record keeps both; a re-run re-commissions without changing the template.

**See also:** 832's template-binding.yaml (examples/aef-processes/) shows the join pattern.

---

### 1.3 Deterministic-First Execution with Stochastic Fallback — Severity: **SHOULD**

**Everywhere (general missing principle)**

Your §4R.1–4R.6 describes orchestration, but does not specify **executor kind** — whether a step is meant to run deterministically (a script, a validated procedure) or stochastically (an agent makes a judgment call). This is load-bearing for two reasons:

1. **Evidence semantics differ.** A deterministic step's evidence is "input + code + output, reproducible any time"; a stochastic step's evidence is "the actual decision made, because re-running produces a different answer." A log that does not distinguish them is mixing two evidence regimes.

2. **Fallback routing.** The operator's principle (T-685:502–504, T-1072:2.3): *"we want to go very much to deterministic execution… However we do want to fall back on stochastic if it goes wrong, or is an error, or an edge case, or on unclarity."* A supervisor needs to know: is this step supposed to be deterministic with a fallback handler, or stochastic with a deterministic guard?

832 treats this as a first-class **executor kind attribute** on the step (and as a **maturity ladder**—deterministic is the goal, stochastic is the way you get there while discovering the procedure). Your commission does not carry it.

**Change wanted:** Add `executor_kind: deterministic | stochastic | human` to the commission or capability binding, with a note on maturity: this starts stochastic, promoted to deterministic once evidence of safety accrues (T-956:523–534).

---

### 1.4 Risk-Based Tiering and the Exception Hatch — Severity: **SHOULD** (governance-critical)

**Section 4R.4 (supervisor-enforced bounds), 4R.5 (failure rules), §5F operator rulings**

Your v0.3 treats supervisor refusal as terminal ("never re-requested in the same round"). The 832 operator ruled (T-956:47-50): **"advisory plus friction, never a hard block. I want to be the final authority. There should always be an exception hatch."** This is M7 — even a locked, production process keeps an escape route.

Your concept has the structure for this—Tier 0 → operator approval exists—but does not state whether the operator can override a supervisor refusal. Per §5F.2.a/b/c/d/e/f you route on credentials and risk, but "refused by the gate" (4R.4.3) reads terminal.

**Change wanted:** Clarify that supervisor refusals go to the operator (Tier 0) and the operator always has override authority, with the action logged (T-956 model: "advisory plus friction, not refusal-with-no-appeal"). State this explicitly in 4R.4.3 or 5F to match your three-vendor feedback (5B.1.3 "default one-shot; standing after evidence; the hatch never closes" implicit in the operator rulings).

---

### 1.5 Worker Identity and Liveness Semantics — Severity: **NICE**

**Section 4.4 (standing workers), 4R.6**

You define standing worker liveness as "an acknowledgement tied to the commission id, not merely a launched process" (4.3, 4R.4.1, 5B.1.3). Clear. But you do not specify how you distinguish:

- A worker that was commissioned but never started (launch failed, no ack received).
- A worker that acknowledged but then crashed.
- A worker that acknowledged and is processing (in-flight, no handback yet).
- A worker that acknowledged but became unreachable (network partition).

832's operator-command tooling (runme-launcher.sh + runme-signal.sh + runme-watch.sh) implements this for task-granular work: every transition (STARTED → STEP / DONE / STOPPED) is timestamped and logged; a signal loss means "watcher died, re-arm the monitor"; a STOPPED event without a DONE means "the worker exited with a failure, review the log."

Your standing-worker registry and commission ledger are the right carriers, but your v0.3 does not name the state machine. You have "start, collect, request review" as the exempt set (4R.4.2), but not the step transitions a supervisor needs to count.

**Change wanted:** Sketch the worker state machine (commissioned → acknowledged → running → completed/failed/lost) and when the supervisor moves from one state to the next. TermLink's peer-agent discovery (how 832's agents find each other) uses a heartbeat-based liveness model; the section heading "S-3 or later, not S-1" (4R.6) suggests you're deferring this, which is fine—but say so.

---

## §2 Reuse List: What 832 Already Has (with Paths)

ring20 asked (5G): *"what does 832 ALREADY have that you should reuse, piggyback on or extend, for routes, worker identity, worker/agent catalogues, instance tracking, or per-step worker selection — list mechanisms WITH PATHS."*

Each row below was checked against the file it cites (2026-10-06). Equally useful for your design, what 832 does **NOT** have: the designer carries "No action catalogue, execution profile, capability profile, or secret binding" (`docs/research/executable-workflow/designer-contract-inventory.md:275`), no per-step data-class marking, and Tier 3 pre-approval is spec-only (`CLAUDE.md`, Enforcement Tiers). Those are open space for your registry, not something to reuse.

| Mechanism | 832 Path | What It Gives You | Caveats / Integration Notes |
|-----------|----------|-------------------|---------------------------|
| **Executor Kind (deterministic/stochastic)** | `docs/reports/T-685-lane-semantics-authority-vs-domain.md:312-354` | A vocabulary and reasoning for distinguishing step execution modes. Includes evidence semantics (reproducible vs perishable), fallback routing (escalation ladder), and maturity-promotion rules. | Designer-facing in `src/aef-workflow-designer.html` (agentType attribute currently has `primary` \| `framework` \| `coder` \| `any`; expansion needed for your agent taxonomy). Not yet wired to supervision logic. |
| **Risk-Based Tiering** | `docs/reports/T-956-process-maturity-model.md:1-158` + `CLAUDE.md:Enforcement Tiers` | Four-tier risk model (0=consequential, 1=standard, 2=situational auth, 3=pre-approved). Evidence-driven promotion ladder (tier rises on incident, lowers only on guard-pass evidence). "The hatch never closes"—operator override always possible. Integrated with task system. | Full implemented on the 832 side; integrates with task.yaml `tier:` field. Your §4R.4.3 "refuses" maps to Tier-0-candidates; your pre-approval cache maps to Tier-3 pre-approved activities. |
| **Per-Step Worker/Model Routing** | `docs/reports/T-685-lane-semantics-authority-vs-domain.md:474-488`, `docs/reports/T-1072-objectives-sources.md:§2.3` | The operator's ruling: routing decisions (which agent type, which model) "captured in a workflow element" as `aef:meta agentType=` and a proposed model-type field. | Currently `agentType` is in the designer (`src/aef-workflow-designer.html` grep `agentType`), but supervision/dispatch side is not yet built. This is exactly your per-step commission binding. Ring20 can build the dispatch on the supervisor side and we can align schema. |
| **Template vs Instance Tracking** | `examples/aef-processes/template-binding.yaml` + `.agentic-framework/lib/instance-position.sh` + `docs/research/executable-workflow/handoff-ewcr-v1-designer-fixture.yaml:§2.1` | A join pattern: template (the work-plan BPMN, pinned to SHA) + instance (task id + node position). Instance registry tracks which template version is active, what node a task is on, whether a human gate has been passed. Re-runs inherit the template, update instance state. | Integrated with `fw bpmn promote` (makes a template immutable, creates an instance binding). Seam is documented in `docs/standards/aef-bpmn-mapping-v1.md`. Your commission ledger should reference template_sha + instance_id this way. |
| **Operator Commands with Per-Step Gates** | `tools/runme-launcher.sh` + `tools/runme-signal.sh` + `tools/runme-watch.sh` | A three-part execution model: (1) dry-run with hash binding (`dryrun.ok`), (2) per-step `y/N` gate, (3) signal log (START, step, DONE, STOPPED). The step transitions are the supervisor's ledger. Re-arming a watcher restarts monitoring when a signal is lost; logging is immutable. | This is **operator-command work**, not agent-initiated. Your commission lifecycle + supervisor can follow this shape exactly: dry-run the commission, gate on the operator's y/N, record each step's signal. The ledger (`run-<ts>.log` beside the job) is your audit trail. |
| **Authority as a Box Property** | `docs/reports/T-685-lane-semantics-authority-vs-domain.md:1056–1077` + `docs/standards/aef-bpmn-mapping-v1.md:§3` | The operator's decision: authority (tier + owner) lives on the step/box, not on the lane. Lane is a partition (its meaning modeller-declared). Moving a box to another lane does not change who is accountable. | In the designer: `aef:meta tier=` + `aef:meta owner=` (derived from lane, cannot be overridden on the box itself—deviation is a design discussion worth having with your team). Supervisor can read tier from the step, not from lane position. |
| **Dry-Run with Hash Binding** | `tools/runme-launcher.sh`, `.context/runme/<NNN>-<name>/dryrun.ok` | A preflight check (dry-run) produces a SHA-256 of the job. Execution is refused if the job changed since dry-run. Any edit requires a new dry-run. This prevents "the config I checked is not the config that ran" attacks. | Your commission (before execution) should hash the template + registry entries + credentials and refuse to execute if any changed. This is your "versioning" problem solved: the dry-run hash is the immutability anchor. |
| **Contingent Authority** | `docs/reports/T-685-lane-semantics-authority-vs-domain.md:570–603` + `CLAUDE.md:Enforcement Tiers` + `docs/reports/T-888-authority-ruling.md` | Authority can be **contingent on the step's properties**: a step that fails its guard, or exceeds its tier, or outputs data above its class, escalates to a higher-authority actor (human, then another agent type). The escalation is the five-rung error ladder (redirect, analyse-in-place, fix-and-capture, forward, escalate-to-human). | This maps to your supervisor (4.6, 5B feedback) / review ladder (5B.2.3 "three review / remediation rounds"). The cascade from one agent to another is deterministic if each rung knows its audience and guard. |

---

## §3 Open Questions Back to Ring20

Before ring20's v0.4, these clarifications would help 832's integration planning:

### Q1. Worker Identity Lifecycle in Standing Mode

You defer standing workers to S-3+ (§4R.6, "not S-1"). But your v0.3 introduces "stable agent identity" and "liveness that proves the agent process, not merely a launched process" (4.3, 4.4.1/4.4.2). 

**Question:** In S-1 (one-shot workers only), you avoid the identity/liveness complexity entirely. But then how does the supervisor prove a one-shot commission started? Is it the sole receipt of the ack with the commission_id, or do you also require some form of heartbeat / alive signal before counting the commission as "verified started" (4.3, before the worker hands back)?

**Why this matters:** 832's operator-command tooling treats ack-receipt as "started", then watches for signal events. If ring20 needs something stronger (e.g., a handshake), the supervisor's liveness guard differs. Clarifying S-1's liveness gate helps designers know when a commission is safe to count.

---

### Q2. Registry Entry Versioning and Re-Commission

Your §4R.2 "registry entry = arc-001 manifest + four extensions" and §4R.7 "Registry growth without self-expansion". But if a registry entry is updated (e.g., a capability's credential_gate changes from `read` to `write`, or a new dependency is added), **what happens to in-flight commissions?**

**Question:** Does a commission keep the old entry version (pinned at commission time), or does it re-evaluate the registry on each step? If a commissioned capability is withdrawn (`deprecated_after` reached), does an in-flight instance fail, or does it have a grace period?

**Why this matters:** This is exactly the template-instance binding problem (Q1.2 above). Pinning the capability_sha at commission time prevents config drift during execution, but requires documenting the pin strategy. 832 uses content_sha for all immutable artifacts; adopting the same may simplify cross-project handoff.

---

### Q3. Deterministic-First Execution and Worker Selection Asymmetry

The operator's principle (T-685:502–504, your adoption in §5) is: deterministic first, stochastic fallback. But **worker assignment may not follow the same asymmetry.**

**Question:** If a step is deterministic (a validated procedure / script), must the worker be deterministic too (a machine / rule-based agent), or can a deterministic step use a stochastic worker as long as the worker's output is validated before accepting? Conversely, can a stochastic step (an exploratory agent decision) use a deterministic worker (a validation check)?

**Why this matters:** This affects your commission binding and supervisor guards. If executor_kind and worker_kind must always align, your routing is simpler. If they are orthogonal (executor-kind says "this step's logic", worker-kind says "this worker's nature"), your routing is more flexible but guards are more complex. A sentence clarifying the intended relationship would help.

---

**End of review.** 

Ring20's v0.3 is well-structured and reflects good understanding of the three-vendor feedback (§5B). The gaps above are not defects—they are design choices that benefit from explicit statement before S-1 code writes to them.

832 is ready to align on shared mechanisms (pre-approval, tiering, per-step routing, template-instance binding) and to contribute the aef: carrier vocabulary if your commission envelope adopts compatible schema.

---

**Sources consulted:**
- `docs/reports/T-685-lane-semantics-authority-vs-domain.md` (authority, executor kind, fallback routing)
- `docs/reports/T-956-process-maturity-model.md` (tiering, exception hatch, evidence semantics)
- `docs/reports/T-1072-objectives-sources.md` (operator vision summary)
- `docs/standards/aef-bpmn-mapping-v1.md` (frozen Part I contract)
- `docs/research/executable-workflow/designer-contract-inventory.md` (capability registry, data class)
- `tools/runme-launcher.sh`, `tools/runme-signal.sh`, `tools/runme-watch.sh` (operator command orchestration)
- `examples/aef-processes/template-binding.yaml` (template-instance join pattern)
