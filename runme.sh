#!/usr/bin/env bash
# =============================================================================
#  T-962 — LOOK AT THE VALIDATOR FINDINGS IN THE DESIGNER
#  Run with:   bash /opt/832-Workflow-designer/runme.sh
#  Dry run:    bash /opt/832-Workflow-designer/runme.sh --dry-run
#  Other port: bash /opt/832-Workflow-designer/runme.sh 8900
# =============================================================================
#
#  WHAT THIS DOES: rebuilds the gallery serve root from the CURRENT working copy
#  and serves it, so you can open the designer, press "✓ Check", and see the
#  findings on the map. Runs in the foreground; Ctrl-C stops it.
#
#  WHY NOT YOUR USUAL URL. http://192.168.10.107:3013/designer/app does NOT serve
#  src/. It serves a pinned, sha256-verified vendored bundle named in
#  .agentic-framework/policy/designer-pin.yaml. Two separate reasons it cannot show
#  this work:
#    1. The pin asks for v0.11.0 and vendor/designer/ holds 0.12.0 and 0.8.0, so
#       that URL is currently returning the "not yet synced" PLACEHOLDER page.
#       Pre-existing, nothing to do with this change, and filed separately.
#    2. Even with a correct pin, src/ is 0.14.0 and getting it there is a
#       release → sha256-verify → pin → serve cycle, not a page reload. That
#       gate is the design working, not an obstacle to route around.
#
#  THE AGENT DOES NOT RUN THIS. check-tier0.sh matches command TEXT, so anything
#  consequential inside a script is invisible to it — the harness only sees
#  `bash runme.sh` (OBS-449). Only --dry-run was exercised before handover.
#
#  PORT: defaults to 8834, the gallery's own port. T-253 retired :8834 behind ufw
#  and the agent must not change firewall rules, so from THIS machine use
#  localhost; from another device you would need a port you have opened yourself.
#  Pass one as the first argument to override.
# =============================================================================
# ── T-963: START UNDER BASH, OR RE-EXEC INTO IT ──────────────────────────────
# MUST be the first executable line, before `set -o pipefail` and before the log
# is opened. Measured 2026-10-01: invoked as `sh runme.sh` this script died with
#     runme.sh: 33: set: Illegal option -o pipefail
# at the `set` line — which is BEFORE the log exists, so it produced no log, no
# trace, and nothing for a watcher to see. The operator ran it twice and both
# times the only evidence was absence. A handover script whose failure mode is
# "no output anywhere" is worse than one that fails loudly.
#
# `sh` is dash on this host, and neither `-o pipefail` nor the `>(tee …)` process
# substitution below is POSIX. Re-exec rather than drop the features: pipefail is
# load-bearing in the rebuild step, and the log is the whole point.
if [ -z "${BASH_VERSION:-}" ]; then
    exec bash "$0" "$@"
fi

set -uo pipefail

PROJ="/opt/832-Workflow-designer"
cd "$PROJ" || { echo "FATAL: cannot cd to $PROJ"; exit 1; }

TS="$(date -u +%Y%m%dT%H%M%SZ)"
LOG="$PROJ/runme-$TS.log"
# Prove the log can actually be written BEFORE redirecting into it. If the script
# is run by a user without write access here, the redirect would otherwise swallow
# every subsequent message and leave the same no-output-anywhere signature.
if touch "$LOG" 2>/dev/null; then
    exec > >(tee -a "$LOG") 2>&1
    trap 'cp -f "$LOG" "$PROJ/runme-LATEST.log" 2>/dev/null || true' EXIT
else
    LOG="(none — $PROJ is not writable by $(id -un))"
    echo "WARNING: cannot create a log file in $PROJ as $(id -un)."
    echo "         Continuing WITHOUT a log; everything below is on screen only,"
    echo "         so copy it if something goes wrong."
    echo
fi

echo "=== T-962: serve the designer with validator findings — $TS ==="
echo "log: $LOG"
echo

DRY=0
PORT=8834
for a in "$@"; do
    case "$a" in
        --dry-run) DRY=1 ;;
        ''|*[!0-9]*) echo "Ignoring unrecognised argument: $a" ;;
        *) PORT="$a" ;;
    esac
