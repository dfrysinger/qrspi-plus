#!/usr/bin/env bash
# check-bats-id-hygiene-sweep.sh
#
# Structural lint for the T11 bats-test-name ID-hygiene sweep. Asserts that a
# proposed unified diff is mechanical-only — every modified hunk is one of:
#   (a) An `@test "..."` description-string token strip inside an existing
#       `.bats` file under `tests/` (leading/trailing `[Tnn]` or `[F<digits>]`
#       tokens removed from the description; body content untouched).
#   (b) A brand-new file under `tests/fixtures/` (intentional fixture
#       relocation of tokens the sweep moves out of `@test` descriptions).
#
# Reads the unified diff from stdin; if stdin is a TTY, falls back to
# `git diff HEAD` against the working tree.
#
# Exit codes:
#   0  diff is mechanical-only AND non-empty.
#   1  diff is empty (vacuous pass forbidden), OR contains a non-mechanical
#      change. Offending file:line and reason are emitted to stderr.

set -euo pipefail

emit() { printf '%s: %s\n' "$(basename -- "${BASH_SOURCE[0]}")" "$*" >&2; }

if [ -t 0 ]; then
  diff_input="$(git diff HEAD 2>/dev/null || true)"
else
  diff_input="$(cat)"
fi

# Emptiness probe — avoid bash global parameter substitution on large diffs
# (O(N^2) in bash 3.2/macOS); use tr instead, which is linear.
if [ -z "$(printf '%s' "$diff_input" | tr -d '[:space:]' | head -c 1)" ]; then
  emit "diff is empty — vacuous pass forbidden; the structural lint requires a non-empty diff to prove mechanical-only nature."
  exit 1
fi

# Per-file walk via awk: classify each file as new-fixture or existing-bats,
# track changed lines, and emit a violation diagnostic with file:line when a
# changed line does not match the allowed shape for its file class.
#
# State emitted on stdout: one line per violation, format "VIOLATION<TAB>file<TAB>line<TAB>reason".
violations="$(printf '%s\n' "$diff_input" | awk '
  function reset_file() {
    file=""; is_new=0; in_hunk=0; old_ln=0; new_ln=0; class="";
  }
  BEGIN { reset_file() }

  /^diff --git / {
    reset_file();
    next;
  }
  /^new file mode/ { is_new=1; next }
  /^--- / { next }
  /^\+\+\+ / {
    sub(/^\+\+\+ /, "");
    sub(/^b\//, "");
    file=$0;
    if (is_new) {
      if (file ~ /^tests\/fixtures\//) {
        class="new-fixture";
      } else if (file ~ /^tests\/.*\.bats$/) {
        # New .bats files under tests/ are allowed: the T11 sweep ships its
        # own acceptance test file alongside the mechanical strips.
        class="new-bats";
      } else {
        printf "VIOLATION\t%s\t0\tnew file outside tests/fixtures/ or tests/**/*.bats — only fixture additions and new bats test files are mechanical\n", file;
        class="reject";
      }
    } else {
      if (file ~ /^tests\/.*\.bats$/) {
        class="existing-bats";
      } else {
        printf "VIOLATION\t%s\t0\tmodified file outside tests/**/*.bats — only @test description token strips in existing .bats files are mechanical\n", file;
        class="reject";
      }
    }
    next;
  }
  /^@@ / {
    in_hunk=1;
    # Parse @@ -old,oldcount +new,newcount @@
    match($0, /\+[0-9]+/);
    new_ln=substr($0, RSTART+1, RLENGTH-1)+0;
    match($0, /-[0-9]+/);
    old_ln=substr($0, RSTART+1, RLENGTH-1)+0;
    next;
  }
  in_hunk && class=="existing-bats" {
    line=$0;
    if (substr(line,1,1)=="+") {
      body=substr(line,2);
      if (body !~ /^@test "/) {
        printf "VIOLATION\t%s\t%d\tnon-@test changed line in existing .bats file — body-content edits are not mechanical\n", file, new_ln;
      }
      new_ln++;
    } else if (substr(line,1,1)=="-") {
      body=substr(line,2);
      if (body !~ /^@test "/) {
        printf "VIOLATION\t%s\t%d\tnon-@test changed line in existing .bats file — body-content edits are not mechanical\n", file, old_ln;
      }
      old_ln++;
    } else {
      # context line " ..." — advance both
      old_ln++; new_ln++;
    }
    next;
  }
  in_hunk && (class=="new-fixture" || class=="new-bats") {
    # All-add hunks expected; reject any "-" line (impossible for new file, but defensive).
    if (substr($0,1,1)=="-") {
      printf "VIOLATION\t%s\t%d\tunexpected deletion in new file\n", file, old_ln;
    }
    if (substr($0,1,1)=="+" || substr($0,1,1)==" ") new_ln++;
    if (substr($0,1,1)=="-" || substr($0,1,1)==" ") old_ln++;
    next;
  }
')"

if [ -n "$violations" ]; then
  while IFS=$'\t' read -r tag file line reason; do
    [ "$tag" = "VIOLATION" ] || continue
    emit "${file}:${line}: ${reason}"
  done <<< "$violations"
  emit "structural lint failed — diff is not mechanical-only."
  exit 1
fi

exit 0
