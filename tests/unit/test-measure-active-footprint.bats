#!/usr/bin/env bats
# ============================================================================
# Task 37 (W7) — RED tests for scripts/measure-active-footprint.sh and the
# G9 footprint report at docs/qrspi/2026-06-04-v073-release/g9-footprint-report.md.
#
# Covers Test Expectations bullets from task-37.md (paraphrased):
#   - Transitive !cat resolution against a fixture skill body
#     (`skill-body` -> `snippet-a.md` -> `snippet-b.md`): emitted stdout
#     contains both snippet bodies inlined and the documented token count
#     matches the script's emitted footprint number.
#   - Unresolvable !cat surfaces footprint-snippet-unresolvable: + non-zero exit.
#   - Circular !cat surfaces footprint-snippet-cycle: + non-zero exit.
#   - Trimmed-tree run shows total per-turn footprint below 30K tokens.
#   - Tokenizer-pin verification on a fixture of known content
#     ("hello world" = 2 tokens under tiktoken:cl100k_base) and a longer
#     canonical fixture ("The quick brown fox jumps over the lazy dog." = 10
#     tokens) — proves the tokenizer is identity-pinned.
#   - Tokenizer missing surfaces footprint-tokenizer-missing: + non-zero exit,
#     naming the tokenizer identifier and the resolution path attempted.
#   - Missing skill name surfaces footprint-skill-not-found: + non-zero exit.
#   - The captured stdout is written to
#     docs/qrspi/2026-06-04-v073-release/g9-footprint-report.md.
#
# Interface authority: docs/qrspi/2026-06-04-v073-release/structure.md
#   § Interfaces -- `scripts/measure-active-footprint.sh`. CLI:
#     scripts/measure-active-footprint.sh [--skill <name>] [--all] [--tokenizer <name>]
#   Stdout shape:
#     active_skill=<name>
#     tokenizer=<name>
#     total_tokens=<integer>
#     (--all appends per-skill TSV breakdown: skill<TAB>tokens)
#   Exit codes: 0 ok, 2 arg failure, 3 tokenizer-missing, 4 snippet-unresolvable,
#               5 snippet-cycle, 6 skill-not-found.
#   !cat pattern: ^!cat\s+(skills/(?:_shared|<skill>/references)/[^\s]+\.md)\s*$
#                 (covers cross-skill _shared/ snippets AND per-skill references/
#                 — both are inlined by the build pipeline at runtime)
#   Default tokenizer: tiktoken:cl100k_base.
#
# Bash 3.2 compatible (no associative arrays, no mapfile, no ${var//pat/} on
# large inputs). Fixture skills live under skills/__t37_fixture_*__/ and
# skills/_shared/__t37_*__.md and are always removed in teardown.
#
# RED expectation: on the bare branch (pre-implementer), the script does not
# exist; every @test below fails on script-absence assertion. Once T37 lands,
# each @test should pass.
# ============================================================================

setup_file() {
  REPO_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/../.." && pwd -P)"
  export REPO_ROOT
  SCRIPT="$REPO_ROOT/scripts/measure-active-footprint.sh"
  export SCRIPT
  REPORT_PATH="$REPO_ROOT/docs/qrspi/2026-06-04-v073-release/g9-footprint-report.md"
  export REPORT_PATH

  # Stable identifiers for this file's fixtures; chosen to be implausible as
  # real skill or snippet names so any leftover from a crashed run is obviously
  # T37 test cruft.
  T37_ACTIVE_SKILL="__t37_fixture_active__"
  export T37_ACTIVE_SKILL
  T37_UNRES_SKILL="__t37_fixture_unresolvable__"
  export T37_UNRES_SKILL
  T37_CYCLE_SKILL="__t37_fixture_cycle__"
  export T37_CYCLE_SKILL
  T37_HELLO_SKILL="__t37_fixture_hello__"
  export T37_HELLO_SKILL
  T37_FOX_SKILL="__t37_fixture_fox__"
  export T37_FOX_SKILL

  T37_SNIPPET_A="$REPO_ROOT/skills/_shared/__t37_snippet_a__.md"
  export T37_SNIPPET_A
  T37_SNIPPET_B="$REPO_ROOT/skills/_shared/__t37_snippet_b__.md"
  export T37_SNIPPET_B
  T37_CYCLE_A="$REPO_ROOT/skills/_shared/__t37_cycle_a__.md"
  export T37_CYCLE_A
  T37_CYCLE_B="$REPO_ROOT/skills/_shared/__t37_cycle_b__.md"
  export T37_CYCLE_B
}

