# E2E Test Template

Tests that verify critical user journeys work end-to-end across the full stack. E2E tests prove the entire system works together for real user scenarios.

## Test Structure

1. **Setup:** Create a clean, realistic starting state (user account, initial data)
2. **Journey:** Execute the complete user workflow step by step
3. **Checkpoints:** Verify intermediate states at each major step
4. **Final assertion:** Verify the end state matches the user's goal
5. **Cleanup:** Restore to clean state

## When to Write E2E Tests

- Critical user journeys (signup → first action → value delivery)
- Workflows that span 3+ components or vertical slices
- Flows where failure would be user-visible and high-impact
- Do NOT write E2E tests for everything — they are slow and brittle. Reserve for critical paths.

Use acceptance tests for individual features. Use integration tests for component boundaries. Reserve E2E tests for the end-to-end journeys that matter most to real users.

## Naming Convention

```
test('E2E: [user journey description]', ...)
```

Example: `test('E2E: user registers, creates box, invites collaborator', ...)`

The `E2E:` prefix makes these tests easy to filter in test output and CI reports. The description should read like a user story — what the user does, not what the system does.

## Anti-Patterns

- Writing E2E tests for simple CRUD operations (use acceptance tests)
- Depending on external services without mocking at the network boundary
- Testing implementation details within the E2E flow
- Making E2E tests that take more than 30 seconds (too slow for CI)
- Not cleaning up state between E2E tests (they WILL interfere)
