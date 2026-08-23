#!/usr/bin/env python3
"""
T-361 — our exported bytes must not make claims about anybody else.

WHAT HAPPENED
-------------
For two months every `.bpmn` we exported carried, verbatim:

    <!-- BPMN DI (visual layout) omitted in this demo;
         AEF generates it from node coordinates -->

AEF does not. They measured their own source (rail 417): `bpmndi` occurs exactly
once in it, `tools/corpus_spec.py:347`, a namespace declaration with no reader and
no writer behind it. They never parsed DI, never emitted it, and hold no record of
ever agreeing to. There is no DI generator on our side either — so the sentence had
no referent anywhere. It shipped in 11 releases inside bytes AEF pins by sha,
including the 0.4.0 they are pinned to today, and into 106 stored documents.

WHY NOTHING CAUGHT IT
---------------------
Two reasons, and the second is the general one.

1. `DI_TRAILER` was defined and read by NOTHING. The emitter carried its own
   hardcoded duplicate, while a comment above the constant claimed the two "share
   one source of truth". They agreed by coincidence, not by construction.

2. PL-034: a guard that checks INTERNAL SELF-CONSISTENCY cannot detect a broken
   promise. Every internal check passed, because the emitter and its own constant
   were in perfect agreement about a sentence that was false outside the process.
   The string had even been through a two-party incident already (their T-2682
   reader guard, their T-2683 restore, our readDocComment guard). Both
   investigations asked WHERE the comment appears. Neither asked whether it was
   TRUE. An incident directs attention rather than distributing it.

WHAT THIS GUARD ACTUALLY CHECKS — and what it cannot
----------------------------------------------------
CAN:  that the emitter derives from the constant instead of duplicating it;
      that the trailer preserves the compatibility prefix;
      that the trailer attributes no action to a NAMED EXTERNAL PARTY;
      that real produced .bpmn bytes carry the approved tail, with legacy
      documents exempt only by recorded sha.

CANNOT: judge whether an arbitrary sentence is true. A subtly false claim that
      names nobody would pass. That limit is stated rather than papered over —
      the rule here is the narrower, checkable one: WE DESCRIBE OUR OWN BYTES AND
      NAME NO ONE ELSE'S BEHAVIOUR. That is what made this instance findable at
      all, and it is enforceable; "is it true" is not.
"""

import hashlib
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "src", "aef-workflow-designer.html")
LEDGER = os.path.join(ROOT, "tests", "data", "t361-legacy-di-trailer.txt")

# Test-only redirection, used ONLY by _t361-guard-teeth.py to point this guard at a
# mutated copy of the tree. Unset in the gating runner, so the leg always measures
# the real source. These are not a bypass: they cannot make a failing check pass on
# the real tree, only make the guard examine a deliberately broken one.
SRC = os.environ.get("T361_SRC", SRC)
ROOT = os.environ.get("T361_ROOT", ROOT)
LEDGER = os.environ.get("T361_LEDGER", LEDGER)

# Parties on the other side of a seam from us. We may talk ABOUT them in source
# comments all day; we may not put a claim about them in bytes we hand to them.
EXTERNAL_PARTIES = ["AEF", "bpmn.io", "Camunda", "Zeebe", "Bizagi", "Signavio",
                    "Enterprise Composer", "Activiti", "Flowable"]

failures = []


def check(ok, msg, detail=""):
    if ok:
        print(f"  ok   {msg}")
    else:
        print(f"  FAIL {msg}")
        if detail:
            for line in str(detail).splitlines()[:6]:
                print(f"       {line}")
        failures.append(msg)


