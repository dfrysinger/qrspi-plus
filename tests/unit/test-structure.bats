#!/usr/bin/env bats
bats_require_minimum_version 1.5.0

# Task 37 — R2 I-N5: Structure invokes Config Validation Procedure for second_reviewer
#
# Structure previously contained the silent-default fallback "If config.md
# doesn't exist, default to second_reviewer: false". using-qrspi:411-444 says
# "Every skill that reads config.md applies this procedure before using any
# field" and the "No silent defaults" subsection forbids assuming
# second_reviewer: false when missing. These tests assert structure/SKILL.md
# now invokes the Config Validation Procedure for second_reviewer and that no
# silent-default fallback prose remains.

setup() {
  STRUCTURE_FILE="$BATS_TEST_DIRNAME/../../skills/structure/SKILL.md"
  export STRUCTURE_FILE
}

@test "structure SKILL.md exists" {
  [ -f "$STRUCTURE_FILE" ]
}

@test "structure SKILL.md contains a Config Validation section" {
  run grep -c "^### Config Validation$" "$STRUCTURE_FILE"
  [ "$status" -eq 0 ]
  [ "$output" = "1" ]
}

@test "structure Config Validation section invokes the using-qrspi Config Validation Procedure" {
  # Match the canonical invocation prose used by Plan/Integrate so the
  # Procedure is referenced rather than re-inlined.
  grep -Eq "Apply the \*\*Config Validation Procedure\*\* in \`using-qrspi/SKILL\.md\`\." "$STRUCTURE_FILE"
}

@test "structure Config Validation declares second_reviewer as the field it validates" {
  # The invocation line must name second_reviewer, mirroring the Plan/Integrate
  # pattern ("X validates pipeline, route, and second_reviewer", etc.). This
  # prevents a vacuous invocation that doesn't actually validate anything.
  grep -Eq "Structure validates [^.]*second_reviewer" "$STRUCTURE_FILE"
}

@test "structure SKILL.md no longer contains the silent-default fallback for second_reviewer" {
  # The previous prose was: "If config.md doesn't exist, default to
  # second_reviewer: false." Assert that exact silent-default phrasing is gone.
  run grep -E "default to .second_reviewer: false." "$STRUCTURE_FILE"
  [ "$status" -ne 0 ]
}

@test "structure SKILL.md does not silently default any second_reviewer value" {
  # Broader guard: forbid any "default to second_reviewer ..." or "second_reviewer
  # defaults to ..." phrasing surviving in structure.md.
  run grep -Ei "default(s)? to[[:space:]]+.?second_reviewer|second_reviewer[^A-Za-z0-9_].*defaults? to" "$STRUCTURE_FILE"
  [ "$status" -ne 0 ]
}
