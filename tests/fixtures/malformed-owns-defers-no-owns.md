---
name: malformed-no-owns
description: Synthetic SKILL.md fixture with the H2 heading present but missing the `### {Skill} OWNS` H3 subsection. Used to test the scope-reviewer rules-loading fail-closed case 2.
---

# Malformed SKILL — No OWNS Subsection

## Overview

This skill fixture has the `## Malformed OWNS / Malformed DEFERS` H2 heading but is missing the `### Malformed OWNS` H3 subsection. The scope-reviewer must fail closed.

## Malformed OWNS / Malformed DEFERS

Prose-only intro, no H3 OWNS subsection follows.

### Malformed DEFERS

- Some deferred concern.

## Process

Unrelated content.
