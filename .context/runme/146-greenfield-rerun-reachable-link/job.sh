# Operator job for tools/runme-launcher.sh. DEFINITIONS ONLY: the launcher refuses a job that runs
# anything when loaded. Steps run from the project root, each after the operator's y/N.
# --dry-run rehearses every `step` in a clone of HEAD; a step that acts outside the repo (push, tag push, /etc,
# model calls, host services), or needs such a step's result, is `step_outward "<what>" '<cmd>'` instead.
# A verb only the operator may run (fw inception decide, …), which refuses in the agent's session, is
# `step_operator "<what>" '<cmd>'` (T-1324): listed as operator only, never rehearsed, run for real like any step.
JOB_TITLE="T-968: re-run Greenfield's own task '\\AEF TermLink reachable' (WSL keepalive + portproxy 9100), then link 832 to the hub"
JOB_TASK="T-968"
JOB_WHY="Root cause (ring20, msgs 4583f6e8, 05970912): Greenfield runs in WSL Ubuntu on a Windows 10 laptop and makes its
hub reachable with its OWN scheduled task '\\AEF TermLink reachable' (greenfield T-087: keeps WSL alive, sets the
portproxy 0.0.0.0:9100 -> WSL). Ring20's pool-worker scripts deleted that portproxy row by mistake (ring20 is fixing
them), and WSL had stopped. So nothing new is installed: this job re-runs Greenfield's own task.
  1 LOOK (read only): WSL state, the hub inside WSL, portproxy, the task's state and the tail of its log.
  2 RUN the existing task (Start-ScheduledTask), wait, show the portproxy again.
  3 check from here; 4 fetch the hub key from WSL (validated, stored 0600, never printed); 5 prove the link.
Login: Windows OpenSSH as your user (build/greenfield-ssh-user). Nothing is sent to Evergreen."

PROFILE="greenfield"
USERFILE=/opt/832-Workflow-designer/build/greenfield-ssh-user   # absolute: untracked, so a rehearsal clone has none
LOG=.context/runme/146-greenfield-rerun-reachable-link

preflight() {
    check "on bleeding-edge" '[ "$(git rev-parse --abbrev-ref HEAD)" = bleeding-edge ]'
    check "termlink is installed here" 'command -v termlink >/dev/null'
    check "the greenfield hub has an address in ~/.termlink/hubs.toml" '[ -n "$(hub_host)" ]'
    check "the login user is recorded (build/greenfield-ssh-user)" '[ -s $USERFILE ]'
}

steps() {
    step_outward "Look (read only): WSL, hub in WSL, portproxy, Greenfield's reachable task and its log" 'pwsh_remote look ps_look'
    step_outward "Run Greenfield's own task '\\AEF TermLink reachable', wait 45 s, show the portproxy" 'pwsh_remote rerun ps_rerun'
    step_outward "Check from here that the greenfield hub answers" 'hub_up'
    step_outward "Fetch the hub key from WSL, validate (64 hex), store it 0600 in TermLink's store (never printed)" 'fetch_secret'
    step_outward "Prove the link: remote doctor and the session list on greenfield" 'prove'
}

hub_host() {
    awk -v p="[hubs.$PROFILE]" '$0==p{f=1;next} /^\[/{f=0} f && /^address/{gsub(/[" ]/,"",$0); split($0,a,"="); split(a[2],b,":"); print b[1]; exit}' "$HOME/.termlink/hubs.toml"
}
secret_file() {
    awk -v p="[hubs.$PROFILE]" '$0==p{f=1;next} /^\[/{f=0} f && /^secret_file/{sub(/^[^=]*=[ ]*/,"",$0); gsub(/"/,"",$0); print; exit}' "$HOME/.termlink/hubs.toml"
}
login() { echo "$(cat "$USERFILE")@$(hub_host)"; }

