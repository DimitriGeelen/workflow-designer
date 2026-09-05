---
id: T-587
name: "ingest and reflect on the AEF executable workflow-contract source packet"
description: >
  Governed ingestion of the two hash-pinned AEF source documents (architecture
  dossier c9070637, delivery roadmap 5be23719) dispatched under source task
  T-037 / governance container T-036, plus the Designer-side reflection that
  must precede any arc or task translation.

status: work-completed
workflow_type: inception
owner: agent
horizon: null
tags: []
components: []
related_tasks: []
arc_id: ewcr-governed-delivery
created: 2026-08-25T00:00:00Z
last_update: 2026-08-26T08:55:40Z
date_finished: 2026-08-26T08:55:40Z
target_blast_radius: 5
voi_score: 0.9
---

# T-587: ingest and reflect on the AEF executable workflow-contract source packet

## Problem Statement

AEF has dispatched a two-document source packet describing an executable
workflow-contract runtime, with a proposed ownership split (Designer owns
authoring and visualisation; AEF owns governance, validation, authority and
execution) and a proposed delivery roadmap of arcs. The dispatch (T-036 prompt
artifact, Prompt B) explicitly forbids importing those arcs mechanically.

The question this inception answers is: **which parts of the proposed roadmap
are true, false, or unmeasured against this project's actual authoring surface,
Mapping Standard, import/export behaviour and topology — and what is the
smallest Designer-owned or joint-contract slice that is actually next?**

## Assumptions

Registered in the reflection artifact; `fw assumption add` unavailable in the
dispatch session (see Technical Constraints).

## Open Questions

Filed in `docs/research/executable-workflow/questions-and-dispositions.md`
under IW-N ids with confidence/disposition/rationale per question.

## Exploration Plan

1. Verify both pinned SHA-256 hashes before reading. (done)
2. Store immutable hash-addressed snapshots + source manifest.
3. Five bounded ingestion passes: orientation, ownership, delivery,
   adversarial, synthesis.
4. Produce the operating digest and the questions/dispositions register.
5. Produce the Designer-side reflection artifact (current-state/gap matrix,
   arc dispositions, next justified slice, proposed BVP with counterarguments,
   required AEF contract requests, monitoring plan, human decisions).
6. Stop. Do not create downstream arcs or bulk tasks.

## Technical Constraints

The dispatch session runs under a permission profile in which `fw`, `git` and
`curl` Bash invocations are all denied and cannot be approved (non-interactive
session). Consequences recorded in the reflection artifact: no `fw doctor`,
no `fw context status`, no `fw fabric` topology query, no `fw task create`,
no assumption/learning registration, no commit. Source documents were obtained
from the peer project working tree rather than over HTTP; both hashes match the
pinned values exactly, so provenance is intact.

## Scope Fence

**IN:** hash verification, immutable snapshot storage, five-pass ingestion,
reflection artifact, proposed (not confirmed) BVP, proposed next slice,
identification of required joint contracts and human decisions.

**OUT:** implementing any runtime; altering AEF authority semantics; starting
an arc; confirming BVP; creating downstream build tasks; editing the AEF
repository; changing the frozen Mapping Standard.

## Acceptance Criteria

### Agent
- [x] Both source hashes verified against the pinned manifest values
- [x] Immutable hash-addressed snapshots + source manifest stored
- [x] Five-pass ingestion completed; operating digest written
- [x] Questions/dispositions register written with IW-N shape
- [x] Designer reflection artifact written (gap matrix, dispositions, next
      slice, proposed BVP with counterarguments, AEF contract requests,
      monitoring plan, human decisions)

### Human
- [x] [REVIEW] Review the reflection and decide GO/NO-GO on the proposed next slice
  **Steps:**
  1. Read `docs/research/executable-workflow/reflection-designer.md`
  2. Review the proposed next slice and the "Human decisions required" section
  3. Record the decision: `cd /opt/832-Workflow-designer && .agentic-framework/bin/fw inception decide T-587 go --rationale "..."`
  **Expected:** Decision recorded, next slice authorised or refused
  **If not:** Ask for the specific evidence behind the disputed disposition

## Go/No-Go Criteria

**GO if:**
- The proposed next slice is Designer-owned or a clearly paired joint contract
- Its exit evidence is executable in this project without AEF changes landing first
- The Mapping Standard boundary is not moved by it

**NO-GO if:**
- The next slice requires AEF contract semantics that are not yet ratified
- It would move or reinterpret the frozen Mapping Standard without a paired task

## Verification

# Both pinned source hashes still match their stored snapshots.
sha256sum -c docs/research/executable-workflow/source-manifest.sha256

## Recommendation

**Recommendation:** GO — but only on the narrow Arc-0 slice in
`docs/research/executable-workflow/reflection-designer.md` §5, and only after
H1–H3 are answered.

