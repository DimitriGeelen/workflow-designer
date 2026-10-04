# T-1029: facts for the rotation decision (the machine ID is public)

> **CORRECTION, 2026-10-04 (T-1030). This question was already closed. There is no open decision.**
> The operator closed it under T-938 on 2026-09-30. The encrypted file was purged from the repository, and the operator found that **nobody downloaded it apart from automated access**. The agent wrote this report without reading that closing record, and wrongly presented the question as open. (The operator's no-download finding was restated on 2026-10-04; it is recorded here so the next reader does not repeat the mistake.)
>
> **The one new fact does not reopen it.** The 10-02 re-vendor re-published the machine ID (fixed: T-1024 locally, AEF T-3788 upstream). A public machine ID only matters to someone holding a copy of `api-keys.enc`, and per T-938 none exists outside this host. **No rotation is needed.** The options at the end of this report are retired. The text below is kept as written so the correction can be read against it.

**Date:** 2026-10-04. **Method:** code, file metadata and git history only. No secret, no key and no machine-ID value was read into this report or printed. The one look at stored names used the store's own loader and printed key *names* only.

## 1. What the machine ID protects

`.agentic-framework/web/secrets_store.py` (T-378):
- The key is `PBKDF2-HMAC-SHA256(machine-id, salt = a constant written in that public source file, 600,000 iterations)`, turned into a Fernet key.
- It encrypts **`.context/secrets/api-keys.enc`**.

The salt and the iteration count are public, and the machine ID is now public too (see 3). So **anyone holding a copy of `api-keys.enc` from this host can decrypt it.** Without a copy of that file, the public ID by itself unlocks nothing.

## 2. What exists in 832 now

| Item | Fact |
|---|---|
| `.context/secrets/api-keys.enc` | 204 bytes, **last written 2026-09-27**. Git-ignored (`.gitignore:43`), not tracked. |
| Entries in it | **1, named `openrouter`.** The value was not read. T-938 established on 09-30 that it is the *live* OpenRouter key, the same as the one in `~/.litellm-openrouter.env`. |

The file was last written on 09-27, before the exposure on 09-30, so **the store still holds the exposed key**, unless that key has been revoked at OpenRouter without the store being updated. Nothing in this repo records a rotation.

## 3. Where copies went

1. **The encrypted file.** T-938 (09-30): it was committed and **pushed to origin** (the internal OneDev server) for about three days. Then, on your instruction, history was rewritten and force-pushed. `git log --all` finds no commit touching that path today. T-938 says its AC "the cascade is mapped" is met, but its text doesn't preserve whether OneDev mirrors to GitHub, or whether anyone fetched in those three days.
2. **The machine ID.** It is in AEF's **public GitHub mirror** (master and bleeding-edge, checked 2026-10-04). AEF redacted it on 2026-10-04 (their T-3788); the redaction reaches GitHub with their next push, but **public history keeps the old value** unless AEF rewrites it.
3. **832 itself:** the ID is out of the tracked tree (T-1024), and still in our own history (OneDev only).

**Putting it together:** anyone who obtained a copy of `api-keys.enc` while it was pushed (09-27 to 09-30) can decrypt the live OpenRouter key today, using the public machine ID. Whether such a copy exists outside this host isn't knowable from here. It depends on who could read the OneDev repo in that window, and on whether OneDev mirrored it anywhere.

## 4. What the machine ID does NOT protect

- The Watchtower session-signing key (`.fw-secret-key`) is random, not derived. It was rotated after T-410.
- AEF says it has no `api-keys.enc` on this host.

## Your decision (numbered; one keypress)

1. **Rotate the OpenRouter key (recommended).** Issue a new key at OpenRouter, revoke the old one, and update both `~/.litellm-openrouter.env` and the store (`fw` secrets UI or `set_api_key`). This makes every exposed copy worthless, whatever the answers to the unknowns above. *Cost:* a few minutes. Anything using the old key fails until it's updated.
2. **Rotate the OpenRouter key and re-key the store** so it stops depending on the machine ID (an upstream change for AEF, because the derivation is machine-bound by design). *Cost:* option 1 plus an AEF task.
3. **Don't rotate, accept the risk.** That's defensible only if the OneDev repo was readable by no one but you during 09-27 to 09-30 and nothing mirrored it. *Consequence:* if a copy exists anywhere, the key stays usable by whoever holds it.
4. **History rewrites (separate decision, Tier 0).** Removing the ID from 832's own history, or asking AEF to rewrite theirs, is defence in depth *after* rotation. It never replaces rotation.

The agent rotates nothing, rewrites nothing, and contacts no provider. Whichever you choose, a `runme.sh` can do the local half (update the store from a key you paste in, without echoing it).
