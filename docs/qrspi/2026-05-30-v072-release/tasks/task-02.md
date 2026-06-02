---
status: approved
task: 2
phase: 1
pipeline: full
goal_ids: [G12]
task_type: code
model: opus
---

# Task 02: G12 verifier-fan-in script with dispatch-prose include

- **Target files:** scripts/verifier-fan-in.sh (create), skills/_shared/verifier-dispatch-prose.md (create)
- **Dependencies:** none. **Blocks:** Task 05 (G13 enum hardening on `scripts/verifier-fan-in.sh`), Task 06 (G11 verifier sidecar extension lock), Task 24 (CD-4 interaction-mode helper).
- **LOC estimate:** ~180

**Overview**

Create the deterministic verifier fan-in primitive and the shared verifier-dispatch prose snippet so apply-fix consumes disk-written verifier sidecars through `kept-findings.txt` instead of chat-parsed verifier output. The script owns the kept-set decision and audit trail; the snippet gives artifact-level and task-level consumers one includeable dispatch sequence without duplicating per-finding loop prose. (Why: see goals.md ### G12. Approach: see design.md ## G12 and design.md ### CD-4.)

**Scope**

- **In:**
  - Create `scripts/verifier-fan-in.sh` to enumerate `<round-dir>/*.finding-F*.md`, validate each finding's `change_type:`, locate the paired `<reviewer-tag>.finding-F<NN>.score.md` sidecar, parse `score:`, apply the script-owned threshold rule, and emit the canonical kept set.
  - Write `kept-findings.txt` as one absolute kept finding-file path per line and `.verifier-fan-in-audit.json` with scored, kept, dropped, halt, and threshold data.
  - Fail loudly with a non-zero exit and audit halt record for missing `change_type`, out-of-enum `change_type`, missing sidecar, wrong sidecar extension, or unparseable score.
  - Create `skills/_shared/verifier-dispatch-prose.md` with the single `dispatch-agent.sh --verifier-fanout` invocation, one Task call per emitted spec line using the referenced dispatch file verbatim, `await-round.sh`, and the subsequent `scripts/verifier-fan-in.sh <round-dir>` invocation.
  - Preserve the singleton verifier tier-override shape and keep verifier payload prose out of orchestrator stdout/stderr.

- **Out:**
  - `change_type` enum drift hardening across reviewer emission and fan-in consumption — Task 05 owns.
  - Verifier-agent sidecar path/extension instruction updates — Task 06 owns.
  - Interaction-mode detection and rescue/escalation helper behavior for CD-4 halt handling — Task 24 owns.
  - Adding `!cat` include sites to consumer skill files — outside this task's target files; this task authors the includeable shared snippet only.

**Definition of done**

- `scripts/verifier-fan-in.sh` exists and accepts a round directory argument for the fan-in pass.
- A well-formed round exits 0, writes `kept-findings.txt` containing only absolute paths for kept finding files, and writes `.verifier-fan-in-audit.json` with scored, kept, dropped, empty `halts`, and threshold data.
- Findings below the configured floors for `style`, `clarity`, and `correctness` are dropped; `scope` and `intent` findings are kept without score-threshold filtering.
- Missing `change_type`, out-of-enum `change_type`, missing sidecar, wrong sidecar extension, and unparseable score each exit non-zero and record the matching halt cause in `.verifier-fan-in-audit.json`.
- `skills/_shared/verifier-dispatch-prose.md` documents exactly one verifier fan-out dispatch sequence: `dispatch-agent.sh --verifier-fanout`, one Task call per emitted spec line using `DISPATCH_FILE=<absolute-path-from-PROMPT_FILE>`, `await-round.sh`, then `scripts/verifier-fan-in.sh <round-dir>`.
- The shared snippet does not echo verifier payloads, does not restate per-finding verifier loops, and uses a bare `<tier>` for verifier `--tier-override` rather than the reviewer CSV grammar.

**Test expectations**

- Run a well-formed fixture round and verify exit 0, `kept-findings.txt` absolute-path contents, and `.verifier-fan-in-audit.json` counts/thresholds with `halts: []`.
- Run threshold fixtures proving below-floor `style`, `clarity`, and `correctness` findings are dropped while `scope` and `intent` findings are not threshold-filtered.
- Run malformed fixture rounds for missing `change_type`, out-of-enum `change_type`, missing sidecar, wrong sidecar extension, and unparseable score; each must exit non-zero and write the matching audit halt cause.
- Inspect `skills/_shared/verifier-dispatch-prose.md` for the required `dispatch-agent.sh --verifier-fanout` invocation, one-Task-per-spec-line contract, `await-round.sh` follow-up, and fan-in invocation.
- Grep the shared snippet to confirm it contains no verifier payload echoing, no inline per-finding verifier loop, and no reviewer-style `tag=tier` tier-override grammar.

**References**

- goals.md ### G12 — problem framing for replacing chat-parsed verifier sidecars with an automated fan-in consumer.
- design.md ## G12 — declares the CD-4 verifier-fan-in pipeline as the resolution and names the script as canonical filter.
- design.md ### CD-4 — end-to-end reviewer → verifier → sidecar → fan-in → kept-findings flow, component C script behavior, component H dispatch snippet behavior, and G12 acceptance.
- structure.md ### `scripts/verifier-fan-in.sh` — per-file block for the script interface, audit schema, halt causes, and threshold/filter responsibilities.
- structure.md ### `skills/_shared/verifier-dispatch-prose.md` — per-file block for the shared verifier-dispatch prose contents and constraints.
- structure.md ### CD-4 / G12 verifier-dispatch-prose `!cat` include sites — downstream consumer placement context for the shared snippet.
