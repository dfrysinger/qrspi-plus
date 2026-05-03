# Questions review

## Round 1 — Claude

Verdict: **NEEDS-FIXES** (14 findings — pervasive goal-leakage via over-specification of candidate solutions and exact taxonomies).

### High

- **R1-F01** (high, intent) — Q4 reveals G3's exact problem framing and target solution by citing "the specific failure mode when a non-namespaced ref blocks creation of a namespaced child" + "conventional patterns teams use to reserve a namespace (e.g., `foo/main` + `foo/*`)". Reframe as a generic question about git ref hierarchy rules and conventions for nesting refs under shared prefixes, without naming the failure mode or reservation pattern as the answer. referenced_files: [questions.md, goals.md]
- **R1-F02** (high, intent) — Q3 enumerates `qrspi/{slug}/main`, `qrspi/{slug}/task-NN`, `qrspi/{slug}/stage-after-G{N}` as the things to find — telling the researcher both the desired namespace and that propagating it is the work. Reframe to ask neutrally what feature-branch and worktree-branch naming conventions appear across the skill prompts today, without listing the target shape. referenced_files: [questions.md, goals.md]
- **R1-F03** (high, intent) — Q8 enumerates exactly G5's three candidate strategies ("env-var-with-fail-loud, glob-resolution under `${HOME}` (latest-wins semantics), and plugin-manifest discovery"). Reframe as an open question about portable patterns for resolving external helper paths in shell/plugin tooling, letting the researcher surface options. referenced_files: [questions.md, goals.md]
- **R1-F04** (high, intent) — Q11 names G7 Candidate A's specific config knobs (`sandbox.filesystem.allowWrite` "configured per dispatch", `sandbox.allowUnsandboxedCommands` interaction with `dangerouslyDisableSandbox`). Reframe to ask broadly what the native sandbox covers per platform/per tool and what configuration surface it exposes, without pre-naming the config keys we intend to set. referenced_files: [questions.md, goals.md]
- **R1-F05** (high, intent) — Q13 quotes G8 Candidate E's grep patterns verbatim (`**G\d{2}**`, `**M\d{2}**`, `**U\d+**`, `F-\d+`, `T\d+`, `#\d+`). Reframe to ask where internal-to-the-methodology identifiers and external tracker references appear across implementer prompts, templates, and commit-message guidance — described conceptually rather than as regex. referenced_files: [questions.md, goals.md]
- **R1-F06** (high, intent) — Q20 lists "intent / non-obvious constraints / tradeoffs / pointers to context / surprises" — the exact taxonomy G11 Candidate A proposes. Reframe as an open question asking what taxonomies and good/bad pairings the WHY-not-WHAT commenting consensus uses across mainstream sources, without prescribing the categories. referenced_files: [questions.md, goals.md]

### Medium

- **R1-F07** (medium, intent) — Q9's tail "identify which computations are derived from filesystem layout vs. genuinely require persisted state" reveals G6's maximum-landing hypothesis (state.sh removability via filesystem-derived computations). Reframe to ask only what state.sh does, who calls it, what it persists. referenced_files: [questions.md, goals.md]
- **R1-F08** (medium, intent) — Q12 enumerates exactly the bypass classes G7 already discovered round-by-round (eval, source, ANSI-C, pushd/popd, cd -, here-strings, command substitution, variable expansion). Reframe to ask broadly what the documented limits and bypass classes of regex/lexer-based shell-command parsing are. referenced_files: [questions.md, goals.md]
- **R1-F09** (medium, intent) — Q18 prescribes G10 Candidate A's exact summary shape ("TL;DR, key findings, surprises, caveats"). Reframe to ask what shapes source-authored summary blocks take across prior art and what tradeoffs apply, without listing the four-section taxonomy. referenced_files: [questions.md, goals.md]
- **R1-F10** (medium, intent) — Q21 categorizes by "exact-string matches vs. structural assertions vs. behavior-based assertions" — exactly G12's brittleness axis. Reframe to ask researchers to characterize the corpus by what it asserts against and what it protects, without seeding the brittleness frame. referenced_files: [questions.md, goals.md]
- **R1-F11** (medium, intent) — Q16 asks "how they handle misclassification override paths" — directly mirrors G9's open design question. Reframe to ask broadly how prior-art systems classify task types and what governance/correction patterns they document. referenced_files: [questions.md, goals.md]
- **R1-F12** (medium, scope) — No question covers G2's reviewer-perspective separation in templates. Add a [codebase] question on where reviewer-perspective separation (or its absence) is asserted in implementer/reviewer/per-task-orchestrator templates today. referenced_files: [questions.md, goals.md]

