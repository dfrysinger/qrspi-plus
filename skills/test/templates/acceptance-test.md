# Acceptance Test Template

Tests that verify a specific acceptance criterion from goals.md is met. Each test proves one feature works as specified.

## Test Structure

Every acceptance test follows this pattern:

1. **Setup:** Create the preconditions (user, data, state)
2. **Action:** Perform the operation described in the acceptance criterion
3. **Assert:** Verify the expected outcome matches the criterion exactly
4. **Cleanup:** Restore state (if not handled by test framework)

## Naming Convention

```
test('[criterion] - [specific behavior]', ...)
```

Example: `test('rate limit - returns 429 when client exceeds 100 req/min', ...)`

## Annotation Requirement

Every test MUST include a comment linking to the acceptance criterion:

```
// Acceptance criterion: "Clients exceeding 100 requests/min receive 429 Too Many Requests"
```

Place this comment immediately before the test body — not on the `test(...)` line itself, but as the first line inside the callback. This makes it easy to trace a failing test back to the requirement it covers.

## What Makes a Good Acceptance Test

- Tests observable behavior, not implementation details
- Uses realistic data (not `"test"`, `"foo"`, `"bar"`)
- Asserts specific values, not just "not null" or "truthy"
- Independent — can run in any order, doesn't depend on other tests
- Fast — no unnecessary delays or large data sets
- Deterministic — same result every run

## Anti-Patterns

- Testing internal function calls instead of user-visible behavior
- Asserting on implementation details (specific SQL queries, internal state)
- Using `toContain` when you can use `toEqual` (weaker assertion)
- Testing the framework instead of the feature
