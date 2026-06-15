# fix-FX2: lint corpus violations — [T01]/[T11]/[T19-ban] tokens

## Source
Test phase round-01: test-g2-bats-id-hygiene #1 — corpus sweep finds forbidden tokens previously masked by bash-4-only globstar.

## Divergence
plan G2 requires the bats corpus to be free of internal-ID tokens like `[Tnn]`. The new g2 acceptance test uses bash-3.2 portable `find … | xargs grep` and surfaces real hits in:
- `tests/unit/test-check-bats-id-hygiene-sweep.bats:40,58` — `[T01]` / `[T11]` inside heredoc-embedded diff fixtures
- `tests/unit/test-bash32-runtime-coverage.bats:182` — `[T19-ban]` inside a printf body

## Fix
Choose the cheapest fidelity-preserving fix per file. For the heredoc fixtures: runtime-assemble the token (see `test-g2-bats-id-hygiene.bats` lines 51-55 `open_bracket=…/close_bracket=…` pattern) so the literal `[Txx]` never appears at column 0 in the script source. For the printf body: same approach OR add the `# bats lint:no-id-hygiene` carve-out marker if the line construction shape supports it.

## Out of scope
- Do NOT change the lint regex anchor (anchoring to `^@test` would let real violations sneak through in fixture-construction lines).
