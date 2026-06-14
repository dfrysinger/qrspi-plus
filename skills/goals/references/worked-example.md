# Goals — Worked Examples

Optional reading. Use when authoring or reviewing a `goals.md` and the inline template in `SKILL.md` is not enough to disambiguate the per-goal structure.

## Good `goals.md` — "Rate Limiter for Public API"

```markdown
---
status: draft
---

# Goals: Rate Limiter for Public API

## Purpose

The public REST API has no per-client rate limiting; abusive callers are degrading service for legitimate consumers. This run captures the problem space and known signals so Design can propose a fair-resource-usage architecture.

## Constraints

- Redis is already in the stack and is the only shared-state store available
- Rate-limited paths cannot exceed 5ms p99 overhead (existing latency budget)
- Clients sit behind proxies — X-Forwarded-For must be respected
- Must be deployable without downtime (rolling deploy)
- Timeline: complete within current sprint (5 days)

## Goals

### G1 — Per-client request limiting

- **type:** `known-fix`

#### Problem

A small number of clients are issuing burst traffic that crowds out other consumers. The API has no mechanism to throttle a single client's request rate; every request is served until downstream resources saturate.

#### Why we care

Service quality for legitimate consumers degrades during abuse events. Support load increases as customers report intermittent failures. Without enforcement, a single misbehaving client can effectively DoS the public API.

#### What we know so far

- The abuse pattern is per-API-key; clients without an API key fall back to source IP.
- Industry pattern is token-bucket or sliding-window counters — both are **candidates Design should weigh**.
- Redis-backed counters are a **possibility for Design to evaluate** given the existing Redis dependency; in-memory per-node counters are an alternative Design may also weigh.

### G2 — Rate-limit response headers

- **type:** `known-fix`

#### Problem

When a client is rate-limited it has no way to know when to retry, and even un-throttled clients have no visibility into how close they are to a limit.

#### Why we care

Without retry-guidance headers, polite clients cannot back off correctly and become indistinguishable from abusive ones. SDK authors have requested limit-introspection headers repeatedly.

#### What we know so far

- Common-practice headers include `Retry-After`, `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset` — **candidates Design should weigh** for the response contract.
- IETF `RateLimit-*` draft headers exist as an alternative Design may also weigh.
```

What is NOT in this example: no `Success Criteria` / `Acceptance Criteria` section (Design's Test Strategy + Plan's per-task expectations own that), no `Out of Scope` section, no per-goal solution definition.

## Bad `goals.md` — "Rate Limiting"

```markdown
---
status: draft
---

# Goals: Rate Limiting

## Purpose

Add rate limiting so the API doesn't get abused.

## Constraints

- Use existing tech stack

## Goals

### G1 — Rate limiting

#### Problem

Rate limiting needed.

#### What we ship

- 429 responses
- An admin UI to configure limits
- Implementation in Redis with a token bucket
```

### Why the bad one fails

- **No `type` field** on G1 — required.
- **"Rate limiting needed"** is not a problem statement; it's a solution-shaped placeholder.
- **Missing "Why we care"** entirely; carries a `What we ship` subsection not in the permitted three.
- **Solution commitments leaked** — "Implementation in Redis with a token bucket" pre-commits Design.
- **Admin UI smuggled in** — separate goal, not a sub-bullet.
- **"Use existing tech stack"** as a constraint is not concrete.