# pwsh_remote <name> <script-fn>: run PowerShell on the laptop; the step fails unless the script's own end marker comes
# back (job 143's lesson: ssh's exit code alone said "ok" for commands that never ran).
pwsh_remote() {
    local enc out="$LOG/$1.txt"
    enc=$("$2" | iconv -f UTF-8 -t UTF-16LE | base64 -w0) || return 1
    ssh -o ConnectTimeout=15 "$(login)" "powershell -NoProfile -NonInteractive -EncodedCommand $enc" 2>&1 | tr -d '\r' | tee "$out"
    grep -q "^== END OK" "$out" || { echo "The remote script did not finish OK; see $out"; return 1; }
}

ps_look() {
    cat <<'PS'
$ErrorActionPreference = 'Continue'
"== $(whoami) on $env:COMPUTERNAME"
"== WSL distros:"; (wsl.exe -l -v 2>&1 | Out-String) -replace "`0", ""
"== hub inside WSL Ubuntu:"; wsl.exe -d Ubuntu -u root -e sh -c 'systemctl is-active termlink-hub; ss -tln | grep 9100'
"== portproxy:"; netsh interface portproxy show v4tov4
"== Greenfield's task:"; Get-ScheduledTask -TaskName 'AEF TermLink reachable' -ErrorAction SilentlyContinue | Format-Table TaskName, State -AutoSize | Out-String
Get-ScheduledTaskInfo -TaskName 'AEF TermLink reachable' -ErrorAction SilentlyContinue | Format-List LastRunTime, LastTaskResult | Out-String
"== its log (last 15 lines):"; Get-Content 'C:\ProgramData\aef-reachable\reachable-boot.log' -Tail 15 -ErrorAction SilentlyContinue
"== END OK"
PS
}

ps_rerun() {
    cat <<'PS'
$ErrorActionPreference = 'Stop'
if (-not (Get-ScheduledTask -TaskName 'AEF TermLink reachable' -ErrorAction SilentlyContinue)) { "the task 'AEF TermLink reachable' does not exist"; exit 1 }
Start-ScheduledTask -TaskName 'AEF TermLink reachable'
"started; waiting 45 s for WSL and the portproxy"; Start-Sleep -Seconds 45
"== portproxy:"; netsh interface portproxy show v4tov4
"== log (last 10 lines):"; Get-Content 'C:\ProgramData\aef-reachable\reachable-boot.log' -Tail 10 -ErrorAction SilentlyContinue
if (-not ((netsh interface portproxy show v4tov4 | Out-String) -match '9100')) { "no 9100 portproxy row after the task ran"; exit 1 }
"== END OK"
PS
}

hub_up() {
    local out
    out=$(timeout 30 termlink fleet status 2>&1 | grep -E "^\s*\S*\s+$PROFILE\s")
    echo "$out"
    case "$out" in *UP*|*auth*|*AUTH*) return 0 ;; esac
    echo "Still not reachable. See $LOG/look.txt and $LOG/rerun.txt, and tell the agent."
    return 1
}

fetch_secret() {
    local v f; f=$(secret_file)
    [ -n "$f" ] || { echo "no secret_file for [hubs.$PROFILE] in ~/.termlink/hubs.toml"; return 1; }
    v=$(ssh -o ConnectTimeout=15 "$(login)" "wsl.exe -d Ubuntu -u root -e cat /var/lib/termlink/hub.secret" 2>/dev/null | tr -d '\r\n\0 ')
    printf '%s' "$v" | grep -Eqx '[0-9a-fA-F]{64}' || { v=; echo "what came back is not 64 hex characters (nothing printed, nothing stored)"; return 1; }
    mkdir -p "$(dirname "$f")" && ( umask 077; printf '%s\n' "$v" > "$f.new" ) && mv "$f.new" "$f" && chmod 600 "$f"
    v=
    echo "stored in $f (0600, $(wc -c < "$f") bytes; value not printed)"
}

prove() {
    timeout 60 termlink remote doctor "$PROFILE" && timeout 60 termlink remote list "$PROFILE"
}
