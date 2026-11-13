#!/bin/bash
# _t1257-chromium-holder-probe.sh — T-1257 kind 1: who creates /tmp/.org.chromium.Chromium.* files? Read-only.
#   bash tools/_t1257-chromium-holder-probe.sh [seconds=1200] [logfile=stdout]   (run in the background across a burst)
# Every 2 s: list dotted files newer than the last check; for each, record the holding processes
# (fuser), their cwd, cgroup unit and a short cmdline (Chrome's own and its ancestors' up to 4 levels).
dur=${1:-1200}; out=${2:-/dev/stdout}
end=$((SECONDS + dur)); seen=$(mktemp); ls -1A /tmp/ 2>/dev/null | grep '^\.org\.chromium\.Chromium\.' | sort > "$seen"
echo "start $(date -u +%FT%TZ) existing=$(wc -l < "$seen")" >> "$out"
while [ $SECONDS -lt $end ]; do
    sleep 2
    now=$(mktemp); ls -1A /tmp/ 2>/dev/null | grep '^\.org\.chromium\.Chromium\.' | sort > "$now"
    for f in $(comm -13 "$seen" "$now"); do
        pids=$(fuser "/tmp/$f" 2>/dev/null)
        echo "NEW $(date -u +%T) $f pids=[${pids}]" >> "$out"
        for p in $pids; do
            q=$p
            for lvl in 0 1 2 3 4; do
                [ -r /proc/$q/cmdline ] || break
                cmd=$(tr '\0' ' ' < /proc/$q/cmdline | cut -c1-160)
                cwd=$(readlink /proc/$q/cwd 2>/dev/null)
                cg=$(grep -o '[^/]*\.\(service\|scope\)' /proc/$q/cgroup 2>/dev/null | tail -1)
                echo "   L$lvl pid=$q cwd=$cwd cg=$cg :: $cmd" >> "$out"
                q=$(awk '/^PPid:/{print $2}' /proc/$q/status 2>/dev/null); [ -n "$q" ] && [ "$q" != 0 ] || break
            done
            break   # one holder's ancestry is enough
        done
    done
    mv "$now" "$seen"
done
echo "end $(date -u +%FT%TZ)" >> "$out"
rm -f "$seen"