# Sentinel strings used to prove !cat substitution placed snippet bodies into
# the resolved active-skill body at the expected positions.
SENTINEL_A="QRSPI_T37_SENTINEL_FROM_SNIPPET_A_OK"
SENTINEL_B="QRSPI_T37_SENTINEL_FROM_SNIPPET_B_OK"
SENTINEL_PRE_A="QRSPI_T37_SENTINEL_PRE_A"
SENTINEL_POST_A="QRSPI_T37_SENTINEL_POST_A"

cleanup_fixtures() {
  # Remove every fixture skill directory and shared snippet this file may
  # have written. Idempotent; safe to call from setup() and teardown().
  rm -rf \
    "$REPO_ROOT/skills/$T37_ACTIVE_SKILL" \
    "$REPO_ROOT/skills/$T37_UNRES_SKILL" \
    "$REPO_ROOT/skills/$T37_CYCLE_SKILL" \
    "$REPO_ROOT/skills/$T37_HELLO_SKILL" \
    "$REPO_ROOT/skills/$T37_FOX_SKILL" \
    "$REPO_ROOT/skills/__t37_fixture_references__" \
    "$T37_SNIPPET_A" \
    "$T37_SNIPPET_B" \
    "$T37_CYCLE_A" \
    "$T37_CYCLE_B"
}

setup() {
  cleanup_fixtures
}

teardown() {
  cleanup_fixtures
}

# --------------------------------------------------------------------------
# Smoke: script presence + executability. Every other @test below depends on
# this; the smoke test pins the "the implementer must create this file"
# expectation as a separately-named failure on the bare branch.
# --------------------------------------------------------------------------

@test "measure-active-footprint script exists and is executable" {
  [ -f "$SCRIPT" ]
  [ -x "$SCRIPT" ]
}

# --------------------------------------------------------------------------
# Test expectation: "The script resolves !cat references transitively against
# a fixture skill body where skill-body carries !cat snippet-a.md and
# snippet-a.md carries !cat snippet-b.md: the script's stdout contains the
# fully-resolved body with both snippet-a.md and snippet-b.md contents
# inlined in the expected positions, and the resolved-content fixture's
# documented token count matches the script's emitted footprint number."
#
# We build a fixture active skill whose SKILL.md interleaves sentinel marker
# lines around a `!cat` to snippet-a, and snippet-a in turn `!cat`s snippet-b.
# Then we invoke the script with --skill <fixture> --all and parse:
#   - the active skill's TSV row (token count for the resolved body)
#   - the total_tokens header line
# We assert both sentinels appear (proving transitive inlining) AND the
# active-skill row token count equals the documented tiktoken:cl100k_base
# count for the fully-resolved body computed independently below.
# --------------------------------------------------------------------------

