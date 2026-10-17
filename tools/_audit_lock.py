"""_audit_lock.py — run `fw audit` from a probe without mistaking a held audit lock for a verdict (832 T-1166).

`fw audit` takes an exclusive flock and, when another audit holds it (the 15-minute cron audit, a pre-push audit,
a concurrent agent), exits 75 at once with "Another audit is already running — exiting (no verdict produced)".
A probe that reads the audit's output then saw nothing and refused with a message blaming the CONTROL ("no D2 line",
"no CTL-028 line"): OBS-481 recorded five probes red under a cron audit and green on rerun, cause unconfirmed until
T-1166 reproduced it by holding the lock.

    from _audit_lock import run_fw_audit, LOCK_HELD
    proc = run_fw_audit([FW, "audit", "--section", "compliance"], cwd=..., env=..., timeout=900)
    if proc.returncode == LOCK_HELD: print(LOCK_HELD_MESSAGE); sys.exit(2)

run_fw_audit waits for the lock and retries (every 10 s, up to T1166_LOCK_WAIT seconds, default 180), so a short
collision costs a pause, not a verdict. If the lock is still held after that it returns the exit-75 result, and the
probe says CANNOT RUN — the wording the bridge suite already files under "never got to look" (T-1060).
`fw audit --check <id>` (AEF T-4209) takes no lock; prefer it where the probe reads a single selectable check.
"""
import os
import subprocess
import time

LOCK_HELD = 75
LOCK_HELD_MESSAGE = ("CANNOT RUN: another `fw audit` held the audit lock for the whole wait (exit 75, \"Another audit is "
                     "already running\"), so nothing was evaluated. This is not a verdict on the control; rerun when the "
                     "audit has finished (T-1166).")


def _lock_busy(proc):
    out = (proc.stdout or "") + (proc.stderr or "")
    return proc.returncode == LOCK_HELD or "Another audit is already running" in out


def run_fw_audit(argv, wait_s=None, poll_s=10, **kwargs):
    """subprocess.run(argv, **kwargs), retried while the audit lock is held. Returns the last CompletedProcess;
    its returncode is LOCK_HELD if the lock never came free within wait_s."""
    if wait_s is None:
        wait_s = int(os.environ.get("T1166_LOCK_WAIT", "180"))
    deadline = time.monotonic() + wait_s
    kwargs.setdefault("capture_output", True)
    kwargs.setdefault("text", True)
    while True:
        proc = subprocess.run(argv, **kwargs)
        if not _lock_busy(proc):
            return proc
        if time.monotonic() >= deadline:
            proc.returncode = LOCK_HELD
            return proc
        time.sleep(poll_s)
