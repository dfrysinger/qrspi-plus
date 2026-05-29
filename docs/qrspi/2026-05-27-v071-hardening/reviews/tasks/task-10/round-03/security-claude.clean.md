# Security review — Task 10 Round 03 — CLEAN

**Reviewer:** security-claude
**Round:** 03
**Verdict:** clean (no findings)

## Scope reviewed

Diff: `docs/qrspi/2026-05-27-v071-hardening/reviews/tasks/task-10/round-03.diff`

Files in diff:
- `skills/using-qrspi/SKILL.md` — +2 prose lines (new fail-loud paragraph under `#### \`model_routing:\` block`); 1-line edit to `trusted_path:` bullet replacing a broken cross-reference with the correct frontmatter source-of-truth.
- `skills/using-qrspi/SKILL.anchors.json` — mechanical regen; every `line_start`/`line_end` downstream of the insertion point bumped by +2. Math checks out.
- `tests/unit/test-config-model-routing.bats` — test name + assertion updated from legacy "role lookup" wording to current "host/tier lookup" schema wording.
- `tests/unit/test-using-qrspi-vocab.bats` — new `_extract_h4` helper (mirrors sibling test file), `USING` alias export, two new pins on the fail-loud contract (one affirmative, one anti-pattern-absence regression pin).

## Security concern resolution

### 1. Fail-loud paragraph closes G7b/#204 silent-fallback surface
The new paragraph (SKILL.md line ~470 in post-edit file) enumerates all three structural failure modes of the host→tier→model schema (unmatched host key, unmatched tier / unresolved `inherit`, bare short-form value) and binds each to a hard halt with explicit error reporting. Critically, it forecloses **both** silent-fallback paths — the agent-bundled default *and* the host CLI's silent re-routing — naming each explicitly. No "unless", no "best-effort", no escape hatch. The vocab tests at lines 237–258 of the bats file pin the affirmative ("halts and reports", "never falls back silently") and the absence of the historical anti-pattern wording ("silently fall back to the agent-bundled default", "silently degrade"), so a future softening edit RED-fails at the test layer before reaching review.

### 2. `trusted_path:` bullet preserves safety-critical short-circuit
The bullet repair replaces a structurally-impossible cross-reference ("matches entries in `model_routing:`" — but the host-keyed schema has no role-keyed entries to match) with the correct source-of-truth: the agent frontmatter's `model_role:` value, declared independent of `model_routing:`'s structure. The surrounding sentences ("short-circuit ahead of the normal routing chain", "bypass the chain entirely") are untouched, so the safety-critical guarantee — that finding-verifier, security-reviewer, and other trusted-path agents always route to their agent-bundled default and cannot be silently downgraded by `model_routing:` substitution — is preserved. The repair strengthens the contract by making the matching key well-defined.

### 3. No auth / secrets / command-injection / path-traversal surface touched
As expected — diff is exclusively documentation prose + mechanical anchor regen + bats test pins. The new `_extract_h4` awk helper operates on `$USING_QRSPI_SKILL` (repo-internal path derived from `$REPO_ROOT`), with no untrusted input and no shell interpolation. Pattern mirrors the existing helper in `test-config-model-routing.bats`.

No further review required for this round.
