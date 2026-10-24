#!/usr/bin/env python3
"""T-1286: --dry-run rehearses a job's steps in a throwaway clone, with the repo's own hooks.

Every leg runs the REAL entry point (runme.sh -> tools/runme-launcher.sh) against a fixture repo
(RUNME_REPO, honoured only off the real job dir) whose pre-commit hook refuses any staged file named
forbidden*. Fixtures live under .context/rehearse/test-t1286-<pid>/ and are removed at the end.
"Old dry-run" = the launcher as it was before T-1286 (commit f60a5f35): checks only.
Exit 0 = all legs pass.
"""
import os
import shutil
import signal
import subprocess
import sys
import tempfile
import time

ROOT = os.environ.get("T1286_ROOT") or os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RUNME = os.path.join(ROOT, "runme.sh")
OLD_LAUNCHER_REV = "f60a5f35"   # the last commit whose dry-run ran the checks only
fails = []

HOOK = """#!/bin/sh
if git diff --cached --name-only | grep -q '^forbidden'; then
    echo "FIXTURE GATE: a forbidden file is staged; commit refused"
    exit 1
fi
"""
GIT = "git -c user.name=t1286 -c user.email=t1286@example.invalid"


def leg(ok, name, detail=""):
    print("%s  %s%s" % ("PASS" if ok else "FAIL", name, (" — " + detail) if detail else ""))
    if not ok:
        fails.append(name)


def sh(cmd, cwd):
    return subprocess.run(cmd, shell=True, cwd=cwd, capture_output=True, text=True, check=True).stdout.strip()


class Fixture:
    def __init__(self, base):
        self.base = base
        self.repo = os.path.join(base, "repo")
        self.origin = os.path.join(base, "origin.git")
        self.jobs = os.path.join(base, "jobs")
        # markers OUTSIDE the project: the rehearsal sees the whole project read-only, by design
        self.out = tempfile.mkdtemp(prefix="t1286-out-")
        for d in (self.repo, self.jobs):
            os.makedirs(d)
        sh("git init -q --bare %s" % self.origin, base)
        sh("git init -q -b bleeding-edge . && echo fixture > README.md && git add README.md && "
           "%s commit -qm 'T-1286: fixture' && git remote add origin %s && git push -q origin bleeding-edge"
           % (GIT, self.origin), self.repo)
        hook = os.path.join(self.repo, ".git", "hooks", "pre-commit")
        with open(hook, "w") as fh:
            fh.write(HOOK)
        os.chmod(hook, 0o755)
        # the old launcher, as it was: its own PROJ is base/old, which its checks-only dry-run never needs
        old = os.path.join(base, "old", "tools")
        os.makedirs(old)
        self.old_launcher = os.path.join(old, "runme-launcher.sh")
        with open(self.old_launcher, "w") as fh:
            fh.write(sh("git show %s:tools/runme-launcher.sh" % OLD_LAUNCHER_REV, ROOT))

    def job(self, name, body):
        d = os.path.join(self.jobs, name)
        os.makedirs(d)
        with open(os.path.join(d, "job.sh"), "w") as fh:
            fh.write(body.replace("@OUT@", self.out).replace("@REPO@", self.repo).replace("@GIT@", GIT))
        return d

    def env(self, **extra):
        return dict(os.environ, RUNME_JOBS_DIR=self.jobs, RUNME_REPO=self.repo, RUNME_SIGNAL_NO_TERMLINK="1",
                    RUNME_EVENTS_FILE=os.path.join(self.base, "events"), RUNME_PICKER="0", **extra)

    def dry(self, name, old=False, **extra):
        cmd = ["bash", self.old_launcher if old else RUNME, "--dry-run", name]
        r = subprocess.run(cmd, capture_output=True, text=True, env=self.env(**extra), timeout=120)
        return r.returncode, r.stdout + r.stderr

    def state(self):  # the fixture repo as the assertion sees it
        # T-1296: the hooks are compared by NAME and CONTENT. `ls -la .git/hooks` was hashed here before: it prints
        # mtimes to the minute, including the `..` line (.git itself, touched by any git command), so a leg that
        # crossed a minute boundary under load "changed" the fixture with nothing changed.
        return sh("git rev-parse HEAD; git for-each-ref; git ls-files --stage; git status --porcelain; "
                  "(cd .git/hooks && find . -type f | sort | xargs -r sha256sum) | sha256sum", self.repo)

    def made(self, marker):
        return os.path.exists(os.path.join(self.out, marker))

    def clones_left(self):
        # T-1296: only clones of THIS fixture's own jobs. .context/rehearse/ is shared: another process's rehearsal (a
        # launcher test's dry-run, another session) may sit there briefly and is none of this test's business.
        rh = os.path.join(ROOT, ".context", "rehearse")
        mine = set(os.listdir(self.jobs)) if os.path.isdir(self.jobs) else set()
        return [d for d in os.listdir(rh) if d in mine] if os.path.isdir(rh) else []

    def state_diff(self, before):
        # T-1296: on a failing cleanup leg, say WHAT differs (and which clones were left), not just that it failed.
        import difflib
        now = self.state()
        d = [l for l in difflib.unified_diff(before.splitlines(), now.splitlines(), "before", "after", lineterm="", n=0)
             if l[:1] in "+-" and not l.startswith(("+++", "---"))]
        return "state diff: %s | clones left: %s" % ("; ".join(d[:6]) or "none", self.clones_left() or "none")


