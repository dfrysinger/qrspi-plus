#!/usr/bin/env bats

setup() {
  MENU=$(awk '
    /\*\*Verifier-round failure menu\.\*\*/ { in_block=1; next }
    in_block && /^\*\*[A-Z]/ { exit }
    in_block && /^## / { exit }
    in_block { print }
  ' skills/using-qrspi/SKILL.md)
}

@test "menu describes three exact options: skip, retry, stop" {
  echo "$MENU" | grep -qE '^\s*1\.\s*skip\b'
  echo "$MENU" | grep -qE '^\s*2\.\s*retry\b'
  echo "$MENU" | grep -qE '^\s*3\.\s*stop\b'
}

@test "menu has no default option" {
  echo "$MENU" | grep -qE 'no default|user must pick|must select'
}

@test "skip writes round-NN-verifier-disabled.md and does NOT mutate config.md" {
  echo "$MENU" | grep -qF 'verifier-disabled.md'
  echo "$MENU" | grep -qE 'does NOT mutate.*config\.md|no config\.md mutation'
}

@test "skip's round-NN-verifier-disabled.md write contract pins the three spec §3 fields" {
  # Spec §3: "timestamp + reason + finding count". The bats test pins all
  # three fields are documented in the menu prose (which is sourced from the
  # spec text the implementer pasted into using-qrspi/SKILL.md). If a future
  # edit drops one of these fields, this test fails — preventing the
  # implementer from authoring a schema-incomplete write contract.
  echo "$MENU" | grep -qE 'timestamp:|^[[:space:]]*timestamp\b'
  echo "$MENU" | grep -qE 'reason:|^[[:space:]]*reason\b'
  echo "$MENU" | grep -qE 'finding_count:|finding count'
}

@test "retry for reviewer-no-output deletes stale tag files before re-dispatch" {
  echo "$MENU" | grep -qE '\*\.finding-\*\.md.*\*\.score\.yml.*\*\.clean\.md|delete.*tag.*finding.*score.*clean|retry.*clean.*stale'
}

@test "always-on footer is present" {
  echo "$MENU" | grep -qF "the safe escape"
}

@test "menu covers the four abnormality classes" {
  echo "$MENU" | grep -qiE 'VERIFY_FAILED'
  echo "$MENU" | grep -qiE 'reviewer.*no output|produced no output'
  echo "$MENU" | grep -qiE 'sidecar missing|missing sidecar'
}

@test "each menu-cases fixture's cited diagnostic appears verbatim in the menu prose" {
  # Spec §5 test #5: "Fixture covers each abnormality the menu handles." Each
  # fixture carries a cited-diagnostic.txt naming the regex the menu prose
  # must contain to handle that abnormality. Iterating over the fixtures
  # asserts the menu is fixture-backed, not just a static prose match.
  for case_dir in tests/fixtures/issue-109/menu-cases/*/; do
    [[ -d "$case_dir" ]] || continue
    local cited
    cited=$(cat "${case_dir}cited-diagnostic.txt")
    echo "$MENU" | grep -qiE "$cited" \
      || { echo "menu prose does not match cited diagnostic for $case_dir: $cited"; return 1; }
  done
}
