#!/usr/bin/env bats
bats_require_minimum_version 1.5.0

# T37 — G4: Cross-cutting rejection-of-summary-shims invariant pin.
#
# Per design.md lines 219 and 238, the QRSPI design rejects "summary-shim"
# mechanisms — LLM-generated condensations of a stable artifact substituted
# as the prompt source-of-truth in place of the original artifact — as a
# distinct third category alongside Mechanism A (prompt caching, preserves
# verbatim) and Mechanism B (section-anchor index, slices verbatim).
#
# This pin walks every skill body (skills/**/SKILL.md) and every QRSPI
# agent body (agents/qrspi-*.md) and asserts no dispatch site composes a
# prompt whose source-of-truth payload is a derived-summary artifact.
#
# Detection algorithm (Implement-TDD authored; the boundary statements are
# Plan-OWNed, the literal regex is local to this BATS file):
#
#   Match summary-shim shapes in dispatch-prompt construction:
#   - `<summary-of <PATH>>` / `<summary_of <PATH>>` placeholder syntax
#     (a literal placeholder that indicates a derived condensation will
#     be substituted for the path's verbatim body before dispatch).
#   - `summary_of:` / `condensed_of:` / `digest_of:` companion key in a
#     dispatch parameters block (a companion field naming a stable
#     artifact whose value is a derived summary rather than the artifact
#     content or a verbatim slice).
#   - `<<<SUMMARY-OF id=` sentinel (a wrapper analogous to the
#     untrusted-artifact wrapper that carries a derived condensation
#     instead of verbatim content).
#
#   Exclusions (NOT summary-shims; do NOT flag):
#   - Verbatim Reads (Read tool calls that load the full file body
#     into the prompt). Plain references to a stable artifact path in
#     dispatch parameter declarations (e.g., `--task-def task-NN.md`,
#     `companion_plan=plan.md`) are verbatim payloads — not flagged.
#   - Mechanism B narrow-Read sites: a Read against an index-driven
#     line-range slice (e.g., `Read("file.md", offset=N, limit=M)`) is
#     byte-identical to the source slice and is not a summary-shim.
#   - Human-facing digest surfaces: a `## Summary` body surfaced for
#     human presentation (e.g., a research/summary.md document the
#     collator emits for the user, or a "Summary:" prose paragraph in
#     skill body documentation) is NOT a dispatch-prompt source-of-truth
#     substitution. The rejection scope is dispatch-prompt payloads only
#     per the design line-219 carve-out. The regex is tight enough that
#     human-facing summary documentation does not match.
#
# Falsifiability fixtures (three behavioral cases):
#   - Positive: a synthesized summary-shim dispatch site causes the
#     detector to fire.
#   - Verbatim-Read: a synthesized verbatim Read site does NOT cause
#     the detector to fire.
#   - Mechanism B narrow-Read: a synthesized narrow-Read site against
#     an index-driven slice does NOT cause the detector to fire.
#
# Bash 3.2 portable: no associative arrays, no mapfile, no coproc,
# no wait -n, no ${var,,}. The CI bash32 job exercises this pin.

load '../helpers/skill-markdown'

setup_file() {
  require_repo_root
  export REPO_ROOT
}

setup() {
  FIXTURE_DIR="$(mktemp -d)"
  export FIXTURE_DIR
}

teardown() {
  rm -rf "$FIXTURE_DIR"
}

# ---------------------------------------------------------------------------
# _detect_summary_shim <file>
# Returns 0 (match found) when the file contains a summary-shim dispatch
# shape per the documented detection patterns; returns 1 otherwise. On
# match, prints the offending file path and line(s) to stdout.
#
# Bash 3.2 portable: plain grep -E, no awk state machines, no associative
# arrays. The exclusion of human-facing `## Summary` headings is encoded
# by anchoring the placeholder/companion patterns to NON-heading shapes.
# ---------------------------------------------------------------------------
_detect_summary_shim() {
  local file="$1"
  # Pattern 1: <summary-of PATH> or <summary_of PATH> placeholder.
  #            Must look like a placeholder syntax (angle brackets +
  #            keyword + path-shape). Matches both hyphen and underscore.
  # Pattern 2: <<<SUMMARY-OF id= sentinel wrapper (parallel to the
  #            untrusted-artifact wrapper shape).
  # Pattern 3: summary_of: / condensed_of: / digest_of: companion key
  #            naming a file path as its value (the .md/.json/.yml/.txt
  #            suffix anchors this to a dispatch-companion shape and
  #            excludes prose like "summary of the design").
  grep -nE \
    -e '<summary[-_]of[[:space:]]+[^>]+>' \
    -e '<<<SUMMARY-OF[[:space:]]+id=' \
    -e '(summary_of|condensed_of|digest_of):[[:space:]]*[^[:space:]]+\.(md|json|ya?ml|txt)' \
    "$file"
}

# =============================================================================
# Repo-wide scan: every skill body must be summary-shim-free
# =============================================================================

