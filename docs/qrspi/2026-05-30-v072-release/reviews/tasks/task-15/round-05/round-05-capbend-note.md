---
round: 5
fix_cycle: 5
cap: 3
cap_bend_number: 2
authority: user blanket "cap bend as needed to get good quality final result"
constraint: additive only — "substantive refactors doesnt sound good"
base_sha: 84af550a962bcede69cef044d62241a14e9ac3ad
---
Fix cycle 5 is the 5th fix cycle (cap=3; bent once at fix-4). Bent again per user authority.
All three fixes are strictly additive grep assertions on EXISTING tests (no new tests, no refactors):
- tc F01 (L615): add false-none failure-mode grep to the "covers malformed-field and false-none cases" test body.
- tc F02 / tc-codex F01 (L495): add a "public-symbol rename" framing grep to worked-example-A pin.
- tc F03 (L580): tighten the G18 `--` separator pin to require the literal `--` token (mirrors G15 sibling L371 rigor).