def tail(out, n=4):
    return " | ".join(out.strip().splitlines()[-n:])


def main():
    base = os.path.join(ROOT, ".context", "rehearse", "test-t1286-%d" % os.getpid())
    f = None
    try:
        f = Fixture(base)
        before = f.state()

        # 1 the class it is for: a step a gate refuses. The OLD dry-run (checks only) passes it; the new one fails it,
        #   prints the step and the gate's own words, writes no dryrun.ok, and the fixture repo is untouched
        d = f.job("001-gate", '''JOB_TITLE="Commit a file the fixture gate refuses"
preflight() { check "git works" 'git --version >/dev/null'; }
steps() { step "commit forbidden.txt" 'echo x > forbidden.txt && git add forbidden.txt && @GIT@ commit -qm "T-1286: refused"'; }
''')
        rco, outo = f.dry("001-gate", old=True)
        rc, out = f.dry("001-gate")
        leg(rco == 0 and "dry-run passed" in outo, "1a the OLD dry-run passes the gate job (it never runs the step)", tail(outo, 1))
        leg(rc != 0 and "FAIL  step 1/1: commit forbidden.txt" in out and "FIXTURE GATE" in out
            and "runs: echo x > forbidden.txt" in out and not os.path.exists(os.path.join(d, "dryrun.ok")),
            "1b the NEW dry-run fails it: step + gate output printed, no dryrun.ok (the old one's removed)", tail(out))
        leg(f.state() == before and not os.path.exists(os.path.join(f.repo, "forbidden.txt")) and not f.clones_left(),
            "1c the fixture repo is unchanged and the clone is gone")

        # 2 a job whose steps all succeed passes both; its commit lands in the clone only
        d = f.job("002-good", '''JOB_TITLE="Commit an allowed file, then see it committed"
preflight() { check "on bleeding-edge" '[ "$(git rev-parse --abbrev-ref HEAD)" = bleeding-edge ]'; }
steps() {
    step "commit allowed.txt" 'echo x > allowed.txt && git add allowed.txt && @GIT@ commit -qm "T-1286: allowed"'
    step "the commit is there" 'git log --oneline -1 | grep -q allowed && [ -z "${PROJECT_ROOT+x}${CONTEXT_DIR+x}${TASKS_DIR+x}" ]'
}
''')
        rco, outo = f.dry("002-good", old=True)
        rc, out = f.dry("002-good", PROJECT_ROOT="/nonexistent", CONTEXT_DIR="/nonexistent", TASKS_DIR="/nonexistent")
        leg(rco == 0 and rc == 0 and "ok    step 1/2: commit allowed.txt" in out and "ok    step 2/2: the commit is there" in out
            and os.path.exists(os.path.join(d, "dryrun.ok")) and "ok    real repo unchanged" in out,
            "2a a good job passes old and new; steps ran in the clone with PROJECT_ROOT/CONTEXT_DIR/TASKS_DIR unset", tail(out))
        leg(f.state() == before and not os.path.exists(os.path.join(f.repo, "allowed.txt")) and not f.clones_left(),
            "2b the commit stayed in the clone: fixture HEAD, refs, index, tree and hooks unchanged; clone removed", f.state_diff(before))

        # 3 step_outward: in the plan as (outward), never run by the rehearsal; a real run runs it like any step
        d = f.job("003-outward", '''JOB_TITLE="One outward step"
preflight() { check "true" 'true'; }
steps() {
    step "inside" 'git status --short >/dev/null'
    step_outward "acts outside the repo" 'touch @OUT@/outward'
}
''')
        rc, out = f.dry("003-outward")
        leg(rc == 0 and "2. acts outside the repo (outward)" in out
            and "skip  step 2/2: acts outside the repo — not rehearsed: acts outside the repo" in out and not f.made("outward"),
            "3a step_outward: shown (outward), listed as not rehearsed, its marker never made", tail(out))
        for other in ("001-gate", "002-good"):   # out of the queue, so the real run below has one job to run
            with open(os.path.join(f.jobs, other, "retired"), "w") as fh:
                fh.write("test: only 003 runs\n")
        answers = os.path.join(f.base, "answers")
        with open(answers, "w") as fh:
            fh.write("y\ny\n")
        r = subprocess.run(["bash", RUNME], capture_output=True, text=True, env=f.env(RUNME_TTY=answers), timeout=60)
        events = open(os.path.join(f.base, "events")).read() if os.path.exists(os.path.join(f.base, "events")) else ""
        leg(r.returncode == 0 and f.made("outward") and "Run step 2/2? [y/N]" in r.stdout and " step 2/2 acts outside" in events
            and os.path.exists(os.path.join(d, "done")),
            "3b the real run treats step_outward like step: y/N, run, event, done", tail(r.stdout))

        # 4 an undeclared push fails the rehearsal and lands nowhere (the clone's push url refuses)
        f.job("004-push", '''JOB_TITLE="Push without declaring it"
steps() { step "push a branch" 'git push origin HEAD:refs/heads/rehearsal-leak'; }
''')
        rc, out = f.dry("004-push")
        leaked = sh("git ls-remote origin rehearsal-leak", f.repo)
        leg(rc != 0 and "FAIL  step 1/1: push a branch" in out and "declare-it-step_outward" in out and not leaked,
            "4 an undeclared push fails in the rehearsal and reaches no remote", tail(out))

        # 5 the guard: a step that writes into the real repo by an absolute path fails, and the write never lands
        f.job("005-reach", '''JOB_TITLE="Reach into the real repo"
steps() { step "write outside the clone" 'touch @REPO@/stray'; }
''')
        rc, out = f.dry("005-reach")
        guarded = "the real repo is read-only to them" in out
        leg(guarded and rc != 0 and "FAIL  step 1/1: write outside the clone" in out and "Read-only file system" in out
            and not os.path.exists(os.path.join(f.repo, "stray")) and f.state() == before,
            "5 guarded: a step writing into the real repo fails (read-only) and nothing lands", tail(out) + " | " + f.state_diff(before))

        # 6 without the guard the before/after assertion catches the same reach: working tree and hooks named
        f.job("006-reach", '''JOB_TITLE="Reach into the real repo, unguarded"
steps() { step "write outside the clone" 'touch @REPO@/stray && echo "#x" > @REPO@/.git/hooks/post-stray'; }
''')
        rc, out = f.dry("006-reach", RUNME_REHEARSE_NO_GUARD="1")
        leg(rc != 0 and "NO read-only guard" in out and "THE REHEARSAL CHANGED THE REAL REPO" in out
            and "+ status         ?? stray" in out and "+ hooks" in out
            and not os.path.exists(os.path.join(f.jobs, "006-reach", "dryrun.ok")),
            "6 unguarded: the real-repo-unchanged assertion fails the dry-run, naming the tree and hooks change", tail(out, 8))
        for p in (os.path.join(f.repo, "stray"), os.path.join(f.repo, ".git", "hooks", "post-stray")):
            if os.path.exists(p):
                os.remove(p)
        leg(f.state() == before, "6b (fixture restored for the legs after)", f.state_diff(before))

        # 7 an interrupt mid-step: the launcher EXITS (does not resume), stops the step's whole process group, removes
        #   the clone. T-1273: a handler that returned would carry on to the next step.
        for sig, want in ((signal.SIGTERM, 143), (signal.SIGINT, 130)):
            name = "007-slow-%d" % sig
            f.job(name, '''JOB_TITLE="A slow step"
steps() { step "slow" 'touch @OUT@/started-%d; sleep 31.286; touch @OUT@/finished-%d'; step "after" 'touch @OUT@/after-%d'; }
''' % (sig, sig, sig))
            p = subprocess.Popen(["bash", RUNME, "--dry-run", name], env=f.env(), stdout=subprocess.PIPE,
                                 stderr=subprocess.STDOUT, text=True)
            t0 = time.time()
            while not f.made("started-%d" % sig) and time.time() - t0 < 60:
                time.sleep(0.1)
            p.send_signal(sig)
            try:
                rc = p.wait(timeout=15)
            except subprocess.TimeoutExpired:
                p.kill(); rc = None
            time.sleep(0.5)
            still = subprocess.run(["pgrep", "-fx", "sleep 31.286"], capture_output=True).returncode == 0
            leg(rc == want and not f.clones_left() and not still and not f.made("after-%d" % sig)
                and not os.path.exists(os.path.join(f.jobs, name, "dryrun.ok")),
                "7 %s mid-step: exit %d at once, step's group killed, clone removed, no later step, no dryrun.ok"
                % (signal.Signals(sig).name, want), "rc=%r still=%r left=%r" % (rc, still, f.clones_left()))

        # 8 RUNME_REPO is for tests only: refused on the real job dir
        env = dict(os.environ, RUNME_REPO=f.repo, RUNME_SIGNAL_NO_TERMLINK="1")
        env.pop("RUNME_JOBS_DIR", None)
        r = subprocess.run(["bash", RUNME, "--list"], capture_output=True, text=True, env=env, timeout=30)
        leg(r.returncode != 0 and "RUNME_REPO is for tests only" in r.stdout, "8 RUNME_REPO refused on the real job dir")
    finally:
        shutil.rmtree(base, ignore_errors=True)
        if f is not None:
            shutil.rmtree(f.out, ignore_errors=True)

    print("\n%d failed leg(s)" % len(fails) if fails else "\nall legs passed")
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
