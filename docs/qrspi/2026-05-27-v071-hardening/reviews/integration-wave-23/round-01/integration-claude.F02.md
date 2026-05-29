---
finding_id: int-claude-r01-f02
severity: low
change_type: refactor
referenced_files:
  - tests/acceptance/v07-phase1/test-phase1-acceptance.bats:976-1022
artifact: integration-wave-23
round: 1
reviewer: integration-claude
---

# F02 — TE12 self-description drift after T7 mismatch-decoupling

TE12's self-description "non-zero transport exit propagates unchanged on the correctly-routed Codex-available path (no suppression)" no longer matches the scenario the test actually exercises after T7.

TE12's setup (`test-phase1-acceptance.bats:986-1011`):
- `COPILOT_CLI` unset → `_detected_host=claude-code`
- companion-glob populated in `MOCK_HOME` → `_codex_available=true`
- `_t7_make_mock_repo` writes default `codex_reviews: false` and TE12 does NOT override it → `_codex_reviews=false`

Under T7's decoupled mismatch policy (`scripts/run-codex-review.sh:622-624`), `_codex_available=true` ≠ `_codex_reviews=false` triggers the `[mismatch]` warning unconditionally before dispatch. So TE12 is in fact exercising the mismatch path, not the "correctly-routed" path its comment describes.

The test still proves its load-bearing assertion (exit 42 propagates from the mock transport), and it intentionally exercises the no-short-circuit branch (since `codex_reviews=false` skips the codex-unavailable short-circuit on line 632). But the self-description is now misleading, and the test's coverage overlaps with TE13 (which explicitly exercises the mismatch+propagation case).

**Suggested fix:** add `printf -- '---\ncodex_reviews: true\n---\n' > "$tmp/artifact-dir/config.md"` after line 988 (mirroring TE5/TE7/TE9b/TE10's pattern) so avail=true+config=true aligns with the "correctly-routed Codex-available" intent and the mismatch warning doesn't fire in this scenario. Preserves the exit-propagation assertion while restoring scenario fidelity, and re-establishes TE12 vs TE13 as discriminating non-overlapping cases.
