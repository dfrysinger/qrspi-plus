---
status: draft
---

<!-- SMOKE-TEST FIXTURE: issue-110 commit 6/22
     Deliberate boundary violation: implementation language smuggled into a
     goal body under "What we know so far".

     Violated clause (skills/goals/owns-defers.md, Goals DEFERS):
       "Implementation logic, function signatures, assertion text"
       → Structure / Plan / Implement

     A quality reviewer (qrspi-goals-reviewer) with no OWNS/DEFERS access
     will see acceptable "What we know so far" prose and emit NO scope finding.
     A scope reviewer (qrspi-goals-scope-reviewer) that Reads
     skills/goals/owns-defers.md at Step 1 MUST cite the DEFERS clause above
     and flag the G2 body as a boundary violation (change_type: scope).
-->

# Goals: Rate-Limit Enforcement

## Purpose

Add per-client rate limiting to the public API so abusive callers cannot
exhaust server capacity.

## Constraints

- Must integrate with the existing Express middleware chain.
- p99 response time must not exceed 150 ms under normal load.

## Goals

### G1 — Surface clear error responses on rate-limit breach

- **type:** `known-fix`

#### Problem

Clients hitting the rate limit receive a generic 500 error; they cannot
distinguish rate-limit rejections from server faults.

#### Why we care

Clear 429 responses let callers back off gracefully, reducing unnecessary
retry storms.

#### What we know so far

A `429 Too Many Requests` response with a `Retry-After` header is the
standard signal. Design should weigh whether a JSON body with an error code
is also worth adding.

### G2 — Track per-client request counts efficiently

- **type:** `exploratory`

#### Problem

We have no per-client counters, so enforcement is impossible.

#### Why we care

Without counters the rate-limit feature cannot ship at all.

#### What we know so far

Implement a token-bucket algorithm using a `Map<clientId, TokenBucket>`
where `TokenBucket = { tokens: number; lastRefill: number }`. Refill on
each request call via `Math.min(capacity, tokens + rate * elapsed)`.
