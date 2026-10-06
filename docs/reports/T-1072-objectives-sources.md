# T-1072 — Sources for the project objectives: the operator's own words, and where the draft departs from them

**Task:** T-1072 · **Written:** 2026-10-06 · **Draft under review:** `.context/project/objectives.yaml` (T-986)
**Method:** read-only. Every quote below is copied from the file and line cited. Where the repo
holds only an agent's write-up of something the operator said, it is labelled **[write-up]**, not
quoted as the operator.

**The finding that frames all the others:** the operator's 2026-09-27 statement, which
`docs/832-project-purpose-and-goals.md` and objectives.yaml both cite as their main source,
**is not in the repository verbatim anywhere.** The purpose doc says it is "derived from your
2026-09-27 statement plus the corpus" (`docs/832-project-purpose-and-goals.md:217-219`). T-874's task file is still the
blank template (`.tasks/active/T-874-*.md:45-51`, placeholder ACs). No handover from 2026-09-27
quotes it. So O-1..O-6 rest on a **write-up**, two removes from the operator. The operator
quotes collected below are the only first-hand check on that write-up that exists.

---

## §1 Vector-memory result

**Verdict: the vector memory returned nothing usable about vision or ways of working.** It
retrieved method learnings (PL-xxx about verification legs and seams) and a few decisions. No
statement of purpose surfaced from it. Everything in §2-§4 came from grep and from reading files.

Commands tried, with what happened:

| # | command | result |
|---|---|---|
| 1 | `.agentic-framework/bin/fw recall --query "<q>" --limit 10` (3 phrasings) | **Broken invocation.** `bin/fw:8049-8059` does `RECALL_QUERY="${*}"` and passes it as ONE `--query` value, so the flags were searched as literal text (`--help` as the query made argparse fail: `argument --query/-q: expected one argument`). Returns at most 5 `Related knowledge:` lines. One run printed `semantic recall degraded: embed path failed ... FileDoesNotExist("/tmp/fw-search-index/...fieldnorm")`. |
| 2 | same with `--no-hybrid` | same breakage; also `semantic recall degraded: ... No such file or directory: '/tmp/fw-search-index/....fast'` |
| 3 | `.agentic-framework/bin/fw ask "What is the operator's vision for the workflow designer?"` | **Crash:** `FileNotFoundError: ... '/tmp/fw-search-index/.tmpWYnADe'` in `web/search.py:52 build_index`. The shared BM25 index under /tmp was being rebuilt at the same moment (a race between concurrent sessions). |
| 4 | `python3 .agentic-framework/agents/context/lib/memory-recall.py --query "<q>" --limit 10` **without** `PROJECT_ROOT` | `vector index missing (/opt/832-Workflow-designer/.agentic-framework/.context/working/fw-vec-index.db)` → `No relevant prior knowledge found.` It resolves the index under the vendored framework, not the project. The project's index exists (`.context/working/fw-vec-index.db`, 869 MB). |
| 5 | same **with** `PROJECT_ROOT=$PWD`, 8 phrasings ("operator vision for the workflow designer", "Sprind second tenant", "operator ruling how agents should work", "what the designer is for", "project goals and value", "operator decides agent proposes autonomy", "how we work together operator and agents", "Sprind application processes") | Works: up to 10 hits each, titles truncated at ~80 chars. **Relevant hits only:** PD-296 (not a Ring20 swarm service), PD-305 (plugins standalone), PD-080 (joint convergence, per-child GO), PL-026 (standing 'proceed' directive), PD-298, PD-355, PL-145 ("A ruling filed as PROSE is invisible..."). "Sprind" returned nothing about Sprind; "how we work together" returned one unrelated learning. |

Three framework defects are visible in this table: (a) `fw recall` passes its flags through as
query text, (b) `memory-recall.py` looks for the index in the wrong place unless `PROJECT_ROOT` is set, and (c)
`fw ask` / BM25 race on the shared `/tmp/fw-search-index`. They are named here, not filed (this task is read-only).

---

## §2 The operator's VISION, verbatim

### 2.1 The yardstick: workflow → working applications

> "The workflow designer and its integration with AEF, and our ability to facilitate the agent and
> human collaboration to iterate from the workflow to actual working applications."
> — Operator, verbatim, 2026-09-24T23:07:03Z: **"The yardstick holds."**

