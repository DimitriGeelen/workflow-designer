# T-476 — Our exposure to the OBS-037 phantom-checkbox misalignment

**Measured 2026-08-12. Vendored framework version: 1.6.354.**
**Verdict: exposed, bounded, and the remedy is an operator-decided version bump.**

## 1. What AEF found, and why it lands here

We handed AEF OBS-037 (their Human-AC tick guard was symmetric — it blocked un-ticks
as hard as ticks — and comment-blind). They shipped the fix as **T-2954** and reported
it at rail 588. Inside that report is a second defect, worse than either of us had it:

> `get_checkbox_states` counts `- [ ]` lines that live inside `<!-- ... -->` guidance
> comments. `detect_toggle` then zips old/new box lists **positionally**. Phantoms at
> low indices shift every real AC's index, so the zip misaligns and an agent deleting a
> **comment** is reported as a Human-AC **tick**.

This is not merely their problem. `.agentic-framework/` **is** their framework, vendored
into our tree. Their fix is upstream; our copy predates it.

## 2. Site census — enumerated, not sampled

AEF censused four comment-handling sites. Ours differ, so the lookup was done by name
across the whole vendored tree rather than by their paths (a path-based check first
returned two false ABSENTs):

| AEF's site | in our vendored tree | comment semantics here |
|---|---|---|
| `lib/verification-port.sh` | **absent** — file does not exist at 1.6.354 | n/a |
| `check-human-ac-tick.py` | present at `agents/context/` (different path) | **none — no stripping at all** |
| `agents/audit/audit.sh` | present | strips `<!--.*?-->` at 6 sites (DOTALL) |
| `lib/review.sh` | present | `grep -v '<!--'` — drops lines *containing* the opener |

`lib/comment_strip.py` — the shared rule AEF's fix introduces — **is not present**.
That is the cleanest single marker that this tree is pre-fix.

The fabricating site is `agents/context/check-human-ac-tick.py`:
`get_checkbox_states` (line 57) has no strip; `detect_toggle` (line 71) zips positionally;
`log_bypass` (line 77) writes the record.

## 3. Reachability — executed, not reasoned about

The verdict below comes from importing our own vendored guard and **running** it, not
from reading the code. Probe: `tools/_t476-obs037-exposure-probe.py`.

**The first probe returned a false negative, and it is worth recording why.** It used
this task's own file as the before/after pair and reported *"not reachable"*. T-476's
`### Human` section contains only the two commented examples and **no real AC**, so the
zip compared phantom against phantom and saw nothing. The misalignment needs a real
ticked AC for the shifted index to land on. **That negative was a property of the sample,
not of the guard** — the probe produced a plausible verdict without doing its job, which
is the same class as the dict-key probe in T-474 and AEF's collapsed `awk` range this
same round. Re-aimed as a corpus sweep with the denominator stated:

    task files where the edit is possible (### Human section has comments):  387
    of those, guard reports a Human-AC TICK that never happened:              16   (4.1%)
    positive control (a genuine [ ] -> [x]):                                  detected

Hand-verified instance, `.tasks/active/T-093-branch-pitch-setting-parallel-block-stac.md`:

    boxes with comments:    [' ', ' ', 'x']     # 2 phantoms + 1 real, human-ticked
    boxes with comments stripped: ['x']
    detect_toggle -> [(0, ' ', 'x')]            # "the agent ticked a Human AC"

The agent deleted a comment. The guard reports a tick.

## 4. Corpus shape (PL-084 denominator)

    task files with a ### Human section:   440
    of those, carrying phantom boxes:      343   (78.0%)
    worst-case phantoms in one file:         2

78% is a property of our task **template**, which ships the commented `- [ ] [REVIEW]`
and `- [ ] [REVIEWER]` examples. Every task created from it inherits two phantoms at
indices 0-1. (AEF measured 1103/2942 = 37.5% on their side; ours is higher because our
template's example block is denser, not because our tree is worse-maintained.)

## 5. Severity — stated honestly, in both directions

**Bounded, and smaller today than the defect sounds:**
- Under agent control the guard **blocks**. The lived effect right now is *spurious
  blocks* on legitimate edits that touch no checkbox. Annoying, not corrupting.
- The fabricating path into the audit log requires `FW_ALLOW_HUMAN_AC_TICK=1`, which is
  a gate bypass the agent is categorically forbidden from using.

**Not dismissible:**
- The record it would fabricate is a **Human-AC tick** — the one assertion the agent is
  never permitted to make. The guard exists to protect exactly that record, and the
  failure mode is it writing a false one.
- A spurious block is itself the pressure that makes someone reach for the override. The
  defect manufactures the temptation and then mis-records the result.
- 16 files are live today; the count moves with the corpus, not with anything we control.

## 6. Remedy — the operator's call, not ours

The fix exists upstream (T-2954, `lib/comment_strip.py`, 33/33 green across four suites,
falsified both ways). Two routes:

- **A — version bump (recommended).** Take AEF's fix as shipped. Consistent with the
  vendoring model; no local divergence.
- **B — local in-tree patch under G-008.** Technically permitted, but it would collide
  with route A the moment the bump happens, and would fork a file AEF actively maintains.

**Not done under agent initiative, deliberately:** no `fw upgrade`, no
`--force-downgrade`, no `FW_UNDECIDABLE_VERSION_PROCEED`. AEF's own constraint at
DM 536 §1 is explicit — *"the bump is your operator's call, not mine and not yours"* —
and nothing measured here overrides it. This report is the evidence for that decision,
not a substitute for it.

Registered as **OBS-038** so the finding outlives this task's archival.

## 7. What this cost to find: nothing, and that is the point

AEF fixed a bug we reported and, in reporting the fix, described the mechanism precisely
enough that we could measure the same defect in our own tree in one session — including
a version-drift exposure neither side would have thought to look for. The rail carried
a working diagnostic, not just a status update.
