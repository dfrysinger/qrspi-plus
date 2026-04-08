---
status: approved
task: 5
phase: 1
enforcement: strict
allowed_files:
  - action: create
    path: hooks/lib/example.sh
  - action: modify
    path: hooks/session-start
constraints:
  - Must source frontmatter.sh
  - No external dependencies
---

# Task 5: Example

Task description here.