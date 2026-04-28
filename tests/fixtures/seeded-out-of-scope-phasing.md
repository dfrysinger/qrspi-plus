---
status: draft
---

# Phasing: Out-of-Scope Seed (phasing.md)

This fixture deliberately seeds content that violates `## Phasing OWNS / Phasing DEFERS`. The scope-reviewer dispatch with `{ARTIFACT_TYPE}=phasing` MUST emit boundary-drift findings tagged `change_type: scope`.

This fixture uses the FAMILY-SHAPE headings (`### Phasing OWNS` / `### Phasing DEFERS`) per the scope-reviewer template's Rules-Loading Procedure — synthetic content for testing the rules-loading positive path despite FU-5 (live phasing/SKILL.md still uses bare `### OWNS` / `### DEFERS`).

## Phasing OWNS / Phasing DEFERS

### Phasing OWNS

- Vertical-slice authoring.
- Phase boundary decisions.

### Phasing DEFERS

- File paths and module boundaries → Structure.
- Task specs and LOC estimates → Plan.

## Slices

### Slice 1: User registration

- DEFERS violation — file paths embedded inside the slice:
  - `src/auth/register.ts`
  - `src/auth/login.ts`
- DEFERS violation — function signature embedded:
  - `function registerUser(input: RegisterInput): Promise<User>`

### Slice 2: Architecture re-litigation

- DEFERS violation — re-asserts an architecture decision Design owns: "switch from event-sourcing to CRUD because phases are easier."

## Phases

### Phase 1: PoC

- DEFERS violation — task spec embedded with LOC estimate:
  - **Task 1:** Build register handler. LOC: ~80. Test expectations: returns 201 on success.

## Implementation Hooks

- DEFERS violation — skill-implementation jargon (subagent dispatch verbs, hook syntax) appears: "dispatch a subagent to invoke `pre_task_use` hook before each task."
