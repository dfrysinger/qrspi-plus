---
finding_id: R1-F04
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-17-v07-release/plan.md:L820-L832
  - docs/qrspi/2026-05-17-v07-release/plan.md:L893-L904
  - docs/qrspi/2026-05-17-v07-release/design.md:L584-L590
artifact: plan
round: 1
reviewer: security-claude
---

Task 27 introduces the `wave_context:` companion parameter for the visual-fidelity reviewer dispatch. The design specifies that `wave_context:` is wrapped between `<<<UNTRUSTED-ARTIFACT-START id=wave_context>>>` / `<<<UNTRUSTED-ARTIFACT-END id=wave_context>>>` markers per the reviewer-protocol untrusted-data convention, and the reviewer agent must treat the body as untrusted data (not instructions).

The plan's test expectations for T27 confirm the wrapping: "Implement assembles a `wave_context:` companion from earlier-wave visual-fidelity reviewer findings on sibling UI tasks and passes it on the visual-fidelity reviewer dispatch in later waves, wrapped between the canonical `<<<UNTRUSTED-ARTIFACT-START id=wave_context>>>` / `<<<UNTRUSTED-ARTIFACT-END id=wave_context>>>` markers." The T30 wave-context-shape pin confirms the structural shape: "wave_context companion payload carries the wave identifier and per-task entries (task ID, task name, `allowed_files` glob, sibling findings) wrapped between the canonical untrusted-data markers."

However, the `wave_context:` body is assembled from earlier-wave visual-fidelity reviewer findings — specifically from the finding files written by `qrspi-visual-fidelity-reviewer`. These finding files are written under `reviews/tasks/task-NN/` and their content may in turn contain quoted strings from the artifact under review (e.g., a finding that quotes a UI string from the source artifact). If the source artifact contained a crafted `<<<UNTRUSTED-ARTIFACT-START id=wave_context>>>` token inside a string that the reviewer quoted in its finding, that token would appear in the assembled `wave_context:` body.

When the orchestrator assembles `wave_context:` from these finding files and wraps the assembled body between `<<<UNTRUSTED-ARTIFACT-START id=wave_context>>>` and `<<<UNTRUSTED-ARTIFACT-END id=wave_context>>>`, a nested sentinel token inside the body creates a premature close of the outer wrapper. Specifically: the reviewer parsing the dispatch prompt would see `<<<UNTRUSTED-ARTIFACT-START id=wave_context>>>` (outer open), then encounter a `<<<UNTRUSTED-ARTIFACT-END id=wave_context>>>` from inside the body (premature close), then encounter trusted content from the prompt's instruction region interpreted as data, and then see another unexpected sentinel. The net effect is that content outside the intended untrusted region could be interpreted as untrusted (masking real instructions) or that the closing sentinel in the body could confuse the reviewer's instruction parser in a model-specific way.

The plan does not require the `wave_context:` assembly step to sanitize or reject finding content that contains sentinel tokens. Neither T27's test expectations nor the T30 wave-context-shape pin include a test case asserting: "when a sibling task's earlier-wave finding contains a sentinel-marker string, the wave_context assembly either sanitizes the marker or rejects the finding with a loud diagnostic."

The design's G7 hygiene contract covers internal-ID tokens in git-tracked files but explicitly carves out `wave_context:` as a runtime-assembled in-memory parameter. That carve-out is correct for the G7 ID-hygiene scan, but it should not also exempt `wave_context:` assembly from sentinel-collision validation. The `guard_marker_injection` function introduced in T02 exists precisely for this scenario and should be applied to each finding body before it is incorporated into the `wave_context:` payload.

Resolution: T27's test expectations should add: "When a sibling task's earlier-wave finding file contains a `<<<UNTRUSTED-ARTIFACT-START>>>` or `<<<UNTRUSTED-ARTIFACT-END>>>` sentinel token in its body, the `wave_context:` assembly step either strips the token (with a logged diagnostic) or excludes the finding from the payload with a loud diagnostic, rather than embedding a nested sentinel in the wrapper body." T30's wave-context-shape pin should add a fixture that exercises this collision case.
