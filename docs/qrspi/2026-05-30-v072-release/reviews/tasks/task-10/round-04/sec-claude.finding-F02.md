---
finding_id: R4-F02
severity: low
change_type: correctness
referenced_files: [skills/using-qrspi/SKILL.md]
---

# Path-traversal prose constraint contradicts canonical example

**Location:** `skills/using-qrspi/SKILL.md` ~L997-1010.

Prose: `finding_paths[]` values MUST be relative paths **within the current `round-NN/` directory**. Canonical example: `round-01/quality-claude.finding-F02.md` — paths START with `round-01/`, referencing a SIBLING round directory from `reviews/{step}/round-NN-dispositions.md` perspective. They are NOT "within the current round-NN/" — they point INTO a different round.

AC5 test checks `(\.\./|^\s*-\s*/)` — necessary but insufficient. Doesn't catch round-boundary crossing or prose/example inconsistency.

**Concrete scenario:** future developer building path-validation tooling implements per-prose validator → fails against canonical example → either loosens validator (`../private/secret.txt` passes since `../` check was only guard) or prohibits cross-round paths (feature unusable).

LOW because section is "informational only / consumed by no current script" but inconsistency sets bad precedent.

**Recommended fix:** update prose to "within the current `reviews/{step}/` tree" OR update example to use paths relative to round-NN-dispositions.md location.
