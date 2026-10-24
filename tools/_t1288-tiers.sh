# _t1288-tiers.sh — tiers, quarantine and retry-once for tests/run-bridge-tests.sh (832 T-1288). Sourced, not run.
#
# WHY (T-1285 spike 2): three per-leg-triaged runs of the suite gave 10 reds and 0 product regressions, almost all
# from the browser legs and the instrument sweep. Every run was red, so a real regression hid among them. The suite
# is now three tiers, each leg declared in ONE place, the line that registers it:
#
#     leg core|browser|sweep "<name>" <function> [args...]
#
#   core    starts no browser and is not the sweep. Hermetic: its own TMPDIR under .context/st/ (removed after), no
#           network and no browser (a private mount + network namespace where unshare allows it). Must be green;
#           tools/_t1288-prepush-gate.sh runs it before every push.
#   browser a leg that launches a browser (CDP harnesses, the person-sees gate, the shot scripts). A leg that fails
#           by TIMEOUT (rc 124) or "did not open a DevTools port" is retried once, alone, after the other legs:
#           FLAKY when the retry passes (counted and listed), RED when it fails again.
#   sweep   the T-509 instrument sweep.
#
# A leg named in tests/quarantine.yaml (leg, reason, owner, fix_by) still runs and reports, as QUARANTINED, and does
# not fail its tier; an entry past its fix_by FAILS the tier. A leg with no tier, or a tier not in the list, is a
# FAIL of its own (and tools/_t1288-tier-guard.py fails the file statically).
#
# A leg's counts are the deltas of the suite's own pass/fail counters across its function, so a leg may count more
# than once (the corpus loop counts each map). flaky and quarantined count legs.
#
# Environment (for the fixture tests): T1288_QUARANTINE (default tests/quarantine.yaml), T1288_TODAY (YYYY-MM-DD),
# T1288_NO_HERMETIC=1 (skip the namespace; the TMPDIR rule still holds), T1288_ST (default .context/st).

T1288_TIERS="core browser sweep"
T1288_TIER=all
T1288_LIST=0

t1288_usage() {
    echo "usage: $(basename "$0") [--tier core|browser|sweep|all] [--list-legs]"
    echo "  --tier all (default) runs every leg, as before T-1288; --list-legs prints <tier> <name> and runs nothing"
}

# t1288_parse_args "$@" — sets T1288_TIER and T1288_LIST; exits 2 on a bad argument.
t1288_parse_args() {
    while [ $# -gt 0 ]; do
        case "$1" in
            --tier) T1288_TIER="${2:-}"; shift 2 || { t1288_usage >&2; exit 2; } ;;
            --tier=*) T1288_TIER="${1#--tier=}"; shift ;;
            --list-legs) T1288_LIST=1; shift ;;
            -h|--help) t1288_usage; exit 0 ;;
            *) echo "unknown argument: $1" >&2; t1288_usage >&2; exit 2 ;;
        esac
    done
    case " $T1288_TIERS all " in
        *" $T1288_TIER "*) ;;
        *) echo "unknown tier: '$T1288_TIER' (core|browser|sweep|all)" >&2; exit 2 ;;
    esac
}

