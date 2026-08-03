# T-353 — corpus readiness for the P-011 errexit gate change

**Status: measured. Nothing applied.** Every line in scope lives in `.tasks/completed/`,
which makes editing it a convention change across other owners' archived tasks — the same
class as G-015 leg 1. AC5 holds it at "proposed".

## 1. AC2 — the 19 DIVERGENT lines, classified by measurement

`tools/_t353-classify.py`. The bucket is classified by *running* each line, not by reading
it: the line is executed under the remedy construct with an `ERR` trap, so `$BASH_COMMAND`
names the diverging command — the subject's own report rather than my parse of it — and the
captured variable is then re-inspected to see what the assertion was actually matched against.

**Result: 19 of 19 `FAILURE-PATH-CORRECT`. Zero genuine false greens.**

Every one is a test whose subject exits non-zero *by design* — the validator rejecting an
invalid fixture, or `grep -c` exiting 1 because it counted the zero matches the line is
asserting. The remedy breaks all 19. This confirms T-352's inversion by measurement rather
than by reading, which is what AC2 asked for.

### What the instrument had to survive first

Four controls run before any verdict is emitted and must occupy **four distinct buckets**;
a collision exits non-zero with nothing reported. They caught three defects in this file:

1. **All three original controls collapsed into one bucket.** The head of every member is an
   *assignment* (`out=$(cmd 2>&1)`), so its own stdout is empty by construction — the output
   went into the variable. I was inspecting that empty stdout and reporting "pattern absent".
2. **The error vocabulary missed the only tool the corpus calls.** I listed
   `No such file or directory`; `validate-workflow.py` says `ERROR [E-LOAD] …: file not found`.
   A vocabulary built by imagining error text does not match the error text that exists.
3. **Three real lines were reported `ASSERTION-UNMET` by my own matcher.** Their patterns are
   grep BREs — `\[E-XML-AUTHORITY\]` matches the text `[E-XML-AUTHORITY]` — and I was testing
   them with a Python substring check. Fixed by asking `grep` instead of reimplementing it.
   A fourth control was then added specifically to prove `ASSERTION-UNMET` is still
   *reachable*, because a bucket that can never fill and a bucket that legitimately came up
   empty are indistinguishable.

## 2. AC1 — the repairs, proven to discriminate

`tools/_t353-repair-probe.sh`, 4 legs per target, gate construct extracted from
`update-task.sh` at runtime:

| leg | line | document | construct | required |
|---|---|---|---|---|
| 1 | original | rejected | current | **PASS** — the defect, reproduced |
| 2 | repaired | rejected | current | **FAIL** — the defect, removed |
| 3 | repaired | real | current | PASS — no regression |
| 4 | repaired | real | remedy | PASS — ready for the fix |

Leg 1 carries the argument. Without it the repair could be a no-op and legs 2–4 would read
identically. Without leg 3 a pattern refusing *everything* scores perfectly.

Repair: `grep -q "VALID"` → `grep -q "^VALID"`. The validator prints `VALID  <path>` and
`INVALID  <path>` both at column 0, so the anchor is the whole fix.

**14/16 legs pass. The two failures are the finding below.**

## 3. THE CORRECTION — "4 latent" was wrong, and the bucket it came from conflates two states

### 3a. T-299 is not latent. It fails today.

Its target document validates to `WARN … 0 error(s), 3 warning(s)` — the verdict word is
`WARN`, and the string `VALID` does not appear in the output **at all**. The line does not
pass; it is red. My published description — "they pass honestly *because their documents are
valid*" — is false for this one.

Corrected population: **3 latent + 1 already-red**, not 4 latent.

### 3b. The LATENT bucket contains 30 lines that never agreed about anything

`LATENT` was defined as "ran, both constructs agreed" and its prose reads *"the first command
simply succeeds today."* Tallying the recorded verdict pairs:

| pair | n |
|---|---:|
| `(PASS/PASS)` — genuinely latent | 159 |
| **`(FAIL/n/a)`** — **fails under the current gate; C-run skipped because A already failed** | **30** |

Those 30 did not agree. They *failed*, and "n/a" is the absence of a second measurement, not
a matching one. **A bucket keyed on "the two constructs did not differ" spans both
"both passed" and "never got far enough to differ", and I described the whole of it as the
first.**

This is the same defect as the DIVERGENT inversion — a bucket named by a predicate, then
described as if it were one of the two opposite states that predicate spans — committed one
section below the paragraph diagnosing it. Third instance on this arc (T-343, T-341, T-352).

### 3c. …and 30 is a FLOOR, not a count (found by T-354)

The T-352 scan only ever examined lines carrying a **top-level `;`** — that was its entire
population definition. So "30 red lines" means *30 red lines among the `;`-shaped ones*. A red
line without a `;` was never a candidate.

