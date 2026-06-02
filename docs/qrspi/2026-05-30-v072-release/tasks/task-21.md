---
status: approved
task: 21
phase: 1
pipeline: full
goal_ids: [G16]
task_type: code
model: opus
---

# Task 21: G16 path-filter exfil hardening in `dispatch-agent.sh`

- **Target files:** `scripts/dispatch-agent.sh`; `tests/unit/test-dispatch-agent.bats`; `agents/qrspi-implementer.md`; `scripts/dispatch-companion.sh` (audit/comment only if the direct companion entry point can accept raw file paths)
- **Dependencies:** Task 20
- **LOC estimate:** ~120

**Overview**

Harden the post-rename dispatch wrapper so every prompt-ingested file path is canonicalized under `$REPO_ROOT` before its content can enter a sanctioned LLM channel. The task also adds defense-in-depth implementer prose and audits the companion dispatcher for the same raw-path surface. (Why: see goals.md ### G16. Approach: see design.md ## G16.)

**Scope**

- **In:**
  - Add a single fail-closed `assert_path_under_repo_root <label> <abs-path>` guard in `scripts/dispatch-agent.sh`, inherited from the pre-rename `scripts/run-codex-review.sh` design, that canonicalizes with `realpath` / `readlink -f` and rejects paths whose canonical target is not under canonical `$REPO_ROOT/`.
  - Apply the guard after file-existence checks and before any prompt emission or `cat` read for the agent file and every `--subject-code`, `--artifact-body`, `--companion`, and `--diff-file` path family.
  - Preserve legitimate repo-local `--dry-run` behavior and the existing first-party spec-line / prompt-file contract.
  - Rename/extend the existing wrapper test coverage in `tests/unit/test-dispatch-agent.bats` to pin out-of-repo absolute paths, symlink-out-of-repo paths, readable out-of-repo companion files, guard coverage for all four path-argument families, canonicalization-failure diagnostics, and valid repo-local pass cases.
  - Insert the `## Orchestrator-Only Scripts (Bash Allowlist)` section at the top of `agents/qrspi-implementer.md`, using the post-rename script names `scripts/dispatch-agent.sh` and `scripts/dispatch-companion.sh`, and forbid relative, absolute, alias, or shell-expansion invocation shapes.
  - Audit `scripts/dispatch-companion.sh`: if it accepts raw file paths directly, share the same repo-boundary guard; otherwise document that it receives assembled prompt data rather than arbitrary file paths.

- **Out:**
  - Dispatch-script rename collapse, universal routing behavior, and per-skill prose migration — T20 owns; this task works against the post-rename `dispatch-agent.sh` / `dispatch-companion.sh` surface.
  - Broader all-`scripts/` sanctioned-channel exfil sweeps beyond the direct companion entry point — deferred to the v0.7.3+ open question in design.md ## G16.
  - Adding a full positive command-family allowlist to `agents/qrspi-implementer.md` — design.md ## G16 locks the narrow B1 restriction only.
  - Changes to `agents/qrspi-test-writer.md`, `skills/reviewer-protocol/SKILL.md`, or `skills/using-qrspi/SKILL.md` — design.md ## G16 explicitly excludes them from this remediation.

**Definition of done**

- `scripts/dispatch-agent.sh` rejects any canonicalized prompt-ingested path outside canonical `$REPO_ROOT/` with non-zero exit and a clear stderr diagnostic containing `resolves outside repository` where applicable.
- Symlinks whose lexical path appears allowed but whose canonical target is outside the repository are rejected before prompt files are emitted or file contents are read.
- Readable out-of-repo `--companion` paths fail by boundary check rather than by missing-file behavior.
- `--subject-code`, `--artifact-body`, `--companion`, and `--diff-file` all pass through the same repo-boundary enforcement point; valid repo-local inputs for each continue to pass `--dry-run`.
- Canonicalization failures fail closed with non-zero exit and a clear stderr diagnostic; no raw path is read with `cat` before existence and repo-boundary checks pass.
- `agents/qrspi-implementer.md` contains a top-of-body `## Orchestrator-Only Scripts (Bash Allowlist)` section forbidding implementers from invoking `scripts/dispatch-agent.sh` or `scripts/dispatch-companion.sh` under relative, absolute, alias, or shell-expansion path shapes.
- `scripts/dispatch-companion.sh` is audited for direct raw-file-path inputs and either shares the guard for any such inputs or documents that it receives assembled prompt data rather than arbitrary file paths.

**Test expectations**

- `tests/unit/test-dispatch-agent.bats` includes a regression where `bash scripts/dispatch-agent.sh ... --subject-code /etc/hosts --dry-run` exits non-zero and stderr contains `resolves outside repository`.
- Add a symlink regression proving a path whose lexical location looks allowed but whose canonical target is outside `$REPO_ROOT` exits non-zero with the same diagnostic before any prompt file is emitted.
- Add a readable out-of-repo `--companion` regression that exits non-zero with `resolves outside repository`, proving the guard is a boundary check rather than a missing-file side effect.
- Use tests or table-driven coverage to pin that `--artifact-body` and `--diff-file` receive the same `assert_path_under_repo_root` enforcement as `--subject-code` and `--companion`.
- Include valid repo-local artifact, companion, subject-code, and diff path dry-run cases that preserve the existing first-party spec-line / prompt-file contract.
- Include a canonicalization-failure check that fails closed with a clear stderr diagnostic and confirms no raw path is read before existence and repo-boundary checks pass.
- Grep/structure inspection confirms `agents/qrspi-implementer.md` has the required allowlist section using post-rename script names and covering relative, absolute, alias, and shell-expansion path shapes.
- Audit inspection confirms `scripts/dispatch-companion.sh` either uses the shared boundary guard for direct raw-file-path inputs or carries the documented no-raw-path comment.

**References**

- goals.md ### G16 — problem framing for sanctioned-channel exfil through arbitrary wrapper path inputs.
- design.md ## G16 — strict `$REPO_ROOT/` canonicalization, narrow implementer allowlist, regression tests, and companion audit decisions.
- structure.md ### `scripts/run-codex-review.sh` → Slice 1.4 rename to `scripts/dispatch-agent.sh`; responsibility includes G16 boundary guard on every prompt-ingested path.
- structure.md ### `tests/unit/test-run-codex-review.bats` → rename to `tests/unit/test-dispatch-agent.bats`; responsibility lists the G16 regression coverage.
- structure.md ### `agents/qrspi-implementer.md` — top-of-body orchestrator-only script allowlist insertion site and post-rename-name note.
- structure.md ### `scripts/run-third-party-llm.sh` → rename to `scripts/dispatch-companion.sh`; companion dispatcher surface to audit for raw-path inputs.
