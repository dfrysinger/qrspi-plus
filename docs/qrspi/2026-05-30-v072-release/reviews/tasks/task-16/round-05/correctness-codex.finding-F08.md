---
finding_id: R5-F08
severity: medium
change_type: correctness
referenced_files: [tests/unit/test-config-model-routing.bats]
---
Resolver tests are prose/grep-only, not behavioral — the coverage-gap class that let F01 (and four prior partial-migration misses) slip through five spec-gate rounds. The `_resolve-lib.sh` tests (test-config-model-routing.bats:282-323) only `grep` the script SOURCE for keyword strings ("--tier-override", "default_tier", "none.*halt", etc.); they never source the library and EXECUTE `resolve_tier`/`resolve_model` against a config fixture, so real logic regressions (precedence bugs, the none-on-comment halt failure, malformed-row handling, injection) are untested. Source: cq-codex F3. Fix (test-only): add behavioral bats that source `_resolve-lib.sh` (QRSPI_SOURCE_ONLY=1) and assert runtime behavior: each precedence layer (override / agent tier: / default_tier: / hardcoded-medium-with-warning); none-halt against an `extra-low: none  # comment` fixture (exit!=0, F01 repro); unconfigured/absent-row halt; a normal commented row emits a clean value; invalid tier from override AND agent frontmatter AND default_tier halts; `tier: low # comment` normalizes-and-succeeds; missing CONFIG_MD fails distinctly; document the out-of-block shadow gap with an xfail/explicit-note test.
