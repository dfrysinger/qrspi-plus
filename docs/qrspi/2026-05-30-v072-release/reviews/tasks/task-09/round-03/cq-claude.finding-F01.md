---
finding_id: R3-F01
reviewer_tag: cq-claude
round: 3
severity: low
change_type: clarity
referenced_files: [scripts/run-codex-review.sh]
---

# cq-claude F01: Stale "Hand-built JSON object" lead comment contradicts jq implementation

**Location:** scripts/run-codex-review.sh lines 589-590

The function's opening rationale reads "Hand-built JSON object — values are controlled (no embedded quotes from untrusted input)." That describes the OLD `printf -v entry` build, which R2 replaced with `jq -nc --arg` (lines 612-617). The "values are controlled" justification was the original printf-safety reasoning; jq's `--arg` makes that property unconditional, so the trust-model framing is now misleading.

**Suggested fix:** Replace lead sentence with one describing jq:

```bash
# JSON entry constructed via jq (defense-in-depth: jq guarantees
# well-formed output regardless of input content). The vendor is
# fixed to 'openai-codex' for this script; ...
```

**Convergent with cq-codex F01.**
