---
id: T-986
name: "Write down the objectives of 832-Workflow-designer"
description: >
  Seeded once by fw upgrade (T-3636): this project has no .context/project/objectives.yaml.
  Author it once, from this project's own material: a headline, a few objectives each
  with a measure, and what is out of scope. Progress is derived from the work afterwards.
status: work-completed
workflow_type: build
current_node: frw_8_partial
owner: human
horizon: now
tags: [objectives-authoring]
components: []
related_tasks: []
created: 2026-10-01T21:11:29Z
last_update: 2026-10-05T08:23:51Z
date_finished: 2026-10-05T08:23:51Z
bvp_scores_proposed:
  - ts: '2026-10-05T08:21:17Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 0
      D2: 0
      D3: 0
      D4: 0
      F-RECALL: 0
      F2: 0
      F4: 0
      F3: 0
      F1: 2
    rationale: 'D1=0 (no-signal); D2=0 (no-signal); D3=0 (no-signal); D4=0 (no-signal);
      F-RECALL=0 (no-signal); F2=0 (no-signal); F4=0 (basis: task body — no hypothesis,
      so this score has no claim to be wrong about,L0: no signal); F3=0 (basis: task
      body — no hypothesis, so this score has no claim to be wrong about,L0: no signal);
      F1=2 (basis: task body — no hypothesis, so this score has no claim to be wrong
      about,L2:keyword=import)'
    rubric_sha: e4a00f38e801
---

# T-986: Write down the objectives of 832-Workflow-designer

## Context

`fw upgrade` seeded this task because 832-Workflow-designer has no
`.context/project/objectives.yaml`. Every governed project authors its objectives once,
through its own entry point; this is that moment for a project that was onboarded before
the step existed. It is seeded once: upgrade will not add it again, and never if the file
exists.

**Draft from this project's own material only:** its README and docs, the code and its
history, its tasks and arcs, and anything the operator has said. Never copy another
project's objectives, and never the framework's own.

After this, the objectives are not rewritten to stay current. Arcs and tasks point at
objective ids (`supports: [O-n]`), progress is read from that work, and the framework's
audit flags an objective nothing serves.

### The shape to write

```yaml
# Project objectives — 832-Workflow-designer.
#
# Authored intent; progress is derived, never written here.
# Arcs reference these ids via `supports: [O-n, ...]`.
headline: >-
  One or two sentences: who this is for and what it does for them.
objectives:
  - id: O-1
    text: >-
      An outcome a user or operator would notice, not an activity.
    measure: >-
      How you would know it holds. Say plainly if it is not measured yet.
out_of_scope:
  - "Something a reasonable person might expect this project to do, and it will not."
```

Keep objectives few (three to six). Every objective needs a `measure`, even if the honest
answer is "not measured yet".

**The flow:** the agent drafts, an independent reviewer checks it where one is available,
and the operator sees it once and ratifies it or says what to change.

## Acceptance Criteria

### Agent
- [x] `.context/project/objectives.yaml` exists in the shape above: the header line
      saying authored intent, progress is derived; headline; objectives (each with id,
      text, measure); out_of_scope
- [x] Drafted from this project's own material — never copied from another project or
      from the framework
- [x] Independent review asked for where available (`fw reviewer T-986`, or another
      model), and its corrections applied or answered

### Human
- [ ] [REVIEW] The objectives say what 832-Workflow-designer is for, in words you would use
  **Steps:**
  1. Read `.context/project/objectives.yaml`
  2. Check: does the headline say what 832-Workflow-designer does and for whom? Is each
     objective an outcome you care about, with a measure you would accept? Is anything
     missing, or anything listed out of scope that should not be?
  **Expected:** You would sign the file as written, or after the changes you named
  **If not:** Tell the agent what to change; it edits the file and hands it back

## Verification

# The objectives file exists and has the shape: headline, objectives each with id/text/measure, out_of_scope list
python3 -c "import yaml; d=yaml.safe_load(open('.context/project/objectives.yaml')); o=d['objectives']; assert str(d['headline']).strip() and o and all(x.get('id') and x.get('text') and x.get('measure') for x in o) and isinstance(d['out_of_scope'], list)"
# It carries the authored-intent header (progress is derived, never written into it)
grep -qi 'authored intent; progress is derived' .context/project/objectives.yaml

## Recommendation

<!-- Fill in once the draft has been reviewed, before handing over with
     `fw task review T-986`.

     **Recommendation:** GO / NO-GO / DEFER
     **Rationale:** why
     **Evidence:**
     - Finding 1 -->

**Recommendation:** GO: ratify `.context/project/objectives.yaml`, or name what to change. Ratifying it also settles the open item in T-874: the purpose and six goals you stated on 2026-09-27 were drafted into `docs/832-project-purpose-and-goals.md` and never ratified. O-1..O-6 are those goals, G1..G6.

**Rationale:**
- The draft comes from this project's own material only, chiefly your 2026-09-27 statement as written up under T-874.
- An independent reviewer (a separate model, read-only) checked it against that source and returned **ACCEPT WITH CHANGES**. Every finding was applied or answered:
  - **Removed as state:** progress notes in O-1 and O-5. The file holds intent; progress is derived.
  - **Removed as invented:** an out-of-scope item with no source; "every corpus map" (O-2); "AEF accepts" (O-6); a reverse query in O-3.
  - **Softened to match the source:** "never" in O-2 became "refused".
  - **Added:** the users in the headline; "tenant-neutral" in O-5; O-6's reverse-render half, marked "not measured yet"; and O-4's operator view, cited to P2.
  - **Answered, not applied:** the P5 stop conditions have no field in this shape, so they are kept as a labelled header comment for you to place.
- Your judgement is needed on the same three points the purpose doc already flagged for you:
  1. Is the second tenant *Sprind specifically* (O-5)? That was inferred from one sentence.
  2. Is G0, the method, rightly left out rather than made an objective?
  3. Where should the stop conditions live?

**Evidence:**
- The two T-986 verification lines pass: shape, plus the "authored intent; progress is derived" header.
- **Progress since 2026-09-27, derived from arc-005 and not written into the file:**
  - O-2: the kind marker shipped, and AEF was told.
  - O-3: template and instance resolve both ways.
  - O-4: transitions are validated, and the three refusals land in the audit log.
  - Still open: backfilling the corpus `kind`, and the designer showing an instance's position.
  - O-1's pseudocode carrier (SD-14, T-281) and O-5's second tenant (one example map, no instances) remain the biggest gaps.

## Updates

<!-- Auto-populated by git mining at task completion.
     Manual entries optional during execution. -->

### 2026-10-05T08:21:16Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
- **Change:** horizon: next → now (auto-sync)

## Reviewer Verdict (v1.5)

- **Scan ID:** R-a1a0bc6d
- **Timestamp:** 2026-10-05T08:23:53Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-10-05T08:23:51Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
