// T-1429: an element screenshot shows its element, or fails.
//
// Page.captureScreenshot with a `clip` takes a rectangle in viewport coordinates. It does not care what is painted
// there: an element under the properties panel, past the window edge or scrolled away is "shot" as whatever covers
// it, and the harness exits 0. That happened twice in a day (T-1427: _t884 refused-*.png went from 6.8 KB to a 902 B
// blank; T-893: differs-*.png showed the panel instead of the marker).
//
// clearShot() measures the element; if its clip runs past the canvas (the properties panel's left edge, or the
// window), it widens the window just enough, re-renders and re-measures. Then it asks the page what is painted at the
// element's centre (document.elementFromPoint) and refuses unless that is the element or inside it. Only then it
// captures, and puts the window back.
//
//   import { clearShot } from './_cdp-clear-shot.mjs';
//   const png = await clearShot(cmd, ev, 'g.node[data-id="n1"]', { pad: 30, rerender: 'renderAll(); true' });
//
// `cmd` is the CDP command function (_cdp-client.mjs), `ev` an evaluate helper `(cmd, expr) => value`.

const sleep = ms => new Promise(r => setTimeout(r, ms));

// The designer's right-hand properties panel. Anything right of its left edge is covered.
const PANEL = '#properties';

function measureExpr(sel, pad) {
  return `(() => {
    const el = document.querySelector(${JSON.stringify(sel)});
    if (!el) return null;
    const r = el.getBoundingClientRect();
    const p = document.querySelector(${JSON.stringify(PANEL)});
    const pr = p ? p.getBoundingClientRect() : null;
    // The panel covers the canvas, not itself: an element inside the panel is bounded by the window only.
    const inPanel = !!(p && p.contains(el));
    const edge = (!inPanel && pr && pr.width > 0 && pr.left > 0) ? pr.left : innerWidth;
    const cx = r.x + r.width / 2, cy = r.y + r.height / 2;
    const hit = (cx >= 0 && cy >= 0 && cx < innerWidth && cy < innerHeight) ? document.elementFromPoint(cx, cy) : null;
    // On screen means: what is painted at the centre is the element, inside it, or on the same canvas (an SVG element
    // of the element's own <svg>, e.g. a flow drawn across a gateway). A panel, a dialog, the page background past the
    // window, or nothing at all is not.
    const svg = el.ownerSVGElement || null;
    const sameCanvas = !!(hit && svg && (hit === svg || (hit.ownerSVGElement === svg)));
    return { x: r.x, y: r.y, w: r.width, h: r.height, edge, iw: innerWidth, ih: innerHeight,
             painted: !!(hit && (hit === el || el.contains(hit) || sameCanvas)),
             hit: hit ? (hit.id ? '#' + hit.id : hit.tagName.toLowerCase() + (hit.className && hit.className.baseVal === undefined ? '.' + String(hit.className).split(' ')[0] : '')) : null,
             pad: ${pad} };
  })()`;
}

export async function clearShot(cmd, ev, sel, opts = {}) {
  const pad = opts.pad ?? 24;
  const padTop = opts.padTop ?? pad;
  const rerender = opts.rerender || 'true';
  const settle = opts.settleMs ?? 200;
  let m = await ev(cmd, measureExpr(sel, pad));
  if (!m) throw new Error(`clearShot: no element ${sel}`);
  let widened = false;
  const right = m.x + m.w + pad;
  const bottom = m.y + m.h + pad;
  if (opts.widen !== false && (right > m.edge || bottom > m.ih)) {
    const w = Math.ceil(Math.max(m.iw, m.iw + (right - m.edge) + 40));
    const h = Math.ceil(Math.max(m.ih, bottom + 40));
    await cmd('Emulation.setDeviceMetricsOverride', { width: w, height: h, deviceScaleFactor: 1, mobile: false });
    await ev(cmd, rerender); await sleep(settle);
    m = await ev(cmd, measureExpr(sel, pad)); widened = true;
    if (!m) throw new Error(`clearShot: ${sel} gone after widening`);
  }
  try {
    if (m.x + m.w + pad > m.edge) throw new Error(`clearShot: ${sel} is still under the properties panel (right ${Math.round(m.x + m.w + pad)} > panel ${Math.round(m.edge)})`);
    if (!m.painted) throw new Error(`clearShot: ${sel} is not what is painted at its centre (found ${m.hit})`);
    const s = await cmd('Page.captureScreenshot', { format: 'png', clip: {
      x: Math.max(0, m.x - pad), y: Math.max(0, m.y - padTop), width: m.w + 2 * pad, height: m.h + pad + padTop, scale: opts.scale ?? 2 } });
    return Buffer.from(s.data, 'base64');
  } finally {
    if (widened) { await cmd('Emulation.clearDeviceMetricsOverride'); await ev(cmd, rerender); await sleep(settle); }
  }
}
