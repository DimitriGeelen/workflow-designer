---
id: T-589
name: "designer properties panel: add a clickable component-fabric link and a URL field for code/tests"
description: >
  designer properties panel: add a clickable component-fabric link and a URL field for code/tests

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
created: 2026-08-25T22:39:21Z
last_update: 2026-08-26T09:27:38Z
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

# T-589: designer properties panel: add a clickable component-fabric link and a URL field for code/tests

## Context

Operator ask: the properties panel on the right of the designer — the box carrying
`Endpoint`, `Agent type`, `Tier` — needs two more fields:

1. a **link to the component fabric**, clickable through to the card
2. a **place for URLs** (code, tests)

### The design question, answered before building

The obvious risk was that new fields mean a **dialect change**: a new `aef:` element or a
new `metaKeys` entry, which breaks ratified parity with `tools/yaml-to-bpmn.py META_KEYS`
(`tests/test_editor_bridge_meta_parity.py`) and puts the frozen standard —
`docs/standards/aef-bpmn-mapping-v1.md`, not editable under agent control — in scope. That
would make this a coordination with 999-AEF rather than a build, exactly like CashWeb's
parked `<aef:pseudo>` ask.

**It is not.** T-570 already removed the blocker: import reads EVERY `<aef:meta>` attribute
into `node.aef` unconditionally, and export stopped filtering the bag on the way out
(`aefExtensionXml`, the `scalarHandled` skip set at :9605). `<aef:meta>` is already a bag of
scalar attributes. So two new **scalar** fields ride the existing carriage with no new
element, no `metaKeys` change (stays at 20), and nothing for AEF to ratify.

The constraint this imposes on the design: both fields must be **scalars**. A structured
value would need its own emitter and would then be a contract change. `links` therefore
holds newline-separated URLs in one string, not an array.

Before T-570 this same change would have silently DESTROYED both fields on the next save —
loaded, rendered nowhere, dropped on re-export. Worth stating because "add a field to the
panel" reads as trivial and was, until recently, a data-loss bug.

### Consumer evidence — arrived independently, twenty minutes after filing

001-CashWeb-Lightspeed-Ecwid-integration reported hitting exactly this ceiling in
production on `designer-v0.11.0`. Their operator's ask is *"click a node, GO TO the API test
and the code"* — the same sentence as this task, reached from the other side.

**Their measurement, re-run here against `src/aef-workflow-designer.html` rather than
taken on trust — every figure confirmed:**

| probe | theirs | ours |
|---|---|---|
| `linkify` | 0 | 0 |
| `window.open` | 0 | 0 |
| `location.href` | 0 | 0 |
| `<a ` literal | 0 | 0 |
| `createElement('a')` | 1 (download button) | 1, at `:8409` |

So the designer today **cannot navigate anywhere**. That is not a gap in this task's design,
it is the reason the task exists, and it means the anchor-rendering path is genuinely new
code rather than a variant of something already present.

They also confirmed T-566 and T-570 with numbers that reframe both:

- **T-566** — `note` is on all 14 node types in 0.11.0 and was on **zero** in 0.8.0. Their
  phase-1 map already carried **ten authored notes no operator had ever been able to see.**
  We described that fix as "46% unreadable"; on their side it was ten invisible facts.
- **T-570** — their `code-links.yaml` recorded three reasons the node→code binding was
  deliberately kept OUT of the `.bpmn`, one being *"an editor Save destroys prose the pinned
  build does not know about"*. T-570 retired that reason. They now write each node's
  implementing file and its API-test call id into `aef:meta note`. **Our carriage fix is
  load-bearing for a consumer's data model**, which is a stronger claim than the round-trip
  test makes.

### Their option (a) — NOT this task, and not authorised by their asking

They propose two shapes and prefer the one this task does not cover:

- **(b)** render a URL-shaped value in a known field as an anchor — **this task.**
- **(a)** emit an outbound `aef:select {uid}` on the annotation seam when a node is
  selected, so an embedding parent can render links beside the canvas and keep all policy
  consumer-side.

(a) is smaller than (b) and serves embedders rather than our own panel; they are
complementary, not alternatives. It is deliberately **not** folded in here — one task, one
deliverable — and a peer proposal is a PROPOSAL, not a build instruction (G-020). It also
adds an outbound message to the T-258 seam that other consumers parse, so whether to extend
that seam is the operator's call. Filed as evidence, not as scope.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] `fabricRef` and `links` exist in `FIELD_META` and appear in the `AEF_FIELDS` lists for
      the task-like node types that can carry an implementation (`serviceTask`,
      `scriptTask`, `subProcess`, `userTask`), ordered ABOVE `note` so they do not push the
      structured fields down (the ordering rule stated at :1844).
      <br>**Evidence:** leg `fields-render-above-note` — measured in the rendered panel, not
      read off the lists: `fabric@12 links@13 note@14`. Leg `gateway-not-offered` is the
      other arm: an `exclusiveGateway` is offered neither.
