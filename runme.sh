#!/usr/bin/env bash
# =============================================================================
#  T-968 — LINK TO THE EVERGREEN DEPLOYMENT ON .132, THROUGH TERMLINK
#  Run with:   bash /opt/832-Workflow-designer/runme.sh
#  Dry run:    bash /opt/832-Workflow-designer/runme.sh --dry-run
# =============================================================================
#
#  WHAT THIS DOES: registers a TermLink hub profile for 192.168.10.132, heals its
#  credential using TermLink's own declared out-of-band anchor, and lists the
#  sessions so we can find the Evergreen agent by name. It does NOT dispatch
#  anything — that is the next step, once we know which session to talk to.
#
#  WHY NOT SSH. I suggested scp and the operator was right to refuse. TermLink
#  exists so cross-host work runs in the TARGET project's own session context,
#  under its own governance. Reaching into .132 over SSH from here routes around
#  the mechanism this framework is built on.
#
#  `fleet reauth --bootstrap-from ssh:<host>` is a different thing, and the
#  distinction is the point: it is TermLink's OWN declared trust anchor for
#  recovering a hub secret, documented in its help text, and the secret travels
#  host-to-host without passing through this agent, this transcript or any file
#  the agent reads. It is Tier-2 (single-use, logged), which is exactly why YOU
#  run it and not me.
#
#  THE AGENT DOES NOT RUN THIS. check-tier0.sh matches command TEXT, so a Tier-2
#  step inside a script is invisible to it — the harness only sees `bash
#  runme.sh` (OBS-449). Only --dry-run was exercised before handover.
#
#  NOTHING HERE PRINTS OR STORES A SECRET. The script never reads the value; it
#  names the anchor and lets termlink fetch it. If you see a hex secret in the
#  output, that is a bug — tell me.
# =============================================================================

if [ -z "${BASH_VERSION:-}" ]; then
    exec bash "$0" "$@"
fi

set -uo pipefail

PROJ="/opt/832-Workflow-designer"
cd "$PROJ" || { echo "FATAL: cannot cd to $PROJ"; exit 1; }

HUB_HOST="192.168.10.132"
HUB_ADDR="$HUB_HOST:9100"
PROFILE="evergreen"

TS="$(date -u +%Y%m%dT%H%M%SZ)"
LOG="$PROJ/runme-$TS.log"
if touch "$LOG" 2>/dev/null; then
    exec > >(tee -a "$LOG") 2>&1
    trap 'cp -f "$LOG" "$PROJ/runme-LATEST.log" 2>/dev/null || true' EXIT
else
    LOG="(none — $PROJ not writable by $(id -un))"
    echo "WARNING: cannot create a log file; output is on screen only."
    echo
fi

echo "=== T-968: link to Evergreen on $HUB_ADDR — $TS ==="
echo "log: $LOG"
echo