# t1288_hermetic <script> "$@" — for --tier core, re-exec the runner in a private mount + network namespace: only a
# loopback interface, and the browser binaries and caches covered, so a core leg that reaches for either fails
# instead of passing on the host's luck. Where unshare is not available the run continues and says so.
t1288_hermetic() {
    local script="$1"; shift
    [ "$T1288_TIER" = core ] && [ "$T1288_LIST" = 0 ] || return 0
    [ -n "${_T1288_IN_NS:-}" ] && return 0
    if [ "${T1288_NO_HERMETIC:-}" = 1 ]; then
        echo "core: namespace skipped (T1288_NO_HERMETIC=1); TMPDIR still private"; return 0
    fi
    local inner='ip link set lo up 2>/dev/null || exit 97
for d in "$HOME/.cache/ms-playwright" "$HOME/.cache/puppeteer" "$HOME/.cache/chromium"; do
  [ -d "$d" ] && { mount -t tmpfs -o size=1m,mode=0755 tmpfs "$d" || exit 97; }
done
for f in /usr/bin/chromium /usr/bin/chromium-browser /usr/bin/google-chrome /usr/bin/google-chrome-stable /snap/bin/chromium; do
  [ -e "$f" ] && { mount --bind /dev/null "$f" || exit 97; }
done
export _T1288_IN_NS=1
exec bash "$0" "$@"'
    local flags
    for flags in "--mount --net" "--user --map-root-user --mount --net"; do
        # shellcheck disable=SC2086
        if unshare $flags --propagation private true 2>/dev/null; then
            # shellcheck disable=SC2086
            exec unshare $flags --propagation private bash -c "$inner" "$script" "$@"
        fi
    done
    echo "core: hermeticity NOT enforced — unshare cannot make a mount + network namespace here; the legs are still"
    echo "      the ones declared core, and TMPDIR is still private"
}

# t1288_private_tmpdir — for --tier core, point TMPDIR at .context/st/ (created here, removed by t1288_cleanup) so
# the run's own mktemp -d lands inside the project, never in the shared /tmp.
_T1288_MADE_ST=0
t1288_private_tmpdir() {
    [ "$T1288_TIER" = core ] && [ "$T1288_LIST" = 0 ] || return 0
    T1288_ST="${T1288_ST:-$ROOT/.context/st}"
    [ -d "$T1288_ST" ] || { mkdir -p "$T1288_ST" && _T1288_MADE_ST=1; }
    export TMPDIR="$T1288_ST"
}
t1288_cleanup() {
    [ "$_T1288_MADE_ST" = 1 ] && rm -rf "$T1288_ST"
    return 0
}

# ── quarantine ──────────────────────────────────────────────────────────────────────────────────────────────────
declare -A _T1288_Q_REASON=() _T1288_Q_OWNER=() _T1288_Q_FIXBY=() _T1288_Q_EXPIRED=()
_T1288_Q_ERR=""
t1288_load_quarantine() {
    local qf="${T1288_QUARANTINE:-$ROOT/tests/quarantine.yaml}" today="${T1288_TODAY:-$(date -u +%Y-%m-%d)}" line
    [ -f "$qf" ] || return 0
    local parsed
    parsed=$(python3 - "$qf" "$today" <<'PY'
import sys, datetime, yaml
qf, today = sys.argv[1], datetime.date.fromisoformat(sys.argv[2])
try:
    doc = yaml.safe_load(open(qf, encoding="utf-8")) or {}
    entries = doc.get("quarantine") or []
    assert isinstance(entries, list), "quarantine: must be a list"
    for e in entries:
        miss = [k for k in ("leg", "reason", "owner", "fix_by") if not str(e.get(k) or "").strip()]
        assert not miss, f"entry {e.get('leg')!r} lacks {', '.join(miss)}"
        fix = e["fix_by"] if isinstance(e["fix_by"], datetime.date) else datetime.date.fromisoformat(str(e["fix_by"]))
        one = lambda s: " ".join(str(s).split())
        print("\t".join([one(e["leg"]), one(e["owner"]), fix.isoformat(), "1" if fix < today else "0", one(e["reason"])]))
except Exception as x:
    print(f"ERROR\t{x}")
PY
)
    while IFS=$'\t' read -r leg owner fix expired reason; do
        [ -n "$leg" ] || continue
        if [ "$leg" = ERROR ]; then _T1288_Q_ERR="$owner"; continue; fi
        _T1288_Q_REASON[$leg]="$reason"; _T1288_Q_OWNER[$leg]="$owner"; _T1288_Q_FIXBY[$leg]="$fix"
        [ "$expired" = 1 ] && _T1288_Q_EXPIRED[$leg]=1
    done <<< "$parsed"
}

