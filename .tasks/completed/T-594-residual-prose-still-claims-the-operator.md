---
id: T-594
name: "Residual prose still claims the operator resolved H2 after T-593 cleaned the structured fields"
description: >
  Residual prose still claims the operator resolved H2 after T-593 cleaned the structured fields

status: work-completed
workflow_type: build
owner: agent
horizon: null
tags: [arc:ewcr-governed-delivery]
components: []
related_tasks: []
arc_id: ewcr-governed-delivery
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-26T14:42:18Z
last_update: 2026-09-03T05:18:33Z
date_finished: 2026-08-26T14:47:49Z
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

# T-594: Residual prose still claims the operator resolved H2 after T-593 cleaned the structured fields

## Context

T-593 removed the manufactured claim that the operator resolved H2 — but only from the
**structured fields** (`status`, `resolved_by`, `resolved_at`, `to_project`). Its
verification leg walked YAML keys ending in `_by`. **Prose is invisible to a key-walker.**

Found while answering the operator's question "what is H2?" — not by any check I wrote.
Three residual sites still assert the resolution as fact:

1. `handoff-ewcr-v1-designer-fixture.yaml:315` — `why_prepared_and_not_sent` attributed the
   999 counterparty to an operator ruling on H2 and declared identification no longer a
   blocker, leaving only authorisation and transport. This is the whole defect restated in
   a free-text field, and worse than the original: it tells a reader the matter is settled.
2. `.tasks/active/T-590-…md:558` — the Envelope-state summary described H2 as settled in
   favour of 999 and `to_project` as filled.
3. `tag: counterparty-named` on T-590's frontmatter — a tag whose name asserts the
   counterparty has been named.

