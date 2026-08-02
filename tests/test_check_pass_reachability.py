#!/usr/bin/env python3
"""T-333 — can each validator rule PASS at all? (AEF OBS-124 counterpart)

AEF's rail-380 observation: a 19-hook validator bug survived for weeks not
because of the missing `${CLAUDE_PROJECT_DIR}` expansion, but because the
check's PASSING STATE WAS UNREACHABLE for the config their own framework
generates -- `os.path.exists("bash")` is False for every wrapper hook, so the
check failed on 100% of runs, carried no information, and read as decoration.
Their installer exits 0 while printing "completed with validation errors", so
nothing could gate on it even in principle.

Two duals, and this arc had instrumented only one:

    vacuous pass     the check never evaluates      reads as confirmation
    unreachable pass the check never passes         reads as decoration

Teeth (T-321/T-327), discrimination probes (T-329) and PAIRED_SAME_ID (T-331)
all attack the first. Nothing attacked the second. This harness does.

WHY THE GATING SUITES DO NOT ALREADY COVER IT. They come close: the runners
exit non-zero, the gating runner and P-011 consume that exit code, and they are
green -- so no assertion inside them is in a permanent-fail state. That is not
discipline, it is that the exit code is wired. But green proves only NO
PERMANENT-FAIL. It does not prove a rule's two branches are BOTH reachable, and
a validator rule is not an assertion in a suite: it is a predicate over
documents, and it can fire on every document that exists without any suite
noticing, because firing is not failing.

THE MECHANICAL QUESTION, per rule:

    is there a reachable input where it does NOT fire, and one where it DOES?

  - never silent  ->  ALWAYS-FIRES.  The pass branch is unreachable. AEF's shape.
  - never fires   ->  NEVER-WITNESSED. No evidence the fire branch works at all.

TWO THINGS THIS HARNESS IS CAREFUL ABOUT, both learned the hard way on this arc:

(1) The population is read from the validator SOURCE via ast, not from what the
    corpus happens to emit. A rule that never fires must APPEAR in the report;
    if the population were "rules seen firing", a never-firing rule would be
    absent, and absence would be carrying the decision (T-331).

(2) Denominators are FORM-SCOPED. A yaml-only rule firing on 100% of yaml
    documents is silent on every bpmn document, so a pooled denominator files
    it under both-branches and hides the always-fires case it actually is.
    This harness HAD that defect; the teeth below caught it (see T-333).

Scope is resolved with ast rather than by splitting the source at
`class XmlValidator` -- run_yaml() is DEFINED BELOW that class, so a span split
classifies every module-level function as xml, and E-YAML-PARSE gets measured
against the 89 bpmn documents it can never reach.
"""
import ast
import glob
import importlib.util
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
VALIDATOR = os.path.join(ROOT, "tools", "validate-workflow.py")


