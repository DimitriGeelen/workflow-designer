---
id: T-340
name: "Standard BPMN DI is silently discarded on import: the whole bpmndi sub-tree is dropped and never re-emitted"
description: >
  parseBpmnXml never reads bpmndi and buildBpmnXml never emits it, while declaring the bpmndi namespace on the root. Any BPMN document carrying standard DI loses all of it on open-save. Same class as T-337 one granularity up: an unknown sub-tree rather than an unknown flow-node tag. Latent by occupancy (0 of 175 local .bpmn files carry DI) but every mainstream BPMN modeller emits it. Found by T-339.

status: started-work
workflow_type: build
owner: agent
horizon: now
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-02T10:39:05Z
last_update: 2026-08-09T15:43:59Z
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

# T-340: Standard BPMN DI is silently discarded on import: the whole bpmndi sub-tree is dropped and never re-emitted

## Context

`parseBpmnXml` (src:9595) contains no reference to `bpmndi` at all, and `buildBpmnXml`
(src:9439) emits none — while declaring `xmlns:bpmndi` on the root it never uses. So every
`<bpmndi:BPMNDiagram>` in an input document is dropped on open→save, silently.

Measured by T-339 (`tools/_t338-input-fidelity-cdp.mjs`, leg 5): standard DI injected into all
24 corpus maps, survived on 0. Verdict `DI-DROPPED`, now gated.

**Same class as T-337, one granularity up.** T-337 is an unknown flow-node *tag* falling through
an allowlist read with no complement branch. This is an entire unknown *sub-tree*. The shared
sentence: what the importer does not enumerate is not rejected, it is invisible, and export
writes only what state holds.

**Severity: latent by occupancy, not by construction.** 0 of 175 local `.bpmn` files carry
`BPMNDiagram`, and `tools/yaml-to-bpmn.py` emits none — so nothing loses DI today. But DI is
what *every* mainstream BPMN modeller (Camunda, bpmn.io, Signavio) emits, so this is the shape a
genuine third-party file arrives in. It is more exposed than T-337, not less: T-337 needs an
exotic tag, this needs only a file authored in a real BPMN tool.

> **Filing corrections (2026-08-03, see `## Decisions`) — left in place rather than rewritten,
> so the record shows what was believed at filing.** (1) "0 of 175" is **0 of 126** at
> `457194ec`, and the zero is an *unreachable witnessing state*: all 126 are designer-produced
> and our exporter never emits DI, so the bucket could not have filled. The severity claim
> rests on the standard, not on the corpus. (2) The `src:9656` anchor for the ratified
> principle has already drifted — T-337's edit moved it; the durable anchors are `src:8201`
> (T-225, original) and the head of `parseBpmnXml`. (3) The operator decision is real but
> *understates* its reach: options that emit DI change bytes AEF pins.

