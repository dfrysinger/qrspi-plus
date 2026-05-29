---
finding: F02
reviewer: sec-claude
round: 2
task: 6
severity: low
change_type: correctness
file: scripts/run-codex-review.sh
lines: [125]
---

# Unvalidated `HOME` in companion-glob enables false availability signal and filesystem probing

## Summary

`check_codex_available` builds a glob path directly from `${HOME}` without
normalizing or validating it (line 125).  Any caller who controls `HOME`
can make the availability check return a false positive — or probe for
file existence at an arbitrary filesystem path — by supplying a crafted
`HOME` value.

## Vulnerable code

```bash
# line 125  scripts/run-codex-review.sh
for f in "${HOME}/.claude/plugins/cache/openai-codex/codex"/*/scripts/codex-companion.mjs; do
  if [[ -f "$f" ]]; then
    found=1
    break
  fi
done
```

`HOME` is taken verbatim from the environment with no length, character,
or path-normalization checks.

## Concrete attack scenario — false availability signal

The companion-glob probe is the production gate that decides whether
Codex dispatch proceeds under `claude-code`.  A caller plants a fake
companion file tree under a directory they control, then overrides `HOME`
when invoking the script:

```sh
mkdir -p /tmp/attacker/.claude/plugins/cache/openai-codex/codex/v1.0/scripts
touch /tmp/attacker/.claude/plugins/cache/openai-codex/codex/v1.0/scripts/codex-companion.mjs

HOME=/tmp/attacker bash scripts/run-codex-review.sh \
  --agent-file agents/... --reviewer-tag ... ...
```

`check_codex_available claude-code` returns 0 because the glob resolves
to the stub file.  The script proceeds to dispatch as if a real Codex
companion were installed.  The downstream dispatcher then runs with no
real Codex backend, and any result it produces is fabricated.

This is especially relevant in CI environments where `HOME` is
user-configurable per-job (e.g., GitHub Actions `env:` block, Dockerfile
`ENV HOME`).

## Concrete attack scenario — filesystem existence probe

By setting `HOME` to a relative path with `..` components, the caller
can learn whether a file exists at an arbitrary location:

```sh
HOME=/var/run/secrets bash scripts/run-codex-review.sh ...
# → probes /var/run/secrets/.claude/.../codex-companion.mjs
# absence → exit 1 (probed, no match);  if something matches → exit 0
```

Even with no write access the attacker gains a boolean oracle for
file-existence at paths outside the expected `~/.claude/` tree.

## Why it matters

The test suite itself exploits this property intentionally —
line 417 in `test-host-detection.bats` passes `HOME="$MOCK_HOME"` into
the subshell to control probe outcomes.  The same mechanism is available
to any real caller.  The probe is designed to gate production dispatch;
making it trivially bypassable weakens the availability contract.

## Recommended fix

Add a guard before the glob expansion that rejects a `HOME` value
containing `..` path components or that does not resolve to an absolute
path under the real user's home directory:

```bash
check_codex_available() {
  local host="${1:-}"
  case "$host" in
    claude-code)
      # Reject obviously unsafe HOME values before probing.
      case "${HOME:-}" in
        *..* | "" | *$'\n'*)
          echo "check_codex_available: unsafe HOME value" >&2
          return 1
          ;;
      esac
      ...
```

Alternatively, resolve `HOME` to a canonical absolute path with
`realpath` (or `cd "$HOME" && pwd -P`) and reject if it doesn't start
with `/`.
