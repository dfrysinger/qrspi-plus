---
finding_id: R2-F02
severity: high
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/plan.md:L847-L856]
artifact: plan
round: 2
reviewer: security-claude
---

T27 renders `reference_artifact:` via `SendUserFile` or inline Read without requiring any path validation against the artifact directory, enabling path-traversal to arbitrary files on the host.

The T27 description states: "The orchestrator renders the `reference_artifact:` to the user in a user-visible form keyed on the artifact's file extension — images (`.png`, `.jpg`, `.jpeg`, `.gif`, `.webp`) and PDFs (`.pdf`) dispatch through `SendUserFile` so the user sees the rendered artifact, not a path string; text artifacts (`.md`, `.txt`, `.json`, `.yml`, `.yaml`, and other text MIME types) are surfaced via inline Read."

The `reference_artifact: <path>` value originates from a task spec frontmatter field. Task specs in `tasks/task-NN.md` are authored by sub-subagents in the T31/T32 fan-out. A compromised or malicious sub-subagent could write `reference_artifact: ../../../../.ssh/id_rsa` or `reference_artifact: ../../../../etc/shadow`. The Implement orchestrator would then call `SendUserFile` or Read against that resolved absolute path, surfacing the contents to the user session — leaking secrets from the host filesystem.

The T30 pin bundle does not include any test expectation asserting that `reference_artifact:` paths outside the artifact directory (or outside a declared allowed prefix) are rejected before rendering. The security-claude.R1-F03 fix added path-validation for `--artifact-dir` (T03) and `--report-out` (T33) but this analogous field in T27 was not addressed.

Required fix: Add to T27's description and test expectations: the orchestrator validates the `reference_artifact:` path before any Read or SendUserFile call — the path must be within the `<artifact-dir>` tree (or a declared sibling/allowed path listed in the spec); a path that resolves outside the allowed tree exits 1 (or pauses with a named diagnostic) WITHOUT rendering or reading the path; and the T30 reference-gate-fields pin must include a test expectation for the path-traversal rejection case (a task spec with a `reference_artifact:` pointing outside the artifact dir is blocked before rendering).
