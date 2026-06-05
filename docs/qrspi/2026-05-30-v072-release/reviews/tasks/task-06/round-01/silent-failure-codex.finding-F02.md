---
finding_id: R1-F02
reviewer_tag: silent-failure-codex
round: 1
task: 6
severity: medium
change_type: test_coverage
referenced_files:
  - tests/unit/test-verifier-agent-file.bats
---

# F02 — `score:` integer 0–100 requirement test is too weak (regex permits non-integer documentation)

## Location

`tests/unit/test-verifier-agent-file.bats:76`

```bash
echo "$body" | grep -qE 'score:.*int|score:.*0.*100|integer.*score:|frontmatter.*score:|score:.*frontmatter' \
  || { echo "verifier agent does not require score: integer 0-100 in sidecar frontmatter"; return 1; }
```

## Silent-failure risk

The alternatives `frontmatter.*score:` and `score:.*frontmatter` match ANY prose mentioning frontmatter near a `score:` field — regardless of whether the agent constrains `score:` to integer 0–100. Contract drift (e.g., the agent file allowing `score:` as a float, a string, or a different range) would be undetected; the test stays green; downstream fan-in parsing would fail late or be misdiagnosed.

## Fix

Require BOTH the type signal AND the range signal:

```bash
# Must document score: is an integer AND that the range is 0..100
echo "$body" | grep -qiE 'score.*integer.*0.*100|score.*int.*0.*100|integer 0.{0,3}100|score:.*<int.*0.{0,3}100>' \
  || { echo "verifier agent does not require score: integer 0-100 in sidecar frontmatter"; return 1; }
```

Or, if the implementer documented a specific canonical form (e.g., `score: <int 0..100>` per the agent body), assert that literal form:

```bash
echo "$body" | grep -qF 'score: <int 0..100>' \
  || { echo "verifier agent missing canonical score: <int 0..100> contract"; return 1; }
```
