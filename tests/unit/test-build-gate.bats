#!/usr/bin/env bats

setup_file() {
  REPO_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/../.." && pwd -P)"
  export REPO_ROOT
}

@test "plan/SKILL.md documents the build_command field" {
  run grep -F 'build_command' "$REPO_ROOT/skills/plan/SKILL.md"
  [ "$status" -eq 0 ]
}

@test "plan/SKILL.md allows 'none' as a build_command sentinel" {
  run grep -F "'none'" "$REPO_ROOT/skills/plan/SKILL.md"
  [ "$status" -eq 0 ]
}

@test "implement/SKILL.md runs build after tests in per-task verification" {
  run grep -E -i 'build.*after.*test|run.*build_command|run the (project|plan).*build' "$REPO_ROOT/skills/implement/SKILL.md"
  [ "$status" -eq 0 ]
}

@test "implement/SKILL.md fails the task when build exits non-zero" {
  # Tighten: require the build-verification context so a stale doc that mentions
  # "non-zero exit" elsewhere (e.g., Codex error codes) doesn't satisfy this.
  # Uses flag-based awk (not range /pat/,/pat/) because start and end share "^###".
  run bash -c "awk '/^### Build Verification/{found=1} found && /^###/ && !/^### Build Verification/{exit} found' '$REPO_ROOT/skills/implement/SKILL.md' | grep -E -i 'non-zero exit fails the task|fail.*task.*build|non-zero.*exit.*captur'"
  [ "$status" -eq 0 ]
}

@test "implementer-protocol/SKILL.md states all-green rule" {
  run bash -c "awk '/^### Done Signal/,/^##[^#]/' '$REPO_ROOT/skills/implementer-protocol/SKILL.md' | grep -E -i 'four|five|tests.*build.*typecheck|all (four|five)? ?green|all (are )?required'"
  [ "$status" -eq 0 ]
}

# ===========================================================================
# T39 / G32 — tools/build-plugin.mjs resolver + build pipeline pins.
#
# Per docs/qrspi/2026-05-30-v072-release/structure.md §`tests/unit/test-build-gate.bats`
# (Slice 1.7) and tasks/task-39.md §"Test expectations":
#
#   - resolver strict grammar / repo-root resolution / transitive nesting /
#     CR stripping / no extra blank lines / idempotence
#   - fail-loud (file:line + reason) on every D3 condition: malformed `!cat`,
#     missing target, cycle (full cycle printed), absolute path, `..` traversal,
#     outside-root include, `${CLAUDE_SKILL_DIR}` in shipped file
#   - symlink-escape regression mirroring T21's assert_path_under_repo_root
#   - stale-build diagnostic shape (PR-CI gate)
#
# Test expectations under exercise are commented inline next to each `@test`.
# Fixtures are created under BATS_TEST_TMPDIR with a minimal source layout
# (.claude-plugin/plugin.json + skills/ tree) and invoked through the
# resolver's documented `--root` / `--out` CLI surface so each fixture is
# isolated from the real source tree (per structure.md "Fixture authoring":
# "keep fixtures inside a test-local subdirectory so they do not pollute the
# real `!cat` resolution surface").
# ===========================================================================

# Helper: stage a minimal source root with a manifest and a single skill file
# whose body is the caller-supplied content. Echoes the absolute path of the
# staged root so callers can pass it to `--root`.
_t39_stage_root() {
  local root="$1"; shift
  local skill_body="$1"; shift
  mkdir -p "$root/.claude-plugin" "$root/skills/sample" "$root/scripts" "$root/templates" "$root/.github/plugin"
  # T28 / G8: build script reads VERSION at repo root before any walk and
  # stamps the four source consumer manifests. Fixture provides all five
  # so the resolver/D3 paths under exercise here run to their failure mode
  # instead of being short-circuited by VERSION/consumer pre-flight checks.
  printf '0.0.0\n' >"$root/VERSION"
  cat >"$root/.claude-plugin/plugin.json" <<JSON
{ "name": "qrspi-fixture", "version": "0.0.0", "skills": ["./skills"] }
JSON
  cat >"$root/.claude-plugin/marketplace.json" <<JSON
{ "name": "fixture-local", "plugins": [ { "name": "qrspi-fixture", "version": "0.0.0", "source": "./build" } ] }
JSON
  cat >"$root/.github/plugin/plugin.json" <<JSON
{ "name": "qrspi-fixture", "version": "0.0.0" }
JSON
  cat >"$root/.github/plugin/marketplace.json" <<JSON
{ "name": "qrspi-fixture", "metadata": { "version": "0.0.0" }, "plugins": [ { "name": "qrspi-fixture", "version": "0.0.0" } ] }
JSON
  printf '%s' "$skill_body" >"$root/skills/sample/SKILL.md"
  : >"$root/LICENSE"
  : >"$root/README.md"
}

