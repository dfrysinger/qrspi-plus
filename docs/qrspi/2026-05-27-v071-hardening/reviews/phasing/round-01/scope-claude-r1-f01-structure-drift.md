---
finding_id: R1-F01
severity: medium
change_type: boundary-drift
referenced_files: [docs/qrspi/2026-05-27-v071-hardening/phasing.md]
artifact: phasing
round: 1
reviewer: scope-claude
defers_to: structure
---

Every slice body and multiple replan-gate criteria name concrete file paths and/or function/variable/key names. The DEFERS rule is explicit: "File paths, module boundaries, interface contracts, file maps -> owned by Structure. Phasing names slices and phases; it does NOT enumerate files or function signatures." Phasing prose should identify deliverable boundaries by human-readable slice name, not by filesystem path or interface identifier.

Instances (pervasive across all 8 slices):

- Slice 1: `scripts/run-third-party-llm.sh`
- Slice 2: `.gitignore`, `.qrspi-commit-msg.txt`, `git add -A`
- Slice 3: `tests/helpers/skill-markdown.bash`, `tests/unit/test-skill-md-content-patterns.bats`, function name `extract_section_fence_aware`
- Slice 4: `skills/parallelize/SKILL.md`
- Slice 5: `tests/unit/test-evergreen-markdown.bats`, function name `_is_path_exempt()`, inline comment syntax `<!-- evergreen-exempt -->`
- Slice 6: `skills/using-qrspi/SKILL.md`, env-var interface contract `COPILOT_CLI=1`
- Slice 7: `skills/using-qrspi/SKILL.md`, `scripts/run-third-party-llm.sh`
- Slice 8: `agents/*.md`, `config.md`, config key name `model_routing:`
- Replan criteria 3-5: `tests/unit/test-evergreen-markdown.bats`, `_is_path_exempt()`, `scripts/run-third-party-llm.sh`, `.qrspi-commit-msg.txt`

Recommended fix: Replace file paths and interface names with slice-scoped natural-language descriptions (e.g., "the control-char detection shell script" rather than `scripts/run-third-party-llm.sh`; "the shared test helper" rather than the full path). Paths and function names belong in the Structure file-map artifact.

(Materialized from inline subagent return; Claude scope-reviewer environment does not write to disk.)
