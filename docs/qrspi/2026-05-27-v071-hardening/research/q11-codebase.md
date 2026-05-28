---
status: draft
question_ids: [11]
research_type: codebase
---

# Q11: `model:` values in `agents/*.md` YAML frontmatter and which dispatching skills/scripts read or act on that field

## Summary

**TL;DR:** Across 41 `agents/*.md` files, three concrete model values (`sonnet`, `haiku`, `opus`) and one sentinel value (`inherit`) are declared. The `model:` field is consumed as the lowest-priority "Layer 3" fallback in a four-layer routing chain documented in `skills/implement/SKILL.md` and `skills/using-qrspi/SKILL.md`; most dispatch sites in the skill files hard-code `model: "sonnet"` inline (Layer 1b), meaning the bundled default is bypassed at those sites. No shell script reads `model:` from agent frontmatter — `run-codex-review.sh` parses only the `skills:` field.

**Key findings:**
- **33 agents** declare `model: sonnet` (all reviewer and analyzer agents except the three exceptions below).
- **5 agents** declare `model: inherit` (`qrspi-implementer`, `qrspi-implementer-lightweight`, `qrspi-research-specialist`, `qrspi-research-collator`, `qrspi-test-writer`) — the Agent call inherits the orchestrator's current model unless overridden.
- **2 agents** declare `model: haiku` (`qrspi-finding-verifier`, `qrspi-scope-tagger`) — designated cheap/fast model for mechanical per-finding scoring and scope tagging.
- **1 agent** declares `model: opus` (`qrspi-replan-analyzer`) — but the dispatch site in `skills/replan/SKILL.md:77` hard-codes `model: "sonnet"`, so the bundled `opus` value is overridden at runtime.
- The agent-bundled `model:` is **Layer 3** (lowest-precedence non-trusted layer) in the routing chain defined at `skills/implement/SKILL.md:524–530`; it is reached only when no per-task override (Layer 1a), no dispatch-site inline override (Layer 1b), and no `model_routing:` table entry (Layer 2) yields a value.
- A `trusted_path:` short-circuit in `config.md` can bypass all four layers and route directly to the agent-bundled default — specifically documented as a protection for safety-critical roles (e.g., finding verifier, security reviewer): `skills/implement/SKILL.md:520`.
- `scripts/run-codex-review.sh` strips agent frontmatter entirely (`strip_frontmatter`); it parses only the `skills:` field from frontmatter and accepts `--model` as an externally-supplied CLI flag (`run-codex-review.sh:99, 180, 445`).

**Surprises:** `qrspi-replan-analyzer` carries `model: opus` in its frontmatter (`agents/qrspi-replan-analyzer.md:4`) but the only dispatch site in `skills/replan/SKILL.md:77` passes `model: "sonnet"` inline, making the bundled `opus` value effectively dead in normal pipeline operation.

**Caveats:** Investigation covered all 41 `agents/*.md` files and the primary skill files (`implement`, `using-qrspi`, `plan`, `replan`, `research`, `design`, `goals`, `parallelize`, `phasing`, `structure`, `questions`, `integrate`, `test`) plus `scripts/run-codex-review.sh` and `scripts/run-third-party-llm.sh`. Template files in `templates/` were not separately scanned for dispatch calls. The `config.md` run-instance file (not a repo-tracked skill) is where the `model_routing:` table and `trusted_path:` entries live at runtime; the actual role-to-model mappings applied depend on operator edits to that file.

## Full findings

### Inventory of `model:` values in `agents/*.md`

All 41 agent files were scanned via `grep -n "^model:" agents/*.md`. Results:

