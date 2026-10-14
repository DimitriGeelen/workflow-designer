#!/usr/bin/env python3
"""T-1172 — opening a map from Watchtower's /designer page keeps Watchtower around it.

Before: a card's "Open in editor" went to /designer/app, the bare designer bundle as the whole tab, and only the
browser's Back returned to Watchtower. Now it goes to /designer/open, a Watchtower page (normal navigation) that
frames /designer/app with the same load value and offers a fullscreen toggle like the fabric browser.

Legs (Flask test client on the vendored Watchtower, the project's own store):
  1. /designer/open?load=<a map's server-latest src> answers 200 with Watchtower's navigation, the designer frame
     (src /designer/app?load=<the same value>), the fullscreen button and the fullscreenchange wiring.
  2. The frame's load value is the page's, byte for byte, so the T-2596 click-time nonce minted into it reaches
     /designer/app (whose T-2599 redirect mints one only when it is missing).
  3. /designer/open without ?load falls back to /designer (302).
  4. /designer's cards link to /designer/open and keep the click-time nonce minter (T-2596).
  5. /designer/app still answers on its own (old links, the blank editor): 200, or 302 to its nonce.
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
c = app.test_client()
out = {}
land = c.get("/designer")
html = land.get_data(as_text=True)
m = re.search(r'href="(/designer/open\?load=[^"]+)"', html)
out["landing_status"] = land.status_code
out["card_href"] = m.group(1) if m else None
out["card_nonce_minter"] = bool(re.search(r'href="/designer/open\?load=[^"]+"[^>]*\s+onclick="this\.href=this\.href\.split\(\'%26t%3D\'\)', html))
out["cards_to_app"] = len(re.findall(r'class="corpus-open" href="/designer/app\?', html))
href = out["card_href"] or "/designer/open?load=%2Fapi%2Fversion%3Fid%3Dtask-lifecycle%26v%3D1"
href_nonce = href + "%26t%3D1700000000000"
r = c.get(href_nonce)
page = r.get_data(as_text=True)
fr = re.search(r'<iframe id="dsg-frame" src="([^"]+)"', page)
out["open_status"] = r.status_code
out["open_has_nav"] = ('<nav' in page) and ('/designer' in page)
out["open_frame_src"] = fr.group(1) if fr else None
out["open_has_fs_button"] = 'id="dsg-fullscreen-btn"' in page and "requestFullscreen" in page
out["open_has_fs_sync"] = "fullscreenchange" in page
from urllib.parse import parse_qs, urlsplit, unquote
page_load = parse_qs(urlsplit(href_nonce).query)["load"][0]
frame_load = parse_qs(urlsplit(out["open_frame_src"] or "").query).get("load", [""])[0]
out["load_carried"] = frame_load == page_load and "t=1700000000000" in frame_load
noload = c.get("/designer/open")
out["noload_status"] = noload.status_code
out["noload_location"] = noload.headers.get("Location", "")
app_r = c.get("/designer/app")
out["app_status"] = app_r.status_code
# T-1175: the full-width rule is on the inline page, scoped to it, and not on the landing page
rule = "main#content:has(#dsg-stage)"
out["fullwidth_on_open"] = rule in page and "max-width: none" in page
out["fullwidth_not_on_landing"] = rule not in html
print(json.dumps(out))
'''


def main():
    env = dict(os.environ, FW_DIR=FW, PROJECT_ROOT=ROOT)
    p = subprocess.run([sys.executable, "-c", PROBE], env=env, capture_output=True, text=True, timeout=180)
    line = (p.stdout.strip().splitlines() or [""])[-1]
    try:
        o = json.loads(line)
    except ValueError:
        print("COULD NOT MEASURE: the Watchtower app did not answer\n" + (p.stderr or p.stdout)[-800:])
        return 2
    legs = [
        ("1 /designer/open renders inside Watchtower (navigation), with the designer frame and the fullscreen toggle",
         o["open_status"] == 200 and o["open_has_nav"] and bool(o["open_frame_src"]) and o["open_has_fs_button"]
         and o["open_has_fs_sync"] and (o["open_frame_src"] or "").startswith("/designer/app?load=")),
        ("2 the frame carries the page's load value byte for byte, nonce included", o["load_carried"]),
        ("3 /designer/open without a map falls back to /designer",
         o["noload_status"] == 302 and o["noload_location"].endswith("/designer")),
        ("4 the landing cards open /designer/open and keep the click-time nonce minter (T-2596)",
         o["landing_status"] == 200 and bool(o["card_href"]) and o["card_nonce_minter"] and o["cards_to_app"] == 0),
        ("5 /designer/app still answers on its own", o["app_status"] in (200, 302)),
        ("6 the inline page lifts Watchtower's width cap for itself only (T-1175)",
         o["fullwidth_on_open"] and o["fullwidth_not_on_landing"]),
    ]
    for name, ok in legs:
        print(("PASS  " if ok else "FAIL  ") + name)
    if not all(ok for _, ok in legs):
        print(json.dumps(o, indent=1))
        return 1
    print("%d/%d legs passed" % (len(legs), len(legs)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
