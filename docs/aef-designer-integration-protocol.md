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

### Delivery across the T-559 project boundary (proven mechanism, phase-1)

Step 2 above ("copy the artifact") assumes the AEF side can *read* `/opt/832`. In practice **it cannot**:
the T-559 project-boundary enforcement blocks an AEF session from reading another project's files (and
symmetrically blocks 832 from reaching into AEF). So the pull is realised as a **832-side push**:

1. **832 delivers** the artifact over the cross-agent **termlink `file_send`** channel to the AEF session
   (chunked transfer; returns the sender-computed sha256). This is how release 0.1.0 was delivered
   (2026-07-10): `file_send` → AEF session, 394110 bytes, sha256 `d0e0177c…0317d`.
2. **AEF receives** the file into its file-receive inbox and runs `fw designer sync --from <received-path>`,
   which sha256-verifies against `policy/designer-pin.yaml` and installs read-only (rejecting any mismatch).
3. The checksum is the trust boundary — the transport (push vs pull, file_send vs URL) is irrelevant as long
   as the received bytes match the pin. An operator may equally expose a fetchable URL; the verify step is
   identical.

Net: the manifest `sha256` remains the single source of trust; only the *transport* changes to respect the
boundary. Neither side crosses the other's filesystem.

**Reproduce a build from source** (audit / provenance): run `scripts/release-designer.sh` in this repo at
the matching `VERSION`; it is deterministic (byte-identical artifact + checksum on every run).

**Render gate (T-180):** the release cut runs a headless render-check (`tests/test_designer_render.py`)
against the freshly built artifact before writing the manifest — sha256 proves the *bytes*, this proves the
build actually *renders* and still carries the governance fields (catches a broken or stale build a
byte-check would pass). Fail-closed; the only bypass, for browser-less environments, is
`RELEASE_SKIP_RENDER_CHECK=1`, which warns loudly on stderr (never a silent skip).

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

## Cross-agent coordination channel (durable path — use this, not PTY inject)

Both directions above ride a cross-agent channel (questions, decisions, artifact hand-offs) between the 832
session and the AEF session. That channel has a **proven-reliable** shape and a **known-lossy** one; use the
former for anything that must persist.

**Durable (use this):**
1. **Artifacts / files** → `termlink file_send` to the target session. Chunked, returns a sender sha256; the
   receiver re-verifies against the pin (same trust boundary as a release delivery). Lands in the receiver's
   file-receive inbox — **non-disruptive**: the peer processes it when it surfaces, so it never derails their
   live work. This is how release 0.1.0 *and* the T-175 mapping strawman + IW-1 answer were delivered
   (2026-07-10).
2. **Questions / decisions / steers** → a signed **channel/DM post** carrying explicit `thread=T-XXX`
   metadata (e.g. the T-175 thread). The thread is the durable conversational record; always tag it so the
   post is retrievable by thread even when peer `dms`/`search` verbs miss it.

**Lossy (do NOT rely on for anything durable):**
- **PTY inject** into a peer session. If the peer runs in **manual mode**, injected text lands in their input
  box **unsubmitted** — and is discarded when they `claude --continue`. This is exactly how AEF's IW-1
  question failed to reach 832 durably (2026-07-10): delivered by inject, never submitted, lost on continue.
  Inject is fine for a live nudge you can confirm was consumed; it is **not** a delivery mechanism.

**Discovery caveat:** all local sessions share one identity fingerprint, so a bare `dms`/`search` can't pin a
single sender and may return empty even when posts exist. Mitigation: keep an explicit `thread=T-XXX` on every
post and treat `file_send` as the durable backbone; a peer that "can't find" a post should read the thread by
id, not search by sender.

**Rule of thumb:** if it must survive the peer's next `--continue`, it goes through `file_send` (artifact) or a
threaded channel post (message). Never through an unconfirmed inject.

---

## Versioning

- Semantic version in `VERSION` (repo root). Phase-1 starts at `0.1.0`.
- `dist/` accumulates versioned artifacts (`aef-workflow-designer-<version>.html`); `dist/MANIFEST.yaml`
  points at the latest + its checksum.
- Bump `VERSION` and re-run the release script for each release.

---

## Annotation seam (postMessage) — live-state badges on served maps

Ratified T-250 GO (shape A, operator decision 2026-07-27, rail 216). Available when the
manifest carries `capabilities: { annotation_seam: 1 }` (0.7.0+). The embedding page
(AEF Watchtower) drives it; the designer is a passive display surface.

**Handshake (designer → parent), after EVERY full render including initial load:**

```json
{ "type": "aef:ready", "version": 1, "workflow": "<workflowMeta id>", "uids": ["n_...", ...] }
```

Renders rebuild the SVG wholesale, so annotations are wiped per render — the parent
re-annotates after each `aef:ready`. Emitted only when embedded (`parent !== window`),
targetOrigin `*` (v0; see origin policy below). Transient intra-gesture partial renders
(mid-drag) may clear badges early; the gesture-ending full render re-handshakes.

**Annotate (parent → designer):**

```json
{ "type": "aef:annotate", "annotations": [
    { "uid": "n_abc", "badge": "running", "tone": "ok", "title": "since 12:04Z" } ] }
```

- `uid` — node uid (the `aef:uid` value; also the SVG `g[data-id]`). Unknown uids are
  ignored silently. `badge` — short text, clamped to 48 chars, rendered as a pill at the
  node's top-right. `tone` — one of `info | ok | warn | err` (default `info`).
  `title` — optional hover tooltip (native SVG `<title>`, clamped to 200 chars).
- Accepted ONLY from the embedding parent (`event.source === window.parent`).
- Read-only overlay: never serialized into BPMN, never in autosave, stripped from
  thumbnails, dropped on document switch. Malformed payloads are ignored without error.

**Origin policy v0:** emit `*`, accept parent-source only. The uid list is map structure,
not a secret, and badge text renders via text nodes (no HTML path). Tightening to an
origin allowlist is the designated next step if a second embedder class appears.

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
