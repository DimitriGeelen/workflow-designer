#!/usr/bin/env bash
# serve-gallery.sh — assemble and serve the corpus gallery (T-041).
#
# Builds a self-contained serve root (gallery index + designer + rendered maps)
# so an operator on the LAN can click through every corpus map without a file
# picker. Deliberately does NOT serve the repo root (keeps .git/.context off
# the wire).
#
# Usage: tools/serve-gallery.sh [PORT] [--build-only]   (default port 8834)
#
# --build-only assembles the serve root and stops there — no port is bound, no
# server is started. Added by T-350 for G-015: every path that produced the serve
# root also required binding a port, and the default :8834 is retired behind ufw
# (T-253), which the agent must not change. That coupled "refresh the serve root"
# to "start a server". It is a FULL rebuild, deliberately: copying designer.html
# alone would satisfy the diff-based gates while leaving rendered/ stale — a green
# that asserts less than it says, which is the defect G-015 is about.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

BUILD_ONLY=0
PORT=""
for arg in "$@"; do
  case "$arg" in
    --build-only) BUILD_ONLY=1 ;;
    -h|--help)
      # Print the header comment block — bounded by the first non-comment line,
      # not by a pinned line range that silently truncates when the block grows.
      awk 'NR==1{next} /^#/{sub(/^# ?/,""); print; next} {exit}' "$0"
      exit 0 ;;
    -*)
      # Never fall through to the PORT slot: a typo like `--build-onlyy` would
      # otherwise become PORT and surface as a baffling bind failure.
      echo "serve-gallery: unknown option: $arg" >&2
      echo "  usage: tools/serve-gallery.sh [PORT] [--build-only]" >&2
      exit 2 ;;
    *)
      [ -n "$PORT" ] && { echo "serve-gallery: unexpected extra argument: $arg" >&2; exit 2; }
      PORT="$arg" ;;
  esac
done
PORT="${PORT:-8834}"

OUT="${GALLERY_DIR:-$ROOT/build/gallery}"

# The recursive delete below takes a caller-supplied path (GALLERY_DIR). Cheap guard
# against the values that turn a rebuild into a catastrophe. Not hypothetical: T-350
# makes the build path the routinely run one, and T-350's own teeth harness deleted this
# repository by feeding an unguarded copy of this script GALLERY_DIR=$ROOT.
case "${OUT%/}" in
  ""|"/"|"$ROOT")
    echo "serve-gallery: FATAL — refusing to recursively delete the serve root: GALLERY_DIR resolves to '$OUT'" >&2
    echo "  (empty, '/' or the repo root are refused; nothing was deleted)" >&2
    exit 2 ;;
esac

