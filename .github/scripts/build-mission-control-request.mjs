import { readFile } from "node:fs/promises";

const event = JSON.parse(await readFile(process.env.GITHUB_EVENT_PATH, "utf8"));
const task = process.env.INPUT_TASK?.trim();
const baseRef =
  process.env.INPUT_BASE_REF?.trim() || event.repository.default_branch;
const model = process.env.INPUT_MODEL?.trim();

if (!task) {
  throw new Error("The agent task must not be empty.");
}

if (task.length > 20_000) {
  throw new Error("The agent task exceeds the PoC limit of 20,000 characters.");
}

const executionContract = `
Work only in ${process.env.GITHUB_REPOSITORY}.
Read AGENTS.md and CONTRIBUTING.md before editing.
Make the smallest complete change that satisfies the task.
Follow the repository's branch, commit, generated-file, and validation rules.
Run the most focused relevant validation available.
Create a pull request with a concise explanation of the change and validation.
Do not merge the pull request.
If the task is ambiguous or cannot be completed safely, stop and explain the blocker.
`.trim();

const request = {
  prompt: `${task}\n\nRepository execution contract:\n${executionContract}`,
  base_ref: baseRef,
  create_pull_request: true,
};

if (model) {
  request.model = model;
}

process.stdout.write(`${JSON.stringify(request, null, 2)}\n`);
