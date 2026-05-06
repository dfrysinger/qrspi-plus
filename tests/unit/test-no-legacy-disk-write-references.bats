#!/usr/bin/env bats

# Grep guards for the deferred-reviewer migration cutover (#125).
# Asserts the post-cutover state: no agent or skill file references
# the legacy reviewer single-file `round-NN-{reviewer-tag}.md` path
# pattern, and `skills/reviewer-protocol/SKILL.md` carries no
# Reviewer-Tag Routing Table or Legacy Disk-Write Contract section.

@test "no agent or skill file references the legacy round-NN-{reviewer-tag}.md path pattern" {
  # The legacy pattern's reviewer-tag suffix is always `claude` or `codex`
  # (bare or role-prefixed). This regex skips non-reviewer artifacts like
  # round-NN-review.md, round-NN-results.md, round-NN-dispositions.md,
  # round-NN-verified.md, round-NN-verifier-disabled.md (kept by design).
  local offenders
  offenders=$(grep -rE 'round-NN-([a-z0-9-]+-)?(claude|codex)\.md' agents/ skills/ \
    || true)
  if [ -n "$offenders" ]; then
    echo "legacy reviewer single-file path references remain:"
    echo "$offenders"
    return 1
  fi
}

@test "reviewer-protocol skill carries no Legacy Disk-Write Contract section" {
  ! grep -qE '^## Legacy Disk-Write Contract' skills/reviewer-protocol/SKILL.md
}

@test "reviewer-protocol skill carries no Reviewer-Tag Routing Table" {
  ! grep -qE '^## Reviewer-Tag Routing Table' skills/reviewer-protocol/SKILL.md
}

@test "no skill or agent file references the legacy fixes filename" {
  local offenders
  offenders=$(grep -rnE 'round-[0-9N]+-fixes\.md' skills/ agents/ 2>/dev/null || true)
  if [ -n "$offenders" ]; then
    echo "legacy round-NN-fixes.md references remain:"
    echo "$offenders"
    return 1
  fi
}
