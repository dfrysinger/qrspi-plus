---
status: draft
---

# Design: Out-of-Scope Seed (design.md)

This fixture deliberately seeds content that violates `## Design OWNS / Design DEFERS`. The scope-reviewer dispatch with `{ARTIFACT_TYPE}=design` MUST emit boundary-drift findings tagged `change_type: scope`.

## Approach

Event-sourced write side, projection-based read side.

## Key Decisions

- DEFERS violation — full DDL embedded:

```sql
CREATE TABLE rate_limits (
  client_id TEXT NOT NULL,
  count INTEGER NOT NULL,
  CHECK (count >= 0)
);
```

- DEFERS violation — full function signature embedded:

```typescript
function rateLimiter(req: Request, res: Response, next: NextFunction): Promise<void>
```

## Trade-offs Considered

- Token bucket vs sliding window — chosen approach won.

## Test Strategy

- DEFERS violation — full assertion text embedded:

```typescript
expect(res.statusCode).toBe(429);
```

## Phasing

- DEFERS violation — phase split authored in design.md (owned by `qrspi:phasing`):
- Phase 1: DB layer
- Phase 2: API layer

## Vertical Slices

- DEFERS violation — vertical slice authoring belongs to Phasing.

## System Diagram

```mermaid
graph LR
  A[client] --> B[server]
```
