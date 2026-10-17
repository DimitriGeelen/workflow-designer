# Operator job for tools/runme-launcher.sh (T-1055). DEFINITIONS ONLY.
JOB_TITLE="Install AEF's claude-fw router on PATH (old copies backed up) so AEF's T-4218 project pin is active"
JOB_TASK="T-1190"
JOB_WHY="Your 'yes' (2026-10-17). /usr/bin/claude-fw and ~/.local/bin/claude-fw are a fixed COPY of an older wrapper
(another install rewrote them today at 15:26). That copy lacks AEF T-4218: a claude-fw session now pins PROJECT_ROOT
and FRAMEWORK_ROOT to the project it is started in, the fix for the 055 leak we hit. AEF's answer is the router
(bin/claude-fw-router, 3.7 KB): it finds the project you start it in and runs THAT project's own claude-fw, so every
project gets its own up-to-date wrapper. MACHINE-WIDE: a project with no claude-fw of its own gets plain claude
(no auto-restart) and says so on stderr. Running sessions are not affected; the next claude-fw start is. Both old
copies are saved in this job's backup/ folder first; to undo, copy them back. Another project's install can put a
fixed copy back again; fw doctor reports it if so."

ROUTER=.agentic-framework/bin/claude-fw-router
OUT=.context/runme/036-install-claude-fw-router
TARGETS="/usr/bin/claude-fw /root/.local/bin/claude-fw"

preflight() {
    check "on bleeding-edge" '[ "$(git rev-parse --abbrev-ref HEAD)" = bleeding-edge ]'
    check "the router is vendored, executable and parses" '[ -x "$ROUTER" ] && bash -n "$ROUTER"'
    check "the vendored router is the one from AEF 956f05f36" 'git diff --quiet f266c5a7 -- "$ROUTER"'
    check "both targets exist" 'for t in $TARGETS; do [ -f "$t" ] || exit 1; done'
    check "neither target is the router already" 'for t in $TARGETS; do cmp -s "$ROUTER" "$t" && exit 1; done; exit 0'
}

steps() {
    step "Back up both installed copies into $OUT/backup/ (with sha256)" 'do_backup'
    step "Install the router at /usr/bin/claude-fw and ~/.local/bin/claude-fw" 'do_install'
    step "Prove the routing in a dummy project (a marker script, no claude is started)" 'do_route_test $TARGETS'
    step "Check fw doctor no longer reports a drifted fixed copy" 'do_doctor'
}

do_backup() {
    mkdir -p "$OUT/backup" || return 1
    cp -p /usr/bin/claude-fw "$OUT/backup/usr-bin-claude-fw" || return 1
    cp -p /root/.local/bin/claude-fw "$OUT/backup/local-bin-claude-fw" || return 1
    (cd "$OUT/backup" && sha256sum usr-bin-claude-fw local-bin-claude-fw > SHA256SUMS) || return 1
    cmp -s /usr/bin/claude-fw "$OUT/backup/usr-bin-claude-fw" && cmp -s /root/.local/bin/claude-fw "$OUT/backup/local-bin-claude-fw" || return 1
    cat "$OUT/backup/SHA256SUMS"
    echo "undo: cp -p $OUT/backup/usr-bin-claude-fw /usr/bin/claude-fw; cp -p $OUT/backup/local-bin-claude-fw /root/.local/bin/claude-fw"
}

do_install() {
    local t
    for t in $TARGETS; do
        rm -f "$t" && cp "$ROUTER" "$t" && chmod +x "$t" || { echo "could not install $t"; return 1; }
        cmp -s "$ROUTER" "$t" || { echo "$t is not the router after the copy"; return 1; }
        echo "ok  $t = router ($(wc -c < "$t") bytes)"
    done
}

do_route_test() {   # args: the installed paths to test; each must already be the router (do_install checked)
    local d t out rc=0
    for t in "$@"; do cmp -s "$ROUTER" "$t" || { echo "refusing: $t is not the router, running it could start claude"; return 1; }; done
    d=$(mktemp -d /tmp/t1190-route.XXXXXX) || return 1
    mkdir -p "$d/proj/.agentic-framework/bin" "$d/proj/sub"
    touch "$d/proj/.agentic-framework/FRAMEWORK.md"
    printf '#!/bin/sh\nexit 0\n' > "$d/proj/.agentic-framework/bin/fw"
    printf '#!/bin/sh\necho "ROUTED-T1190 $FW_ROUTED_FROM $*"\n' > "$d/proj/.agentic-framework/bin/claude-fw"
    chmod +x "$d/proj/.agentic-framework/bin/fw" "$d/proj/.agentic-framework/bin/claude-fw"
    for t in "$@"; do
        out=$(cd "$d/proj/sub" && "$t" --probe 2>&1)
        if [ "$out" = "ROUTED-T1190 $d/proj/.agentic-framework --probe" ]; then echo "ok  $t ran the dummy project's own claude-fw"
        else echo "FAIL $t gave: $out"; rc=1; fi
    done
    rm -rf "$d"
    return "$rc"
}

do_doctor() {
    .agentic-framework/bin/fw doctor > "$OUT/doctor-after.txt" 2>&1
    if grep -q 'Installed claude-fw (.*) drifted' "$OUT/doctor-after.txt"; then
        echo "fw doctor still reports a drifted claude-fw on PATH:"; grep -A2 'Installed claude-fw (.*) drifted' "$OUT/doctor-after.txt"; return 1
    fi
    echo "ok  fw doctor: no drifted claude-fw on PATH ($(grep -c . "$OUT/doctor-after.txt") lines saved)"
}