@test "[T37-no-shim] skills/**/SKILL.md contain no summary-shim dispatch shapes" {
  local hit=0
  local file
  local match
  # Bash 3.2 portable file iteration via find + while-read; no mapfile.
  while IFS= read -r file; do
    match="$(_detect_summary_shim "$file" || true)"
    if [ -n "$match" ]; then
      printf 'SUMMARY-SHIM DETECTED in %s:\n%s\n' "$file" "$match" >&2
      hit=1
    fi
  done < <(find "$REPO_ROOT/skills" -type f -name 'SKILL.md')
  [ "$hit" -eq 0 ]
}

# =============================================================================
# Repo-wide scan: every QRSPI agent body must be summary-shim-free
# =============================================================================

@test "[T37-no-shim] agents/qrspi-*.md contain no summary-shim dispatch shapes" {
  local hit=0
  local file
  local match
  while IFS= read -r file; do
    match="$(_detect_summary_shim "$file" || true)"
    if [ -n "$match" ]; then
      printf 'SUMMARY-SHIM DETECTED in %s:\n%s\n' "$file" "$match" >&2
      hit=1
    fi
  done < <(find "$REPO_ROOT/agents" -type f -name 'qrspi-*.md')
  [ "$hit" -eq 0 ]
}

# =============================================================================
# Positive fixture: synthesized summary-shim site MUST trigger detection
# =============================================================================

@test "[T37-no-shim] Positive fixture: summary-shim placeholder triggers detection" {
  cat > "$FIXTURE_DIR/shim-placeholder.md" <<'EOF'
## Dispatching the Reviewer

Compose the reviewer prompt with the following body:

  Reviewer protocol: <summary-of skills/reviewer-protocol/SKILL.md>

Then dispatch via Agent(...).
EOF
  local match
  match="$(_detect_summary_shim "$FIXTURE_DIR/shim-placeholder.md" || true)"
  [ -n "$match" ]
}

@test "[T37-no-shim] Positive fixture: summary-shim companion key triggers detection" {
  cat > "$FIXTURE_DIR/shim-companion.md" <<'EOF'
## Dispatch parameters

```
summary_of: skills/reviewer-protocol/SKILL.md
```
EOF
  local match
  match="$(_detect_summary_shim "$FIXTURE_DIR/shim-companion.md" || true)"
  [ -n "$match" ]
}

@test "[T37-no-shim] Positive fixture: summary-shim sentinel wrapper triggers detection" {
  cat > "$FIXTURE_DIR/shim-sentinel.md" <<'EOF'
Pass the following companion on the dispatch:

<<<SUMMARY-OF id=reviewer_protocol>>>
condensed body here
<<<SUMMARY-OF id=reviewer_protocol/END>>>
EOF
  local match
  match="$(_detect_summary_shim "$FIXTURE_DIR/shim-sentinel.md" || true)"
  [ -n "$match" ]
}

# =============================================================================
# Negative fixture: verbatim Read site MUST NOT trigger detection
# =============================================================================

@test "[T37-no-shim] Verbatim-Read fixture does NOT trigger detection" {
  cat > "$FIXTURE_DIR/verbatim-read.md" <<'EOF'
## Dispatching the Reviewer

Read the full reviewer-protocol body into the prompt:

  Read("skills/reviewer-protocol/SKILL.md")

Compose the dispatch prompt with the verbatim body. Companion fields:

  companion_plan=plan.md
  companion_goals=goals.md
EOF
  local match
  match="$(_detect_summary_shim "$FIXTURE_DIR/verbatim-read.md" || true)"
  [ -z "$match" ]
}

# =============================================================================
# Negative fixture: Mechanism B narrow-Read site MUST NOT trigger detection
# =============================================================================

@test "[T37-no-shim] Mechanism B narrow-Read fixture does NOT trigger detection" {
  cat > "$FIXTURE_DIR/narrow-read.md" <<'EOF'
## Dispatching the Reviewer

Consult the section-anchor index for the protocol section:

  index = ReadJSON("skills/reviewer-protocol/SKILL.anchors.json")
  slice = Read("skills/reviewer-protocol/SKILL.md", offset=210, limit=60)

Compose the dispatch prompt with the byte-identical narrow slice.
EOF
  local match
  match="$(_detect_summary_shim "$FIXTURE_DIR/narrow-read.md" || true)"
  [ -z "$match" ]
}

# =============================================================================
# Negative fixture: human-facing `## Summary` heading is NOT a dispatch shim
# =============================================================================

@test "[T37-no-shim] Human-facing ## Summary heading does NOT trigger detection" {
  cat > "$FIXTURE_DIR/human-summary.md" <<'EOF'
# Research Summary

## Summary

This document presents a human-facing digest of the research findings
collected by the per-question specialists. It is NOT a dispatch-prompt
payload; the underlying q*.md files remain the verbatim source-of-truth
for any subsequent dispatch.

The summary of the design choices is presented here for the reader.
EOF
  local match
  match="$(_detect_summary_shim "$FIXTURE_DIR/human-summary.md" || true)"
  [ -z "$match" ]
}
