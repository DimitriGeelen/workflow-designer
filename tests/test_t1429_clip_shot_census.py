#!/usr/bin/env python3
"""T-1429: every CDP harness that clips a screenshot to an element either uses the clear-shot guard or is listed here.

A clip is a viewport rectangle. Page.captureScreenshot does not care what is painted there, so an element under the
properties panel or past the window edge is "shot" as whatever covers it, and the harness exits 0. That happened twice
in a day (T-1427: _t884 refused-*.png went from 6.8 KB to a 902 B blank; T-893: differs-*.png showed the panel instead
of the marker). tools/_cdp-clear-shot.mjs widens the window when needed, refuses unless document.elementFromPoint at the
element's centre is the element, and only then captures.

The rule this enforces:
  - a harness under tools/ that calls Page.captureScreenshot with a `clip` imports _cdp-clear-shot.mjs, or
  - it is in UNGUARDED below with the reason it is not guarded yet.
A NEW clip-shot harness without the guard fails. An UNGUARDED entry whose file now imports the guard (or no longer
clips) fails too, so the list cannot go stale. Controls prove both directions bite.
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TOOLS = os.path.join(ROOT, "tools")
GUARD = "_cdp-clear-shot.mjs"

NODE = "shoots map nodes, which move under the properties panel or past the window as the layout changes: guard next (T-1429)"
CHROME = "shoots fixed UI (toolbar, panels, dialogs, labels at known places), not map nodes that move: lower risk, guard when touched"
UNGUARDED = {
    "_t1078-advisory-overlap-cdp.mjs": NODE,
    "_t1366-shots.mjs": NODE,
    "_t1381-shots.mjs": NODE,
    "_t1369-shots.mjs": NODE,
    "_t258-annotation-seam-cdp.mjs": NODE,
    "_t601-lane-boundary.mjs": NODE,
    "_t884-instance-overlay-cdp.mjs": "has its own equivalent guard from T-1427 (widens the window, fails on a blank shot); move to the shared one",
    "_t892-lane-default-cdp.mjs": NODE,
    "_t1327-notice-shots.mjs": NODE,
    "_t884-live-proof-cdp.mjs": NODE,
    "_t1126-field-suggestions-cdp.mjs": CHROME,
    "_t1125-field-profile-cdp.mjs": CHROME,
    "_selection-align-verify-cdp.mjs": CHROME,
    "_t1067-side-label-wrap-cdp.mjs": CHROME,
    "_t1124-hide-empty-fields-cdp.mjs": CHROME,
    "_t1176-toolbar-reach-cdp.mjs": CHROME,
    "_endpoint-hover-verify-cdp.mjs": CHROME,
    "_t1365-shots.mjs": CHROME,
    "_t1128-field-defaults-settings-cdp.mjs": CHROME,
    "_t1249-v11-io-shots.mjs": CHROME,
    "_t255-visual-shots.mjs": CHROME,
    "_t251-visual-shots.mjs": CHROME,
    "_t1345-message-shots.mjs": CHROME,
    "_t1155-doc-title-verify-cdp.mjs": CHROME,
    "_t911-kind-badge-verify-cdp.mjs": CHROME,
}

# `clip:` written out, the shorthand `{ format: 'png', clip }`, or a ternary `clip ? { … clip } : …` — all clip.
CLIP_SHOT = re.compile(r"captureScreenshot['\"]?\s*,[^;]{0,160}?\bclip\b", re.S)


def clips(text):
    return bool(CLIP_SHOT.search(text))


def census(files):
    """files: {name: text}. Returns (unguarded_new, stale_entries)."""
    new, stale = [], []
    for name, text in sorted(files.items()):
        if name == GUARD:
            continue
        guarded = GUARD in text
        if clips(text) and not guarded and name not in UNGUARDED:
            new.append(name)
    for name in sorted(UNGUARDED):
        text = files.get(name)
        if text is None or GUARD in text or not clips(text):
            stale.append(name)
    return new, stale


def main():
    files = {}
    for f in os.listdir(TOOLS):
        if f.endswith(".mjs"):
            with open(os.path.join(TOOLS, f), encoding="utf-8") as fh:
                files[f] = fh.read()
    fails = []
    new, stale = census(files)
    for n in new:
        fails.append("%s clips a screenshot without %s: import clearShot, or list it in UNGUARDED with a reason" % (n, GUARD))
    for s in stale:
        fails.append("UNGUARDED lists %s, which is gone, now guarded, or no longer clips: remove the entry" % s)
    guarded = sorted(n for n, t in files.items() if n != GUARD and GUARD in t and clips(t) is False or (n != GUARD and GUARD in t))
    print("guarded: %s" % ", ".join(guarded) or "none")
    print("unguarded, listed: %d (%d shoot map nodes)" % (len(UNGUARDED), sum(1 for v in UNGUARDED.values() if v == NODE)))

    # Controls: a new unguarded clip shot is caught; an entry whose file adopted the guard is caught as stale.
    shot = "await cmd('Page.captureScreenshot', { format: 'png', clip: { x: 0, y: 0, width: 1, height: 1 } });"
    n2, _ = census({"_new-cdp.mjs": shot})
    if n2 != ["_new-cdp.mjs"]:
        fails.append("control: a new unguarded clip shot was not caught (%r)" % n2)
    n3, _ = census({"_new-cdp.mjs": "import { clearShot } from './_cdp-clear-shot.mjs';\n" + shot})
    if n3:
        fails.append("control: a guarded clip shot was flagged (%r)" % n3)
    name = next(iter(UNGUARDED))
    _, s2 = census({name: "import { clearShot } from './_cdp-clear-shot.mjs';\n" + shot})
    if name not in s2:
        fails.append("control: an UNGUARDED entry that adopted the guard was not reported stale")
    if not clips(shot) or clips("await cmd('Page.captureScreenshot', { format: 'png' });"):
        fails.append("control: the clip detector reads a shot wrong")

    for f in fails:
        print("FAIL: " + f)
    print("%s: %d failure(s)" % ("PASS" if not fails else "FAIL", len(fails)))
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
