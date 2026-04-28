---
status: draft
---

# Goals: Out-of-Scope Seed (goals.md)

This fixture deliberately seeds content that violates `## Goals OWNS / Goals DEFERS`. The scope-reviewer dispatch with `{ARTIFACT_TYPE}=goals` MUST emit boundary-drift findings tagged `change_type: scope` (or `intent`).

## Purpose

Synthetic fixture for scope-reviewer per-`{ARTIFACT_TYPE}=goals` dispatch tests.

## Constraints

- Use existing tech stack.

## Goals

### G1 — Seeded out-of-scope goal

- **type:** `known-fix`

#### Problem

Rate limiting needed.

#### Acceptance Criteria

- 429 returned within 5ms p99 — DEFERS violation: acceptance criteria belong to Design Test Strategy / Plan per-task expectations.
- Token bucket capacity = 100 — DEFERS violation: solution-prescribing.

#### Out of Scope

- Admin UI — DEFERS violation: top-level Out-of-Scope is forbidden in goals.md.

#### File Map

- `src/middleware/rate-limiter.ts` — DEFERS violation: file maps belong to Structure.

## Out of Scope

- DEFERS violation: top-level `Out of Scope` heading is explicitly forbidden by goals.md template.

## Phasing

- Phase 1: rate limiter — DEFERS violation: phasing decisions belong to `qrspi:phasing`.