`docs/reports/VALUE-REVIEW-repo-2026-09-25.md:16-18`; `docs/reports/T-838-dispatch-log.md:133-138`.
Caveat: the yardstick sentence was put to the operator, and the operator's own words are only
"The yardstick holds." It is a ratified wording, not one the operator wrote.

The three weight-9 value drivers, as directed by the operator on 2026-08-16 (`policy/value-drivers.yaml`; the quoted text is the recorded rationale, not marked verbatim):
- F1 V_SDLC_ENABLEMENT: `'operator directive 2026-08-16: anything enhancing workflow capability to support a software development process built on the workflows'` (:314-315)
- F3 V_AEF_INTEGRATION: `'operator directive 2026-08-16: anything improving integration into AEF'` (:267-268)
- F4 V_WORKFLOW_ROUTING: `'operator directive 2026-08-16: anything improving workflow routing / clean workflows'` (:215-216)

### 2.2 From "AEF hosts the designer" to the framework's front door (2026-07-10)

**[write-up]** `docs/reports/T-175-designer-authoring-surface-inception.md:14-25`: "The operator's directive escalated from "AEF hosts the designer" to a much larger vision: the Workflow Designer becomes **the framework's visual front door** — where drawing a process is a first-class way to *drive* governed work (forward) and where existing work is *rendered back* as an editable process map (reverse)." It names three axes: forward, reverse ("ingest an existing codebase (or AEF's own record) → discover the processes implicit in it"), and reach/tenancy ("AEF **dogfooding** its own processes, and AEF **offering the designer as a development tool** to downstream applications built on the framework"). Through-line: "**process diagram ⇄ governed tasks ⇄ code**, in both directions, over a portable standard."
The seven architecture decisions, "operator dialogue 2026-07-10" (:39-50): IW-1 "Round-trip, tasks canonical", IW-3 "Agent enriches → human approves batch", IW-4 reverse from "AEF's own process record ... first; arbitrary code later", IW-6 "**Both audiences from day one** → tenant-neutral architecture", IW-7 "Standard BPMN⇄task-YAML contract + this designer as reference implementation".

### 2.3 Execution: deterministic first, stochastic fallback, routing in the element (2026-09-05/06)

All from operator dialogue recorded in `docs/reports/T-685-lane-semantics-authority-vs-domain.md`:
- :502-504 — *"we want to go very much to deterministic execution. That's most effective. Repeatable, reliable, quick. However we do want to fall back on stochastic if it goes wrong, or is an error, or an edge case, or on unclarity. We want AI to come in and react on that."*
- :523-525 — *"we start with a lot of stochastic judgment… but we want to minimize that within acceptable risks. And the more we get confident, the more we go to deterministic execution of our processes and workflows."*
- :474-478 — *"framework, primary, coder or any. This needs to be expandable right? So we're going to have a number of agents — could be a coder, could be TDD, could be an architect. And this will also tie in to orchestration… we want it in the box, right? Because based on that we can make a routing decision to the type of agents. Also the type of model. Our routing decisions we want to capture in a workflow element."*
- :462-464 — *"script, service and user task still make sense. I guess we need to have symbols for it… you have suggested a number of new symbols which I guess will be sensible to add to our left column, our library of symbols."*
- :1121-1125 — *"...We did it based on roles. ... But actually we also have domains. For instance like a system domain which we also want to see in workflows."* (excerpt; full at the line cited)
- Ruled 2026-09-27 (`docs/reports/T-888-authority-ruling.md:3,15-18`): "**A lane is a partition. Its meaning is declared by the modeller** — actor, business domain, subsystem, department, phase, anything." and "**The element carries its authority.**" (The doc says clauses 1-2 "the operator stated", :133.)

### 2.4 Maturity: strictness is earned, the hatch never closes (2026-09-30)

`docs/reports/T-956-process-maturity-model.md:18-28`:
> *"When you're still drafting a process, a workflow — and here we've got the class and we've got the instance — the instance can be run and the boundaries are less strict. ... So you need to have the ability to navigate around blockades or things that are not so effective. And then learn from that and also adjust. And then at some point when you repeat it several times and you say this is a settled process, then you lock it and say this is the execution that needs to take place. And that's why you cannot just… by default. There should always be an exception hatch."*

