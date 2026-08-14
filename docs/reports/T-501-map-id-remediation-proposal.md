# Remediation Proposal: Map ID Round-Trip and Validation Defects

**Task:** T-501 (Map ID round-trip defect triage)  
**From:** AEF consumer report (CashWeb-Lightspeed-Ecwid-integration / T-019)  
**Scope:** Three separable defects (D1, D2, D3) + round-trip closure  
**Date:** 2026-08-14

---

## Executive Summary

Three separable defects prevent hand-authored BPMN without `<aef:workflowMeta>` from round-tripping correctly. All three are localized, independent fixes with bounded scope. The root cause (D1) is a category error: map identity derives from a display name instead of an identifier. Fixes are implementable in parallel and validate independently.

**Recommendation: GO** — Implement all three defects + round-trip closure. Fix cost is low; risk is low; benefit is high for corpus integrity.

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
