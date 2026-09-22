#!/usr/bin/env python3
"""_t821-swallowed-failure-census.py — every swallowed failure in src/ is instrumented or
explicitly excused, and nothing is merely forgotten.

T-821 (F-05). The editor had 46 `catch (_) {}` sites and no error surface. T-821 instrumented
the ones it judged meaningful — and THAT judgement is the thing that cannot audit itself.
PL-288: "a chosen-set assertion cannot find what you forgot to choose." A guard that checks
the sites I remembered proves only that I remembered them.

So this enumerates EVERY catch in the file and demands each be one of:

  INSTRUMENTED — its body calls aefRecordFault(). The failure leaves a trace.
  EXCUSED      — it matches an entry in EXCUSES below, WITH A WRITTEN REASON and an exact
                 expected count. Silence is sometimes right; it is never right unexamined.
  FINDING      — everything else. A failure the product still swallows without a decision.

THE COUNTS ARE LOAD-BEARING. An excuse is keyed to a normalised source line AND the number
of times it may appear. Add a fifth copy of an excused one-liner and this goes red, because
"this pattern is fine" is a claim about the sites that existed when it was written. Without
the count an excuse becomes a licence, which is how an excuse list rots into a blindfold.

KNOWN LIMIT, stated so a clean run cannot imply coverage it does not have: an excuse is
keyed to the catch's SOURCE LINE, so re-formatting an excused site (inlining it into a
wrapper, splitting it across lines) produces a signature this table does not hold and the
site lands as a FINDING. The error is toward false findings, never toward false silence —
a reformatted site is re-examined rather than quietly inherited — which is the direction
this instrument should fail in. It still means a reformat costs someone a re-read.

Exit: 0 all sites accounted for | 1 findings | 3 could-not-measure
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, '..', 'src', 'aef-workflow-designer.html')

# signature -> (expected_count, reason)
# The signature is the catch's own source line, whitespace-collapsed.
EXCUSES = {
    # --- geometry probes whose failure IS the documented fallback ------------------
    "try { return svg.getScreenCTM().a; } catch (_) { return 1; }":
        (1, "getScreenCTM throws only on a detached/hidden SVG; scale 1 is the correct "
            "answer in that state, not a degraded one. Recording it would fire on every "
            "headless render and train the operator to ignore the badge."),
    "try { scale = svg.getScreenCTM().a || 1; } catch (_) { /* keep 1 */ }":
        (1, "same condition and same correct fallback as the getScreenCTM site above."),
    "let tw = 0; try { tw = t.getBBox().width; } catch (_) { tw = badgeText.length * 6; }":
        (1, "getBBox throws on an unrendered node; the character estimate is a deliberate "
            "approximation with a known error, not a failure to report."),
    "try { bb = svg.getBBox(); } catch (_) { bb = null; }":
        (1, "null bb is handled by the caller as 'nothing to fit', which is true when the "
            "canvas is empty — indistinguishable from the throw and equally correct."),
    # --- environment interrogation, where the throw IS the answer -------------------
    "function _aefEmbedded() { try { return !!window.parent && window.parent !== window; } catch (_) { return true; } }":
        (1, "a cross-origin parent throws on access; that throw is precisely how you learn "
            "you ARE embedded. Reporting it would record a fault on the healthy path."),
    "try { return new URLSearchParams(location.search).get('load') || null; } catch (_) { return null; }":
        (1, "no ?load parameter is the common case, not a fault."),
    # --- user-initiated, already visible to the operator ----------------------------
    "if (el.requestFullscreen) { try { el.requestFullscreen().catch(() => {}); } catch (_) {} }":
        (2, "fullscreen refusal is enacted by the browser in front of the operator — the "
            "screen visibly does not change. A second channel adds nothing."),
    "try { document.exitFullscreen().catch(() => {}); } catch (_) {}":
        (2, "as above, in the other direction. TWO sites: the census caught that my reason "
            "was written against one while the file has two — exactly the count check "
            "earning its place on its first run."),

    # --- the recorder's own internals. It cannot report its own failure without recursing,
    #     and a recorder that throws breaks every catch it is called from — the one outcome
    #     worse than the silence T-821 removed. This is the single place where silence
    #     remains the correct answer, and it is stated here rather than assumed.
    "try { localStorage.setItem(FAULT_KEY, JSON.stringify(_faults)); } catch (_) {}":
        (1, "the fault being recorded may BE localStorage refusing writes; the in-memory "
            "ring still holds it, so this session's surface stays correct."),
    "try { localStorage.removeItem(FAULT_KEY); } catch (_) {}":
        (1, "clearing is the operator's own gesture and its failure is visible: the badge "
            "stays."),
    "try { renderFaultIndicator(); } catch (_) {}":
        (2, "a DOM write during teardown or before the header exists; the ring is already "
            "updated, so the record survives and the next render shows it."),
    "} catch (_) { /* the recorder is the one place silence is still the correct answer */ }":
        (1, "outer guard of aefRecordFault — see the note at the function."),
    "} catch (_) { _faults = []; }":
        (1, "restoring a corrupt fault ring at init. Recording THAT would write the ring "
            "we just failed to read; an empty ring is the honest state."),

    # --- display formatting with a correct fallback --------------------------------
    "try { when = new Date(f.ts).toLocaleString(); } catch (_) { when = String(f.ts); }":
        (1, "toLocaleString on an exotic locale; the raw timestamp is still the same fact, "
            "less prettily."),
    "let when = ''; try { when = new Date(e.ts).toLocaleString(); } catch (_) {}":
        (1, "as above; an empty date column loses formatting, not information."),
    "let when = ''; try { when = new Date(s.ts).toLocaleString(); } catch (_) {}":
        (1, "as above."),

    # --- the throw IS the negative answer ------------------------------------------
    "} catch (_) { /* fall through to not-found */ }":
        (1, "the lookup failing and the thing being absent are the same outcome for the "
            "caller, which handles not-found as a normal state."),
    "} catch (_) { /* fall through */ }":
        (1, "same shape: the caller's next branch is the correct handling either way."),
    "} catch (err) { /* fall back to far-anchor keys */ }":
        (1, "an alternative key strategy, chosen deliberately; both paths are supported "
            "and neither is a degraded mode."),
    "} catch (_) { /* detached / headless — fall back to node-box floor */ }":
        (1, "fires on every headless render. Recording it would put a permanent badge on "
            "a healthy editor and teach the operator to dismiss it — OBS-293's shape."),
    "} catch (_) { /* static gallery — leave the button hidden */ }":
        (1, "probing for a write-capable sidecar. Absence is the documented static-gallery "
            "deployment, not a fault."),
    "} catch (_) { /* skip non-styleable nodes */ }":
        (1, "iterating nodes to inline computed styles; text and comment nodes have none. "
            "Expected on every single run."),
    "try { host = gNodes.querySelector(\'g[data-id=\"\' + CSS.escape(a.uid) + \'\"]\'); } catch (_) { host = null; }":
        (1, "a malformed uid from the annotation seam; null host is handled as 'no such "
            "node', which is the truth."),
    "function snapshotState() { try { return buildBpmnXml(state); } catch (_) { return null; } }":
        (1, "called with state possibly null during init; null is the caller's "
            "no-snapshot-available signal and is checked."),
    "try { root.querySelectorAll(\'.aef-annotation\').forEach(e => e.remove()); } catch (_) {}":
        (1, "clearing annotations from a root that may already be detached; nothing is "
            "lost that was not already gone."),
    "} catch (_) { resolve(null); }":
        (2, "thumbnail capture promise; null is the documented 'no thumbnail' value and "
            "the save proceeds without one, which the server accepts."),
    "} catch (_) { /* best-effort — unresolved refs just keep the picker path */ }":
        (1, "a uuid index refresh; failing leaves the operator on the picker, which is the "
            "path they would have taken anyway."),

    # --- already reported through another channel ----------------------------------
    "const data = await res.json().catch(() => ({}));":
        (1, "a non-JSON body from the sidecar. The caller checks res.ok and alerts AND "
            "records on failure, so this catch only shapes the message."),
    "const d = await res.json().catch(() => ({}));":
        (3, "as above, at three call sites that each alert and record on !ok."),
    "} catch (_) { /* toast is best-effort */ }":
        (1, "the toast is itself a notification surface; its failure cannot be usefully "
            "reported by showing a notification."),
    "} catch (_) { /* server check is best-effort; base toast already shown */ }":
        (1, "an enrichment on a message the operator has already been shown."),
    "try { localStorage.removeItem(AUTOSAVE_KEY); } catch (_) {}":
        (1, "discarding a restored autosave the operator declined; a failure here means "
            "the offer reappears next load, which is visible and self-correcting."),
    "try { createNewWorkflow(); } catch (_) {}":
        (1, "the fallback after declining a restore. Its own failure leaves the canvas as "
            "it is, which the operator sees directly."),
}

def norm(line):
    return re.sub(r'\s+', ' ', line).strip()

def _code_mask(text):
    """True at every index that is real code — not a comment, string or template literal.

    A small state machine rather than a regex: the thing being excluded (a comment that
    quotes code) is exactly what a regex cannot see past.
    """
    mask = [True] * len(text)
    i, n = 0, len(text)
    state = None          # None | '//' | '/*' | "'" | '"' | '`'
    while i < n:
        c = text[i]
        nxt = text[i + 1] if i + 1 < n else ''
        if state is None:
            if c == '/' and nxt == '/':
                state = '//'
            elif c == '/' and nxt == '*':
                state = '/*'
            elif c in ('"', "'", '`'):
                state = c
            if state is not None:
                mask[i] = False
                if state in ('//', '/*'):
                    mask[i + 1] = False
                    i += 2
                    continue
        else:
            mask[i] = False
            if state == '//' and c == '\n':
                state = None
            elif state == '/*' and c == '*' and nxt == '/':
                mask[i + 1] = False
                state = None
                i += 2
                continue
            elif state in ('"', "'", '`'):
                if c == '\\':
                    if i + 1 < n:
                        mask[i + 1] = False
                    i += 2
                    continue
                if c == state:
                    state = None
        i += 1
    return mask


def main():
    if not os.path.isfile(SRC):
        sys.stderr.write("COULD-NOT-MEASURE: source not found: %s\n" % SRC)
        return 3
    text = open(SRC, encoding='utf-8').read()
    lines = text.split('\n')

    code_mask = _code_mask(text)
    sites = []           # (lineno, signature, body)
    for m in re.finditer(r'\bcatch\s*\(', text):
        # Skip a `catch` that is not code. The first run of this census reported one of its
        # OWN documentation lines as a finding, because that comment quotes `catch (_) {}`
        # verbatim. A census that counts prose is not measuring the product, and the shape
        # of the mistake — a text scan that cannot tell a subject from a description of one
        # — is the same one _t451 documents about its own edge detector.
        if not code_mask[m.start()]:
            continue
        # brace-match the catch body so a multi-line handler is read whole
        i = text.find('{', m.end())
        if i < 0:
            continue
        depth, j = 0, i
        while j < len(text):
            if text[j] == '{':
                depth += 1
            elif text[j] == '}':
                depth -= 1
                if depth == 0:
                    break
            j += 1
        body = text[i:j + 1]
        lineno = text.count('\n', 0, m.start()) + 1
        sites.append((lineno, norm(lines[lineno - 1]), body))

    if not sites:
        sys.stderr.write("COULD-NOT-MEASURE: no catch sites found at all — the scan is "
                         "broken, not the source\n")
        return 3

    instrumented, excused_hits, findings = [], {}, []
    for lineno, sig, body in sites:
        if 'aefRecordFault' in body:
            instrumented.append((lineno, sig))
        elif sig in EXCUSES:
            excused_hits.setdefault(sig, []).append(lineno)
        else:
            findings.append((lineno, sig))

    print("=== T-821: swallowed failures in src/aef-workflow-designer.html ===")
    print()
    print("  catch sites            %4d" % len(sites))
    print("  instrumented           %4d  body calls aefRecordFault()" % len(instrumented))
    print("  excused                %4d  with a written reason below" % sum(len(v) for v in excused_hits.values()))
    print("  FINDINGS               %4d  swallowed without a decision" % len(findings))
    print()

    rc = 0

    # An excuse whose count moved is a finding in BOTH directions: more sites than the
    # reason was written against, or a site that no longer exists (the excuse is now
    # carrying weight for nothing and should be deleted, not left to cover a future one).
    for sig, (expected, reason) in EXCUSES.items():
        got = len(excused_hits.get(sig, []))
        if got != expected:
            rc = 1
            print("  EXCUSE COUNT MOVED  expected %d, found %d" % (expected, got))
            print("    %s" % sig[:110])
            print("    The reason on file was written against %d site(s). Re-read it against"
                  % expected)
            print("    the current ones and update BOTH the count and the reason, or instrument.")
            print()

    if findings:
        rc = 1
        print("FINDINGS — each of these swallows a failure with no record and no stated reason:")
        for lineno, sig in findings:
            print("  src/aef-workflow-designer.html:%d" % lineno)
            print("      %s" % sig[:120])
        print()
        print("  Either call aefRecordFault('<code>', e) in the handler, or add the line to")
        print("  EXCUSES in this file WITH A REASON. 'It never happens' is not a reason —")
        print("  that is the claim a bare catch makes and cannot support.")

    if rc == 0:
        print("every swallowed failure is instrumented or excused with a reason")
    return rc


if __name__ == '__main__':
    sys.exit(main())
