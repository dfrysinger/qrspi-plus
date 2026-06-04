---
finding_id: R4-F03
severity: medium
change_type: correctness
referenced_files: [tests/acceptance/v07-phase1/test-phase1-acceptance.bats]
---

# AC5: python3/pyyaml hard dependency with misleading error transform

**Location:** `tests/acceptance/v07-phase1/test-phase1-acceptance.bats` L2075–2076.

```bash
python3 -c "import sys, yaml; yaml.safe_load(sys.stdin.read())" <<<"$yaml" \
  || { echo "Sub-Threshold Observations YAML template did not parse cleanly"; ...; return 1; }
```

When `python3` is absent or `pyyaml` is not installed, the OR branch fires and falsely reports "YAML template did not parse cleanly" — sending the debugger down the wrong path. Infrastructure failure silently transformed into content-failure report.

Pattern NOT followed: same file uses `command -v yq` / `command -v shellcheck` skip guards (L75, L82). Convergent with tc-claude.finding-F03 (PI-V072-T10-021).

**Recommended fix:** add `command -v python3` and `python3 -c "import yaml"` skip guards before the parse call.
