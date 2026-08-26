// T-604 — one definition of "attach to the page target", shared by every CDP driver.
//
// WHY THIS EXISTS. Chromium writes DevToolsActivePort when the BROWSER is listening.
// That is not the same instant the PAGE target is registered in /json. Every driver in
// tools/ had its own hand-copied spawn block that read the target list ONCE and
// dereferenced it with no retry:
//
//     cl = cdp(tg.find(t => t.type === 'page').webSocketDebuggerUrl);
//
// In the registration window find() returns undefined and the property access throws a
// bare TypeError, which surfaces as "DRIVER ERROR ... exit 2". Identical bytes, two
// verdicts. That is OBS-313: the P-011 gate reddened T-603 on correct code, then passed
// on re-run. Measured under contention it reproduces on the SECOND browser of a
// self-test, and it fails FASTER than a passing run (3s vs 5-6s) — which is why the
// "editor load timeout" diagnosis I first wrote down could never have been right.
//
// Two drivers (_t570, _t572) already carried a retry loop. It was written twice and
// never swept, so 73 other call sites kept the defect. A guard that exists in two copies
// and is missing from seventy-three is not a guard, it is a coincidence. Hence: one
// definition, imported — not a pattern to be re-typed.
//
// The thrown message names ATTACH explicitly, because the failure it replaces was
// indistinguishable at a glance from a real verification leg going red, and a gate that
// intermittently reddens correct work is what trains --skip-verification into fingers.

const sleep = ms => new Promise(r => setTimeout(r, ms));

export const ATTACH_FAIL = 'CDP ATTACH FAILED';

/**
 * Resolve the page target's WebSocket URL, retrying until the target is registered.
 *
 * @param {number} port        DevTools port from DevToolsActivePort
 * @param {object} [opts]
 * @param {number} [opts.budgetMs=10000]  total time to keep retrying
 * @param {number} [opts.stepMs=50]       pause between attempts
 * @param {string} [opts.host='127.0.0.1']
 * @returns {Promise<string>}  ws:// debugger URL
 * @throws  Error whose message starts with ATTACH_FAIL, naming the cause
 */
export async function pageWsUrl(port, opts = {}) {
  const budgetMs = opts.budgetMs ?? 10000;
  const stepMs = opts.stepMs ?? 50;
  const host = opts.host ?? '127.0.0.1';
  const t0 = Date.now();
  let attempts = 0, lastSeen = 'no response';

  for (;;) {
    attempts++;
    try {
      const targets = await (await fetch('http://' + host + ':' + port + '/json')).json();
      if (Array.isArray(targets)) {
        const page = targets.find(t => t && t.type === 'page' && t.webSocketDebuggerUrl);
        if (page) return page.webSocketDebuggerUrl;
        lastSeen = targets.length
          ? targets.length + ' target(s), types: ' + targets.map(t => t && t.type).join(',')
          : 'empty target list';
      } else lastSeen = 'non-array response';
    } catch (e) {
      lastSeen = 'fetch failed: ' + (e && e.message || e);
    }
    const spent = Date.now() - t0;
    if (spent > budgetMs) {
      throw new Error(
        ATTACH_FAIL + ': no page target on ' + host + ':' + port + ' after ' + attempts +
        ' attempt(s) in ' + spent + 'ms (last: ' + lastSeen + '). ' +
        'This is a BROWSER ATTACH failure, not a verification leg failing — ' +
        'the code under test was never exercised.');
    }
    await sleep(stepMs);
  }
}
