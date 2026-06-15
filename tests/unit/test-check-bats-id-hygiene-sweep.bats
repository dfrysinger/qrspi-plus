#!/usr/bin/env bats
# ============================================================================
# Coverage for the pre-committed structural-lint script
# scripts/structural-lints/check-bats-id-hygiene-sweep.sh.
#
# The script gates the bats ID-hygiene sweep (cited as the schema-migration
# `structural_lint:` for the bats-corpus mechanical sweep): it reads a
# unified diff from stdin and accepts only mechanical-only edits — either
# `@test "..."` description-string token strips inside existing .bats files
# under tests/, or brand-new files under tests/fixtures/. Anything else
# (non-@test body change, non-.bats file edit, or empty diff) MUST exit
# non-zero with a named diagnostic on stderr.
#
# Locks the script's behaviour against silent regression so the
# mandatory-trio existence check on the consumer task remains meaningful.
# ============================================================================

setup() {
  REPO_ROOT=$(cd "$BATS_TEST_DIRNAME/../.." && pwd)
  export REPO_ROOT
  SCRIPT="$REPO_ROOT/scripts/structural-lints/check-bats-id-hygiene-sweep.sh"
  export SCRIPT
  [ -x "$SCRIPT" ] || chmod +x "$SCRIPT"
}

# ----------------------------------------------------------------------------
# Pass cases: mechanical-only diffs exit 0.
# ----------------------------------------------------------------------------

@test "description-string strip inside existing bats file exits 0" {
  # Bracketed token assembled at runtime so the literal `[T01]` never
  # appears at column 0 in this fixture source — keeps the bats-corpus
  # [Tnn] sweep (test-g2-bats-id-hygiene #1) clean while preserving the
  # exact diff payload the script under test must accept. Switching to an
  # unquoted heredoc so ${ob}/${cb} expand; no `$` or backticks live in
  # the diff body itself, so no other escaping is required.
  ob='['
  cb=']'
  diff_input=$(cat <<DIFF
diff --git a/tests/unit/test-example.bats b/tests/unit/test-example.bats
index 1111111..2222222 100644
--- a/tests/unit/test-example.bats
+++ b/tests/unit/test-example.bats
@@ -10,7 +10,7 @@
 setup() {
   :
 }
-@test "${ob}T01${cb} sample assertion holds for inputs" {
+@test "sample assertion holds for inputs" {
   run true
   [ "\$status" -eq 0 ]
 }
DIFF
)
  run bash -c 'printf "%s\n" "$1" | "$2"' _ "$diff_input" "$SCRIPT"
  [ "$status" -eq 0 ]
}

@test "brand-new fixture under tests/fixtures plus description strip exits 0" {
  # See sibling test above re: runtime-assembled bracket token. Same
  # rationale — preserves exact diff payload while keeping the corpus
  # sweep clean.
  ob='['
  cb=']'
  diff_input=$(cat <<DIFF
diff --git a/tests/unit/test-example.bats b/tests/unit/test-example.bats
index 1111111..2222222 100644
--- a/tests/unit/test-example.bats
+++ b/tests/unit/test-example.bats
@@ -1,3 +1,3 @@
-@test "${ob}T11${cb} mechanical sweep is sound" {
+@test "mechanical sweep is sound" {
   :
 }
diff --git a/tests/fixtures/sample-id-token.txt b/tests/fixtures/sample-id-token.txt
new file mode 100644
index 0000000..3333333
--- /dev/null
+++ b/tests/fixtures/sample-id-token.txt
@@ -0,0 +1,2 @@
+# fixture body — intentional token preserved here, never in @test desc
+marker-token-line
DIFF
)
  run bash -c 'printf "%s\n" "$1" | "$2"' _ "$diff_input" "$SCRIPT"
  [ "$status" -eq 0 ]
}

# ----------------------------------------------------------------------------
# Fail cases: non-mechanical diffs exit non-zero with a named diagnostic.
# ----------------------------------------------------------------------------

@test "body-content change inside existing bats test body exits non-zero with file:line diagnostic" {
  diff_input=$(cat <<'DIFF'
diff --git a/tests/unit/test-example.bats b/tests/unit/test-example.bats
index 1111111..2222222 100644
--- a/tests/unit/test-example.bats
+++ b/tests/unit/test-example.bats
@@ -10,7 +10,7 @@
 @test "sample assertion holds for inputs" {
   run true
-  [ "$status" -eq 0 ]
+  [ "$status" -eq 1 ]
 }
DIFF
)
  run bash -c 'printf "%s\n" "$1" | "$2"' _ "$diff_input" "$SCRIPT"
  [ "$status" -ne 0 ]
  [[ "$output" == *"tests/unit/test-example.bats"* ]]
  [[ "$output" == *"non-@test"* ]] || [[ "$output" == *"body-content"* ]]
}

@test "edit to non-bats file outside tests/fixtures exits non-zero with named diagnostic" {
  diff_input=$(cat <<'DIFF'
diff --git a/scripts/some-script.sh b/scripts/some-script.sh
index 1111111..2222222 100644
--- a/scripts/some-script.sh
+++ b/scripts/some-script.sh
@@ -1,3 +1,3 @@
 #!/usr/bin/env bash
-echo old
+echo new
DIFF
)
  run bash -c 'printf "%s\n" "$1" | "$2"' _ "$diff_input" "$SCRIPT"
  [ "$status" -ne 0 ]
  [[ "$output" == *"scripts/some-script.sh"* ]]
  [[ "$output" == *"outside tests"* ]] || [[ "$output" == *"not mechanical"* ]] || [[ "$output" == *"only @test"* ]]
}

@test "empty diff exits non-zero — vacuous pass forbidden" {
  run bash -c ': | "$1"' _ "$SCRIPT"
  [ "$status" -ne 0 ]
  [[ "$output" == *"empty"* ]] || [[ "$output" == *"vacuous"* ]]
}
