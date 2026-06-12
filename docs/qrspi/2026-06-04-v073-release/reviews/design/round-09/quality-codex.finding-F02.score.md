---
verifier_status: passed
score: 60
actual_model: unknown
defect_class: inconsistent-spec
---
Cite check passes. design.md L246-250 (Solution) says the script reads `pipeline:` from `<artifact-dir>/config.md` and is invoked with `--artifact-dir`. Acceptance bullets at L263-265 indeed write `scripts/upstream-paths.sh --step plan` without showing the `--artifact-dir` argument despite the bullets explicitly referring to "a fixture artifact-dir with `pipeline: full` config" etc. The inconsistency is real: the CLI snippets omit the flag the same paragraphs say is required.

It's a small-surface documentation tightening — a competent implementer reading the surrounding prose would supply `--artifact-dir` — but the acceptance bullets are the spec the bats coverage will be written from, so getting them precise matters. Real, modest impact.
