# QRSPI Framework Reference

**Source:** Dex Horthy, "Everything We Got Wrong About RPI" — Coding Agents Summit (South Bay Summit, 2026)

## Background: Why RPI Broke Down

The original **RPI** (Research → Plan → Implement) used a single `/create_plan` mega-prompt with **85+ instructions** that internally attempted to do design decisions, structure outlines, and detailed planning all at once. The result: design and structure steps were **"accidentally skipped"** because they were buried sub-steps. Plans were low quality, and engineers were reviewing ~2000 lines of code instead of catching problems earlier.

QRSPI fixes this by **extracting every hidden sub-step into an explicit phase** with its own prompt, inputs, outputs, and human review gate. Each phase compacts its output before feeding the next phase, keeping context window utilization in the **"smart zone" (~40-60%)** via Frequent Intentional Compaction (FIC).

## The 9 Steps (Plugin Implementation)

| # | Step | Before (RPI) | Purpose |
|---|------|-------------|---------|
| 1 | **Goals** | (new) | Capture user intent, constraints, acceptance criteria |
| 2 | **Questions** | Research | Generate targeted research questions — query planning before code is read |
| 3 | **Research** | Research | Objective codebase/web exploration driven by questions |
| 4 | **Design** | Plan | Interactive design discussion, vertical slicing, phasing |
| 5 | **Structure** | Plan | Map design to files, interfaces, component boundaries |
| 6 | **Plan** | Plan | Detailed task specs with test expectations |
| 7 | **Worktree** | Implement | Parallelization analysis, worktree creation, dispatch |
| 8 | **Implement** | Implement | TDD execution per task with tiered review loops |
| 9 | **Test** | Implement | Acceptance testing, phase routing, replan gates |

## Core Philosophy

**"Do not outsource the thinking."** QRSPI gives the agent every opportunity to show you what it's thinking at each stage, with human review gates between phases. You review ~200 lines of research/design/plan artifacts instead of ~2000 lines of code.

**Context engineering is the only lever.** The only thing that affects LLM output quality is what's in the context window. Each QRSPI phase produces a compact artifact, runs in a fresh subagent, and feeds only its declared inputs to the next phase — staying in the 40-60% "smart zone" instead of the >60% "dumb zone."

## Key Principles

- **Separate what we need to know from finding the answers** (Questions → Research split)
- **Hide the ticket from researchers** — research stays objective, prevents confirmation bias
- **Vertical slices, not horizontal layers** — each feature goes end-to-end through the stack
- **One line of plan ≈ one line of code** — plans are long and detailed, spot-check them
- **Hammer on goals, design, and structure** — these are the high-leverage review points
- **Single pipeline for all work** — fix tasks route through the same Worktree → Implement pipeline

## User Review Effort Guide

| Artifact | Review Effort |
|----------|--------------|
| `goals.md` | **Hammer on this** — wrong goals = everything downstream is wrong |
| `questions.md` | Thorough — missing questions = blind spots |
| `research/summary.md` | Read and verify — wrong facts = wrong design |
| `design.md` | **Hammer on this** — approach, slicing, phasing |
| `structure.md` | **Hammer on this** — file layout, interfaces |
| `plan.md` + task specs | Spot-check — review subagent validates detail |
| Code | **Thorough review** — reinvest time saved from spot-checking plan |