# ── per-tier bookkeeping ────────────────────────────────────────────────────────────────────────────────────────
declare -A T1288_PASS=() T1288_FAIL=() T1288_FLAKY=() T1288_QUAR=() T1288_SECS=() T1288_RAN=() _T1288_LEG_TIER=()
_T1288_RETRY=()          # "tier<TAB>name<TAB>fn<TAB>args..." of legs waiting for their one retry
_T1288_PENDING_FAIL=0    # fails held back while a retry is pending (added back if the run dies first)
T1288_FLAKY_LIST=()
T1288_QUAR_LIST=()
for _t in $T1288_TIERS; do T1288_PASS[$_t]=0; T1288_FAIL[$_t]=0; T1288_FLAKY[$_t]=0; T1288_QUAR[$_t]=0; T1288_SECS[$_t]=0; done
unset _t

# Marks a timeout (rc 124) seen anywhere inside a leg, subshells included (a file, not a variable, for that reason).
timeout() {
    command timeout "$@"
    local rc=$?
    [ "$rc" = 124 ] && [ -n "${_T1288_TO_MARK:-}" ] && : > "$_T1288_TO_MARK"
    return "$rc"
}

# section "<header>" — a header shown before the next leg that actually runs (a loop of legs has one header, and a
# run of another tier should not print it).
_T1288_SECTION=""
section() { _T1288_SECTION="$1"; }

# leg <tier> <name> <fn> [args...]
leg() {
    local tier="${1:-}" name="${2:-}" fn="${3:-}"
    case " $T1288_TIERS " in
        *" $tier "*) ;;
        *)
            if [ "$T1288_LIST" = 1 ]; then echo "NO-TIER ${name:-?} (got '$tier')"; _T1288_NOTIER=1; return 0; fi
            report FAIL "leg '${name:-?}' has no tier (got '$tier'): declare it 'leg core|browser|sweep <name> <fn>' (T-1288)"
            fail=$((fail + 1)); _T1288_NOTIER=1
            return 0 ;;
    esac
    shift 3 || true
    if [ -n "${_T1288_LEG_TIER[$name]:-}" ]; then
        report FAIL "leg name '$name' is declared twice (tiers ${_T1288_LEG_TIER[$name]} and $tier); names key the quarantine (T-1288)"
        fail=$((fail + 1))
    fi
    _T1288_LEG_TIER[$name]="$tier"
    if [ "$T1288_LIST" = 1 ]; then echo "$tier $name"; return 0; fi
    [ "$T1288_TIER" = all ] || [ "$T1288_TIER" = "$tier" ] || return 0
    T1288_RAN[$tier]=1
    if [ -n "$_T1288_SECTION" ]; then printf '\n%s\n' "$_T1288_SECTION"; _T1288_SECTION=""; fi
    _t1288_run "$tier" "$name" first "$fn" "$@"
}

