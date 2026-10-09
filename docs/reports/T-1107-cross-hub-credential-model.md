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

## Survey

Method: web search, 2026-10-09. Search results were summaries of spec pages; claims taken from secondary
write-ups are marked (2nd). Details not re-read in full (Matrix key rotation, NATS leaf-node credentials,
A2A field names) should be re-checked before anything is built on them.

### Comparison table

| System | First trust (out of band) | Credential form | Scope / least privilege | Rotation | Unilateral revocation | Offline / LAN |
|---|---|---|---|---|---|---|
| Matrix federation | None by default: keys fetched from the peer's `/_matrix/key/v2/server`, optionally corroborated by notaries | Per-server ed25519 signing keys + TLS cert; every request signed | Server-to-server is all-or-nothing; room and server ACLs limit participation | Several keys live at once; old ones kept as `old_verify_keys` | Server ACLs / block the peer's name; no key-level revoke | Works on a LAN if names resolve and certs verify; default leans on DNS + web PKI |
| XMPP s2s | Dialback: DNS lookup of the claimed domain (weak). SASL EXTERNAL: certificate chain to a CA | Cert (mTLS); dialback uses a shared secret within one trust domain | Whole-domain stream; no per-agent scope | Cert renewal | Drop the peer / block the domain | Dialback needs DNS; EXTERNAL needs a CA or pinned certs |
| SMTP (DKIM, MTA-STS) | Domain owner publishes keys and policy in DNS/HTTPS; no bilateral enrolment | DKIM: keypair, public half in DNS TXT. MTA-STS: web-PKI cert + policy file | Authenticates sender domain / transport only; authorisation is separate (SPF, DMARC, local policy) | DKIM selectors: publish new, retire old | Receiver blocks the domain; sender removes the DNS key | Needs DNS (and web PKI for MTA-STS); DANE needs DNSSEC |
| Tailscale / Headscale sharing | Admin sends a single-use invite link; recipient accepts | Per-node WireGuard keypair, control-plane issued; auth keys for enrolment | Share exposes one node only; ACLs of both tailnets apply; tags/groups stripped | Node keys expire (default 180 days) | Sharer removes the share; admin removes the node, key revoked at once | Control plane needed (Headscale is self-hosted, so LAN-only is possible) |
| Nebula | Each side gives the other its CA cert (or both join one CA) | Host cert signed by the CA carrying name, IP, groups; host private key | Groups in the cert; per-host firewall rules by group/port | Reissue certs | `pki.blocklist` of cert fingerprints, pushed to every host by hand; reload tears tunnels down | Fully offline: the CA is a file, lighthouses optional |
| SPIFFE/SPIRE federation | Operators exchange trust bundles once (`bundle show` / `bundle set`), or fetch from a bundle endpoint (`https_spiffe` or `https_web`) | X.509-SVID or JWT-SVID per workload; only the trust bundle is shared | Identity only; each relying party writes its own policy on SPIFFE IDs | Short-lived SVIDs; bundles refreshed from the endpoint | Remove the peer's bundle on your side | Yes with `https_spiffe` (no public DNS or CA); needs a SPIRE server |
| NATS accounts / JWT | Operator/account public nkeys exchanged; the importer holds the exporter's account key | Ed25519 nkeys and signed JWTs (operator -> account -> user) | Account exports named subjects; importer imports only those; private exports need an activation token | Signing keys per account; JWT expiry | Revocation list inside the account JWT; remove the import | Yes: JWTs verify offline against operator keys; leaf nodes are a separate auth domain |
| SSH CA | Host trusts the CA public key (`TrustedUserCAKeys`); user trusts the host CA in `known_hosts` | Signed certificate: principals, valid-after/before, extensions | Principals + `force-command` / source-address options per cert | Short validity; re-sign | KRL (`RevokedKeys`) per host; short expiry is the main control | Fully offline |
| OAuth2 client credentials, mTLS/DPoP-bound | Client registered with the AS (or metadata document); cert or key registered | Client secret or key; tokens bound to client cert thumbprint (mTLS) or a key (DPoP) | OAuth scopes / audience on every token | Short-lived tokens; rotate client cert/key | AS revokes client or token; resource server must check | Needs an AS; self-hostable but heavy for two peers |
| A2A | Agent card at `/.well-known/agent-card.json` declares schemes; credentials obtained out of band (2nd) | Per card: API key, HTTP, OAuth2, OIDC, mTLS; cards may carry a JWS signature (2nd) | Scopes via the declared scheme; no peer enrolment defined | Per scheme | Per scheme | Card discovery fine; real auth depends on the scheme |
| MCP authorization | Client discovers the AS via protected-resource metadata (RFC 9728); registration by DCR or client-ID metadata document | OAuth 2.1 bearer tokens with resource indicators | OAuth scopes on the server | Token expiry / refresh | AS-side | Needs an AS and HTTP; built for user-to-server, not peer-to-peer |

