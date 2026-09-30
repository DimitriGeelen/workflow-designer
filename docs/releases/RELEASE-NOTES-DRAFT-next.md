# Release notes DRAFT — the next designer release after `designer-v0.13.0`

**Status: DRAFT for the operator.** Nothing here has been released. The version number is left as
`X.Y.Z` on purpose: bumping `VERSION`, writing `dist/`, tagging and pushing a release are the
operator's under G-007 — a release is a sovereignty promise over immutable bytes, and an agent
choosing the number is an agent deciding what promise is being made. Rename this file once the number
is chosen.

## What is actually in it

**11 commits touched `src/aef-workflow-designer.html`** since `designer-v0.13.0`: **+454 / −16 lines**.
The other ~272 commits on `bleeding-edge` are framework, task-register and tooling work that the
release artifact does not contain — the artifact is a single-file copy of `src/`, so only these
eleven change the shipped bytes.

### Authoring surface

- **`aefMeta.authority` becomes a first-class element key** (`a906f337`, `71d4943b`, T-889) — authority
  is carried on the element rather than inferred.
- **Authority is drawn in three states that do not collapse** (`df1df4df`, T-893) — silent when it
  matches the lane default, a faint mark when it differs, explicit when set. The three are visually
  distinguishable, which was the point: a single marker could not say *which* of the three it meant.
- **A lane's authoring default is authorable in the panel** (`86a12a82`, T-892) — it pre-fills new
  elements and re-renders the T-893 markers on change.
- **The lane default ships PRESENTATIONAL** (`a37aaf4e`, T-890) — and the commit records that the guard
  which should protect it does not.
- **The diagram-kind marker is settable and visible** (`5495a91f`, T-911; `39e0579d`, T-875) — arc-005's
  stated mechanic.
- **The Emits panel authors the ratified shape** (`5b6931a4`, T-573) — one module-scope vocabulary for
  the structured-list keys, plus a content-equality guard so a brushed field moves no bytes.

### Correctness

- **Orphaned-node ownership no longer depends on `laneSet` serialisation order** (`3cb17878`, T-891) —
  the guess is replaced by a rule.
- **Instance position is visible in the designer** (`94d2b2a6`, T-884) — a snapshot verb,
  `/api/instances` on the project server, and an overlay drawing the current node, the derived
  completed path, and the node a refusal fired on with its rule.

### Worth reading in the commit messages rather than summarised here

Four of the eleven record a guard that was wrong rather than only the feature that landed: T-875 ("the
guard I reached for to prove it round-trips does not cover it"), T-890 ("the guard that should protect
it does not"), T-889 ("the guard that proves it was reading comments as code"), T-904 ("my own fix broke
a second check that does the same thing"). Those are the honest part of this release and they are in the
git log, not compressed into a bullet.

## Preconditions, checked

| | |
|---|---|
| `master` is a fast-forward ancestor of `bleeding-edge` | **yes** — PD-309's train is intact; the T-938 history rewrite did not break it, because `filter-repo` preserved SHAs for commits it did not need to change |
| audit | 26 pass / 11 warn / **0 fail** |
| unpushed commits | 0 |
| `src/` changed since the tag | **yes** — 11 commits, +454/−16 |
| `VERSION` / `dist/MANIFEST.yaml` | both `0.13.0`, i.e. **not yet bumped** for this release |
| working tree | `.context/audits/cron/` retention churn only, which is not the agent's to commit (T-571) |

## One thing to know before running it

**`fw release status` reports `Latest tag: <none>`** while 16 tags exist. It does not recognise this
project's `designer-vX.Y.Z` naming, so the framework verb cannot see the release history. The real
mechanism is `scripts/release-designer.sh`, which is what previous releases used. Do not read the
framework verb's "none" as "unreleased" — filed so the next person does not.

## The sequence, for the operator

Each step is the operator's; none is delegated.

1. Land `bleeding-edge` on `master` by fast-forward (PD-309 — never a merge, never a third branch):
   `cd /opt/832-Workflow-designer && .agentic-framework/bin/fw integrate run bleeding-edge`
2. Choose and write the version in `./VERSION`. The eleven commits add authoring capability without
   removing any, which reads as a minor bump, but the number is the operator's call.
3. Build the artifact — deterministic, same source + same VERSION gives byte-identical output:
   `cd /opt/832-Workflow-designer && bash scripts/release-designer.sh`
4. Tag and announce per the previous releases' pattern (`designer-vX.Y.Z`), then
   `bash scripts/announce-release.sh` if that is still the flow.
5. AEF re-pins the sha256 — see `docs/aef-designer-integration-protocol.md`. They vendor a pinned copy,
   so the release is only useful to them once the tag exists and the hash is stable.