done
[ "$DRY" -eq 1 ] && echo "*** DRY RUN — nothing will be built, no port will be bound ***" && echo

# ---------------------------------------------------------------------------
# PREFLIGHT — each check says what it proves. A refusal changes nothing.
# ---------------------------------------------------------------------------
echo "--- preflight ---"
fail=0
chk() {
    if eval "$2" >/dev/null 2>&1; then echo "  ok    $1"; else echo "  FAIL  $1"; fail=1; fi
}
chk "the working copy HAS the new Check feature (so there is something to look at)" \
    "grep -q 'async function validateCurrentWorkflow' '$PROJ/src/aef-workflow-designer.html'"
chk "the findings drawer markup is present" \
    "grep -q 'id=\"findings-drawer\"' '$PROJ/src/aef-workflow-designer.html'"
chk "the gallery builder exists" \
    "test -f '$PROJ/tools/serve-gallery.sh'"
chk "port $PORT is free (nothing else is bound to it)" \
    "! ss -tlnH \"sport = :$PORT\" 2>/dev/null | grep -q LISTEN"
# T-965: a second run must not race a server already serving this docroot. Name the
# pid rather than making the operator hunt for it.
if ss -tlnH "sport = :$PORT" 2>/dev/null | grep -q LISTEN; then
    _pid="$(ss -tlnpH "sport = :$PORT" 2>/dev/null | grep -oE 'pid=[0-9]+' | head -1 | cut -d= -f2)"
    echo "        ^ already serving, pid ${_pid:-unknown}. Stop it with:  kill ${_pid:-<pid>}"
    echo "          or run this script on another port:  bash $PROJ/runme.sh 8900"
fi

if [ "$fail" -ne 0 ]; then
    echo
    echo "REFUSED by a preflight check. Nothing was built; the tree is as it was."
    echo
    echo "If the PORT check failed, something is already listening there. Pick another:"
    echo "  bash $PROJ/runme.sh 8900"
    echo
    echo "Log: $LOG"
    exit 2
fi
echo "  all preflight checks passed"
echo

cat <<'WHAT'
--- what to do once it is up ---

  1. Open the URL printed below.
  2. Open any map (📂 Open project…), or just use the starter map that loads.
  3. Press  ✓ Check  in the toolbar.

  EXPECTED on a sound map:
     the dock at the bottom says   "checked · no findings"
     — NOT a blank panel. "Not yet checked", "no findings" and "could not
     check" are three different lines, on purpose.

  TO SEE IT FIND SOMETHING, drag a step clear of every lane band and press
  ✓ Check again. You should get TWO rows:
     W-XML-LANE-GEOMETRY  and  W-XML-LANE-CAPACITY
  both labelled "not on the map".

  CORRECTED FROM THE LAST VERSION OF THIS SCRIPT, which told you that drag
  would give E-XML-NODE-UNASSIGNED. It cannot. The designer reassigns a
  step's lane only while it is OVER a lane, so a step dragged into empty
  space keeps its last valid lane and is never orphaned — good behaviour I
  had not read before telling you to rely on it. That rule comes from
  IMPORTED maps, not from drawing. Sorry for the wasted attempt.

  WHY THOSE TWO SAY "not on the map": they anchor to a LANE, not to a step,
  and only steps can carry a marker today. That gap is OBS-465 and is the
  next thing worth building — it is also, I think, the honest answer to
  whether this feature is finished.

  The server runs in the background; the stop command is printed at the end.

WHAT

if [ "$DRY" -eq 1 ]; then
    echo "DRY RUN — would rebuild the serve root and serve it on port $PORT. Stopping here."
    echo "Log: $LOG"
    exit 0
fi

echo "--- rebuilding the serve root from the current working copy ---"
bash "$PROJ/tools/serve-gallery.sh" "$PORT" --build-only
rc=$?
if [ "$rc" -ne 0 ]; then
    echo
    echo "REFUSED: the serve-root rebuild failed (exit $rc). Nothing is being served."
    echo "Log: $LOG"
    exit 3
fi

