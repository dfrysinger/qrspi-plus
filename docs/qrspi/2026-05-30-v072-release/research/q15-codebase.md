---
status: draft
question_ids: [15]
research_type: codebase
---

# Q15: Helper functions in `scripts/run-codex-review.sh` for environment detection and their consumers in skill prompts

## Summary

**TL;DR:** `scripts/run-codex-review.sh` defines two environment-detection helpers — `detect_host` (line 123) and `check_codex_available` (line 148). The first probes the `COPILOT_CLI` environment variable and the canonical filesystem path of the `gh` binary to emit either `copilot-cli` or `claude-code`. The second globs the filesystem at `~/.claude/plugins/cache/openai-codex/codex/*/scripts/codex-companion.mjs` to verify Codex is reachable for the `claude-code` host. Both helpers are consumed inside the same script at lines 577 and 606. Outside the script, `skills/using-qrspi/SKILL.md` and `skills/goals/SKILL.md` contain prose-level call sites that describe identical detection logic (same glob pattern, same env var), and `scripts/codex-companion-bg.sh` independently re-implements the same `codex-companion.mjs` glob at line 80 for its own resolution step.

**Key findings:**
- `detect_host` is defined at `scripts/run-codex-review.sh:123–140`; it examines `COPILOT_CLI` and verifies `gh` resolves to a path under `/usr/*`, `/opt/*`, or `/Applications/*` after `realpath`/`readlink -f` normalization.
- `check_codex_available` is defined at `scripts/run-codex-review.sh:148–191`; for the `claude-code` host it globs `~/.claude/plugins/cache/openai-codex/codex/*/scripts/codex-companion.mjs` and applies `HOME` safety guards before doing so.
- Both helpers are called inside `run-codex-review.sh` at lines 577 and 606 respectively.
- `skills/using-qrspi/SKILL.md` (lines 405, 411, 416, 466, 470, 509, 536) references `detect_host` and `check_codex_available` by name, documents their semantics, and specifies the `COPILOT_CLI` env-var convention and the same `codex-companion.mjs` glob.
- `skills/goals/SKILL.md` (lines 112, 120) performs Codex-companion availability detection in prose using the identical glob `~/.claude/plugins/cache/openai-codex/codex/*/scripts/codex-companion.mjs` and a separate plugin-directory glob `~/.claude/plugins/cache/*/qrspi/*/skills/ux/` for the UX-skill probe.
- `scripts/codex-companion-bg.sh` (line 80) independently re-implements the same companion glob in a local function (`_resolve_companion`), operating on the same `HOME`-based path, using `shopt -s nullglob` and `sort -V | tail -n1` to pick the newest version.
- No agent files under `agents/` reference `detect_host` or `check_codex_available` directly.
- `QRSPI_SOURCE_ONLY=1` is the test-harness mechanism that allows unit tests to source `run-codex-review.sh` and call `detect_host`/`check_codex_available` in isolation; tests reside in `tests/unit/test-host-detection.bats` and `tests/unit/test-codex-review-codex-availability.bats`.

**Surprises:** `scripts/codex-companion-bg.sh` duplicates the `codex-companion.mjs` filesystem glob independently rather than calling `check_codex_available`, so the two scripts share the detection pattern but not the implementation.

**Caveats:** Only files under `scripts/` and `skills/` were exhaustively scanned; `docs/` subdirectories contain copies of skill text (accumulated from prior runs) that also mention `detect_host`, but those are derived artifacts, not independent call sites. Agent files under `agents/` were checked with grep and returned no matches.

---

## Full findings

### Helper functions defined in `scripts/run-codex-review.sh`

The script defines the following helper functions. Lines 86–91 (`require_value`), 274–281 (`require_flag`), 322–329 (`resolve_path`), 331–338 (`assert_file_exists`), 351–368 (`extract_skill_names`), 422–427 (`reject_if_contains_marker_file`), 429–433 (`reject_if_contains_marker_value`), 459–461 (`strip_frontmatter`), 463–469 (`emit_untrusted_artifact`), 471–516 (`emit_dispatch_parameters`), and 518–532 (`compose_prompt`) are utility/prompt-assembly helpers. The two environment-detection helpers are:

