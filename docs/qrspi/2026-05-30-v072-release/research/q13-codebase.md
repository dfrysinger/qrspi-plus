---
status: draft
question_ids: [13]
research_type: codebase
---

# Q13: How does `scripts/run-codex-review.sh` resolve and validate paths passed to `--subject-code` and `--companion`?

## Summary

**TL;DR:** `resolve_path()` (lines 322–329) performs only a leading-`/` check to choose between returning the path verbatim (absolute) or prepending `$REPO_ROOT/` (relative). It does no normalization, no canonicalization, and no rejection of `..` segments or other special characters. This contrasts sharply with `detect_host()`'s `realpath`/`readlink -f` canonicalization of the `gh` binary path, and with `check_codex_available()`'s explicit rejection of `..` and non-absolute `HOME` values.

**Key findings:**
- `resolve_path()` has two code paths: if input starts with `/`, return it verbatim; else prepend `$REPO_ROOT/` and return. No `realpath`, no `readlink -f`, no `..` rejection.
- After resolution, `assert_file_exists()` applies only a `-f` filesystem existence test — no further normalization or constraint checking.
- Both `--subject-code` paths (accumulated in `PRIMARY_ABS[]`) and `--companion` paths (`COMPANION_ABS[]`) are processed identically through `resolve_path()` then `assert_file_exists()`.
- `--diff-file` bypasses `resolve_path()` entirely; it is tested directly with `[[ ! -f "$DIFF_FILE" ]]` with no absolute-path enforcement and no REPO_ROOT prepending.
- `detect_host()` (lines 123–140) uses `realpath "$_gh_path" 2>/dev/null || readlink -f "$_gh_path" 2>/dev/null` to canonicalize the `gh` binary path — resolving both `..` segments and symlinks — before the trusted-prefix check, and fails closed if both tools are absent.
- `check_codex_available()` (lines 148–191) validates `HOME` against `..`, empty, and newline patterns, and checks it begins with `/`, but does not call `realpath`/`readlink -f` to canonicalize `HOME`.
- The marker-injection guard (`reject_if_contains_marker_file`) checks file contents after path resolution, not the path string itself.

**Surprises:** `--diff-file` is the only path-type flag that bypasses `resolve_path()` entirely — no REPO_ROOT prepending and no absolute-path enforcement for that flag, unlike `--subject-code`, `--companion`, and `--agent-file`.

**Caveats:** Full file read; no sampling. The analysis covers the current on-disk file only; no git history comparison was performed.

## Full findings

### `resolve_path()` — lines 322–329

```bash
resolve_path() {
  local p="$1"
  if [[ "$p" == /* ]]; then
    echo "$p"
  else
    echo "$REPO_ROOT/$p"
  fi
}
```

The function applies exactly one check: does the path begin with `/`?

- **Absolute paths (`p == /*`):** returned verbatim, unchanged. No `realpath`, no `readlink -f`, no removal of `..` components, no symlink resolution, no length or character constraints.
- **Relative paths (everything else):** `$REPO_ROOT/` is prepended. `REPO_ROOT` is itself derived from `"$(cd "$SCRIPT_DIR/.." && pwd -P)"` (line 60), which is canonicalized at script startup, but the appended suffix is not further normalized.

Consequently, a caller-supplied path like `../../etc/passwd` (relative) becomes `$REPO_ROOT/../../etc/passwd`, and a path like `/abs/../etc/passwd` (absolute) is returned as-is — the shell (or underlying `[[ -f ... ]]` call) will resolve the `..` segments when the path is used.

### `assert_file_exists()` — lines 331–338

```bash
assert_file_exists() {
  local label="$1"
  local p="$2"
  if [[ ! -f "$p" ]]; then
    echo "error: ${label} not found: $p" >&2
    exit 1
  fi
}
```

Only checks that the resolved path names a regular file. No re-normalization, no canonicalization, no further constraints on path content.

### Path resolution for `--subject-code` — lines 386–391

```bash
PRIMARY_ABS=()
for sc in "${PRIMARY_PATHS[@]}"; do
  abs="$(resolve_path "$sc")"
  assert_file_exists "$PRIMARY_FIELD" "$abs"
  PRIMARY_ABS+=("$abs")
done
```

Each `--subject-code` argument passes through `resolve_path()` then `assert_file_exists()` only. The resolved absolute path is stored in `PRIMARY_ABS[]` and later used in `emit_dispatch_parameters()` (line 476) and passed to `reject_if_contains_marker_file()` (line 437) — the latter checks the *file contents* for a marker string, not the path itself.

### Path resolution for `--companion` — lines 399–406