# ---------------------------------------------------------------------------
# SERVE — detached, against the docroot just built. T-965.
#
# The previous version called serve-gallery.sh a SECOND time here, and that was
# three bugs in one line:
#   1. serve-gallery.sh does `rm -rf "$OUT"` on EVERY invocation — it is a full
#      rebuild by design (its own header, T-350/G-015). So the serve step DELETED
#      the docroot the check above had just verified, making that check assert
#      nothing about what you actually get.
#   2. It blocks forever. "Ctrl-C stops it" was in the header, and that is not the
#      same as the terminal coming back. The operator read a script that never
#      returns and prints nothing further as hung, and cancelled it. They were
#      right to: a handover script that owns your terminal indefinitely is not a
#      handover.
#   3. The URL was printed BEFORE that rebuild, so for a moment the page it told
#      you to open did not exist.
#
# Now: build once (above), start gallery-serve.py directly, wait until it really
# answers, verify the FEATURE OVER HTTP rather than by grepping a file that is
# about to be deleted, print the URL, and return the terminal.
# ---------------------------------------------------------------------------
SERVED_LOG="$PROJ/build/gallery-serve-$TS.log"
nohup python3 "$PROJ/tools/gallery-serve.py" "$PORT" \
      --docroot "$PROJ/build/gallery" --repo "$PROJ" --bind 0.0.0.0 \
      > "$SERVED_LOG" 2>&1 &
SRV_PID=$!

# Wait for it to actually answer. Printing a URL before the socket is live is
# how the 404 window above happened.
ready=0
for _ in $(seq 1 60); do
    if curl -sf -o /dev/null "http://127.0.0.1:$PORT/api/health" 2>/dev/null; then ready=1; break; fi
    sleep 0.25
done
if [ "$ready" -ne 1 ]; then
    echo "REFUSED: the server did not come up on port $PORT within 15s."
    kill "$SRV_PID" 2>/dev/null
    echo "Its own log: $SERVED_LOG"
    echo "Log: $LOG"
    exit 5
fi

# THE CHECK THAT MATTERS, made against what is actually being served. The earlier
# grep-the-file-on-disk version could not have caught a serve step that shipped the
# wrong page, because the serve step ran afterwards and rebuilt the directory.
#
# T-966: DOWNLOAD TO A FILE, THEN GREP THE FILE. The first version of this line was
#     curl -sf ".../designer.html" | grep -q '...'
# under `set -o pipefail`, and it REFUSED on a page that was perfectly fine. grep -q
# matches and exits, closing the pipe; curl cannot finish writing a 1,063,221-byte
# document into a 64KB buffer and dies; pipefail propagates its status; the `!`
# turns that into a refusal. Measured on a live server: piped rc=23, file rc=0,
# deterministic at this size rather than racy.
#
# CLAUDE.md calls the file form "THE DEFAULT" and gives this exact curl example,
# citing a measurement on a 146KB page. I wrote the pipe anyway, while fixing a
# different defect in this same script. Keeping the whole story here because the
# rule plainly is not enough on its own.
PAGE_TMP="$PROJ/build/.runme-served-$TS.html"
curl -sf "http://127.0.0.1:$PORT/designer.html" -o "$PAGE_TMP" 2>/dev/null
if ! grep -q 'async function validateCurrentWorkflow' "$PAGE_TMP" 2>/dev/null; then
    echo "REFUSED: the page being SERVED does not contain the Check feature."
    echo "Stopping the server rather than sending you to look for a missing button."
    kill "$SRV_PID" 2>/dev/null
    rm -f "$PAGE_TMP"
    echo "Tell the agent — this is its bug, not yours."
    echo "Log: $LOG"
    exit 4
fi
# Per-run filename and removed on success, so a stale page from an earlier run can
# never satisfy a later check.
rm -f "$PAGE_TMP"

echo "$SRV_PID" > "$PROJ/build/gallery-serve.pid"
echo "  ok    the SERVED page carries the Check feature (verified over HTTP)"
echo
echo "============================================================"
echo "  OPEN THIS:   http://localhost:$PORT/designer.html"
echo
echo "  The server runs in the BACKGROUND — this script is done and your"
echo "  terminal is yours again. Stop it when you have finished looking:"
echo "      kill $SRV_PID"
echo "  (pid also in build/gallery-serve.pid; its own log is $SERVED_LOG)"
echo "============================================================"
echo
echo "Log:  $LOG"
echo "Copy: $PROJ/runme-LATEST.log"
exit 0