**Repair semantics NOT chosen** — same reason as T-337. Options: (a) preserve-and-re-emit
unconsumed DI (matches the T-259 precedent and the ratified "diagram XML is never silently
migrated", src:9656); (b) consume DI as layout on import and re-emit it, which makes DI
authoritative over `aef:position` and is a real design change; (c) refuse documents carrying DI.
Each changes what we emit for a peer's content, which is the T-559 product seam.


## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [ ] **BLOCKED** — Chosen semantics implemented in `parseBpmnXml`/`buildBpmnXml`
- [ ] **BLOCKED** — `EXPECTED_DI` in `tools/_t338-input-fidelity-cdp.mjs` updated to record the improvement
- [ ] **BLOCKED** — Bridge suite green with the changed expectation

All three are downstream of the ruling below and are left **unticked and marked BLOCKED**
rather than reworded into something satisfiable. A task whose scope is blocked should look
blocked. No agent AC was added to cover the measurement work in `## Decisions` — that work
is *evidence for* the ruling, not a deliverable of the task as scoped, and manufacturing a
tickable AC out of it would make a blocked task read as progressing.

### Human

- [ ] [REVIEW] Repair semantics for standard BPMN DI on import

      > **Consolidated view: `docs/reports/T-397-import-repair-semantics-brief.md`.** This is
      > one of four open rulings; the brief states all four in their *current* form, which
      > matters here because this AC has been corrected in place (the recommendation moved
      > from `(a′)` to `(b)`, and step 3 below is marked superseded). The brief also
      > re-measured the disjointness claim this ruling rests on — `BOTH = 0` still holds, now
      > over 142 files rather than the 126 measured when it was written.
      >
      > ### 2026-08-09 — AEF reached the same ruling independently (rail 487, T-403)
      >
      > AEF measured their round-trip importer and **drop** `bpmndi` geometry, for our reason:
      > they emit `aef:position` on every node and no BPMNDI at all, so preserving the input's
      > DI would hand the export two carriers for one geometry with no user action to reconcile
      > them. Same position, same ruling, same reasoning — *arrived at before reading ours*.
      >
      > That is worth strictly more than agreement: two independent derivations of PL-114 from
      > different codebases. It does not make the ruling yours-by-default — it removes the
      > worry that PL-114 was reasoning built backwards from a conclusion we already liked.
      >
      > **Adopt their instrument, not just their answer.** They pin
      > `test_di_drop_has_a_competing_carrier`, which asserts the carrier **exists**: delete
      > `aef:position` and the test goes red. Ours argues the rule in prose. Theirs makes the
      > day the rule stops holding go RED instead of going silent — which is precisely the
      > failure mode this whole brief is about. Recommend adding the equivalent guard on our
      > side as part of whatever repair this ruling authorises.

      > **Read the brief's "competing-carrier rule" before ruling.** It explains why this
      > ruling should *differ* from T-337's and T-347's rather than matching them: DI is the
      > only class where we generate a rival carrier (`aef:position`), so preservation here
      > produces two contradictory geometries instead of fidelity.

      **This AC was filed under `### Agent` and moved here.** It reads "decided (operator)"
      while sitting in the section P-010 gates on, so completion would have required an agent
      to tick a box only the human may tick — the only exits from that are `--force` or a
      quiet wrong decision. Identical mis-filing to T-341's AC1, in the sibling task, filed
      the same week. Agent→Human is the safe conversion direction (the T-1811/T-1878 rule
      restricts Human→Agent, not the reverse).

      **Steps:**
      1. Read `## Decisions` below — in particular *"why option (a) does not transfer from
         T-337"* and *"what each option costs"*.
      2. Choose one: **(a)** preserve-and-re-emit verbatim · **(a′)** preserve structure but
         refresh shape coordinates from `aef:position` on export · **(b)** consume DI as
         layout and re-emit regenerated DI · **(c)** refuse documents carrying DI.
      3. **Superseded — this step said "(b) or (a′) changes bytes AEF pins, coordinate before
         implementing". That is true only of a MAXIMAL (b) that always emits regenerated DI.**
         Scoped as recommended below, (b) changes zero bytes for existing maps and needs no
         re-pin. What is still worth asking AEF is narrower and is not blocking: *if you ever
         hand us a document carrying both `aef:position` and DI, which wins?* Nothing produces
         that shape today. Asked on the rail at offset 413/415.
      4. Record it: `cd /opt/832-Workflow-designer && .agentic-framework/bin/fw context add-decision "T-340 DI repair semantics: <a|a-prime|b|c>" --task T-340 --rationale "<why>"`

      **Expected:** one option recorded. No AEF acknowledgement is required for scoped (b) —
      that expectation belonged to the maximal variant and is withdrawn.

      **If not:** if none of the four is right, the likely reason is that the real question is
      *"should the designer adopt BPMN DI as its geometry and retire `aef:position`?"* —
      **filed as its own inception (see `## Decisions`), and NOT a reason to defer this
      ruling.** Scoped (b) is a strict subset of that adoption, so choosing it now is the
      first increment either way and is not work thrown away if the inception says GO.

      **Recommendation (corrected 2026-08-03 — was (a′), now (b)). See
      `## Decisions` → "the recommendation was wrong, and the option set was framed too
      narrow" for the full reasoning.** In short: (a) and (a′) both preserve DI *bytes* while
      leaving the importer blind to it, so a foreign file still auto-layouts on load
      (`src:9742` — position comes from `aef:position` if present, **else lay out
      automatically**, and a foreign file has no `aef:position` by construction). (a) then
      re-emits the original DI alongside auto-layout `aef:position` — two contradictory
      geometries **immediately, with no user action**. (a′) overwrites the author's
      coordinates with the auto-layout — consistent, and it destroys the thing worth saving.

      **(b) consume DI as layout is the only option under which the author opens their
      diagram and sees their diagram**, and the byte objection that disqualified it applies
      only to a maximal form of it. Scoped as: **on import `aef:position` → else DI → else
      auto-layout; on export emit DI only when the input carried it.** The two populations are
      disjoint today (121 of 126 files carry `aef:position` and none carry DI; a foreign file
      carries DI and cannot carry `aef:position`), so the precedence rule never fires on our
      corpus: **zero bytes change for existing maps, `_t308` stays 24/24, no fixture re-pin,
      no seam event.**

      What remains for AEF is therefore narrower than step 3 above implies: not "may we break
      your pins" but **"if you ever hand us a document carrying both `aef:position` and DI,
      which wins?"** Nothing produces that shape today, which is exactly why it is cheap to
      state now.

<!-- Criteria requiring human verification (UI/UX, subjective quality). Not blocking.
     Remove this section if all criteria are agent-verifiable.
     Each criterion MUST include Steps/Expected/If-not so the human can act without guessing.

     ── Prefix routing (T-1811, T-1878): default to [REVIEWER] if Expected is grep-able ──
     If your Expected clause is grep-able / file-exists / structural (a deterministic
     shell check), prefer [REVIEWER] — that AC should be an Agent AC with the reviewer
     command in `## Verification` instead of a Human AC here. Only keep [REVIEW] if
     verification genuinely needs human taste (tone, feel, layout rhythm).
     See CLAUDE.md §AC Classification Guidance for the conversion rule.

     [REVIEW] example (genuine human judgment):
       - [ ] [REVIEW] Dashboard renders correctly
         **Steps:**
         1. Open https://example.com/dashboard in browser
         2. Verify all panels load within 2 seconds
         3. Check browser console for errors
         **Expected:** All panels visible, no console errors
         **If not:** Screenshot the broken panel and note the console error

     [REVIEWER] example (static-scan-verifiable — convert to Agent AC + Verification):
       - [ ] [REVIEWER] Block message names both bypass mechanisms
         **Steps:**
         1. Run `bin/fw reviewer T-XXX`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-XXX 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
-->

## Verification

# Shell commands that MUST pass before work-completed. One per line.
# Lines starting with # are comments (skipped). Empty lines ignored.
# The completion gate runs each command — if any exits non-zero, completion is blocked.
#
# Toolchain hint (L-291): if you edited *.vbproj/*.csproj/*.xaml add `dotnet build`;
# *.go → `go build ./...`; Cargo.toml → `cargo check`; tsconfig.json → `tsc --noEmit`;
# pom.xml → `mvn -q compile`. P-011 runs only what you write — broken builds slip
# past otherwise (origin: 003-NTB-ATC-Plugin T-077, broken WPF DLL on master 5 days).
#
# Pipefail/SIGPIPE hint (L-387): P-011 runs each command under `set -eo pipefail`.
# `cmd | grep -q PATTERN` exits 141 (SIGPIPE) when grep matches and closes stdin
# while the upstream is still writing — verification then "fails" even though
# the pattern was present. Safe pattern: capture first, grep the capture:
#     out=$(cmd 2>&1); echo "$out" | grep -q "PATTERN"
# Or:
#     cmd > /tmp/.out 2>&1 && grep -q "PATTERN" /tmp/.out
# Origin: L-387, captured 4× (T-1716, T-1838, T-1862, T-1863) before this hint.
#
# Single pipe only — no intermediate tail/awk/sed stages between capture and grep
# (T-2090): `echo "$out" | tail -3 | grep -q PAT` re-introduces the SIGPIPE risk
# the capture step closed off — the middle stage is what `grep -q` slams its
# stdin on. `echo "$out"` is small and immediate; grep scans the whole captured
# string anyway, so the tail-3 was cosmetic. Drop it: `echo "$out" | grep -q PAT`.
#
# Enforcement-baseline hint (L-398, T-1886): if you edited `.claude/settings.json`
# (added/removed/reorganised hooks), add `bin/fw enforcement baseline` to your
# Verification block. Otherwise the canonical hash diverges and `fw doctor`
# reports a FAIL ("Enforcement baseline CHANGED") that accumulates silently.
# Origin: T-1849/T-1730/T-1731 each added a legitimate hook without refreshing
# the baseline — FAIL sat for multiple sessions until T-1886 cleaned up.
#
# T-340 note: this block deliberately does NOT assert the current state of the
# defect (e.g. "bpmndi appears exactly twice in src"). Such a line is true today
# and goes RED at the moment the fix lands — a probe that fails when it is right,
# sending the next session to debug working code. The DI-specific assertion also
# cannot be written yet: its shape depends on which repair semantics the operator
# rules for, and writing one now would encode a guess at that ruling as a gate.
# What is here holds under every option.
bash tests/run-bridge-tests.sh
node tools/_t338-input-fidelity-cdp.mjs

## RCA

<!-- REQUIRED for bug-class tasks (workflow_type=build with bug-tag, OR title matches
     fix/bug/rca/broken/crash/error/regression/fail/hotfix).
     Non-bug-class tasks may leave this section empty or remove it.

     For bug-class, fill in:
       **Symptom:** what was observed (the user-facing manifestation).
       **Root cause:** the specific structural/logical gap — not "the code was wrong".
       **Why structurally allowed:** what in the framework/code/tooling let this go undetected.
       **Prevention:** what catches the next instance (test/lint/gate/doc/learning) — distinct from the fix itself.

     The completion gate (T-1550, G-019) blocks --status work-completed when
     bug-class AND this section is empty/template-only. Use --skip-rca to bypass (logged).
-->

**Symptom:** a BPMN document carrying standard `<bpmndi:BPMNDiagram>` loses all of it on
open→save. Not gated (the title matches no bug-class keyword), filled anyway.

**Root cause:** `parseBpmnXml` reads an enumerated set of elements and `buildBpmnXml` writes a
fixed skeleton from `state`. DI is in neither enumeration, so it is never *rejected* — it is
never *visited*, and export writes only what `state` holds. Same sentence as T-337 one
granularity up: **what the importer does not enumerate is invisible, and invisible means
deleted.** The root declares `xmlns:bpmndi` (`src:9443`) and never uses it, so the emitted
document advertises a vocabulary it drops.

**Why structurally allowed:** every instrument pointed at this repository measures documents
this repository produced. 121 of 126 `.bpmn` files carry `aef:position`, our exporter's
fingerprint; the other 5 are editor save history. Our exporter never emits DI, so **no corpus
census could ever have witnessed this defect** — the bucket cannot fill. It took injecting DI
into inputs out-of-band (T-339, `_t338` leg 5) to see it at all. A self-produced corpus
validates the round trip against our own vocabulary and is silent about everyone else's.

**Prevention:** the `_t338` input-fidelity instrument already covers it (`EXPECTED_DI =
'DI-DROPPED'`, gated in the bridge suite) — it was built to inject shapes the corpus does not
contain, precisely because the corpus cannot supply them. The remaining gap is that no
*third-party-authored* BPMN document exists anywhere in the tree to test against; that is a
population problem, not a rule problem, and is bigger than this task.

## Evolution

### 2026-08-03 — the operator constraint, and the corpus zero
- **What changed:** two of the filing's own claims moved under measurement. (1) The "operator
  decides" AC is real but *understated* — options (b)/(a′) change bytes AEF pins, so the
  ruling is partly the peer's, not just the operator's. (2) "Latent by occupancy, 0 of 175"
  is an unreachable witnessing state: 126 files today, all designer-produced, none capable of
  carrying DI. The zero measures our authorship, not DI's rarity.
- **Plan impact:** T-337's option (a) cannot be copied across. DI collides with
  `aef:position`, so preserve-verbatim buys a silent two-geometry document — recommendation
  moved to (a′), preserve-structure-refresh-coordinates.
- **Triggered:** no new task. The "no third-party BPMN in the tree" gap is named in the RCA
  rather than filed, because it is a property of the whole import-loss class (T-337, T-340,
  T-347, T-348), not of this task — filing it here would scope it to DI.

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

### 2026-08-03 — the operator AC is REAL, checked rather than assumed

The first move was to test the filing's own constraint, because the last time I wrote
"operator's call" into an AC (RAIL-407, the vendored task template) **it was false and I had
parked a one-file change behind a decision that was never needed.** Restraint and a scope
error look identical from outside, so the constraint gets measured like anything else.

**The precedent points the other way, and that is what made the check necessary.** T-337 —
the sibling defect, same class one granularity down — carried the *identical* "Repair
semantics NOT chosen" filing note and had **no operator AC at all**. The agent chose option
(a), recorded it under Decisions, and the task shipped complete with zero Human ACs. On the
face of it T-340's operator AC is the inconsistent one.

**It survives the check anyway, for a reason specific to DI:**

| | T-337 (foreign flow-node tag) | T-340 (standard DI) |
|---|---|---|
| what is preserved | bytes nothing else describes | **geometry `aef:position` already owns** (`src:9272`, emitted for every node on every save) |
| conflict after preservation | none — inert passthrough | **two contradictory sources of truth for one property** |
| bytes changed for existing maps | 0 (measured, 24/24 identical) | 0 for (a); **all 24** for (b) |
| decision reaches | this repo | **AEF** — `tests/run-bridge-tests.sh:206` pins `source_bpmn_sha` and says *"fixture edited? re-pin + notify AEF"* |

So the ruling is not merely the operator's, it is partly the **peer's** — which is strictly
more than the filing claimed. Left blocked.

### 2026-08-03 — why option (a) does not transfer from T-337

T-337's passthrough is inert: a `businessRuleTask` element's bytes are described by nothing
else we hold, so re-emitting them verbatim cannot contradict anything. **DI is not inert.**
`<bpmndi:BPMNShape>` carries `dc:Bounds x/y`, which is the same property as `aef:position` —
and `aef:position` is authoritative, user-mutable (drag), and re-emitted unconditionally at
`src:9272`.

Preserve-verbatim therefore has a failure mode T-337 did not: **drag one node and save, and
the document asserts two different positions for it.** A third-party tool reads the standard
DI and renders the *old* layout; we read `aef:position` and render the new one. Nothing is
lost, nothing errors, and the two readers disagree forever. That is a worse failure than the
current one in at least one respect — today's drop is total and therefore obvious to anyone
who looks; stale DI is silent and self-consistent.

Recorded because the tempting move was to copy T-337's decision across on the strength of
"same class, one granularity up" — which is how the filing itself describes this task, and it
is true of the *defect* while being false of the *repair*.

### 2026-08-03 — the corpus zero is an unreachable witnessing state, not evidence of rarity

The filing rates severity "latent by occupancy" on *"0 of 175 local `.bpmn` files carry DI"*.
Re-measured at `457194ec`:

| population | count |
|---|---|
| tracked `.bpmn` files | **126** (filing said 175, no commit pinned) |
| carrying `BPMNDiagram` | **0** |
| carrying `aef:position` — i.e. written by our own exporter | **121** |
| remaining 5 | all `.editor-versions/` save history, 3 in `_trash` — also designer-produced |

**Every one of the 126 is designer-produced, and our exporter provably never emits DI**
(`bpmndi` appears twice in the whole source: a namespace declaration at `src:9443` and a
syntax-highlighter regex at `src:10019`, neither functional). So the zero is not a measurement
of how rare DI is — **it is a restatement of the fact that we wrote the corpus.** The bucket
could not have filled. A count over a population where the property is impossible by
construction cannot distinguish "rare" from "never tested".

The honest severity sentence is therefore *not* "latent by occupancy" but: **this repository
has never once been tested against a BPMN document authored by a third-party tool, so it holds
no evidence about DI incidence in the wild either way.** The filing's own next sentence — that
every mainstream modeller emits DI — is the load-bearing one, and it is reasoning from the
standard, not from the corpus.

Three population numbers now exist for this same question across three tasks — 47 (T-337's
census), 175 (this filing), 126 (today) — and none was pinned to a commit. The 47 reconciles
exactly as the authored subset (24 rendered + 20 fixtures + 1 + 1 + 1); 175 reconciles with
nothing currently in the tree.

### 2026-08-03 — what each option costs (so the ruling is decidable, not just posed)

- **(a) preserve verbatim** — 0 bytes changed for existing maps, seam-safe. Cost: the stale-DI
  divergence above.
- **(a′) preserve structure, refresh coordinates from `aef:position` on export** — 0 bytes for
  maps with no DI (all 126), one authoritative geometry, keeps DI content we do not model
  (edge waypoints, labels). Cost: rewrites a peer's coordinate bytes.
- **(b) consume DI as layout, re-emit regenerated** — makes DI authoritative over
  `aef:position` on import, and **changes exported bytes for all 24 corpus maps**, so
  `_t308-export-byte-identity` goes 24/24 drifted and AEF's pinned fixtures need a re-pin.
- **(c) refuse** — destroys the editing path for exactly the documents the seam exists to
  serve; same objection that rejected (c) in T-337.

### 2026-08-03 — the recommendation was wrong, and the option set was framed too narrow

Two corrections, the second prompted by the operator asking *"why not just adopt the
standard?"* — a question none of the four options was shaped to receive.

**1. The user-facing defect is worse than "DI is dropped", and that inverts the ranking.**
`src:9742`: position comes from `aef:position` **if present, else lay out automatically**. A
third-party file has no `aef:position` — it is our namespace — so opening a Camunda or
bpmn.io export means the author's arrangement is **replaced by our auto-layout on load**, and
saving makes that irreversible. So:

| option | what the author sees on open | what the saved file says |
|---|---|---|
| today | auto-layout | one geometry, theirs deleted |
| (a) preserve verbatim | auto-layout | **two contradictory geometries, immediately, with no user action** — original DI beside auto-layout `aef:position` |
| (a′) preserve + refresh | auto-layout | one geometry — the auto-layout. Consistent, and it destroys the thing worth saving |
| **(b) consume as layout** | **their diagram** | one geometry, theirs |

(a) and (a′) both preserve DI *bytes* while leaving the importer blind to DI, which is why
neither addresses the symptom. My earlier note that (a)'s divergence appears "after a drag"
was wrong — it is present the moment the file is saved.

**2. The byte objection that disqualified (b) applied only to a maximal form of it.** I
rejected (b) as "changes exported bytes for all 24 maps → re-pin AEF's fixtures", which is
true of *always* emitting regenerated DI. Scoped properly — **import: `aef:position` → else
DI → else auto-layout; export: emit DI only when the input carried it** — the two populations
are disjoint (121 of 126 carry `aef:position`, none carry DI; a foreign file carries DI and
cannot carry `aef:position`), so the precedence never fires on our corpus. Zero bytes change,
`_t308` stays 24/24, no seam event. **I let a property of the maximal variant disqualify the
whole option**, which is the same error as rating severity from a census that could not fill:
a general claim resting on one unexamined sub-case.

**3. The question the option set could not receive: should `aef:position` exist at all?** DI
is a standard, is strictly richer than our extension (bounds, waypoints, label positions
against our x/y), and Portability is the fourth constitutional directive — *prefer standards*.
The injury is also **symmetric and I had not said so**: our exports carry no DI either, so
bpmn.io opening one of our files auto-layouts it exactly as we do to theirs. We are on both
ends of the same defect.

Full adoption is **not** folded into T-340. It changes bytes for all 24 maps, reaches
`tools/yaml-to-bpmn.py` (which emits `aef:position`) and the bridge parity assertions, needs
dual-read indefinitely so 126 existing files keep loading, and rewrites every file on first
save — which must be argued against the T-225 ratification *"diagram XML is never silently
migrated"* as a deliberate versioned migration rather than assumed exempt. That is an
inception with one go/no-go question, filed separately.

**Crucially the two are not alternatives: (b) is a strict SUBSET of adopting the standard**,
not a competing design. It is byte-neutral, ships now, stops the layout destruction, and is
the first increment of the migration rather than work thrown away if adoption goes ahead.

**Open assumption for that inception, not to be rediscovered halfway through: why does
`aef:position` exist at all?** There may be a recorded reason — a bridge constraint, DI judged
too heavy for the yaml round trip — and I have not looked. Recorded as an unchecked
assumption rather than asserted as an oversight.

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-08-02T10:39:05Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-340-standard-bpmn-di-is-silently-discarded-o.md
- **Context:** Initial task creation

### 2026-08-03T12:04:46Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
