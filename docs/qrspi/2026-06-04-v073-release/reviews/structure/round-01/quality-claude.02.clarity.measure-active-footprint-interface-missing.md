---
reviewer: quality-claude
artifact: structure
change_type: clarity
severity: nonblocking
---

# `scripts/measure-active-footprint.sh` interface unspecified despite serving as G9's final acceptance-gate evidence

## Where

- `structure.md` § File Map → G9 row for `scripts/measure-active-footprint.sh`:
  > "Use a deterministic tokenizer (tiktoken or host tokenizer) to compute per-turn footprint = `using-qrspi/SKILL.md` + heaviest active skill + `!cat`-ed shared snippets; print the count and exit 0."
- `structure.md` § File Map → G9 row for `docs/qrspi/2026-06-04-v073-release/g9-footprint-report.md`:
  > "Captured output of `scripts/measure-active-footprint.sh` against the trimmed tree. Final acceptance gate evidence."
- `structure.md` § Test Architecture → G9 acceptance under T3:
  > "`scripts/measure-active-footprint.sh` against the trimmed tree records < 30K tokens for a typical session"
- `structure.md` § Interfaces — **no entry** for `measure-active-footprint.sh`.

## What is wrong

Every other new script in the v0.7.3 surface — `upstream-paths.sh`, `review-prep.sh`, `design-absorption-markers.sh`, `orchestration-boundary-check.sh`, `validate-stage-commit-parents.sh`, plus the dispatch-agent high-level mode and the `VERSION` data file — gets a full Interfaces block: usage line, flags, env, stdout shape, exit codes, side effects, rationale notes where they aren't obvious. `measure-active-footprint.sh` gets one File Map sentence and that is it.

That sentence under-specifies the contract enough that two readers can build mutually-incompatible scripts:

- **Input surface.** "Per-turn footprint = `using-qrspi/SKILL.md` + heaviest active skill + `!cat`-ed shared snippets" describes the conceptual calculation, not the CLI input. Does the script take `--skill <name>` to measure one specific skill? Does it iterate over all SKILL.md files automatically and report the max? Does the caller pass a list? What determines "heaviest" — line count, byte count, token count itself?
- **`!cat` resolution.** The footprint formula includes "`!cat`-ed shared snippets." The script must therefore parse SKILL.md bodies for `!cat skills/_shared/<topic>.md` references and resolve them transitively. That parsing logic is non-trivial and is the load-bearing part of "deterministic" measurement — it isn't named.
- **Tokenizer selection.** "tiktoken or host tokenizer" is presented as either-or. Tokenizer choice changes the count by 10–20% on typical SKILL prose; G9's acceptance gate is "< 30K tokens" — a hard numeric threshold whose pass/fail depends on tokenizer choice. Either pin the tokenizer in the interface, or document that the threshold is tokenizer-relative and `g9-footprint-report.md` must record which one was used.
- **Output format.** "Print the count and exit 0" — one number to stdout? Or a per-skill breakdown the report file then quotes? `g9-footprint-report.md` is "captured output," which implies the script's stdout is meant to be the report body, not just a single integer.
- **Exit codes.** "Exit 0" is the success path. What about: tokenizer not installed; `!cat` reference resolves to a missing file (Pass-1 trim broke a snippet path); SKILL.md not found. Other scripts' interfaces enumerate non-zero codes for these.

## Why it matters

This script is **the G9 acceptance-gate evidence producer**. Goals.md, design.md G9 acceptance, and Structure's T3 cross-cutting invariants all rely on its output as the load-bearing measurement of whether v0.7.3's central correctness goal landed. Under-specifying the script that produces the acceptance number leaves room for the implementer to ship a measurement whose result the reviewer cannot reproduce — exactly the "silent clean for the wrong reason" failure shape G6 and G7 exist to prevent on the round-mechanics surface.

The Interfaces section is also doing real work for the other scripts: it pins the contract Plan-time implementers and reviewers both read. The reader of Structure has every reason to expect a measurement-script-shaped contract here too, and its absence reads as oversight.

## What to fix

Add an Interfaces entry for `scripts/measure-active-footprint.sh` matching the shape of the other script blocks. Minimum content:

- **Usage line** including any `--skill <name>` / `--all` / `--snippet-resolve` flags.
- **Tokenizer pinned** — name the specific tokenizer (e.g., "tiktoken cl100k_base") OR document that tokenizer name is a `--tokenizer <name>` flag whose value is recorded in `g9-footprint-report.md` for replay.
- **Stdout shape** — single integer? Per-skill breakdown table? Whatever shape the report file is supposed to capture.
- **Exit codes** — at minimum success (0), tokenizer-missing, snippet-unresolvable, skill-not-found.
- **`!cat` resolution semantics** — does the script follow `!cat` references transitively, and what does it do on a broken reference?

Length comparable to the other interface blocks (≈15–25 lines). Resolves the ambiguity at the moment the implementer writes the script, not three rounds into G9.
