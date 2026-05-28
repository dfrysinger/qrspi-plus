---
finding_id: R1-F01
severity: medium
change_type: scope
referenced_files: [docs/qrspi/2026-05-17-v07-release/plan.md:L174, docs/qrspi/2026-05-17-v07-release/plan.md:L458]
artifact: plan
round: 1
reviewer: scope-claude
---

Task descriptions for T02 and T13 encode verbatim function signatures with parameter shapes — content the OWNS/DEFERS rule explicitly defers to structure.md.

T02 (line 174): "The library exposes three named functions per the structure.md interface contract: `strip_frontmatter <file>` writes the file body…; `guard_marker_injection <file>` exits 0 when no untrusted-data marker collision…; `emit_dispatch_parameters <kv-list>` writes the canonical dispatch-parameter block…"

T13 (line 458): "The helper at `tests/helpers/skill-markdown.bash` exposes four functions per the structure.md Interfaces contract: `extract_section <file> <heading_level> <heading_text>` returns lines between…; `extract_and_grep <file> <heading_level> <heading_text> <regex>` chains extract plus grep…; `assert_section_contains <file> <heading_level> <heading_text> <regex>` is a BATS-shaped wrapper…; `require_repo_root` resolves `REPO_ROOT` from `BATS_TEST_DIRNAME` plus `git rev-parse --show-toplevel`…"

Per the OWNS/DEFERS rule, "Function signatures, type definitions, parameter shapes → structure.md (interface contracts per file are Structure's OWNS, not Plan's)." Both descriptions reproduce the full named-function + parenthesized-parameter-list signatures for each public entry point — these are contracts the INVEST Negotiable framing says Plan must not pre-empt. The fact that both descriptions acknowledge citing the "structure.md interface contract" confirms the author knew these details live in structure.md; reproducing them here creates a redundant second source of truth that can drift.

The corresponding test expectations (which enumerate the same named functions by name as behavioral targets rather than as parameter-shape contracts) are acceptable Plan OWNS content — they describe observable behaviors, not parameter shapes.

Resolution: trim each Description to the behavioral claim only. For T02: "Creates a sourced bash library carrying the prompt-composition utilities…exposing three helpers for prompt assembly that the universal dispatcher and the retired shim source." For T13: "Authors the shared BATS helper library…exposing section-extraction, assertion, and repo-root-resolution helpers." The named-function signatures and parameter lists should remain exclusively in structure.md.