#### `model: sonnet` (33 agents, line 4 in each)
| Agent file | Line |
|---|---|
| `agents/qrspi-code-quality-reviewer.md` | 4 |
| `agents/qrspi-code-simplifier.md` | 4 |
| `agents/qrspi-design-reviewer.md` | 4 |
| `agents/qrspi-design-scope-reviewer.md` | 4 |
| `agents/qrspi-goal-traceability-reviewer.md` | 4 |
| `agents/qrspi-goals-reviewer.md` | 4 |
| `agents/qrspi-goals-scope-reviewer.md` | 4 |
| `agents/qrspi-implement-gate-reviewer.md` | 4 |
| `agents/qrspi-integration-reviewer.md` | 4 |
| `agents/qrspi-parallelize-reviewer.md` | 4 |
| `agents/qrspi-parallelize-scope-reviewer.md` | 4 |
| `agents/qrspi-phasing-reviewer.md` | 4 |
| `agents/qrspi-phasing-scope-reviewer.md` | 4 |
| `agents/qrspi-plan-goal-traceability-reviewer.md` | 4 |
| `agents/qrspi-plan-reviewer.md` | 4 |
| `agents/qrspi-plan-scope-reviewer.md` | 4 |
| `agents/qrspi-plan-security-reviewer.md` | 4 |
| `agents/qrspi-plan-silent-failure-hunter.md` | 4 |
| `agents/qrspi-plan-spec-reviewer.md` | 4 |
| `agents/qrspi-plan-test-coverage-reviewer.md` | 4 |
| `agents/qrspi-questions-reviewer.md` | 4 |
| `agents/qrspi-replan-reviewer.md` | 4 |
| `agents/qrspi-replan-scope-reviewer.md` | 4 |
| `agents/qrspi-research-reviewer.md` | 4 |
| `agents/qrspi-security-integration-reviewer.md` | 4 |
| `agents/qrspi-security-reviewer.md` | 4 |
| `agents/qrspi-silent-failure-hunter.md` | 4 |
| `agents/qrspi-spec-reviewer.md` | 4 |
| `agents/qrspi-structure-reviewer.md` | 4 |
| `agents/qrspi-structure-scope-reviewer.md` | 4 |
| `agents/qrspi-test-coverage-reviewer.md` | 4 |
| `agents/qrspi-type-design-analyzer.md` | 4 |
| `agents/qrspi-visual-fidelity-reviewer.md` | 4 |

#### `model: inherit` (5 agents)
| Agent file | Line | `model_role:` also present |
|---|---|---|
| `agents/qrspi-implementer.md` | 4 | no |
| `agents/qrspi-implementer-lightweight.md` | 4 | yes: `lightweight-implementer` (line 5) |
| `agents/qrspi-research-collator.md` | 4 | yes: `research-collator` (line 5) |
| `agents/qrspi-research-specialist.md` | 4 | yes: `research-specialist` (line 5) |
| `agents/qrspi-test-writer.md` | 4 | yes: `test-writer` (line 5) |

#### `model: haiku` (2 agents)
| Agent file | Line |
|---|---|
| `agents/qrspi-finding-verifier.md` | 3 |
| `agents/qrspi-scope-tagger.md` | 3 |

#### `model: opus` (1 agent)
| Agent file | Line |
|---|---|
| `agents/qrspi-replan-analyzer.md` | 4 |

---

### The four-layer routing chain (`skills/implement/SKILL.md`)

The canonical description of how `model:` is consumed lives at `skills/implement/SKILL.md:518–537` under `§ Per-Task Routing`. Before the Agent call is composed, the dispatcher resolves `(provider, model)` through a strict precedence chain:

**Short-circuit (pre-chain): `trusted_path:` match** (`skills/implement/SKILL.md:520`)  
If the dispatch target matches an entry in `config.md`'s `trusted_path:` block (by agent file path or `model_role:` value), the chain is bypassed entirely and the agent-bundled default (`model:` field from frontmatter) is used. Intended for safety-critical roles (e.g., security reviewer, finding verifier) so they cannot be silently routed to cheap models.

**Layer 1a — per-task spec `model:` override** (`skills/implement/SKILL.md:524`)  
If `tasks/task-NN.md` frontmatter carries a `model:` field, that value wins. Highest-precedence non-trusted layer.

**Layer 1b — hardcoded dispatch-site `model:` override** (`skills/implement/SKILL.md:526`)  
If the `Agent({...})` call at the dispatch site in a skill's SKILL.md includes an inline `model:` argument, that wins. Most dispatch calls in skill files use this mechanism — they hard-code `model: "sonnet"`.