# _t1288_run <tier> <name> first|retry <fn> [args...]
_t1288_run() {
    local tier="$1" name="$2" attempt="$3" fn="$4"; shift 4
    local p0=$pass f0=$fail t0=$SECONDS out="$TMP/.t1288-leg.out" stamp="$TMP/.t1288-stamp"
    _T1288_TO_MARK="$TMP/.t1288-timeout"
    rm -f "$_T1288_TO_MARK"; : > "$stamp"
    if [ "$tier" = browser ]; then
        # captured so a DevTools-port failure can be recognised, then shown as it would have been
        "$fn" "$@" > "$out" 2>&1
        cat "$out"
    else
        "$fn" "$@"
    fi
    local dp=$((pass - p0)) df=$((fail - f0))
    T1288_SECS[$tier]=$(( ${T1288_SECS[$tier]} + SECONDS - t0 ))
    if [ "$df" -gt 0 ] && [ -n "${_T1288_Q_OWNER[$name]:-}" ] && [ -z "${_T1288_Q_EXPIRED[$name]:-}" ]; then
        fail=$((fail - df))
        T1288_QUAR[$tier]=$(( ${T1288_QUAR[$tier]} + 1 ))
        T1288_QUAR_LIST+=("$tier $name (owner ${_T1288_Q_OWNER[$name]}, fix by ${_T1288_Q_FIXBY[$name]})")
        T1288_PASS[$tier]=$(( ${T1288_PASS[$tier]} + dp ))
        report QUARANTINED "$name — red, known non-product: ${_T1288_Q_REASON[$name]} (owner ${_T1288_Q_OWNER[$name]}, fix by ${_T1288_Q_FIXBY[$name]}; tests/quarantine.yaml)"
        return 0
    fi
    if [ "$df" -gt 0 ] && [ "$tier" = browser ] && [ "$attempt" = first ] && _t1288_retryable "$out" "$stamp"; then
        pass=$((pass - dp)); fail=$((fail - df)); _T1288_PENDING_FAIL=$((_T1288_PENDING_FAIL + df))
        local IFS=$'\t'
        _T1288_RETRY+=("$tier"$'\t'"$name"$'\t'"$df"$'\t'"$fn${*:+$'\t'}$*")
        report RETRY "$name — failed by timeout or no DevTools port; retried once, alone, after the other legs"
        return 0
    fi
    T1288_PASS[$tier]=$(( ${T1288_PASS[$tier]} + dp ))
    T1288_FAIL[$tier]=$(( ${T1288_FAIL[$tier]} + df ))
    return 0
}

# A browser leg's failure is retryable when the leg saw rc 124 from timeout, or its output (or a leg-*.out it wrote
# during this run) says the browser did not open a DevTools port.
_t1288_retryable() {
    local out="$1" stamp="$2" f
    [ -e "$_T1288_TO_MARK" ] && return 0
    grep -q 'did not open a DevTools port' "$out" 2>/dev/null && return 0
    while IFS= read -r f; do
        grep -q 'did not open a DevTools port' "$f" 2>/dev/null && return 0
    done < <(find "$TMP" -maxdepth 1 -type f -name 'leg-*.out' -newer "$stamp" 2>/dev/null)
    return 1
}

# t1288_finish — the retries, then expired quarantine entries, then one summary line per tier that ran.
t1288_finish() {
    local entry tier name df fn
    if [ "${#_T1288_RETRY[@]}" -gt 0 ]; then
        echo
        echo "== Browser legs that failed by timeout or no DevTools port: one retry each, alone (T-1288) =="
        for entry in "${_T1288_RETRY[@]}"; do
            local -a parts=()
            IFS=$'\t' read -r -a parts <<< "$entry"
            tier="${parts[0]}"; name="${parts[1]}"; df="${parts[2]}"; fn="${parts[3]}"
            _T1288_PENDING_FAIL=$((_T1288_PENDING_FAIL - df))
            local f0=$fail p0=$pass
            _t1288_run "$tier" "$name" retry "$fn" "${parts[@]:4}"
            if [ "$fail" -eq "$f0" ]; then
                T1288_FLAKY[$tier]=$(( ${T1288_FLAKY[$tier]} + 1 ))
                T1288_FLAKY_LIST+=("$tier $name")
                report FLAKY "$name — failed by timeout or no DevTools port, passed alone on retry ($((pass - p0)) passed)"
            elif [ "$fail" -gt "$f0" ]; then
                report FAIL "$name — RED: failed again when retried alone (T-1288)"
            fi
        done
    fi
    for name in "${!_T1288_Q_EXPIRED[@]}"; do
        tier="${_T1288_LEG_TIER[$name]:-}"
        [ -n "$tier" ] || continue
        [ "$T1288_TIER" = all ] || [ "$T1288_TIER" = "$tier" ] || continue
        report FAIL "quarantine entry '$name' is past its fix_by ${_T1288_Q_FIXBY[$name]} (owner ${_T1288_Q_OWNER[$name]}): fix the leg or re-justify the entry in tests/quarantine.yaml (T-1288)"
        fail=$((fail + 1)); T1288_FAIL[$tier]=$(( ${T1288_FAIL[$tier]} + 1 ))
    done
    for name in "${!_T1288_Q_OWNER[@]}"; do
        if [ -z "${_T1288_LEG_TIER[$name]:-}" ]; then
            report FAIL "quarantine entry '$name' names no leg of this suite (renamed or removed?): remove or correct it (T-1288)"
            fail=$((fail + 1))
        fi
    done
    if [ -n "$_T1288_Q_ERR" ]; then
        report FAIL "tests/quarantine.yaml is unreadable: $_T1288_Q_ERR — nothing is quarantined until it parses (T-1288)"
        fail=$((fail + 1))
        local t; for t in $T1288_TIERS; do [ -n "${T1288_RAN[$t]:-}" ] && { T1288_FAIL[$t]=$(( ${T1288_FAIL[$t]} + 1 )); break; }; done
    fi
    echo
    t1288_summary_lines
    [ "${#T1288_FLAKY_LIST[@]}" -gt 0 ] && printf '  flaky: %s\n' "${T1288_FLAKY_LIST[@]}"
    [ "${#T1288_QUAR_LIST[@]}" -gt 0 ] && printf '  quarantined: %s\n' "${T1288_QUAR_LIST[@]}"
    return 0
}

