# T-1465 Human AC#1 — independent review (rung 3), revision 4f7412980

Images opened: docs/reports/T-1465-shots/task-lifecycle-wide-{before,after}.png,
task-gate-wide-{before,after}.png (3000x1000). Not re-rendered (images judged as given).
Crops (cited, this directory, suffix = dispatch id): task-lifecycle-{before,after}-bottom,
task-gate-{before,after}-bottom, task-gate-after-zoom.

## task-lifecycle
- Before: 'gate failed — rework' bar runs below the pool's bottom edge, across the
  "+ Add another lane" strip; its label overlays the strip text ("+ Add ⟨gate failed — rework⟩").
- After: identical route (Run-gates gateway down, left along the bottom, up into "Perform the work").
  Pool/agent lane is drawn taller; bar and label sit inside, ~10 px above the pool edge.
  Strip is below the pool, text "+ Add another lane" fully legible, nothing on it.
- Every other node, flow and label is pixel-identical by inspection. Reads better.

## task-gate
- Before: 're-issue' and 'agent remediates' bar runs below the pool edge over the strip; both labels
  straddle the pool border line; strip text sits right under the bar.
- After: routes unchanged; pool drawn taller. Pixel scan at x=600: flow at y=631-632, pool
  border at y=635-636 (before: border 620-621, flow 631-632). Both labels sit inside the pool,
  clear of the border. Strip moved down (~y=650+), its text clear and unobstructed.
- The bar runs only ~2 px above the pool border. At 100% the brighter flow line and the dimmer
  border are still distinct (see zoom crop), so it does not read worse than before, where the
  bar lay outside the pool across the strip. Minor nit, not a failure: a few px more pool padding
  under the lowest bar would give it more air.

## Verdict: green
Each after reads at least as well as its before (better: strip cleared, labels off borders);
no flow or label on the strip in either after image; routes unchanged versus before, as Step 3 says.
