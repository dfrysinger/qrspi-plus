---
reviewer: security-claude
task: 10
round: 1
verdict: clean
---

# Security review — Task 10 round 01 — CLEAN

No security findings. Analysis summary:

## Scope of this diff
Data + documentation + tests only:
- `docs/qrspi/2026-05-27-v071-hardening/config.md` — adds a `model_routing:`
  YAML block inside a fenced code block under a new `## Model routing (G7b / #204)`
  H2 (27 added lines).
- `skills/using-qrspi/SKILL.anchors.json` — mechanical line-number bumps for
  downstream anchors (no semantic change).
- `skills/using-qrspi/SKILL.md` — adds a `#### Model Routing` documentation
  subsection describing the two-step lookup (host column via `detect_host`,
  tier row via agent frontmatter).
- `tests/unit/test-agent-frontmatter-no-model.bats` — adds four awk/grep
  helpers (`_model_routing_block`, `_host_subblock`, `_assert_tier_maps_to`,
  `_markdown_section`) and seven test cases (TE1–TE7) covering the six
  required host/tier entries plus a meta-self-assertion fixture.

No production-code dispatcher in this round reads the table — the consuming
dispatcher is documented as prose in SKILL.md, not implemented as code.
The task spec explicitly frames this as data-wiring with the resolver
prose deferred to the dispatcher consumer.

## Category-by-category

### 1. Injection
- **Command injection in BATS helpers:** None. All helper inputs are either
  (a) repo-tracked file paths (`docs/qrspi/.../config.md`,
  `skills/using-qrspi/SKILL.md`) or (b) literal string constants baked into
  the test bodies (`claude-code`, `copilot-cli`, `haiku`, `sonnet`, `opus`,
  `inherit`, `Model Routing`, plus pre-escaped regex literals such as
  `claude-haiku-4\.5`). No attacker-controlled value reaches the
  `awk -v h="$host"` interpolation or the interpolated `grep -E` pattern in
  `_assert_tier_maps_to`. No `eval`, no `bash -c`, no `sh -c`, no command
  substitution of untrusted data.
- **Heredoc fixture safety:** Synthetic fixtures use
  `cat >"$fixture" <<'EOF'` — the **quoted** terminator disables shell
  expansion and command substitution inside the body, so the fixture content
  cannot escape into the surrounding test process.
- **Path traversal:** All file paths are repo-relative constants under the
  worktree; nothing constructs paths from variable input.
- **Model-ID injection into a future dispatcher:** Not reachable in this
  round (no consumer). The model-ID strings themselves
  (`claude-haiku-4.5`, `claude-sonnet-4.6`, `claude-opus-4.7-high`) contain
  no shell metacharacters and no fragments that could break out of a
  quoted argv slot in a future dispatcher.

### 2. Authentication and Authorization
N/A — no auth surface added or modified.

### 3. Data Exposure
- Test failure output prints sub-blocks of `config.md` / `SKILL.md` on
  assertion failure. Those files are public documentation; no secret
  material flows through.
- No new logging, no new error surfaces visible to end users.

### 4. Input Validation
- The awk parser `_model_routing_block` correctly bounds extraction: it
  starts at `^model_routing:[[:space:]]*$` and stops at the next column-0
  non-blank line. In the real `config.md` the YAML block lives inside a
  ```yaml fenced code block; the closing ``` line is column-0 non-blank and
  correctly terminates the block. No infinite loop, no bleed into adjacent
  sections of `config.md`, no swallowing of the cache-control retirement
  paragraph that precedes the new H2.
- No regex with catastrophic backtracking; all patterns are anchored and
  bounded by character-class quantifiers.
- No deserialization sink — the file is read as line-oriented text by awk.

### 5. Dependency Risks
No new dependencies. Helpers use awk + grep + bash 3.2 portable constructs
only (per the explicit portability comment in the test file: "no `mapfile`,
no `${var,,}`, no associative arrays, no GNU-only grep flags").

### 6. Cryptography
N/A — no crypto primitives, no random-number use, no tokens or hashing.

### 7. Race Conditions
N/A — synchronous awk/grep over static files inside per-test
`BATS_TEST_TMPDIR` isolation. No concurrent state.

## Orchestrator's specific concerns — addressed

- **Trust-boundary on model IDs:** No code path in this round sends these
  IDs anywhere. The dispatcher consumer is prose-only. When the consumer
  is implemented in a later task, that round's review will need to verify
  the read path validates host name against the closed set
  `{claude-code, copilot-cli}` and the tier name against
  `{haiku, sonnet, opus, inherit}` before indexing — but that is not in
  scope for T10.
- **Command injection in new bash helpers:** None reachable; all callers
  pass literals.
- **Awk parser on the new H2:** Parses safely; correctly bounded by the
  closing ``` fence as a column-0 non-blank stopper.
- **Mis-typed routing entries / billing surprises:** Every cell of the
  8-entry table matches task-10.md TE1–TE5 exactly. No tier maps up
  (sonnet→opus) or down (opus→haiku) accidentally. TE5 actively guards
  against the documented bare-short-form misconfiguration that would cause
  Copilot CLI to swap silently to a different model and emit warnings.

No findings at any severity. No advisories. CLEAN.
