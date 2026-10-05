#!/usr/bin/env bash
# T-588 teeth — RETIRED with the differential (T-1045). See the header of
# tools/_t588-verification-extractor-differential.sh for why. The mutation discipline moved to the
# successors: _t943-heading-states.sh (restart-on-match mutant, shown red on 2026-10-05) and
# _t574-p011-block-locator-teeth.py (prefix-match and anchor mutants). Delegates, so the _t509 sweep
# still covers this name: exit 0 only if the retired differential's successors pass.
exec bash "$(dirname "${BASH_SOURCE[0]}")/_t588-verification-extractor-differential.sh" "$@"
