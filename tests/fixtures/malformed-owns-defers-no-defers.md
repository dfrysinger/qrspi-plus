---
name: malformed-no-defers
description: Synthetic SKILL.md fixture with the H2 heading and OWNS subsection present but missing the `### {Skill} DEFERS` H3 subsection. Used to test the scope-reviewer rules-loading fail-closed case 3.
---

# Malformed SKILL — No DEFERS Subsection

## Overview

This skill fixture has the `## Malformed OWNS / Malformed DEFERS` H2 and the `### Malformed OWNS` H3 but is missing the `### Malformed DEFERS` H3 subsection. The scope-reviewer must fail closed.

## Malformed OWNS / Malformed DEFERS

### Malformed OWNS

- Some owned concern.

## Process

Unrelated content; note that the next H2 begins without a DEFERS H3.
