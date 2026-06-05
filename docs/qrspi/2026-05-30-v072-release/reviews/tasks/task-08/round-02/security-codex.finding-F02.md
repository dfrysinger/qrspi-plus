---
finding_id: R2-F02
severity: medium
change_type: correctness
artifact: code
round: 2
reviewer: security-codex
model: gpt-5.3-codex
referenced_files:
  - agents/qrspi-finding-verifier.md#L69-L74
  - tests/acceptance/v07-phase1/test-phase1-acceptance.bats#L1151-L1155
---

# Cite Check can be bypassed with citation-shape obfuscation / mixed citations

**What's wrong:** The verifier spec only defines line-range syntax as `path:line` / `path:line-line`, but acceptance fixtures use another shape (`README.md#L99999-L99999`). This ambiguity means non-canonical or obfuscated citation formats may not be parsed as line-ranged cites and can fall through unchecked.

**Concrete attack scenario:** An attacker includes one real citation plus one fabricated out-of-range citation written as `file#Lx-Ly` (or whitespace/Unicode-obfuscated variant). If parser logic only enforces `path:line` forms, the fabricated cite is not checked; the valid cite still supports a non-zero score, bypassing hallucination rejection.

**Fix:** Define and enforce a canonical citation grammar (including `#L` if supported), normalize before validation, and fail closed on unparseable/ambiguous citation tokens instead of silently skipping them.
