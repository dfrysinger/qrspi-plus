---
status: draft
question_ids: [10]
research_type: codebase
---

# Q10: Full footprint of the prompt-cache mechanism

## Summary

**TL;DR:** The prompt-cache mechanism spans five files: the provider-schema documentation in `skills/using-qrspi/SKILL.md` (lines 427–428 and 441–442), the dual-flag gate implementation in `scripts/run-third-party-llm.sh` (lines 196–221 and 499–512), a dedicated cache-probe script at `scripts/g4-cache-probe.sh`, a stub spike-report document at `docs/qrspi/2026-05-17-v07-release/spikes/g4-cache-probe.md`, and two BATS unit suites: `tests/unit/test-cache-control-capability-gate.bats` and `tests/unit/test-cache-hit-rate.bats`. The 4-cell truth-table gate (only `supports_prompt_cache: true` AND `emit_cache_control_markers: true` together emit `cache_control`) is also duplicated as 4 named tests in `tests/unit/test-run-third-party-llm.bats`.

**Key findings:**
- `supports_prompt_cache` appears in 4 load-bearing locations: SKILL.md YAML example (line 427), SKILL.md description bullet (line 441), dispatcher `run-third-party-llm.sh` shell variable assignment (line 511), and three BATS fixture-writer helpers.
- `emit_cache_control_markers` appears in 4 parallel load-bearing locations: SKILL.md YAML example (line 428), SKILL.md description bullet (line 442), dispatcher shell variable assignment (line 512), and three BATS fixture-writer helpers. Additionally referenced in `test-cache-hit-rate.bats` at lines 167–170 and 183.
- The gate logic in `run-third-party-llm.sh`: both shell variables default to `"false"` (lines 499–500); `_dispatch_openai_chat` at line 205 evaluates `[ "$SUPPORTS_PROMPT_CACHE" = "true" ] && [ "$EMIT_CACHE_CONTROL_MARKERS" = "true" ]` to set a local `emit_cache` variable; if true, a Node.js snippet at lines 215–225 appends `msg.cache_control = { type: 'ephemeral' }` to the request JSON.
- One dedicated cache-probe script: `scripts/g4-cache-probe.sh` — issues 3 sequential Anthropic dispatches with a byte-identical system-prefix, extracts `cache_creation_input_tokens` / `cache_read_input_tokens` from a sidecar `.usage.json` file, derives a Path A / Path B / "Metadata not exposed" decision, and writes the report atomically with a co-located lock file.
- One spike-report evidence document (stub state): `docs/qrspi/2026-05-17-v07-release/spikes/g4-cache-probe.md` — `run_id: stub-pending-live-execution`, Decision section reads "Pending — operator runs scripts/g4-cache-probe.sh against live Anthropic API before this decision lands."
- Two dedicated BATS unit files and one general dispatcher test file reference cache-control behavior, for a total of 13 named `@test` blocks (5 in `test-cache-control-capability-gate.bats`, 4 in `test-run-third-party-llm.bats`, and 4 path-conditional + precondition tests in `test-cache-hit-rate.bats`).

**Surprises:** `test-run-third-party-llm.bats` contains a full duplicate of the 4-cell truth-table (identical test bodies to `test-cache-control-capability-gate.bats`) — the gate is pinned in two separate BATS suites.

**Caveats:** The `goals.md` file was not read (isolation invariant). The search covered all non-hidden files under the repo root. No acceptance-suite files outside `tests/unit/` reference these flags.

---

## Full findings

### 1. `skills/using-qrspi/SKILL.md` — schema documentation

**File:** `skills/using-qrspi/SKILL.md`

**Line 427** — YAML example, optional field value:
```yaml
supports_prompt_cache: false              # optional; default: false
```

**Line 428** — YAML example, optional field value:
```yaml
emit_cache_control_markers: false         # optional; default: false; independent of supports_prompt_cache
```

**Lines 441–442** — Description bullets under "Optional fields per entry":
- Line 441: `` `supports_prompt_cache` ``: boolean, default `false`. Signals that the provider supports prompt caching at the protocol level.
- Line 442: `` `emit_cache_control_markers` ``: boolean, default `false`. **Independent of `supports_prompt_cache`.** The dispatcher emits `cache_control` fields in requests to this provider ONLY when BOTH `supports_prompt_cache: true` AND `emit_cache_control_markers: true` are set on the provider entry (the dual-flag gate). A `true`/`false` mismatch on either flag suppresses `cache_control` emission entirely — setting one flag without the other has no effect on dispatcher output.

---

### 2. `scripts/run-third-party-llm.sh` — gate implementation

#### Initialization (lines 496–512)

Both shell variables are initialized to `"false"` before the provider-block parse loop:

```bash
SUPPORTS_PROMPT_CACHE="false"        # line 499
EMIT_CACHE_CONTROL_MARKERS="false"   # line 500
```

They are populated by the provider-config parser at lines 511–512:

```bash
supports_prompt_cache)      SUPPORTS_PROMPT_CACHE="$rec_val" ;;
emit_cache_control_markers) EMIT_CACHE_CONTROL_MARKERS="$rec_val" ;;
```

#### Gate logic in `_dispatch_openai_chat` (lines 196–225)

The function comment at lines 196–197 states:
> Emits cache_control ONLY when BOTH supports_prompt_cache AND emit_cache_control_markers are "true" on the resolved provider entry.

The dual-flag evaluation (lines 203–207):
```bash
# Dual-flag cache-control gate.
local emit_cache="false"
if [ "$SUPPORTS_PROMPT_CACHE" = "true" ] && [ "$EMIT_CACHE_CONTROL_MARKERS" = "true" ]; then
  emit_cache="true"
fi
```

The downstream Node.js JSON assembly (lines 215–225):
```javascript
const emitCache = process.argv[1] === 'true';
const msg = { role: 'user', content: prompt };
if (emitCache) {
  msg.cache_control = { type: 'ephemeral' };
}
```

**Scope of gate:** Applies only to `transport_type: openai-chat-completions`. The `codex-broker` transport branch does not assemble a JSON body in the shell script (delegates to a subprocess), so this gate is functionally inert for that transport.

---

### 3. `scripts/g4-cache-probe.sh` — dedicated cache-probe script

**File:** `scripts/g4-cache-probe.sh` (381 lines)

**Purpose:** G4 Mechanism A cache-probe ("Plan-time measurement"). Issues 3 sequential reviewer prompts with a byte-identical system-prefix (`skills/reviewer-protocol/SKILL.md` verbatim), captures `cache_creation_input_tokens` and `cache_read_input_tokens` from each response's `.usage.json` sidecar, derives a Path A / Path B decision, and writes an atomic report.

**Invocation:**
```
scripts/g4-cache-probe.sh --report-out <path>
```

**Path validation (lines 85–97):** Resolved `--report-out` path must lie under `$REPO_ROOT/docs/qrspi/`; traversal attempts rejected.

**Lock-file discipline (lines 99–117):** Removes any prior `g4-cache-probe.lock` at the start. On successful report write, creates a co-located lock file containing `run_id: <timestamp>-$$`. Downstream consumers detect stale reports by absence of lock or `run_id` mismatch.

**Decision derivation logic (lines 270–288):**
- All 6 metadata cells are `"none"` sentinel → `"Metadata not exposed — … Path B is REQUIRED"`
- Numeric fields but `cache_read` on calls 2 and 3 both `== 0` → `"Metadata exposed but zero hits — … Path B selected"`
- Otherwise (`cache_read` on call 2 OR 3 `> 0`) → `"Path A selected — … cache_control marker insertion is NOT required"`

**Dispatcher call (lines 207–213):**
```bash
bash "$DISPATCHER" \
  --artifact-dir "$ARTIFACT_DIR" \
  --provider anthropic-probe \
  --model claude-sonnet-4-5-20250929 \
  --output-file "$response_file" \
  < "$prompt_file"
```

Uses the `anthropic-probe` provider entry from `<artifact-dir>/config.md`.

**Report output path convention:** `docs/qrspi/<run-dir>/spikes/g4-cache-probe.md`; lock at `docs/qrspi/<run-dir>/spikes/g4-cache-probe.lock`.

---

### 4. `docs/qrspi/2026-05-17-v07-release/spikes/g4-cache-probe.md` — spike-report evidence document

**File:** `docs/qrspi/2026-05-17-v07-release/spikes/g4-cache-probe.md`

**State:** Stub authored at v0.7 T33 implementation time. Has not been replaced by a live run.

**Key fields:**
- `run_id: stub-pending-live-execution`
- `metadata_exposed: pending`
- All 6 measurement table cells: `pending`
- Decision section: `"Pending — operator runs scripts/g4-cache-probe.sh against live Anthropic API before this decision lands."`

**Derivation rule documented in stub** (three branches, lines 50–62):
1. Metadata not exposed at all → Path B REQUIRED (marker insertion + follow-up measurement)
2. Metadata exposed but zero hits → Path B selected (marker insertion)
3. Path A selected → instrument + measure only; `cache_control` marker insertion NOT required

**Consumers documented:** T36 `test-cache-hit-rate.bats` reads the Decision section; conditional T43 (Wave 9) marker-insertion task is gated by it.

---

### 5. `tests/unit/test-cache-control-capability-gate.bats` — dedicated dual-flag gate unit pin

**File:** `tests/unit/test-cache-control-capability-gate.bats` (163 lines)

**Label:** "T36 Slice 7 cache-control unit pin — dual-flag cache_control emission gate"

**Test structure:** Exercises all 4 cells of the `supports_prompt_cache` × `emit_cache_control_markers` truth table via stub curl that captures the request body to `$FIXTURE_DIR/curl-request-body.json`.

