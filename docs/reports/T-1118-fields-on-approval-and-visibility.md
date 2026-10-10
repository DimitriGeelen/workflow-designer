# T-1118 — Unknown content becomes a designer field only on operator approval; field visibility

**Status:** inception, scope captured, not explored yet. **Origin:** the operator's ruling on T-347, 2026-10-10.

## The ruling this builds on (T-347)

- **R1 (build, T-347):** content the designer does not understand is kept and written back unchanged. Nothing is lost
  silently any more. (R1a, a second pool kept with a notice on import, awaits confirmation.)
- **R2 (this inception):** when the designer meets an unknown kind of content, it **suggests** turning it into a real,
  editable field; the **operator approves** each one. Valuable twice: the field becomes editable, and the suggestions
  show which fields real files use that the designer is missing.

## Scope, in the operator's words

1. "An option to show or not in certain projects — we can extend, but not everything is desirable." → visibility **per project**.
2. "Maybe even per workflow you want to show or hide certain fields for elements." → visibility **per workflow, per element type**.
3. "You look what you need and then you hide the not used fields, because we've got a lot of pollution, a lot of empty
   fields there where nothing is shown." → **show only what is used**: the properties panel hides empty / unused fields
   by default, so the panel shows what this map actually carries.

## Questions to answer (IW-1..5 in the task)

1. Detecting a new kind and wording the suggestion.
2. The approval path and where an approval is recorded.
3. Where visibility lives (project / workflow / element type) and which level wins.
4. Hiding unused fields without hiding anything that carries a value, and how a user reveals a hidden field to fill it.
5. First kinds: Greenfield's extra pools and message flows (T-1096).

## Dialogue Log

- 2026-10-10, operator on T-347: "certainly one" (R1); R2 "on suggestion… tier 0, with operator… it can be really
  valuable… we're also missing"; "an option to show or not in certain projects… not everything is desirable".
- 2026-10-10: "maybe even per workflow you want to show or hide certain fields for elements."
- 2026-10-10: "you look what you need and then you hide the not used fields because we've got a lot of pollution, a lot
  of empty fields there where nothing is shown. So put that also in the inception please."
