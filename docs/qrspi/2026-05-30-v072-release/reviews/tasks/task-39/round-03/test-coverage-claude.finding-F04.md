---
reviewer: test-coverage-claude
finding_id: F04
severity: low
change_type: correctness
references:
  - tools/build-plugin.mjs#L83-L85
  - tools/build-plugin.mjs#L313
  - tests/acceptance/v07-phase1/test-cache-retirement-invariants.bats
---

# F04 — `MANIFEST_PATH_EXCLUSIONS` (marketplace.json self-reference) and required-asset-missing diagnostics have no negative-path tests

## Observation

Two production-code branches with semantic load:

### A. `MANIFEST_PATH_EXCLUSIONS` (tools/build-plugin.mjs L83–85, L313)

```js
const MANIFEST_PATH_EXCLUSIONS = new Set([
  path.join('.claude-plugin', 'marketplace.json'),
]);
```

Used at L313: `if (MANIFEST_PATH_EXCLUSIONS.has(rel)) continue;`

The acceptance suite asserts `build/.claude-plugin/plugin.json` exists
(L271 of test-cache-retirement-invariants.bats) but never asserts the
inverse: that `build/.claude-plugin/marketplace.json` is **absent**.
The production code's stated rationale ("shipping it inside
`build/.claude-plugin/` would self-reference") is a real correctness
property — if the exclusion set ever drops marketplace.json, the build
ships a stale copy of the registry pointing at itself.

### B. Required-file/dir missing diagnostic (L382–384, L406–408)

```js
throw new BuildError(
  `manifest: required directory missing from source root: ${dir.rel}`,
);
```

The fixture helper `_t39_stage_root` always stages every required path
(`skills/`, `.claude-plugin/`, `LICENSE`, `README.md`), so the
"required missing" branch is never exercised. The same applies to
the "expected directory but found non-directory" guard (L391–394) and
its file twin (L414–417).

## Impact

- A future commit that drops marketplace.json from the exclusion set
  ships a `build/.claude-plugin/marketplace.json` that points at
  `./build` from inside `./build` — a cycle that breaks Claude
  marketplace registration.
- A regression that swallows the required-missing error (e.g., changes
  `if (dir.required)` to `if (false)`) ships an empty/partial build
  silently. No test catches it.

## Suggested remediation

```bats
@test "[T39/G32] build/.claude-plugin/marketplace.json is NOT shipped (self-reference exclusion)" {
  [ -f "$REPO_ROOT/build/.claude-plugin/plugin.json" ]
  [ ! -e "$REPO_ROOT/build/.claude-plugin/marketplace.json" ]
}

@test "[T39/G32] fail-loud: missing required manifest directory (skills/) is reported" {
  local root="$BATS_TEST_TMPDIR/no-skills"
  mkdir -p "$root/.claude-plugin"
  printf '{"name":"x","version":"0.0.0"}\n' >"$root/.claude-plugin/plugin.json"
  : >"$root/LICENSE"; : >"$root/README.md"
  run _t39_run_build "$root"
  [ "$status" -ne 0 ]
  echo "$output" | grep -F 'skills'
  echo "$output" | grep -E -i 'required|missing'
}

@test "[T39/G32] fail-loud: missing required manifest file (LICENSE) is reported" {
  local root="$BATS_TEST_TMPDIR/no-license"
  _t39_stage_root "$root" "# x"$'\n'
  rm -f "$root/LICENSE"
  run _t39_run_build "$root"
  [ "$status" -ne 0 ]
  echo "$output" | grep -F 'LICENSE'
  echo "$output" | grep -E -i 'required|missing'
}
```
