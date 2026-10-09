#!/usr/bin/env python3
"""T-1055: the runme launcher enforces the operator's safeguards itself, so no job can skip them.

Every leg runs the REAL entry point (runme.sh -> tools/runme-launcher.sh) against a scratch job
directory, with answers fed through RUNME_TTY (honoured only off the real job dir; leg 11 shows the
refusal) and events to a scratch file. Steps write marker files, so "ran" / "did not run" is
observed, not inferred. Exit 0 = all legs pass.
"""
import os
import stat
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RUNME = os.path.join(ROOT, "runme.sh")
# runme.sh execs this; named here so a broken stub fails as itself (leg 0), not as missing output.
LAUNCHER = os.path.join(ROOT, "tools", "runme-launcher.sh")
NEW = os.path.join(ROOT, "tools", "runme-new.sh")
fails = []


def leg(ok, name, detail=""):
    print("%s  %s%s" % ("PASS" if ok else "FAIL", name, (" — " + detail) if detail else ""))
    if not ok:
        fails.append(name)


class Box:
    """One scratch job dir + events file + answers file."""

    def __init__(self, tmp, tag):
        self.dir = os.path.join(tmp, tag)
        self.jobs = os.path.join(self.dir, "jobs")
        self.out = os.path.join(self.dir, "out")
        os.makedirs(self.jobs)
        os.makedirs(self.out)
        self.events = os.path.join(self.dir, "events")
        self.answers = os.path.join(self.dir, "answers")

    def job(self, name, body):
        d = os.path.join(self.jobs, name)
        os.makedirs(d)
        with open(os.path.join(d, "job.sh"), "w") as fh:
            fh.write(body.replace("@OUT@", self.out))
        return d

    def run(self, *args, answers=""):
        with open(self.answers, "w") as fh:
            fh.write(answers)
        env = dict(os.environ, RUNME_JOBS_DIR=self.jobs, RUNME_EVENTS_FILE=self.events,
                   RUNME_SIGNAL_NO_TERMLINK="1", RUNME_TTY=self.answers)
        r = subprocess.run(["bash", RUNME] + list(args), capture_output=True, text=True, env=env, timeout=60)
        return r.returncode, r.stdout + r.stderr

    def made(self, marker):
        return os.path.exists(os.path.join(self.out, marker))

    def events_text(self):
        return open(self.events).read() if os.path.exists(self.events) else ""


TWO_STEPS = '''JOB_TITLE="Two steps"
JOB_TASK="T-1055"
JOB_WHY="test job"
preflight() { check "always true" 'true'; }
steps() {
    step "first" 'touch @OUT@/s1'
    step "second" 'touch @OUT@/s2'
}
'''


