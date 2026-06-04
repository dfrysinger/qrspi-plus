---
finding_id: R1-F03
reviewer_tag: silent-failure-codex
round: 1
task: 6
severity: low
change_type: test_coverage
referenced_files:
  - tests/unit/test-verifier-agent-file.bats
---

# F03 — Sidecar-path construction test can pass without enforcing the `.md → .score.md` derivation rule

## Location

`tests/unit/test-verifier-agent-file.bats:34`

```bash
@test "sidecar path construction rule is documented (.md -> .score.md)" {
  awk '/^---$/{n++; next} n>=2{print}' agents/qrspi-finding-verifier.md \
    | grep -qE '\.md.*->.*\.score\.md|\.md.*→.*\.score\.md|replacing.*\.md.*\.score\.md|<reviewer-tag>.*finding-F.*\.score\.md|sidecar_path.*\.score\.md'
}
```

## Silent-failure risk

The two loose alternatives `<reviewer-tag>.*finding-F.*\.score\.md` and `sidecar_path.*\.score\.md` match the agent file even if the explicit derivation rule (`<finding_file_path>` with `.md` → `.score.md`) is removed. As long as the canonical path example or the `<sidecar_path>` placeholder line exists, the test passes — but the construction rule itself could be deleted, weakening the contract.

The test name claims to enforce the `.md -> .score.md` rule but the regex actually allows passage on weaker evidence.

## Fix

Remove the loose alternatives. Keep only the alternatives that prove the derivation rule:

```bash
grep -qE '\.md.*->.*\.score\.md|\.md.*→.*\.score\.md|replacing.*\.md.*\.score\.md'
```

If the implementer wanted to allow a canonical-example variant, name it explicitly (e.g., a literal canonical-form line check) rather than a permissive `.*` regex.

## Severity rationale

Low: the agent file currently does carry the explicit `.md → .score.md` derivation rule (line 36), so the test is not currently vacuous in practice. But the regex permits future contract weakening to ship green — that is the silent-failure surface.
