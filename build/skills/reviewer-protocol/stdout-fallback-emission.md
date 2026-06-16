# Stdout-Fallback Emission Contract

**This section overrides the upstream "Per-Finding Disk-Write Contract" and any "use the Write tool" instruction in the agent body above — WHEN THE WRITE TOOL IS UNAVAILABLE OR UNAUTHORIZED.** A reviewer subagent that cannot write per-finding files to disk (Codex read-only sandbox; a Copilot CLI Task subagent whose allowed-tools allowlist denies disk writes; or any future host that withholds the Write capability) must still emit findings — via stdout, in the format below — so the orchestrator can materialize them via the stdout-fallback path in `scripts/await-round.sh`.

Reviewers that DO have a working Write tool should follow the upstream disk-write contract instead. The stdout-fallback path is a safety net, not a default: writing per-finding files directly is more efficient and avoids round-tripping the payload through the orchestrator's context.

## When to use this fallback

Use the stdout-fallback emission contract when ANY of the following applies:

- You are running as a Codex reviewer (read-only filesystem sandbox blocks every Write).
- The Write/Create/Edit tools are absent from your allowed-tools (Copilot CLI Task subagents inherit only the tools their `allowed-tools` frontmatter declares).
- Your first attempt to Write a finding fails with a permission or sandbox error.

If your Write tool works, follow the upstream Per-Finding Disk-Write Contract instead and do NOT emit to stdout.

## Emission format

- For each finding, print exactly the literal line `<<<FINDING-BOUNDARY>>>` on its own line, then the YAML+body shape from the Per-Finding Disk-Write Contract's "Per-finding file format" (4 schema fields + 3 audit fields, then the prose `message` body). One finding per block — never combine.
- For zero findings, print exactly the single literal line `NO_FINDINGS` on its own line. Nothing else: no boundary, no frontmatter, no commentary, no five-line brief-return shape.

No prose outside finding bodies. No preamble. No summary. No closing notes. Anything that is neither boundary-prefixed nor the `NO_FINDINGS` sentinel is malformed and produces zero finding files for your tag.

The orchestrator captures your stdout return value to `<round-dir>/.dispatch/<tag>.raw` and `scripts/await-round.sh` runs `scripts/third-party-finding-splitter.sh` on it, materializing per-finding files (`<reviewer_tag>.finding-F<NN>.md`) or the clean sentinel (`<reviewer_tag>.clean.md`) under `reviews/{step}/round-NN/`. The on-disk schema is identical to what a direct-Write reviewer would have produced; the only difference is who performs the Write.

Once you have emitted the last finding (or the `NO_FINDINGS` sentinel), terminate. Your job ends at stdout emission.

## Worked example — one finding

```
<<<FINDING-BOUNDARY>>>
---
finding_id: R3-F01
severity: high
change_type: correctness
referenced_files: [skills/design/SKILL.md:L120-L134]
artifact: design
round: 3
reviewer: quality-codex
---

The artifact's "Default action" sentence contradicts the change-type classifier in `skills/reviewer-protocol/SKILL.md` (which lists `style|clarity|correctness` as auto-apply and `scope|intent` as pause). Fix: rewrite the sentence to cite the classifier verbatim.
```

## Worked example — zero findings

```
NO_FINDINGS
```

Exactly that text on a single line. Nothing else.
