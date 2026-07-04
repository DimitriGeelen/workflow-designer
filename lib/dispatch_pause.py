"""Shim (T-090 / gap G-004): bridge a vendored-framework import bug.

The vendored Watchtower blueprint (.agentic-framework/web/blueprints/
review.py:18) inserts PROJECT_ROOT/lib on sys.path and then imports
`dispatch_pause` — but in shared-tooling mode the real module lives at
FRAMEWORK_ROOT/lib/dispatch_pause.py, so every /review/T-XXX page 500s.
The vendored tree is read-only in this repo; this shim sits at the exact
path the buggy line adds and re-exports the real module's public names.

REMOVE THIS FILE when upstream fixes review.py to use FRAMEWORK_ROOT
(close gap G-004 in .context/project/concerns.yaml at the same time).
"""
import importlib.util
from pathlib import Path

_REAL = Path(__file__).resolve().parent.parent / ".agentic-framework" / "lib" / "dispatch_pause.py"
_spec = importlib.util.spec_from_file_location("_dispatch_pause_real", _REAL)
_mod = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_mod)

globals().update({k: v for k, v in vars(_mod).items() if not k.startswith("_")})
