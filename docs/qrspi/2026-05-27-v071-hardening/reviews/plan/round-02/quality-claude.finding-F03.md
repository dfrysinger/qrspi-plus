---
finding_id: R2-F03
severity: low
change_type: modified
artifact: plan
round: 2
reviewer: quality-claude
referenced_files:
  - docs/qrspi/2026-05-27-v071-hardening/plan.md
  - docs/qrspi/2026-05-27-v071-hardening/design.md
  - docs/qrspi/2026-05-27-v071-hardening/structure.md
---

# R2-F03: Task 3 description omits function name while design DKR3 explicitly delegates final naming to Plan

## Location

`plan.md` → Task 3, Description paragraph and all Test expectations.

## Observation

`design.md` DKR3 states:

> Add `extract_section_fence_aware` **(working name; Plan settles final name)** to `tests/helpers/skill-markdown.bash` as a sibling to `extract_section`.

Design explicitly delegates the canonical function name to the Plan artifact.

`structure.md` §Interfaces then provides the function signature using that name:

```bash
# extract_section_fence_aware(file, start_pattern)
extract_section_fence_aware()
```

The Task 3 description in the current plan (after round-2 changes) reads:

> "A new fence-aware section-extraction function is added to the shared test-helper library alongside the existing heading-anchored `extract_section`."

Neither the description nor any of the eight test expectations names the function. The description also generically refers to "the shared test-helper library" rather than explicitly naming `tests/helpers/skill-markdown.bash` (the target file is listed in the Target files line, but not in the description prose).

The round-2 simplification of the Task 3 description condensed the previous wording (which also didn't name the function) but did not add the function name that design delegated to Plan.

## Why it matters

The function name is an implementation contract. The test-writer writing `tests/unit/test-helpers-skill-markdown.bats` must know the function name to write the `@test` blocks and the `load` call. An implementer who reads Task 3 in isolation — without cross-referencing structure.md — cannot determine the function name from the plan and must either:

(a) Fall back to structure.md for the name (an extra lookup that the design intended Plan to eliminate by "settling the name"), or
(b) Invent a name that may differ from the structure.md interface spec, creating a naming inconsistency.

The risk is low because structure.md is a required companion artifact and `extract_section_fence_aware` is named there. However, the design explicitly says Plan is the authority on this name, and the plan delegates it silently back to structure.md. The "no vague language" criterion and the design's explicit delegation both point toward naming the function in the task.

## Suggested resolution

Add the function name to the Task 3 description (one line is sufficient):

```
A new fence-aware section-extraction function, `extract_section_fence_aware`, is added to `tests/helpers/skill-markdown.bash` alongside the existing heading-anchored `extract_section`. ...
```

Optionally, the first test expectation could also reference the name:

```
- The new `extract_section_fence_aware` function returns content from the anchor line (inclusive) through the last line before the next out-of-fence section boundary
```

This matches the interface name in structure.md and fulfills the design's intent that Plan "settles the final name."
