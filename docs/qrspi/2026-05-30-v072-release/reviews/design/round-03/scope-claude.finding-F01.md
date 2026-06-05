---
finding_id: R3-F01
severity: low
change_type: scope
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/design.md:L1042-L1075
  - docs/qrspi/2026-05-30-v072-release/design.md:L63-L90
  - docs/qrspi/2026-05-30-v072-release/design.md:L96-L100
  - docs/qrspi/2026-05-30-v072-release/design.md:L461-L488
artifact: design
round: 3
reviewer: scope-claude
---

**Drift category — line-by-line procedural logic and full function/flag signatures (installed v0.7.1 OWNS/DEFERS).** The installed contract DEFERS "Full function signatures with parameter types and return types" and "Line-by-line logic (procedural pseudocode, control-flow detail)" to Structure / Plan / Implement. Several sites in the artifact cross that line under the installed (not G34-amended) contract.

**Concrete sites.**

- **G4 round-prepare.sh body (L1042-1075).** A literal bash script body is authored inside the design block — `if [[ -z "$IMPLEMENTER_COMMIT" ]]; then`, `git -C "<worktree-path>" rev-parse HEAD`, `ACTUAL_HEAD=$(git ...)`, exit codes `10/11/12`, and per-branch stderr message bodies. This is control-flow detail at Implement altitude (procedural pseudocode with conditionals, variable assignments, and literal echoed strings), not the "shape of the inter-actor contract" that Sub-Rule C calls for. Even the exit-code recovery table at L1078-1092 spells out the per-exit recovery prose verbatim.
- **CD-1 #3 `scripts/dispatch-agent.sh` invocation spec (L63-90).** The flag list is spelled out with parameter typing — `--step <step>`, `--round <N>`, `--output-dir <round-dir>`, `--artifact <artifact-name>`, `--agents tag1=agent-name-1,tag2=agent-name-2,...`, `--task-branch <worktree-path> --implementer-commit <40-char-SHA>`, `--tier-override tag1=high,tag2=medium,...` — and the per-flag behavior block enumerates lifecycle, output-format, and per-pair routing logic at a level the installed DEFERS list assigns to Plan / Implement. The "Spec line format" callout at L89 (`shell-style KEY=VALUE pairs, space-separated, one line per dispatch, no quoting`) is a wire-format spec belonging to Structure.
- **CD-1 #4 `await-round.sh` (L96-100).** Same shape — full invocation surface with `--round-dir` parameter typing and per-line behavior contract.
- **CD-4 verifier-fanout script-behavior block (L461-488).** Numbered procedure of what the script does internally — globs filename pattern, derives tag from filename, resolves tier→vendor→model, builds PROMPT_FILE at a specific path, etc. Reads as a script-implementation outline, not an inter-actor contract.

**Why this matters under the installed contract.** "Full function signatures" + "line-by-line logic" are deferred because Structure authors the file map and Plan/Implement author the per-task surface; design.md committing the script body forecloses those downstream authoring decisions. The Altitude Sub-Rule A worked-example column ("Not permitted: layout / wiring / signatures") at L803-806 in this same artifact reinforces the principle — the design's own altitude rule sits adjacent to content that crosses the line.

**Note on G34's proposed loosening (advisory, NOT applied to this finding).** G34 (this artifact, L2887-2895) proposes adding to Design OWNS: "detailed descriptions of the solutions with full edge cases, end-to-end flows specifying actor sequence and per-step inputs/outputs, prompt-writing specifics" — which would arguably bless CD-1 #3's flag-spec block. G34 D3 still DEFERS "Executable shell beyond a few illustrative lines (a 2-3 line block illustrating shape is fine; a 20-line script body is not)" — which would still flag G4 L1042-1075's ~30-line script body. So even under the proposed loosening, the G4 round-prepare.sh body remains drift; the CD-1/CD-4 invocation specs are blessed.

**Recommended disposition.** Operator override at human gate per PI-HKP-005 (captured pattern). If the operator wishes to bring the G4 round-prepare.sh body back into altitude even under G34, replace the literal shell block with a 3-bullet behavior spec naming the three checks (within-round equality, across-rounds advance, missing-flag), their exit codes, and the recovery action — defer the literal `if/then/else` shell to Implement against a documented `block-hash`-style contract. The exit-code recovery table at L1078-1092 already carries the contract value; the script body itself can be reduced to a pointer at that table.
