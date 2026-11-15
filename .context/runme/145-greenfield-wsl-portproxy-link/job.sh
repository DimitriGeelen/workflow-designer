# Operator job for tools/runme-launcher.sh. DEFINITIONS ONLY: the launcher refuses a job that runs
# anything when loaded. Steps run from the project root, each after the operator's y/N.
# --dry-run rehearses every `step` in a clone of HEAD; a step that acts outside the repo (push, tag push, /etc,
# model calls, host services), or needs such a step's result, is `step_outward "<what>" '<cmd>'` instead.
# A verb only the operator may run (fw inception decide, …), which refuses in the agent's session, is
# `step_operator "<what>" '<cmd>'` (T-1324): listed as operator only, never rehearsed, run for real like any step.
JOB_TITLE="T-968: make the greenfield hub reachable (Windows portproxy 9100 -> WSL, kept across restarts), then link 832 to it"
JOB_TASK="T-968"
JOB_WHY="Root cause, found by ring20 (msg 4583f6e8): Greenfield runs in WSL2 Ubuntu on a Windows 10 laptop; the hub is
the WSL systemd unit termlink-hub (0.0.0.0:9100 inside WSL). WSL had stopped, so the hub was down; it runs again now,
but WSL is in NAT mode and nothing on the Windows side forwards 9100, so this machine gets no answer. Mirrored
networking needs Windows 11, so the fix is a portproxy. Login: Windows OpenSSH as your user (build/greenfield-ssh-user).
  1 LOOK (read only): admin rights, WSL state, hub inside WSL, current portproxy, firewall rules for 9100.
  2 CHANGES THE LAPTOP: netsh portproxy 0.0.0.0:9100 -> the WSL address now (needs your user to be an administrator).
  3 CHANGES THE LAPTOP: a scheduled task 'TermLink WSL hub proxy' at your logon that starts WSL, keeps it alive and
    re-applies the portproxy (the WSL address changes on each start). Script: C:\\ProgramData\\termlink\\wsl-hub-proxy.ps1.
    Undo: Unregister-ScheduledTask 'TermLink WSL hub proxy'; netsh interface portproxy delete v4tov4 listenport=9100 listenaddress=0.0.0.0
  4 check from here that the hub answers.
  5 fetch the hub key from WSL (/var/lib/termlink/hub.secret), validate it (64 hex), write it to TermLink's store
    (0600) without printing it; 6 prove the link (remote doctor + session list). Nothing is sent to Evergreen."

PROFILE="greenfield"
USERFILE=/opt/832-Workflow-designer/build/greenfield-ssh-user   # absolute: untracked, so a rehearsal clone has none
LOG=.context/runme/145-greenfield-wsl-portproxy-link

preflight() {
    check "on bleeding-edge" '[ "$(git rev-parse --abbrev-ref HEAD)" = bleeding-edge ]'
    check "termlink is installed here" 'command -v termlink >/dev/null'
    check "the greenfield hub has an address in ~/.termlink/hubs.toml" '[ -n "$(hub_host)" ]'
    check "the login user is recorded (build/greenfield-ssh-user)" '[ -s $USERFILE ]'
}

