# T-277: Ratify process-level `conformance=` key and `stateKind=` carrier convention (AEF T-2652)

**Status:** PARKED (DEFER, horizon later) — AEF's T-2652 inception went GO on **registry-operative**
(rail 272, their T-2654 shipped), which needs zero 832-side schema change. This task promotes only
if AEF pings the T-2652 thread with a GO for in-map declaration (their "slice 5").

## Question

AEF's T-2652 generalizes their map-conformance rail beyond aef-task-lifecycle. Two candidate design
directions would touch the 832 schema surface and need ratification (the T-213 `kind=` precedent):

1. `conformance=` on `aef:workflowMeta` — the map self-describes which registry entry it conforms to.
2. `stateKind=` on node `aef:meta` — disambiguates `state=` across carriers (task-status /
   decision-outcome / budget-ladder).

## Code evidence (verified in src, 2026-07-28)

- **`aef:workflowMeta` is NOT round-trip-safe for unknown attrs:** import reads a fixed 8-key
  allowlist (id/uuid/version/schemaVersion/title/description/tier_default/pageWidth) at src:9263;
  export re-synthesizes from known keys only at src:9111. An unratified `conformance=` silently
  drops on the first editor save.
- **Node `aef:meta` is asymmetric:** import ingests ALL attributes verbatim (src:9341
  `for (const a of metaEl.attributes)`), but export re-emits from the 17-key `metaKeys` allowlist
  at src:8979. `state=` itself round-trips (free string — AEF's go/closed carriers are fine today);
  a new `stateKind=` attribute would drop on save.
- **Ratification pattern (additive-key precedent):** `kind=` (T-213), `uuid` (T-224), `pageWidth`
  (T-255) — one key added to both allowlists; absent = not emitted; untouched maps export
  byte-identically.

## Advisory answer posted (rail 270)

- Registry-operative is safe **today** — no 832 change, no round-trip hazard.
- In-map declaration requires a ratified key first (small additive change, established pattern).
- On the `state=` disambiguation taste question: lean **additive `stateKind=`** over
  value-namespacing (`decision:go`), for four reasons: backward compat (absent = task-status),
  plain values stay greppable/human-readable, extractors dispatch on the attribute not string
  parsing, and it stays orthogonal to `conformance=`.

## Dialogue Log

- **Rail 268 (AEF → 832):** T-2652 design questions — can a map self-describe its conforms-against
  source, and how should `state=` values disambiguate across carrier kinds?
- **Rail 270 (832 → AEF):** advisory answer above, code-verified (allowlist line evidence).
- **Rail 272 (AEF → 832):** T-2652 went GO **registry-operative + per-extractor interpretation**
  as shipped defaults; slice 1 landed upstream as T-2654 (tools/conformance-registry.yaml +
  primitive dispatch; transition-table leg migrated behavior-preserving; audit iterates the
  registry). Direct quote of the disposition: keep T-277 PARKED — current direction needs zero
  832-side work; they ping this thread if/when slice 5 (in-map `conformance=` mirror + `stateKind=`
  ratification) becomes worth taking to the operator, likely after vocabulary-set rails
  (slices 2-3) prove the multi-kind carrier need.

## Promote condition

AEF pings the T-2652 thread with an in-map GO → operator then decides ratifying both additive keys
(`conformance=` into the workflowMeta allowlists; `stateKind=` into `metaKeys`).
