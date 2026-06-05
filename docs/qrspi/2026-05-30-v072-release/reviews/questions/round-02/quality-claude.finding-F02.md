---
finding_id: F02
severity: high
change_type: clarity
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/questions.md
artifact: questions
---

# Goal Leakage — Q13 Names the Exact Security Gap That G16 Exists to Fix

## Location

Question 13, second sentence:

> "Specifically: does `resolve_path()` or any equivalent function enforce a repository-boundary check, and what does the script do when it receives an absolute path outside the project root?"

## Problem

G16's entire premise is that `scripts/run-codex-review.sh` accepts arbitrary absolute paths (including paths outside the project root) and forwards their contents to the Codex provider without a repo-boundary check. The question above names both halves of that premise explicitly:

1. **"does `resolve_path()` enforce a repository-boundary check"** — presupposes a boundary check is the expected enforcement mechanism, telling the researcher that boundary enforcement is the desired property we are auditing for.
2. **"what does the script do when it receives an absolute path outside the project root"** — frames the research as auditing a specific failure mode (path outside project root), which is precisely the G16 exfil surface.

A researcher reading Q13 in isolation understands: the project has identified `resolve_path()` as the candidate enforcement point and is concerned about an absolute-path escape. The goal (G16 — sanctioned-channel exfil via arbitrary path acceptance) is fully inferable.

The first sentence of Q13 is neutral: "How does `scripts/run-codex-review.sh` currently resolve and validate paths passed to `--subject-code` and `--companion`?" asks how the current mechanism works without hinting at a gap. The leakage is entirely in the second "Specifically:" sentence.

## Why It Matters

Unlike most goal-leakage cases where the researcher's framing is merely biased, here the leakage names a security vulnerability. A researcher who knows "absolute paths outside the project root are the concern" immediately focuses on that specific vector rather than characterizing the general path-handling logic and observing gaps empirically. This is significant because Design's security analysis relies on Research characterizing what the code does, not confirming a pre-identified attack vector.

Secondary concern: the question discloses to any observer that `resolve_path()` lacks boundary enforcement today, which is a live vulnerability detail in the project's public artifact directory.

## Suggested Rewrite

Remove the specific "absolute path outside the project root" framing and keep only the neutral path-resolution description request:

> "How does `scripts/run-codex-review.sh` currently resolve and validate paths passed to `--subject-code` and `--companion`? Specifically: what does `resolve_path()` or any equivalent function do with the input path — does it normalize, canonicalize, or apply any constraints before the path is used? Compare with the `check_codex_available` / host-canonicalization logic already in the file (around line 165–180)."

This asks how path handling works today without naming the boundary-enforcement gap or the out-of-repo path attack surface.
