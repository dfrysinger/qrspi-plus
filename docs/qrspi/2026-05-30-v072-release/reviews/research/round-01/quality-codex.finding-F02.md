---
finding_id: R1-F02
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/research/summary.md
artifact: research
round: 1
reviewer: quality-codex
---

For codebase research entries, many factual claims in the collated summaries are uncited at `file:line` granularity (for example, Q1/Q2 TL;DR and multiple bullets in summary.md:9-37). The companion summaries are likewise mostly prose assertions without per-claim `file:line` citations (e.g., q01-codebase.md:11-23, q02-codebase.md:11-22). This fails the "codebase references specific (`file:line`) for every factual claim" quality check.
