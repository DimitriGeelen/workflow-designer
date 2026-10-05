#!/usr/bin/env python3
"""_t1048-gallery-thumbs.py — every design on the gallery overview page has a preview tile.

T-1048 (operator, 2026-10-05): the overview page (tools/serve-gallery.sh → index.html) shows a small
preview per design. This builds the page into a throwaway GALLERY_DIR with the tile refresh switched
off (no browser needed) and asserts the page as built, never a description of it:

  1. every corpus map is listed, in its own <li>, with both links pointing at the same map
  2. every listed map has a tile: an <img> whose file exists and is a non-empty PNG
  3. no <img> on the page points at a file that is not there (no broken images)
  4. CONTROL: with an EMPTY tile directory every entry falls back to the "no preview" box. That is
     the degraded path, and it must render placeholders, not broken <img> tags.
     It also proves leg 2 can fail: the same build with no tiles is reported as missing tiles.

Stale tiles (older than their map) are reported, not failed. serve-gallery.sh refreshes them on
every real build, and this check deliberately does not launch a browser.
Exit 0 = all legs pass; 1 = a leg failed; 2 = could not build the page.
"""
import os
import re
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SCRIPT = os.path.join(ROOT, "tools", "serve-gallery.sh")
CACHE = os.path.join(ROOT, ".editor-versions", "_rendered")
CORPORA = [os.path.join(ROOT, "examples", d, "rendered") for d in ("aef-processes", "app-processes")]
PNG = b"\x89PNG\r\n\x1a\n"


def build(out, thumbs=None):
    env = dict(os.environ, GALLERY_DIR=out, GALLERY_SKIP_THUMBS="1")
    if thumbs is not None:
        env["GALLERY_THUMBS_DIR"] = thumbs
    r = subprocess.run(["bash", SCRIPT, "--build-only"], env=env, capture_output=True, text=True, timeout=300)
    if r.returncode != 0:
        print("CANNOT BUILD: serve-gallery.sh --build-only exited %d: %s" % (r.returncode, r.stderr.strip()[-300:]))
        sys.exit(2)
    with open(os.path.join(out, "index.html"), encoding="utf-8") as fh:
        return fh.read()


def entries(html):
    return re.findall(r"<li>(.*?)</li>", html, re.S)


def main():
    maps = sorted({f[:-5] for d in CORPORA if os.path.isdir(d) for f in os.listdir(d) if f.endswith(".bpmn")})
    if not maps:
        print("CANNOT BUILD: no corpus maps found")
        return 2
    fails = []

    def leg(ok, name, detail=""):
        print("%s  %s%s" % ("PASS" if ok else "FAIL", name, (" — " + detail) if detail else ""))
        if not ok:
            fails.append(name)

    with tempfile.TemporaryDirectory() as tmp:
        out = os.path.join(tmp, "g")
        html = build(out)
        lis = entries(html)
        listed = []
        for li in lis:
            hrefs = re.findall(r'href="designer\.html\?load=rendered/([^"]+)\.bpmn"', li)
            listed.append(hrefs[0] if hrefs and len(set(hrefs)) == 1 else None)
        leg(sorted(x for x in listed if x) == maps and None not in listed,
            "1 every corpus map is listed once, tile and name linking the same map",
            "%d listed, %d maps" % (len(lis), len(maps)))

        missing = []
        for li, m in zip(lis, listed):
            src = re.search(r'<img src="thumbs/([^"]+)"', li)
            ok = False
            if src:
                path = os.path.join(out, "thumbs", src.group(1))
                if os.path.isfile(path):
                    with open(path, "rb") as fh:
                        ok = fh.read(8) == PNG
            if not ok:
                missing.append(m)
        leg(not missing, "2 every listed design has a preview tile (an existing PNG)",
            "missing: %s" % missing if missing else "%d tiles" % len(lis))

        broken = [s for s in re.findall(r'<img src="([^"]+)"', html) if not os.path.isfile(os.path.join(out, s))]
        leg(not broken, "3 no <img> points at a missing file", "broken: %s" % broken if broken else "")

        empty = os.path.join(tmp, "no-tiles")
        os.mkdir(empty)
        out2 = os.path.join(tmp, "g2")
        html2 = build(out2, thumbs=empty)
        lis2 = entries(html2)
        leg(len(lis2) == len(maps) and "<img" not in html2 and html2.count('class="ph">no preview') == len(maps),
            "4 CONTROL: with no tiles, every entry shows the 'no preview' box and no <img> is emitted",
            "%d placeholders over %d entries" % (html2.count('class="ph">no preview'), len(lis2)))

    stale = [m for m in maps for d in CORPORA
             if os.path.isfile(os.path.join(d, m + ".bpmn")) and os.path.isfile(os.path.join(CACHE, m + ".png"))
             and os.path.getmtime(os.path.join(d, m + ".bpmn")) > os.path.getmtime(os.path.join(CACHE, m + ".png"))]
    print("INFO  %d stale tile(s)%s (refreshed by the next real serve-gallery.sh build)"
          % (len(stale), (": " + ", ".join(stale)) if stale else ""))

    print("\n%d/4 legs passed" % (4 - len(fails)))
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