**Rationale:** The dossier's ownership boundary and its explicit protection of
Mapping Standard Part I are compatible with this project as it stands — there is
no boundary conflict to resolve. What is *not* compatible is the roadmap's
Designer column for Arcs 4–6, which re-proposes work carrying four standing
DEFER dispositions here (T-279/280/281/282) and a NO-GO on the AEF side
(their T-2669), without a superseding decision. Scheduling those would reverse
recorded dispositions on a document's say-so.

The one genuinely unclaimed, safe, and useful Designer contribution is Arc 0's:
write down what our contract actually is — defaults, inference rules, identity
model and its open defects — and render one canonical pilot fixture through the
existing frozen mapping. It is read-only, additive, lands without AEF code, and
resolves the real Arc 0 blocker, which is not topology but the fact that neither
side has written our defaults down.

**Evidence:**
- Both pinned hashes verified before and after storage; `sha256sum -c` passes.
- Boundary agreement: dossier §0.1/§6.1 vs `docs/standards/aef-bpmn-mapping-v1.md` §3.
- Disposition collision: `docs/proposals/aef-workflow-process-layer-2026-07-02/DISPOSITION-2026-07-28.md`
  SD-8/9/14/15 + addendum, against `roadmap-5be23719.md` §2.1 Arcs 4–6.
  T-277/279/280/281/282 confirmed still `status: captured` on 2026-08-25.
- Roadmap's "0 components, 0 edges" premise is the authoring project's
  measurement; this project has 67 component cards, with six open
  instrumentation defects (T-342/343/344/345/524/525).
- Arc 4's Designer read-half already ships (`dist/MANIFEST.yaml`
  `capabilities: { annotation_seam: 1 }`, release 0.11.0); the write half does
  not exist and touches a seam whose origin policy is still v0 `*`.
- BVP driver-ID collision: roadmap F1/F3 ≠ local F1/F3
  (`policy/value-drivers.yaml` v3).
- Two of the four cited reviews (DeepSeek, Mistral) have no disposition table in
  the pinned dossier, so Arc 0's exit gate is not satisfiable from the packet.

## Decisions

## Decision

**Decision**: GO

**Rationale**: The dossier's ownership boundary and its explicit protection of
Mapping Standard Part I are compatible with this project as it stands — there is
no boundary conflict to resolve. What is *not* compatible is the roadmap's
Designer column for Arcs 4–6, which re-proposes work carrying four standing
DEFER dispositions here (T-279/280/281/282) and a NO-GO on the AEF side
(their T-2669), without a superseding decision. Scheduling those would reverse
recorded dispositions on a document's say-so.

The one genuinely unclaimed, safe, and useful Designer contribution is Arc 0's:
write down what our contract actually is — defaults, inference rules, identity
model and its open defects — and render one canonical pilot fixture through the
existing frozen mapping. It is read-only, additive, lands without AEF code, and
resolves the real Arc 0 blocker, which is not topology but the fact that neither
side has written our defaults down.

**Date**: 2026-08-26T08:55:40Z

## Updates

### 2026-08-26T08:55:40Z — inception-decision [inception-workflow]
- **Action:** Recorded inception decision
- **Decision:** GO
- **Rationale:** The dossier's ownership boundary and its explicit protection of
Mapping Standard Part I are compatible with this project as it stands — there is
no boundary conflict to resolve. What is *not* compatible is the roadmap's
Designer column for Arcs 4–6, which re-proposes work carrying four standing
DEFER dispositions here (T-279/280/281/282) and a NO-GO on the AEF side
(their T-2669), without a superseding decision. Scheduling those would reverse
recorded dispositions on a document's say-so.

The one genuinely unclaimed, safe, and useful Designer contribution is Arc 0's:
write down what our contract actually is — defaults, inference rules, identity
model and its open defects — and render one canonical pilot fixture through the
existing frozen mapping. It is read-only, additive, lands without AEF code, and
resolves the real Arc 0 blocker, which is not topology but the fact that neither
side has written our defaults down.

## Reviewer Verdict (v1.5)

- **Scan ID:** R-a7106a3d
- **Timestamp:** 2026-08-26T08:55:41Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

## Recommendation Verdict (v1.0)

- **Scan ID:** RC-c80deb9b
- **Timestamp:** 2026-08-26T08:55:41Z
- **Overall:** CONTRADICTED
- **Claims:** 9

| Claim | Type | Status |
|-------|------|--------|
| `docs/research/executable-workflow/reflection-designer.md` | file | ✓ pass |
| `docs/standards/aef-bpmn-mapping-v1.md` | file | ✓ pass |
| `docs/proposals/aef-workflow-process-layer-2026-07-02/DISPOSITION-2026-07-28.md` | file | ✓ pass |
| `dist/MANIFEST.yaml` | file | ✓ pass |
| `policy/value-drivers.yaml` | file | ✓ pass |
| `T-279` | task | ✓ pass |
| `T-2669` | task | ✗ fail — no task file in .tasks/{active,completed}/ |
| `T-277` | task | ✓ pass |
| `T-342` | task | ✓ pass |

### 2026-08-26T08:55:40Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
- **Reason:** Inception decision: GO
