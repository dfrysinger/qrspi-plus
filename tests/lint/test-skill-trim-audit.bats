#!/usr/bin/env bats
bats_require_minimum_version 1.5.0

# tests/lint/test-skill-trim-audit.bats
#
# G9 trim-audit: zero drift tokens (script-mechanic narrative restatements)
# across all active SKILL.md files. Concrete script names in process-step
# calls are fine — only narrative restatements of script mechanics are banned.
#
# Discovery: skills/*/SKILL.md excluding skills/_shared/ and .archive/.

setup() {
  REPO_ROOT="$(git -C "${BATS_TEST_DIRNAME}" rev-parse --show-toplevel)"
  export REPO_ROOT
}

_audit() {
  local pattern="$1" desc="$2"
  local hits
  hits="$(find "${REPO_ROOT}/skills" -name "SKILL.md" \
           ! -path "*/skills/_shared/*" ! -path "*/.archive/*" \
         | sort | xargs grep -En -- "${pattern}" 2>/dev/null || true)"
  if [ -n "$hits" ]; then
    printf 'G9: drift token "%s" (%s) found in active SKILL.md files:\n%s\n' \
      "${pattern}" "${desc}" "${hits}" >&2
    return 1
  fi
}

@test "[G9] jobId — zero matches in active SKILL.md files" {
  _audit 'jobId' 'async-job mechanics narrative'
}

@test "[G9] tmpfile — zero matches in active SKILL.md files" {
  _audit 'tmpfile' 'temp-file mechanics narrative'
}

@test "[G9] HEAD~1 — zero matches in active SKILL.md files" {
  _audit 'HEAD~1' 'git-history offset narrative'
}

@test "[G9] narrow.broaden — zero matches in active SKILL.md files" {
  _audit 'narrow\.broaden' 'scope-narrowing prose restatement'
}

@test "[G9] sidecar.*schema — zero matches in active SKILL.md files" {
  _audit 'sidecar.*schema' 'sidecar schema mechanics narrative'
}

@test "[G9] change_type:.*enum — zero matches in active SKILL.md files" {
  _audit 'change_type:.*enum' 'change-type enum narrative'
}

@test "[G9] verifier.*threshold — zero matches in active SKILL.md files" {
  _audit 'verifier.*threshold' 'verifier threshold mechanics narrative'
}

@test "[G9] third-party.*splitter — zero matches in active SKILL.md files" {
  _audit 'third-party.*splitter' 'third-party splitter narrative'
}