def _load(path, name):
    spec = importlib.util.spec_from_file_location(name, path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


vw = _load(VALIDATOR, "validate_workflow")

# ---------------------------------------------------------------------------
# Which document form can reach each top-level scope. TOTAL and EXPLICIT: a
# scope that emits rule ids and is not listed here is an ERROR, never a silent
# default. An unlisted scope would otherwise be measured against the wrong
# document population and report a false never-witnessed (T-331).
# ---------------------------------------------------------------------------
SCOPE_FORM = {
    "Validator":     "yaml",
    "run_yaml":      "yaml",
    "XmlValidator":  "xml",
    "run_xml":       "xml",
    "main":          "both",   # file-load errors are form-independent
    "detect_format": "both",
}

# ---------------------------------------------------------------------------
# Declared NEVER-WITNESSED. Counted tolerance, printed every run.
#
# Each entry is a rule with a live predicate that no corpus document and no
# fixture has ever made fire. That is NOT the same as a parity gap (a rule
# missing on one form); it is a rule PRESENT on its form whose firing branch
# has never been observed to work.
#
# All six are ALSO declared parity gaps in test_rule_form_parity.py, and the
# overlap is the finding: the parity NOTE argues priority from carrier counts
# on the form that has NO rule ("aef:constituents carried by 23/96 bpmn") while
# the form that HAS the rule has zero witnessed firings. The gap is between an
# unwitnessed rule and no rule -- which is a weaker claim than the NOTE reads
# as, and neither harness said so until this one.
#
# To close an entry: author a fixture that makes it fire, then delete the line.
# The count assertion below goes red either way, so this cannot rot silently.
# ---------------------------------------------------------------------------
NEVER_WITNESSED = {
    "E-CONST-DUP":        "aef:constituents duplicate; no yaml corpus map or fixture carries constituents",
    "E-CONST-SHAPE":      "aef:constituents malformed; same missing carrier",
    "W-CONST-FIELD":      "aef:constituents field check; same missing carrier",
    "E-SCOPEOF-DANGLING": "aef:scopeOf target missing; 0 authored scopeOf carriers on the yaml form",
    "E-SCOPEOF-SELF":     "aef:scopeOf self-reference; same missing carrier",
    "W-SCOPEOF-TYPE":     "aef:scopeOf on a node type that cannot carry it; same missing carrier",
}
EXPECTED_NEVER_WITNESSED = 6

CORPUS_GLOBS = (
    "examples/aef-processes/*.workflow.yaml",
    "examples/aef-processes/rendered/*.bpmn",
    "build/aef-corpus-drop/*.bpmn",
    "tests/fixtures/aef-bpmn/*.bpmn",
)
FIXTURE_GLOBS = (
    "tests/fixtures/invalid/*",
    "tests/fixtures/warn/*",
    "tests/fixtures/valid/*",
)

RULE_RE = re.compile(r"^(?:E|W|I|O)-[A-Z0-9-]+$")


def rule_forms(source_path):
    """Map every rule id the source can emit to the document form(s) that reach it."""
    tree = ast.parse(open(source_path, encoding="utf-8").read())
    forms, unclassified = {}, set()
    for top in tree.body:
        if not isinstance(top, (ast.ClassDef, ast.FunctionDef)):
            continue
        ids = {n.value for n in ast.walk(top)
               if isinstance(n, ast.Constant) and isinstance(n.value, str)
               and RULE_RE.match(n.value)}
        if not ids:
            continue
        form = SCOPE_FORM.get(top.name)
        if form is None:
            unclassified.add(top.name)
            continue
        for rid in ids:
            prev = forms.get(rid)
            forms[rid] = "both" if prev and prev != form else form
    return forms, unclassified


def paths(globs):
    out = []
    for pat in globs:
        out += sorted(glob.glob(os.path.join(ROOT, pat)))
    return [p for p in out if os.path.isfile(p)]


def findings_of(path):
    text = open(path, encoding="utf-8").read()
    try:
        if vw.detect_format(path, text) == "xml":
            return {f.rule for f in vw.run_xml(text)}
        return {f.rule for f in vw.run_yaml(text)}
    except Exception:
        return None            # unparseable: counted apart, never read as silence


def sweep(doc_paths, forms):
    """Count fires/silent per rule, counting a document only when its form is one
    the rule is emitted on. A rule never reaches the other form's parser, so
    those documents are not evidence that it stayed silent."""
    fires, silent, unreadable = {}, {}, []
    for p in doc_paths:
        got = findings_of(p)
        if got is None:
            unreadable.append(p)
            continue
        dform = "xml" if p.lower().endswith((".bpmn", ".xml")) else "yaml"
        for rid, rform in forms.items():
            if rform != "both" and rform != dform:
                continue
            bucket = fires if rid in got else silent
            bucket[rid] = bucket.get(rid, 0) + 1
    return fires, silent, unreadable


def witness_e_load():
    """E-LOAD cannot be witnessed by any fixture, by construction: it fires on
    file-not-found, and the fixture runner only ever passes paths that exist.
    The state that would witness it is unreachable FOR THE HARNESS -- OBS-124
    one level up, at the instrument rather than the check. So witness it the
    only way it can be witnessed: invoke the CLI on an absent path."""
    missing = os.path.join(ROOT, "tests", "fixtures", ".t333-no-such-file.yaml")
    if os.path.exists(missing):
        return False, "the probe path exists, so file-not-found cannot be provoked"
    proc = subprocess.run([sys.executable, VALIDATOR, missing],
                          capture_output=True, text=True)
    out = (proc.stdout or "") + (proc.stderr or "")
    if "E-LOAD" not in out:
        return False, "validator on an absent path did not emit E-LOAD: %r" % out[:200]
    return True, ""


def main():
    fails = []

    forms, unclassified = rule_forms(VALIDATOR)
    if unclassified:
        fails.append(
            "scope(s) %s emit rule ids but are not classified in SCOPE_FORM. "
            "An unclassified scope is measured against the wrong document "
            "population and reports a false never-witnessed -- classify it "
            "explicitly rather than letting it default"
            % sorted(unclassified))
        _summary(fails)
        return 1

    corpus, fixtures = paths(CORPUS_GLOBS), paths(FIXTURE_GLOBS)
    if not corpus or not fixtures:
        fails.append("corpus (%d) or fixture (%d) population is empty -- the "
                     "sweep would report every rule never-witnessed and every "
                     "bucket would be a capability zero"
                     % (len(corpus), len(fixtures)))
        _summary(fails)
        return 1

    cf, cs, c_bad = sweep(corpus, forms)
    ff, fs, f_bad = sweep(fixtures, forms)

    # A document that will not parse is not evidence of silence. Corpus
    # documents are all expected to parse; fixtures deliberately include
    # malformed ones, which the validator reports rather than crashing on.
    if c_bad:
        fails.append("%d corpus document(s) could not be validated at all, so "
                     "their contribution to every rule's silence count is "
                     "unknown: %s" % (len(c_bad), [os.path.basename(p) for p in c_bad]))

    always, never, both = [], [], []
    for rid in sorted(forms):
        fire = cf.get(rid, 0) + ff.get(rid, 0)
        sil = cs.get(rid, 0) + fs.get(rid, 0)
        if fire and not sil:
            always.append((rid, fire))
        elif not fire:
            never.append(rid)
        else:
            both.append(rid)

    assert len(always) + len(never) + len(both) == len(forms), "partition leak"

    # (1) THE OBS-124 PROPERTY. A rule that fires on every input its form can
    #     produce has an unreachable pass branch: it reports on 100% of runs,
    #     carries no information, and is indistinguishable from decoration.
    for rid, fire in always:
        fails.append(
            "%s fires on ALL %d document(s) of its form and is silent on none. "
            "Its passing state is unreachable, so it can never discriminate -- "
            "this is the AEF OBS-124 shape (a check whose failing state is the "
            "only state it has). Either the predicate is wrong or every "
            "document genuinely violates it; both need a decision, not a "
            "standing report." % (rid, fire))

    # (2) E-LOAD, witnessed directly because no fixture can witness it. It
    #     counts as witnessed ONLY while the direct probe actually succeeds --
    #     a broken probe must not quietly promote the rule to "fine".
    e_load_ok, why = witness_e_load()
    if not e_load_ok:
        fails.append("E-LOAD could not be witnessed: %s. It fires only on "
                     "file-not-found, so no fixture can exercise it and this "
                     "direct probe is the only evidence its branch works" % why)

    # (3) NEVER-WITNESSED: declared, counted, answerable in BOTH directions.
    #     The document sweep cannot see a rule witnessed outside the corpus, so
    #     subtract the directly-witnessed ones -- otherwise E-LOAD reads as
    #     never-witnessed in the same run that just witnessed it.
    observed = set(never) - ({"E-LOAD"} if e_load_ok else set())
    declared = set(NEVER_WITNESSED)
    newly = sorted(observed - declared)
    if newly:
        fails.append(
            "rule(s) %s fire on NO corpus document and NO fixture, and are not "
            "declared. A rule nobody has ever seen fire is a rule nobody has "
            "shown to work -- add a fixture, or declare it here with the reason"
            % newly)
    closed = sorted(declared - observed)
    if closed:
        fails.append(
            "rule(s) %s are declared never-witnessed but now fire somewhere. "
            "The declaration is stale -- delete the entry and decrement "
            "EXPECTED_NEVER_WITNESSED. A tolerance kept past its cause is a "
            "suppression list wearing a tolerance's label" % closed)
    if len(NEVER_WITNESSED) != EXPECTED_NEVER_WITNESSED:
        fails.append("NEVER_WITNESSED holds %d entries, expected %d -- the "
                     "table and its count disagree"
                     % (len(NEVER_WITNESSED), EXPECTED_NEVER_WITNESSED))
    for rid in sorted(declared & observed):
        print("  NOTE (never witnessed, T-333): %s -- %s"
              % (rid, NEVER_WITNESSED[rid]))

    print("check-pass reachability: %d rules over %d corpus + %d fixture "
          "documents (form-scoped denominators) -- %d fire and fall silent on "
          "real inputs, %d declared never-witnessed, %d always-fire. E-LOAD "
          "witnessed directly (no fixture can reach it: it fires on "
          "file-not-found)."
          % (len(forms), len(corpus), len(fixtures), len(both),
             len(observed), len(always)))
    _summary(fails)
    return 1 if fails else 0


def _summary(fails):
    if fails:
        print("\nFAIL (%d):" % len(fails))
        for f in fails:
            print("  - %s" % f)
    else:
        print("OK: no validator rule has an unreachable passing state")


if __name__ == "__main__":
    sys.exit(main())
