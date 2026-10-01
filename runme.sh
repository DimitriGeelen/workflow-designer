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

  TO SEE IT FIND SOMETHING, drag a step so it sits BELOW every lane band,
  then press ✓ Check again. You should get:
     a red ✖ on that step, and a row reading E-XML-NODE-UNASSIGNED
     "...is in no lane, so it has no authority-of-record ... an owner
      cannot be derived and must not be invented"
  That is the same defect class as the AEF map you screenshotted in July.

  THE ONE THING I WANT YOUR EYE ON: a step flagged this way often ALSO
  carries the older "⚠ no authority" label. Two marks, closely related
  conditions. Tell me whether to leave both, hide mine when the older one
  is showing, or merge them. That is taste, and it is yours.

  Ctrl-C stops the server when you are done.

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

# Assert the built copy actually carries the feature. A rebuild that silently
# produced the old file would otherwise send you looking for a button that is
# not there, and you would reasonably conclude the work was broken.
if ! grep -q 'async function validateCurrentWorkflow' "$PROJ/build/gallery/designer.html" 2>/dev/null; then
    echo
    echo "REFUSED: the rebuilt serve root does NOT contain the Check feature."
    echo "That means serve-gallery.sh copied something other than src/, and serving"
    echo "it would show you the wrong page. Tell the agent — this is its bug, not yours."
    echo "Log: $LOG"
    exit 4
fi
echo "  ok    build/gallery/designer.html carries the Check feature"
echo

echo "============================================================"
echo "  OPEN THIS:   http://localhost:$PORT/designer.html"
echo "  (from another device you need a port you have opened; :8834 is"
echo "   behind ufw by T-253 and the agent must not change that)"
echo "============================================================"
echo
echo "--- serving (Ctrl-C to stop) ---"
bash "$PROJ/tools/serve-gallery.sh" "$PORT"
rc=$?
echo
echo "Server stopped (exit $rc)."
echo "Log:  $LOG"
echo "Copy: $PROJ/runme-LATEST.log"
exit "$rc"
