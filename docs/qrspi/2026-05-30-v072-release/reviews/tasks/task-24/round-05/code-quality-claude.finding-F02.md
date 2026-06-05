---
finding_id: F02
severity: low
change_type: style
referenced_files: [tests/unit/test-detect-interaction-mode.bats]
---
Section headers use reviewer-artifact labels (`# FINDING A` … `# FINDING E`, lines ~524-602) instead of reader-oriented descriptors. A reader of the test file in isolation cannot decode "FINDING A". The descriptive subtitle after the em-dash is sufficient; the `FINDING X —` prefix embeds an ephemeral review-round reference into source. CONVERGENT with code-quality-codex section-header finding. Comment-only cleanliness.
