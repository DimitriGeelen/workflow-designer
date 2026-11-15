# Operator job for tools/runme-launcher.sh. DEFINITIONS ONLY: the launcher refuses a job that runs
# anything when loaded. Steps run from the project root, each after the operator's y/N.
# --dry-run rehearses every `step` in a clone of HEAD; a step that acts outside the repo (push, tag push, /etc,
# model calls, host services), or needs such a step's result, is `step_outward "<what>" '<cmd>'` instead.
# A verb only the operator may run (fw inception decide, …), which refuses in the agent's session, is
# `step_operator "<what>" '<cmd>'` (T-1324): listed as operator only, never rehearsed, run for real like any step.
JOB_TITLE="T-968: greenfield TermLink hub — log in as YOUR user (asked), look, start it with sudo if absent, re-check"
JOB_TASK="T-968"
JOB_WHY="Replaces job 142, whose root ssh login that machine refuses ('Permission denied', then 'Too many
authentication failures', 18:05-18:06). Step 1 ASKS which user you log in with on the greenfield machine (your
answer is kept in build/greenfield-ssh-user, which git ignores, so later jobs can reuse it), then only LOOKS:
termlink, hub process, ports, systemd unit, firewall. Step 2 starts the hub with sudo, ONLY if no hub process
runs (systemd unit if there is one, else 'termlink hub start --tcp 0.0.0.0:9100'). Step 3 checks from here.
You may get a password prompt for ssh and one for sudo on that machine."

PROFILE="greenfield"
USERFILE=build/greenfield-ssh-user

preflight() {
    check "on bleeding-edge" '[ "$(git rev-parse --abbrev-ref HEAD)" = bleeding-edge ]'
    check "termlink is installed here" 'command -v termlink >/dev/null'
    check "the greenfield hub has an address in ~/.termlink/hubs.toml" '[ -n "$(hub_host)" ]'
}

steps() {
    step_outward "Ask your login user, then look (read only, over ssh): termlink, hub, ports, systemd unit, firewall" 'ask_user && look'
    step_outward "Start the hub on 0.0.0.0:9100 with sudo, only if no hub process runs there" 'start_if_absent'
    step_outward "Check from here that the greenfield hub now answers" 'check_here'
}

hub_host() {
    awk -v p="[hubs.$PROFILE]" '$0==p{f=1;next} /^\[/{f=0} f && /^address/{gsub(/[" ]/,"",$0); split($0,a,"="); split(a[2],b,":"); print b[1]; exit}' "$HOME/.termlink/hubs.toml"
}

ask_user() {
    local u
    printf "Which user do you log in with on the greenfield machine (%s)? " "$(hub_host)" > /dev/tty
    read -r u < /dev/tty
    case "$u" in ''|*[!a-zA-Z0-9._-]*) echo "not a user name: '$u'"; return 1 ;; esac
    mkdir -p build && echo "$u" > "$USERFILE"
    echo "logging in as $u"
}

remote() {  # remote '<shell>' : run on the greenfield machine as the operator's user (-t so sudo can ask)
    ssh -t -o ConnectTimeout=15 -o PreferredAuthentications=publickey,keyboard-interactive,password \
        "$(cat "$USERFILE")@$(hub_host)" "$1"
}

look() {
    remote 'echo "== logged in as $(id -un) on $(hostname)";
            echo "== termlink: $(command -v termlink || echo NOT INSTALLED) $(termlink --version 2>/dev/null)";
            echo "== hub processes:"; pgrep -a -f "termlink.*hub" || echo "  none";
            echo "== listening on 9100 or by termlink:"; (ss -tlnp 2>/dev/null || ss -tln) | grep -E ":9100|termlink" || echo "  nothing";
            echo "== systemd units:"; systemctl list-unit-files 2>/dev/null | grep -i termlink || echo "  none";
            echo "== firewall (sudo):"; (sudo ufw status 2>/dev/null | head -5) || true'
}

start_if_absent() {
    remote 'if pgrep -f "termlink.*hub" >/dev/null; then
                echo "A hub process already runs; NOT starting a second one:"; pgrep -a -f "termlink.*hub";
                echo "If it listens on localhost only, it must be restarted with --tcp 0.0.0.0:9100 (your decision)."; exit 0;
            fi
            u=$(systemctl list-unit-files 2>/dev/null | awk "/termlink/ && /hub/ {print \$1; exit}")
            if [ -n "$u" ]; then
                echo "starting systemd unit $u"; sudo systemctl start "$u" && sleep 3 && systemctl --no-pager status "$u" | head -8
            else
                echo "no systemd unit; starting as root: termlink hub start --tcp 0.0.0.0:9100 (log /var/log/termlink-hub.log)"
                sudo sh -c "nohup termlink hub start --tcp 0.0.0.0:9100 >> /var/log/termlink-hub.log 2>&1 < /dev/null &"
                sleep 5; pgrep -a -f "termlink.*hub" || { echo "the hub did not stay up:"; sudo tail -20 /var/log/termlink-hub.log; exit 1; }
            fi
            (ss -tln) | grep ":9100" || { echo "still nothing listening on 9100"; exit 1; }'
}

check_here() {
    local out
    out=$(timeout 30 termlink fleet status 2>&1 | grep -E "^\s*\S*\s+$PROFILE\s")
    echo "$out"
    case "$out" in *UP*|*auth*|*AUTH*) echo "The hub answers. Next: job 140 (its step 2 also logs in as root; tell the agent if that is refused too)."; return 0 ;; esac
    echo "Still not reachable from here. If step 1 showed a hub on 0.0.0.0:9100, the firewall is the next suspect."
    return 1
}
