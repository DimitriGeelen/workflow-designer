# Operator job for tools/runme-launcher.sh (T-1055). DEFINITIONS ONLY.
JOB_TITLE="Remove the /tmp/org.chromium.Chromium.* dirs our load run left (they are not empty, so job 070 missed them)"
JOB_TASK="T-1247"
JOB_WHY="Job 070 removed only 24 dirs: it looked for EMPTY org.chromium.Chromium.* dirs, but each holds Chrome's
Singleton files (SingletonCookie, SingletonSocket, ...), as dimitri-mint-dev found. They count 1,321 such dirs from our
T-1246 load run, 2026-10-21 08:55-10:45 host time (CEST). This job removes a dir only if all of these hold:
its name is org.chromium.Chromium.*, you own it, its time is in 08:55-10:45 on 2026-10-21, everything inside is
named Singleton*, and no process is still listening on its SingletonSocket. The check shows how many match and how
many would be skipped before anything is removed. Other dirs, including the other ~330 outside the window, stay."

FROM_TS="2026-10-21 08:55"
TO_TS="2026-10-21 10:45"

preflight() {
    check "the window parses on this host" '[ -n "$(date -d "$FROM_TS" +%s)" ] && [ -n "$(date -d "$TO_TS" +%s)" ]'
    check "how many match (shown; any number is fine)" 'count_line'
}

steps() {
    step "Remove the matching /tmp/org.chromium.Chromium.* dirs (Singleton files only, in the window, not in use)" 'remove_all'
}

listening() { ss -xlp 2>/dev/null | awk '{print $5}' | grep -F '/tmp/org.chromium.Chromium.' ; }

only_singletons() { [ -z "$(find "$1" -mindepth 1 -maxdepth 1 ! -name 'Singleton*' -print -quit)" ]; }

candidates() {
    local a b d t
    a=$(date -d "$FROM_TS" +%s); b=$(date -d "$TO_TS" +%s)
    find /tmp -maxdepth 1 -type d -name 'org.chromium.Chromium.*' -user "$(id -u)" 2>/dev/null \
        | while read -r d; do
            t=$(stat -c %Y "$d"); [ "$t" -ge "$a" ] && [ "$t" -le "$b" ] || continue
            only_singletons "$d" && echo "$d"
          done
}

count_line() {   # one ss call, one candidate walk
    local socks c u
    socks=$(listening); c=$(candidates)
    u=$(printf '%s\n' "$c" | while read -r d; do [ -n "$d" ] && printf '%s\n' "$socks" | grep -qF -- "$d/" && echo x; done | wc -l)
    echo "$(printf '%s\n' "$c" | grep -c .) match, $u of them in use"
}

remove_all() {
    local d n=0 skipped=0 socks
    socks=$(listening)
    while read -r d; do
        [ -n "$d" ] || continue
        case "$d" in /tmp/org.chromium.Chromium.*) ;; *) echo "refusing $d"; continue ;; esac
        if printf '%s\n' "$socks" | grep -qF -- "$d/"; then skipped=$((skipped+1)); continue; fi
        rm -rf -- "$d" && n=$((n+1))
    done < <(candidates)
    echo "removed $n dir(s), skipped $skipped in use; $(candidates | wc -l) left that match"
}