**Layer 2 — `model_routing:` role lookup** (`skills/implement/SKILL.md:528`)  
Reads the agent's `model_role:` frontmatter field, then looks up `config.md`'s `model_routing:` table. Yields `(provider, model)` for the role. This is the operator-tuning surface. Applies only to agents that carry a `model_role:` field in their frontmatter (5 agents: `qrspi-implementer-lightweight`, `qrspi-research-collator`, `qrspi-research-specialist`, `qrspi-test-writer`; `qrspi-implementer` has no `model_role:`).

**Layer 3 — agent-bundled default** (`skills/implement/SKILL.md:530`)  
If all of layers 1a/1b/2 yield nothing, fall back to the agent file's frontmatter `model:` value. Most agents bundle `model: inherit` (implementers, research specialists) so the Agent call inherits the orchestrator's model.

The same four-layer precedence chain is also documented in `skills/using-qrspi/SKILL.md:487–494` from the operator/config perspective, where it references the `model_routing:` block schema at lines `445–470`.

---

### Skill files that dispatch with explicit inline `model:`

Every skill file that dispatches subagents includes an inline `model:` argument in the `Agent({...})` call. This is Layer 1b and overrides the agent's bundled default.

| Skill file | Dispatch call(s) | Inline `model:` value |
|---|---|---|
| `skills/research/SKILL.md:58` | `qrspi-research-specialist` | `"sonnet"` |
| `skills/research/SKILL.md:97` | `qrspi-research-collator` | `"sonnet"` |
| `skills/research/SKILL.md:137` | `qrspi-research-reviewer` | `"sonnet"` |
| `skills/design/SKILL.md:157` | `qrspi-design-reviewer` | `"sonnet"` |
| `skills/design/SKILL.md:169` | `qrspi-design-scope-reviewer` | `"sonnet"` |
| `skills/parallelize/SKILL.md:179` | `qrspi-parallelize-reviewer` | `"sonnet"` |
| `skills/parallelize/SKILL.md:191` | `qrspi-parallelize-scope-reviewer` | `"sonnet"` |
| `skills/test/SKILL.md:92` | `qrspi-test-writer` | resolved per four-layer chain; reads `test_writer_model` from `plan.md` frontmatter |
| `skills/test/SKILL.md:126` | `qrspi-spec-reviewer` | `"sonnet"` |
| `skills/test/SKILL.md:134` | `qrspi-code-quality-reviewer` | `"sonnet"` |
| `skills/test/SKILL.md:142` | `qrspi-goal-traceability-reviewer` | `"sonnet"` |
| `skills/goals/SKILL.md:240` | `qrspi-goals-reviewer` | `"sonnet"` |
| `skills/goals/SKILL.md:250` | `qrspi-goals-scope-reviewer` | `"sonnet"` |
| `skills/integrate/SKILL.md:102` | `qrspi-integration-reviewer` | `"sonnet"` |
| `skills/integrate/SKILL.md:112` | `qrspi-security-integration-reviewer` | `"sonnet"` |
| `skills/plan/SKILL.md:283` | `qrspi-plan-reviewer` | `"sonnet"` |
| `skills/plan/SKILL.md:298–302` | plan artifact reviewers (5 agents) | `"sonnet"` each |
| `skills/plan/SKILL.md:306` | `qrspi-plan-scope-reviewer` | `"sonnet"` |
| `skills/phasing/SKILL.md:112` | `qrspi-phasing-reviewer` | `"sonnet"` |
| `skills/phasing/SKILL.md:126` | `qrspi-phasing-scope-reviewer` | `"sonnet"` |
| `skills/replan/SKILL.md:77` | `qrspi-replan-analyzer` | `"sonnet"` (overrides agent's `model: opus`) |
| `skills/replan/SKILL.md:121` | `qrspi-replan-reviewer` | `"sonnet"` |
| `skills/replan/SKILL.md:132` | `qrspi-replan-scope-reviewer` | `"sonnet"` |
| `skills/structure/SKILL.md:153` | `qrspi-structure-reviewer` | `"sonnet"` |
| `skills/structure/SKILL.md:167` | `qrspi-structure-scope-reviewer` | `"sonnet"` |
| `skills/questions/SKILL.md:83` | `qrspi-questions-reviewer` | `"sonnet"` |
| `skills/implement/SKILL.md:924–934` | per-task reviewers (8 agents) | `"sonnet"` each |
| `skills/implement/SKILL.md:995,1031` | `qrspi-visual-fidelity-reviewer` | `"sonnet"` |
| `skills/implement/SKILL.md:1403` | `qrspi-implement-gate-reviewer` | `"sonnet"` |

**Agents dispatched WITHOUT explicit inline `model:` (rely on agent-bundled default or routing table):**
- `qrspi-finding-verifier` — dispatched via Task syntax in `skills/using-qrspi/SKILL.md:775` and `skills/implement/SKILL.md:819` with no inline `model:` argument; the agent's bundled `model: haiku` therefore applies (or a `trusted_path:` entry if configured).
- `qrspi-scope-tagger` — dispatched via Task syntax in `skills/using-qrspi/SKILL.md:896` and `skills/implement/SKILL.md:1190` with no inline `model:` argument; the agent's bundled `model: haiku` applies.
- `qrspi-implementer` and `qrspi-implementer-lightweight` — the dispatch in `skills/implement/SKILL.md:507, 636` resolves `model` through the full routing chain; the agent's `model: inherit` is Layer 3 (final fallback when no override and no routing table entry exists).

---

### `scripts/run-codex-review.sh` — does NOT read `model:` from frontmatter

`scripts/run-codex-review.sh` is a thin forwarder to `scripts/run-third-party-llm.sh`. It:
1. Parses only the `skills:` field from the agent's frontmatter (`run-codex-review.sh:235–254`) using an awk function `extract_skill_names`.
2. Calls `strip_frontmatter` to remove the entire frontmatter block before including the agent body in the assembled prompt (`run-codex-review.sh:345, 413`).
3. Accepts `--model <codex-model-id>` as a **caller-supplied CLI flag** (`run-codex-review.sh:99`) and forwards it to the dispatcher (`run-codex-review.sh:445`).

The script does **not** read or parse the `model:` value from the agent's YAML frontmatter. The caller must supply the model externally.

`scripts/run-third-party-llm.sh:445–446, 479` similarly accepts `--model` as a required CLI flag and does not read agent frontmatter.

---

### `skills/plan/SKILL.md` — per-task `model:` heuristics and plan frontmatter

`skills/plan/SKILL.md:159–172` defines heuristics for setting the `model:` field in individual `tasks/task-NN.md` frontmatter:
- `task_type == lightweight` → `model: sonnet` (no exception).
- `task_type == code` → `model: opus` if task touches ≥4 files, or adds new types, or has any cross-task dependency; otherwise `model: sonnet`.
- These are defaults; operators may override before plan approval.

`skills/plan/SKILL.md:159` also notes: "Frontmatter-only edits to `agents/*.md` (e.g. flipping a `model:` value) → `lightweight` per the glob — that change has no runtime behavior to TDD against."

`skills/plan/SKILL.md:184` defines a `test_writer_model:` field in the `plan.md` frontmatter (distinct from task-level `model:`); this controls the `qrspi-test-writer` dispatch model in the Test skill.

---

### G5 Initial Routing Matrix (`skills/implement/SKILL.md:543–551`)

The default `model_routing:` table (Layer 2) maps only certain roles — those with `model_role:` frontmatter — to specific providers:

| `model_role:` | Default route | Tier |
|---|---|---|
| `research-collator` | DeepSeek V3 (cheap tier) | cheap-model eligible |
| `lightweight-implementer` | DeepSeek V3 (cheap tier) | cheap-model eligible |
| `research-specialist` | DeepSeek V3, citation-density gated | cheap-model eligible (conditional) |
| general-purpose / Explore agent | Sonnet (Claude) | trusted |

For agents without a `model_role:` in their frontmatter (which is most of the 41 agents), Layer 2 yields nothing and the chain proceeds to Layer 3 (agent-bundled `model:`).