#### `detect_host` — `scripts/run-codex-review.sh:123–140`

```
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

- **Emits** exactly one of `copilot-cli` or `claude-code` to stdout.
- **Environment variable consulted:** `COPILOT_CLI` — must equal `"1"` (exact string).
- **Binary probe:** resolves `gh` with `command -v`, then normalizes the resulting path using `realpath` or `readlink -f` (fail-closed: if both tools are absent, `_gh_path` is set to `""`), and prefix-checks the canonical path against `/usr/*`, `/opt/*`, `/Applications/*`.
- **Described in script header:** lines 97–122 contain an inline doc explaining the security rationale for the two-factor check.
- **Source guard:** when `QRSPI_SOURCE_ONLY=1` (line 203), the script returns after function definitions so tests can call `detect_host` in isolation.

#### `check_codex_available` — `scripts/run-codex-review.sh:148–191`

```
check_codex_available() {
  local host="${1:-}"
  case "$host" in
    copilot-cli)
      return 0
      ;;
    claude-code)
      # HOME validation guards (lines 158–171)
      local found=0
      local f
      for f in "${HOME}/.claude/plugins/cache/openai-codex/codex"/*/scripts/codex-companion.mjs; do
        if [[ -f "$f" ]]; then
          found=1
          break
        fi
      done
      [[ "$found" -eq 1 ]] && return 0 || return 1
      ;;
    *)
      echo "check_codex_available: unsupported host argument: $host" >&2
      return 1
      ;;
  esac
}
```

- **Accepts** one argument: the host string emitted by `detect_host`.
- **`copilot-cli` branch:** returns 0 immediately (no filesystem probe — Codex is assumed natively routable).
- **`claude-code` branch:** first validates `HOME` (rejects values containing `..`, empty strings, newlines, or non-absolute paths via lines 158–171), then globs `${HOME}/.claude/plugins/cache/openai-codex/codex/*/scripts/codex-companion.mjs` and exits 0 if any matching regular file exists.
- **`*` branch:** emits a diagnostic to stderr and returns 1.

### Internal call sites within `scripts/run-codex-review.sh`

| Line | Call | Context |
|------|------|---------|
| 577 | `_detected_host="$(detect_host)"` | Executes after all argument validation; result stored in `_detected_host` for downstream use. |
| 606 | `if check_codex_available "$_detected_host"; then` | Probes Codex availability for the detected host; result stored as `_codex_available="true"/"false"` and `_check_exit`. |
| 620 | mismatch warning emitted on `[[ "$_codex_available" != "$_codex_reviews" ]]` | Compares `check_codex_available` output against `codex_reviews` from `$ARTIFACT_DIR/config.md` (lines 582–600). |
| 630–632 | short-circuit abort when `_codex_available==false && _codex_reviews==true` | Emits `[codex-unavailable]` diagnostic and propagates `check_codex_available`'s exit code. |
| 640–647 | transport selection on `_detected_host` | Emits `[transport: task-tool]` (copilot-cli) or `[transport: shell-pipeline]` (claude-code) and dispatches via the dispatcher. |

### Skill prompts performing similar environment-detection work

#### `skills/using-qrspi/SKILL.md`

This is the primary skill-level consumer of the `detect_host`/`check_codex_available` semantics.

| Line(s) | Pattern | Detail |
|---------|---------|--------|
| 298 | Filesystem glob | `glob for docs/qrspi/*/goals.md` — run-selection logic for mid-pipeline entry; not Codex-related. |
| 304 | Filesystem glob | `glob for docs/qrspi/*/goals.md` — direct-skill-invocation artifact-directory resolution. |
| 405 | Filesystem glob + Codex detection | Instructs the orchestrator to glob `~/.claude/plugins/cache/openai-codex/codex/*/scripts/codex-companion.mjs` to decide whether to ask about Codex reviews during initial config setup. |
| 411 | `detect_host` reference (prose) | Documents the two transport options selected by `detect_host` (`copilot-cli` / `claude-code`) and references `COPILOT_CLI=1` as the marker. |
| 413 | `COPILOT_CLI` env var | Defines `COPILOT_CLI=1` as the Copilot CLI host marker; describes the `[transport: task-tool]` path. |
| 414 | `COPILOT_CLI` env var | Defines `COPILOT_CLI` unset as the Claude Code host path; names `scripts/run-codex-review.sh` as the dispatch script. |
| 416 | `check_codex_available` reference (prose) | Documents the mismatch warning policy and the `check_codex_available` short-circuit when Codex is unavailable and `codex_reviews: true`. |
| 466 | `detect_host` reference (prose) | States that top-level keys in the `model_routing:` block are the host names emitted by `detect_host`. |
| 470 | `detect_host` reference (prose) | Specifies dispatcher behavior when `detect_host` returns a host value with no matching `model_routing:` key. |
| 509 | `detect_host` reference (prose) | Explains the `model_routing:` lookup is indexed by the active dispatch host from `detect_host`. |
| 536 | `detect_host` reference (prose) | Step 1 of the model-routing resolution flow: "The dispatcher calls `detect_host`". |

#### `skills/goals/SKILL.md`

Performs Codex-companion detection in prose (orchestrator instructions, not shell), using the same glob patterns as `check_codex_available`.

| Line | Pattern | Detail |
|------|---------|--------|
| 112 | Filesystem glob | Checks for `~/.claude/plugins/cache/*/qrspi/*/skills/ux/` to decide whether to present the UX step. Uses a wildcard that allows any plugin name (not openai-codex-specific). |
| 120 | Filesystem glob | Identical to `check_codex_available`'s claude-code branch: globs `~/.claude/plugins/cache/openai-codex/codex/*/scripts/codex-companion.mjs` to gate the Codex-reviews question. |

Both `skills/goals/SKILL.md` detections are run by the human-facing orchestrator (Claude) as prose instructions, not bash; they pre-date or parallel the `check_codex_available` shell implementation. Unlike the shell function, the prose version does not apply `HOME` safety guards.

#### `scripts/codex-companion-bg.sh`

Although not a skill prompt, this script re-implements the same companion-discovery glob independently:

| Line | Pattern | Detail |
|------|---------|--------|
| 80 | `local pattern="${HOME}/.claude/plugins/cache/openai-codex/codex/*/scripts/codex-companion.mjs"` | Used inside a local function (`_resolve_companion`, inferred from context). Applies `shopt -s nullglob`, expands the glob into an array, and selects the newest match using `sort -V | tail -n1` (lines 82–94). |