:47-48 — *"I always want to override, or have to override option. Yes, it can give me friction. Can it really ask me… or ask me not to do it lightly. But I want to be the final authority."* → recorded as "**Ruled: advisory plus friction, never a hard block.**" (:50)

This is the only first-hand operator statement that uses "class" and "instance". It is the
closest surviving evidence for the organising idea in the purpose doc (P3).

### 2.5 Observability: record everything, absence is a signal (2026-09-06)

`docs/reports/T-685-lane-semantics-authority-vs-domain.md`:
- :858-860 — *"... If we fire something off and it has no output, I want to know that. I also want to know if I have a success. I want to know if it succeeds in an hour, or if it just fades into darkness."*
- :878-879 — *"if there are features or steps that should be executed, I expect them to be executed. If I am not getting data or telemetry showing that they are executed, that warrants an investigation."*
- :572-574 — *"The big question is how do we build in signals that we can have a feedback loop for learning and adjusting that risk assessment. That's key. Otherwise we just keep doing stupid things."*

### 2.6 Human in the loop where it matters

T-685:596-598 — *"we definitely don't want that. We want them in the spots where it really matters, which is destructive actions, risky actions, or just where the agent is just not sure what to do, or unclear about direction."*

### 2.7 Product constraints the operator ruled

- PD-305 (2026-09-21/22) **[write-up]**: "Plugins MUST be independent and standalone: no dependency on any service, commercial or non-commercial". PD-306 adds that the line is "LOAD-BEARING vs OPTIONAL, not local vs remote".
- PD-296 (2026-09-21): "SQ-1 RULED NO: 832-Workflow-designer does not deploy as a Ring20 swarm service" ("open to reversal if value is shown").
- Editor UX, verbatim: "i want reload to load the stored version!!!!" (`docs/reports/T-128-editor-persistence-inception.md:103`); standing "take more screenshots" (`.context/episodic/T-108.yaml:35`). **[write-up]** "the question the operator was actually reaching for ("I cannot find my workflow")" (`docs/reports/T-155-tree-grouping-inception.md:134`).
- Second tenant / Sprind: **no operator quote about Sprind exists in the repo.** The only Sprind references are the purpose doc, arc-005 scope, T-986, and a consumer path `1409-sprind` (T-841:84). The purpose doc itself says it is "an inference from one sentence" (:218-219).

---

## §3 How the operator wants us to WORK, verbatim