_t39_run_build() {
  local root="$1"
  local out="${2:-$root/build}"
  ( cd "$REPO_ROOT" && node "$REPO_ROOT/tools/build-plugin.mjs" --root "$root" --out "$out" )
}

# ---------------------------------------------------------------------------
# Happy-path: build script exists, exits 0, and writes a build/ tree.
# Test expectation: "Run `node tools/build-plugin.mjs`; assert it exits 0
# and creates a reproducible `build/` tree from the manifest plus fixed
# include list."
# ---------------------------------------------------------------------------
@test "tools/build-plugin.mjs exists and is a Node ES module" {
  [ -f "$REPO_ROOT/tools/build-plugin.mjs" ]
}

@test "node tools/build-plugin.mjs on a minimal fixture exits 0 and produces build/" {
  local root="$BATS_TEST_TMPDIR/happy"
  _t39_stage_root "$root" "# sample"$'\n'
  run _t39_run_build "$root"
  [ "$status" -eq 0 ]
  [ -d "$root/build" ]
  [ -d "$root/build/skills/sample" ]
  [ -f "$root/build/skills/sample/SKILL.md" ]
}

# ---------------------------------------------------------------------------
# Resolver: strict grammar acceptance + repo-root resolution + transitive
# nested expansion + no extra blank lines + idempotence.
# Test expectations:
#   - "Unit-test resolver success cases for strict grammar acceptance,
#      repo-root resolution, transitive nested expansion, CR stripping, no
#      extra blank lines, and idempotent byte-identical re-run behavior."
# ---------------------------------------------------------------------------
@test "resolver: bare-relative !cat directive is expanded from repo root" {
  local root="$BATS_TEST_TMPDIR/grammar"
  _t39_stage_root "$root" "# Header"$'\n'"!cat skills/sample/included.md"$'\n'"# Trailer"$'\n'
  printf 'INCLUDED_BODY\n' >"$root/skills/sample/included.md"
  run _t39_run_build "$root"
  [ "$status" -eq 0 ]
  run grep -F 'INCLUDED_BODY' "$root/build/skills/sample/SKILL.md"
  [ "$status" -eq 0 ]
  run grep -F '!cat skills/sample/included.md' "$root/build/skills/sample/SKILL.md"
  [ "$status" -ne 0 ]
}

@test "resolver: nested transitive expansion (A includes B includes C) in single pass" {
  local root="$BATS_TEST_TMPDIR/nested"
  _t39_stage_root "$root" "TOP"$'\n'"!cat skills/sample/b.md"$'\n'"END"$'\n'
  printf 'B_PRE\n!cat skills/sample/c.md\nB_POST\n' >"$root/skills/sample/b.md"
  printf 'C_BODY\n' >"$root/skills/sample/c.md"
  run _t39_run_build "$root"
  [ "$status" -eq 0 ]
  run grep -F 'C_BODY' "$root/build/skills/sample/SKILL.md"
  [ "$status" -eq 0 ]
  run grep -F '!cat ' "$root/build/skills/sample/SKILL.md"
  [ "$status" -ne 0 ]
}

@test "resolver: idempotent — running on already-expanded build/ output is byte-identical" {
  local root="$BATS_TEST_TMPDIR/idem"
  _t39_stage_root "$root" "X"$'\n'"!cat skills/sample/included.md"$'\n'
  printf 'INCLUDED\n' >"$root/skills/sample/included.md"
  run _t39_run_build "$root"
  [ "$status" -eq 0 ]
  cp "$root/build/skills/sample/SKILL.md" "$BATS_TEST_TMPDIR/first.md"
  # Re-run the resolver against the already-expanded build/ as its source
  # root: must produce a byte-identical file (no `!cat` directives remain
  # to expand; second run is a no-op on resolver output).
  local root2="$BATS_TEST_TMPDIR/idem2"
  _t39_stage_root "$root2" ""
  cp "$root/build/skills/sample/SKILL.md" "$root2/skills/sample/SKILL.md"
  run _t39_run_build "$root2"
  [ "$status" -eq 0 ]
  run diff -q "$BATS_TEST_TMPDIR/first.md" "$root2/build/skills/sample/SKILL.md"
  [ "$status" -eq 0 ]
}

