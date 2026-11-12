# Operator job for tools/runme-launcher.sh. DEFINITIONS ONLY: the launcher refuses a job that runs
# anything when loaded. Steps run from the project root, each after the operator's y/N.
# T-1257 / T-1404: removes the stale, empty org.chromium.Chromium.* dirs Chrome left in /tmp (one per launch; T-1404
# stops new ones from 832's harnesses). Both steps act outside the repo (/tmp), so both are `step_outward`.
JOB_TITLE="Remove stale empty Chromium temp dirs from /tmp (org.chromium.Chromium.*, older than 24 h, nothing live)"
JOB_TASK="T-1257"
JOB_WHY="Chrome leaves one /tmp/org.chromium.Chromium.XXXXXX dir per launch (T-1404 measured it; 832's harnesses no
longer leave them as of today). About 1,800 stale ones sit in /tmp. You said yes to clearing them (2026-11-12).
A dir is removed ONLY if all four hold: its name is org.chromium.Chromium.*, it is older than 24 hours, it holds
nothing but Chrome's SingletonCookie and SingletonSocket (or nothing at all), and no process is listening on its
socket (a live Chrome, ours or another project's). Dirs holding anything else (Chrome component downloads, model
files) are left alone, whoever made them. Step 1 only counts and lists; step 2 removes and reports what it removed.
The dotted .org.chromium.Chromium.* FILES (about 1 GB of shared memory) are NOT touched: they are not shown to be ours."

LIST=.context/runme/135-clean-chromium-tmp-dirs/candidates.txt

preflight() {
    check "on bleeding-edge" '[ "$(git rev-parse --abbrev-ref HEAD)" = bleeding-edge ]'
    check "the T-1404 fix is in (so 832 stops adding new ones)" 'grep -q "removeChromeTemp(dir)" tools/_cdp-profile.mjs'
}

steps() {
    step_outward "Count and list the dirs that meet all four rules (nothing removed)" 'do_list'
    step_outward "Remove exactly the listed dirs, re-checking each rule just before removing it" 'do_remove'
}

# One dir qualifies: name, age > 24 h, only singleton entries (or empty), its socket not listened on.
qualifies() {
    local d=$1 e
    case "$(basename "$d")" in org.chromium.Chromium.*) ;; *) return 1 ;; esac
    [ -d "$d" ] && [ ! -L "$d" ] || return 1
    [ -n "$(find "$d" -maxdepth 0 -mmin +1440 2>/dev/null)" ] || return 1
    for e in $(ls -A "$d"); do
        case "$e" in SingletonCookie|SingletonSocket) ;; *) return 1 ;; esac
    done
    if [ -e "$d/SingletonSocket" ] || [ -L "$d/SingletonSocket" ]; then
        ss -xl 2>/dev/null | grep -qF "$d/SingletonSocket" && return 1
    fi
    return 0
}

do_list() {
    local d n=0 all=0
    : > "$LIST"
    for d in /tmp/org.chromium.Chromium.*; do
        [ -d "$d" ] || continue
        all=$((all + 1))
        if qualifies "$d"; then printf '%s\n' "$d" >> "$LIST"; n=$((n + 1)); fi
    done
    echo "org.chromium.Chromium.* dirs in /tmp: $all; meeting all four rules: $n (list: $LIST)"
    head -3 "$LIST"
}

do_remove() {
    [ -s "$LIST" ] || { echo "no list from step 1, or it is empty: nothing to remove"; return 0; }
    local d n=0 skipped=0
    while IFS= read -r d; do
        if qualifies "$d"; then rm -rf -- "$d" && n=$((n + 1)); else skipped=$((skipped + 1)); fi
    done < "$LIST"
    echo "removed $n; skipped $skipped (changed since step 1); left in /tmp now: $(ls -d /tmp/org.chromium.Chromium.* 2>/dev/null | wc -l)"
}
