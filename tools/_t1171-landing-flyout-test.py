#!/usr/bin/env python3
"""T-1171 — the /designer landing cards' thumbnail fly-out (hover to enlarge, an Open button).

Markup legs on the rendered page (Flask test client on the vendored Watchtower, the project's own store); the
hover / leave / Open behaviour was measured in a browser and is recorded in the task with screenshots.
  1. Every card WITH a thumbnail has exactly one fly-out holding the same image and an Open button.
  2. Cards WITHOUT a thumbnail have no fly-out.
  3. The fly-out's Open button, its image and the thumbnail open through corpusOpenCard(), i.e. by clicking the
     card's own editor link — they are not links themselves.
  4. Every card still has exactly ONE link carrying ?load (the T-2596 nonce minter), so the per-card counter holds.
  5. The page defines corpusOpenCard and wires the hover once per wrap (re-insertion by htmx does not double it).
Exit 0 = all legs pass; 1 = a leg failed; 2 = could not run.
"""
import json
import os
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FW = os.path.join(ROOT, ".agentic-framework")

PROBE = r'''
import json, os, re, sys
sys.path.insert(0, os.environ["FW_DIR"]); os.chdir(os.environ["FW_DIR"])
from web.app import app
html = app.test_client().get("/designer").get_data(as_text=True)
cards = re.split(r'<div class="corpus-card', html)[1:]
out = {"cards": len(cards), "rows": []}
for c in cards:
    c = c.split('<div class="corpus-card')[0]
    thumb = re.search(r'<div class="corpus-thumb"[^>]*>\s*<img src="([^"]+)"', c)
    fly = re.findall(r'<div class="corpus-flyout"', c)
    fly_img = re.search(r'<div class="corpus-flyout"[^>]*>\s*<img src="([^"]+)"[^>]*onclick="corpusOpenCard\(this\)"', c)
    out["rows"].append({
        "has_thumb": bool(thumb),
        "flyouts": len(fly),
        "same_img": bool(thumb and fly_img and thumb.group(1) == fly_img.group(1)),
        "open_btn": bool(re.search(r'<button type="button" class="corpus-flyout-open" onclick="corpusOpenCard\(this\)"', c)),
        "thumb_click": bool(re.search(r'<div class="corpus-thumb" onclick="corpusOpenCard\(this\)"', c)) if thumb else None,
        "no_thumb_placeholder": 'corpus-thumb no-thumb' in c,
        "load_links": len(re.findall(r'<a [^>]*href="[^"]*\?load=', c)),
    })
out["has_fn"] = "window.corpusOpenCard" in html and "a.corpus-open:not(.corpus-overlay)" in html
out["wired_once"] = "__flyWired" in html
print(json.dumps(out))
'''


def main():
    env = dict(os.environ, FW_DIR=FW, PROJECT_ROOT=ROOT)
    p = subprocess.run([sys.executable, "-c", PROBE], env=env, capture_output=True, text=True, timeout=180)
    try:
        o = json.loads((p.stdout.strip().splitlines() or [""])[-1])
    except ValueError:
        print("COULD NOT MEASURE: the Watchtower app did not answer\n" + (p.stderr or p.stdout)[-800:])
        return 2
    rows = o["rows"]
    with_t = [r for r in rows if r["has_thumb"]]
    without = [r for r in rows if not r["has_thumb"]]
    if not with_t:
        print("COULD NOT MEASURE: no card with a thumbnail in this store")
        return 2
    legs = [
        ("1 every thumbnail card has exactly one fly-out with the same image and an Open button (%d cards)" % len(with_t),
         all(r["flyouts"] == 1 and r["same_img"] and r["open_btn"] for r in with_t)),
        ("2 cards without a thumbnail have no fly-out (%d such cards)" % len(without),
         all(r["flyouts"] == 0 for r in without)),
        ("3 the thumbnail, the fly-out image and Open go through corpusOpenCard (not links)",
         all(r["thumb_click"] for r in with_t)),
        ("4 every card keeps exactly one ?load link (T-2596 nonce minter)", all(r["load_links"] == 1 for r in rows)),
        ("5 corpusOpenCard clicks the card's editor link; the hover is wired once per wrap", o["has_fn"] and o["wired_once"]),
    ]
    for name, ok in legs:
        print(("PASS  " if ok else "FAIL  ") + name)
    if not all(ok for _, ok in legs):
        print(json.dumps(o, indent=1)[:2000])
        return 1
    print("%d/%d legs passed" % (len(legs), len(legs)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