# TWO TRUST ANCHORS, and WHICH ONE is your decision, passed as an argument rather
# than guessed (G-007). Measured on the first dry run: non-interactive ssh to .132
# is refused from here, so `ssh:` needs key auth enabling purely for this — which is
# a bigger change than the job deserves.
#
#   bash runme.sh                      -> ssh anchor, needs BatchMode ssh to work
#   bash runme.sh /path/to/secret      -> file anchor: YOU fetch it, nothing to enable
#
# For the file route, on 192.168.10.132:
#     termlink hub export-secret
# then put that hex string in a root-only file on THIS host, e.g.
#     install -m600 /dev/null ~/.termlink/evergreen.secret
#     # paste the hex into it with your editor
# The agent never reads that file; it only passes its PATH to termlink.
DRY=0
ANCHOR=""
SECRET_FILE=""
for a in "$@"; do
    case "$a" in
        --dry-run) DRY=1 ;;
        /*) SECRET_FILE="$a" ;;
        *) echo "Ignoring unrecognised argument: $a" ;;
    esac
done
if [ -n "$SECRET_FILE" ]; then
    ANCHOR="file:$SECRET_FILE"
else
    ANCHOR="ssh:$HUB_HOST"
fi
[ "$DRY" -eq 1 ] && echo "*** DRY RUN — no profile written, no credential fetched ***" && echo
echo "trust anchor: $ANCHOR"
echo

# Snapshot so a refusal provably changes nothing.
HUBS="$HOME/.termlink/hubs.toml"
BEFORE_SUM="$(sha256sum "$HUBS" 2>/dev/null | cut -d' ' -f1 || echo absent)"

echo "--- preflight ---"
fail=0
chk() {
    if eval "$2" >/dev/null 2>&1; then echo "  ok    $1"; else echo "  FAIL  $1"; fail=1; fi
}
chk "termlink is installed" \
    "command -v termlink"
chk "$HUB_HOST answers at all (host is up)" \
    "ping -c1 -W2 $HUB_HOST"
chk "the hub is LISTENING on $HUB_ADDR (this was the blocker before)" \
    "timeout 4 bash -c 'cat < /dev/null > /dev/tcp/$HUB_HOST/9100'"
if [ -n "$SECRET_FILE" ]; then
    chk "the secret file you named exists and is root-only" \
        "test -f '$SECRET_FILE' && test \"\$(stat -c %a '$SECRET_FILE')\" = 600"
else
    chk "ssh to $HUB_HOST works non-interactively (the ssh anchor needs it)" \
        "ssh -o BatchMode=yes -o ConnectTimeout=5 $HUB_HOST true"
fi

if [ "$fail" -ne 0 ]; then
    echo
    echo "REFUSED by a preflight check. Nothing was written."
    echo
    echo "  hub not listening  ->  on $HUB_HOST run:  termlink hub start --tcp 0.0.0.0:9100"
    echo "  ssh refused        ->  the bootstrap anchor is 'ssh $HUB_HOST -- sudo cat ...'."
    echo "                         If you prefer not to enable that, fetch the secret"
    echo "                         yourself and tell me; I will switch the script to"
    echo "                         --bootstrap-from file:<path> instead."
    echo
    echo "Log: $LOG"
    exit 2
fi
echo "  all preflight checks passed"
echo

cat <<EOF
--- what will happen ---

  1. Register a hub profile named '$PROFILE' for $HUB_ADDR.
     (add is also an update, so re-running is safe.)

  2. TIER-2 STEP, and the reason this script exists rather than a bare command:
         termlink fleet reauth $PROFILE --bootstrap-from $ANCHOR
     This runs, on your behalf and host-to-host:
         ssh $HUB_HOST -- sudo cat /var/lib/termlink/hub.secret
     The secret is written into your termlink config. It is never read by the
     agent, never echoed here, and never committed. You may be prompted for sudo
     on $HUB_HOST.

  3. Verify with 'remote doctor', then list the sessions so we can find the
     Evergreen agent BY NAME before anything is sent to it.

  Nothing is dispatched to Evergreen by this script. Finding out who is there
  comes first.

EOF

if [ "$DRY" -eq 1 ]; then
    echo "DRY RUN — stopping before step 1."
    echo "hubs.toml unchanged (sha256 $BEFORE_SUM)"
    echo "Log: $LOG"
    exit 0
fi

printf '  proceed? [y/N] ' > /dev/tty
IFS= read -r yn < /dev/tty || yn=""
case "$yn" in y|Y) ;; *) echo; echo "ABORTED — nothing written. Log: $LOG"; exit 3 ;; esac
echo

echo "--- 1. registering profile '$PROFILE' ---"
termlink remote profile add "$PROFILE" "$HUB_ADDR" --bootstrap-from "$ANCHOR"
rc=$?
if [ "$rc" -ne 0 ]; then
    echo "REFUSED: profile registration failed (exit $rc). Log: $LOG"
    exit 4
fi

echo
echo "--- 2. healing the credential (Tier-2, via termlink's declared anchor) ---"
termlink fleet reauth "$PROFILE" --bootstrap-from "$ANCHOR"
rc=$?
if [ "$rc" -ne 0 ]; then
    echo
    echo "REFUSED: the credential heal failed (exit $rc)."
    echo "Common causes: sudo on $HUB_HOST needs a password, or the hub was"
    echo "restarted after the secret was cached. Read the message above."
    echo "Log: $LOG"
    exit 5
fi

echo
echo "--- 3. verifying, and finding out who is on that hub ---"
termlink remote doctor "$PROFILE"
echo
termlink remote list "$PROFILE"
rc=$?
echo

if [ "$rc" -eq 0 ]; then
    echo "DONE: the link is up. Send the agent the session list above and it will"
    echo "identify the Evergreen agent, then dispatch the corpus request INTO that"
    echo "session so their governance applies to their own work."
else
    echo "The profile is registered but listing sessions exited $rc — read above."
fi
echo
echo "Log:  $LOG"
echo "Copy: $PROJ/runme-LATEST.log"
exit "$rc"
