# Operator job for tools/runme-launcher.sh. DEFINITIONS ONLY: the launcher refuses a job that runs
# anything when loaded. Steps run from the project root, each after the operator's y/N.
JOB_TITLE="Make the bpmn-fetch-832 file receiver permanent (systemd, restarts itself)"
JOB_TASK="T-1084"
JOB_WHY="Peers (aef-greenfield-test) send files to 832 at the TermLink session bpmn-fetch-832. It ran
only inside a Claude session, so it died with it: iterations 2-8 and the T-172 designer requests
never arrived (T-1083). This installs deploy/systemd/termlink-bpmn-fetch-832.service, a copy of the
CashWeb receiver's pattern: event-only (no shell for peers), Restart=always. Changes /etc/systemd/system
and enables one service; nothing else. Undo: systemctl disable --now termlink-bpmn-fetch-832 && rm
/etc/systemd/system/termlink-bpmn-fetch-832.service && systemctl daemon-reload."

UNIT=termlink-bpmn-fetch-832.service
SRC=deploy/systemd/$UNIT
DST=/etc/systemd/system/$UNIT

preflight() {
    check "on bleeding-edge" '[ "$(git rev-parse --abbrev-ref HEAD)" = bleeding-edge ]'
    check "unit file committed as-is" 'git ls-files --error-unmatch "$SRC" >/dev/null && git diff --quiet -- "$SRC"'
    check "unit file passes systemd-analyze verify" 'systemd-analyze verify "$SRC"'
    check "TermLink hub is running" 'systemctl is-active --quiet termlink-hub.service'
    check "no other bpmn-fetch-832 session on the hub (two would split deliveries)" '! timeout 20 termlink list 2>/dev/null | grep -qw bpmn-fetch-832'
    check "service not installed yet, or installed from this same file" '[ ! -e "$DST" ] || cmp -s "$SRC" "$DST"'
}

steps() {
    step "Install the unit file to $DST and reload systemd" 'install -m 0644 "$SRC" "$DST" && systemctl daemon-reload'
    step "Enable and start $UNIT (starts now and at every boot)" 'systemctl enable --now "$UNIT"'
    step "Check: the service is active and bpmn-fetch-832 is on the hub as respawn=systemd" 'wait_listed'
}

wait_listed() {
    local i
    for i in $(seq 1 20); do
        if systemctl is-active --quiet "$UNIT" \
           && timeout 20 termlink list 2>/dev/null | grep -w bpmn-fetch-832 | grep -q respawn=systemd; then
            timeout 20 termlink list 2>/dev/null | grep -w bpmn-fetch-832
            return 0
        fi
        sleep 1
    done
    echo "bpmn-fetch-832 not listed after 20 s:"
    systemctl status "$UNIT" --no-pager -n 15
    return 1
}
