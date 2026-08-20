# Remediation Proposal: Map ID Round-Trip and Validation Defects

**Task:** T-501 (Map ID round-trip defect triage)  
**From:** AEF consumer report (CashWeb-Lightspeed-Ecwid-integration / T-019)  
**Scope:** Three separable defects (D1, D2, D3) + round-trip closure  
**Date:** 2026-08-14 · **§0 added 2026-08-20 after re-measurement**

---

## §0 — WHAT THIS DOCUMENT GOT WRONG (read before §1)

Added 2026-08-20. Everything below §0 is the 2026-08-14 text, unedited. This section
says which of its claims survived measurement and which did not. It is at the top
because a reader who opens this file at the decision gate is being asked to approve
its recommendation, and one of the things that changed is the recommendation.

**The document and the task disagreed about the answer.** This file says
`Recommendation: GO` (§Executive Summary). `.tasks/active/T-501-*.md` says
`Recommendation: DEFER`. Both were written on 2026-08-14, neither cites the other,
and the Human AC sends the operator to `fw task review T-501`, which renders the
*task's* recommendation while this file sits open beside it saying the opposite.
Neither was re-derived from the source. This is the OBS-291 class — a document that
stopped tracking the task it represents — with the sharper property that the two
artifacts contradict each other on the single field the gate exists to decide.

### C-1 — The three defects are REAL and still present at v0.10.0 (claim stands)

Verified against `src/aef-workflow-designer.html` on 2026-08-20. The line numbers in
this document have drifted (the file grew from ~10.1k to 10,612 lines) but the code
at each site is byte-for-byte what §D1/§D2/§D3 quote:

| Defect | Claimed line | Actual line at v0.10.0 | Code |
|---|---|---|---|
| D1 fallback to display name | 9845 | **9950** | `id: aefMetaEl?.getAttribute('id') \|\| procName \|\| 'imported',` |
| D2 sanitizer (properties panel) | 5183 | **5223** | `.trim().toLowerCase().replace(/[^a-z0-9_\-]/g, '-')` |
| D2 validator (save) | 8393 | **8433** | `if (!/^[a-z0-9][a-z0-9_-]*$/.test(id))` |

### C-2 — D2 has a THIRD site this document never found

`renameActiveWorkflow()` at **line 2685** applies the identical sanitizer and the
identical missing leading-character rule. §D2 lists two sites and proposes unifying
them; unifying two of three leaves the rename path still able to mint `-cash-sync`.

### C-3 — The fix this document proposes ALREADY EXISTS IN THE TREE, three lines away

`createFromPendingRef()` at **line 9162** is the correct rule, written for ghost
adoption and never generalised:

```js
let base = String(ghost.name || 'workflow').trim().toLowerCase()
             .replace(/[^a-z0-9_\-]/g, '-').replace(/^-+|-+$/g, '') || 'workflow';
```

That is `sanitizeWorkflowId()` from §D2, already implemented and already shipping.
§D2 proposes writing it from scratch. The work is to *lift* it to a shared helper and
call it from all four sites (2685, 5223, 9162, and the new load-time site), not to
author it.

### C-4 — THE D1 FIX AS WRITTEN WOULD BE A REGRESSION. Do not implement it.

§D1 proposes:

```js
id: aefMetaEl?.getAttribute('id') || deriveSlug(procId) || deriveSlug(procName) || 'imported',
```

`deriveSlug()` (line 1658) is **not a slugifier**. It is a *summariser*, written for
node labels: it takes the first word longer than one character and truncates to 16
chars. Applied to an identifier it discards the identifier.

Measured over the 60 BPMN documents in `examples/aef-processes/rendered`,
`tests/fixtures/aef-bpmn`, `tests/fixtures/third-party` and
`tests/fixtures/lane-provenance` (script in §0.1, re-runnable):

- **46 carry `<aef:workflowMeta>`; 14 do not** — those 14 are the live fallback path.
- **Today: all 14 of 14 derive an id the save validator rejects.** The defect is
  total on that path, not partial. This is *stronger* than §D1 claims.
- **Under the proposed fix: 14 files collapse to 4 distinct ids** — `process` ×8,
  `proc` ×4, `id` ×1, `009164cd` ×1 — and **every one of the four passes the
  validator.**

