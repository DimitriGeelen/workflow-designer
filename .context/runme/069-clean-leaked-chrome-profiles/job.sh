# Operator job for tools/runme-launcher.sh (T-1055). DEFINITIONS ONLY.
JOB_TITLE="Remove the Chrome profile dirs our T-1246 load run leaked into /tmp"
JOB_TASK="T-1247"
JOB_WHY="dimitri-mint-dev found 548 /tmp/nodecuts-chrome-* dirs (1.9 GB) and about 1,011 empty
org.chromium.Chromium.* dirs, made on 2026-10-21 while our T-1246 load run looped tools/_node-cuts-cdp.mjs.
They slow down file managers on this host. The agent does not act outside the project, so this is your job.
Step 1 removes the nodecuts-chrome-* dirs. Step 2 removes only EMPTY org.chromium.Chromium.* dirs whose time
falls inside the window of the nodecuts dirs themselves (first to last, plus 5 minutes either side).
Both skip any dir a running process still names on its command line. Each step prints what it removed and
the space it freed. The fix, so harnesses clean up after a kill, is T-1247's build."

preflight() {
    check "there are nodecuts-chrome-* dirs in /tmp" '[ "$(nodecuts | wc -l)" -gt 0 ]'
    check "the window can be worked out from their times" '[ -n "$(window)" ]'
}

steps() {
    step "Remove the leaked /tmp/nodecuts-chrome-* dirs (not in use)" 'remove_list nodecuts'
    step "Remove empty /tmp/org.chromium.Chromium.* dirs from the same window (not in use)" 'remove_list chromium_empty'
}

nodecuts() { find /tmp -maxdepth 1 -type d -name 'nodecuts-chrome-*' -user "$(id -u)" 2>/dev/null; }

window() {   # "<first epoch - 300> <last epoch + 300>" from the nodecuts dirs' own mtimes
    nodecuts | xargs -r stat -c %Y 2>/dev/null | sort -n | awk 'NR==1{a=$1} {b=$1} END{if(NR) print a-300, b+300}'
}

chromium_empty() {
    local w a b d t
    w=$(window); [ -n "$w" ] || return 0
    a=${w% *}; b=${w#* }
    find /tmp -maxdepth 1 -type d -name 'org.chromium.Chromium.*' -empty -user "$(id -u)" 2>/dev/null \
        | while read -r d; do t=$(stat -c %Y "$d"); [ "$t" -ge "$a" ] && [ "$t" -le "$b" ] && echo "$d"; done
}

in_use() { pgrep -f -- "$1" >/dev/null 2>&1; }

remove_list() {   # $1 = the function that lists candidate dirs
    local d n=0 skipped=0 before after
    before=$(df -k --output=avail /tmp | tail -1)
    while read -r d; do
        [ -n "$d" ] || continue
        case "$d" in /tmp/nodecuts-chrome-*|/tmp/org.chromium.Chromium.*) ;; *) echo "refusing $d"; continue ;; esac
        if in_use "$d"; then skipped=$((skipped+1)); continue; fi
        rm -rf -- "$d" && n=$((n+1))
    done < <("$1")
    after=$(df -k --output=avail /tmp | tail -1)
    echo "removed $n dir(s), skipped $skipped in use, freed about $(( (after - before) / 1024 )) MB"
}
