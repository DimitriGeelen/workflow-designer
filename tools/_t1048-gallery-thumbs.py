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

    # ── Watchtower's /designer corpus page (vendored AEF template + blueprint, T-1048) ──
    try:
        import jinja2
        tpl_dir = os.path.join(ROOT, ".agentic-framework", "web", "templates")
        env = jinja2.Environment(loader=jinja2.FileSystemLoader(tpl_dir), autoescape=True)
        env.globals["csrf_token"] = lambda: "x"
        cards = [dict(id="with", title="with", latest_v=2, version_count=2, saved_h="t", open_url="/designer/app?load=%2Fapi%2Fversion%3Fid%3Dwith%26v%3D2",
                      is_draft=False, has_overlay=False, thumb_url="/api/thumb?id=with&v=2"),
                 dict(id="without", title="without", latest_v=1, version_count=1, saved_h="t", open_url="/designer/app?load=%2Fapi%2Fversion%3Fid%3Dwithout%26v%3D1",
                      is_draft=False, has_overlay=False, thumb_url=None)]
        out_html = env.get_template("designer_landing.html").render(projects=cards, ghost_count=0)
        ok = (out_html.count('<img src="/api/thumb?id=with&amp;v=2"') == 1 and out_html.count('class="corpus-thumb no-thumb"') == 1
              and out_html.count("/api/thumb?id=without") == 0 and out_html.count("onclick=\"this.href=") == 2)
        leg(ok, "5 Watchtower card template: a tile when the PNG exists, 'no preview' (no <img>) when not, one nonce-minting editor link per card (T-2596)")
    except Exception as e:  # noqa: BLE001 — a template that cannot render is a failure, said as one
        leg(False, "5 Watchtower card template renders", "%s: %s" % (type(e).__name__, e))

    import urllib.request
    try:
        base = open(os.path.join(ROOT, ".context", "working", "watchtower.url")).read().strip()
        page = urllib.request.urlopen(base + "/designer", timeout=10).read().decode("utf-8", "replace")
    except Exception as e:  # noqa: BLE001
        print("NOT CHECKED  6 live /designer page — Watchtower not reachable (%s). Leg 5 still covers the template." % type(e).__name__)
    else:
        n_cards = page.count('class="corpus-card')
        srcs = re.findall(r'<img src="(/api/thumb\?[^"]+)"', page)
        bad = []
        for s in srcs:
            try:
                r = urllib.request.urlopen(base + s.replace("&amp;", "&"), timeout=10)
                if r.headers.get_content_type() != "image/png" or r.read(8) != PNG:
                    bad.append(s)
            except Exception:  # noqa: BLE001
                bad.append(s)
        leg(n_cards > 0 and page.count('class="corpus-thumb') == n_cards and not bad
            and page.count("onclick=\"this.href=") == n_cards,
            "6 live /designer: every card has a tile, every tile is a real PNG, one nonce link per card",
            "%d cards, %d img tiles, %d bad%s" % (n_cards, len(srcs), len(bad), (": %s" % bad) if bad else ""))

    stale = [m for m in maps for d in CORPORA
             if os.path.isfile(os.path.join(d, m + ".bpmn")) and os.path.isfile(os.path.join(CACHE, m + ".png"))
             and os.path.getmtime(os.path.join(d, m + ".bpmn")) > os.path.getmtime(os.path.join(CACHE, m + ".png"))]
    print("INFO  %d stale tile(s)%s (refreshed by the next real serve-gallery.sh build)"
          % (len(stale), (": " + ", ".join(stale)) if stale else ""))

    print("\n%d failed leg(s)" % len(fails) if fails else "\nall legs passed")
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
