---
finding_id: R8-F02
severity: informational
change_type: correctness
referenced_files:
  - tests/unit/test-codex-review-host-detection.bats
artifact: task-06/tests/unit/test-codex-review-host-detection.bats
round: 8
reviewer: sec-claude
scope: test [r7-sec.F02] covers combined scenario, not pure symlink-in-trusted-prefix
toctou_note: included below as a secondary point
---

## Title: `[r7-sec.F02]` Tests Combined `..`+Symlink, Not Pure Symlink-in-Trusted-Prefix; and TOCTOU Note

### A. Test Coverage Gap — `[r7-sec.F02]`

**Location:** `tests/unit/test-codex-review-host-detection.bats`, new test `[r7-sec.F02]`

The test constructs its attack as:

```bash
local injected_path="/usr/../${TMP_DIR}/trusted-sim/usr/bin"
# command -v gh → "/usr/../$TMP_DIR/trusted-sim/usr/bin/gh"
# realpath resolves .. AND follows the symlink at that path → $FAKE_BIN/gh
```

This is **a `..`-injection attack that also happens to pass through a symlink**, not a pure
symlink-inside-trusted-prefix attack. The pure symlink scenario (R6-F02's original attack
vector) is:

```bash
# No .. in PATH — the path returned by command -v is already canonical-looking
ln -sf /tmp/evil/gh /opt/homebrew/bin/gh
COPILOT_CLI=1 PATH=/opt/homebrew/bin detect_host
# command -v gh → "/opt/homebrew/bin/gh"   (no .. anywhere)
# Without realpath: [[ "/opt/homebrew/bin/gh" == /opt/* ]] → TRUE → FORGED
# With realpath:    realpath /opt/homebrew/bin/gh → /tmp/evil/gh → fails prefix → SAFE ✓
```

This second case is **not tested** by either new test. The code handles it correctly (realpath
follows symlinks unconditionally, independent of `..` segments), but there is no RED/GREEN
regression test confirming the behaviour. If a future refactor skips symlink resolution for
paths that appear to lack `..` segments, the pure-symlink attack would silently re-open.

**Recommended addition:**

```bash
@test "[r7-sec.F02-pure] symlink at trusted prefix path resolved to untrusted target rejected" {
  # No .. in PATH — the fake gh lives at a path that string-matches /opt/* but whose
  # realpath target is $FAKE_BIN/gh (outside any trusted prefix).
  local opt_sim="$TMP_DIR/opt-sim"
  mkdir -p "$opt_sim"
  ln -s "$FAKE_BIN/gh" "$opt_sim/gh"
  # opt_sim is /tmp/...; does NOT start with /opt/ at the resolved level.
  # We can't write to real /opt, so we simulate via an existing FAKE_BIN symlink
  # and test that realpath follows it.  Skip test if /opt isn't accessible.
  run bash -c "
    export QRSPI_SOURCE_ONLY=1
    export COPILOT_CLI=1
    export PATH='${opt_sim}:/usr/bin:/bin'
    . \"$WRAPPER\"
    detect_host
  "
  # opt_sim is under /tmp (or /private/tmp) — no trusted prefix → safe
  [ "$status" -eq 0 ]
  [ "$output" = "claude-code" ]
}
```

Note: this test only verifies the path starts outside trusted prefixes — the string-prefix
bypass for the pure symlink case requires the symlink to live *inside* a real trusted prefix
(`/opt/`, `/usr/`, `/Applications/`), which is difficult to fake in CI without real write
access. Documenting this limitation is acceptable; the code fix is correct.

---

### B. TOCTOU (Time-of-Check / Time-of-Use) — Low Severity

**Location:** `scripts/run-codex-review.sh` — gap between `detect_host` return and downstream `gh` invocation

```
T1: detect_host() → realpath validates /usr/local/bin/gh → prefix ✓ → mode = "copilot-cli"
        [window opens]
T2: attacker replaces /usr/local/bin/gh with malicious binary
        [window closes at gh execution]
T3: run-third-party-llm.sh invokes gh (now malicious)
```

**Severity: Informational.** Exploiting this window requires:
1. Write access to a trusted system directory (`/usr/local/bin`, `/opt/homebrew/bin`, etc.) — already a compromised posture
2. Precise timing against a short-lived window in a local script

No practical attack path exists that does not require an already-privileged local attacker. Noted for completeness because the dispatch asked; this does not warrant a code change.

---

### Closure Verdict (R6-F01, R6-F02)

| Scenario | Fix effective? | Tested by new tests? |
|---|---|---|
| `..`-injection, tools present | ✓ closed | ✓ `[r7-sec.F01]` |
| Combined `..` + symlink, tools present | ✓ closed | ✓ `[r7-sec.F02]` |
| Pure symlink in trusted prefix, tools present | ✓ closed (code correct) | ✗ not directly tested |
| Any attack, both tools absent (fallback) | ✗ **NOT closed** — see R8-F01 | ✗ not tested |