The offending sentences are **paraphrased above, not quoted**. Quoting them here would
leave the false assertion searchable in a fourth file and would blind the very check this
task adds — the same mistake in a new place. The verbatim text is preserved where it
belongs, in git history (`76556cd2`, and this task's diff).

This is PL-145 in a new costume — *a ruling filed as PROSE is invisible to every instrument
that looks for rulings* — and the framework surfaced PL-145 to me when I created T-593.
The lesson was on screen and the leg still only checked structure.

## Acceptance Criteria

### Agent
- [x] No prose in any EWCR artifact asserts that the operator resolved, decided, chose or
      named the H2 counterparty
- [x] The envelope's `why_prepared_and_not_sent` no longer claims identification is settled;
      it names H2 as an open blocker alongside authorisation and transport
- [x] T-590's Envelope-state line reads `H2 is UNRESOLVED`, matching the artifact it
      describes
- [x] The `counterparty-named` tag is removed from T-590's **frontmatter** — a tag is a
      claim, and this one is false until the operator answers. (Not a blanket string purge:
      the envelope's `tag_not_applied` block and T-590's Updates entry are *records* of what
      happened and are preserved. A first draft of this AC would have deleted both — the
      leg was corrected before it forced the fix to destroy governance history.)
- [x] T-590's Human AC no longer instructs the operator to apply `counterparty-named`
      unconditionally — applying it is conditional on them answering H2 first
- [x] The T-593 verdict still holds: structured fields remain clean (`status: unresolved`,
      no truthy `*_by`, `to_project: null`, both candidates retained)
- [x] A verification leg exists that would have caught THIS class — scanning prose, not just
      keys — and it is poison-controlled in both directions
- [x] `sha256sum -c` passes 6/6 from the repo root after re-pinning; T-590 still passes its
      full verification block

### Human
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
# ⚠ ERREXIT WARNING (T-352) — READ BEFORE USING THE CAPTURE PATTERN BELOW.
# P-011 runs each command under `-o pipefail` but NOT under an effective `-e`.
# Measured, not assumed (tools/_t352-p011-errexit-probe.sh): the gate runs each line as
# `if ( … eval "$cmd" ); then` (update-task.sh:1018) and that subshell is the CONDITION
# of an `if`, which neutralises errexit inside it. pipefail survives; errexit does not.
# CONSEQUENCE: a line of the form `a; b` IS JUDGED ON `b` ALONE. `a`'s exit code is
# discarded, so a command that fails outright can still leave the line green.
#   Proven false green:
#     out=$(python3 tools/validate-workflow.py BROKEN.bpmn 2>&1); echo "$out" | grep -q "VALID"
#   -> PASSES on a document the validator exits 2 on and labels INVALID, because
#      `grep -q "VALID"` matches INVALID as a SUBSTRING. Two defects stacked.
# PREFER a single command whose own exit code is the verdict — then no context question
# arises. When you must chain, the LAST command has to be the one that can fail, and its
# pattern must not be matchable by the earlier command's FAILURE output.
# Note `set -e` re-issued inside the subshell does NOT fix this: the suppressed context is
# inherited and re-setting the option does not clear it. See T-352 for the remedy.
#
# Pipefail/SIGPIPE hint (L-387): `cmd | grep -q PATTERN` exits 141 (SIGPIPE) when grep
# matches and closes stdin while the upstream is still writing — verification then
# "fails" even though the pattern was present. The capture pattern below fixes THAT,
# and creates the errexit exposure described above; the file form fixes both:
#     cmd > /tmp/.out 2>&1 && grep -q "PATTERN" /tmp/.out     # PREFERRED: && not ;
#     out=$(cmd 2>&1); echo "$out" | grep -q "PATTERN"        # SIGPIPE-safe, errexit-blind
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
# T-594 legs. The point of this task is that T-593's legs walked STRUCTURED KEYS and could
# not see a claim written in prose. Leg 1 is the one that would have caught it. Bare
# commands and `! grep -qE` only — no `cmd | grep -q` (T-592).

# 1. PROSE SCAN — the check T-593 was missing — lives in leg 7's script, not inline here.
#    Written inline first, it MATCHED ITSELF: a grep-for-absence whose pattern spells out
#    the forbidden phrases is a line containing those phrases, so the leg went red on its
#    own text. Defining the pattern in exactly one place (the script) fixes that and keeps
#    the scan and its poison control from drifting apart. See leg 7.
# 2. The false claim that identification is settled is gone.
! grep -qE "not identification|blocker is authorisation and transport, not" docs/research/executable-workflow/handoff-ewcr-v1-designer-fixture.yaml
# 3. The tag asserting the counterparty is named is out of T-590's FRONTMATTER. Scoped to the
#    frontmatter deliberately: the envelope's `tag_not_applied` block and T-590's Updates
#    entry are RECORDS of what happened, and a blanket `! grep -q counterparty-named` would
#    have forced the fix to delete governance history to go green.
python3 -c "import re;s=open('.tasks/active/T-590-ewcr-arc-0-designer-contract-inventory-a.md',encoding='utf-8').read();fm=s.split('---')[1];t=re.search(r'^tags: *\[(.*)\]',fm,re.M).group(1);assert 'counterparty-named' not in t,t"
# 3b. ORDERING, not string presence: within T-590's H2 acceptance criterion, "Record the
#     choice" must come BEFORE the --add-tag step, so the tag follows the decision rather
#     than standing in for one. Keyed on order because a leg keyed on quoting style would
#     be brittle and would not express the property that actually matters.
python3 -c "import re;s=open('.tasks/active/T-590-ewcr-arc-0-designer-contract-inventory-a.md',encoding='utf-8').read();i=s.find('Answer H2');b=s[i:i+1600];r=b.find('Record the choice');t=b.find('--add-tag');assert i!=-1 and r!=-1 and t!=-1 and r<t,(i,r,t)"
# 4. T-593's verdict still holds — this task must not regress the structured fields.
python3 -c "import yaml;d=yaml.safe_load(open('docs/research/executable-workflow/handoff-ewcr-v1-designer-fixture.yaml'));r=d['to_project_resolution'];assert r['status']=='unresolved' and d['to_project'] is None and not r.get('resolved_by') and len(r['candidates'])==2,r"
python3 -c "import yaml;d=yaml.safe_load(open('docs/research/executable-workflow/handoff-ewcr-v1-designer-fixture.yaml'));bad=[];w=lambda n,p:[ (bad.append((p+'.'+k,v)) if (k.endswith('_by') and v) else None) or (w(v,p+'.'+k) if isinstance(v,dict) else None) for k,v in n.items()] if isinstance(n,dict) else None;w(d,'');assert not bad,bad"
# 5. H2 is still named as an OPEN blocker — removing the false claim must not delete the question.
grep -q "H2" docs/research/executable-workflow/handoff-ewcr-v1-designer-fixture.yaml
# 6. Hash pins and T-590's own block survive.
sha256sum -c docs/research/executable-workflow/source-manifest.sha256
# 7. The prose leg has TEETH — poison a copy, require rejection; accept the real tree.
bash tools/_t594-prose-claim-teeth.sh

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

**Symptom:** After T-593 "fixed" the manufactured operator resolution of H2, the envelope
still told any reader that the counterparty was settled by operator ruling and that
identification was no longer a blocker — in a free-text field, three lines from the
correction that said the opposite.

**Root cause:** T-593's verification walked YAML **keys** (`*_by`, `status`, `to_project`).
The same claim also lived in prose. A key-walker cannot see prose, so the leg reported
green over a file that still carried the defect it was written to catch.

**Why structurally allowed:** the fix and its check were scoped to the shape the defect
*happened to take first*, not to the claim itself. Once the structured fields were clean,
every instrument agreed the task was done: 8/8 legs, 6/6 hashes, a GO verdict. Nothing
measured the assertion, only its encoding. This is PL-145 — *a ruling filed as PROSE is
invisible to every instrument that looks for rulings* — which the framework printed on
screen when T-593 was created. Having the lesson available is not the same as applying it.

**Prevention:** a prose-scanning leg now runs over the artifacts, T-590 **and this task
itself**, with `tools/_t594-prose-claim-teeth.sh` proving it rejects four different
phrasings and that the pattern is not inert. The generalisation — that a claim must be
checked in every encoding it can take, not the one you first found — is the operator's
[REVIEW] call below, since it is a rule about how verification is written.

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

## Recommendation

**Recommendation:** GO.

**Rationale:** This is a correction of my own incomplete fix, not a judgement call. T-593
removed the manufactured operator resolution from the structured fields and I reported it
as done; the same claim was still sitting in prose, telling any reader — including the
counterparty — that H2 was settled. Nothing here decides H2. It is still yours, and it is
still the only blocker on EWCR delivery.

Worth saying plainly: this was found because you asked "what is H2?", not by any check I
wrote. T-593's own verification was green over it.

**Evidence:**
- 4 sites corrected: the envelope's `why_prepared_and_not_sent`, T-590's Envelope-state
  line, T-590's frontmatter tag, and T-590's H2 step ordering (record the decision *then*
  tag it, so the tag follows the decision instead of standing in for one).
- P-011: **9/9 legs passed**. T-590 re-run and **still 18/18**. Manifest **6/6**.
- `tools/_t594-prose-claim-teeth.sh`: **6/6** — the real tree is accepted, four *different*
  phrasings of the claim are each rejected, and the regex is proven capable of matching at
  all (an absence-check that can never match is vacuous by construction).
- The control earned its keep twice. First it went red on my own correction notes, which
  quoted the false sentence verbatim — and that contamination had also made the poison arms
  meaningless, since the poisoned copies would have failed regardless of the poison. Both
  were fixed: notes paraphrase, and the leg now covers this task's own file too.
- Governance history preserved: a first draft of the tag AC would have deleted the
  envelope's `tag_not_applied` record and T-590's Updates entry to go green. The leg was
  narrowed to the frontmatter claim instead of the fix being widened to destroy records.
- Detector reports **0** vacuous legs contributed by T-594.

**What I did not do:** decide H2, touch the frozen standard, or adopt the generalised rule
under initiative.

## Decisions

### 2026-08-26 — paraphrase the false claim rather than quote it

- **Chose:** In every correction note, describe what the text asserted instead of
  reproducing it, and extend the prose leg to cover this task's own file.
- **Why:** A correction that quotes the false sentence leaves it searchable in one more
  file and blinds the check guarding it. Consistency matters more than fidelity here — the
  verbatim wording is preserved in git history, which is where a record belongs.
- **Rejected:** (a) quoting verbatim for fidelity — that is what tripped the control;
  (b) exempting task files from the leg — the defect does not care which file it is in, and
  an exemption written for my own convenience is how the next instance survives.

<!-- Record decisions ONLY when choosing between alternatives.
     Skip for tasks with no meaningful choices.
     Format:
     ### [date] — [topic]
     - **Chose:** [what was decided]
     - **Why:** [rationale]
     - **Rejected:** [alternatives and why not]
-->

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-08-26T14:42:18Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-594-residual-prose-still-claims-the-operator.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-b6672488
- **Timestamp:** 2026-08-26T14:47:51Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** yes
- **Findings:** none

- **Layer-1 escalations:** 1
  1. **destructive-action** (high) — Destructive operation in verification or AC
     - matched: `destroy`

### 2026-08-26T14:47:49Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed

### 2026-09-03T05:18:33Z — status-update [task-update-agent]
- **Change:** tags: +arc:ewcr-governed-delivery
