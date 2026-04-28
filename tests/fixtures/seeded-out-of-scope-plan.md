---
status: draft
---

# Plan: Out-of-Scope Seed (plan.md)

This fixture deliberately seeds content that violates `## Plan OWNS / Plan DEFERS`. The scope-reviewer dispatch with `{ARTIFACT_TYPE}=plan` MUST emit boundary-drift findings tagged `change_type: scope`.

## Overview

## Phase 1: PoC

## Task Specs

### Task 1: Rate limiter middleware

- **goal_id:** G1
- **LOC estimate:** ~80
- **Description:** DEFERS violation — function signature in task spec: `function rateLimiter(req: Request, res: Response, next: NextFunction): Promise<void>`. The signature belongs to structure.md.
- **Test Expectations:**
  - DEFERS violation — full assertion text in test expectations bullet:
    - `expect(res.statusCode).toBe(429)`
    - `assert.equal(body.error, 'rate limited')`
- **Implementation:**
  - DEFERS violation — line-by-line logic embedded:
    1. `if (count > 100) { return 429; }`
    2. `for (const key of keys) { redis.del(key); }`

### Task 2: Architecture re-litigation

- **goal_id:** G1
- **Description:** DEFERS violation — design-layer prose: "We considered event-sourcing as an alternative approach but the trade-off favored token-bucket for blast radius reduction."

### Task 3: Phasing forward reference

- **goal_id:** G2
- **Description:** DEFERS violation — phasing-layer leak: "Phase 2 will add the admin UI; future phases will introduce per-tenant policies."
