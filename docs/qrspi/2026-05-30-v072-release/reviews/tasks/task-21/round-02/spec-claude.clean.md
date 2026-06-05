---
reviewer: spec-claude
round: 2
verdict: clean
---

# Spec Review — Task 21 Round 2: CLEAN

Round-02 fixes both spec-codex findings from round-01. All spec requirements and
test expectations verified.

## F01 Fix Verified (spec line 50 — "before prompt emission")

`tests/unit/test-dispatch-agent.bats` lines 1539-1543 now add two absence assertions
to the symlink-outside-repo test:

```bash
[[ ! "$output" =~ "<<<AGENT-BODY-END>>>" ]]
[[ ! "$output" =~ "<<<UNTRUSTED-ARTIFACT-START" ]]
```

These prove rejection fires before `compose_prompt()` emits any prompt content.
The ordering in `scripts/dispatch-agent.sh` confirms this: all `assert_path_under_repo_root`
calls (lines 894, 943, 951, 960, 970) execute before `compose_prompt()` is invoked
at line 1102.

## F02 Fix Verified (spec line 54 — "no raw path read before checks pass")

`tests/unit/test-dispatch-agent.bats` lines 1553-1568 now write a unique sentinel
string into the subject file and assert `[[ ! "$output" =~ "$sentinel" ]]`. Since
`emit_untrusted_artifact` (the only `cat` call for user-supplied paths) is inside
`compose_prompt()` which runs after all guards, a failing REPO_ROOT ensures no file
bytes are read before exit. The test correctly captures this invariant.

## Full Spec Checklist

| Requirement | Location | Status |
|---|---|---|
| `assert_path_under_repo_root` guard in `dispatch-agent.sh` | `scripts/lib/path-guard.sh` sourced; called at dispatch-agent.sh:894, 943, 951, 960, 970 | ✓ |
| Guard fires after existence check and before cat/prompt emission | ordering: assert_file_exists → assert_path_under_repo_root → compose_prompt (line 1102) | ✓ |
| `resolves outside repository` diagnostic on stderr | path-guard.sh:93 | ✓ |
| Symlinks whose canonical target is outside repo rejected | path-guard.sh uses `realpath`; trailing-slash prefix match | ✓ |
| Canonicalization failures fail closed | path-guard.sh:71-86 | ✓ |
| All four path families guarded (`--subject-code`, `--artifact-body`, `--companion`, `--diff-file`) | dispatch-agent.sh:943, 943, 960, 970 | ✓ |
| `agents/qrspi-implementer.md` Orchestrator-Only Scripts section | agents/qrspi-implementer.md diff lines 9-45; covers relative/absolute/alias/shell-expansion shapes, both post-rename script names | ✓ |
| `dispatch-companion.sh` audited / guard shared for `--prompt-file` | dispatch-companion.sh sources path-guard.sh; `assert_path_under_repo_root` called for launch:--prompt-file; stdin-only surface documented as no-raw-path | ✓ |
| Regression: `/etc/hosts` rejected | test-dispatch-agent.bats:1466 | ✓ |
| Regression: symlink-outside-repo rejected before emission | test-dispatch-agent.bats:1523-1543 | ✓ |
| Regression: readable out-of-repo companion rejected by boundary | test-dispatch-agent.bats:1490-1505 | ✓ |
| Table coverage: all four families have rejection tests | tests at lines 1453, 1477, 1490, 1507 | ✓ |
| Valid repo-local pass cases for all four | test-dispatch-agent.bats:1573-1601 | ✓ |
| Canonicalization failure: sentinel absent from output | test-dispatch-agent.bats:1547-1569 | ✓ |
| Structural grep: implementer allowlist section | test-dispatch-agent.bats:1609-1620 | ✓ |
| Audit inspection: companion guard or documented comment | test-dispatch-agent.bats:1622-1631 | ✓ |

## Target Files Check

All modified files are in the spec's Target files list or are necessary auxiliaries:
- `scripts/dispatch-agent.sh` ✓ (Target)
- `scripts/lib/path-guard.sh` ✓ (new shared lib — necessary per spec's "single fail-closed guard" requirement)
- `agents/qrspi-implementer.md` ✓ (Target)
- `scripts/dispatch-companion.sh` ✓ (Target)
- `tests/unit/test-dispatch-agent.bats` ✓ (Target)
- `tests/unit/test-dispatch-sites.bats` — not listed as Target, but changes are limited to `mktemp -d "$(pwd)/.bats-tmp.XXXXXX"` substitutions necessary to keep existing tests compatible with the new repo-boundary guard; no new behavior added

No out-of-scope additions found.