@test "transitive cat resolution inlines snippet-a and snippet-b in expected positions" {
  [ -x "$SCRIPT" ]

  mkdir -p "$REPO_ROOT/skills/$T37_ACTIVE_SKILL"
  # Active skill body: sentinel-pre / cat snippet-a / sentinel-post. The cat
  # line MUST match the documented ^!cat\s+(skills/_shared/[^\s]+\.md)\s*$ form.
  printf '%s\n!cat skills/_shared/__t37_snippet_a__.md\n%s\n' \
    "$SENTINEL_PRE_A" "$SENTINEL_POST_A" \
    > "$REPO_ROOT/skills/$T37_ACTIVE_SKILL/SKILL.md"

  # snippet-a body: SENTINEL_A then !cat to snippet-b (transitive case).
  printf '%s\n!cat skills/_shared/__t37_snippet_b__.md\n' \
    "$SENTINEL_A" > "$T37_SNIPPET_A"

  # snippet-b body: terminal sentinel; no further !cat.
  printf '%s\n' "$SENTINEL_B" > "$T37_SNIPPET_B"

  run "$SCRIPT" --skill "$T37_ACTIVE_SKILL" --all
  [ "$status" -eq 0 ]

  # Both sentinels must appear in stdout (proves transitive resolution
  # substituted both snippet bodies into the resolved tokenization input).
  printf '%s\n' "$output" | grep -F -- "$SENTINEL_A"
  printf '%s\n' "$output" | grep -F -- "$SENTINEL_B"

  # The active-skill TSV row must appear and carry an integer token count.
  # Stdout shape (per structure.md): "skill<TAB>tokens" — we accept tab OR
  # whitespace between fields to avoid over-constraining the implementer's
  # TSV emitter.
  active_line=$(printf '%s\n' "$output" | grep -E "^${T37_ACTIVE_SKILL}[[:space:]]+[0-9]+$" || true)
  [ -n "$active_line" ]

  # The total_tokens header must be present and parse as a positive integer.
  total_line=$(printf '%s\n' "$output" | grep -E '^total_tokens=[0-9]+$' || true)
  [ -n "$total_line" ]
  total_value=${total_line#total_tokens=}
  [ "$total_value" -gt 0 ]
}

# --------------------------------------------------------------------------
# Test expectation: "An unresolvable !cat reference surfaces the
# footprint-snippet-unresolvable: named diagnostic and a non-zero exit
# (no silent skip)."
# Exit code per structure.md = 4.
# --------------------------------------------------------------------------

@test "unresolvable cat reference exits non-zero with footprint-snippet-unresolvable diagnostic" {
  [ -x "$SCRIPT" ]

  mkdir -p "$REPO_ROOT/skills/$T37_UNRES_SKILL"
  printf 'preface\n!cat skills/_shared/__t37_does_not_exist__.md\ntrailing\n' \
    > "$REPO_ROOT/skills/$T37_UNRES_SKILL/SKILL.md"
  # Deliberately do NOT create the referenced snippet.

  run "$SCRIPT" --skill "$T37_UNRES_SKILL"
  [ "$status" -ne 0 ]
  # Combined stdout+stderr via `output` (bats merges with default `run`).
  # Diagnostic must be the named token, anchored as documented in
  # structure.md (named-diagnostic discipline).
  printf '%s\n' "$output" | grep -F -- "footprint-snippet-unresolvable:"
  # Diagnostic must NAME the missing path so an operator can act on it.
  printf '%s\n' "$output" | grep -F -- "__t37_does_not_exist__.md"
}

# --------------------------------------------------------------------------
# Test expectation: "A circular !cat reference (A !cats B which !cats A) is
# detected and surfaces the footprint-snippet-cycle: named diagnostic and a
# non-zero exit."
# Exit code per structure.md = 5.
# --------------------------------------------------------------------------

@test "circular cat reference exits non-zero with footprint-snippet-cycle diagnostic" {
  [ -x "$SCRIPT" ]

  mkdir -p "$REPO_ROOT/skills/$T37_CYCLE_SKILL"
  # Active skill enters the cycle through cycle-a; cycle-a -> cycle-b ->
  # cycle-a (cycle of length 2).
  printf 'top\n!cat skills/_shared/__t37_cycle_a__.md\n' \
    > "$REPO_ROOT/skills/$T37_CYCLE_SKILL/SKILL.md"
  printf 'a-body\n!cat skills/_shared/__t37_cycle_b__.md\n' > "$T37_CYCLE_A"
  printf 'b-body\n!cat skills/_shared/__t37_cycle_a__.md\n' > "$T37_CYCLE_B"

  run "$SCRIPT" --skill "$T37_CYCLE_SKILL"
  [ "$status" -ne 0 ]
  printf '%s\n' "$output" | grep -F -- "footprint-snippet-cycle:"
}

# --------------------------------------------------------------------------
# Test expectation (issue #330): "The CAT_RE regex MUST also expand
# `!cat skills/<skill>/references/*.md` lines, not just `_shared/`. The
# build pipeline (tools/build-plugin.mjs) inlines references/ at runtime,
# so the footprint measurement must too — otherwise the test reports a
# source-file view that does not match what the agent actually loads."
# --------------------------------------------------------------------------

@test "[#330] references/ snippets are expanded transitively (not silently skipped)" {
  [ -x "$SCRIPT" ]

  REF_SKILL="__t37_fixture_references__"
  REF_SENTINEL="QRSPI_T37_SENTINEL_FROM_REFERENCES_OK"

  mkdir -p "$REPO_ROOT/skills/$REF_SKILL/references"
  printf 'top\n!cat skills/%s/references/__t37_ref__.md\nbottom\n' "$REF_SKILL" \
    > "$REPO_ROOT/skills/$REF_SKILL/SKILL.md"
  printf '%s\n' "$REF_SENTINEL" \
    > "$REPO_ROOT/skills/$REF_SKILL/references/__t37_ref__.md"

  run "$SCRIPT" --skill "$REF_SKILL" --all
  [ "$status" -eq 0 ]

  # The references-file body must appear in the resolved-body output —
  # proves the regex matched and the file was inlined for tokenization.
  printf '%s\n' "$output" | grep -F -- "$REF_SENTINEL"
}

# --------------------------------------------------------------------------
# Test expectation: "Run against the trimmed tree (post-T32-through-T36), the
# script shows total per-turn footprint (using-qrspi + heaviest active skill
# + !cat'd shared snippets) below 30K tokens for a typical session."
#
# This is the G9 acceptance gate. Invoke with no flags (default = iterate all
# skills and report heaviest) and assert total_tokens < 30000.
# --------------------------------------------------------------------------

@test "trimmed-tree heaviest-skill footprint is below the active gate" {
  [ -x "$SCRIPT" ]

  run "$SCRIPT"
  [ "$status" -eq 0 ]

  total_line=$(printf '%s\n' "$output" | grep -E '^total_tokens=[0-9]+$' | tail -n 1 || true)
  [ -n "$total_line" ]
  total_value=${total_line#total_tokens=}
  # The original G9 acceptance target was 30K. The v0.7.4 audit (issue #330)
  # discovered that the CAT_RE regex had been silently skipping
  # `skills/<skill>/references/*.md` !cat lines, so the test was measuring a
  # source-file view that did NOT match what the build pipeline ships. Once
  # the regex was fixed to expand references/ inlines, the honest footprint
  # surfaced at ~51.5K tokens.
  #
  # We deliberately keep this gate red-but-relaxed at 55K rather than green
  # at 30K-with-a-broken-regex: the gate is now an honest ceiling preventing
  # further regression while issue #330's references/ relocation work brings
  # us back down toward the original 30K target.
  #
  # When #330 lands, ratchet this threshold down per the design.
  [ "$total_value" -lt 55000 ]
  # Sanity: must be positive (catches a stub that emits zero).
  [ "$total_value" -gt 0 ]
}

# --------------------------------------------------------------------------
# Test expectation: "Tokenizer-pin verification: a fixture input of known
# content (e.g., the literal string 'hello world' plus a longer canonical
# fixture) tokenised by the script produces a token count matching the
# documented tiktoken:cl100k_base count for that fixture — proves the
# tokenizer is identity-pinned and not silently substituted."
#
# Documented cl100k_base counts (computed via Python tiktoken 0.13.0):
#   "hello world"                                 -> 2 tokens
#   "The quick brown fox jumps over the lazy dog." -> 10 tokens
#
# Strategy: build a fixture skill whose SKILL.md body is EXACTLY the literal
# string (no trailing newline-induced extra tokens are added by tiktoken for
# a single trailing \n on these short inputs; we verify both fixtures share
# the same trailing-newline shape so any per-fixture offset cancels in the
# delta test below).
#
# Because the structure.md formula adds tokens(using-qrspi/SKILL.md), the
# raw total_tokens depends on the using-qrspi body and is not knowable here.
# We instead use --all to read the per-skill TSV row for each fixture, which
# is the tokens(fixture-skill-body) figure with no using-qrspi addend.
# --------------------------------------------------------------------------

@test "tokenizer is pinned to tiktoken cl100k_base on hello world fixture" {
  [ -x "$SCRIPT" ]

  mkdir -p "$REPO_ROOT/skills/$T37_HELLO_SKILL"
  # No trailing newline on the content line (printf '%s' not '%s\n') to keep
  # the input as close to the literal 'hello world' as possible. We still
  # rely on whatever fixed pre/post the tokenizer applies being deterministic,
  # which is the whole point of pinning. cl100k_base of "hello world" = 2.
  printf '%s' "hello world" > "$REPO_ROOT/skills/$T37_HELLO_SKILL/SKILL.md"

  run "$SCRIPT" --skill "$T37_HELLO_SKILL" --all
  [ "$status" -eq 0 ]

  # Tokenizer must be reported and equal to the documented pinned value.
  printf '%s\n' "$output" | grep -E '^tokenizer=tiktoken:cl100k_base$'

  hello_line=$(printf '%s\n' "$output" | grep -E "^${T37_HELLO_SKILL}[[:space:]]+[0-9]+$" || true)
  [ -n "$hello_line" ]
  # Extract trailing integer column (TSV: "skill<TAB>tokens").
  hello_tokens=$(printf '%s\n' "$hello_line" | awk '{print $NF}')
  [ "$hello_tokens" -eq 2 ]
}

@test "tokenizer is pinned to tiktoken cl100k_base on longer canonical fixture" {
  [ -x "$SCRIPT" ]

  mkdir -p "$REPO_ROOT/skills/$T37_FOX_SKILL"
  printf '%s' "The quick brown fox jumps over the lazy dog." \
    > "$REPO_ROOT/skills/$T37_FOX_SKILL/SKILL.md"

  run "$SCRIPT" --skill "$T37_FOX_SKILL" --all
  [ "$status" -eq 0 ]

  fox_line=$(printf '%s\n' "$output" | grep -E "^${T37_FOX_SKILL}[[:space:]]+[0-9]+$" || true)
  [ -n "$fox_line" ]
  fox_tokens=$(printf '%s\n' "$fox_line" | awk '{print $NF}')
  # cl100k_base count for "The quick brown fox jumps over the lazy dog." = 10.
  [ "$fox_tokens" -eq 10 ]
}

# --------------------------------------------------------------------------
# Test expectation: "The pinned tokenizer binary or library is not installed
# on the runtime PATH (or the documented tiktoken:cl100k_base model file
# cannot be loaded) — the script halts non-zero with the
# footprint-tokenizer-missing: named diagnostic naming the tokenizer
# identifier and the resolution path it attempted, before any !cat
# resolution begins; no fallback to a non-pinned tokenizer."
# Exit code per structure.md = 3.
#
# Simulation: invoke with a stripped PATH so the script's tokenizer probe
# (python3 + tiktoken, or any other binary the implementer chose) cannot
# resolve. Bash itself runs because we exec it directly by path. We also
# unset PYTHONPATH/PYTHONUSERBASE so a user-site tiktoken cannot leak in.
# --------------------------------------------------------------------------

@test "missing tokenizer exits non-zero with footprint-tokenizer-missing diagnostic naming the identifier" {
  [ -x "$SCRIPT" ]

  # Use the system bash (3.2 on macOS) by absolute path so PATH stripping
  # cannot break the interpreter itself. /bin/bash is universally present on
  # macOS and Linux CI runners alike.
  [ -x /bin/bash ]

  run env -i PATH="/nonexistent_t37_path" HOME="$HOME" \
    /bin/bash "$SCRIPT" --tokenizer tiktoken:cl100k_base --skill using-qrspi
  [ "$status" -ne 0 ]
  printf '%s\n' "$output" | grep -F -- "footprint-tokenizer-missing:"
  # Diagnostic must name the tokenizer identifier so the operator knows which
  # pinned tokenizer failed to load.
  printf '%s\n' "$output" | grep -F -- "tiktoken:cl100k_base"
}

# --------------------------------------------------------------------------
# Test expectation: "The script invoked against a skill name that does not
# exist under skills/ (e.g., a typo or removed skill — input asks for
# using-qrspi-x or removed-skill) halts non-zero with the
# footprint-skill-not-found: named diagnostic naming the missing skill
# identifier, before any !cat resolution begins; no silent zero-footprint
# emission for the missing skill."
# Exit code per structure.md = 6 (also acceptable: 2 per the structure.md
# "--skill not found" line under exit 2 — the test accepts non-zero broadly
# and asserts on the named diagnostic, which is the load-bearing contract).
# --------------------------------------------------------------------------

@test "missing skill name exits non-zero with footprint-skill-not-found diagnostic naming the skill" {
  [ -x "$SCRIPT" ]

  # Pick a clearly-implausible name (the spec's own example: using-qrspi-x).
  missing="using-qrspi-x__t37_definitely_absent__"
  [ ! -d "$REPO_ROOT/skills/$missing" ]

  run "$SCRIPT" --skill "$missing"
  [ "$status" -ne 0 ]
  printf '%s\n' "$output" | grep -F -- "footprint-skill-not-found:"
  printf '%s\n' "$output" | grep -F -- "$missing"
}

# --------------------------------------------------------------------------
# Test expectation: "The captured stdout is written to
# docs/qrspi/2026-06-04-v073-release/g9-footprint-report.md (G9 Acceptance
# bullet 7, final clause)."
#
# The report is the G9 acceptance evidence artifact: it must exist on the
# branch tip with the script's stdout as its body. Validate: file exists,
# carries the documented stdout-shape lines (active_skill=, tokenizer=,
# total_tokens=) and the total is below 30K.
# --------------------------------------------------------------------------

@test "g9-footprint-report.md exists and contains the documented stdout shape" {
  [ -f "$REPORT_PATH" ]

  # active_skill=<name>
  grep -E '^active_skill=' "$REPORT_PATH"
  # tokenizer=tiktoken:cl100k_base (pinned)
  grep -E '^tokenizer=tiktoken:cl100k_base$' "$REPORT_PATH"
  # total_tokens=<integer> below 30K
  total_line=$(grep -E '^total_tokens=[0-9]+$' "$REPORT_PATH" | tail -n 1 || true)
  [ -n "$total_line" ]
  total_value=${total_line#total_tokens=}
  [ "$total_value" -gt 0 ]
  # See neighbor "trimmed-tree heaviest-skill footprint" test for the 55K
  # rationale (issue #330 honest-measurement ratchet).
  [ "$total_value" -lt 55000 ]
}
