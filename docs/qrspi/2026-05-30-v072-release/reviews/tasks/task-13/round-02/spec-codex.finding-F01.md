---
finding_id: R2-F01
reviewer_tag: spec-codex
severity: medium
change_type: correctness
referenced_files: [tests/unit/test-scope-tagger-dispatch.bats, scripts/round-prepare.sh, tasks/task-13.md]
---

# Missing Bats coverage for malformed prior-anchor and empty prior-scope-set branches

**Spec requirement (task-13.md L49, Test Expectations):**
- "later-round invocation fails loudly for missing **or malformed** `round-(NN-1)-commit.txt`"
- "narrowing-eligible later-round invocation with scope tagging enabled fails loudly for missing **or empty** `round-(NN-1)-scope-set.txt`"

**Observed coverage in `tests/unit/test-scope-tagger-dispatch.bats`:**
- Missing prior anchor — covered (L719).
- No-stray-anchor on missing prior anchor — covered (L741).
- Missing prior scope-set — covered (L771).
- **Malformed prior anchor — NOT covered.**
- **Empty prior scope-set — NOT covered.**

**Distinct untested code branches in `scripts/round-prepare.sh`:**
- L194–203: malformed anchor (fails `^[0-9a-f]{40}\n$` shape) → exit 1, diagnostic "malformed prior-round commit anchor".
- L215–218: empty scope-set (`! -s`) → exit 1, diagnostic "empty prior-round scope-set".

**Disposition: ADOPT.** Add two additive bats fixtures pinning the malformed-anchor and empty-scope-set exit-1 branches with diagnostic-language assertions. Additive only — no refactor.
