---
finding_id: R1-F03
reviewer_tag: security-codex
round: 1
task: 6
severity: medium
change_type: correctness
referenced_files:
  - agents/qrspi-finding-verifier.md
  - tests/unit/test-verifier-agent-file.bats
---

# F03 — Path-confusion hardening incomplete for `<reviewer-tag>` path component

## Location

- `agents/qrspi-finding-verifier.md:36` — canonical sidecar shape includes `<reviewer-tag>` in the filename, but no charset constraints are defined for what makes a valid tag
- `tests/unit/test-verifier-agent-file.bats:65–69` — tests only assert loose regex presence of the canonical path shape, not that the tag is path-safe

## Attack scenario

If an attacker can influence reviewer tag upstream (via config, env var, or input injection), a tag like:

```
evil/../../.git/hooks/post-commit
```

When interpolated into the sidecar filename pattern `<reviewer-tag>.finding-F<NN>.score.md`, the resulting path:

```
<round-dir>/evil/../../.git/hooks/post-commit.finding-F01.score.md
```

After path normalization, escapes the round directory entirely and could overwrite arbitrary files when the verifier writes the sidecar.

## Threat model

Reviewer tags currently flow from orchestrator dispatch parameters (typically literal strings like `spec-claude`). The orchestrator is trusted in v0.7.2. But the contract layer (agent file) defines the path pattern WITHOUT a charset constraint — if a future change exposes tag generation to less-trusted input (e.g., parsing from manifest JSON, env vars, or user-supplied review config), the path-traversal becomes exploitable. Contract-layer hardening is the right place to close this, regardless of current trust boundary.

## Scope note

T06 added `.score.md` extension lock but did not add tag charset validation. The fix is a small extension to T06's existing sidecar-extension lock work — same surface (agent contract + test file) — and arguably should ship together since both close the "verifier sidecar path attack surface."

## Suggested remediation

Add to the verifier agent contract:

> `<reviewer-tag>` MUST match the regex `^[a-z0-9][a-z0-9-]{0,63}$` (lowercase alphanumeric and hyphen, 1–64 chars, must start with alphanumeric). Tags failing this constraint MUST cause the verifier to halt with diagnostic `"invalid-reviewer-tag: <tag>"` before attempting any filesystem operation. The orchestrator MUST validate tags before dispatching the verifier (defense in depth).

Add to `tests/unit/test-verifier-agent-file.bats`:

```bash
@test "sidecar-tag contract: reviewer-tag charset is restricted" {
  local body
  body=$(awk '/^---$/{n++; next} n>=2{print}' agents/qrspi-finding-verifier.md)
  echo "$body" | grep -qE '<reviewer-tag>.*regex.*\^.*\[a-z0-9.*\]' \
    || { echo "verifier agent missing reviewer-tag charset constraint"; return 1; }
}
```

## Severity rationale

Medium: not exploitable in v0.7.2 (orchestrator controls tags), but the contract layer has the gap and a single careless future change opens the attack surface. Defense in depth at the contract boundary is cheap and correct.
