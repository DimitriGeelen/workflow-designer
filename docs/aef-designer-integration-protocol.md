# AEF ⇄ Workflow Designer — integration protocol

**Scope:** how AEF consumes releases of the Workflow Designer and how improvements flow back.
**Authority:** T-173 GO (mechanism **M3 + `fw designer`**) + T-175 IW-6 (bidirectional flow).
**Source of truth:** `832-Workflow-designer` (this repo). AEF vendors a **pinned copy** — never a fork.

This is the phase-1 protocol (the self-contained single-file editor). Server/corpus/versioning hosting
is phase-2 (see arc `designer-authoring-surface`).

---

## Roles

- **832 (this repo)** — authors the designer, cuts versioned releases into `dist/`, is the single source
  of truth. Future designer development happens here.
- **AEF (`/opt/999-Agentic-Engineering-Framework`)** — vendors a pinned release artifact and serves it via
  a `fw designer` route. AEF **never edits its vendored copy**.

The topology is deliberately acyclic: 832 vendors AEF at `.agentic-framework/`; AEF references only a
**build artifact** of 832 (not its source), so the dependency cycle never closes.

---

## Direction 1 — PULL (832 → AEF): vendor / re-pin a version

1. Read `dist/MANIFEST.yaml` in this repo — `latest` names the current version; `sha256` is its checksum.
2. Copy `dist/aef-workflow-designer-<version>.html` into AEF's vendored location (e.g.
   `.../designer/aef-workflow-designer-<version>.html`).
3. **Verify** the copy: `sha256sum` must equal the manifest `sha256`. Reject on mismatch.
4. Record the pinned version on the AEF side (a version constant / manifest entry) so the pin is explicit
   and reproducible.
5. Serve it via `fw designer`.

**Re-pin (adopt a newer release):** repeat steps 1–4 against the new `latest`. Pinning is always to a
specific version + checksum — never "track HEAD".

**Reproduce a build from source** (audit / provenance): run `scripts/release-designer.sh` in this repo at
the matching `VERSION`; it is deterministic (byte-identical artifact + checksum on every run).

Provenance convention: each release corresponds to a git tag `designer-v<version>` on this repo.

---

## Direction 2 — IMPROVEMENTS (AEF → 832): upstream, never patch

AEF (its agent or its users) will find bugs and want features in the designer. Those **do not** get patched
into AEF's vendored copy — that would fork the source of truth and break the "832 = SoT" constraint.
Instead:

1. File the improvement **upstream to 832** via the cross-agent termlink channel (the proven path — the
   T-173 / T-175 collaboration threads, and the ring20 RCA upstreams, all used it). A task-thread + a clear
   repro / request.
2. **832** implements it in `src/`, cuts a new release (`scripts/release-designer.sh`), bumps `VERSION`.
3. **AEF** re-pins to the new release (Direction 1).

This keeps a single lineage: every designer change is authored once, in 832, and propagates by re-pinning.

---

## Versioning

- Semantic version in `VERSION` (repo root). Phase-1 starts at `0.1.0`.
- `dist/` accumulates versioned artifacts (`aef-workflow-designer-<version>.html`); `dist/MANIFEST.yaml`
  points at the latest + its checksum.
- Bump `VERSION` and re-run the release script for each release.

---

## Known caveat — CDN fonts (offline behaviour)

The designer links **Google Fonts** (`fonts.googleapis.com` / `fonts.gstatic.com`) for its typefaces
(JetBrains Mono, Outfit). Consequences for a vendored/served copy:

- **Authoring functions offline** — the browser falls back to system fonts, and BPMN diagramming +
  import/export do not depend on the webfonts. So an air-gapped AEF deployment still *works*.
- **But it is not zero-network** — the browser will *attempt* the font fetch. In a locked-down deployment
  that request fails (silently, with fallback), and the typography differs from the intended design.

True offline self-containment (inline/self-host the fonts) is tracked as a **separate** task (a visual
change to `src/`, out of scope for cutting a release). Until then, AEF deployments that must be fully
offline should either accept the system-font fallback or self-host the fonts at their edge.
