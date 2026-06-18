### Default routing matrix (agent-class → default tier band)

The `model_routing:` block in `config.md` maps tier names (`cheap`, `medium`, `trusted`, `high`) to concrete `(provider, model)` pairs. Every QRSPI subagent class binds to a default tier band; operators may override per-run by editing `config.md` without code changes.

| Agent class                         | Default tier band                | Rationale |
|-------------------------------------|----------------------------------|----------------------------------------|
| `qrspi-research-collator`           | cheap (eligible)                 | Mechanical verbatim extraction; no synthesis. Cheap is sufficient — per-collation cost dominates Wave fan-out at scale. |
| `qrspi-implementer-lightweight`     | cheap (eligible)                 | Single-pass execution of well-specified lightweight tasks. Reviewer fan-out catches drift; routing the implementer to cheap saves dominant Wave token cost. |
| `qrspi-research-specialist`         | cheap (eligible, conditional)    | Question-scoped research with structured output. Cheap is sufficient WHEN citation density meets the floor; below-floor output triggers one re-run on the trusted-tier route. See `skills/research/SKILL.md` § Citation-Density Post-Validation Hook. |
| general-purpose / Explore agent     | trusted                          | General-purpose exploration that may surface ambiguous findings; cheap-tier misreads here propagate through every downstream consumer. Stay trusted. |
| `qrspi-test-writer`                 | trusted                          | Test authoring is high-leverage — a bad test pins a wrong contract. Stay trusted; cost is dominated by reviewer fan-out, not test-writer dispatches. |

The matrix is observable via `test-routing-matrix-application.bats`. Concrete `(provider, model)` resolution is `config.md`-owned — operator-edited `model_routing:` entries override the defaults without code changes.
