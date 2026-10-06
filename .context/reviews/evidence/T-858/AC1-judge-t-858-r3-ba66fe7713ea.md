# T-858 AC1 — independent reviewer evidence (judge-t-858-r3-ba66fe7713ea)

Revision under review: 6b0b84b634c7912634cfd94daa5e2edc070d56cf
Target: live Watchtower http://192.168.10.107:3013 (footer: designer-v0.15.3-165-gaa85f51a)
Method: real Chromium (Playwright 1400x900), page loaded the way an operator loads it, with the
shipped base.html showToast and /static/htmx-toast.js. Driver script copied as AC1-drive-*.py.txt.

## Safety (why I did not click a literal Approve button)
Clicking a real Approve is a consequential action if the stale-token repro fails. So every POST from
the browser had its CSRF header overwritten with a garbage token, cookies were cleared after load
(the tab-1 session goes stale, the same as step 2's fallback), and the request went through the page's real
htmx stack (htmx.ajax POST to /approvals/reviewer-probe/approve, a path with no handler). The CSRF
check rejects it before routing, so nothing could change. The response is consumed by the same
htmx:responseError -> htmx-toast.js extractor -> showToast path as a button click.

## Half 1: htmx 403 toast
- Network: POST /approvals/reviewer-probe/approve -> 403, header HX-Error-Kind: csrf
- curl of the same request: body `<div class="toast-error">Session expired — reload the page and try again.</div>`
  Content-Length 81 bytes. The brief says 79. The difference is the em dash: 1 character but 3 bytes in UTF-8. Not a defect.
- The rendered toast element (.wt-toast.error) innerText is exactly:
  `Session expired — reload the page and try again.`
  One sentence, with no `function(){`, no `var t=`, no page title, and no truncation. The box is 347x36px and scrollWidth equals
  clientWidth (347=347), so nothing is clipped. Computed style: white on rgb(198,40,40), 13.6px.
- Light theme: AC1-toast-full-*.png and AC1-toast-closeup-*.png. The toast is top-right, fully legible.
- Dark theme (wt-theme=dark): AC1-toast-closeup-dark-*.png. Same text, legible.

## Half 2: plain navigation 403 keeps the full-page recovery UI
- A non-htmx form POST (normal top-level navigation, no HX-Request) with a stale token, in a fresh tab.
- Result: title "Session expired — Workflow designer". The full page is 64,857 bytes of HTML with the Watchtower nav,
  the "Session expired" heading and explanation, "Technical detail: CSRF token missing or invalid", and the
  **Reload page** and **Return to Dashboard** buttons. See AC1-navigation-403-page-*.png.
- So the caller check in app.py (HX-Request == "true" or /api/ prefix) does not take over the
  navigation path.

## Code cross-check
.agentic-framework/web/app.py ~L438-477 returns the escaped one-div fragment only to HX-Request or /api/
callers. The fragment has no <script> and no <title>, so htmx-toast.js's tag-stripper
(.replace(/<[^>]*>/g,'').trim().substring(0,100)) produces exactly the sentence.

## Caveats
- Headless Chromium, not the operator's own browser profile. Light and dark themes were both checked at 1400x900.
- The trigger is synthetic (htmx.ajax), not a click on a row's Approve button. I chose this on purpose so I would not
  risk a real approval. The consumer path is the same one.

Verdict: green