- [x] `fabricRef` renders as a **clickable link** to Watchtower's existing
      `/fabric/component/<name>` route when non-empty, and renders as a plain field with no
      dead link when empty. The href resolves against the origin that served the page,
      never a hard-coded `:3000` port.
      <br>**Evidence:** leg `fabric-anchor-root-relative` —
      `href="/fabric/component/bpmn-cli" target=_blank rel="noopener noreferrer"`. Leg
      `empty-field-no-dead-link` — the plain node offers the field and renders **0** fabric
      anchors. End-to-end against the live Watchtower:
      `curl /fabric/component/bpmn-cli` → `<title>Component: bpmn-cli</title>`.
      <br>**AC wording corrected during build:** this AC originally said the href is "built
      from the live watchtower URL (`.context/working/watchtower.url`)". That is not
      buildable — the designer is a browser page and cannot read a file in the repo. The
      root-relative href is the *stronger* form of the same requirement: it resolves against
      whatever host and port actually served the page, so it follows a moved Watchtower for
      free. The port really has moved — Watchtower serves on **3013**, so a hard-coded 3000
      would already be wrong today.
- [x] `links` accepts multiple URLs (newline-separated) and renders each as a separate
      clickable anchor; a line that is not a URL is shown as text rather than a broken link.
      <br>**Evidence:** leg `links-each-line-anchored` — 5 lines in, 2 anchored
      (`https://example.test/src/orders.js`, `/fabric/component/bpmn-cli`), prose line still
      present as text. Leg `unsafe-shapes-are-text-not-links` — `javascript:alert(1)` and the
      protocol-relative `//evil.example/x` are **not** made clickable and are **not**
      swallowed either; both still render as muted text.
- [x] **Both fields survive a round trip**, proven by an actual parse -> build -> parse in
      the page rather than by reading the two lists — that is the T-570 lesson, where
      inspecting the whitelists said the keys were fine and the round trip said they were
      destroyed.
      <br>**Evidence:** leg `roundtrip-both-keys` — all 4 keys survive parse→build→parse and
      `links` keeps all **5** of its lines, i.e. the newlines survive attribute-value
      normalisation via `escAttr`'s `&#10;` (T-521). Compared against what IMPORT produced,
      not against a hand-written list, so the leg cannot drift from the fixture.
- [x] `metaKeys` is still 20 entries and bridge parity still passes
      (`tests/test_editor_bridge_meta_parity.py`), proving this was carried by the existing
      `<aef:meta>` bag and is NOT a contract change.
      <br>**Evidence:** `test_editor_bridge_meta_parity.py` → `OK: all 20 editor metaKeys …
      present in bridge META_KEYS (29 keys)`, exit 0. Leg `no-contract-change` —
      `metaKeys=20`, two exports byte-identical, and the emitted attribute order is
      `["tier","note","fabricRef","links"]`: both new keys ride as **carried** attributes
      after the known ones, exactly as T-570's shape-derived skip set intends.
- [x] Exporting a document that carries NEITHER field is **byte-identical** to before the
      change. Adding an authorable field must not perturb documents that do not use it.
      <br>**Evidence:** leg `byte-identical-when-unused` — the same key-free document is
      exported by the **pre-change build** (`git show HEAD:src/…`) and by this one in the
      same run, and the bytes match at 3381. Not compared against a stored golden, which
      would only have proved the golden. One `<aef:workflowMeta uuid>` is minted fresh per
      page load and is masked; the mask is required to fire **exactly once per side** or the
      leg throws rather than comparing under a mask that is hiding more than it claims.
- [x] Visual verification per CLAUDE.md: element-level screenshots of the panel with each
      field empty and populated, READ back, with the results recorded under
      `## Visual Verification`.
      <br>**Evidence:** see `## Visual Verification` — two element-level screenshots taken,
      both read back.

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