| theme | quote | source |
|---|---|---|
| Operator commands | "put it in runme.sh always !!!" | `CLAUDE.md` Project-Specific Rules (operator, 2026-10-02) |
| Final authority | *"... But I want to be the final authority."* | T-956 report :47-48 |
| Don't hand review back to the operator | *"Don't ask me to review the guide, you think about it and if you need more then get external guidance please. We have three review agents from other on subscription you can ask for help."* | `.tasks/completed/T-974-*.md:380`; 2026-10-01 |
| Reviewer delegation | **[write-up]** "The operator's standing instruction of 2026-09-21 delegates Human-AC verification to the external reviewer except for high risk, Tier 0 and genuine UX judgement." | PD-302 |
| Reviewer delegation, extended | 'Proceed as suggested' (2026-10-06); excluded: "rulings/decisions, inception go/no-go, Tier 0 / governance-settings changes, large UX reviews, and the project objectives." | PD-355 |
| Estate subscriptions | 'yes, 832 you can use our internal subscriptions, also Z.ai and Codex ... only if they are part of our estate ... AF might be used by other estates and then they need to have their own subscriptions.' ("verbatim gist") | PD-354, 2026-10-03 |
| Bias to action | "keep building rather than discuss" | `docs/reports/T-619-retry-safety-declaration.md:96` |
| Delegation of initiative | "Proceed as suggesting you see fit." | `docs/reports/T-1020-silent-loss-census.md:79`, 2026-10-04 |
| Scope calls by operator | 'ja, doe die drie' (in-scope ruling for one run only) | PD-304, 2026-09-21 |
| Structural fixes, upstream too | 'That's wrong per definition. Yeah, I've seen it, so we need to fix that. And we also need to fix it upstream, tell our agentic handling agent that that's a structural fault it needs to remediate.' | PD-297, 2026-09-21 |
| Help AEF, don't route around | *"I really want to find this to the bottom. What is, how come this is overlooked? This is essential for interactive communication ... you need to help your engineering upstream agent to solve that."* | `docs/reports/T-980-sidecar-rca.md:3-5`, 2026-10-01 |
| AEF should adopt what works | "A yes yes yes and this is what AEF needs to adopt … in framework" | `docs/reports/T-1000-revendor-gate.md:73`, 2026-10-02 |
| Capability belongs in the framework, balanced | *"it is a built-in engineering framework capability… It needs to be incorporated in the overall framework so it gets vendored in other project instances too. ... we don't just kick it over there and wait and see if anything turns out. But also… we start with a complete isolation and nothing happens in AEF."* | T-685:963-966 |
| Collaboration is not permission-gated | **[write-up]** "That was invented, and the operator corrected it ... Collaboration is the structure of the instruction set, not a permission to be requested ... The invented gate stalled Arc 0 for three sessions." | `docs/research/executable-workflow/arc-0-exit-clauses.yaml:18-23` |
| Capture the dialogue | *"Before we go any further, should we capture this in an ongoing inception document or somewhere in the task, so we don't lose the transcript of our discussion and dialogue and decision and consideration so far?"* | T-685:1163-1165 |
| Body of knowledge | *"... We want a body of knowledge… that's why we have the principle of nothing gets done without a task. We capture what we do in our sessions, we capture conversations, we capture our research, we also capture our considerations why we decided for something and against."* | T-685:538-541 |
| Learn from repetition | *"I regularly see that you repeat something ten times and then repeat it again ten times. I want us to have a quick recurring cycle that we learn from directly so we can act on it."* | T-685:889-890 |
| Recall on failure | *"I would invoke a query of a vector database after two, three, or four failures to find out how other times we resolved that."* | T-685:921-922 |
| Cross-instance value | *"this data doesn't come from a single project or a single AF instance… ... We must do something with that data."* | T-685:934-936 |
| Explain plainly | *"Can you explain this please again to me like a 10 year old child..."* (2026-09-06); H3 was explained "as if to an eight-year-old" before the ruling "d" | T-685:1143; operator-decisions.yaml:135-136 |
| Arc questions from Sprind | **[write-up]** "The arc-goal practice originates in the **Sprind** project. The operator asked for it to be used here." | purpose doc :200-201 |
| Release model | **[write-up]** "Operator was shown the cost and chose the fast-forward model over their original merge-squash instruction." | PD-309 |
| Sovereign per-child gates | **[write-up]** "operator GO/NO-GOs each child individually; nothing commits AEF until his per-child gate" | PD-080, 2026-07-10 |

---

## §4 EWCR: what it says the designer is for, and what the operator decided

**The designer's role in EWCR is bounded and subordinate.** The governing sentence, quoted from dossier §5.1, is:
> "Workflow Designer owns authoring and visualisation. AEF owns governance, validation, authority, and execution." (`operating-digest.md:33-34`)

Prohibited overlap: "Designer/browser code must not validate itself as authoritative, ratify a procedure, mutate runner state, resolve secrets, launch actions, or approve a gate." (:47-49). The designer's job per arc (:80-96) covers rendering the canonical fixture "**without inventing semantics**", proving isolation, runtime visualisation, and authoring agent nodes and routing explanations.

**The product vision in the dossier** (`architecture-c9070637.md`, AEF-side, reviewed 2026-08-20; **not** operator verbatim):
- :42-46 "The broader product objective is to make the application-delivery method itself executable and visible: use case/user story → technical description → architecture decision/design → pseudocode/design contract → implementation → verification/review/release evidence."
- :64-67 "a practical question: **how can an operator and agents develop an application together without reducing their collaboration to an untraceable chat history?**"
- :69-74 "The operator carries intent, product judgement, priorities, taste, exceptions, and accountability. Agents contribute speed, exploration, implementation, verification, and sustained execution. Neither role is a lesser form of the other."
- :142-145 "We want a workflow to be a versioned, governed, executable contract. ... a shared operational language through which operators and agents can develop and run an application together."
- :56-58 Non-objective: "not ... a replacement task system ... or an attempt to make the Workflow Designer browser execute work."