So the proposed fix converts a loud, total, save-time failure into a silent,
near-total collision. `bizagi-nested-ns.bpmn` (`Id_f2afc6ec-e5fc-…`) becomes the
literal string `id`. The consumer's own reported map, `name="Cash to Ecwid stock
sync"`, becomes `cash`. That is the failure mode this project has been finding all
week: the broken state renders as health.

**And three of the four branches are unreachable.** `deriveSlug()` is total — it
returns `'node'` for empty input and can never return a falsy value — so
`deriveSlug(procId)` always short-circuits the chain. `deriveSlug(procName)` and
`'imported'` are dead code in the proposed line. `procId` is itself already
`|| 'imported'` at line 9947, so the guard is doubly dead.

**The correct transform is C-3's, applied to the identifier.** Same 14 files, same
script: **10 distinct ids, 0 invalid.** `Process_0dp8lmr` stays `process_0dp8lmr`
instead of becoming `process`.

### C-5 — The one collision that survives is real, and the tree already handles it

Under the correct transform, 5 of the 14 still collide — on `process_1`, because five
different third-party fixtures literally declare `<bpmn:process id="Process_1">`
(Camunda's default). No transform can separate them; the information is not in the
document. That collision is honest and it is **already handled**: `loadBpmnIntoLibrary`
at line 9214 appends `_v<n>` until unique and writes the result back to
`workflowMeta.id`.

This is the load-bearing point for scoping. The `_v<n>` policy sits *downstream* of
the transform, so the transform decides what it is disambiguating. With the correct
rule the operator sees `process_1`, `process_0dp8lmr`, `process_0k3ryf8` and one
`_v2…_v5` run over genuinely identical inputs. With `deriveSlug` they see
`process`, `process_v2` … `process_v8` — eight distinct documents rendered as serial
numbers, because the distinguishing bytes were destroyed before the policy could use
them. §D1's risk table rates this phase "Medium"; the risk is not in changing
derivation, it is in *which* function does the deriving.

### C-6 — Claims this document makes that are NOT verifiable from this repository

- *"Corpus measurement: 126 of 145 hand-authored BPMN have NO workflowMeta"* (§Round-Trip
  Closure) and the *"145-file sweep"* in §Testing Strategy refer to the **consumer's**
  tree (001-CashWeb). Under the T-559 boundary we cannot read it. **Neither number was
  checked here and neither should be cited as evidence in this repository.** The
  832-side equivalent, measured above, is 14 of 60.
- §Consumer Impact's claims about the v0.8.0 vendored build are unverified here.

### C-7 — A measurement error of my own, recorded because it is the same class

The first pass at the §0.1 census used a regex (`<bpmn:process\b[^>]*>`) instead of an
XML parser and reported **7** of 14 invalid under the current rule, plus a phantom
`imported ×7` collision bucket. Both were artifacts of the regex failing on multi-line
and namespace-prefixed process elements. The corrected figure is 14 of 14. A measuring
instrument that silently under-reports is the defect this task is about; it was
re-run with `xml.etree` before any conclusion was drawn, and the wrong first number is
left here rather than deleted.

### §0.1 — The census, re-runnable

```python
import os, re, collections, xml.etree.ElementTree as ET
roots = ['examples/aef-processes/rendered', 'tests/fixtures/aef-bpmn',
         'tests/fixtures/third-party', 'tests/fixtures/lane-provenance']
BPMN = '{http://www.omg.org/spec/BPMN/20100524/MODEL}'
VAL  = re.compile(r'^[a-z0-9][a-z0-9_-]*$')

def derive_slug(s):                      # src:1658 — the SUMMARISER (proposed, wrong)
    if not s: return 'node'
    w = [x for x in re.split(r'[\s\-]+', re.sub(r'[^a-z0-9\s\-]', ' ', s.lower())) if len(x) > 1]
    return (w[0] if w else 'node')[:16]

def slugify_id(s):                       # src:9162 — the SLUGIFIER (already in tree, right)
    t = re.sub(r'[^a-z0-9_\-]', '-', (s or '').strip().lower())
    return re.sub(r'^[-_]+|[-_]+$', '', t) or 'workflow'

rows = []
for root in roots:
    for dp, _, fns in os.walk(root):
        for fn in sorted(fns):
            if not fn.endswith(('.bpmn', '.xml')): continue
            r = ET.parse(os.path.join(dp, fn)).getroot()
            if any('workflowMeta' in el.tag for el in r.iter()): continue   # fallback not reached
            p = [el for el in r.iter(BPMN + 'process')]
            rows.append((fn, p[0].get('id') if p else None, p[0].get('name') if p else None))

for label, fn_ in (('current  ', lambda i, n: n or i or 'imported'),
                   ('proposed ', lambda i, n: derive_slug(i or 'imported')),
                   ('corrected', lambda i, n: slugify_id(i or 'imported'))):
    ids = collections.Counter(fn_(i, n) for _, i, n in rows)
    bad = sum(1 for _, i, n in rows if not VAL.match(fn_(i, n)))
    print('%s: %d files -> %d distinct, %d invalid' % (label, len(rows), len(ids), bad))
```

Expected on 2026-08-20 (`src` at v0.10.0):

```
current  : 14 files -> 14 distinct, 14 invalid
proposed : 14 files ->  4 distinct,  0 invalid     <-- silent collision
corrected: 14 files -> 10 distinct,  0 invalid
```

### §0.2 — What this changes about the recommendation

The 2026-08-14 GO was for a package whose headline item would have made things worse.
The 2026-08-14 DEFER was right to hesitate and wrong about why — it cites unscoped
cost and vendored-build risk, and the actual blocker was that nobody had run the
derivation against a corpus. It has now been run. The revised recommendation, its
conditions and its remaining open question are on the task, not here, because the
task is what `fw task review` renders.

---

## Executive Summary

Three separable defects prevent hand-authored BPMN without `<aef:workflowMeta>` from round-tripping correctly. All three are localized, independent fixes with bounded scope. The root cause (D1) is a category error: map identity derives from a display name instead of an identifier. Fixes are implementable in parallel and validate independently.

**Recommendation: GO** — Implement all three defects + round-trip closure. Fix cost is low; risk is low; benefit is high for corpus integrity.

> **SUPERSEDED 2026-08-20 — see §0.** This line is left as written because it is what
> the operator would have been approving. It is no longer the recommendation: §D1's fix
> was measured against the corpus and would collapse 14 documents onto 4 ids (§0 C-4).
> The live recommendation is on the task file, which is what `fw task review` renders.

---

## Defect Analysis

### D1: Fallback Terminates in Display Name (Category Error)

**Location:** `parseBpmnXml()` line 9845  
**Current code:**
```js
id: aefMetaEl?.getAttribute('id') || procName || 'imported',
```

**Problem:**
- `procName` is human-readable text from the BPMN `<bpmn:process name="...">` attribute
- It may contain spaces, capitals, punctuation, non-Latin script
- Using a **display name** as a **machine identifier** is a category error
- Consumer BPMN has `name="Cash to Ecwid stock sync"` → id becomes invalid

**Why it matters:**
- Identity must be stable and slug-safe from the moment of load
- Fallback should prefer the BPMN element `id` (identifier) before the `name` (label)
- Pattern PL-046: "Identity must be minted at object BIRTH, not on the load/import path"

**Fix:**
```js
id: aefMetaEl?.getAttribute('id') || deriveSlug(procId) || deriveSlug(procName) || 'imported',
```

**Rationale:**
- `procId` (e.g., `proc_stock_sync`) is already a slug and passes the validator
- `deriveSlug()` exists and is proven for node identifiers
- Prefer identifier before label in fallback chain
- `deriveSlug()` returns safe, non-empty value
- If hand-authored procId is unusable, fall back to slug of display name
- Safe final fallback to 'imported'

**Testing:**
- Unit: `parseBpmnXml()` with no `<aef:workflowMeta>`, various procId/procName pairs
- Corpus: 145-file sweep of consumer hand-authored BPMN to verify derived IDs pass save guard

---

### D2: Sanitizer and Validator Disagree on Leading-Character Rule

**Location:** `renderProperties()` line 5183 (sanitizer) vs. `saveToProject()` line 8393 (validator)  
**Current sanitizer:**
```js
const trimmed = (v || '').trim().toLowerCase().replace(/[^a-z0-9_\-]/g, '-');
```

**Current validator:**
```js
if (!/^[a-z0-9][a-z0-9_-]*$/.test(id)) {
  alert('To save to the project, the map ID must be lowercase letters, numbers, "-" or "_" (no spaces)...');
}
```

**Problem:**
- Sanitizer removes/replaces non-slug chars but does NOT enforce `^[a-z0-9]` (leading char rule)
- Input `"-cash-sync"` sanitizes to `"-cash-sync"` (unchanged)
- User edits ID field, sanitizer cleans it, passes to `renameActiveWorkflow()`
- User proceeds to save, but validator rejects the leading dash
- User is told "your save failed" after editing and potentially working on the map

**Why it matters:**
- Sanitizer and validator must agree on rules
- Sanitizer is "helpful" (cleans input); validator is "strict" (guards persistence)
- If sanitizer produces output that validator later rejects, user trust breaks down

**Fix:**
Create a shared validation function:

```js
function isValidWorkflowId(id) {
  return /^[a-z0-9][a-z0-9_-]*$/.test(id);
}

function sanitizeWorkflowId(value) {
  let trimmed = (value || '').trim().toLowerCase().replace(/[^a-z0-9_\-]/g, '-');
  // Remove leading non-alphanumeric
  trimmed = trimmed.replace(/^[_\-]+/, '');
  // Fall back to 'workflow' if empty
  return trimmed || 'workflow';
}
```

Then use both consistently:
- Sanitizer: `sanitizeWorkflowId(input)` in renderProperties line 5183
- Validator: `isValidWorkflowId(id)` in saveToProject line 8393 (inline or via function)
- Rename function: call `sanitizeWorkflowId()` to ensure output is always valid

**Rationale:**
- Single source of truth for slug rules
- User is never told "cleaned value is invalid"
- Validation is deterministic

**Testing:**
- Unit: `isValidWorkflowId()` with boundary inputs (leading dash, trailing dash, empty, all valid chars)
- Integration: Edit ID field with leading/trailing dashes, verify sanitizer output, verify save validation passes

---

### D3: Validation Occurs Too Late

**Location:** `saveToProject()` line 8393  
**Current behavior:**
- ID is established when document loads (parseBpmnXml)
- Validation only happens when user clicks "Save to project"
- User may edit the map for minutes before discovering the ID is invalid
- Error message: "To save to the project, the map ID must be…" (blame-y, not actionable)

**Problem:**
- Invalid ID is discoverable at load time, not at save time
- Late discovery means user has already invested time
- UX: "your save failed" rather than "this file's ID needs attention"

**Fix:**
Add load-time validation in `parseBpmnXml()`:

```js
// After deriving id via the fixed D1 fallback chain:
if (!isValidWorkflowId(workflowMeta.id)) {
  workflowMeta.id = sanitizeWorkflowId(workflowMeta.id);
}
```

Then in `renderProperties()`, show a one-time notice if normalization occurred:

```js
if (normalizedOnLoad.has(activeKey)) {
  const notice = document.createElement('div');
  notice.className = 'field-hint';
  notice.textContent = 'ℹ ID was normalized on load: contained invalid characters.';
  // append to properties panel
}
normalizedOnLoad.add(activeKey); // track so we only show once
```

**Rationale:**
- Problem is visible immediately upon load
- User can see and approve the normalized ID before editing
- Error becomes informational (ID was cleaned) rather than a blocking alert
- No edit-time surprise at save

**Testing:**
- Load a BPMN with invalid ID (e.g., "My-Invalid ID")
- Verify ID is normalized to valid slug on load
- Verify UI shows one-time notice
- Verify subsequent saves accept the normalized ID

---

### Round-Trip Closure: Always Emit `<aef:workflowMeta>`

**Location:** `buildBpmnXml()` (export path)  
**Current behavior:**
- `<aef:workflowMeta>` is only emitted if it already existed in the source
- Hand-authored BPMN without the element stays without it on re-export
- Next load falls back to display name again

**Proposed behavior:**
- Always emit `<aef:workflowMeta>` with current `workflowMeta` object
- Preserve uuid (S1, T-224: uuid is invariant across rename)
- Closes the fallback cycle for good

**Fix:**
In `buildBpmnXml()`, unconditionally write workflowMeta:

```xml
<aef:workflowMeta 
  id="${state.workflowMeta.id}"
  uuid="${state.workflowMeta.uuid || ''}"
  version="${state.workflowMeta.version || '1'}"
  schemaVersion="2"
  title="${escAttr(state.workflowMeta.title || '')}"
  description="${escAttr(state.workflowMeta.description || '')}"
  tier_default="${state.workflowMeta.tier_default || '2'}"
  pageWidth="${state.workflowMeta.pageWidth || ''}"
/>
```

**Note on byte-identity:**
- Current code only emits workflowMeta if source had it
- Changing this breaks byte-identity for documents that lacked it
- Corpus measurement: 126 of 145 hand-authored BPMN have NO workflowMeta
- A re-export will now add ~350 bytes of XML
- This is acceptable trade-off: fixes the class for future exports
- Existing exports remain byte-identical (they already lacked it)

**Testing:**
- Save a hand-authored BPMN from the editor
- Re-load it (same session or fresh)
- Verify `<aef:workflowMeta>` element is present
- Verify ID, uuid, version are preserved

---

## Implementation Plan

### Phase 1: Shared Validation (D2 foundation)
- [ ] Create `isValidWorkflowId()` and `sanitizeWorkflowId()` functions
- [ ] Add unit tests for boundary cases
- **Reviewers:** Code review for correctness
- **Time:** ~30 min
- **Risk:** None (pure functions, no state change)

### Phase 2: Load-Time ID Derivation (D1)
- [ ] Update `parseBpmnXml()` to use `deriveSlug()` in fallback chain
- [ ] Track whether ID was normalized
- [ ] Add load-time notice in `renderProperties()`
- [ ] Add unit tests for various procId/procName combinations
- [ ] Run corpus sweep to verify derived IDs pass validator
- **Reviewers:** Test against consumer BPMN
- **Time:** ~45 min
- **Risk:** Medium (changes ID derivation; affects load behavior)

### Phase 3: Sanitizer Consistency (D2 impl)
- [ ] Update `renderProperties()` line 5183 to use `sanitizeWorkflowId()`
- [ ] Ensure saved callback uses shared function
- [ ] Update `renameActiveWorkflow()` to validate input
- **Reviewers:** Manual test: Edit ID with leading dashes, verify sanitizer cleans to valid slug
- **Time:** ~15 min
- **Risk:** Low (uses shared function from Phase 1)

### Phase 4: Validator Consistency (D2 validation)
- [ ] Update `saveToProject()` line 8393 to use `isValidWorkflowId()`
- [ ] Verify validator still catches edge cases
- **Reviewers:** Manual test: Attempt save with various invalid IDs (should now be cleaned by sanitizer)
- **Time:** ~15 min
- **Risk:** Low (uses shared function)

### Phase 5: Round-Trip Closure
- [ ] Update `buildBpmnXml()` to always emit `<aef:workflowMeta>`
- [ ] Preserve uuid, version, and other metadata
- [ ] Document byte-identity impact
- [ ] Test save/load cycle on hand-authored and editor-generated BPMN
- **Reviewers:** Byte-identity verification for existing corpus
- **Time:** ~30 min
- **Risk:** Low (adds metadata, does not remove or change existing logic)

### Testing Strategy

**Unit:**
- Validator and sanitizer boundary cases (empty, leading dash, trailing dash, all valid chars)
- ID derivation with various procId/procName combinations
- Load-time normalization tracking

**Integration:**
- Edit workflow ID, observe sanitizer output, save successfully
- Load hand-authored BPMN, verify ID is valid, save and re-load
- Verify one-time load-time notice appears and disappears on subsequent opens

**Corpus:**
- 145-file sweep of consumer hand-authored BPMN
- Measure: derived IDs pass save validator
- Verify existing valid IDs are unchanged
- Spot-check byte-identity for DI-carrying documents

---

## Tradeoffs and Alternatives Considered

### D1 Alternatives:
1. **Keep procName as fallback, fix at save time** — Rejected: still a category error, doesn't solve UX (D3)
2. **Generate random ID on import** — Rejected: breaks round-trip (consumer reports two opens disagree)
3. **Proposed:** Use deriveSlug on procId then procName — Preferred: stable, auditable, preferred-identifier-first

### D2 Alternatives:
1. **Sanitizer removes leading/trailing dashes** — Proposed
2. **Validator is more permissive** — Rejected: `-foo` is not a valid slug in most convention
3. **Two separate rules** — Rejected: current state; causes the bug

### D3 Alternatives:
1. **Validate at load; fail loudly** — Rejected: blocks workflow, doesn't help user
2. **Validate at load; silently normalize** — Rejected: user doesn't know what happened
3. **Validate at load; show one-time notice** — Proposed: informational, visible, solves UX
4. **Validate only at save** — Current state; causes the bug

### Round-Trip Alternatives:
1. **Never emit workflowMeta on export** — Status quo; perpetuates the fallback forever
2. **Emit only if source had it** — Current; breaks on first editor save
3. **Always emit** — Proposed; adds metadata, closes the class
4. **Lazy-emit (mark, emit on next save)** — Rejected: adds tracking state, when-to-emit ambiguity

---

## Risk Assessment

| Phase | Risk | Mitigation |
|-------|------|-----------|
| Phase 1 (shared functions) | Low | Unit test boundary cases |
| Phase 2 (derivation change) | Medium | Test on consumer corpus; measure ID stability |
| Phase 3 (sanitizer) | Low | Edit field with edge cases; verify no silent corruption |
| Phase 4 (validator) | Low | Sanity check: should never reject Phase 3 output |
| Phase 5 (round-trip) | Low | Measure byte-identity for DI-carrying docs; verify save/load cycle |

**Safety property:** No phase breaks existing workflows. All changes are additive or re-derivation of current values.

---

## Consumer Impact

**For hand-authored BPMN (consumer use case):**
- On load: Invalid IDs are normalized, visible in properties panel
- On edit: Sanitizer prevents invalid input at the field
- On save: Validator always passes (guaranteed by sanitizer)
- On re-load: `<aef:workflowMeta>` is present, no fallback needed

**For editor-generated BPMN (v0.8.0+):**
- No change (workflowMeta already present)
- Re-export adds explicit element (byte-identity impact: ~350 bytes)

**For v0.8.0 vendored build:**
- This fix applies to source code, not the build
- Consumer uses v0.8.0 until next release
- Consumer can hand-patch v0.8.0 with D1+D2 fixes locally if urgent
- Next release (v0.9.0) includes all fixes

---

## Scope Fence

### In Scope:
- D1: Fallback derivation fix
- D2: Sanitizer/validator consistency
- D3: Load-time validation and UX
- Round-trip: Always emit workflowMeta

### Out of Scope:
- Changes to existing ID format or validation rules
- Renaming of existing workflow IDs (user choice, not automatic)
- Rewriting corpus (consumer's responsibility; consumer already patched their one file)
- Changes to other metadata fields (title, version, description)

---

## Verification Gates

| Gate | Condition | How to Verify |
|------|-----------|---------------|
| D1 correctness | Derived IDs pass `/^[a-z0-9][a-z0-9_-]*$/` | Unit test + corpus sweep |
| D2 consistency | Sanitizer output always validates | Edit field, save, verify no rejection |
| D3 UX | Load-time notice is shown, informational | Manually load invalid ID, see notice |
| Round-trip | workflowMeta element persists | Save, load, grep for `<aef:workflowMeta>` |
| Regression | Existing workflows unaffected | Test on 10+ existing consumer BPMN |

---

## Next Steps: Governance Decision

This proposal has been submitted to the AEF SoT for governance review and approval. The human decision-maker should:

1. **Review** the three defect analyses and proposed fixes
2. **Assess** the risk/benefit tradeoff
3. **Decide** whether to proceed with implementation (GO) or request modifications (DEFER with specific feedback)

Once approved, implementation proceeds in five phases as outlined, each with independent reviewability.
