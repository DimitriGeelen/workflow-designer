# T-1107 — Permanent cross-hub credential model for peer agents (field survey)

**Status:** inception, research in progress · **Stopgap meanwhile:** T-1106 (full hub secret, out of band)

## Question

Two independently operated TermLink hubs (ours, 192.168.10.107; Greenfield's, 192.168.10.132), each
run by a different operator, need their agents to message each other in both directions. Today the
only credential TermLink offers for this is the **whole-hub secret**: a 32-byte shared key that grants
everything on that hub. Scoped capability tokens exist but are per session and short-lived (1 h default),
so they do not fit a standing peer link.

How do comparable systems in the field let independently operated nodes trust each other, and what
should 832 propose (to TermLink / AEF) as the permanent measure?

## Constraints we already know

- Credentials never travel over the channel they unlock (operator, 2026-10-08).
- Provisioning is the operator's decision (sovereignty); the agent prepares, the operator runs (runme).
- The peer hub holds a client's confidential maps: least privilege matters more than convenience.
- Must keep working offline/LAN-only (no mandatory cloud identity provider), per Portability.
- Revocation must be possible by either side without the other's cooperation.

## Survey (filled by the research worker)

_pending_

## Options for 832 / TermLink

_pending_

## Recommendation

_pending — DEFER until the survey is in_

## Dialogue Log

- 2026-10-09, operator: chose option 1 (full hub secret out of band) as the immediate measure, and asked:
  "we do need to find a permanent measure to get this done. Could we research how this is often done also
  in the field with similar solutions?" → this inception.
