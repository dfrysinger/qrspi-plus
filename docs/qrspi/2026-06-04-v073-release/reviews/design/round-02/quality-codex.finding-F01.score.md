---
verifier_status: passed
score: 70
actual_model: unknown
defect_class: naming-inconsistency
---

Verified the inconsistency in design.md: lines 319, 330, 335 use the `<phase>` placeholder (which resolves to `integrate` per the skill-directory convention `skills/integrate/SKILL.md` cited on line 321 and across the section), while the acceptance bullet on line 385 hardcodes `reviews/integration/orchestration-boundary.md`. Implementers writing the acceptance bats check would write the path differently depending on which spec line they followed; the v0.7.3 self-host acceptance check specifically references `reviews/integration/...` while the script contract writes to `reviews/<phase>/...` (which would be `reviews/integrate/`). This is a real, mechanically-verifiable contract ambiguity that affects script + test implementation. Score reflects high confidence and real impact, tempered slightly because the fix is mechanical (pick one term and replace) and a careful Plan-phase pass would likely catch it.
