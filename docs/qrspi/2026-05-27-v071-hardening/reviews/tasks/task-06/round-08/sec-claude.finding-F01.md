---
finding_id: R8-F01
severity: low
change_type: correctness
referenced_files:
  - scripts/run-codex-review.sh
  - tests/unit/test-codex-review-host-detection.bats
artifact: task-06/scripts/run-codex-review.sh
round: 8
reviewer: sec-claude
closes_prior: []
reopens_prior: [R6-F01, R6-F02]
scope: pass-through fallback when both realpath and readlink-f are absent
---

## Title: Pass-Through Fallback Re-Opens R6-F01 (`..`-Injection) and R6-F02 (Symlink Bypass) on Environments Without Either Normalization Tool

### Location

`scripts/run-codex-review.sh` — `detect_host` function, c00ee40 lines 22–25 (diff hunk `+109,23`)

```bash
_gh_path="$(realpath "$_gh_path" 2>/dev/null \
  || readlink -f "$_gh_path" 2>/dev/null \
  || printf '%s' "$_gh_path")"   # ← fallback: returns raw command-v output unchanged
```

### Root Cause

The fallback branch `printf '%s' "$_gh_path"` is triggered whenever both `realpath` and `readlink -f` exit non-zero (tool absent or unexpected failure). It returns the unnormalized string that `command -v gh` produced — the identical input that R6-F01 and R6-F02 showed is bypassable.

The subsequent prefix test is unchanged:

```bash
[[ "$_gh_path" == /usr/* || "$_gh_path" == /opt/* || "$_gh_path" == /Applications/* ]]
```

This is a pure string prefix match. On the fallback path it still matches `/usr/../tmp/fakebins/gh` as `/usr/*`, and still accepts a symlink path that resolves outside any trusted prefix.

### Concrete Attack — `..`-Injection (R6-F01 resurfaces)

**Environment requirement:** `realpath` absent AND `readlink -f` absent (e.g., a stripped Alpine container with BusyBox built without `realpath`, or any custom minimal image whose `coreutils` installation excludes both tools).

```bash
# Attacker controls PATH (local or CI environment)
mkdir -p /tmp/fakebins
printf '#!/bin/sh\nexit 0\n' > /tmp/fakebins/gh
chmod +x /tmp/fakebins/gh

export COPILOT_CLI=1
export PATH=/usr/../tmp/fakebins:/usr/bin:/bin

# In the failing environment:
#   command -v gh          → "/usr/../tmp/fakebins/gh"
#   realpath … 2>/dev/null →  (exits non-zero, suppressed)
#   readlink -f … 2>/dev/null → (exits non-zero, suppressed)
#   printf '%s' …          → "/usr/../tmp/fakebins/gh"  ← unchanged
#   [[ "/usr/../tmp/fakebins/gh" == /usr/* ]] → TRUE
# detect_host emits: "copilot-cli"  ← FORGED
```

Same bypass is possible with `/opt/../tmp/fakebins` and `/Applications/../tmp/fakebins`.

### Concrete Attack — Symlink Bypass (R6-F02 resurfaces)

```bash
# Attacker plants a symlink inside a trusted prefix
# (requires write access to /opt/homebrew/bin, which is user-writable on Apple Silicon)
ln -sf /tmp/evil/gh /opt/homebrew/bin/gh

export COPILOT_CLI=1
export PATH=/opt/homebrew/bin:/usr/bin:/bin

# In the failing environment:
#   command -v gh → "/opt/homebrew/bin/gh"
#   realpath … → (absent)
#   readlink -f … → (absent)
#   printf '%s' … → "/opt/homebrew/bin/gh"
#   [[ "/opt/homebrew/bin/gh" == /opt/* ]] → TRUE
# detect_host emits: "copilot-cli"  ← FORGED (gh is actually /tmp/evil/gh)
```

### Test Coverage Gap (load-bearing)

**Neither new test exercises the fallback branch.** Both `[r7-sec.F01]` and `[r7-sec.F02]` run on platforms where `realpath` succeeds (macOS/Linux CI). The test suite has no case that:

1. Stubs out or hides `realpath` and `readlink`
2. Verifies that on such platforms the `..`-injection attack is blocked (or documents that it is not)

This means the pass-through fallback path is **entirely untested**. A future maintainer cannot distinguish "the fallback is safe" from "the fallback was never checked."

### Environments Where Both Tools Are Absent

In practice, the risk is low on mainstream platforms (macOS has `realpath` since 10.12; GNU coreutils ships it on every major Linux distro; BusyBox has had it since 1.22.0). Environments that may lack both:

- Custom Docker images with minimal `busybox` builds that exclude `realpath` applet
- OpenWRT / embedded Linux appliances
- Stripped CI images built from `FROM scratch` or very small base layers
- Any environment where the operator explicitly removed both binaries for image-size reasons

These are uncommon in qrspi's target deployment (developer machines / GitHub Actions), but the fallback creates a platform-dependent security posture that is not documented in the comment block.

### Closure Verdict for R6-F01 and R6-F02

| Platform | R6-F01 (`..`-injection) closed? | R6-F02 (symlink bypass) closed? |
|---|---|---|
| macOS ≥ 10.12 | ✓ yes (`realpath` present) | ✓ yes |
| Ubuntu / Debian / RHEL | ✓ yes (`realpath` in coreutils) | ✓ yes |
| Alpine with standard BusyBox | ✓ yes (`realpath` applet) | ✓ yes |
| Minimal/stripped image, no `realpath`, no `readlink -f` | ✗ **no** (fallback) | ✗ **no** (fallback) |

### Recommended Fix

Option A — fail-closed instead of pass-through:

```bash
if [[ -n "$_gh_path" ]]; then
  _gh_path="$(realpath "$_gh_path" 2>/dev/null \
    || readlink -f "$_gh_path" 2>/dev/null)" || {
    # Neither tool available: cannot verify canonical path; treat as untrusted.
    _gh_path=""
  }
fi
```

If `_gh_path` is empty, the subsequent `[[ -n "$_gh_path" ]]` guard already short-circuits the prefix check, so `detect_host` falls through to `claude-code` — the safe default. No normalization tool ≡ no copilot-cli marker trust.

Option B — document the limitation and add a test:

If the pass-through is intentional for exotic environments, add a bats test that stubs both tools via a fake `PATH` override, asserts that `detect_host` returns `claude-code` on the `..`-injection input (it will not — test will be RED), and document the known gap.

### Add Test for Fallback Path

Regardless of which fix option is chosen, add:

```bash
@test "[r7-sec.F01-fallback] ..injection blocked even when realpath and readlink absent" {
  # Simulate missing tools by prepending a PATH with no-op stubs
  local stubs="$TMP_DIR/no-norm-stubs"
  mkdir -p "$stubs"
  printf '#!/bin/sh\nexit 127\n' > "$stubs/realpath"; chmod +x "$stubs/realpath"
  printf '#!/bin/sh\nexit 127\n' > "$stubs/readlink";  chmod +x "$stubs/readlink"
  local injected_path="/usr/../${FAKE_BIN}"
  run bash -c "
    export QRSPI_SOURCE_ONLY=1
    export COPILOT_CLI=1
    export PATH='${stubs}:${injected_path}:/usr/bin:/bin'
    . \"$WRAPPER\"
    detect_host
  "
  [ "$status" -eq 0 ]
  [ "$output" = "claude-code" ]
}
```

This test will be RED against the current code, confirming the gap, and GREEN after Option A is applied.