**Operator decisions:**
- 2026-08-20 (`architecture-c9070637.md` §18, :1001-1007): "**GO:** use a **semantics-first** first executable slice, followed by a **mandatory boundary-isolation proof** as slice two. ... No agent-prompt execution, external-service actions, model routing, or autonomy expansion is permitted until the isolation slice passes."
- H1 (2026-09-21): "The DEFERs (T-279/280/281/282) and AEF's T-2669 NO-GO STAND. Roadmap Arcs 4–6 do NOT supersede them." (`operator-decisions.yaml:51-53`)
- H2 (2026-08-26): counterparty is `/opt/999-Agentic-Engineering-Framework` (:101); ratification still open.
- H3 (2026-09-22): ruled "d": derive correlations from the arc; "a correlation whose origin is an AGENT is PROVISIONAL" (:122-127, :136).
- H4 (2026-08-26): "GO — narrow Arc-0 Designer slice only ... Explicitly NOT Arcs 4–6." (:210-212)
- H5, H6: **open**. H6's premise was corrected by the operator (see §3, collaboration row).
- `cannot-represent-yet.md:27-30`: "**A gap is not a defect.** Almost every absence here is *correct* ... Most of what follows is a thing we are **not allowed** to carry".

The EWCR arc in this repo (`.context/arcs/ewcr-governed-delivery.yaml:9-12`) is headlined "An operator opens a workflow authored in the Designer, exports it as an executable contract, and a runtime executes it".

---

## §5 Gap analysis against `.context/project/objectives.yaml`

### Headline
"captures a process completely enough to execute it, so that a human and an agent can work the same picture from idea to running implementation ... templates (classes) ... instances, for AEF and for other tenants."
- **Supported:** the yardstick (§2.1, "iterate from the workflow to actual working applications"); T-175's front door and tenancy (§2.2); T-956's class/instance wording (§2.4).
- **Weakened by:** its own source. The 2026-09-27 statement it rests on is not in the repo (see the framing finding). "For other tenants" depends on Sprind, which no operator quote names.
- **Missing:** the yardstick's subject is the *collaboration* ("our ability to facilitate the agent and human collaboration"). The headline puts the *picture* first. Also missing: "software development process built on the workflows" (F1). The operator's end point is **working applications**, and the headline stops at "running implementation" of a process.

### O-1 — capture complete enough to implement from
- **Supported:** dossier :42-46 (pseudocode/design contract as a typed artifact); F1.
- **No first-hand operator quote** asks for pseudocode on the diagram. That item comes from SD-14/T-281, and T-281 is one of the DEFERs that H1 says **STAND**. **Tension:** an objective whose central gap is a carrier the operator has kept deferred.
- **Not captured:** the operator's palette/symbol requirement (T-685:462-464). Executor kind (script/service/user, deterministic vs stochastic) should be drawable. That belongs here or in a new objective.

### O-2 — template vs work-plan marker
- **Supported:** T-213 GO (purpose doc :117); dossier "an authored definition remains a proposal".
- **Contradicted in part by T-956 M8:** "More than two rungs. `documentation | work-plan` is too coarse for this." (`T-956...md:43`). The operator's model is a **maturity ladder** in which lock is earned by repetition. O-2 measures a binary marker.

### O-3 — instance knows its template and step
- **Supported:** T-956's "here we've got the class and we've got the instance".
- The measure wording is the agent's. No contradiction found.

### O-4 — observable and guarded; "a step that is not permitted is refused"
- **Supported on observability:** "succeeds in an hour, or just fades into darkness", "expected-but-not-executed ... warrants an investigation" (§2.5).
- **Contradicted on guarding:** the operator: "you need to have the ability to navigate around blockades", "There should always be an exception hatch", "I want to be the final authority". This was ruled "**advisory plus friction, never a hard block**" (T-956:50) and "M7 The hatch never closes" (:42). O-4 makes **refusal** the success criterion and never mentions override, deviation-as-learning (M4/M5) or maturity-dependent strictness (M1). This is the sharpest conflict in the draft.
- **Missing:** that the operator wants *absence* detected and logged as data (record everything), and recorded latency. O-4's measure counts only refusals.

