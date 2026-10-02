#!/usr/bin/env bash
# _t1000-revendor-gate.sh — the re-vendor protocol, enforced at commit time (832 T-1000, T-995 B4).
#
# WHY. Re-vendoring the framework was one undifferentiated overwrite. Local fixes to vendored
# code were reverted silently, twice (T-840 on 2026-09-25: >=4 fixes and the audit rail that
# would report it, T-944; the 1.7.740 upgrade, T-988: the T-952 rail). The divergence detector
# (tools/_t517) could not see it, because its baseline had never moved since v1.6.763: every
# upstream change looked like an unrecorded local change, and a lost fix looked like nothing.
#
# THE PROTOCOL (operator chose it 2026-10-02; proposed to AEF on conversation revendor-protocol):
#   1. PRISTINE COMMIT  the upgrade, exactly as the vendor wrote it, alone.
#   2. BASELINE ADVANCE .vendor-divergence.yaml baseline_commit := that commit. Now _t517 shows
#                       every declared local fix the upgrade overwrote as STALE, by name.
#   3. WORKLIST         tools/_t1000-revendor-worklist.py; re-apply / reclassify / drop each.
#   4. DONE             _t517 clean.
#
# WHAT THIS GATE ENFORCES (run from .git/hooks/pre-commit; see _t1000-install-hook.sh):
#   G1  a commit that changes .agentic-framework/VERSION may stage only .agentic-framework/ paths.
#   G2  right after a pristine commit (HEAD changed VERSION), every commit is refused unless it
#       sets baseline_commit to HEAD. Nobody carries on as if the upgrade were finished.
#   G3 (STALE > 0 fails the audit, a release refuses) lives in T-999 / T-998, not here.
#
# Override, logged: REVENDOR_GATE_OVERRIDE="<reason>" git commit ...
# Exit 0 = allowed, 1 = refused.
set -u
ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
cd "$ROOT" || exit 0
VF=.agentic-framework/VERSION
DIV=.agentic-framework/.vendor-divergence.yaml

refuse() {
    if [ -n "${REVENDOR_GATE_OVERRIDE:-}" ]; then
        mkdir -p .context/working
        printf '%s\t%s\t%s\n' "$(date -u +%FT%TZ)" "$1" "$REVENDOR_GATE_OVERRIDE" >> .context/working/revendor-gate-overrides.log
        echo "revendor-gate: $1 — OVERRIDDEN (logged): $REVENDOR_GATE_OVERRIDE" >&2
        exit 0
    fi
    echo "" >&2
    echo "REVENDOR GATE ($1) — commit refused (832 T-1000)" >&2
    shift
    for l in "$@"; do echo "  $l" >&2; done
    echo "  Protocol: tools/_t1000-revendor-gate.sh header; design docs/reports/T-1000-revendor-gate.md" >&2
    exit 1
}

git rev-parse -q --verify HEAD >/dev/null || exit 0           # first commit: nothing to compare
v_head=$(git show "HEAD:$VF" 2>/dev/null | tr -d '[:space:]')
v_idx=$(git show ":$VF" 2>/dev/null | tr -d '[:space:]')

# --- G1: an upgrade commit is pristine: vendored paths only -----------------------------------
if [ -n "$v_idx" ] && [ "$v_idx" != "$v_head" ]; then
    outside=$(git diff --cached --name-only | grep -v '^\.agentic-framework/' | head -5)
    if [ -n "$outside" ]; then
        refuse "G1" \
            "This commit changes the framework VERSION ($v_head -> $v_idx), so it is the PRISTINE vendor" \
            "commit (protocol step 1) and must contain only .agentic-framework/ paths. Also staged:" \
            $outside \
            "Unstage them (git restore --staged <path>) and commit them after the baseline advance."
    fi
    exit 0
fi

# --- G2: right after a pristine commit, only the baseline advance may follow ------------------
v_parent=$(git show "HEAD^:$VF" 2>/dev/null | tr -d '[:space:]')
if [ -n "$v_parent" ] && [ -n "$v_head" ] && [ "$v_parent" != "$v_head" ]; then
    head_sha=$(git rev-parse HEAD)
    staged_base=$(git show ":$DIV" 2>/dev/null | sed -n 's/^baseline_commit:[[:space:]]*["'\'']\{0,1\}\([0-9a-f]\{7,40\}\).*/\1/p' | head -1)
    case "$head_sha" in
        "$staged_base"*) [ -n "$staged_base" ] && exit 0 ;;
    esac
    refuse "G2" \
        "HEAD ($(git rev-parse --short HEAD)) is a pristine vendor commit (framework $v_parent -> $v_head)," \
        "and the divergence baseline has not been advanced to it. Until it is, tools/_t517 cannot" \
        "tell a lost local fix from an upstream change. Protocol step 2: set" \
        "  baseline_commit: $head_sha" \
        "in $DIV and commit that alone; then run tools/_t1000-revendor-worklist.py."
fi
exit 0
