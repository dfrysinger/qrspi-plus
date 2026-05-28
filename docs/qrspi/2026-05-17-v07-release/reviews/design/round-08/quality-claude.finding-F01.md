---
finding_id: R8-F01
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/design.md:L91, docs/qrspi/2026-05-17-v07-release/research/summary.md:L55]
artifact: design
round: 8
reviewer: quality-claude
---

G2's Recommendation specifies that `scripts/run-third-party-llm.sh` is "parameterized on `--provider`, `--model`, `--prompt-file`, and `--output-file`" and in the next paragraph instructs the design to "Reuse the Codex companion broker pattern for backgrounding long-running prompts." This pairs two facts that research found in direct contradiction.

Per `research/summary.md` Q3 (TL;DR and surprises section, lines 41–72): "The legacy `launch --prompt-file <path>` argument form is retired; `launch` accepts the prompt only on stdin (commit 21/22 of the #110 migration; `codex-companion-bg.sh:6-12, :293-301`). Passing any positional/flag argument exits 1." The Codex broker the design says it is reusing the pattern from explicitly rejects `--prompt-file` and has been hardened to do so.

This leaves a downstream implementer two readings:

1. G2's CLI surface (`--prompt-file`) is intentional and the "reuse" language only applies to the surrounding broker behaviors (backgrounding, exit-code contract, disk-state fallback) — in which case the design is inconsistent with the stdin-only direction the broker pattern was deliberately migrated to, and should explain why the new shim diverges.
2. G2 meant to inherit stdin-only too, and the `--prompt-file` flag is a stale carryover from the pre-#110 pattern.

Either way, Structure/Plan cannot resolve this without picking a direction the design did not commit to. Recommend revising the Recommendation to either (a) drop `--prompt-file` and adopt stdin per the broker pattern, or (b) keep `--prompt-file` and add an explicit rationale paragraph for diverging from the migration the broker just completed.

Also worth noting: the four-flag list omits whether the script reads its API key by name resolution at call time only (the next paragraph says yes — `api_key_env: DEEPSEEK_API_KEY`) but does not specify a flag for selecting which provider entry's `api_key_env` to honor — `--provider` implicitly does this, which is fine but worth confirming in the same revision.
