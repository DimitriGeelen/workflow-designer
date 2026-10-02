# T-1000 — Gate re-vendoring: design (needs an operator choice before building)

**From:** T-995 GO (B4). **Date:** 2026-10-02.

## What measuring showed first

`tools/_t517-vendor-divergence.py` on today's working tree (T-988's 1.7.740 copied in, uncommitted):
`FAIL — 1599 unrecorded, 11 stale, 2 reclassified`.

The detector compares the vendored tree with `baseline_commit` in `.vendor-divergence.yaml`, and
that baseline is **`ebf0c721` = the T-276 re-vendor of v1.6.763**. It was never advanced: not at
T-840 (1.7.68), not now. Consequences:

- The **11 STALE** are the T-840 losses T-944 reported on 09-30. They were never re-applied.
- **Every T-988 change shows as "unrecorded local change" (1599)**, so the detector cannot tell
  which declared local fixes T-988 erases. It only knows that the tree differs from 1.6.763.
- So the naive gate, "refuse an upgrade commit while STALE > 0", would be blind to exactly the
  losses it exists to catch. It would also fire on the old T-840 losses, which it cannot attribute.

## The structural answer: re-vendoring as a protocol with a moving baseline

The defect is not a missing check. A re-vendor is one undifferentiated overwrite, so "upstream
changed this" and "our fix was lost" look the same. Make them different by construction:

1. **Pristine commit.** The upgrade is committed exactly as the vendor wrote it, alone
   (`.agentic-framework/` paths only, VERSION changed).
2. **Advance the baseline** to that commit (`baseline_commit`, plus `baseline_version`).
   From that moment `_t517` compares against pristine 1.7.740, so **every declared local fix the
   upgrade overwrote shows as STALE**, by name, with its task and reason. Every real upstream
   change stops being "unrecorded".
3. **Re-apply worklist.** For each STALE entry, the local fix is the diff between the old
   baseline and the pre-upgrade HEAD for that path. A tool writes it out as a patch
   (`git apply -3`). Each entry is resolved one of three ways: re-applied, reclassified
   `superseded` (upstream has it), or dropped with a reason.
4. **Done when `_t517` is clean** (0 STALE, 0 unrecorded).

**Gates that make the protocol hold** (project-owned script, installed into `.git/hooks/pre-commit`
by an idempotent installer, because the framework's hook has no extension point; B3's project
audit flags it if a reinstall removes the line; U1 asks AEF for the seam):

- **G1:** a commit that changes `.agentic-framework/VERSION` must contain only `.agentic-framework/`
  paths (the pristine commit). Mixing in project work is refused.
- **G2:** while HEAD's framework VERSION differs from the baseline's VERSION, every commit is
  refused except the one that advances `baseline_commit`. You cannot carry on as if the upgrade
  were done.
- **G3:** while `_t517` reports STALE after an upgrade, `fw audit` FAILs (via B3) and `runme.sh`
  refuses a release (B2). This is visible and blocking, but it does not stop the commits that do
  the re-applying.

## What this means for T-988 (your pending decision)

Landing T-988 under the protocol becomes a `runme.sh` sequence for you:
1. pristine commit of 1.7.740;
2. advance the baseline;
3. I produce the worklist (expected: the T-944 losses plus whatever 1.7.740 overwrote, now
   attributable) and re-apply or reclassify each entry in its own commit;
4. `_t517` clean.

One wrinkle: today's working-tree `lib/inception.sh` already holds the T-996 fix on top of 1.7.740.
The pristine commit must take the vendor's file without it, and T-996 is re-applied in step 3,
which is what the protocol is for.

## The choice

| | Option | Cost | Catches T-988's losses? |
|---|---|---|---|
| **A (recommended)** | the protocol above (G1-G3, moving baseline, worklist) | one tool and one hook script, plus a runme.sh sequence to land T-988; commits are blocked between steps 1 and 2 by design | **yes**, by name |
| B | naive gate: refuse an upgrade commit while STALE > 0 | small | **no**: the baseline is two re-vendors old |
| C | no hook; the protocol only as runme.sh steps | smallest | yes, if the steps are followed; nothing enforces it |

## Decision and build (2026-10-02)

**Operator chose A**: "A yes yes yes and this is what AEF needs to adopt … in framework". Proposal
sent to AEF (sidecar, conversation `revendor-protocol`).

Built:

| piece | file | evidence |
|---|---|---|
| gate G1/G2 | `tools/_t1000-revendor-gate.sh` | `tests/test_t1000_revendor_gate.sh`: 9/9, refusal and pass legs on both sides (mixed upgrade refused / pristine allowed; ordinary commit after pristine refused; wrong baseline refused; correct advance allowed; work flows after; logged override) |
| hook wiring | `tools/_t1000-install-hook.sh` (`--check`) | installed in this repo at line 2 of `.git/hooks/pre-commit`, idempotent; a framework hook reinstall removes it, so T-999's project audit calls `--check` |
| worklist | `tools/_t1000-revendor-worklist.py` | self-test on the T-840 upgrade (pristine 7b5e227e, old baseline ebf0c721): 11 stale paths, 10 with a patch from their own local commits. fabric.py -> T-568 + T-569, exactly what T-944 found by hand. **All 10 patches pass `git apply --check` on today's tree: the T-840 losses were never restored, and can be restored mechanically.** `external_consult.py` (T-887, after T-840) correctly shows no T-840 commit. |

## How T-988 lands under the protocol (not started: the operator's call)

No upstream tag pins 1.7.740 (only up to v1.7.0 is tagged; `bleeding-edge` has moved on), so the
pristine bytes are the working tree as `fw upgrade` wrote it, minus the edits made since. Known
post-upgrade edits:
- `.vendor-divergence.yaml` (ours: T-988's pin note, T-996's entry): kept out of the pristine commit;
- `lib/inception.sh`: the T-996 block, removed for the pristine commit and re-applied from the
  worklist;
- `policy/designer-pin.yaml` (T-988 moved it to 0.15.0, declared local-config): if it goes into
  the pristine commit as-is, it shows as a false STALE; resolve it as "present".

Sequence (to be wrapped in runme.sh when the operator decides T-988):
1. the pristine commit;
2. the baseline advance;
3. `_t1000-revendor-worklist.py`, then re-apply (the 10 T-840 patches, T-996, and whatever 1.7.740
   overwrote) and reclassify;
4. `_t517` clean, then close T-988's divergence criterion.

## First real use: T-988 landed (2026-10-02)

- Operator ran runme.sh: pristine commit **2659abad** (1561 vendored paths), baseline advance
  **d9f997bf**. The step-1 commit hung ~10 min in the framework post-commit hook (O(files x cards)
  grep spawns, T-1004); the advisory hook was stopped after the commit had landed. Step 2 was
  then confirmed by typeahead (the operator had pressed y while waiting), which led to
  `runme_confirm` (T-1003).
- `_t517` against the new baseline: **0 unrecorded** (was 1599: the phantom "local changes" were
  upstream changes), **51 STALE**, each named with its task. This is the visibility the protocol
  exists for: before, the same tree reported 11 STALE and could not attribute the rest.
- Mechanical triage: all 51 patches apply (22 clean, 29 three-way); 0 already present upstream.
- Re-applied so far: T-996 (a3f02cd5); batch 1, the live Watchtower defects T-568 / T-569 / T-606 /
  T-646 (b8eb4af6): probes green, live T-568 probe green after a Watchtower restart. **47 left**,
  tracked in T-1005. update-task.sh (17 local commits) conflicts 13 times in a bulk merge and is
  being done commit by commit.