T-178 makes the gap concrete. It has **three** red verification lines, not one:

```
grep -q '^0.2.0$' VERSION                              # no ';' — invisible to the scan
m=$(grep '^sha256:' …); a=$(sha256sum …); [ "$m" = "$a" ]   # ';' — the one that was found
grep -q 'latest: "0.2.0"' dist/MANIFEST.yaml           # no ';' — invisible to the scan
```

Two of three were outside the scan's reach. **The corpus-wide count of red verification lines
is unmeasured and strictly greater than 30.** Wherever 30 appears — here, and in RAIL-408 — it
is a lower bound.

This is the *subpopulation's property stated about the tree* error, the same one retracted at
RAIL-387 ("zero `curl` lines in any verification block" was active-tasks-only; the real figure
was 15). What survives unchanged: every specific red line named is genuinely red, and the
`29 archived / 1 live` split of the found set is unaffected. The finding holds; the population
sentence did not.

## 4. A LIVE consequence: T-178 is queued for review and will be blocked

29 of the 30 red lines are in archived tasks that never re-run. **One is not.**

`.tasks/active/T-178` — status `work-completed`, `owner: human`, queued at `/review/T-178`:

```bash
m=$(grep '^sha256:' dist/MANIFEST.yaml | tr -d ' "' | cut -d: -f2); a=$(sha256sum dist/aef-workflow-designer-0.2.0.html | awk '{print $1}'); [ "$m" = "$a" ]
```

`MANIFEST.yaml`'s `sha256:` field always names the **latest** release. It is at `0.8.0` and
is internally correct (verified: the field matches `dist/aef-workflow-designer-0.8.0.html`
byte for byte). The line pins **0.2.0** against it. It was true exactly once, at the moment
0.2.0 was latest, and has been false through eight releases since.

**Consequence:** when the operator ticks T-178's Human AC and runs
`fw task update T-178 --status work-completed`, the P-011 gate will refuse the completion —
on a task whose actual deliverable shipped, for a reason that has nothing to do with it.

This is the **G-015 shape**: a verification line asserting a global, always-moving property.
Third carrier found (after the `diff src/… build/gallery/designer.html` family and the
hard-coded ports). Filed separately — one bug, one task — and **not repaired here**: T-178
is another owner's active task and editing its gate is the same convention question AC5 parks.

## 5. AC3 + AC4 — the conversions, proven under both constructs

`tools/_t353-convert.py`. Every one of the 19 is a command that is *supposed* to fail, so the
conversion makes that expectation explicit and lets the assertion carry the whole verdict:

```diff
- out=$(python3 tools/validate-workflow.py BROKEN.xml 2>&1); echo "$out" | grep -q "E-CODE"
+ out=$(python3 tools/validate-workflow.py BROKEN.xml 2>&1 || true); echo "$out" | grep -q "E-CODE"
```

Only *assignments* are converted. A `$(…)` used as a value inside the assertion —
`test "$(echo "$out" | grep -c X)" = "1"` — is part of the verdict, and blanketing it with
`|| true` would make the assertion unable to fail at all.

Three legs per line:

| leg | line | construct | required |
|---|---|---|---|
| 1 | original | remedy | **FAIL** — proves the conversion is not a no-op |
| 2 | converted | remedy | PASS — ready for the gate change |
| 3 | converted | current | PASS — no regression before it lands |

**19/19 pass 3/3. DIVERGENT remaining after conversion: 0.**

Leg 1 is what stops this being a ritual: without it, a conversion that changed nothing scores
2/2 and the corpus gets declared ready on the strength of lines that were never at risk.

## 6. AC1 amended before ticking

AC1 as written required each repaired line to PASS against "the real document". That
presupposed all four documents are valid. Three are; **T-299's is not**, so the requirement is
unsatisfiable for it — and forcing it green would have buried §3a.

The probe therefore declares the expected verdict per target and asserts, for T-299, the two
things that are actually true and falsifiable: the **original** line is already red
(`leg3n` — which is the correction to T-352's classification), and the repair does not change
that, because a tightened pattern cannot fix a stale document (`leg4n`).

**16/16 legs green.** Amended rather than quietly re-scoped, per the T-351 precedent.

## 7. What is deliberately not claimed

- The 30 red lines were **counted from the T-352 scan's recorded verdict pairs**, not re-run.
  Their redness is as of that scan. T-178 and T-299 were re-measured individually and both
  confirmed red today; the other 28 were not.
- Whether the 29 archived red lines should be repaired **at all** is open. They are inert —
  archived verification blocks do not re-run — so repairing them buys tidiness, not safety,
  and touches other owners' records to get it.
- `SKIPPED` (79) remains unmeasured, not clean. Bulk-executing arbitrary verification lines
  is the shape that deleted this repository during T-350.
