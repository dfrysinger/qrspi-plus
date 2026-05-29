# Coverage review — T10 R4 (deep mode): CLEAN

**Reviewer:** coverage-claude
**Round:** 04 (thoroughness fan-out)
**Task:** task-10 (G7b — wire per-host `model_routing` resolution for agent tier names)
**Verdict:** CLEAN (no findings)

## Scope reviewed

Three test files extended/created across T10 initial + R1 + R2:

- `tests/unit/test-agent-frontmatter-no-model.bats` — T10-extended with TE1–TE7 (per-host tier resolution lint + SKILL.md Model Routing section pin + helper meta-self-assertion fixtures)
- `tests/unit/test-config-model-routing.bats` — T10 R1 + R2 touched (schema-replacement pin rewording on L71 / L121 / L187; precedence-chain co-location pin re-anchored to `host/tier lookup`)
- `tests/unit/test-using-qrspi-vocab.bats` — R1 created; R2 appended fail-loud presence pin (slice 3b) + anti-pattern absence pin (slice 3c)

Production "code" under test = the two documented contracts:
- `docs/qrspi/2026-05-27-v071-hardening/config.md` `model_routing:` table (8 entries: 4 tiers × 2 hosts)
- `skills/using-qrspi/SKILL.md` § `#### \`model_routing:\` block` (schema doc + fail-loud paragraph) + § `#### Model Routing` (resolution-flow prose) + § Precedence chain step 3

## Coverage findings

### 1. Behavioral coverage — 100% TE→test mapping

All test expectations from `tasks/task-10.md`, `fixes/task-10-round-01/fix-task-01.md`, and `fixes/task-10-round-02/fix-task-02.md` have a corresponding assertion. Mapping verified line-by-line:

| Source | TE | Test |
|---|---|---|
| task-10 | TE1 | `[T10/TE1]` (test-agent-frontmatter-no-model.bats L357–387) |
| task-10 | TE2 | `[T10/TE2]` (L389–419) |
| task-10 | TE3 | `[T10/TE3]` (L421–451) |
| task-10 | TE4 | `[T10/TE4]` (L453–485) |
| task-10 | TE5 | `[T10/TE5]` (L487–517) — has explicit vacuous-pass guard |
| task-10 | TE6 | `[T10/TE6]` (L519–550) |
| task-10 | TE7 | `[T10/TE7] GREEN` (L552–611) + `[T10/TE7] RED` (L613–700) |
| R1 fix | TE1 | vocab.bats L81–86 |
| R1 fix | TE2 | vocab.bats L88–93 |
| R1 fix | TE3 | vocab.bats L95–110 |
| R2 fix | Slice 3a | test-config-model-routing.bats L187–193 |
| R2 fix | Slice 3b | vocab.bats L112–123 |
| R2 fix | Slice 3c | vocab.bats L125–134 |

### 2. Edge cases — covered

- Block-absent fixture: TE7 RED (a)
- Host-key-missing fixture: TE7 RED (b)
- Tier-row-missing fixture: TE7 RED (c)
- Bare tier short-form rejection: TE5 (production) + TE7 GREEN scan (helper)
- `_host_subblock` correctly rejects `<host>: <inline-value>` (regex requires trailing whitespace-only line) — verified against AWK
- Vacuous-pass guards present on TE5 and on each tier-pair assertion (TE1–TE4 fail if either sub-block is empty)

### 3. Test quality — strong

- All assertions are on observable file content (not implementation internals)
- Test names follow `[T10/TEn]` tagging that maps directly to the spec
- Loud diagnostics on every failure path (echo of extracted sub-block on mismatch)
- TE7 meta-self-assertion is a notable strength — defends the AWK helpers themselves against silent drift
- R2 slice 3a comment explicitly documents the pre-R2 silent-pass quirk it closes
- Slice 3c anti-pattern absence pin paired with slice 3b presence pin — symmetric load-bearing coverage of the fail-loud contract per the dispatch directive's minimum

### 4. Test isolation — clean

- TE7 fixtures use `${BATS_TEST_TMPDIR}` (per-test scratch dir)
- `setup` / `setup_file` only export env vars; no shared mutable state
- No time/network/order dependencies
- All three files load `../helpers/skill-markdown` consistently

## Trade-off acknowledgment (not a finding)

Per the dispatch directive's instruction:

> "Note any thin coverage on the three individual invariants if it would meaningfully harden the test bed — but the silent-failure-claude R3 review acknowledged the spec deliberately bundled the invariants into one positive pin as a trade-off, not a defect."

The R2 fail-loud presence pin (vocab.bats L121–122) asserts `"halts and reports"` + `"never falls back silently"` against the H4 body. The SKILL.md fail-loud paragraph (L470) enumerates three structural invariants in a single sentence:

1. `detect_host` returns a host with no matching top-level key
2. agent tier name (or implicit `inherit`) matches no row under the host's sub-mapping
3. tier value is a bare short-form rather than a fully versioned ID

A future edit dropping any single invariant clause would still pass the umbrella `"halts and reports"` pin. Three additional substring pins (`"no matching top-level key"`, `"matches no row"`, `"bare short-form"`) would harden this without expanding surface area significantly.

**This is explicitly acknowledged as a deliberate spec trade-off by silent-failure-claude R3, not a defect. Not filed as a coverage finding.**

## No findings

All test expectations covered with load-bearing, well-isolated, behavior-oriented assertions. The R2 silent-failure F01 closure has both required pin types (presence + absence). The R1 schema-replacement closure has full vocab coverage. The structural lint helper is meta-tested.

Verdict: **CLEAN**
