---
finding_id: scope-codex-F02
severity: medium
change_type: scope
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/structure.md:594-601
  - docs/qrspi/2026-05-30-v072-release/structure.md:2687-2691
artifact: structure
round: 11
reviewer: scope-codex
---

Several test blocks go beyond Structure's "test file layout / behavior level" ownership into test assertion and fixture design. Examples include fabricated-citation fixture mechanics, exact `score: 0` / `reason: HALLUCINATED:` assertions, halt-matrix fixture coverage, grep-lint string exclusions, regex-family assertions, negative-test phrases, and `$body` guard mechanics. Structure may name the test files and one-line behavior coverage, but these detailed expectations are Plan/Implement-owned.

(Persisted by orchestrator from Codex chat-only return — see stored memory `copilot CLI task tool`.)
