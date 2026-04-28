---
status: draft
---

# Structure: Out-of-Scope Seed (structure.md)

This fixture deliberately seeds content that violates `## Structure OWNS / Structure DEFERS`. The scope-reviewer dispatch with `{ARTIFACT_TYPE}=structure` MUST emit boundary-drift findings tagged `change_type: scope`.

## File Map

### Slice 1: Rate limiter

| File | Action | Responsibility | Goal IDs | LOC | Commit Range |
|------|--------|----------------|----------|-----|--------------|
| `src/middleware/rate-limiter.ts` | Create | Rate limit middleware | G1 | ~150 LOC | abc123..def456 |

DEFERS violations above: per-task LOC and commit ranges belong to Plan.

## Interfaces

### RateLimiter

- DEFERS violation — full implementation body embedded (Structure owns the signature, NOT the body):

```typescript
function rateLimiter(req: Request, res: Response, next: NextFunction) {
  const count = redis.incr(`rl:${req.clientId}`);
  if (count > 100) {
    res.status(429).send('rate limited');
    return;
  }
  next();
}
```

## Test Layout

- DEFERS violation — assertion text embedded in structure.md:

```typescript
expect(res.statusCode).toBe(429);
expect(res.body).toEqual({ error: 'rate limited' });
```

## Phasing

- DEFERS violation — phase boundaries re-authored:
- Phase 1: middleware
- Phase 2: admin UI

## Architectural Diagram

```mermaid
graph LR
  A[client] --> B[middleware] --> C[handler]
```