steps() {
    step_outward "Look (read only): admin?, WSL state, hub in WSL, portproxy, firewall for 9100" 'pwsh_remote look ps_look'
    step_outward "CHANGE: portproxy 0.0.0.0:9100 -> WSL Ubuntu's address now" 'pwsh_remote proxy ps_proxy'
    step_outward "CHANGE: scheduled task at your logon keeps WSL alive and re-applies the portproxy" 'pwsh_remote task ps_task'
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

# pwsh_remote <name> <script-fn>: run a PowerShell script on the laptop; the step fails unless the script's own end
# marker comes back (job 143's lesson: ssh's exit code alone said "ok" for commands that never ran).
pwsh_remote() {
    local enc out="$LOG/$1.txt"
    enc=$("$2" | iconv -f UTF-8 -t UTF-16LE | base64 -w0) || return 1
    ssh -o ConnectTimeout=15 "$(login)" "powershell -NoProfile -NonInteractive -EncodedCommand $enc" 2>&1 | tr -d '\r' | tee "$out"
    grep -q "^== END OK" "$out" || { echo "The remote script did not finish OK; see $out"; return 1; }
}

ps_look() {
    cat <<'PS'
$ErrorActionPreference = 'Continue'
$admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
"== $(whoami) on $env:COMPUTERNAME, administrator: $admin"
"== WSL distros:"; (wsl.exe -l -v 2>&1 | Out-String) -replace "`0", ""
"== hub inside WSL Ubuntu:"; wsl.exe -d Ubuntu -u root -e sh -c 'systemctl is-active termlink-hub; ss -tln | grep 9100; hostname -I'
"== portproxy:"; netsh interface portproxy show v4tov4
"== listening on Windows :9100:"; Get-NetTCPConnection -State Listen -LocalPort 9100 -ErrorAction SilentlyContinue | Format-Table LocalAddress, OwningProcess -AutoSize | Out-String
"== firewall rules for 9100:"
Get-NetFirewallRule -Enabled True -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like '*9100*' -or $_.DisplayName -like '*termlink*' } | ForEach-Object {
  $a = $_ | Get-NetFirewallAddressFilter; $p = $_ | Get-NetFirewallPortFilter
  "  {0} | {1} {2} | port {3} | remote {4}" -f $_.DisplayName, $_.Direction, $_.Action, $p.LocalPort, ($a.RemoteAddress -join ',') }
"== END OK"
PS
}

ps_proxy() {
    cat <<'PS'
$ErrorActionPreference = 'Stop'
$ip = ((wsl.exe -d Ubuntu -u root -e hostname -I) -split '\s+' | Where-Object { $_ -match '^\d+\.\d+\.\d+\.\d+$' } | Select-Object -First 1)
if (-not $ip) { "no WSL address (is the Ubuntu distro running?)"; exit 1 }
"WSL Ubuntu address: $ip"
netsh interface portproxy delete v4tov4 listenport=9100 listenaddress=0.0.0.0 2>$null | Out-Null
netsh interface portproxy add v4tov4 listenport=9100 listenaddress=0.0.0.0 connectport=9100 connectaddress=$ip
if ($LASTEXITCODE -ne 0) { "netsh refused (administrator rights needed)"; exit 1 }
netsh interface portproxy show v4tov4
"== END OK"
PS
}

ps_task() {
    cat <<'PS'
$ErrorActionPreference = 'Stop'
$dir = 'C:\ProgramData\termlink'; New-Item -ItemType Directory -Force -Path $dir | Out-Null
$script = @'
# Started at logon by the scheduled task 'TermLink WSL hub proxy' (832 T-968). Keeps WSL Ubuntu running (so its
# termlink-hub unit runs) and points the Windows portproxy for 9100 at WSL's address, which changes on each start.
$keep = Start-Process wsl.exe -ArgumentList '-d','Ubuntu','-u','root','-e','sleep','infinity' -WindowStyle Hidden -PassThru
Start-Sleep -Seconds 10
$ip = ((wsl.exe -d Ubuntu -u root -e hostname -I) -split '\s+' | Where-Object { $_ -match '^\d+\.\d+\.\d+\.\d+$' } | Select-Object -First 1)
if ($ip) {
  netsh interface portproxy delete v4tov4 listenport=9100 listenaddress=0.0.0.0 | Out-Null
  netsh interface portproxy add v4tov4 listenport=9100 listenaddress=0.0.0.0 connectport=9100 connectaddress=$ip | Out-Null
}
Wait-Process -Id $keep.Id
'@
Set-Content -Path "$dir\wsl-hub-proxy.ps1" -Value $script -Encoding UTF8
$action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$dir\wsl-hub-proxy.ps1`""
$trigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Highest
$settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit ([TimeSpan]::Zero) -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
Register-ScheduledTask -TaskName 'TermLink WSL hub proxy' -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force | Out-Null
Get-ScheduledTask -TaskName 'TermLink WSL hub proxy' | Format-Table TaskName, State -AutoSize | Out-String
"== END OK"
PS
}

hub_up() {
    local out
    out=$(timeout 30 termlink fleet status 2>&1 | grep -E "^\s*\S*\s+$PROFILE\s")
    echo "$out"
    case "$out" in *UP*|*auth*|*AUTH*) return 0 ;; esac
    echo "Still not reachable. Look at $LOG/look.txt (firewall rules, admin) and tell the agent."
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
