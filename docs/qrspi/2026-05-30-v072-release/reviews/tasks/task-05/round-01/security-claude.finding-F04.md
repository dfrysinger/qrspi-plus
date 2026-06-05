---
finding_id: F04
reviewer_tag: security-claude
round: 1
severity: low
change_type: correctness
referenced_files:
  - tests/unit/test-change-type-partition.bats:408-410
artifact: tests/unit/test-change-type-partition.bats
---

# Duplication-Check Exclusion Filter Matches Filename as Prefix, Not Exact Path

Materialized from chat-only response by claude-sonnet-4.6.

```bash
hits=$(grep -rEn 'style[[:space:]|,]+clarity[[:space:]|,]+correctness[[:space:]|,]+scope[[:space:]|,]+intent' skills/ scripts/ 2>/dev/null \
       | grep -vE '^(skills/reviewer-protocol/SKILL\.md|scripts/verifier-fan-in\.sh):' \
       || true)
```

Two issues:

1. Inside the POSIX bracket expression `[[:space:]|,]`, `|` is a LITERAL pipe character, not an alternation operator. The pattern only matches `\s`, `|`, or `,` as separators — enum lists with multiple spaces, tabs, or other separators are not matched.

2. The exclusion filter `^(skills/reviewer-protocol/SKILL\.md|scripts/verifier-fan-in\.sh):` matches the filename as a prefix. A file at `skills/reviewer-protocol/SKILL.md.bak` would produce lines prefixed `skills/reviewer-protocol/SKILL.md.bak:` — but the `:` in the exclusion is OUTSIDE the alternation group, so `^skills/reviewer-protocol/SKILL\.md` (without `:`) matches `skills/reviewer-protocol/SKILL.md.bak:`. Actually wait — the regex is `^(...):` so the `:` IS required. But the `.` in `SKILL\.md` is escaped so it's literal. So `SKILL.md.bak:` does NOT match `SKILL\.md:` (because between `md` and `:` there's `.bak` — `md:` vs `md.bak:`). The pattern is therefore correct on closer reading.

   Re-examining: the actual gap is the POSIX bracket-expression bug in (1). A backup file like `SKILL.md.bak` containing a hardcoded `style|clarity|correctness|scope|intent` alternation would actually be DETECTED (not excluded), because `SKILL.md.bak:` does not match `SKILL\.md:`. Downgrading severity.

Fix: rewrite the separator class to handle multiple separator forms, e.g.:
```bash
'style[[:space:]]*[,|]?[[:space:]]*clarity[[:space:]]*[,|]?[[:space:]]*correctness...'
```
Or just rewrite to match the multiline JSON/YAML array form used in real code.
