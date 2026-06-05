# Type Design Review — Task 39, Round 3 — CLEAN

Reviewer: type-design-claude
Subject: tools/build-plugin.mjs
Round: 3

## Scope

The only new type introduced by this task is `BuildError extends Error`
(tools/build-plugin.mjs:137). The build context (`{ rootReal, expandCache }`,
line 140) is a plain object literal, not a declared type.

## Evaluation

`BuildError` was assessed against all seven criteria:

1. **Encapsulation** — empty subclass; no state to leak.
2. **Invariant expression** — no fields, no invariants to violate. Its sole
   role is `instanceof` discrimination of formatted/fail-loud build
   diagnostics from unexpected runtime errors, which is correctly modeled as
   a nominal subtype rather than a flag on a generic Error.
3. **Naming** — `BuildError` describes what it is in the domain.
4. **Granularity** — represents exactly one concept (a fail-loud, pre-formatted
   build diagnostic).
5. **Relationships** — `extends Error` is a legitimate is-a relationship and
   the idiomatic JS pattern for `instanceof`-based discrimination.
6. **Generics/unions** — N/A.
7. **Nullability** — N/A.

The discrimination site at line 535 (`if (e instanceof BuildError) … else
throw e;`) is the canonical pattern an empty Error subclass exists to enable,
and it makes the "expected error vs. bug" distinction a structural property
rather than a string-prefix convention.

The plain-object `ctx` shape is appropriate for a stdlib-only ESM script;
both fields are required and consistently used together, so there is no
boolean-flag combination needing a discriminated union and no nullable
footgun a class would eliminate.

## Findings

None.
