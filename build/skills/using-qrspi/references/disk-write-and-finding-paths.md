**Disk-write contract (artifact-level reviews).** Each artifact-level reviewer subagent writes its findings directly to disk and returns only a brief structured summary to main chat. Main chat never receives finding text in subagent return values. This keeps reviewer output out of main chat's conversation history (where it would re-bill as cache reads on every subsequent turn) until main chat explicitly reads the file to apply fixes — at which point the standard `/compact` after fix-apply (see "Compaction at Step Transitions" + per-skill apply-fix recommendations) sheds it.

**Per-finding file paths.** Each reviewer writes one file per finding into a per-round directory under `reviews/{step}/`:

- Claude reviewer subagent → `reviews/{step}/round-NN/<reviewer_tag>.finding-F<NN>.md` (one file per finding; `<reviewer_tag>` is e.g. `quality-claude`, `scope-claude`)
- Claude scope-reviewer subagent → `reviews/{step}/round-NN/<reviewer_tag>.finding-F<NN>.md` (same shape; dedicated `qrspi-{name}-scope-reviewer` agents)
- Second-model reviewer (async) → `reviews/{step}/round-NN/<reviewer_tag>.finding-F<NN>.md` (filled per the `## Per-Finding Disk-Write Contract` from the reviewer-protocol skill; transport mechanics owned by `scripts/await-round.sh` and `scripts/codex-companion-bg.sh`)
- Clean-round sentinel → `reviews/{step}/round-NN/<reviewer_tag>.clean.md` (one file per reviewer when zero findings)
- Main chat fix-apply summary → `reviews/{step}/round-NN-dispositions.md`

`{step}` is the canonical step name (e.g. `goals`, `design`, `plan`, `replan`). `NN` is the zero-padded round number. Per-reviewer parallelism is preserved: each reviewer writes its own files into the shared round directory, and per-finding filenames are unique by reviewer tag + finding number so concurrent reviewers never race on the same file.

**Per-finding file format.** Each finding file conforms to the 5-field schema defined in the `## Per-Finding Disk-Write Contract` from the reviewer-protocol skill. The finding-file format, clean-file format, and sidecar (`.score.md`) format are specified there; this skill defers to that contract rather than re-enumerating.
