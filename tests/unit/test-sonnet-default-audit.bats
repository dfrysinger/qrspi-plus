#!/usr/bin/env bats

# Structural CI test: regression guard for #117 Part 1 (Sonnet-default audit).
# Asserts that every non-reviewer, non-implementer Agent dispatch in skills/**/SKILL.md
# pins model explicitly — no silent inheritance from parent default.
#
# Coverage:
# - The four sites named in spec §9 audit table (research-specialist, research-collator,
#   replan-analyzer, test-writer) carry their expected per-site pin.
# - Reviewer dispatches in skills/**/SKILL.md continue to pin model: "sonnet" (per #101).

setup() {
  cd "$BATS_TEST_DIRNAME/../.."
}

@test "research/SKILL.md pins qrspi-research-specialist to sonnet" {
  grep -E 'subagent_type: "qrspi-research-specialist".*model: "sonnet"' \
    skills/research/SKILL.md > /dev/null
}

@test "research/SKILL.md pins qrspi-research-collator to sonnet" {
  grep -E 'subagent_type: "qrspi-research-collator".*model: "sonnet"' \
    skills/research/SKILL.md > /dev/null
}

@test "replan/SKILL.md pins qrspi-replan-analyzer to sonnet" {
  grep -E 'subagent_type: "qrspi-replan-analyzer".*model: "sonnet"' \
    skills/replan/SKILL.md > /dev/null
}

@test "test/SKILL.md reads test_writer_model from plan.md frontmatter" {
  # Either reads plan.test_writer_model (with sonnet fallback) or pins literal sonnet.
  grep -E 'subagent_type: "qrspi-test-writer".*model: "(sonnet|<plan\.test_writer_model)' \
    skills/test/SKILL.md > /dev/null
}

@test "every reviewer Agent dispatch in skills/**/SKILL.md pins model" {
  # A reviewer dispatch line is a bullet item containing a backticked Agent({...}) call
  # whose subagent_type names a qrspi-*-reviewer / qrspi-*-hunter / qrspi-*-analyzer / qrspi-code-simplifier
  # agent. Every such line must carry model: somewhere on the same line.
  local offenders
  offenders=$(grep -rE '`Agent\(\{[^`]*subagent_type: "qrspi-([a-z-]+-reviewer|silent-failure-hunter|type-design-analyzer|code-simplifier)"' \
    skills/ \
    | grep -v 'model:' \
    || true)
  if [ -n "$offenders" ]; then
    echo "reviewer dispatches missing explicit model:"
    echo "$offenders"
    return 1
  fi
}