@test "resolver: strips CR (\\r) characters from included content" {
  local root="$BATS_TEST_TMPDIR/cr"
  _t39_stage_root "$root" "TOP"$'\n'"!cat skills/sample/crlf.md"$'\n'
  printf 'CRLF_LINE\r\nNEXT\r\n' >"$root/skills/sample/crlf.md"
  run _t39_run_build "$root"
  [ "$status" -eq 0 ]
  # No CR bytes should appear in the built file. R3 fix tc-F05: replaced
  # `grep -U $'\r'` (GNU-only `-U` makes the assertion vacuously pass on
  # BSD/BusyBox grep) with a size-diff check using `tr -d '\r'`, which is
  # portable across bash 3.2 + BSD/GNU/BusyBox.
  local _bg_built="$root/build/skills/sample/SKILL.md"
  local _bg_sz_with _bg_sz_without
  _bg_sz_with=$(wc -c <"$_bg_built")
  _bg_sz_without=$(tr -d '\r' <"$_bg_built" | wc -c)
  [ "$_bg_sz_with" -eq "$_bg_sz_without" ]
}

@test "resolver: directive line is replaced 1:1 with include content (no extra blank lines)" {
  local root="$BATS_TEST_TMPDIR/blank"
  _t39_stage_root "$root" "L1"$'\n'"!cat skills/sample/inc.md"$'\n'"L3"$'\n'
  printf 'L2\n' >"$root/skills/sample/inc.md"
  run _t39_run_build "$root"
  [ "$status" -eq 0 ]
  # Built file should be exactly L1\nL2\nL3\n with no extra blank line at the
  # directive's former position.
  run cat "$root/build/skills/sample/SKILL.md"
  [ "$status" -eq 0 ]
  [ "$output" = "L1
L2
L3" ]
}

# ---------------------------------------------------------------------------
# Resolver fail-loud conditions (D3). Each must exit non-zero with file:line
# plus a reason on stderr, per task-39 §Definition of done bullet on D3.
# Test expectation: "Unit-test resolver failure cases for malformed `!cat`
# lines, missing targets, include cycles with full cycle printed, absolute
# paths, path traversal/escaping attempts, outside-root includes, and
# `${CLAUDE_SKILL_DIR}` in shipped files."
# ---------------------------------------------------------------------------
@test "fail-loud: malformed !cat line (extra arg) exits non-zero with file:line diagnostic" {
  local root="$BATS_TEST_TMPDIR/malformed"
  _t39_stage_root "$root" "X"$'\n'"!cat skills/sample/inc.md extraneous-arg"$'\n'
  printf 'BODY\n' >"$root/skills/sample/inc.md"
  run _t39_run_build "$root"
  [ "$status" -ne 0 ]
  # stderr (merged) must contain SKILL.md:2 (the offending line) and a reason.
  echo "$output" | grep -E 'SKILL\.md:2'
}

@test "fail-loud: missing target file exits non-zero with file:line diagnostic" {
  local root="$BATS_TEST_TMPDIR/missing"
  _t39_stage_root "$root" "X"$'\n'"!cat skills/sample/does-not-exist.md"$'\n'
  run _t39_run_build "$root"
  [ "$status" -ne 0 ]
  echo "$output" | grep -E 'SKILL\.md:2'
  echo "$output" | grep -E -i 'not found|does not exist|missing'
}

@test "fail-loud: include cycle exits non-zero with the FULL cycle printed" {
  local root="$BATS_TEST_TMPDIR/cycle"
  _t39_stage_root "$root" "TOP"$'\n'"!cat skills/sample/a.md"$'\n'
  printf 'A\n!cat skills/sample/b.md\n' >"$root/skills/sample/a.md"
  printf 'B\n!cat skills/sample/a.md\n' >"$root/skills/sample/b.md"
  run _t39_run_build "$root"
  [ "$status" -ne 0 ]
  # Full cycle must be printed: both file paths must appear in the diagnostic.
  echo "$output" | grep -F 'skills/sample/a.md'
  echo "$output" | grep -F 'skills/sample/b.md'
  echo "$output" | grep -E -i 'cycle|circular'
}

@test "fail-loud: absolute-path include rejected" {
  local root="$BATS_TEST_TMPDIR/abs"
  _t39_stage_root "$root" "X"$'\n'"!cat /etc/passwd"$'\n'
  run _t39_run_build "$root"
  [ "$status" -ne 0 ]
  # Absolute path must fail grammar OR path-resolution; either way diagnostic
  # must reference the offending line and a non-trivial reason.
  echo "$output" | grep -E 'SKILL\.md:2'
}

@test "fail-loud: '..' path traversal rejected" {
  local root="$BATS_TEST_TMPDIR/traverse"
  _t39_stage_root "$root" "X"$'\n'"!cat ../escape.md"$'\n'
  printf 'OUTSIDE\n' >"$BATS_TEST_TMPDIR/escape.md"
  run _t39_run_build "$root"
  [ "$status" -ne 0 ]
  echo "$output" | grep -E -i 'outside|traversal|invalid'
}

@test "fail-loud: \${CLAUDE_SKILL_DIR} occurrence in shipped file rejected" {
  local root="$BATS_TEST_TMPDIR/legacy"
  _t39_stage_root "$root" 'embedded ${CLAUDE_SKILL_DIR}/x in body'$'\n'
  run _t39_run_build "$root"
  [ "$status" -ne 0 ]
  echo "$output" | grep -F 'CLAUDE_SKILL_DIR'
  echo "$output" | grep -E 'SKILL\.md:'
}

# ---------------------------------------------------------------------------
# Symlink-escape regression — task-39 §Test expectations final bullet:
#   "a fixture commits a `!cat`-targeted file that is itself a symlink whose
#   canonical target is outside `$REPO_ROOT` (e.g., `/etc/passwd` or
#   `/tmp/secret`); the build fails non-zero before any byte of the symlink's
#   referent enters the `build/` tree, with a stderr diagnostic containing
#   `resolves outside repository`."
# Mirrors T21's symlink-out-of-repo regression in test-dispatch-agent.bats.
# ---------------------------------------------------------------------------
@test "symlink-escape: !cat target whose canonical path is outside repo root fails with 'resolves outside repository'" {
  local root="$BATS_TEST_TMPDIR/symlink-escape"
  _t39_stage_root "$root" "X"$'\n'"!cat skills/sample/secret.md"$'\n'
  # Place the actual file outside the source root, then symlink into source.
  printf 'OUT_OF_REPO_SECRET\n' >"$BATS_TEST_TMPDIR/secret-outside.md"
  ln -s "$BATS_TEST_TMPDIR/secret-outside.md" "$root/skills/sample/secret.md"
  run _t39_run_build "$root"
  [ "$status" -ne 0 ]
  # Required diagnostic phrase per task-39 spec; mirrors T21 phrasing.
  echo "$output" | grep -F 'resolves outside repository'
  # No bytes of the referent should have leaked into build/.
  if [ -f "$root/build/skills/sample/SKILL.md" ]; then
    run grep -F 'OUT_OF_REPO_SECRET' "$root/build/skills/sample/SKILL.md"
    [ "$status" -ne 0 ]
  fi
}

# ---------------------------------------------------------------------------
# Stale-build diagnostic shape — Test expectation:
#   PR CI's `git diff --exit-code build/ .claude-plugin/marketplace.json`
#   exits non-zero when build/ on the branch differs from what the resolver
#   produces from current source, and the failure message points the author
#   at `node tools/build-plugin.mjs`.
# Asserted at the workflow-text level here; the live behavior is exercised
# by tests/unit/test-ci-workflow-shape.bats.
# ---------------------------------------------------------------------------
# ---------------------------------------------------------------------------
# Round-2 hardening: --out cannot resolve to the repository root, nor to any
# ancestor directory of the repository root. The wipe step
# (`fs.rmSync(outDirAbs, {recursive:true, force:true})`) would otherwise
# erase the working tree (including .git) silently — `force:true` swallows
# errors. Guard must fire BEFORE any rmSync call.
# ---------------------------------------------------------------------------
@test "fail-loud: --out resolving to repo root rejected before any rmSync" {
  local root="$BATS_TEST_TMPDIR/out-is-root"
  _t39_stage_root "$root" "# sample"$'\n'
  # Sentinel file at the source root — must remain after the failed run.
  printf 'SENTINEL\n' >"$root/CANARY.txt"
  run _t39_run_build "$root" "$root"
  [ "$status" -ne 0 ]
  echo "$output" | grep -E -i 'repository root|cannot.*root|--out'
  # Source tree must still be intact: rmSync must not have wiped the root.
  [ -f "$root/CANARY.txt" ]
  [ -f "$root/.claude-plugin/plugin.json" ]
  [ -f "$root/skills/sample/SKILL.md" ]
}

@test "fail-loud: --out resolving to an ancestor of repo root rejected" {
  local parent="$BATS_TEST_TMPDIR/anc-parent"
  local root="$parent/repo"
  mkdir -p "$parent"
  _t39_stage_root "$root" "# sample"$'\n'
  printf 'PARENT_CANARY\n' >"$parent/PARENT_CANARY.txt"
  run _t39_run_build "$root" "$parent"
  [ "$status" -ne 0 ]
  echo "$output" | grep -E -i 'repository root|ancestor|--out'
  [ -f "$parent/PARENT_CANARY.txt" ]
  [ -f "$root/skills/sample/SKILL.md" ]
}

# ---------------------------------------------------------------------------
# Round-2 hardening: legacy `${CLAUDE_SKILL_DIR}` must be rejected in NON-.md
# shipped files too (scripts/*.sh, templates/*, .claude-plugin/*.json).
# Original implementation only scanned expanded .md files; non-.md content
# bypassed the guard.
# ---------------------------------------------------------------------------
@test "fail-loud: \${CLAUDE_SKILL_DIR} in shipped non-.md file rejected" {
  local root="$BATS_TEST_TMPDIR/legacy-non-md"
  _t39_stage_root "$root" "# clean"$'\n'
  # Place legacy token in a shipped shell script.
  printf '#!/usr/bin/env bash\necho "${CLAUDE_SKILL_DIR}/foo"\n' \
    >"$root/scripts/legacy-helper.sh"
  chmod +x "$root/scripts/legacy-helper.sh"
  run _t39_run_build "$root"
  [ "$status" -ne 0 ]
  echo "$output" | grep -F 'CLAUDE_SKILL_DIR'
  echo "$output" | grep -F 'scripts/legacy-helper.sh'
}

# ---------------------------------------------------------------------------
# Round-2 hardening: include depth cap defends against billion-laughs
# diamond-expansion DoS. Cycle-stack alone catches direct ancestor cycles
# but does not bound non-cyclic deep nesting.
# ---------------------------------------------------------------------------
@test "fail-loud: include depth cap rejects pathologically deep nesting" {
  local root="$BATS_TEST_TMPDIR/deep"
  _t39_stage_root "$root" "TOP"$'\n'"!cat skills/sample/n00.md"$'\n'
  # Build a 24-level linear chain: n00 -> n01 -> ... -> n23 -> leaf.
  # Cap is around ~16, so this must trip.
  local i
  for i in $(seq 0 23); do
    local nxt
    nxt=$(printf 'n%02d' $((i + 1)))
    printf 'L%02d\n!cat skills/sample/%s.md\n' "$i" "$nxt" \
      >"$root/skills/sample/$(printf 'n%02d' "$i").md"
  done
  printf 'LEAF\n' >"$root/skills/sample/n24.md"
  run _t39_run_build "$root"
  [ "$status" -ne 0 ]
  echo "$output" | grep -E -i 'depth|too deep|nesting'
}

# ---------------------------------------------------------------------------
# Round-2 hardening: per-cache-entry byte-size cap defends against
# materialized-output blow-up under intra-file fan-out. A file with N copies
# of `!cat <child>` caches an expansion of size N×|expand(child)|; with N=10
# at each of D levels the top-of-chain materialized size is N^D × |leaf|.
# Depth-cap alone bounds D but does NOT bound the materialized bytes.
#
# Fixture: 4 levels of N=10 fan-out (depth 4, well under MAX_INCLUDE_DEPTH=8)
# with a non-trivial leaf — top-level materialized size ~ 10^4 × leaf bytes,
# which exceeds the 4 MB per-entry cap. Build must fail-loud with the full
# include chain printed.
# ---------------------------------------------------------------------------
@test "fail-loud: per-cache-entry byte-size cap rejects intra-file fan-out blow-up" {
  local root="$BATS_TEST_TMPDIR/fanout"
  _t39_stage_root "$root" "TOP"$'\n'"!cat skills/sample/lvl0.md"$'\n'
  # Leaf: ~500 bytes so 10^4 × leaf > 4 MB.
  local leaf_line
  leaf_line=$(printf 'X%.0s' {1..499})
  printf '%s\n' "$leaf_line" >"$root/skills/sample/leaf.md"
  # Build 4 levels of 10× fan-out: lvl0 -> 10× lvl1 -> 10× lvl2 -> 10× lvl3 -> 10× leaf.
  local L next
  for L in 0 1 2 3; do
    next="leaf.md"
    if [ "$L" -lt 3 ]; then
      next="lvl$((L + 1)).md"
    fi
    : >"$root/skills/sample/lvl${L}.md"
    local k
    for k in $(seq 1 10); do
      printf '!cat skills/sample/%s\n' "$next" >>"$root/skills/sample/lvl${L}.md"
    done
  done
  run _t39_run_build "$root"
  [ "$status" -ne 0 ]
  # Diagnostic must indicate size-cap excess and print the include chain.
  echo "$output" | grep -E -i 'size|bytes|too large|cap'
  echo "$output" | grep -F 'skills/sample/lvl0.md'
  # No partial build/ output should leak the materialized blow-up.
  if [ -f "$root/build/skills/sample/SKILL.md" ]; then
    # Built file (if any) must be much smaller than 4 MB.
    local sz
    sz=$(wc -c <"$root/build/skills/sample/SKILL.md")
    [ "$sz" -lt 4194304 ]
  fi
}

@test "CI workflow text references node tools/build-plugin.mjs in the build-sync gate failure path" {
  [ -f "$REPO_ROOT/.github/workflows/ci.yml" ]
  run grep -F 'node tools/build-plugin.mjs' "$REPO_ROOT/.github/workflows/ci.yml"
  [ "$status" -eq 0 ]
  run grep -F 'git diff --exit-code build/' "$REPO_ROOT/.github/workflows/ci.yml"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Round-3 hardening (tc-F03): SECRET_BASENAME_PATTERNS denylist coverage.
# Plant secret/credential basenames inside fixture source roots and assert
# the build fails non-zero with a diagnostic naming the offending file.
# Covers both call paths through which the denylist fires:
#   - recurseDir (nested under a manifest dir like skills/ or scripts/)
#   - recurseDir at a manifest-dir top level (.claude-plugin/)
# Both paths flow through `isSecretBasename(entry.name)` in recurseDir.
# ---------------------------------------------------------------------------
@test "denylist: .env in skills/ subtree is rejected with file path in diagnostic" {
  local root="$BATS_TEST_TMPDIR/denylist-env"
  _t39_stage_root "$root" "# clean"$'\n'
  printf 'SECRET=value\n' >"$root/skills/sample/.env"
  run _t39_run_build "$root"
  [ "$status" -ne 0 ]
  # Diagnostic must name the offending file path so the contributor can
  # locate and remove it (or git rm + rebuild).
  echo "$output" | grep -F 'skills/sample/.env'
  echo "$output" | grep -E -i 'denylist|secret|refused'
  # No build/ output should have been created for the offending path.
  [ ! -e "$root/build/skills/sample/.env" ]
}

@test "denylist: id_rsa in scripts/ subtree is rejected with file path in diagnostic" {
  local root="$BATS_TEST_TMPDIR/denylist-id-rsa"
  _t39_stage_root "$root" "# clean"$'\n'
  printf 'BEGIN OPENSSH PRIVATE KEY\n' >"$root/scripts/id_rsa"
  run _t39_run_build "$root"
  [ "$status" -ne 0 ]
  echo "$output" | grep -F 'scripts/id_rsa'
  echo "$output" | grep -E -i 'denylist|secret|refused'
  [ ! -e "$root/build/scripts/id_rsa" ]
}

@test "denylist: *.pem in .claude-plugin/ is rejected with file path in diagnostic" {
  local root="$BATS_TEST_TMPDIR/denylist-pem"
  _t39_stage_root "$root" "# clean"$'\n'
  printf -- '-----BEGIN CERTIFICATE-----\n' >"$root/.claude-plugin/server.pem"
  run _t39_run_build "$root"
  [ "$status" -ne 0 ]
  echo "$output" | grep -F '.claude-plugin/server.pem'
  echo "$output" | grep -E -i 'denylist|secret|refused'
  [ ! -e "$root/build/.claude-plugin/server.pem" ]
}
