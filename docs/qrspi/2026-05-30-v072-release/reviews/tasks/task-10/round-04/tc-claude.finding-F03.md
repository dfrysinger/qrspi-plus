---
finding_id: R4-F03
severity: low
change_type: style
referenced_files: [tests/acceptance/v07-phase1/test-phase1-acceptance.bats]
---

# AC5 calls python3/PyYAML without env availability guard

AC5's YAML-parse validation step calls `python3 -c "import sys, yaml; yaml.safe_load(...)"` without a `command -v` or `import yaml` guard. On macOS without PyYAML installed, `import yaml` raises `ModuleNotFoundError` and the test fails with a misleading parse-failure error.

Precedent: same file already uses skip guards for `yq` (L74-75) and `shellcheck` (L81-83).

**Recommended remediation:**
```bash
python3 -c "import yaml" 2>/dev/null \
  || skip "python3 PyYAML not available (env-dep — passes in CI)"
```
Alternatively, validate with grep-only structural assertions.
