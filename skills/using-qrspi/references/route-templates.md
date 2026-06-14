
When the user selects a pipeline mode, write the route into `config.md` (see Config File section below). Use one of these templates:

**Quick Fix route:**
```yaml
route:
  - goals
  - questions
  - research
  - plan
  - implement
  - test
```

**Full pipeline route:**
```yaml
route:
  - goals
  - questions
  - research
  - design
  - phasing
  - structure
  - plan
  - parallelize
  - implement
  - integrate
  - test
```

**Full + UX (adds wireframing after Phasing, before Structure):**
```yaml
route:
  - goals
  - questions
  - research
  - design
  - phasing
  - ux
  - structure
  - plan
  - parallelize
  - implement
  - integrate
  - test
```

> **Note:** Replan is NOT included in any route list (it is out-of-route). It is invoked by Test when more phases remain in the design, not when Test fails. Test handles final-phase completion (PR creation) directly.

### Mid-Pipeline Route Change

Route changes are only allowed before Plan executes:

- **Full → Quick Fix:** Allowed only before Plan. Drop Design, Phasing, Structure, Parallelize, Integrate from the route. Update `config.md`.
- **Quick Fix → Full:** Allowed only before Plan. Insert Design, Phasing, Structure before Plan, and Parallelize, Integrate after Plan. Update `config.md`.
- **Add/remove UX step:** Allowed only before Structure. Insert or remove `ux` between `phasing` and `structure`. Update `config.md`.

After Plan is approved, the route is locked. Route changes after that point require a backward loop to re-run Plan.
