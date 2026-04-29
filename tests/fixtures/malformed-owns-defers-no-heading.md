---
name: malformed-no-heading
description: Synthetic SKILL.md fixture missing the `## {Skill} OWNS / {Skill} DEFERS` H2 heading entirely. Used to test the scope-reviewer rules-loading fail-closed case 1.
---

# Malformed SKILL — No OWNS/DEFERS Heading

## Overview

This skill fixture deliberately omits the `## {Skill} OWNS / {Skill} DEFERS` heading entirely. The scope-reviewer's Rules-Loading Procedure must fail closed and emit a single structured-error finding (`change_type: correctness`, `severity: high`) when invoked against this file.

## Process

Some unrelated process content here.

### OWNS

This H3 is intentionally missing — the entire H2 wrapping section is absent.

## Red Flags

- Synthetic fixture, not a real skill.
