# Operator job for tools/runme-launcher.sh (T-1055). DEFINITIONS ONLY.
JOB_TITLE="Remove the empty /tmp/org.chromium.Chromium.* dirs from our load run's window (job 069 step 2 missed them)"
JOB_TASK="T-1247"
JOB_WHY="Job 069 removed 547 nodecuts-chrome-* dirs, but its step 2 removed no Chromium dirs: it worked out its time
window from the nodecuts dirs, which step 1 had just deleted (the agent's mistake). This job uses the fixed window
dimitri-mint-dev reported, 2026-10-21 09:03-10:38 host time, plus 5 minutes either side. It removes only EMPTY
org.chromium.Chromium.* dirs owned by you, in that window, that no running process names. The check prints how many
match before anything is removed."

FROM_TS="2026-10-21 08:58"
TO_TS="2026-10-21 10:43"

preflight() {
    check "the window parses on this host" '[ -n "$(date -d "$FROM_TS" +%s)" ] && [ -n "$(date -d "$TO_TS" +%s)" ]'
    check "count of empty Chromium dirs in the window (shown, any number is fine)" 'echo "$(candidates | wc -l) match"'
}

steps() {
    step "Remove the empty /tmp/org.chromium.Chromium.* dirs from 08:58-10:43 (not in use)" 'remove_all'
}

candidates() {
    local a b d t
    a=$(date -d "$FROM_TS" +%s); b=$(date -d "$TO_TS" +%s)
    find /tmp -maxdepth 1 -type d -name 'org.chromium.Chromium.*' -empty -user "$(id -u)" 2>/dev/null \
        | while read -r d; do t=$(stat -c %Y "$d"); [ "$t" -ge "$a" ] && [ "$t" -le "$b" ] && echo "$d"; done
}

remove_all() {
    local d n=0 skipped=0
    while read -r d; do
        [ -n "$d" ] || continue
        case "$d" in /tmp/org.chromium.Chromium.*) ;; *) echo "refusing $d"; continue ;; esac
        if pgrep -f -- "$d" >/dev/null 2>&1; then skipped=$((skipped+1)); continue; fi
        rmdir -- "$d" 2>/dev/null && n=$((n+1))
    done < <(candidates)
    echo "removed $n empty dir(s), skipped $skipped in use; $(candidates | wc -l) left in the window"
}
