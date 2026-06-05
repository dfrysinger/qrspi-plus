---
finding_id: R2-F01
severity: high
change_type: correctness
artifact: code
round: 2
reviewer: security-claude
model: claude-sonnet-4.6
referenced_files:
  - agents/qrspi-finding-verifier.md#L20-L22
  - agents/qrspi-finding-verifier.md#L67-L78
---

# `Informational:` label can route a HALLUCINATED finding around Cite Check via carve-out scope ambiguity

**Problem:** The Informational carve-out reads "do NOT apply the false-positive patterns **below**." The word "below" is structurally ambiguous. In the document layout, the Rubric section (containing the Informational special-path) comes before the Procedure section (containing step 3.5 Cite Check). An LLM verifier agent reading top-to-bottom encounters the carve-out at rubric-read time and may interpret "patterns below" as "everything that follows in this document" — which includes the Procedure section's step 3.5 — rather than as "the bullet list starting at line 40."

If the verifier takes the broad reading, it routes an `Informational:`-labeled finding entirely past Cite Check and straight to the Informational structural-confidence scoring sub-path (75 / 50 / 25). That sub-path has no halt-and-zero mechanism and no `HALLUCINATED:` reason prefix. A finding with plausible but entirely fabricated citations could score 50 ("partially verifiable") and land in `kept-findings.txt` without any `HALLUCINATED:` marker.

**Attack:** `Informational:` prefix + fabricated `referenced_files` citations + verifier-confused-by-scope = silent fabrication slip-through with no greppable audit trail. TC8 covers advisory/no-citation; TC4–TC7 cover non-Informational HALLUCINATED. The intersection (`Informational:` + fabricated citation) is untested.

**Fix:** Disambiguate the carve-out scope — explicitly state Cite Check applies to ALL findings regardless of label.
