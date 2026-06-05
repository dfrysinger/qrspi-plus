---
finding_id: R2-F01
reviewer_tag: security-codex
round: 2
task: 3
severity: medium
change_type: correctness
referenced_files:
  - skills/reviewer-protocol/SKILL.md
  - skills/reviewer-protocol/first-party-emission.md
  - skills/reviewer-protocol/third-party-emission.md
---

# F01 — Unconstrained `<reviewer_tag>` can enable path traversal outside `<round_subdir>`

## Location

- `skills/reviewer-protocol/SKILL.md:45` (dispatch contract)
- `skills/reviewer-protocol/first-party-emission.md:70–77` (path rules)
- `skills/reviewer-protocol/third-party-emission.md:50–52` (splitter target paths)

## Issue

File paths are defined as `<round_subdir>/<reviewer_tag>.finding-F<NN>.md` and `<round_subdir>/<reviewer_tag>.clean.md`, but the contract has no charset, length, or path-traversal constraint on `<reviewer_tag>`. The dispatch contract treats `<reviewer_tag>` as dispatcher-supplied and path-forming, but never constrains it to a safe token like `^[a-z0-9-]+$`.

## Attack scenario

If an attacker can influence dispatch parameters — directly via a compromised orchestrator code path, indirectly via a config-parsing bug, or via a future feature that reads tags from less-trusted input (e.g., manifest JSON, env vars, user-supplied review config) — they can set:

```
reviewer_tag = "../../outside"
```

Then `<round_subdir>/../../outside.finding-F01.md` resolves outside the round directory. Depending on the surface:

- **First-party Write:** The reviewer subagent's Write tool writes the finding file outside the round dir, potentially into source tree, .git, hooks, or other sensitive locations.
- **Third-party splitter:** `third-party-finding-splitter.sh` materializes the per-finding files outside the round dir, with the same impact.

If the writer process has filesystem access to the target location, files can be planted or overwritten.

## Convergence with sibling findings

This is the same gap as `security-codex.finding-F03.md` in T06 R1 — but T06 deferred the fix because the reviewer-tag charset was deemed out-of-scope for the T06 sidecar-extension lock. **T03 directly owns the path-rules contract surface** (per its DoD: "path rules" sections in first-party-emission.md and third-party-emission.md), so the fix belongs HERE in this round if T03 takes it, OR in a coordinated v0.7.3 task that updates both the path-rules and the verifier sidecar contract.

## Suggested fix

Add to the path-rules sections of BOTH `first-party-emission.md` and `third-party-emission.md`:

```
<reviewer_tag> MUST match the regex ^[a-z0-9][a-z0-9-]{0,63}$ (lowercase
alphanumeric and hyphen, 1–64 chars, must start with alphanumeric).
Tags containing path separators (/, \), traversal tokens (.., .), or
any character outside the allowed charset MUST be rejected by the
dispatcher BEFORE any Write or splitter invocation. The orchestrator
MUST canonicalize the resolved per-finding path and assert it remains
under <round_subdir> after path normalization.
```

Add a corresponding bats test asserting the charset constraint appears in both emission contracts.

## Severity rationale

Medium: not exploitable in v0.7.2 (orchestrator controls tags as literal strings), but the contract layer has the gap and a single careless future change opens the attack surface. Defense-in-depth at the contract boundary is cheap and correct, especially since T03 directly owns the path-rules surface where the fix lands.
