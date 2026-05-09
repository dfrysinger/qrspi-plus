---
name: smoke-spec
description: Convention for the smoke_checks block in plan task specs. Smoke checks are fetch-based runtime assertions the implementer runs after build passes.
---

# Smoke check spec

A `smoke_checks:` block in a task spec lists fetch-based runtime assertions
the implementer runs after the build passes. Smoke checks catch the
"vitest green ≠ runtime works" drift class — missing globals.css imports,
broken redirects, unwired routes, runtime React errors that surface at
first request.

## Block format

```yaml
smoke_checks:
  - path: /signin
    auth: none
    expect_status: 200
    expect_body_contains:
      - "Sign in"
    expect_link_href_pattern: "globals\\.css"
  - path: /home
    auth: signed-in
    expect_status: 200
    expect_body_not_contains:
      - "Welcome to Home"  # placeholder copy that should have been replaced
  - path: /api/auth/callback?code=stub
    auth: none
    expect_status: 302
    expect_location: "/onboarding"
```

## Required fields

- `path` — URL path to fetch (relative to the dev server's origin).
- `auth` — one of `none`, `signed-in`, `admin`. The implementer scaffolds a
  session cookie based on this value before issuing the fetch.
- `expect_status` — integer HTTP status the response must match exactly.

## Optional fields

- `expect_body_contains` — array of strings; each must appear in the
  response body.
- `expect_body_not_contains` — array of strings; none may appear.
- `expect_location` — string for 30x responses; the `Location` header must
  match exactly.
- `expect_link_href_pattern` — regex (as a string); at least one
  `<link rel="stylesheet" href="...">` `href` must match. Used to verify
  global stylesheets are reachable.

## Auth scaffolding

The Plan declares the project's auth-scaffolding recipe in a sibling field
(e.g., `smoke_auth: { cookie_name: "sb-access-token", signing: "..." }`).
The first project to use smoke checks pays the recipe-authoring cost; the
implementer refers to that field when running checks against the dev
server.

## When to include smoke checks

- **Required** for any task adding or modifying a route, page, layout, or
  user-facing component.
- **Optional** for tasks touching only internal libraries (no route or
  component surface).

## Helper script

The implementer runs smoke checks via `scripts/run-smoke-checks.mjs` (in
this plugin). The script:
1. Reads the task spec's `smoke_checks:` block.
2. Starts the dev server using `dev_command` from the plan.
3. Waits for the port to listen (default 3000; configurable).
4. Issues each fetch and asserts the contract.
5. Stops the dev server.
6. Exits non-zero on any failure.

The implementer does NOT modify smoke checks to make them pass — they are
authored by the Plan skill, not the implementer.
