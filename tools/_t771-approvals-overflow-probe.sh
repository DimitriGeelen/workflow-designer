#!/usr/bin/env bash
# T-771 — what the /approvals overflow disclosure actually hides.
#
# The operator went to /approvals to rule on five items gating Arc-0 and reported there
# was "nothing to do". The page was not empty: it was 454KB and contained all five. They
# sat behind a <details> that renders CLOSED by default, whose summary reads:
#
#     "N more verifications — lower priority, all still actionable"
#
# This probe measures whether that label is true of what it hides. It is not.
#
# The list is sorted by (sort_priority ASC, age_days DESC) — approvals.py:370 — and then
# cut positionally at 10 (_approvals_content.html:496). A positional cut through a sorted
# list is not a priority boundary: when one priority group is larger than the cap, the
# group straddles the cut and the hidden half gets described as lower priority than the
# visible half it is identical to.
#
# Second-order effect, and the one that bit: the secondary key is age DESCENDING, oldest
# first. So a ruling filed today sorts to the BOTTOM of its priority group. The newer and
# more urgent a ruling is, the more reliably it is hidden.
#
# Usage:
#   ./tools/_t771-approvals-overflow-probe.sh              # measure the live page
#   ./tools/_t771-approvals-overflow-probe.sh --self-test  # fixtures + negative controls
set -o pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CUT_MARKER='details class="ac-overflow"'

die() { echo "FAIL: $*" >&2; exit 1; }

# measure <html-file> — prints "visible_p0 collapsed_p0 collapsed_total"
measure() {
    local html="$1"
    local cut
    cut=$(grep -b -o "$CUT_MARKER" "$html" | head -1 | cut -d: -f1)
    if [ -z "$cut" ]; then
        # No disclosure rendered at all: nothing is hidden.
        echo "$(grep -c 'data-priority="0"' "$html" 2>/dev/null || echo 0) 0 0"
        return 0
    fi
    grep -b -o 'data-priority="[0-9]"' "$html" \
      | awk -F'[:"]' -v cut="$cut" '
          { if ($1+0 < cut) { if ($3=="0") vis0++ } else { hid++; if ($3=="0") hid0++ } }
          END { printf "%d %d %d\n", vis0+0, hid0+0, hid+0 }'
}

self_test() {
    local tmp fails=0
    tmp=$(mktemp -d) || die "mktemp"
    trap 'rm -rf "$tmp"' EXIT

    # Fixture A: the defect shape — top-priority items on BOTH sides of the cut.
    {
      echo '<div data-priority="0">visible</div>'
      echo '<div data-priority="0">visible</div>'
      echo '<details class="ac-overflow">'
      echo '<div data-priority="0">hidden but top priority</div>'
      echo '<div data-priority="2">hidden, genuinely lower</div>'
      echo '</details>'
    } > "$tmp/defect.html"

    read -r v0 h0 ht < <(measure "$tmp/defect.html")
    if [ "$v0" = "2" ] && [ "$h0" = "1" ] && [ "$ht" = "2" ]; then
        echo "ok   defect shape: 2 visible p0, 1 collapsed p0 of 2 collapsed"
    else
        echo "FAIL defect shape: got $v0/$h0/$ht want 2/1/2"; fails=$((fails+1))
    fi

    # Fixture B — NEGATIVE CONTROL. Same page, but the cut falls on a real priority
    # boundary: nothing top-priority is hidden. The probe must report 0 hidden p0, or it
    # is reporting the defect regardless of input and asserting nothing (PL-178).
    {
      echo '<div data-priority="0">visible</div>'
      echo '<details class="ac-overflow">'
      echo '<div data-priority="2">hidden, genuinely lower</div>'
      echo '</details>'
    } > "$tmp/clean.html"

    read -r v0 h0 ht < <(measure "$tmp/clean.html")
    if [ "$h0" = "0" ] && [ "$ht" = "1" ]; then
        echo "ok   negative control: clean cut reports 0 collapsed top-priority"
    else
        echo "FAIL negative control: got hidden_p0=$h0 hidden_total=$ht want 0/1"; fails=$((fails+1))
    fi

    # Fixture C — NEGATIVE CONTROL. No disclosure at all; nothing may be reported hidden.
    echo '<div data-priority="0">visible</div>' > "$tmp/nodisclosure.html"
    read -r v0 h0 ht < <(measure "$tmp/nodisclosure.html")
    if [ "$ht" = "0" ]; then
        echo "ok   negative control: no disclosure reports nothing hidden"
    else
        echo "FAIL negative control: got hidden_total=$ht want 0"; fails=$((fails+1))
    fi

    # The two source constants the finding rests on must still be where it says they are.
    if grep -q '_ac_cap = 10' "$PROJECT_ROOT/.agentic-framework/web/templates/_approvals_content.html"; then
        echo "ok   positional cap is 10 (_approvals_content.html)"
    else
        echo "FAIL positional cap constant moved"; fails=$((fails+1))
    fi
    if grep -q 'sort_priority.*-t\["age_days"\]' "$PROJECT_ROOT/.agentic-framework/web/blueprints/approvals.py"; then
        echo "ok   secondary sort is age descending (approvals.py)"
    else
        echo "FAIL secondary sort key changed — re-derive the finding"; fails=$((fails+1))
    fi

    echo
    [ "$fails" -eq 0 ] && { echo "SELF-TEST PASSED — 5 legs, 2 of them negative controls"; return 0; }
    echo "SELF-TEST FAILED ($fails)"; return 1
}

[ "${1:-}" = "--self-test" ] && { self_test; exit $?; }

URL_BASE=$(cat "$PROJECT_ROOT/.context/working/watchtower.url" 2>/dev/null)
[ -n "$URL_BASE" ] || die "no watchtower.url — cannot fetch the page (PL-260: do not cite a queue you have not fetched)"

HTML=$(mktemp) || die "mktemp"
trap 'rm -f "$HTML"' EXIT
curl -sf "$URL_BASE/approvals" -o "$HTML" || die "could not fetch $URL_BASE/approvals"

read -r VIS0 HID0 HIDT < <(measure "$HTML")

echo "/approvals — what the collapsed disclosure hides"
echo
echo "  top-priority (unchecked [REVIEW]) visible : $VIS0"
echo "  top-priority collapsed                    : $HID0"
echo "  collapsed in total                        : $HIDT"
echo
if [ "$HIDT" -gt 0 ]; then
    PCT=$(( HID0 * 100 / HIDT ))
    echo "  The summary calls all $HIDT of them \"lower priority\"."
    echo "  $PCT% of them are in the SAME top-priority group as the $VIS0 shown above it."
fi
echo
echo "  Operator route that does not depend on the default view:"
echo "    $URL_BASE/approvals?expand=verifications"
exit 0
