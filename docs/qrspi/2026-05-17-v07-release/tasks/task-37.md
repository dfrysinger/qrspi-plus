---
task: 37
status: approved
pipeline: full
task_type: code
model: sonnet
phase: 1
goal_ids: [G4]
dependencies: [T13]
loc_estimate: 80
---

# Task 37: G4 cross-cutting rejection-of-summary-shims invariant pin

- **Phase:** 1
- **Target files:**
  - `tests/unit/test-no-summary-shim-dispatches.bats` (Create) — repo-wide code-search BATS pin that asserts no agent dispatch site feeds an LLM-generated summary of a stable artifact back into a downstream prompt as source-of-truth. Loads `tests/helpers/skill-markdown.bash` (T13) for `require_repo_root` and shared diagnostics; scans `skills/**/SKILL.md` and `agents/qrspi-*.md` for dispatch-prompt shapes that would substitute a derived summary for a verbatim Read or for a Mechanism B index-driven narrow Read.
- **Dependencies:** T13
- **LOC estimate:** ~80
- **Description:** Pins the cross-cutting G4 rejection-of-summary-shims invariant per `design.md` lines 219 and 238 — the rule that summary-shim mechanisms (LLM-generated condensations consumed as prompt source-of-truth in place of the original artifact) are explicitly rejected by the design, in contrast to Mechanism A (prompt caching, which preserves verbatim content) and Mechanism B (the section-anchor index, which slices verbatim content). The test is a code-search assertion against the QRSPI dispatch surface: it walks every skill body (`skills/**/SKILL.md`) and every QRSPI agent body (`agents/qrspi-*.md`) and asserts no dispatch site composes a prompt whose source-of-truth payload is a derived-summary artifact substituted for the corresponding stable source artifact (e.g., a dispatch that injects `<summary-of reviewer-protocol.md>` into a reviewer's prompt body rather than the actual `reviewer-protocol/SKILL.md` content or a verbatim index-driven slice of it). The pin is cross-cutting because the invariant spans every dispatch site rather than any one Mechanism A or Mechanism B surface — it catches regressions where a future skill author reaches for the rejected third mechanism (the summary shim) instead of either of the two unconditionally-accepted mechanisms. The test uses `tests/helpers/skill-markdown.bash` for the shared `require_repo_root` resolution and shared diagnostic shape; it fails loud with the offending file path, dispatch-site context, and the matched summary-shim shape when an introduction is detected.
- **Test expectations:**
  - The test walks every file matching `skills/**/SKILL.md` and `agents/qrspi-*.md` from the resolved `REPO_ROOT`.
  - For each file the test asserts no dispatch-prompt construction substitutes a derived-summary artifact for the corresponding stable source artifact as the prompt's source-of-truth payload.
  - When a fixture introduces a summary-shim dispatch shape (e.g., a dispatch site that composes its prompt around an LLM-generated condensation of `reviewer-protocol/SKILL.md` and feeds that condensation as the reviewer's source-of-truth body), the test fails with a diagnostic naming the offending file, the line range of the dispatch site, and the matched summary-shim shape.
  - The test loads `tests/helpers/skill-markdown.bash` via `load 'helpers/skill-markdown'` and uses `require_repo_root` for repo-root resolution.
  - The test does NOT flag verbatim Read sites (full-file Reads) or Mechanism B index-driven narrow Reads against `.anchors.json` from T34 — both deliver verbatim content and are explicitly outside the rejected category.
  - The test does NOT flag human-facing digest surfaces (summaries presented to a reader rather than fed back into an agent dispatch as source-of-truth) — the rejection scope is dispatch-prompt source-of-truth payloads only, per the design line-219 carve-out.
  - The test runs green under the unit BATS suite against the current dispatch surface.
  - The test runs green under the bash 3.2 runtime from the T14 CI workflow's `bash32` job.
  - The detection pattern distinguishes summary-shim dispatch sites (where a derived condensation of a stable artifact is substituted as the prompt source-of-truth in place of the original artifact) from the two accepted mechanisms. The literal detection algorithm — the specific regex(es), token forms, and grep/awk commands used to classify a dispatch site — is authored in the BATS file itself (Implement-TDD), not in this task spec. Plan declares the behavioral boundary in plain language; the falsifiability anchor is concrete fixtures the pin exercises. The three exclusion categories (Plan OWNS the boundary statements): (1) **verbatim Reads excluded** — a dispatch site that Reads the full body of the stable artifact and feeds the verbatim content into the prompt is not a summary-shim. (2) **Mechanism B narrow-read sites excluded** — a dispatch site that consults a section-anchor index (`.anchors.json` from T34) and Reads a narrow line-range slice that is byte-identical to the source slice is not a summary-shim, because the slice preserves verbatim content. (3) **Human-facing digest surfaces excluded** — a summary surfaced to a human reader (e.g., a `## Summary` body for user presentation) is not a summary-shim, because the rejection scope is dispatch-prompt source-of-truth payloads only, per the design line-219 carve-out. The pin's falsifiability is exercised by three behavioral fixtures: a positive fixture (a synthesized summary-shim dispatch site) causes the pin to fail; a verbatim-Read fixture does NOT cause the pin to fail; a Mechanism B narrow-read fixture does NOT cause the pin to fail.
