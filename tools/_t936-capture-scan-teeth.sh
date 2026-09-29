#!/usr/bin/env bash
# _t936-capture-scan-teeth.sh — does the stray-capture detector fire on what actually happened?
#
# FOUR OCCURRENCES, and the fourth is why this exists. Three were found by hand after six days
# (2026-09-23, 09-25, 09-28). The fourth — `re,io`, 7,962,628 bytes, 1431x915, 2026-09-29T19:35:38Z —
# was created BY THE AGENT during this session, ninety minutes before the detector found it, while the
# agent was writing the observation about the other three. A multi-line `python3 -c "` block beginning
# `import re,io` had its quoting broken; the shell ran ImageMagick's import(1); exit 0; the expected
# output appeared anyway and nobody looked.
#
# The detector found it on its first run. That is the argument for building it.
#
# WHY THE FIXTURE FILENAMES ARE THE REAL FILENAMES. `0`, `importlib.util`, `yaml,glob,sys`, `re,io` —
# no extension between them, and every one reads as a typo. A check keyed on `.ps`/`.eps` or on any
# name pattern would have missed all four. This is the same location-not-content defect measured twice
# elsewhere in this corpus today (C-001's research artifact, T-919; the ownership field, T-931), so the
# negative control here is a file whose NAME suggests nothing and whose CONTENT is a capture.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 90

TOOL="tools/_t936-stray-capture-scan.py"
[ -f "$TOOL" ] || { echo "SETUP BROKEN: no $TOOL"; exit 1; }

PASS=0; FAIL=0
ok() { if [ "$2" -eq 0 ]; then echo "  PASS  $1"; PASS=$((PASS+1)); else echo "  FAIL  $1"; [ -n "${3:-}" ] && echo "        $3"; FAIL=$((FAIL+1)); fi; }

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT INT TERM

# A minimal ImageMagick PostScript header, byte-identical in the fields the detector reads to the
# four real captures. Not a copy of one: a real capture is an image of somebody's screen and has no
# business in a fixture directory.
mkcapture() {  # $1 path  $2 width  $3 height
    { printf '%%!PS-Adobe-3.0\n%%%%Creator: (ImageMagick)\n%%%%Title: (%s)\n' "$(basename "$1")"
      printf '%%%%CreationDate: (2026-09-29T19:35:38+00:00)\n'
      printf '%%%%BoundingBox: -0 -0 %s %s\n%%%%HiResBoundingBox: 0 0 %s %s\n' "$2" "$3" "$2" "$3"
      printf '%%%%DocumentData: Clean7Bit\n%%%%LanguageLevel: 1\n%%%%EndComments\n'
      head -c 4096 /dev/zero | tr '\0' 'X'
    } > "$1"
}

count() { python3 "$TOOL" --root "$TMP" --json 2>/dev/null | python3 -c 'import sys,json; print(len(json.load(sys.stdin)))'; }
canvas_of() { python3 "$TOOL" --root "$TMP" --json 2>/dev/null | python3 -c 'import sys,json; r=json.load(sys.stdin); print(r[0]["canvas"] if r else "-")'; }

echo "=== T-936 stray capture detector ==="
echo

# ── POSITIVE: the four real shapes ────────────────────────────────────────────────────────────
echo "FIRES on what actually happened — real filenames, no extensions"
for n in '0' 'importlib.util' 'yaml,glob,sys' 're,io'; do
    rm -f "$TMP"/* 2>/dev/null
    mkcapture "$TMP/$n" 3440 1383
    ok "a capture named '$n' is found" "$([ "$(count)" -eq 1 ] && echo 0 || echo 1)" "found $(count)"
done
echo

# ── THE CANVAS, which is what tells the operator how exposed they are ─────────────────────────
echo "REPORTS the canvas, so exposure is judgeable without opening the image"
rm -f "$TMP"/* 2>/dev/null; mkcapture "$TMP/desktop" 3440 1383
ok "a full-desktop capture reports 3440x1383" "$([ "$(canvas_of)" = "3440x1383" ] && echo 0 || echo 1)" "got $(canvas_of)"
rm -f "$TMP"/* 2>/dev/null; mkcapture "$TMP/window" 1431 915
ok "a single-window capture reports 1431x915" "$([ "$(canvas_of)" = "1431x915" ] && echo 0 || echo 1)" "got $(canvas_of)"
echo

# ── NEGATIVE: it must not fire on ordinary files, or the WARN is noise ────────────────────────
echo "DOES NOT FIRE on files that are not captures"
rm -f "$TMP"/* 2>/dev/null
printf 'id: T-1\nname: an ordinary yaml file\n' > "$TMP/task.yaml"
printf '#!/bin/sh\necho hello\n' > "$TMP/script.sh"
head -c 9000 /dev/urandom > "$TMP/binary.bin"
ok "yaml, shell and random binary -> no finding" "$([ "$(count)" -eq 0 ] && echo 0 || echo 1)" "found $(count)"

# PostScript that is a DOCUMENT, not a capture: right magic, wrong creator.
printf '%%!PS-Adobe-3.0\n%%%%Creator: (dvips)\n%%%%Title: (a real document)\n%%%%EndComments\n' > "$TMP/paper.ps"
ok "PostScript from a non-capture tool (dvips) -> no finding" \
   "$([ "$(count)" -eq 0 ] && echo 0 || echo 1)" \
   "found $(count) — matching on %!PS-Adobe alone would flag every legitimate .ps in the tree"
echo

# ── CONTROLS ─────────────────────────────────────────────────────────────────────────────────
echo "CONTROLS"
# The name must be irrelevant. Same bytes, innocuous name: still found.
rm -f "$TMP"/* 2>/dev/null; mkcapture "$TMP/notes.txt" 1431 915
ok "content decides, not the name: a capture called 'notes.txt' is still found" \
   "$([ "$(count)" -eq 1 ] && echo 0 || echo 1)" "found $(count)"

# And the inverse: an innocuous file named like a capture is NOT found.
rm -f "$TMP"/* 2>/dev/null; printf 'just text\n' > "$TMP/yaml,glob,sys"
ok "name decides nothing: an ordinary file called 'yaml,glob,sys' is NOT found" \
   "$([ "$(count)" -eq 0 ] && echo 0 || echo 1)" "found $(count)"

# The privacy boundary is in the code, not in a comment.
ok "the read is capped (HEADER_BYTES), so the raster is never loaded" \
   "$(grep -q 'HEADER_BYTES = ' "$TOOL" && grep -q 'fh.read(HEADER_BYTES)' "$TOOL" && echo 0 || echo 1)" \
   "an uncapped read would pull megabytes of the operator's screen into memory to find a bounding box"

# Empty candidate set must not read as a clean bill of health (T-3105).
rm -f "$TMP"/* 2>/dev/null
ok "an empty directory exits 0 with an explicit 'no findings' line, not silence" \
   "$(python3 "$TOOL" --root "$TMP" 2>&1 | grep -q 'no stray screen captures found' && echo 0 || echo 1)"
echo

echo "=== SUMMARY ==="
echo "PASS: $PASS"
echo "FAIL: $FAIL"
[ "$FAIL" -eq 0 ] || exit 1
exit 0
