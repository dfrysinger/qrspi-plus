
When the user rejects an artifact at any human gate, they provide feedback. A new subagent round is launched with the original inputs + a feedback file containing the rejected artifact and the user's feedback. Rejection never skips steps or moves backward — it re-runs the current step with feedback until approved.
