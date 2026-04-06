# Boundary Test Template

Tests that verify the system handles edge cases, invalid input, limits, and error conditions gracefully. Boundary tests prove the system is robust at its limits.

## Test Structure

1. **Identify the boundary:** What is the limit, edge case, or error condition?
2. **Setup:** Create state that approaches the boundary
3. **Action:** Push past the boundary (invalid input, max limit, empty state, etc.)
4. **Assert:** Verify the system handles it gracefully (error message, rejection, fallback)
5. **Verify no side effects:** Confirm the boundary violation didn't corrupt state

## Boundary Categories

- **Input validation:** Empty strings, null, undefined, wrong types, too long, too short, special characters, SQL injection attempts, XSS payloads
- **Limits:** Maximum values, minimum values, exactly-at-limit, one-over-limit, zero, negative numbers
- **Empty states:** Empty collections, no results, first-time user, no data
- **Auth boundaries:** Unauthenticated, wrong role, expired token, malformed token
- **Concurrent access:** Simultaneous writes, read-during-write, double-submit

## Naming Convention

```
test('boundary: [boundary description]', ...)
```

Example: `test('boundary: rejects email longer than 254 characters', ...)`

The `boundary:` prefix makes these tests easy to filter. The description should name the specific boundary being tested — not "handles errors" but "rejects email longer than 254 characters."

## What Makes a Good Boundary Test

- Tests one boundary at a time (don't combine invalid email + expired token)
- Verifies both the rejection AND the error message/code
- Confirms no state mutation occurred (the boundary violation was safely rejected)
- Tests both sides of the boundary (at-limit allowed, over-limit rejected)

## Anti-Patterns

- Only testing happy paths (the boundary test exists to test unhappy paths)
- Testing boundaries that the framework already validates (unless you want to verify the framework config)
- Not verifying the error message (just checking for "any error" is too weak)
- Combining multiple boundary violations in one test (masks which boundary failed)
