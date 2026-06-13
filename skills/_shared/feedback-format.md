# Feedback File Format (shared)

Single source of truth for the user-rejection feedback file. When a user rejects an artifact at a human gate, the feedback is captured to a known path so the next subagent can act on it. Self-contained: every required field and the file-path convention is below.

## File path

```
{artifact-dir}/feedback/{step}-round-{NN}.md
```

`{step}` is the canonical step name (e.g. `goals`, `design`, `plan`). `{NN}` is the zero-padded rejection round number.

## File body

```markdown
---
step: {step name}
round: {rejection round number}
rejected_artifact: {path to rejected artifact}
---

## User Feedback
{The user's rejection feedback, verbatim}

## Previous Artifact
{The full content of the rejected artifact}
```

The new subagent receives the original inputs plus this feedback file.
