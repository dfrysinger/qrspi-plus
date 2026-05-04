<!-- EXPECTS-FRAMING (single-template): <output_file> AND a stdin-piped prompt; <codex_dispatches> MUST NOT be declared in the same framing block. -->
<!-- EXPECTS-FRAMING (multi-template): <codex_dispatches> with one or more <dispatch> children, each carrying <output_file> AND a stdin-piped prompt; top-level <output_file> MUST NOT be declared in the same framing block. -->

## Dispatch form

All Codex dispatches use the **stdin pipeline** form. The legacy `launch --prompt-file <path>` form is retired (commit 21/22 of #110 migration); all live callers were migrated by commit 18 of that sequence to assemble the prompt body inline and pipe it to the wrapper.

### Canonical dispatch shape

The orchestrator assembles each prompt by concatenating the YAML-stripped bodies of `skills/reviewer-protocol/SKILL.md` and the relevant `agents/qrspi-{name}.md` agent file, then appending dispatch-specific parameters under a `## Dispatch parameters` heading, and pipes the result to `scripts/codex-companion-bg.sh launch`:

```sh
{ awk '/^---$/{n++; next} n>=2{print}' skills/reviewer-protocol/SKILL.md;
  printf '\n\n---\n\n';
  awk '/^---$/{n++; next} n>=2{print}' agents/qrspi-{name}.md;
  printf '\n\n## Dispatch parameters\n\n';
  printf 'task_id: %s\n' "<task_id>";
  printf 'phase_dir: %s\n' "<phase_dir>";
  printf 'output_file: %s\n' "<output_file>";
} | scripts/codex-companion-bg.sh launch
```

The awk one-liner strips the YAML front-matter (everything between the first and second `---` lines) so the agent's frontmatter description does not leak into the dispatch body. Internal `---` separators inside the body are preserved.

The wrapper reads the piped prompt from stdin (no temp file managed by the orchestrator), spawns the companion in `--background` mode, and prints the captured `jobId` to stdout as a single line, exiting 0 within ~5s. The orchestrator records the printed `jobId` text from the Bash tool's stdout output and pastes it as the literal `<jobId>` argument in the matching await Bash call below; there is no shell variable assignment in this flow, and shell command substitution (`$()` / backticks) is forbidden per Daniel's CLAUDE.md. If launch exits non-zero, abort this Codex review and write a launch-failure note to `<output_file>`.

## Single-template form

This section applies when the framing block declares a top-level `<output_file>` and a single stdin-piped prompt and does NOT declare `<codex_dispatches>`.

1. Assemble the dispatch prompt per the canonical shape above (concatenate protocol + agent body + dispatch parameters).
2. Launch the job early (in parallel with the Claude reviewer above) by piping the assembled prompt into `scripts/codex-companion-bg.sh launch` as a foreground Bash-tool call. The wrapper prints the jobId to stdout as a single line and exits 0 within ~5 seconds. Record the printed jobId text and paste it as the literal `<jobId>` argument in the matching await call below. If launch exits non-zero, abort this Codex review and write a launch-failure note to `<output_file>`.
3. After the Claude reviewer returns, await the result and **redirect stdout directly to the per-round Codex file** so finding text never enters main chat: `scripts/codex-companion-bg.sh await --artifact-dir <ABS_ARTIFACT_DIR> <jobId> > <output_file>` (substituting the framing block's `<ABS_ARTIFACT_DIR>` and the recorded jobId). The `--artifact-dir` flag is required — it tells the wrapper where to write its audit row (`<ABS_ARTIFACT_DIR>/.qrspi/audit-codex-review.jsonl`); calling `await` without it exits 1 before any polling. Exit codes: **0** = success, the file now contains the Codex markdown findings; **10** = 20-min ceiling hit (no stdout produced) — write an explicit ceiling note (e.g., `Codex review: 20-min ceiling hit, no findings produced`) to the per-round Codex file, do NOT silently retry; **11** = companion crash mid-job (job-not-found) — write a crash note to the per-round Codex file and surface to the user before proceeding; **12** = audit-write fail (e.g., row > 4096 bytes, or invalid `--artifact-dir`) — write an infrastructure-failure note to the per-round Codex file and surface to the user, do NOT retry blindly. **Main chat does not read the Codex per-round file until apply-fix time** — preserving the disk-write contract's no-finding-text-in-main-chat invariant.

## Multi-template form

This section applies when the framing block declares `<codex_dispatches>` (with one or more `<dispatch>` children, each carrying its own `<output_file>` and stdin-piped prompt) and does NOT declare a top-level `<output_file>`.

For each `<dispatch>` element inside `<codex_dispatches>` above:

1. Assemble that dispatch's prompt per the canonical shape above (the `<dispatch>` element identifies which `agents/qrspi-{name}.md` agent file to concatenate with the protocol).
2. At dispatch time (in parallel with the matching Claude reviewer), pipe the assembled prompt into `scripts/codex-companion-bg.sh launch` as a foreground Bash-tool call. The wrapper prints the jobId to stdout as a single line and exits 0 within ~5 seconds. The orchestrator records the printed jobId under the dispatch's `label` attribute (e.g., jobId-{label}); these labels are orchestrator-note labels, not shell variable names. Shell command substitution (`$()` / backticks) is forbidden per Daniel's CLAUDE.md. If a launch exits non-zero, abort that dispatch's Codex review and write a launch-failure note to its `<output_file>`; the remaining dispatches proceed independently.
3. After the Claude reviewers return, run the matching await for each captured jobId and **redirect each await's stdout directly to that dispatch's `<output_file>`** so finding text never enters main chat: `scripts/codex-companion-bg.sh await --artifact-dir <ABS_ARTIFACT_DIR> <jobId> > <output_file>` (substituting the framing block's `<ABS_ARTIFACT_DIR>` and the matching dispatch's declared path). The `--artifact-dir` flag is required — it tells the wrapper where to write its audit row (`<ABS_ARTIFACT_DIR>/.qrspi/audit-codex-review.jsonl`); calling `await` without it exits 1 before any polling. Per-await exit codes: **0** = success, file contains markdown findings; **10** = 20-min ceiling hit — write an explicit ceiling note to that dispatch's Codex file, do NOT silently retry; **11** = companion crash mid-job — write a crash note and surface to the user; **12** = audit-write fail (e.g., row > 4096 bytes, or invalid `--artifact-dir`) — write an infrastructure-failure note and surface to the user, do NOT retry blindly. Await **all** captured jobIds — do not skip awaits if an earlier one ceilings or crashes; each dispatch's result is recorded independently. **Main chat does not read the Codex per-round files until apply-fix time** — preserving the disk-write contract's no-finding-text-in-main-chat invariant.

<!-- Embedded via: !`cat ${CLAUDE_SKILL_DIR}/../_shared/codex/launch-await-pattern.md` -->
