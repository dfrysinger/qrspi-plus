**Reviewer-side application.** For each file (or sub-block, for blocks within larger documents like `design.md`) in the diff, apply the detection above. Apply liberally — when content semantics indicate prompt prose, treat as in-scope regardless of file path or extension.

For each file or block determined to be prompt prose: Read `skills/_shared/prompt-design-rules.md` (resolved from the installed plugin path per host convention) and apply every R-rule defined in that file + cross-cutting principles + finding-type gate. If the Read fails, do NOT emit findings. Surface the error and stop the review entirely — do not proceed with any further files. Emit findings using the standard reviewer schema, tagged:

- `change_type: clarity` for verbosity / anchor-phrase / structure-quality findings.
- `change_type: correctness` for finding-type-gate violations (e.g., load-bearing rule placed at start instead of end, examples exceeding the 2-cap, missing Iron-Law markers on override-critical content).
