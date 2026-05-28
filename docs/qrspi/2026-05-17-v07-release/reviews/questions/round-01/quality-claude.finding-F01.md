---
finding_id: R1-F01
severity: high
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/questions.md:L13-L37, docs/qrspi/2026-05-17-v07-release/goals.md]
artifact: questions
round: 1
reviewer: quality-claude
---

Pervasive goal leakage across the question set: a researcher reading only `questions.md` (without `goals.md`) could reverse-engineer most of the v0.7 release's intended deliverables. The Questions-step contract requires that questions surface a research surface without disclosing the goal — this set repeatedly imports goals-specific vocabulary, citations, and proposed fix shapes back into the question prose.

Concrete instances (non-exhaustive):

- **Q4** names "DeepSeek-V3 and Kimi K2 (Moonshot)" — these are exemplar models pulled verbatim from G5's "What we know so far." The question could ask the same thing as "OpenAI Chat Completions compatibility for two current third-party cheap-model endpoints" without naming the candidates the goal already selected.
- **Q5** cites the Medium article title and URL verbatim. The goals explicitly identify this article as research input; reproducing the title in the question signals to the researcher that this article is the chosen prior art, which is goal content.
- **Q8** lists "SKILL bodies, reviewer-protocol, implementer-protocol" — the exact triplet enumerated in G4's "What we know so far" candidate (a). A researcher would see this and infer the candidate has already been selected.
- **Q12** names the forbidden token families `R<N>-F<NN>`, `T<NN>`, and "goal/question/design IDs" — copied directly from G7's candidate-guidance bullet. Asking the researcher to look for "existing guidance restricting those tokens from appearing in edited files" makes the proposed fix explicit.
- **Q13** asks specifically about "Worktree-Aware Setup Validation" terminology and the partition between "worktree configuration vs. runtime worktree creation" — this is G8's exact framing of the proposed owns-defers fix.
- **Q14** enumerates `feature branch tip`, `task-NN tip`, `stage-after-W{N}`, `task-00 tip`, and `W4a/b/c` — every term in G9's "What we know so far" appears here. The question hands the researcher the goal's vocabulary inventory.
- **Q17** asks about ordering "scratch-file write, staging, and commit" with `.gitignore` coverage — this is G12's two-candidate solution structure expressed as a question. A researcher reading Q17 would infer that scratch staging is a problem and that gitignore is being considered.
- **Q22** lists `jq`, `yq`, `bats-core`, ShellCheck on `hooks/`, and matrix strategies — exactly the dependency set G17 enumerates.
- **Q23** lists both `qrspi/{slug}/...` and `{handle}/issue-{NNN}-{slug}` namespace formats verbatim from G17's "What we know so far," and frames them as "namespaces ... that would need to be reflected in CI trigger filters." The "would need to be reflected" framing reveals that CI is the deliverable.
- **Q24** lists `v0.6`, `v0.6.0`, `v0.7+`, `0.6+` and "carve-outs ... under `docs/qrspi/YYYY-MM-DD-*/`" — all four token forms and the exact carve-out path are lifted from G18.

The cumulative effect is that a researcher reading the question set in isolation can reconstruct: the cost-opt routing trio with DeepSeek/Kimi as targets, the Plan post-approval split, the context-optimization mechanism candidates, the ID-hygiene lint, the Parallelize owns-defers fix, the Parallelize vocabulary fix, the commit-scratch gitignore fix, GitHub Actions CI scope, and evergreen-prose enforcement scope. That is the v0.7 release plan expressed through the question titles.

Recommended fix: rewrite the offending questions to ask about the underlying research surface without naming the proposed solution shape, candidate vocabulary, or chosen citations. Examples:

- Q4 → "What OpenAI Chat Completions compatibility surfaces do current third-party cheap-model endpoints expose (request/response shape, streaming, error codes)?" (no model names)
- Q5 → split off as a [web] question that just asks "What patterns do public writeups describe for shell-side third-party LLM dispatch ... ?" without naming the specific article.
- Q8 → "Which dispatch sites across `skills/` and `agents/` repeatedly include the same long stable files in prompt composition?" (drop the triplet enumeration)
- Q12 → "How does the fix-cycle implementer pathway thread reviewer-finding and task identifiers into prompts, and what restrictions, if any, exist on those tokens appearing in edited files?" (drop the literal token forms)
- Q14 → "What Branch Map vocabulary is canonical in `skills/parallelize/SKILL.md`, and where do reviewer surfaces define or contradict that vocabulary?" (drop the term enumeration)
- Q17 → "What is the ordering of scratch-file write, staging, and commit in the implementer-protocol commit procedure, and what does `.gitignore` cover for transient implementer artifacts?" (drop the framing that signals the fix shape)
- Q22 → "What GitHub Actions patterns exist for running BATS suites and shell linting on `ubuntu-latest`?" (drop the dependency enumeration)
- Q23 → "What branch-naming conventions are documented in the repo, and how do those namespaces appear in scripts or templates?" (drop the framing that signals CI trigger filters)
- Q24 → "Which evergreen contract files in `main` contain release-version tokens or milestone references, and what carve-outs exist for dated pipeline artifacts?" (drop the token-form list)

This is a correctness finding (not intent) because the leakage is a property of how the questions were written, not a contradiction of any user decision — the rewrites preserve every research surface the current set covers.