- [ ] [REVIEW] Each URL appearing twice — once in the editable box, once as the rendered
      anchor below it — is acceptable, or you want a different shape
  **Steps:**
  1. `cd /opt/832-Workflow-designer && .agentic-framework/bin/fw serve-src` is NOT the route —
     `/designer` serves a pinned build without this change. Instead run this single line and
     open the URL it prints:
     `cd /opt/832-Workflow-designer && P=$(python3 -c "import socket;s=socket.socket();s.bind(('127.0.0.1',0));print(s.getsockname()[1])") && D=$(mktemp -d) && cp src/aef-workflow-designer.html "$D/designer.html" && (python3 tools/gallery-serve.py $P --repo "$(mktemp -d)" --docroot "$D" --bind 0.0.0.0 &) && sleep 2 && echo "http://192.168.10.107:$P/designer.html"`
  2. Open any map, click a serviceTask, scroll the right-hand panel to **Links**.
  3. Type two URLs on separate lines and click elsewhere to commit.
  **Expected:** the textarea keeps the raw text you typed; the clickable anchors render
  underneath it. Both are present at once, by design.
  **If not / if you dislike it:** say which you'd rather have — anchors only when the field
  is not focused, a collapsed "N links" summary, or leave as is. It is a one-branch change
  in the `linkList` renderer; I did not pick a shape for you.

- [ ] [REVIEW] `Fabric component` is the right field name and the right target
  **Steps:**
  1. In the same panel, set **Fabric component** to `bpmn-cli` and click elsewhere.
  2. Click `→ open bpmn-cli card`.
  **Expected:** Watchtower opens the component card for `bpmn-cli` in a new tab.
  **If not:** note whether the wrong page opened (route problem) or nothing is clickable
  (render problem) — they have different fixes.

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

# Bridge parity: both new keys must be carried by the EXISTING <aef:meta> bag, so metaKeys
# stays at 20 and the ratified parity with tools/yaml-to-bpmn.py META_KEYS is untouched.
python3 tests/test_editor_bridge_meta_parity.py
# The panel probe: 10 legs, including the pre-change build as a control arm. Exit 0 only —
# exit 1 is a failed leg and exit 2 is "could not look", which is NOT a pass.
node tools/_t589-panel-links-cdp.mjs > /tmp/.t589-probe.out 2>&1 && grep -q "10/10 T-589 legs passed" /tmp/.t589-probe.out
# The control arm must actually be a control: if the HEAD build already rendered anchors for
# the fixture, every leg below it is vacuous. Assert the leg is present AND passing by name.
grep -q "^PASS  control-baseline-cannot-navigate" /tmp/.t589-probe.out
# The whitelist leg specifically — a regression that starts linkifying javascript: URLs would
# still leave 9 legs green, so this one is named rather than left to the aggregate count.
grep -q "^PASS  unsafe-shapes-are-text-not-links" /tmp/.t589-probe.out

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

## Visual Verification

Screenshots are element-level (the two field wrappers, lifted into one container), taken
against a **locally served copy of the working tree** — not against `/designer`.

**FP-009 fired again and was caught by checking, not by luck.** Watchtower's `/designer`
route serves sha `9b02697c…` while the working tree is `07b8b161…`; the served build
contains **zero** occurrences of `fabricLink`. Screenshotting the operator-reachable
designer would have produced pictures of a build without this change in it. The probe
server was verified to serve the working-tree sha byte-for-byte before any screenshot.

**Modes covered: one, and that is the whole set.** The designer has no theme, density or
font switching — `data-theme` 0, `prefers-color-scheme` 0, `.theme-light` 0, density/font
mode 0, and exactly one `--accent:` declaration in the file. So "every visual mode the
change can affect" is a single mode here; this is recorded as a measured fact rather than
as a skipped step.

| shot | what it shows | read back |
|---|---|---|
| `.playwright-mcp/t589-populated.png` | Both fields on a node carrying values: `Fabric component` input `bpmn-cli` with `→ open bpmn-cli card` underlined beneath it; `Links` textarea with 5 lines, followed by **2 underlined anchors** and **3 muted plain rows** | yes |
| `.playwright-mcp/t589-empty.png` | The same two fields on a node carrying neither: two empty inputs, **no anchor, no dead link** | yes |

**Colour was verified by computed style, not by eye.** In the rendered PNG I read the two
link rows as blue and the fabric link as lime — an inconsistency that would have been a real
defect, since both come from the same `linkRow()`. Measured instead: all three anchors are
`rgb(196, 238, 84)`, which is `--accent: #c4ee54`. The screenshot was right and my reading of
it was wrong. Recorded because the usual failure runs the other way (DOM math agreeing while
the render is broken); here the render was fine and the eye was the unreliable instrument.
What the screenshot *is* good for — that 2 of 5 lines are underlined links and 3 are not —
is exactly what it confirms.

