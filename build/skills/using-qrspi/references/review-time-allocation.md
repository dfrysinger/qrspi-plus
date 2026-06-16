
When presenting artifacts for human review, guide the user on where to invest review time:

- **Design and Structure** — invest heavy review here. These artifacts set the architecture. Errors here cascade through every downstream step.
- **Plan** — spot-check. Plan is a mechanical decomposition of approved artifacts. Sample a few task specs for correctness; you don't need to read every line.
- **Implementation code** — use task specs as a review guide. Each spec in `tasks/*.md` describes what a task was supposed to do, making code review efficient and traceable. Time saved on Plan review is time available to read the code.
