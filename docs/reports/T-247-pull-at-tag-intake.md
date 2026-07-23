# T-247 — Pull-at-tag release intake (seam-contract change)

Research artifact (C-001). Status: exploration complete, Recommendation GO, awaiting operator decide.

## Question

Should designer-release consumers switch from per-peer file_send delivery to pulling the
frozen artifact + MANIFEST at the annotated release tag (`designer-vX.Y.Z`), verifying by
sha against the MANIFEST at the same tag?

## Findings

1. **The mechanism already exists.** Every release since 0.3.0 commits the frozen artifact
   and MANIFEST.yaml at its annotated tag. Verified 2026-07-23 on origin:
   - `designer-v0.3.0` → artifact sha `36be033d…` (== pin), MANIFEST present
   - `designer-v0.3.1` → artifact sha `d99a42da…` (== pin), MANIFEST present
   - `designer-v0.3.2` → artifact sha `983e0e30…` (== pin), MANIFEST present
   Zero 832-side build is required; the release pipeline and immutability guard are untouched.

2. **The verification anchor is unchanged.** Consumer flow becomes: rail announce (kept as
   trigger + verdict handshake) → fetch artifact+MANIFEST at tag → independent sha256 vs
   MANIFEST at the SAME tag → re-pin → sync → e2e → verdict. Identical integrity guarantee
   to file_send; only the transport differs.

3. **T-559 is preserved by both operators' ruling.** AEF's operator recorded D-335:
   "frozen annotated tag = published frozen bytes — invariant satisfied; your working tree
   remains off-limits." Our framing at rail 178 said the same. The invariant's purpose
   (consumer never depends on producer working-tree state) holds: a tag is frozen.

4. **The gap is operator-visible, twice in one day.** (a) AEF's operator heard of unreleased
   master work (T-245) and dispatched a fruitless release hunt (their T-2556, rail 177) —
   under pull-at-tag, "is there a newer version?" is `git ls-remote` on tags. (b) Our
   operator asked how subscribers learn of/obtain new features — the answer was "we tell
   them, 1:1, and hand them bytes", which does not scale past one consumer.

5. **One link unvalidated (IW-4):** whether AEF's host can read origin
   (`ssh://git@192.168.10.201:6611/workflow-designer`). ssh authorization is git-server
   config, operator-owned. Test posted to AEF at rail 183 (`git ls-remote … 'refs/tags/designer-v*'`,
   expect 5 lines). Failure mode is soft: Dimitri grants access, file_send covers any interim.

## Dialogue Log

- **Operator (832) asked:** "consider we have other apps subscribed to our developments —
  how do they know there are new features and how do they get the changes?" → agent laid
  out the current rail+file_send model and its 1:N gaps; operator then proposed:
  "would the best not be to use github versioning and pull based on version number?"
- **Agent course-check:** agreed with the pull model; flagged three caveats — seam-contract
  change needs AEF agreement, pull doesn't solve notification (keep rail announce), and
  reachability/pull-source (GitHub mirror vs LAN origin) unverified.
- **Operator chose option 1:** propose on the rail + capture the task now (T-247 created).
- **AEF exchange:** proposal at rail 178 → their preliminary agent read at 181 (advisory:
  spirit-compatible, prefer LAN origin, small bounded build their side) → operator-ratified
  ACCEPT at 182 (D-335, T-2616 = `fw designer sync --from-tag`, file_send fallback kept) →
  832 dry-run-target verification posted at 183 with the IW-4 reachability test.
- **Outcome:** contract agreed both sides; the only open is IW-4 (their ls-remote result);
  operator decide on T-247 pending.

## Decision Trail

- Pull source: **read-only LAN origin** over github mirror (AEF preference, rail 182 —
  same LAN, no external dependency; our github remote stays mirror-only, push-token
  constraint untouched).
- Rail announce **kept** as new-version trigger and verdict handshake (caught real defects
  in both prior release rounds — 0.3.1 e2e observations, 0.3.2 re-pin verdict).
- file_send **kept as fallback** — makes the switch reversible per-release with no
  renegotiation.
- Companion, explicitly out of scope here: T-246 (MANIFEST changelog + structured
  capabilities block) makes a pull self-describing; AEF: "the capabilities block is exactly
  what makes our conditional-emit guard self-configuring at re-pin."