### Notes per system

**Matrix.** Trust is *fetched*, not provisioned: each homeserver publishes ed25519 keys and TLS fingerprints,
signs every federation request, and verifiers may corroborate through notary servers (the Perspectives
idea). Lesson: signed requests with a publishable public key beat a shared secret, but Matrix has no
least-privilege story between two servers.
https://spec.matrix.org/legacy/server_server/r0.1.2 · https://spec.matrix.org/latest/server-server-api/

**XMPP s2s.** Dialback (XEP-0220) is DNS-based, one-direction, and the XEP itself says it is "not a
security mechanism". SASL EXTERNAL over TLS (RFC 6120) is the strong one: the certificate is the identity.
Lesson: mutual certificates, each direction authenticated separately; DNS-derived trust is not enough for
confidential data.
https://xmpp.org/extensions/xep-0220.html · https://www.rfc-editor.org/rfc/rfc6120

**SMTP.** DKIM publishes a public key in DNS under a selector, so rotation is publish-new-then-retire-old;
MTA-STS pins a transport policy. Neither authorises anything; both prove "this domain said so". Lesson:
the selector pattern is a clean rotation model, and authentication and authorisation are separate layers.
https://www.rfc-editor.org/rfc/rfc6376 · https://www.rfc-editor.org/rfc/rfc8461

**Tailscale / Headscale.** Closest social model to ours: admin of node A creates a single-use invite
(unused links expire in 30 days), the other side accepts, and only that one node is reachable, filtered by
the ACLs of both tailnets. Either side can end it alone. Node keys expire. Lesson: *share one endpoint, not
the network*, with an explicit accept step. Headscale gives the same on a LAN.
https://tailscale.com/kb/1084/sharing · https://tailscale.com/kb/1010/node-key-expiry

**Nebula.** A tiny CA (a file) signs host certificates that carry groups; the firewall allows by group.
Across organisations, each side adds the other's CA cert, or one CA signs a cert for the peer with a
restrictive group. Revocation is a fingerprint blocklist pushed by hand to every host: unilateral, not
centralised. Lesson: offline-capable, the certificate carries the scope. A P256 blocklist bypass
(CVE-2026-25793, fixed in 1.10.3) is a reminder to pin the key, not only a cert hash.
https://nebula.defined.net/docs/config/pki · https://defined.net/blog/blocklisting/

**SPIFFE/SPIRE federation.** Federation exchanges *trust bundles* (public roots), never secrets. The first
bundle is seeded out of band (`bundle show` on one server, `bundle set` on the other, both ways); a bundle
endpoint then keeps it fresh. `https_spiffe` works without public DNS or CA. Each side writes its own
policy on the peer's SPIFFE IDs. Lesson: the right *shape* (exchange public material, each side decides
what the peer may do), but a heavy runtime for two hubs.
https://spiffe.io/docs/latest/architecture/federation/readme/ · https://spiffe.io/docs/latest/spiffe-specs/spiffe_federation/

**NATS.** Best match for "let a partner post to one subject". Account A *exports* a subject; account B
*imports* it; nothing else of A is visible to B. Identity is an ed25519 nkey; permissions are signed JWTs
verified offline against a trusted operator. Revocations live in the account JWT; signing keys limit the
damage of a leak. Lesson: scope the grant to a named subject, let the exporter sign it; public keys are
exchanged, not secrets.
https://docs.nats.io/running-a-nats-service/configuration/securing_nats/auth_intro/jwt · https://docs.nats.io/running-a-nats-service/nats_admin/security/jwt

