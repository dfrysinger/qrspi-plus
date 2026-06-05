---
finding_id: R1-F01
reviewer_tag: code-quality-codex
round: 1
task: 6
severity: medium
change_type: clarity
referenced_files:
  - agents/qrspi-finding-verifier.md
  - tests/unit/test-verifier-agent-file.bats
---

# F01 — QRSPI internal IDs (G11) leaked into agent prompt + test names

## Locations

- `agents/qrspi-finding-verifier.md:36` — production agent prompt text contains "(G11 — `.score.md` extension locked; no `.yml` alternative is accepted)"
- `tests/unit/test-verifier-agent-file.bats:56` — comment header "G11 sidecar-extension lock tests"
- `tests/unit/test-verifier-agent-file.bats:58` — `@test "G11: .score.yml is absent from verifier agent body..."`
- `tests/unit/test-verifier-agent-file.bats:62` — failure-message string `"verifier agent body still references .score.yml — must be removed (G11)"`
- `tests/unit/test-verifier-agent-file.bats:65` — `@test "G11: sidecar path uses exactly .score.md extension..."`
- `tests/unit/test-verifier-agent-file.bats:69` — failure-message `"...canonical .score.md sidecar path (G11)"`
- `tests/unit/test-verifier-agent-file.bats:72` — `@test "G11: sidecar frontmatter requires score: as integer 0-100"`
- `tests/unit/test-verifier-agent-file.bats:77` — failure-message `"...score: integer 0-100 in sidecar frontmatter (G11)"`
- `tests/unit/test-verifier-agent-file.bats:80` — `@test "G11: chat-side score output is labeled non-load-bearing telemetry"`
- `tests/unit/test-verifier-agent-file.bats:84` — failure-message `"...non-load-bearing telemetry (G11)"`
- `tests/unit/test-verifier-agent-file.bats:87` — `@test "G11: disk sidecar is the canonical fan-in input..."`
- `tests/unit/test-verifier-agent-file.bats:91` — failure-message `"...canonical fan-in input (G11)"`
- `tests/unit/test-verifier-agent-file.bats:94` — `@test "G11: wrong-extension sidecar references are rejected..."`
- `tests/unit/test-verifier-agent-file.bats:100` — failure-message `"....score.md extension is locked with no fallback (G11)"`

## Observation

`G11` is a QRSPI run-specific goal-tracker token (per goals.md). Per ID hygiene rules, internal IDs MUST NOT appear outside `docs/qrspi/` tracker files. Both the production agent file (which is loaded into every reviewer/verifier dispatch) and the test files (which run on every CI build long after this release ships) are forbidden surfaces.

The agent file leak is the most significant: `agents/qrspi-finding-verifier.md` is consumed verbatim by reviewer subagents at every dispatch. Carrying a stale "(G11 — ...)" parenthetical bloats every verifier prompt indefinitely and refers to a tracker concept that means nothing to the verifier agent at runtime.

The test name and failure-message leaks are lower-severity but still violate the convention — test failures in CI will show "G11" tokens that have no meaning to anyone reading them six months later.

## Fix

Replace every `G11` occurrence with descriptive text. Suggested rewrites:

**Agent file (line 36):**
- Before: `... \`.md\` → \`.score.md\` (G11 — \`.score.md\` extension locked; no \`.yml\` alternative is accepted). Example: ...`
- After:  `... \`.md\` → \`.score.md\` (sidecar extension is locked to \`.score.md\`; no \`.yml\` alternative is accepted). Example: ...`

**Test file:**
- Comment header: `# ── sidecar-extension lock tests ──`
- Test names: `@test "sidecar-extension lock: .score.yml is absent..."`, `@test "sidecar-extension lock: canonical path uses .score.md"`, `@test "sidecar contract: frontmatter requires score: integer 0-100"`, `@test "sidecar contract: chat-side score labeled non-load-bearing telemetry"`, `@test "sidecar contract: disk sidecar is canonical fan-in input"`, `@test "sidecar-extension lock: wrong-extension references rejected"`
- Failure messages: strip the trailing `(G11)` parenthetical and rephrase if context loss occurs (e.g., `"...canonical .score.md sidecar path"`).

## Severity rationale

Medium: production agent file leak is load-bearing (every verifier dispatch carries the token). Test leak is cosmetic but multiplies across 6 test names. Both are easy to fix and the wrong-channel-output failure mode the task aims to prevent is unrelated to the ID hygiene fix.
