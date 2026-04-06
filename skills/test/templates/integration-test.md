# Integration Test Template

Tests that verify data flows correctly between vertical slices or components. Integration tests prove that independently-built pieces work together.

## Test Structure

1. **Setup:** Initialize both components involved in the integration
2. **Action:** Trigger the operation in component A that produces output for component B
3. **Bridge:** Verify the data crosses the boundary correctly (type, format, completeness)
4. **Assert:** Verify component B processes component A's output correctly
5. **Cleanup:** Tear down both components

## What to Test at Integration Boundaries

- **Data format** — does component A's output match component B's expected input?
- **Error propagation** — does an error in component A surface correctly in component B?
- **State consistency** — after the integration, is shared state (DB, cache) consistent?
- **Timing** — does the integration handle async operations correctly?

## Naming Convention

```
test('[component A] → [component B] - [data flow description]', ...)
```

Example: `test('box-service → invitation-service - creates invitation for new box', ...)`

The arrow (`→`) signals this is an integration test and identifies which direction data flows. Both component names should appear in the test name so failures are immediately locatable.

## Anti-Patterns

- Mocking the integration boundary (that defeats the purpose)
- Testing component A and component B independently but not their interaction
- Not testing error propagation across the boundary
- Assuming both components use the same data format without verifying