t1288_summary_lines() {
    local t verdict
    for t in $T1288_TIERS; do
        [ -n "${T1288_RAN[$t]:-}" ] || continue
        verdict=GREEN; [ "${T1288_FAIL[$t]}" -gt 0 ] && verdict=RED
        printf 'tier %-7s %s: %d passed, %d failed, %d flaky, %d quarantined, %d s\n' "$t" "$verdict" \
            "${T1288_PASS[$t]}" "${T1288_FAIL[$t]}" "${T1288_FLAKY[$t]}" "${T1288_QUAR[$t]}" "${T1288_SECS[$t]}"
    done
}

# t1288_history_rows <rc> <dur> <sha> <ts> — the rows tests/.run-history.tsv gets for this run. Columns 1-6 are the
# T-813 ones (ts pass fail rc seconds sha); T-1288 appends tier, flaky, quarantined. A --tier all run writes its
# all-row (the whole run, what _t813/_t952 read) and one row per tier; a single-tier run writes only its own row.
t1288_history_rows() {
    local rc="$1" dur="$2" sha="$3" ts="$4" t trc qsum=0 fsum=0
    for t in $T1288_TIERS; do qsum=$((qsum + ${T1288_QUAR[$t]})); fsum=$((fsum + ${T1288_FLAKY[$t]})); done
    if [ "$T1288_TIER" = all ]; then
        printf '%s\t%s\t%s\t%s\t%s\t%s\tall\t%s\t%s\n' "$ts" "$pass" "$((fail + _T1288_PENDING_FAIL))" "$rc" "$dur" "$sha" "$fsum" "$qsum"
    fi
    for t in $T1288_TIERS; do
        [ -n "${T1288_RAN[$t]:-}" ] || continue
        [ "$T1288_TIER" = all ] || [ "$T1288_TIER" = "$t" ] || continue
        trc=0; [ "${T1288_FAIL[$t]}" -gt 0 ] && trc=1
        case "$rc" in 0|1) ;; *) trc="$rc" ;; esac   # an interrupted run marks every row interrupted
        printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$ts" "${T1288_PASS[$t]}" "${T1288_FAIL[$t]}" "$trc" \
            "${T1288_SECS[$t]}" "$sha" "$t" "${T1288_FLAKY[$t]}" "${T1288_QUAR[$t]}"
    done
}
