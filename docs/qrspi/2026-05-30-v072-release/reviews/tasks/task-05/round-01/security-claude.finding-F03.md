---
finding_id: F03
reviewer_tag: security-claude
round: 1
severity: low
change_type: correctness
referenced_files:
  - tests/unit/test-change-type-partition.bats:279-285
artifact: tests/unit/test-change-type-partition.bats
---

# Unvalidated File Paths from Fan-In Script Output Passed as `awk` File Arguments

Materialized from chat-only response by claude-sonnet-4.6.

```bash
seen=$(while IFS= read -r p; do
         awk -F': *' '...' "$p"
       done <"$KEPT" | sort -u | tr '\n' ' ')
```

`$KEPT` (`kept-findings.txt`) is written by the script-under-test. The paths are passed to `awk "$p"` without boundary validation. If the script has any output-injection bug (or a future version under test does), an attacker could inject paths like `/home/ci-user/.ssh/id_rsa`. The test would then open and read that file via awk — a silent file-read oracle.

Defense-in-depth gap: tests should not blindly trust the output of the script they are testing.

Fix: reject any path that doesn't start with `$dest/`:
```bash
[[ "$p" == "$dest/"* ]] || { echo "unsafe path in kept-findings.txt: $p" >&2; continue; }
[[ -f "$p" ]] || continue
```
