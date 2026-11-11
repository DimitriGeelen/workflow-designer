// T-1395 — one CDP client for every driver in tools/, which no wait can outlive.
//
// WHY THIS EXISTS. 133 harnesses carried the same hand-copied one-line client:
//
//     const cmd = (me, pa = {}) => new Promise((res, rej) => { p.set(mid, ...); s.send(...); });
//
// A command's promise settled only when Chrome answered it. If Chrome died first (killed under
// memory pressure, crashed), the socket closed, nothing rejected the waiting promise, and the
// harness sat in ep_poll for ever with no Chrome child. In T-358's close (2026-11-11, host load
// ~45) _t358-laneless-render-cdp.mjs waited 2 h that way and held the whole browser tier. The
// same harness passed minutes later on its own: the product was fine, the wait had no bound.
//
// Two guards, both named in the error so a red leg says what happened, not just "timeout":
//   - CDP CLOSED: the socket closed (or failed) while commands were waiting; every one is
//     rejected at once, and any command sent afterwards is rejected at once too.
//   - CDP TIMEOUT: a single command got no answer within cmdMs (default 120 s, or the
//     CDP_CMD_MS environment variable). Generous on purpose: it catches a hang, never a slow
//     evaluate. A harness that needs longer passes { cmdMs }.
// `ready` also rejects if the socket closes before it opens.
//
// Same interface as the copies it replaces ({ ready, cmd, close }), so the swap is mechanical;
// `onEvent` receives every CDP event (messages with a method and no id), for drivers that listen.

export const CLOSED = 'CDP CLOSED';
export const TIMEOUT = 'CDP TIMEOUT';
const DEFAULT_CMD_MS = (() => { const v = parseInt(process.env.CDP_CMD_MS || '', 10); return v > 0 ? v : 120000; })();

export function cdp(ws, { cmdMs = DEFAULT_CMD_MS, onEvent = null } = {}) {
  const s = new WebSocket(ws);
  let id = 0, gone = null;
  const pending = new Map();   // id -> { settle, fail, timer }
  const failAll = why => {
    if (gone) return;
    gone = why;
    for (const [, w] of pending) { clearTimeout(w.timer); w.fail(new Error(why)); }
    pending.clear();
  };
  s.addEventListener('message', ev => {
    let m; try { m = JSON.parse(ev.data); } catch (_) { return; }
    if (m.id && pending.has(m.id)) { const w = pending.get(m.id); pending.delete(m.id); clearTimeout(w.timer); w.settle(m); }
    else if (m.method && onEvent) { try { onEvent(m); } catch (_) {} }
  });
  const ready = new Promise((res, rej) => {
    s.addEventListener('open', res);
    s.addEventListener('error', e => { rej(e); failAll(`${CLOSED}: the DevTools socket failed (Chrome gone?)`); });
    s.addEventListener('close', ev => {
      rej(new Error(`${CLOSED} before open (code ${ev.code})`));
      failAll(`${CLOSED}: Chrome's DevTools socket closed (code ${ev.code}) while a command waited — Chrome died or was killed`);
    });
  });
  ready.catch(() => {});   // a caller that never awaits ready must not get an unhandled rejection
  const cmd = (me, pa = {}) => new Promise((res, rej) => {
    if (gone) { rej(new Error(`${gone} [${me}]`)); return; }
    const mid = ++id;
    const timer = setTimeout(() => { pending.delete(mid); rej(new Error(`${TIMEOUT}: ${me} got no answer in ${cmdMs} ms`)); }, cmdMs);
    pending.set(mid, {
      settle: m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result),
      fail: e => rej(new Error(`${e.message} [${me}]`)),
      timer,
    });
    try { s.send(JSON.stringify({ id: mid, method: me, params: pa })); }
    catch (e) { clearTimeout(timer); pending.delete(mid); rej(new Error(`${CLOSED}: send failed (${e.message}) [${me}]`)); }
  });
  return { ready, cmd, close: () => { try { s.close(); } catch (_) {} } };
}