rm -rf "$OUT"
mkdir -p "$OUT/rendered"
cp "$ROOT/src/aef-workflow-designer.html" "$OUT/designer.html"
cp "$ROOT"/examples/aef-processes/rendered/*.bpmn "$OUT/rendered/"
# Second-tenant corpus (T-283/T-284): include app-flavored maps when present.
# Guarded glob — an absent/empty dir must not fail the build under `set -e`.
for f in "$ROOT"/examples/app-processes/rendered/*.bpmn; do
  [ -e "$f" ] && cp "$f" "$OUT/rendered/"
done

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
<p class="n">Generated from examples/aef-processes/*.workflow.yaml and examples/app-processes/*.workflow.yaml
(second-tenant corpus) via tools/yaml-to-bpmn.py.
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
echo "Gallery root: $OUT ($COUNT maps)"

if [ "$BUILD_ONLY" = 1 ]; then
  # Say plainly that nothing is being served. The whole point of the T-231 probe
  # below is that a built artifact is NOT a serving process (PL-046); a build-only
  # run that printed URLs would assert exactly the thing it did not do.
  echo "serve-gallery: BUILD-ONLY — serve root assembled; NO port bound, NO server started." >&2
  echo "  To serve it:  tools/serve-gallery.sh $PORT" >&2
  exit 0
fi

IP=$(hostname -I 2>/dev/null | awk '{print $1}')
echo "Local:  http://localhost:$PORT/"
echo "LAN:    http://${IP:-localhost}:$PORT/"
# ── committed!=serving prevention (T-231) ──────────────────────────────────────
# A stale server still holding $PORT makes the new bind fail; under `nohup ... &`
# that death is invisible and the OLD process keeps serving stale code (hit twice:
# rail offset 137 pre-S1 server, S4a claim). So: clean-stop any listener on $PORT
# BEFORE binding, and refuse to start a shadow if the port stays held.

# Space-separated PIDs listening on TCP $1 (own-user procs; no privilege needed).
# Always exits 0 (|| true) so a no-listener grep-miss doesn't trip `set -e`.
listeners_on_port() {
  { ss -ltnpH "sport = :$1" 2>/dev/null \
      | grep -oE 'pid=[0-9]+' | cut -d= -f2 | sort -u | tr '\n' ' '; } || true
}

held="$(listeners_on_port "$PORT")"
if [ -n "${held// /}" ]; then
  echo "serve-gallery: port $PORT already held by PID(s): ${held% } — clean-stopping before rebind" >&2
  # gallery-serve.py's HTTPServer handles KeyboardInterrupt (SIGINT) but ignores
  # SIGTERM; send TERM once (for other server kinds), then INT — never a silent -9.
  for attempt in 1 2 3; do
    still="$(listeners_on_port "$PORT")"
    [ -z "${still// /}" ] && break
    sig=INT; [ "$attempt" = 1 ] && sig=TERM
    for pid in $still; do kill -"$sig" "$pid" 2>/dev/null || true; done
    for _ in $(seq 1 20); do
      [ -z "$(listeners_on_port "$PORT" | tr -d ' ')" ] && break
      sleep 0.1
    done
  done
  still="$(listeners_on_port "$PORT")"
  if [ -n "${still// /}" ]; then
    echo "serve-gallery: FATAL — port $PORT still held by PID(s): ${still% } after TERM+INT;" >&2
    echo "  refusing to start a second, shadowed server (it would serve stale code)." >&2
    echo "  Stop it manually then re-run:  kill -INT ${still% }" >&2
    exit 1
  fi
  echo "serve-gallery: port $PORT released." >&2
fi

# Write-capable sidecar (T-129/B2): serves the same gallery + /api/* so the editor
# can Save into the repo with versioning. Falls back to the static server if the
# sidecar script is missing (keeps the gallery working in a minimal checkout).
if [ -f "$ROOT/tools/gallery-serve.py" ]; then
  python3 "$ROOT/tools/gallery-serve.py" "$PORT" --docroot "$OUT" --repo "$ROOT" --bind 0.0.0.0 &
  SRV=$!; PROBE_PATH="/api/health"
else
  python3 -m http.server "$PORT" --directory "$OUT" --bind 0.0.0.0 &
  SRV=$!; PROBE_PATH="/"
fi

# Forward stop signals to the child so the NEXT invocation's clean-stop works and a
# Ctrl-C / nohup-kill cleanly ends the server instead of orphaning it.
trap 'kill -INT "$SRV" 2>/dev/null || true' INT TERM

# ── post-deploy BEHAVIOR probe (T-231) ─────────────────────────────────────────
# Assert the RUNNING process actually answers before reporting success — do NOT
# confuse a committed source file with a serving process (PL-046). If the server
# dies (e.g. a failed bind we missed), stop waiting and fail loud.
probe_ok=0
for _ in $(seq 1 100); do
  if curl -sf "http://127.0.0.1:$PORT$PROBE_PATH" >/dev/null 2>&1; then probe_ok=1; break; fi
  kill -0 "$SRV" 2>/dev/null || break     # server exited — stop waiting
  sleep 0.1
done
if [ "$probe_ok" != 1 ]; then
  echo "serve-gallery: FATAL — server on :$PORT did not answer $PROBE_PATH (PID $SRV); deploy failed" >&2
  kill -INT "$SRV" 2>/dev/null || true
  wait "$SRV" 2>/dev/null || true
  exit 1
fi
started="$(ps -o lstart= -p "$SRV" 2>/dev/null | sed 's/^ *//')"
echo "serve-gallery: LIVE on :$PORT (PID $SRV, started ${started:-?}) — $PROBE_PATH OK" >&2

# Block on the server like the old `exec` did (nohup keeps this parent alive).
wait "$SRV"
