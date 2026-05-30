---
finding_id: R1-F02
severity: low
change_type: scope
referenced_files: [docs/qrspi/2026-05-30-v072-release/goals.md]
artifact: goals
round: 1
reviewer: scope-claude
---

**G21 "What we know so far" presents verbatim bats assertion code as a "Known-good replacement" rather than as a candidate Design should weigh — assertion text that the Goals DEFERS rule assigns to Structure/Plan/Implement.**

The Goals OWNS rule requires solution ideas to appear "framed as candidates Design should weigh — never as commitments." G21 introduces a "Known-good replacement" block with verbatim bash code:

> **Known-good replacement** (already used in R5 pins): `body="$(_extract_h4 ...)"; [ -n "$body" ]; echo "$body" | grep -q "expected text"`

The framing "Known-good replacement (already used in R5 pins)" is not candidate language — it is the language of an already-decided solution. Nothing in the surrounding context asks Design to weigh it against alternatives; the alternatives listed later ("Retrofit-only," "Retrofit + lint rule," "Retrofit + lint rule + bats upstream investigation") are about the scope of accompanying changes, not about whether the verbatim assertion pattern itself is correct.

The Goals DEFERS rule explicitly names "assertion text → Structure / Plan / Implement." The literal bash assertion form (`[ -n "$body" ]; echo "$body" | grep -q "expected text"`) is test assertion code. Its canonical home is the Plan artifact (per-task Test Expectations block) or the bats file produced at Implement time.

**Impact:** Minor. The specific assertion pattern is indeed already used in the codebase (R5 pins), so Design is unlikely to select a substantially different form. The issue is structural — Goals is pre-deciding test implementation details rather than leaving the assertion form to Plan/Implement to specify with the full context of the test-harness conventions.

**Expected correction:** Replace the "Known-good replacement" block with a problem-framing or candidate framing:

- Either compress to intent: "the `[ -n "$body" ]; grep -q` decomposition (already used in R5-era pins) is the safe replacement; Design should confirm the correct decomposition form."
- Or reframe under "Candidates Design should weigh:" with the R5 pattern as one option and the retrofit-scope decision as the other axis.

The verbatim assertion code itself should be deferred to the Plan-phase task's Test Expectations block where it belongs.
