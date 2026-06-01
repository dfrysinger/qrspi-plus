---
finding_id: R3-F07
reviewer_tag: stitching-audit
severity: medium
change_type: correctness
gap_class: unanswered-question
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/structure.md
  - docs/qrspi/2026-05-30-v072-release/design.md
line_range: [308, 441]
---

# `split_cmd` / splitter interface seam: per-entry command vs. round-dir-only argument

## Gap description

The dispatch manifest (Interface §10, structure.md lines 308–335) stores a `split_cmd` field
per background manifest entry:

```json
"split_cmd": "scripts/third-party-finding-splitter.sh --round-dir /abs/path/reviews/plan/round-01"
```

`await-round.sh` (Interface §15, line 423) calls this command "per resolved entry":
> "invokes split_cmd (third-party-finding-splitter.sh) per resolved entry to materialize
> per-finding files"

The splitter (Interface §16, lines 432–441) accepts only one argument:
```bash
scripts/third-party-finding-splitter.sh --round-dir <abs-round-dir>
```

Its side-effect description (line 439) is:
> "writes `<round-dir>/<tag>.finding-F<NN>.md` for each `<<<FINDING-BOUNDARY>>>` block"

The `<tag>` in the output path implies the splitter is tag-aware, yet the CLI has no
`--tag` argument. There is no `--input-file` argument either. The only way the splitter
can be tag-aware is if it discovers the tag from somewhere inside the round-dir — but no
interface specifies how.

## The seam mismatch

`await-round.sh` calls `split_cmd` once **per resolved entry**. In a round with two
background entries (e.g., `quality-codex` and `quality-gpt`):

1. Entry 1 (`quality-codex`) resolves. `await-round.sh` calls `split_cmd` for entry 1.
   The splitter runs with `--round-dir`; it finds `.dispatch/quality-codex.raw` and
   writes `quality-codex.finding-F01.md`, `quality-codex.finding-F02.md`, etc. ✓

2. Entry 2 (`quality-gpt`) resolves. `await-round.sh` calls `split_cmd` for entry 2.
   The splitter runs with the same `--round-dir` with no per-entry discriminator. What
   does it process? If it re-processes all `.raw` files in the round-dir (including
   `.dispatch/quality-codex.raw`), it double-writes `quality-codex.finding-F*.md` files.
   If it has state (tracks which `.raw` files were already processed), that state mechanism
   is undocumented.

The two interfaces are inconsistent:
- Interface §14/§10: `split_cmd` is a per-entry field with no tag or input-file in the
  command string.
- Interface §15: split_cmd is invoked "per resolved entry."
- Interface §16: the splitter has only `--round-dir` with no per-entry identifier.

Either the "per resolved entry" description in §15 is wrong (the splitter should be called
once at the end of the round, not per entry), or the splitter needs a `--tag` or
`--input-file` argument, or `split_cmd` should include the specific `.raw` file path.

## Why this is an unanswered-question rather than seam-mismatch

The three interfaces together could be internally consistent if the intended semantics are
one of:

(a) **Per-entry, tag-discriminated**: `split_cmd` stored per entry would include
    `--tag quality-codex` but this is not shown in Interface §10's example. The splitter
    would read `<round-dir>/.dispatch/<tag>.raw` and write only that tag's findings.
    This is the cleanest design but requires `--tag` in Interface §16.

(b) **Per-entry, all-unprocessed**: the splitter processes all `.raw` files not yet split
    (using a marker file or inode check). Multiple calls are idempotent because the splitter
    skips already-split files. This requires a documented state-tracking mechanism.

(c) **Round-level, called once**: `await-round.sh` calls `split_cmd` once after **all**
    entries resolve. The "per resolved entry" prose in §15 is incorrect. This would mean
    every entry stores the same `split_cmd` string and only the first invocation runs (or
    await-round.sh deduplicates before calling). This is simpler but contradicts §15's prose.

None of these is currently specified. The gap is real because an implementer of the splitter
cannot determine from Interface §16 alone which semantics to implement, and an implementer
of `await-round.sh` cannot determine from §15 alone whether to call `split_cmd` once or N
times.

## Minimal-altitude fix

Add a clarifying sentence to Interface §16 stating explicitly which of the three semantics
applies. For option (a), also add `[--tag <reviewer-tag>]` to the CLI spec and update the
Interface §10 `split_cmd` example to include `--tag quality-codex`. For option (c), change
§15's "per resolved entry" to "once after all entries resolve."

The `<tag>` in Interface §16's side-effect description (line 439) — `<tag>.finding-F<NN>.md`
— implies option (a) is the intended design (the splitter is tag-aware); the fix would be
to add `--tag` to the Interface §16 CLI spec and to the §10 `split_cmd` example.
