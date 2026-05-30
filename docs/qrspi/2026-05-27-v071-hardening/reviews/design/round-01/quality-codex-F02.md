---
artifact: design
reviewer: quality-codex
round: 1
finding_id: quality-codex-F02
severity: medium
change_type: coherence
file: design.md
section: "DKR6, DKR7, System Diagram"
---

# F02: Host-detection design includes Codex CLI branch without a corresponding dispatch/availability design

## Evidence

design.md DKR6 defines three detected hosts: Copilot CLI, Codex CLI, Claude Code. DKR7 defines Codex dispatch transports only for Claude Code and Copilot CLI. The Mermaid system diagram shows `H_CODEX` ("Host = Codex CLI") in detection but dispatch branches only to Claude / Copilot paths.

## Impact

The design is internally incomplete for one declared detection outcome, which can cause inconsistent implementation choices.

## Required fix

Either (a) explicitly scope out Codex CLI in DKR6 and remove that branch from detection / diagram, or (b) define the Codex-CLI availability check and dispatch transport path end-to-end.

## Orchestrator note

goals.md G6 § "What we know so far" explicitly says: "Codex CLI's own Codex-reviewer dispatch transport is out of scope for v0.7.1 unless trivial — Design can scope this goal Copilot-only and leave Codex-CLI to a follow-up." Therefore option (a) is the right resolution.

## Convergence note

Same finding raised by quality-claude as F03. Dedup target.
