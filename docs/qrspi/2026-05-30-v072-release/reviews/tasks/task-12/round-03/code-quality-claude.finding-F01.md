---
finding_id: R3-F01
reviewer_tag: code-quality-claude
round: 3
task: 12
severity: low
change_type: clarity
referenced_files:
  - scripts/await-round.sh
  - scripts/round-prepare.sh
  - tests/unit/test-await-round.bats
  - tests/unit/test-round-prepare.bats
---

# F01 — QRSPI-internal review-finding IDs leaked into production code and tests

## Locations

- `scripts/await-round.sh:30` — `# Trust boundary (R2 hardening — security-claude R2-F01/F02):`
- `scripts/await-round.sh:97` — same phrase in Python block comment
- `scripts/round-prepare.sh:68` — `# Trust-boundary input validation (R2 hardening — security-claude R2-F03).`
- `scripts/round-prepare.sh:161` — inline `# Input validation above (… R2-F03) already closes …`
- `scripts/round-prepare.sh:204` — `# `--` separates … (defense in depth — R2-F03).`
- `tests/unit/test-await-round.bats:262` — section header `# ── Command-injection guards (R2 security-claude R2-F01/F02) ─────────`
- `tests/unit/test-round-prepare.bats:505` — `# R2 silent-failure-claude R2-F01: prove the failure surface is attributable …`
- `tests/unit/test-round-prepare.bats:507` — `# ── Option-injection guards (R2 security-claude R2-F03) ──────`

## Observation

The tokens `R2`, `R2-F01`, `R2-F02`, `R2-F03` match the QRSPI-internal ID pattern `\b[GRDFTQ]-?[0-9]+[A-Za-z]?\b` (R and F are in the flagged prefix set). These are run-specific reviewer-finding references copied from the task spec / reviewer output into production scripts and bats test section comments. The ID hygiene rule prohibits these from appearing in code comments, test names, and section headers outside `docs/qrspi/`. None of these files are under `docs/qrspi/`.

## Suggestion

Replace each occurrence with a self-describing WHY comment that captures the intent without the tracking token. Example: `# Shell injection hardening: manifest fields await_cmd / split_cmd are read verbatim from disk and MUST NOT be passed to a shell. Parse via shlex, exec with shell=False.` Section header → `# ── Command-injection regression guards ──`.