def main():
    # 0 the operator's command is the stub, and the stub runs the tested launcher
    with open(RUNME) as fh:
        stub = fh.read()
    leg(os.access(LAUNCHER, os.X_OK) and "tools/runme-launcher.sh" in stub and stub.count("\n") < 30,
        "0 runme.sh is a short fixed stub that execs tools/runme-launcher.sh")

    with tempfile.TemporaryDirectory() as tmp:
        # 1 a job that runs a command when loaded is refused, and the command never runs
        b = Box(tmp, "l1")
        b.job("001-bad", 'touch @OUT@/loaded\nJOB_TITLE="x"\nsteps() { step "s" "true"; }\n')
        rc, out = b.run("--dry-run")
        leg(rc != 0 and "runs a command when it is loaded" in out and not b.made("loaded"),
            "1 load-time command refused; it did not run", out.strip().splitlines()[-1] if out.strip() else "")

        # 2 a real run of a job never rehearsed is refused, nothing runs, the agent is signalled
        b = Box(tmp, "l2")
        b.job("001-two", TWO_STEPS)
        rc, out = b.run(answers="y\ny\n")
        leg(rc != 0 and "has not been rehearsed" in out and not b.made("s1") and "STOPPED" in b.events_text(),
            "2 no dry-run -> refused, nothing ran, STOPPED event written")

        # 3 dry-run: checks run, sha recorded, job.sh read-only, NO step runs
        rc, out = b.run("--dry-run")
        d = os.path.join(b.jobs, "001-two")
        ro = not (os.stat(os.path.join(d, "job.sh")).st_mode & stat.S_IWUSR)
        leg(rc == 0 and os.path.exists(os.path.join(d, "dryrun.ok")) and ro and not b.made("s1")
            and "ok    always true" in out, "3 dry-run records sha, makes job.sh read-only, runs no step")

        # 4 a job edited after its dry-run is refused
        os.chmod(os.path.join(d, "job.sh"), 0o644)
        with open(os.path.join(d, "job.sh"), "a") as fh:
            fh.write("# edited after the dry-run\n")
        rc, out = b.run(answers="y\ny\n")
        leg(rc != 0 and "CHANGED since its dry-run" in out and not b.made("s1"), "4 edited after dry-run -> refused, nothing ran")

        # 5 happy path: rehearsed again, y to each step -> both ran, done written, log + events
        b.run("--dry-run")
        rc, out = b.run(answers="y\ny\n")
        ev = b.events_text()
        logs = [f for f in os.listdir(d) if f.startswith("run-")]
        leg(rc == 0 and b.made("s1") and b.made("s2") and os.path.exists(os.path.join(d, "done")) and logs
            and "Job:   001-two" in out and "sha " in out and " step 1/2 first" in ev and " done rc=0" in ev,
            "5 y,y -> both steps ran, done + log written, started/step/done events")

        # 6 a done job is never run again
        os.remove(os.path.join(b.out, "s1"))
        rc, out = b.run(answers="y\ny\n")
        leg(rc == 0 and "Nothing to run" in out and not b.made("s1"), "6 done job not run again")

        # 7 N at step 2 stops: step 1 ran, step 2 did not, no done
        b = Box(tmp, "l7")
        d = b.job("001-two", TWO_STEPS)
        b.run("--dry-run")
        rc, out = b.run(answers="y\nn\n")
        leg(rc != 0 and b.made("s1") and not b.made("s2") and not os.path.exists(os.path.join(d, "done"))
            and "not confirmed at step 2/2" in out, "7 y then N -> step 1 ran, step 2 did not, no done")

        # 8 a failing step stops the run; later steps do not run
        b = Box(tmp, "l8")
        b.job("001-fails", TWO_STEPS.replace("'touch @OUT@/s1'", "'false'"))
        b.run("--dry-run")
        rc, out = b.run(answers="y\ny\n")
        leg(rc != 0 and "step 1/2 failed" in out and not b.made("s2"), "8 failing step -> stop, later steps not run")

        # 9 two pending jobs -> numbered choice; only the chosen one runs
        b = Box(tmp, "l9")
        b.job("001-a", TWO_STEPS.replace("s1", "a1").replace("s2", "a2"))
        b.job("002-b", TWO_STEPS.replace("s1", "b1").replace("s2", "b2"))
        b.run("--dry-run")
        rc, out = b.run(answers="2\ny\ny\n")
        leg(rc == 0 and "Pending jobs:" in out and b.made("b1") and b.made("b2") and not b.made("a1"),
            "9 two pending -> asks which; only the chosen job ran")

        # 10 a failing preflight fails the dry-run: no dryrun.ok, so the real run stays refused
        b = Box(tmp, "l10")
        d = b.job("001-pre", TWO_STEPS.replace("'true'", "'false'"))
        rc, out = b.run("--dry-run")
        rc2, out2 = b.run(answers="y\ny\n")
        leg(rc != 0 and not os.path.exists(os.path.join(d, "dryrun.ok")) and "has not been rehearsed" in out2
            and not b.made("s1"), "10 failing preflight -> dry-run fails, real run refused")

        # 11 answers from a file are refused on the REAL job dir (the safeguard cannot be scripted)
        env = dict(os.environ, RUNME_TTY=os.path.join(tmp, "nope"), RUNME_SIGNAL_NO_TERMLINK="1")
        env.pop("RUNME_JOBS_DIR", None)
        r = subprocess.run(["bash", RUNME], capture_output=True, text=True, env=env, timeout=30)
        leg(r.returncode != 0 and "RUNME_TTY is for tests only" in r.stdout, "11 RUNME_TTY refused on the real job dir")

        # 12 runme-new scaffolds numbered jobs that load (and refuse to run un-rehearsed)
        b = Box(tmp, "l12")
        env = dict(os.environ, RUNME_JOBS_DIR=b.jobs)
        p1 = subprocess.run(["bash", NEW, "first"], capture_output=True, text=True, env=env).stdout.strip()
        p2 = subprocess.run(["bash", NEW, "second"], capture_output=True, text=True, env=env).stdout.strip()
        rc, out = b.run("--dry-run")
        leg(p1.endswith("001-first/job.sh") and p2.endswith("002-second/job.sh") and rc == 0
            and "dry-run passed" in out, "12 runme-new scaffolds 001, 002; the scaffold rehearses cleanly")

        # 13 (T-1112) the menu names each job's title, state and LAST OUTCOME, so a job that stopped for a
        #    reason says so before the operator picks it again (008 was picked 3x while waiting on a file)
        b = Box(tmp, "l13")
        b.job("001-needs-file", TWO_STEPS.replace('"Two steps"', '"Needs a file first"')
              .replace("'touch @OUT@/s1'", "'echo \"no /root/x.secret - place it first\"; false'"))
        b.job("002-other", TWO_STEPS.replace("s1", "o1").replace("s2", "o2"))
        b.run("--dry-run")
        b.run(answers="1\ny\n")                       # run 001: step 1 fails with its reason
        rc, out = b.run(answers="nothing\n")          # menu again; answer nothing -> no job run
        menu = [l for l in out.splitlines() if l.strip().startswith("1. ")]
        leg(menu and "Needs a file first" in menu[0] and "[ready; last: STOPPED" in menu[0]
            and "no /root/x.secret" in menu[0] and "never run" in out and not b.made("o1"),
            "13 menu line: title, state and last outcome with the step's own reason", menu[0] if menu else out[-300:])

        # 14 (T-1112) a retired job is never offered and never runs; --list --all names it with its reason
        b = Box(tmp, "l14")
        d = b.job("001-old", TWO_STEPS)
        b.run("--dry-run")
        with open(os.path.join(d, "retired"), "w") as fh:
            fh.write("superseded by 002-new\n")
        rc, out = b.run(answers="y\ny\n")
        _, out2 = b.run("--list", "--all")
        leg(rc == 0 and "Nothing to run" in out and not b.made("s1") and not os.path.exists(os.path.join(d, "done"))
            and "RETIRED: superseded by 002-new" in out2, "14 retired: not offered, not run, no done written; --list --all names it")

    print("\n%d failed leg(s)" % len(fails) if fails else "\nall legs passed")
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
