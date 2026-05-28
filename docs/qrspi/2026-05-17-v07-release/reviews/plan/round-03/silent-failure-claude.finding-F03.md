---
finding_id: R3-F03
severity: high
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-17-v07-release/plan.md:L205-L221
  - docs/qrspi/2026-05-17-v07-release/plan.md:L1291-L1305
artifact: plan
round: 3
reviewer: silent-failure-claude
---

T03's test expectations unconditionally assert cache_control behavior keyed on `supports_prompt_cache:`: "When `supports_prompt_cache: false`, the assembled request payload contains no `cache_control` fields; when `true`, the payload includes them." This is an unconditional contract that T03 ships at implementation time, independent of T33's spike outcome.

T43 then says it will *add* `cache_control` marker insertion to `scripts/run-third-party-llm.sh` only on Path B. But if T03 already ships this behavior, T43's Path B edit is redundant — and more critically, T33's measurement is contaminated: the probe dispatches that T33's `g4-cache-probe.sh` issues will already have `cache_control` markers inserted by T03 before T33 can measure whether the platform caches automatically. This makes the Path A vs Path B distinction undetectable — the spike is measuring cache behavior WITH cache_control markers already active, so Path A ("auto-caching works") cannot be distinguished from "we inserted markers and caching worked."

The silent failure here is that the plan specifies contradictory behaviors for two tasks that touch the same file (`scripts/run-third-party-llm.sh`), and neither task's test expectations catch the contradiction:
- T03 ships with cache_control logic (test-proven)
- T43 proposes to add that same logic conditionally (test-expected on Path B)
- T33 measures whether caching works automatically, but T03 has already modified the measurement surface

There are two valid resolutions:
1. T03 does NOT ship cache_control insertion logic (only the capability gate structure); T43 adds the actual insertion on Path B. T03's test expectations must be corrected to remove the "when true, includes them" assertion and instead assert only that the capability-gate flag is read and a Path B hook point exists.
2. T03 DOES ship cache_control insertion unconditionally; T43 is a NO-OP on both paths; T33's probe script explicitly strips or ignores cache_control when measuring auto-caching behavior.

Neither resolution is specified in the current plan. The current text leaves implementers free to deliver T03 with full cache_control logic while also treating T43 as conditional — silently producing an inconsistent state where T33's measurement validity depends on T03 implementation choices that the plan does not constrain.

**Fix:** Disambiguate the cache_control ownership boundary between T03 and T43. Either (a) revise T03's test expectations to remove the unconditional cache_control-insertion assertions and state that T03 ships only the `supports_prompt_cache:` capability-gate flag read with no actual `cache_control` field emission until T43 activates on Path B, OR (b) revise T43 to state it is unconditionally a NO-OP because T03 already ships the cache_control insertion logic, and revise T33's probe requirements to account for pre-existing cache_control markers in its measurements.