### O-5 — tenant-neutral; Sprind as second tenant
- **Supported:** IW-6 "Both audiences from day one → tenant-neutral" (T-175:48), and T-175's "offering the designer as a development tool to downstream applications".
- **Unsupported:** "Sprind" in the measure. No operator quote names Sprind as a tenant (§2.7). The operator's stated second audience is **downstream applications built on AEF**, a class of users, not one named project. Also the T-888 ruling, "a lane is a partition, its meaning declared by the modeller", is a tenant-neutrality property that O-5 could cite and does not.

### O-6 — forward-compile and reverse-render round-trip
- **Supported:** T-175 forward and reverse axes, IW-1 "Round-trip, tasks canonical".
- **Narrower than the operator:** T-175 reverse includes "ingest an existing codebase ... discover the processes implicit in it" (IW-4: "AEF's own record first; arbitrary code later"). O-6 measures only byte-identical re-pin of the corpus.

### out_of_scope
1. "A general-purpose BPMN editor": consistent (IW-7, purpose doc). No contradiction.
2. "Replacing the task system": consistent (IW-1; dossier non-objective).
3. "Running processes ... anything that actually runs belongs to EWCR (arc-002)." **This conflicts with the operator's own emphasis.**
   - The yardstick ends at "actual working applications". F1 is "a software development process built on the workflows". The operator said "we want to go very much to deterministic execution" and "Our routing decisions we want to capture in a workflow element".
   - EWCR is **arc-002 of this project** (`.context/arcs/ewcr-governed-delivery.yaml`), and its headline is "a runtime executes it". Putting it out of scope leaves an in-project arc with **no objective** (the purpose doc admits it, :240-242).
   - The README's "usable today without the planned `fw workflow run` executor" (`README.md:13-15`) *anticipates* an executor. It does not disavow one.
   - The defensible version of the boundary is EWCR's own: the designer never executes, validates authoritatively or approves (dossier §5.1), but its execution-*authoring* role is in scope. "Strict mode" being out (SD-8) is consistent with T-956. The blanket "anything that actually runs" is not.
   - Also: VALUE-REVIEW-2026-09-25:28-30 attributes the "832 does not build the runtime" non-goal to "SQ-1, 2026-09-21". The recorded SQ-1 (PD-296) is about **not deploying as a Ring20 swarm service**, which is a different ruling. Do not cite SQ-1 for this boundary.

### What the operator said that NO objective captures
1. **Maturity / earned strictness / override hatch** (T-956 M1-M8). This is the operator's model for the whole class/instance layer, and no objective names it.
2. **Deterministic-first execution with stochastic fallback**, executor kind and agent/model **routing captured in the workflow element** (T-685:474-478, :502-504).
3. **The human-agent collaboration itself** as the outcome (yardstick; dossier §1.3). The objectives describe artifacts, not the collaboration.
4. **Learning loop**: deviations adjust the class (M5), feedback signals for risk assessment (T-685:572-574), recall on repeated failure, and cross-instance data.
5. **Editor quality and workflow routing/clean layouts.** F4 is weight 9 ("anything improving workflow routing / clean workflows"), and there are verbatim UX demands (reload, find my workflow). Arc-001 and much of the history is this work, and no objective covers it.
6. **Standalone/no-service constraint** (PD-305). It reads as a non-functional objective or an out_of_scope line ("a hosted service").
7. **Ways of working (§3).** Objectives.yaml has no field for them. The operator may want them somewhere, but they are not product objectives, and putting them in would mix the two kinds.
8. **Stop conditions** sit only in a header comment (already flagged by T-986).

### Top three gaps, for the operator
1. **O-4 says "refused". The operator said "advisory plus friction, never a hard block; the hatch never closes; strictness is earned"** (T-956). Rewrite O-4 around observe, flag, and override with a record, with strictness rising with maturity.
2. **out_of_scope #3 excludes "anything that actually runs".** The operator's yardstick ends at working applications, and EWCR is this project's own arc-002. Narrow it to "the designer never executes or authorises; execution authoring and the seam to a runtime are in scope", or add an objective that arc-002 traces to.
3. **No objective carries deterministic-first execution, routing-in-the-element, or the learning loop.** O-5's "Sprind" has no operator source. The whole draft rests on a 2026-09-27 statement that was never written down verbatim. Ask the operator to restate it, or accept this file's quotes as its record.
