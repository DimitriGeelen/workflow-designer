#!/usr/bin/env bash
# serve-gallery.sh — assemble and serve the corpus gallery (T-041).
#
# Builds a self-contained serve root (gallery index + designer + rendered maps)
# so an operator on the LAN can click through every corpus map without a file
# picker. Deliberately does NOT serve the repo root (keeps .git/.context off
# the wire).
#
# Usage: tools/serve-gallery.sh [PORT]   (default 8834)
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PORT="${1:-8834}"
OUT="${GALLERY_DIR:-$ROOT/build/gallery}"

rm -rf "$OUT"
mkdir -p "$OUT/rendered"
cp "$ROOT/src/aef-workflow-designer.html" "$OUT/designer.html"
cp "$ROOT"/examples/aef-processes/rendered/*.bpmn "$OUT/rendered/"

{
  cat <<'HTML'
<!doctype html><html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>AEF Workflow Corpus</title>
<style>
 body{font-family:system-ui,sans-serif;background:#0f1115;color:#d7dae0;margin:2rem auto;max-width:720px;padding:0 1rem}
 h1{font-size:1.3rem}
 a{color:#7ab8ff;text-decoration:none} a:hover{text-decoration:underline}
 li{margin:.35rem 0}
 .n{color:#6b7280;font-size:.85em}
</style></head><body>
<h1>AEF Workflow Corpus &mdash; rendered maps</h1>
<p class="n">Generated from examples/aef-processes/*.workflow.yaml via tools/yaml-to-bpmn.py.
Click a map to open it in the designer (editable; changes stay in your browser).</p>
<ol>
HTML
  for f in "$OUT"/rendered/*.bpmn; do
    b=$(basename "$f" .bpmn)
    printf '<li><a href="designer.html?load=rendered/%s.bpmn">%s</a></li>\n' "$b" "$b"
  done
  cat <<'HTML'
</ol>
<p class="n">Or open <a href="designer.html">the designer empty</a> and use Load for a local file.</p>
</body></html>
HTML
} > "$OUT/index.html"

COUNT=$(ls "$OUT"/rendered/*.bpmn | wc -l)
IP=$(hostname -I 2>/dev/null | awk '{print $1}')
echo "Gallery root: $OUT ($COUNT maps)"
echo "Local:  http://localhost:$PORT/"
echo "LAN:    http://${IP:-localhost}:$PORT/"
# Write-capable sidecar (T-129/B2): serves the same gallery + /api/* so the editor
# can Save into the repo with versioning. Falls back to the static server if the
# sidecar script is missing (keeps the gallery working in a minimal checkout).
if [ -f "$ROOT/tools/gallery-serve.py" ]; then
  exec python3 "$ROOT/tools/gallery-serve.py" "$PORT" --docroot "$OUT" --repo "$ROOT" --bind 0.0.0.0
else
  exec python3 -m http.server "$PORT" --directory "$OUT" --bind 0.0.0.0
fi
