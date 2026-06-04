# Codex Emission Override

**This section overrides the upstream "Per-Finding Disk-Write Contract" (in the reviewer-protocol body above) and any "use the Write tool" instruction in the agent body above — FOR CODEX REVIEWERS ONLY.** You are running as a Codex reviewer with a read-only filesystem sandbox. You cannot Write files to disk — the sandbox blocks every write. Do NOT call the Write tool; if you try, the sandbox blocks it, the orchestrator sees zero output for your tag, and the schema-violation guard at apply-fix step 2 fires.

Instead, emit your findings to **stdout only**, in this format:

- For each finding, print exactly the literal line `<<<FINDING-BOUNDARY>>>` on its own line, then the YAML+body shape from the Per-Finding Disk-Write Contract's "Per-finding file format" (4 schema fields + 3 audit fields, then the prose `message` body). One finding per block — never combine.
- For zero findings, print exactly the single literal line `NO_FINDINGS` on its own line. Nothing else: no boundary, no frontmatter, no commentary, no five-line brief-return shape.

No prose outside finding bodies. No preamble. No summary. No closing notes. Anything that is neither boundary-prefixed nor the `NO_FINDINGS` sentinel is malformed and produces zero finding files for your tag.

The orchestrator pipes your stdout through `scripts/codex-finding-splitter.sh`, which materializes the per-finding files (`<reviewer_tag>.finding-F<NN>.md`) or the clean sentinel (`<reviewer_tag>.clean.md`) under `reviews/{step}/round-NN/` on your behalf. The on-disk schema is identical to what a Claude reviewer would have written; the only difference is who performs the Write.

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
