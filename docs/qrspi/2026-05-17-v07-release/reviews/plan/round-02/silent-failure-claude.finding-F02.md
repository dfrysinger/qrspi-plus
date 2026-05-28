---
finding_id: R2-F02
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/plan.md:L148-L157]
artifact: plan
round: 2
reviewer: silent-failure-claude
---

T01 documents that the legacy-config one-time warning fires when `model_routing:` is absent on resume and documents "one-time backfill behavior when a resumed run's `config.md` predates the `model_routing:` field." The "one-time" semantics require some mechanism to track that the warning has already been delivered so it does not repeat on subsequent resumes. The most natural mechanism is writing a marker to the config file or to a sidecar file after backfill.

Neither T01's description nor its test expectations address what happens if this marker write fails — for example, because `config.md` is read-only or the artifact directory is on a read-only filesystem. If the marker write fails silently, the run proceeds with the backfill applied for this session but with no persisted marker, so the one-time warning fires again on every subsequent resume (the warning becomes a many-time warning), and more critically, the caller has no signal that the config file is in an inconsistent state. In the worst case, the backfill values are only applied in-memory and the on-disk config remains unmodified: the next resume applies backfill again, producing a "resume always uses backfill defaults" mode of operation that is effectively a permanent silent fallback rather than a one-time migration.

T07's `test-config-model-routing.bats` expectations (L320-L324) cover "the legacy-config one-time warning on resume" as a test case but the description says it covers the warning firing, not the marker-write failure path.

Resolution: Add a test expectation to T01 (and a corresponding case in T07's legacy-config pin) specifying that if the one-time warning's persistence write fails, the dispatcher exits 1 with a named diagnostic identifying the write failure rather than silently proceeding with an un-persisted backfill state. Alternatively, clarify that "one-time" is implemented purely in-memory per session (no persistent marker), which eliminates the write-failure surface entirely — but that design decision must be stated explicitly so it is not accidentally implemented as a persistent marker that silently fails.
