# Design — Altitude Sub-Rule worked examples and elaboration

Optional reading. Read when a borderline design decision needs the worked-example evidence to disambiguate whether a Sub-Rule applies.

## Sub-Rule A — Naming-vs-Layout worked examples

| Permitted (identity) | Not permitted (layout / wiring / signatures) |
|---|---|
| "Rename `foo.sh` → `bar.sh`" | "`bar.sh` lives at `scripts/bar.sh` and sources `lib/baz.sh`" |
| "`prep.sh` is auto-invoked by `bar.sh` when its outputs are absent" | "`bar.sh` calls `prep_if_needed(step, round)` returning `{ref, narrowed}`" |
| "The per-round manifest is `manifest.json`, one entry per dispatched job" | "Manifest schema: `{jobs: [{id: str, tier: str, started_at: int}]}`" |
| "Resolver and host-detect are shared infrastructure" | "`detect_host()` returns one of `claude-code\|codex-cli\|copilot-cli`" |

## Sub-Rule B — Prose-as-Decision

**Scope proportionality.** Verbatim authoring is the default when the prose artifact is small enough for design.md to carry cleanly — paragraph-scale items such as a SKILL.md rule, a frontmatter description, a reviewer directive, or a short rubric. For larger prose artifacts (multi-section skill bodies, multi-page reviewer protocols, lengthy agent instructions), design.md specifies (a) the intent and required behaviors, (b) the structural skeleton, and (c) any **anchor phrases** that MUST be exact — sentences whose wording is load-bearing for LLM behavior (RED FLAG / STOP directives, Iron Rules, "do NOT X" prohibitions, named antagonist behaviors). The full body is authored at Implement against that spec (Plan packages the deferred spec into a task with test expectations that assert intent, skeleton, and anchor-phrase presence). Err toward verbatim when in doubt — small artifacts deserve verbatim treatment; defer only when full inclusion would balloon design.md and lose altitude.

**Default when in doubt.** If the artifact is text an LLM will read as instructions, treat the wording as binding. For paragraph-scale items, author the literal sentence. For multi-section bodies, author the intent + skeleton + anchor phrases per Scope proportionality. "The rule should say X in spirit" is insufficient at any scale — even when deferring the body to Implement, the design.md spec must be precise enough that paraphrase risk is constrained.

**Operational rule for design.md.** When locking a prose-design decision, write the content inside a fenced block or blockquote, marked with a comment naming the target artifact.

For verbatim (paragraph-scale) decisions:

```
<!-- prose-design: <target file> § <section> -->
<verbatim text here>
```

For deferred (multi-section) decisions:

```
<!-- prose-design (deferred to Implement): <target file> § <section> -->
Intent: <one-paragraph behavioral spec>
Skeleton: <ordered list of required subsections>
Anchor phrases (MUST be exact):
  - "<load-bearing sentence 1>"
  - "<load-bearing sentence 2>"
```

Downstream readers handle both: verbatim blocks → exact-copy contracts (Implement copies through without paraphrase); deferred blocks → intent + skeleton + anchor-phrase contracts (Plan packages into a task with test expectations; Implement authors the full body against the spec). In both cases anchor phrases are exact-copy.

**Worked examples:**