**Not a defect, but the operator's call:** each URL now appears twice — once inside the
editable textarea and once as the rendered anchor below it. That is the direct consequence
of a field that is both authorable and navigable. Raised as a Human AC rather than resolved
by my own taste.

## Evolution

### 2026-08-26 — T-570 had already made these keys VISIBLE; what was missing was authorable and clickable

- **What changed:** the probe's control arm was written to assert that the pre-change build
  "does not surface fabricRef". It **failed**, and the harness was the thing that was wrong.
  T-570 also added an *Other extensions* readout (`:5953`) that discloses every carried
  scalar read-only under its **raw key name**. So HEAD already showed both values; what it
  could not do was navigate to them or let anyone edit them.
- **Plan impact:** the task's framing — "the designer cannot navigate anywhere" — is still
  true and is still the gap (HEAD renders **0** anchors, confirmed). But the change is
  narrower than "make invisible data visible": it is **promotion**, from read-only
  disclosure to authorable field plus anchor. The control arm now asserts that narrower,
  truer thing, and a new leg requires the keys to *leave* the read-only readout when they
  become fields — one fact, one surface, because two surfaces drift into disagreeing.
- **Triggered:** no new task. Rewritten in place as leg 1 and leg 2 of the probe.

### 2026-08-26 — a leg that passed because it could not read the panel

- **What changed:** `.field-label` carries the label as a text node and then appends a hint
  span, so `.textContent` is `"Fabric component· component card name · opens the card"`.
  Every exact-match lookup against it returned −1. That made the "a gateway is offered
  neither field" leg report **PASS** — not because the gateway was clean, but because no
  label could ever equal any string it compared against.
- **Plan impact:** this is the week's recurring shape landing inside my own instrument: a
  green that means "did not look". Fixed by reading the label's first text node. Two other
  legs were failing loudly for the same root cause, which is the only reason it surfaced —
  had the panel happened to contain no gateway, it would have shipped green.
- **Triggered:** no new task; the fix and the reason are in the probe's own comments so the
  next reader of that leg knows what it is guarding against.

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

### 2026-08-26 — the fabric href is root-relative, not built from a configured base

- **Chose:** emit `href="/fabric/component/<name>"` and let the browser resolve it against
  the origin that served the page.
- **Why:** the designer is served at `/designer` by the same Watchtower that serves
  `/fabric/component/<name>`, so a root-relative href is correct by construction and follows
  a moved or re-pointed Watchtower with no configuration. It is also the only form that
  *can* work: the AC as originally written said "built from `.context/working/watchtower.url`",
  and a browser page cannot read a file out of the repo.
- **Rejected:** a hard-coded `http://…:3000` (already wrong — Watchtower serves on 3013, and
  the port is owned by the triple file, not by the source); baking the URL in at build time
  (pins the link to whatever the port was on the day the artifact was cut, which is the
  same class of staleness as FP-009).

### 2026-08-26 — what becomes a link is a WHITELIST

- **Chose:** only `https?://…` and root-relative `/path` render as anchors. Everything else
  renders as muted text, including `javascript:`, `data:` and protocol-relative `//host/x`.
- **Why:** this value is authored in one project and rendered inside another's embedded
  designer — 001-CashWeb runs our build against their map. The rendering side must not have
  to trust the authoring side. A blacklist of "schemes I know are dangerous" has to stay
  correct forever and is wrong the first time it is incomplete; a whitelist fails closed.
  `//host/path` gets an explicit mention because it *looks* root-relative and resolves
  off-origin.
- **Rejected:** linkifying anything containing `://` (admits every scheme); trusting the
  author because the field is ours (it is not — a consumer's document reaches this code).
- **Note:** a non-navigable line is still SHOWN. Silently dropping a line the author typed
  would be a small version of exactly the data loss T-570 fixed.

### 2026-08-26 — `links` is newline-separated text, not an array

- **Chose:** one scalar string holding one URL per line.
- **Why:** T-570's carriage only carries **scalars** (`typeof aef[k] !== 'object'`). A
  structured value would need its own emitter, which is a new `aef:` element, which is a
  contract change requiring AEF ratification and a frozen-standard bump. The scalar form
  costs nothing and ships today. Confirmed by measurement, not by reading the whitelist:
  `metaKeys` is still 20, bridge parity passes, and the two keys appear as carried
  attributes after the known ones.
- **Rejected:** `<aef:links><aef:link href=…/></aef:links>` (correct-looking and turns an
  afternoon into a cross-project negotiation — the same trap as CashWeb's parked
  `<aef:pseudo>` ask).

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

### 2026-08-25T22:39:21Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-589-designer-properties-panel-add-a-clickabl.md
- **Context:** Initial task creation