This is the same glob path as `check_codex_available`'s claude-code branch but implemented independently and without the `HOME` safety validation guards present in the shell function.

### No direct invocation of the helpers from outside `run-codex-review.sh`

A repo-wide search for `detect_host` and `check_codex_available` in `scripts/` (excluding `run-codex-review.sh`) and `agents/` returned no matches. Both helpers are only called within `run-codex-review.sh` itself (lines 577 and 606). The skill prompts reference them by name in prose for documentation and orchestrator-instruction purposes, but do not invoke them as shell functions. The test suites (`tests/unit/test-host-detection.bats` and `tests/unit/test-codex-review-codex-availability.bats`) source the script with `QRSPI_SOURCE_ONLY=1` to call the helpers directly for unit testing.

### Relationship summary

```
detect_host (run-codex-review.sh:123)
  ← probes: COPILOT_CLI env var, gh binary path (via realpath/readlink -f)
  → called at: run-codex-review.sh:577 (internal)
  → documented in: skills/using-qrspi/SKILL.md:411,413,414,466,470,509,536
  → unit-tested via QRSPI_SOURCE_ONLY=1 in: tests/unit/test-host-detection.bats

check_codex_available (run-codex-review.sh:148)
  ← probes: filesystem glob ~/.claude/plugins/cache/openai-codex/codex/*/scripts/codex-companion.mjs
            HOME environment variable (safety guard)
  → called at: run-codex-review.sh:606 (internal)
  → documented in: skills/using-qrspi/SKILL.md:416
  → parallel prose implementation in: skills/using-qrspi/SKILL.md:405, skills/goals/SKILL.md:120
  → independent reimplementation of same glob in: scripts/codex-companion-bg.sh:80
  → unit-tested via QRSPI_SOURCE_ONLY=1 in:
      tests/unit/test-host-detection.bats
      tests/unit/test-codex-review-codex-availability.bats
```