| Artifact | Altitude content | Sub-rule | Form |
|---|---|---|---|
| Shell script identity (rename + behavior) | Name + purpose + behavior; no function signatures | A | — |
| Skill prose rule (e.g., a Dialogue Conduct rule) | Verbatim wording inside a marked block | B | Verbatim |
| Reviewer protocol rubric (e.g., change-type classifier) | Verbatim rubric text | B | Verbatim |
| Data-contract artifact identity (e.g., JSON manifest) | Name + purpose + necessary fields; no schema layout | A | — |
| Subagent frontmatter description | Verbatim description text | B | Verbatim |
| Routing matrix / lookup table | Verbatim table | B | Verbatim |
| Multi-section SKILL.md body (e.g., a new skill's full body) | Intent + section skeleton + anchor phrases | B | Deferred → Implement |
| Lengthy reviewer-protocol body (multi-section) | Intent + skeleton + anchor phrases | B | Deferred → Implement |

## Sub-Rule C — End-to-End Flow worked examples

**Worked example — failure pattern (components without flow).** A design names three actors — a controller, several worker subagents, a shared output directory — and a goal: collect results from all workers. The design specifies the actors and the goal but not the choreography: how the controller invokes each worker, what each worker is told about where to write, how the controller knows all workers are done, what happens if one worker writes nothing. The result is downstream guessing — Structure invents an invocation contract that doesn't match Plan's task ordering, Implement ships a polling loop the design never authorized, and a worker silently producing no output is missed entirely until Test.

**Worked example — same decision after applying Sub-Rule C.** The design specifies the choreography. The controller writes per-worker inputs to deterministic paths under the shared directory. It invokes the N workers in parallel in a single batched call, passing each worker the path it should read and the path it should write. Each worker reads its input, processes, writes its output to its assigned path. The controller waits for all worker calls to return, then enumerates the shared directory; any expected output that is missing or empty triggers a loud failure citing the missing worker by name. Every actor named, every step ordered, every input and output traced to its producer and consumer, the controller-context-cost call-out present (worker outputs stay on disk; only the consolidated summary enters the controller's window).

**Mermaid flow diagrams.** When the end-to-end flow involves three or more actors with non-trivial sequencing, the per-goal block SHOULD include a Mermaid sequence diagram (or flowchart for branch-heavy flows). The diagram is a load-bearing artifact, not decoration — readers (Structure, Plan, Implement) inspect it before reading the prose. Diagrams are mandatory when the flow:
- crosses the orchestrator/subagent boundary (LLM tool-call boundary)
- involves parallel fan-out followed by wait-all (or other non-linear control flow)
- has loud-failure paths whose detection is across-actor

Per-goal blocks with single-actor or two-actor flows MAY omit the diagram if the prose specification is unambiguous.

**Scope clarification.** Sub-Rule C does NOT push Design into pseudocode (Sub-Rule A still forbids function signatures) or into specifying the per-actor implementation (each actor's internals are owned by Structure for code or Plan for tasks). C specifies the **inter-actor contract**: the shape of each hand-off, the order of operations, the trace from input to output to consumer. Structure and Plan author the internals; Design owns the choreography.

## Sub-Rule D — External-Knowledge Completeness worked examples

**Worked example — failure pattern (deferred external knowledge).** A design decision says "the orchestrator detects auto-mode via a host-specific signal (see vendor docs for the exact mechanism)." Structure maps the work to a script. Plan authors tasks that consume the detection. The implementer reads the design, finds no concrete signal name, guesses (env var name, system-reminder string), and ships a script that fails to detect anything on real sessions. The bug surfaces at Test or in production. The root cause is design-time external-knowledge deferral.

**Worked example — same decision after applying Sub-Rule D.** The design enumerates supported hosts as locked claims. For each host, the design block names the exact detection signal with citation and verification method. Example: for host A: "`## Auto Mode Active` system-reminder block; verified via plugin skill citation X (docs-only, stable source)". For host B: "the host's autopilot-state context tag and its body sentinel sentence (exact literals captured in `scripts/detect-interaction-mode.sh` — kept out of this prose so the regression-grep in `tests/unit/test-detect-interaction-mode.bats` can fence them to the script and its fixture); verified via direct toggle-and-observe on CLI version Z dated 2026-05-31 (docs would have produced the wrong answer)". Unsupported hosts get an explicit unknown branch: "host not yet supported — safe default `interactive` — verification procedure: at host-addition time, toggle the host's auto-mode CLI affordance and observe context for any new tag/marker/sentence; document observation in script header." The implementer reads the block, writes the script branches, and ships working detection on day one. No external research, no guessing, no Test-time surprises.

**Scope clarification.** Sub-Rule D does NOT require Design to restate common-knowledge programming patterns or ordinary tool usage. It targets specifically **claims about external systems whose behavior the implementer cannot verify by reading project code or relying on general programming knowledge**. "We use `git diff` to compare commits" is not a Sub-Rule D claim (basic tool usage). "Vendor X's webhook fires on event Y with payload shape Z" is a Sub-Rule D claim (external-contract specifics). When in doubt, ask: "could a competent implementer answer this from project code + their own knowledge?" If no, Sub-Rule D applies.
