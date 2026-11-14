# Operator job for tools/runme-launcher.sh. DEFINITIONS ONLY: the launcher refuses a job that runs
# anything when loaded. Steps run from the project root, each after the operator's y/N.
# T-968: link 832 to the Evergreen/greenfield hub through TermLink's own declared bootstrap. The heal is Tier-2
# (`termlink fleet reauth --bootstrap-from ssh:<host>` fetches the hub secret host-to-host), so it is the operator's
# step; the secret never passes through the agent, this file, a commit or the transcript. No LAN address is written
# here (T-1239): the host is read at run time from the hub profile in ~/.termlink/hubs.toml.
JOB_TITLE="Link 832 to the Evergreen (greenfield) TermLink hub — you fetch its secret via TermLink's own bootstrap"
JOB_TASK="T-968"
JOB_WHY="You chose to keep working with Evergreen (5a, 2026-11-14): we want their workflow maps to see how our
designer behaves in other hands. Two things must be true first:
 - its TermLink hub must be RUNNING on that machine (it timed out at 2026-11-14 23:00 CET; in October you started it
   with --tcp 0.0.0.0:9100). Step 1 only checks this; if it fails, start the hub there and re-run this job.
 - our copy of its hub secret must match; step 2 heals it with TermLink's declared bootstrap (ssh to that host,
   sudo cat /var/lib/termlink/hub.secret, written straight into TermLink's own store). You will see an ssh prompt.
Step 3 proves the link (remote doctor + session list). Nothing is sent to Evergreen in this job."

PROFILE="greenfield"

preflight() {
    check "on bleeding-edge" '[ "$(git rev-parse --abbrev-ref HEAD)" = bleeding-edge ]'
    check "termlink is installed" 'command -v termlink >/dev/null'
}

steps() {
    step_outward "Check the $PROFILE hub answers (no secret involved)" 'hub_up'
    step_operator "Heal the $PROFILE hub secret via TermLink's declared ssh bootstrap (Tier-2, yours)" 'heal'
    step_outward "Prove the link: remote doctor and the session list on $PROFILE" 'prove'
}

hub_host() {
    awk -v p="[hubs.$PROFILE]" '$0==p{f=1;next} /^\[/{f=0} f && /^address/{gsub(/[" ]/,"",$0); split($0,a,"="); split(a[2],b,":"); print b[1]; exit}' "$HOME/.termlink/hubs.toml"
}

hub_up() {
    local out
    out=$(timeout 30 termlink fleet status 2>&1 | grep -E "^\s*\S*\s+$PROFILE\s")
    echo "$out"
    case "$out" in *UP*|*auth*|*AUTH*) return 0 ;; esac
    echo "The $PROFILE hub is not reachable. Start its TermLink hub on that machine (with --tcp 0.0.0.0:9100), then re-run this job."
    return 1
}

heal() {
    local host; host=$(hub_host)
    [ -n "$host" ] || { echo "no address for [hubs.$PROFILE] in ~/.termlink/hubs.toml"; return 1; }
    termlink fleet reauth "$PROFILE" --bootstrap-from "ssh:root@$host"
}

prove() {
    timeout 60 termlink remote doctor "$PROFILE" && timeout 60 termlink remote list "$PROFILE"
}