Named `@test` blocks (5 total):

| Test | Flags | Assertion |
|------|-------|-----------|
| `cell (a) (false,false)` | (false, false) | request body OMITS `cache_control` |
| `cell (b) (true,false)` | (true, false) | request body OMITS `cache_control` — "default state at T03 ship; critical to T33 spike measurement integrity" |
| `cell (c) (false,true)` | (false, true) | request body OMITS `cache_control` — capability gate |
| `cell (d) (true,true)` | (true, true) | request body CONTAINS `cache_control` with value `ephemeral` |
| `co-located contract` | all 4 | Re-runs all 4 cells in one test; asserts only (d) emits |

**Fixture writer** (`_write_provider`, lines 43–56): writes a `config.md` with both flags parameterized as `$1` and `$2`.

---

### 6. `tests/unit/test-run-third-party-llm.bats` — general dispatcher unit pin (cache section)

**File:** `tests/unit/test-run-third-party-llm.bats`

**Cache-relevant section** (lines 259–301): Header comment at lines 8–9 lists "dual-flag cache_control emission gate (all four cells of supports_prompt_cache: x emit_cache_control_markers:)" as one of the exercise targets.

**Fixture writer** (`_write_config_openai`, lines 46–62): `$5=supports_prompt_cache`, `$6=emit_cache_control_markers`.

Named `@test` blocks for cache gate (4 total, lines 265–301):

| Test | Flags | Assertion |
|------|-------|-----------|
| `cache_control gate (false,false)` | (false, false) | OMITS `cache_control` |
| `cache_control gate (true,false)` | (true, false) | OMITS `cache_control` — "default state at T03 ship and critical to T33 integrity" |
| `cache_control gate (false,true)` | (false, true) | OMITS `cache_control` (capability gate) |
| `cache_control gate (true,true)` | (true, true) | CONTAINS `cache_control` + `ephemeral` |

These are functionally identical to the cells in `test-cache-control-capability-gate.bats`.

---

### 7. `tests/unit/test-cache-hit-rate.bats` — path-conditional cache-hit-rate pin

**File:** `tests/unit/test-cache-hit-rate.bats` (207 lines)

**Label:** "T36 Slice 7 cache-control unit pin — cache-hit-rate, path-conditional"

**Purpose:** Reads `docs/qrspi/2026-05-17-v07-release/spikes/g4-cache-probe.md` (the T33 spike-report deliverable) to branch between Path A and Path B assertion sets.

**References to cache flags:**
- Line 11: `emit_cache_control_markers: false` providers receive NO `cache_control` field
- Line 167–170: Path B assertion grep-checks that `emit_cache_control_markers` appears in the spike report
- Line 183: `@test "Path B contrapositive: providers with emit_cache_control_markers: false get NO cache_control field"` — cross-references `test-cache-control-capability-gate.bats` cells (a)/(b)/(c)

**Named @test blocks with cache-control relevance:**
- Line 157: `Path B assertion: cache_control marker present on dual-flag-true providers AND hit-rate holds (when Path B)`
- Line 183: `Path B contrapositive: providers with emit_cache_control_markers: false get NO cache_control field`

**Loud-failure preconditions (lines 56–111):** The test also pins that:
- `scripts/g4-cache-probe.sh` documents the phrase "Lock-file discipline" (line 78)
- `scripts/g4-cache-probe.sh` documents the phrase "absence of a fresh lock or a run_id mismatch" (lines 82–86)
- The spike-report and lock-file `run_id` values match (lines 95–103)

**Current state:** All Path-conditional tests skip with `"verdict=PENDING — …"` because the stub report's Decision section is "Pending"; the PENDING-state diagnostic test fires and asserts the stub's `run_id` self-identifies as `stub-pending-live-execution` (line 205).

---

### Summary table — complete footprint

| File | Lines | Role |
|------|-------|------|
| `skills/using-qrspi/SKILL.md` | 427–428, 441–442 | Provider schema docs + dual-flag semantics |
| `scripts/run-third-party-llm.sh` | 196–207, 215–225, 499–512 | Gate variables init, parser, dual-flag conditional, JSON emission |
| `scripts/g4-cache-probe.sh` | 1–381 (entire file) | Dedicated cache-probe operator script |
| `docs/qrspi/2026-05-17-v07-release/spikes/g4-cache-probe.md` | 1–75 (entire file) | Spike-report evidence document (stub state) |
| `tests/unit/test-cache-control-capability-gate.bats` | 1–163 (entire file) | 5 dedicated dual-flag gate unit pins |
| `tests/unit/test-run-third-party-llm.bats` | 8–9, 39, 46–57, 260–301 | 4 duplicate dual-flag gate pins in general dispatcher suite |
| `tests/unit/test-cache-hit-rate.bats` | 1–207 (entire file) | Path-conditional hit-rate pin; 2 cache-flag-referencing @tests |