def main():
    src = open(SRC, encoding="utf-8").read()

    # ── source: the constants ───────────────────────────────────────────────
    m_pref = re.search(r"const DI_TRAILER_PREFIX = '([^']*)';", src)
    m_trail = re.search(r"const DI_TRAILER = `([^`]*)`;", src)
    check(bool(m_pref), "DI_TRAILER_PREFIX is defined")
    check(bool(m_trail), "DI_TRAILER is defined")
    if not (m_pref and m_trail):
        return finish()

    prefix = m_pref.group(1)
    trailer = m_trail.group(1).replace("${DI_TRAILER_PREFIX}", prefix)

    # T-399: producer identity, derived from src for the same reason the trailer is
    # — a hardcoded copy here would agree with the emitter by coincidence, which is
    # the precise mechanism that let the false trailer survive a repair for two
    # months (see this file's header, reason 1).
    m_exp = re.search(r"const BPMN_EXPORTER = '([^']*)';", src)
    check(bool(m_exp), "BPMN_EXPORTER is defined")
    if not m_exp:
        return finish()
    exporter = m_exp.group(1)

    check(trailer.startswith(prefix),
          "trailer preserves the compatibility prefix",
          f"prefix={prefix!r} trailer={trailer!r}")

    # A bare substring match is WRONG here and this guard proved it on its own
    # first run: it fired on `aef:position`, which is a namespace prefix inside
    # our own bytes, not a claim about anybody. An over-broad matcher manufactures
    # findings, and a guard that cries wolf about a legitimate token gets widened
    # or deleted — which is how the real rule dies.
    #
    # The distinction that matters: `aef:` is a NAMESPACE TOKEN naming a field in
    # our document. A bare `AEF` in a sentence is a CLAIM ABOUT A PARTY. So: the
    # name must appear as a standalone word that is NOT immediately followed by
    # ':'.
    named = [p for p in EXTERNAL_PARTIES
             if re.search(rf"(?<!\w){re.escape(p)}(?!\w)(?!:)", trailer, re.I)]
    check(not named,
          "trailer attributes no action to a named external party",
          f"names {named} in {trailer!r} — we describe our own bytes, not theirs")

    # ── source: the emitter must DERIVE, not duplicate ──────────────────────
    # This is the structural half. A duplicate literal is how the false sentence
    # survived a repair to the constant for two months.
    #
    # T-423 CHANGED THE EXPECTED STATE, and the change is why this is a disjunction
    # rather than a relaxation. DI is now emitted unconditionally, so the trailer — whose
    # entire claim is "DI is OMITTED" — has NO emit site at all. Zero is now correct.
    #
    # The lazy way to absorb that is to drop the `derived and` half and keep
    # `not duplicated`. Do not: that predicate is also satisfied by a file with no
    # emitter in it, by a renamed constant, and by a typo in the matcher — the
    # absence-assertion-satisfied-by-silence shape this suite pins under T-560. So state
    # both admissible worlds explicitly, and REPORT WHICH ONE HELD, so a reader can see
    # the difference between "nothing is emitted" and "the matcher found nothing".
    emit_lines = [l for l in src.splitlines()
                  if "lines.push" in l and "BPMN DI" in l.replace("${DI_TRAILER}", "BPMN DI")]
    derived = [l for l in emit_lines if "${DI_TRAILER}" in l]
    duplicated = [l for l in emit_lines if "${DI_TRAILER}" not in l]
    arm = ("not emitted at all (T-423: DI is unconditional)" if not emit_lines
           else f"{len(derived)} emit site(s), all derived" if derived and not duplicated
           else f"{len(duplicated)} DUPLICATED literal(s)")
    check(not duplicated,
          "the trailer is either not emitted, or every emit site derives it from DI_TRAILER"
          f" — {arm}",
          "\n".join(duplicated))

    # No stray hardcoded copy of the prefix anywhere outside the two constants.
    stray = [l for l in src.splitlines()
             if prefix in l
             and "DI_TRAILER_PREFIX = " not in l
             and "//" not in l.split(prefix)[0][-4:]]
    check(not stray,
          "no stray hardcoded copy of the trailer prefix in code",
          "\n".join(stray[:4]))

    # T-399: the identity marker gets the same derive-don't-duplicate treatment as
    # the trailer. It is now load-bearing for THIS guard's scope, so a literal in the
    # emitter that drifts from the constant would silently empty the guard's net
    # rather than merely mis-word a comment.
    exp_emit = [l for l in src.splitlines() if "lines.push" in l and "exporter=" in l]
    check(exp_emit and all("${BPMN_EXPORTER}" in l for l in exp_emit),
          "emitter derives the exporter attribute from BPMN_EXPORTER",
          "\n".join(l for l in exp_emit if "${BPMN_EXPORTER}" not in l)
          or "no exporter emit site found")

    # ── real produced bytes ─────────────────────────────────────────────────
    # A source check proves the string was EDITED. It does not prove any shipped
    # artifact stopped saying it. So walk the documents we actually exported.
    ledger = {}
    if os.path.exists(LEDGER):
        for line in open(LEDGER, encoding="utf-8"):
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            sha, path = line.split(None, 1)
            ledger[path] = sha
    check(bool(ledger), f"legacy ledger loaded ({len(ledger)} documents)")

    # ── who wrote it: the two positive identity arms (T-399) ────────────────
    # Scope used to be `prefix in body` — "contains our trailer PREFIX" standing in
    # for "we exported this". Prose collides: AEF's fixture opens its DI comment with
    # the same eight words because it describes the same fact in the same domain
    # vocabulary. It failed in the UNSAFE direction, reporting a foreign document as
    # an unaccounted export of ours, sending any reader after an emitter bug that
    # does not exist.
    #
    # Two arms, because our exports come in two generations and only one of them can
    # ever carry a marker we added today:
    #
    #   FORWARD   the standard `exporter` attribute, emitted by buildBpmnXml.
    #   HISTORIC  the document's PATH appears in the legacy ledger.
    #
    # The historic arm is keyed on PATH and the exemption below stays keyed on SHA,
    # and the split is deliberate. It is what preserves the ledger's stated design
    # (its own header: "Changing the bytes moves the sha, drops it out of the ledger,
    # and puts it back under the live rule"): a re-export at a ledgered path is still
    # in scope by path, and no longer exempt by sha, so it lands in offenders. Keying
    # scope on sha instead would let a re-export escape the guard entirely — the
    # exemption would become a silence with a filename, which is exactly what
    # _t361-guard-teeth.py case 5 exists to forbid.
    #
    # Known and accepted limit: a legacy document HAND-EDITED to a path not in the
    # ledger leaves scope. It is no longer bytes we produced, and no available signal
    # distinguishes it from a foreign document without reintroducing prose matching.
    def is_ours(rel, body):
        return (f'exporter="{exporter}"' in body) or (rel in ledger)

    offenders, legacy_ok, current_ok = [], 0, 0
    for dirpath, dirnames, filenames in os.walk(ROOT):
        dirnames[:] = [d for d in dirnames if d not in (".git", "node_modules")]
        for fn in filenames:
            if not fn.endswith(".bpmn"):
                continue
            full = os.path.join(dirpath, fn)
            rel = os.path.relpath(full, ROOT)
            try:
                body = open(full, encoding="utf-8", errors="replace").read()
            except OSError:
                continue
            if not is_ours(rel, body):
                continue
            if prefix not in body:
                continue
            if trailer in body:
                current_ok += 1
                continue
            sha = hashlib.sha256(open(full, "rb").read()).hexdigest()
            if ledger.get(rel) == sha:
                legacy_ok += 1          # exempt, and the exemption is pinned to these bytes
            else:
                offenders.append(rel)

    print(f"       documents: {current_ok} current, {legacy_ok} legacy-exempt, "
          f"{len(offenders)} unaccounted")

    # ANTI-VACUITY (T-399). Narrowing scope is how this repair could go wrong: an
    # identity test that resolves nothing makes the offender list empty and the guard
    # green, and the output would be indistinguishable from a clean tree. Assert the
    # net still catches documents — BOTH arms, since a break in either one is
    # invisible while the other still resolves something.
    check(current_ok > 0,
          "forward identity arm resolves at least one document (exporter attribute)")
    check(legacy_ok > 0,
          "historic identity arm resolves at least one document (ledger path)")

    check(not offenders,
          "every exported document carries the approved trailer or is a pinned legacy record",
          "\n".join(offenders[:8]))

    return finish()


def finish():
    print()
    if failures:
        print(f"FAIL — {len(failures)} check(s) failed")
        return 1
    print("PASS — emitted comments describe our own bytes and name no one else's behaviour")
    return 0


if __name__ == "__main__":
    sys.exit(main())