```bash
COMPANION_ABS=()
for i in "${!COMPANION_PATHS[@]}"; do
  cpath="${COMPANION_PATHS[$i]}"
  cname="${COMPANION_NAMES[$i]}"
  abs="$(resolve_path "$cpath")"
  assert_file_exists "companion[$cname]" "$abs"
  COMPANION_ABS+=("$abs")
done
```

Identical pipeline to `--subject-code`: `resolve_path()` → `assert_file_exists()`. The `--companion` parsing (lines 220–238) validates that the `NAME=PATH` argument format is well-formed and that `NAME` matches `[A-Za-z_][A-Za-z0-9_]*`, but the `PATH` component receives no validation beyond format parsing before it reaches `resolve_path()`.

### `--diff-file` — lines 408–413 (no `resolve_path()`)

```bash
if [[ -n "$DIFF_FILE" ]]; then
  if [[ ! -f "$DIFF_FILE" ]]; then
    echo "error: diff-file not found: $DIFF_FILE" >&2
    exit 1
  fi
fi
```

`--diff-file` bypasses `resolve_path()` entirely. The raw value from `--diff-file <path>` is tested directly with `-f`. There is no absolute-path enforcement and no REPO_ROOT prepending for this flag.

### Contrast: `detect_host()` canonicalization — lines 123–140

```bash
detect_host() {
  local _gh_path
  _gh_path="$(command -v gh 2>/dev/null)"
  if [[ -n "$_gh_path" ]]; then
    _gh_path="$(realpath "$_gh_path" 2>/dev/null || readlink -f "$_gh_path" 2>/dev/null)" || _gh_path=""
  fi
  if [[ "${COPILOT_CLI:-}" == "1" ]] && \
     [[ -n "$_gh_path" ]] && \
     [[ "$_gh_path" == /usr/* || "$_gh_path" == /opt/* || "$_gh_path" == /Applications/* ]]; then
    echo "copilot-cli"
  else
    echo "claude-code"
  fi
}
```

`detect_host()` calls `realpath` (BSD/macOS) or `readlink -f` (GNU/Linux) on the `gh` binary path. Per the inline comments (lines 112–122), this:
1. Resolves symlinks so the canonical filesystem path is compared against trusted prefixes.
2. Removes `..` segments so PATH-injection attacks (`PATH=/usr/../tmp/fakebins:...`) are defeated.
3. Fails closed: if both tools are absent or fail, `_gh_path` is forced to `""` and the trusted-prefix check is skipped, defaulting to `claude-code`.

This is a materially stronger treatment than `resolve_path()`.

### Contrast: `check_codex_available()` HOME validation — lines 148–191

```bash
check_codex_available() {
  ...
  case "${HOME:-}" in
    *..* | "" | *$'\n'*)
      echo "check_codex_available: unsafe HOME value ..." >&2
      return 1
      ;;
  esac
  if [[ "${HOME}" != /* ]]; then
    echo "check_codex_available: HOME must be an absolute path ..." >&2
    return 1
  fi
  local found=0
  local f
  for f in "${HOME}/.claude/plugins/cache/openai-codex/codex"/*/scripts/codex-companion.mjs; do
    if [[ -f "$f" ]]; then found=1; break; fi
  done
  ...
}
```

`check_codex_available()` for the `claude-code` host path validates `HOME` by:
1. Rejecting `HOME` values containing `..` (case pattern `*..*`).
2. Rejecting empty `HOME`.
3. Rejecting `HOME` values containing newlines.
4. Rejecting non-absolute `HOME` (the `[[ "${HOME}" != /* ]]` guard, added to catch the gap noted in the comment on lines 164–167 that the case guard does not check for a leading `/`).

However, `check_codex_available()` does **not** canonicalize `HOME` with `realpath`/`readlink -f`. The comment at line 165 explicitly acknowledges the case guard does not cover relative paths without `..`, hence the additional `!= /*` guard.

### Summary comparison table

| Mechanism | Input | `..` rejection | Symlink resolution | Absolute check | `realpath`/`readlink -f` |
|---|---|---|---|---|---|
| `resolve_path()` | `--subject-code`, `--companion`, `--agent-file`, `--task-def` | No | No | No (only decides relative vs. absolute handling) | No |
| `assert_file_exists()` | Resolved paths | No | (kernel handles at `-f` check) | No | No |
| `--diff-file` inline check | `--diff-file` | No | No | No | No |
| `detect_host()` | `gh` binary path | Yes (via `realpath`/`readlink -f`) | Yes | N/A | Yes, fail-closed |
| `check_codex_available()` | `HOME` | Yes (case pattern) | No | Yes (`!= /*`) | No |
