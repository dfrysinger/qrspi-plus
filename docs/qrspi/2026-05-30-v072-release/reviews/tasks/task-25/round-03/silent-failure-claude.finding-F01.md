---
finding_id: R3-F01
severity: medium
change_type: correctness
referenced_files:
  - skills/prompt-prose-reviewer/SKILL.md
  - skills/prompt-prose-writer/SKILL.md
reviewer_tag: silent-failure-claude
round: 3
task: 25
---

Assembly-guard HTML comments are LLM-visible but cannot self-trigger on partial-include failure.

HTML comments are NOT inert at LLM runtime — they appear in the raw token stream and are read by the model. So the guard text IS present in context. However, the guard condition "if either include above is unavailable" can only be evaluated if the LLM can detect the absence of expected content. The R2 fix only closes the full-failure case (both !cat lines silent-drop), leaving the partial-failure case open:

**FULL FAILURE (both !cat lines silent-drop):** LLM receives heading + empty + guard comment. An attentive LLM may notice no meaningful content above and surface an error. Risk: somewhat mitigated (non-deterministic, but plausible for a capable model).

**PARTIAL FAILURE — the unclosed path (exactly one of two !cat lines silent-drops):**
- prompt-prose-detection.md loads; prompt-prose-reviewer-addition.md drops silently. LLM receives ~300 words of detection guidance, then the guard comment. The LLM sees substantial content "above" and interprets the include chain as having succeeded. The LLM applies half a skill: detection rules present, but action/enforcement instructions absent. Reviewer runs but silently skips all prompt-prose enforcement.
- OR the reverse: reviewer-addition loads; detection drops silently. LLM has enforcement instructions but no detection criteria. "Apply the detection above" references content that isn't there; LLM hallucinates detection or defaults to over-applying. Still silent.

**Root cause:** No include-boundary delimiters exist in either SKILL.md. After assembly, the output has no structural marker showing where each !cat block was supposed to begin and end. A partial drop leaves a seamless gap — there is nothing in the assembled text for the LLM to identify as absent content.

The bats tests (test-task-25-round02-fixes.bats) grep for guard text presence and pass. They do not and cannot verify the guard triggers on partial failure.

**Proposed fix (option A — sentinel boundary markers):** Wrap each `!cat` in named delimiters in the SKILL.md source:

```
<!-- INCLUDE-BEGIN: prompt-prose-detection -->
!cat skills/_shared/prompt-prose-detection.md
<!-- INCLUDE-END: prompt-prose-detection -->

<!-- INCLUDE-BEGIN: prompt-prose-reviewer-addition -->
!cat skills/_shared/prompt-prose-reviewer-addition.md
<!-- INCLUDE-END: prompt-prose-reviewer-addition -->

<!-- Guard: if you do not see content between any INCLUDE-BEGIN/INCLUDE-END pair above,
do NOT apply this skill. Surface a load error naming the missing block and stop. -->
```

After assembly, a silently-dropped include leaves a visible empty span between its BEGIN and END markers — the LLM can detect it and the guard becomes evaluable.

**Proposed fix (option B — explicit platform dependency declaration):** If the host `!cat` implementation is trusted to fail loudly, document that dependency explicitly in the description frontmatter of both SKILL.md files so consuming agents know the partial-load protection requires host-level guarantees, not LLM detection.

**Note on R2-F02:** "stop the review entirely — do not proceed with any further files" is unambiguous and cleanly resolves R2-F02.