### Low

- **R1-F13** (low, clarity) — Q6's "where does the review text live in each" mildly presupposes locating review-text fields is a problem. Soften to "what do the response payloads contain" or "what fields are present". referenced_files: [questions.md, goals.md]
- **R1-F14** (low, clarity) — Q10 over-specifies by enumerating "cd-before-relative-write, opaque-interpreter detection, audit logging" as `bash-detect.sh`'s enforcement classes. Drop the parenthetical and let the researcher characterize from primary sources. referenced_files: [questions.md, goals.md]

## Round 1 — Codex

Verdict: **NEEDS-FIXES** (4 findings, broadly aligned with Claude's findings).

> Note: Codex companion exited 12 (audit-write fail) due to a stale `state.json.artifact_dir` pointing at a previous run's path. The review STDOUT was emitted before the audit failure and is captured below; the failure was infrastructure (audit log row write), not a review-content failure.

- **R1-F01** (high, correctness) — Questions 3, 13, 15, 16, 20, 21, 22 leak the intended fixes from goals.md. A researcher reading only questions.md can infer the target branch model, the ID-leakage concern, the planned non-TDD path, the desired WHY-not-WHAT commenting rule, and the brittle prompt-test concern. Rewrite to neutral fact-finding prompts that describe the current system or external prior art without naming the intended remedy or defect framing. referenced_files: [questions.md, goals.md]
- **R1-F02** (high, correctness) — Q8, Q20, Q22 are framed around recommendations or pre-defined solution spaces. Q8 preloads candidate resolution strategies; Q20 and Q22 ask for evidence in service of a preferred rule or mitigation. Recast to ask what practices exist, how they vary, and where they are used, without presupposing options to evaluate or the conclusion to support. referenced_files: [questions.md]
- **R1-F03** (high, correctness) — Q21 bakes the defect claim "exact-string brittleness" into the artifact. Replace with neutral characterization criteria (assertion style, coupling level, failure sensitivity); let research determine whether brittleness is present. referenced_files: [questions.md, goals.md]
- **R1-F04** (medium, correctness) — Q6 is tagged `[codebase]` but asks about the real `codex-companion.mjs` which is not clearly limited to the qrspi-plus repo. Split into a repo-local wrapper question + an external companion-behavior question, or retag so the research method matches the source. referenced_files: [questions.md]

## Post-review fixes (round 1)

Re-generated questions.md from scratch. All 14 (Claude) + 4 (Codex) findings addressed:

1. Q3 reframed — branch namespace enumeration removed.
2. Q4 reframed — failure-mode framing + reservation-pattern example removed.
3. Q6 split — repo-local wrapper question (Q6 about `CODEX_COMPANION` wiring) + external companion-behavior question (Q7 about JSON response shape).
4. Q8 reframed — three resolution strategies de-enumerated.
5. Q9 reframed — derivability frame ("filesystem layout vs. genuinely require persisted state") dropped.
6. Q10 reframed — `bash-detect.sh` enforcement-class enumeration dropped.
7. Q11 reframed — specific sandbox config keys dropped.
8. Q12 reframed — bypass-class enumeration dropped.
9. Q13 reframed — regex patterns dropped, surfaces described conceptually.
10. Q15 reframed — "task-type or lightweight-path branching" removed.
11. Q16 reframed — "misclassification override paths" dropped.
12. Q18 reframed — TL;DR/key findings/surprises/caveats taxonomy dropped.
13. Q20 reframed — intent/constraints/tradeoffs/pointers/surprises taxonomy dropped.
14. Q21 reframed — exact-string vs structural vs behavior axis dropped.
15. Q22 reframed — "without exact-string brittleness" defect-claim dropped.
16. R1-F12 coverage gap closed — added Q25 (reviewer-perspective separation in templates) plus Q26 (role assignment in dispatch chain), Q27 (research→design info transfer), Q28 (CI gating).

Total: 28 neutral, fact-finding questions (round 1: 24 → round 2: 28).

## Round 2 — Claude

Verdict: **APPROVE-WITH-MINOR-FIXES** (4 low-severity intent findings — residual axis-loading).

- **R2-F01** (low, intent) — Q3 enumerates the exact six-section inventory ("Branch Model sections, symbolic vocab tables, Worked Examples, Runtime Resolution sections, Merge Strategy guidance, and Code Review Checkpoint diff commands") that mirrors G3's "What we know so far" surface list. Reframe to ask where in the skill prompts branch-naming conventions are referenced, without pre-listing the section taxonomy. referenced_files: [questions.md, goals.md]
- **R2-F02** (low, intent) — Q16's parenthetical "(e.g., separating runtime-behavior changes from text/config changes)" narrowly previews G9's exact discriminator axis. Generalize to "along any axis". referenced_files: [questions.md, goals.md]
- **R2-F03** (low, intent) — Q21's framing "what coupling each category has to specific prompt/template wording versus to runtime behavior" still loads the brittleness axis. Recast to characterize each category by what it asserts against and what regression class it protects. referenced_files: [questions.md, goals.md]
- **R2-F04** (low, intent) — Q27 frames the prior-art question as "read-on-demand versus pre-summarized information flow," which is exactly G10's binary candidate axis. Reframe as an open question about how published agentic-development frameworks structure information flow between research and design stages, without pre-naming the two endpoints. referenced_files: [questions.md, goals.md]

Pass A: all 14 round-1 fixes verified landed, including the new Q25 closing R1-F12. Goal-zone coverage intact across all 12 goals.

## Round 2 — Codex

Verdict: **NEEDS-FIXES** (4 findings, broadly aligned with Claude's round-2 findings + 2 new).

> Note: Codex companion exited 12 again (audit-write fail — same stale state.json infrastructure issue as round 1). Review STDOUT was emitted before the audit failure and is captured below.

- **R2-F01** (high, intent) — Q20 names the target doctrine directly: "WHY-not-WHAT commenting consensus." A researcher reading only questions.md can infer the artifact is trying to validate or install that specific commenting stance. Rephrase generically without foregrounding the desired framing. referenced_files: [questions.md]
- **R2-F02** (high, intent) — Q27 exposes a live design choice by framing the research around "read-on-demand versus pre-summarized information flow between research and design stages." Recast as a neutral question about information-transfer patterns between stages. referenced_files: [questions.md]
- **R2-F03** (medium, intent) — Q12 remains defect- and solution-loaded: "regex- and lexer-based shell-command parsing as a security boundary," "known bypass classes," and "statically enumerating evaluation channels" tell the researcher what mechanism is under suspicion and the kind of failure argument being assembled. referenced_files: [questions.md]
- **R2-F04** (medium, scope) — Q5 is too exhaustive for the "mid-altitude, focused-pass-answerable" bar: "every subcommand, every JSON path, every exit code, every external invocation, and every test stub" pushes toward inventory work. Narrow to externally visible behavior, dependency surface, and test seams. referenced_files: [questions.md]

## Post-review fixes (round 2)

Applied surgical edits in place to questions.md:

1. Q3 — section-list dropped.
2. Q5 — exhaustive enumeration → externally visible interface + dependency surface + test seams.
3. Q12 — security-boundary + bypass-class language → "analysis of shell command lines for the purpose of inferring their effects — techniques, accuracy, alternatives".
4. Q16 — runtime-behavior-vs-text/config parenthetical → "along any axis".
5. Q20 — "WHY-not-WHAT consensus" → "guidance on the purpose and content of code comments — categorizations, good/poor examples".
6. Q21 — "prompt/template wording vs runtime behavior" → "what each category asserts against, and what regression class each category protects".
7. Q27 — "read-on-demand versus pre-summarized" → "structure the transfer of information between research and design stages".

## Round 3 — Claude

Verdict: **APPROVE-CLEAN**. All seven round-2 fixes verified landed cleanly. Pass B fresh re-read found no residual leakage. Goal-zone coverage intact (subagent dispatch / hooks/sandbox / Codex companion / state.sh / prompt-quality / researcher handoff / test corpus / branch namespace / reviewer-perspective separation / ID leakage / task-type prior art / integrate / CI gating). Schema correct (frontmatter, numbering 1–28, tags). No redundancy. Codex round-3 not run (recurring audit-write infrastructure failure unrelated to review content; round-2 Codex aligned tightly with round-2 Claude on the same intent class, so a focused Pass-A verification was sufficient for convergence).
