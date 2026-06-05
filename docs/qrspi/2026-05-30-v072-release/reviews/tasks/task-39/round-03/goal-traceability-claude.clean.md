# Goal Traceability Review — Task 39, Round 3 — CLEAN

Subject: tools/build-plugin.mjs, .github/workflows/ci.yml, CONTRIBUTING.md
Goal: G32 (plugin build pipeline)
Task spec: tasks/task-39.md (goal_ids: [G32])

## Forward trace (G32 → task spec → tests → impl)

Every DoD bullet and Test Expectation in task-39.md traces to a concrete
implementation site:

| DoD / Test Expectation | Implementation site |
|---|---|
| Reproducible `build/` from manifest + fixed include list | build-plugin.mjs:65–79 (MANIFEST_DIRS / MANIFEST_FILES) |
| D3 strict whole-line bare-relative grammar | build-plugin.mjs:117–119 (CAT_STRICT_RE / RELPATH_TOKEN_RE) |
| Transitive expansion, cycle detection, CR strip, idempotence | build-plugin.mjs:189–247 (expand()) |
| Fail-loud: malformed / missing / cycle / abs / traversal / outside-root | build-plugin.mjs:145–177 (resolveTarget) + 218–227 (malformed/token) + 190–198 (cycle/depth) |
| Fail-loud on `${CLAUDE_SKILL_DIR}` in shipped files (.md and non-.md) | build-plugin.mjs:251–259 (assertNoClaudeSkillDir) + 441–458 (final tree pass) |
| Symlink-escape closure mirroring T21 with `resolves outside repository` phrase | build-plugin.mjs:159–175 (resolveTarget), 264–284 (copyFilePreservingMode), 345–361 (.md pre-flight in recurseDir) |
| marketplace.json points to `./build` + v0.7.2 metadata | round-03.diff lines 9–12 |
| Single CI workflow: builder + diff gate, recursive BATS, no auto-commit | ci.yml:112–133 |
| CONTRIBUTING: edit→build→add→commit→push, two PR-blocking modes, committed-`build/` rationale, scripts/ vs tools/ split | CONTRIBUTING.md diff lines 102–188 |

## Backward trace (impl → spec → goal)

Every public behavior in build-plugin.mjs maps to a DoD bullet or Test
Expectation. The defense-in-depth additions (MAX_INCLUDE_DEPTH=8,
MAX_EXPAND_BYTES=4MB, SECRET_BASENAME_PATTERNS) extend "fail-loud" plus
the symlink/billion-laughs DoS mitigation surface and trace to the prior
rounds' security/silent-failure remediation. They support — not exceed
— G32's mandate of "fail non-zero with file:line plus reason." No YAGNI
signal.

## Gap analysis

No uncovered acceptance criteria for this task. The symlink-escape
regression — the most security-load-bearing Test Expectation — is
satisfied by realpathSync canonicalization at every shipped-file
ingress point with the exact `resolves outside repository` diagnostic
phrase the task spec mandates (mirrors T21's
`assert_path_under_repo_root`).

## Spec-to-test fidelity

Strict resolver regex matches the documented grammar
`^[[:space:]]*!cat[[:space:]]+<relpath>[[:space:]]*$`. Diagnostic
phrasing matches T21's audit-friendly phrase as required by the DoD's
final bullet.

No findings.