**SSH CA.** The host trusts a CA key; the CA signs certs with principals, a validity window and
forced-command or source-address options. Revocation is a KRL; short validity is the main control. Lesson:
a signed, expiring, scoped grant checked against one local trust anchor works fully offline; per-cert
options are a good model for "message-only".
https://android.googlesource.com/platform/external/openssh/+/master/PROTOCOL.certkeys

**OAuth2 mTLS / DPoP.** RFC 8705 binds a token to the client certificate thumbprint (`cnf.x5t#S256`);
RFC 9449 DPoP binds it to a key via a signed header. Both make a stolen token useless. Both need an
authorisation server, which we do not want mandatory. Lesson: copy *sender-constraining* (a credential
useless without the holder's private key), not the OAuth machinery.
https://www.rfc-editor.org/rfc/rfc8705 · https://www.rfc-editor.org/rfc/rfc9449 · https://workos.com/blog/mtls-dpop-token-binding-sender-constrained-oauth

**A2A.** A public agent card declares how to authenticate, using OpenAPI-style security schemes, and may be
JWS-signed. Credential provisioning is left out of band. Lesson: the card is a useful template for "what
does this hub accept", but A2A does not solve peer enrolment. (2nd: field names differ between sources.)
https://tyk.io/learning-center/a2a-security-the-developers-complete-guide/ · https://a2a-protocol.org/latest/specification/

**MCP authorization.** OAuth 2.1 plus RFC 9728 protected-resource metadata and RFC 8414 server metadata.
Built for a user-delegated client talking to a server, and needs a reachable authorisation server. Lesson:
the agent ecosystem's default is "get a scoped, expiring token from an AS"; that does not fit an offline
peer link between two operators.
https://modelcontextprotocol.io/specification/latest/basic/authorization

### Patterns that recur

1. **Exchange public material, never secrets.** Every system above except dialback and the TermLink hub
   secret authenticates with a keypair or cert; only a public key, fingerprint, CA cert or bundle crosses
   the boundary. That satisfies "a credential never travels over the channel it unlocks" by construction.
2. **Each direction is its own grant.** Dialback, Tailscale shares and NATS export/import are one-way;
   two-way is two grants.
3. **Scope is a named thing, not "the hub".** Tailscale: one node. NATS: one subject. SSH: principals and
   forced command. Nebula: groups plus port rules.
4. **The grantor revokes alone, locally.** Remove the share, import, trust anchor, bundle or blocklist
   entry on your own side; nobody asks the peer.
5. **Expiry as a backstop.** Short-lived certs or tokens (SSH, SPIFFE, Tailscale) cap what a missed
   revocation can cost.

## Options for 832 / TermLink

Assumptions about TermLink, taken from the task brief and not re-read in its source: the hub authenticates
clients with one hub-wide secret; per-session capability tokens (scopes observe / interact / control /
execute) are minted by the hub; remote hub certs are pinned on first use. The hub is a separate project, so
"TermLink must add" means a proposal to that project, not something 832 can build.

### Option A: per-peer keypair, allow-list, message-only scope

Each hub lists peers by public key (ed25519). A peer authenticates by signing a hub-issued challenge. An
allow-list entry carries a scope (post to `inbox:*` or a named topic list) and an optional expiry. Revoke
by deleting the entry.

- *TermLink must add:* a peer identity type beside the hub secret; challenge-response auth for it; a
  per-peer scope enforced on every verb (a `message` scope narrower than `interact`); an allow-list with
  `peer add / list / revoke`.
- *832 can do alone:* generate and keep its own keypair; write the exact request (scope, topics, expiry);
  prepare the runme job that adds the peer's public key once TermLink supports it. Nothing enforceable
  without TermLink.
- Fit: patterns 1, 3, 4, 5. Closest to SSH `authorized_keys` options and Nebula groups.

### Option B: NATS-style export / import of one inbox topic

The hub owner *exports* a named inbox topic to a named peer key; the peer *imports* it. A signed grant
(topic, direction, expiry, grantee key, signed by the exporter's hub key) is verified offline by the
importer. Two grants give two-way traffic.

- *TermLink must add:* everything in A, plus a signed-grant format, a grant store on both hubs and
  topic-level enforcement.
- *832 can do alone:* nothing enforceable; it can draft the grant format.
- Fit: strongest least privilege (the grant names the one topic) and easy to audit. Largest build; pays off
  only with many peers or topics.

### Option C: SPIFFE-style federated trust bundles

Each operator runs a small CA per hub. Hubs exchange CA certs once, both ways, out of band. Peers get
short-lived client certs from their own CA; the other hub trusts the bundle and maps cert identity to
policy.

- *TermLink must add:* mTLS client auth on the hub, a trust-bundle store (`bundle set/show`), a mapping
  from cert identity to scope, and issuance/renewal tooling.
- *832 can do alone:* nothing enforceable; it could generate its own CA and cert to prepare.
- Fit: the standard answer at scale, expiry for free. Too much machinery for one partner pair, and it adds
  a CA to operate.

### Option D: peering handshake verb with operator approval on both sides

`termlink peer request <hub>` sends a signed request (public key, hub fingerprint, name, wanted scope) into
a *pending* queue on the other hub. The receiving operator confirms the fingerprint over a second channel
and approves, which writes an Option A allow-list entry (or an Option B grant). The same on the reverse
leg. Tailscale's invite flow, with fingerprint confirmation as in SSH TOFU done properly.

- *TermLink must add:* Option A, plus the pending-request queue and `peer approve / deny / list`. The
  request endpoint must be unauthenticated, rate-limited and size-capped: the one new attack surface.
- *832 can do alone:* the operator-facing side: runme jobs for approve, a checklist for confirming
  fingerprints out of band, key-handling hygiene.
- Fit: "the operator decides" becomes part of the protocol. It is A with a better enrolment path, so a
  layer on A, not an alternative.

### What 832 can do alone today, whichever option is chosen

1. Write the requirement as a TermLink feature request (peer identity, message-only scope, per-peer
   revoke, no shared secret), citing the patterns above.
2. Keep the T-1106 stopgap narrow: if possible, give the partner link its own hub instance so the secret
   handed over unlocks only what the partner should see. The client's confidential maps must not live on a
   hub whose secret the partner holds.
3. Rotate the stopgap secret on a calendar and on any staffing change, and record each hand-over; the
   shared secret is the only credential that exists for now.

## Recommendation

**Option A as the permanent measure, delivered with Option D's approval flow; B and C only if the number of
peers grows.**

- Every comparable system exchanges *public* material and keeps the secret with its holder. A per-peer
  keypair does the same, so the whole-hub secret disappears and "credentials never travel over the channel
  they unlock" holds by construction: a public key can be pasted into chat without risk.
- One new scope gives the asked-for least privilege ("message our agents and nothing more"), and each side
  revokes unilaterally by deleting one allow-list line.
- It works LAN-only and offline: no IdP, no CA, no authorisation server. That rules out OAuth/MCP-style
  designs and makes SPIFFE heavier than needed.
- D makes provisioning the operator's decision on both sides and is the right place for fingerprint
  confirmation. Build A first, add D once there is more than one or two peers.
- B is cleanest on paper but its signed-grant format and store are more than a two-party link needs; C adds
  a CA to run.
- Add a short expiry to each entry (for example 90 days, renewable) as the backstop from pattern 5.

Whether to file this as a TermLink feature request is the operator's decision; this report does not make it.

**Open questions for TermLink:** does a `message`-only scope exist or can the current four be narrowed; can
a client be restricted to a topic prefix such as `inbox:*`; how does the hub bind a client key to a session
identity; can a second hub instance with its own secret run on the same host?

## Dialogue Log

- 2026-10-09, operator: chose option 1 (full hub secret out of band) as the immediate measure, and asked:
  "we do need to find a permanent measure to get this done. Could we research how this is often done also
  in the field with similar solutions?" → this inception.
