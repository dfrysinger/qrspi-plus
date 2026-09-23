import { appendFile, readFile } from "node:fs/promises";

const token = process.env.COPILOT_AGENT_TOKEN;
if (!token) {
  throw new Error(
    "COPILOT_AGENT_TOKEN or GAW_COPILOT_TOKEN is required. Configure a user-to-server token with Agent tasks: read and write access.",
  );
}

const [owner, repo] = process.env.GITHUB_REPOSITORY.split("/");
if (!owner || !repo) {
  throw new Error(`Invalid GITHUB_REPOSITORY: ${process.env.GITHUB_REPOSITORY}`);
}

const request = JSON.parse(await readFile(process.env.REQUEST_PATH, "utf8"));
const apiUrl = process.env.GITHUB_API_URL || "https://api.github.com";
const response = await fetch(`${apiUrl}/agents/repos/${owner}/${repo}/tasks`, {
  method: "POST",
  headers: {
    Accept: "application/vnd.github+json",
    Authorization: `Bearer ${token}`,
    "Content-Type": "application/json",
    "X-GitHub-Api-Version": "2026-03-10",
  },
  body: JSON.stringify(request),
});

const responseText = await response.text();
let result;

try {
  result = JSON.parse(responseText);
} catch {
  throw new Error(
    `Agent tasks API returned HTTP ${response.status} with a non-JSON response.`,
  );
}

if (!response.ok) {
  const message = result.message || "Unknown API error";
  throw new Error(`Agent tasks API returned HTTP ${response.status}: ${message}`);
}

if (!result.id || !result.state) {
  throw new Error("Agent tasks API response omitted id or state.");
}

const taskUrl = result.html_url || "https://github.com/copilot/agents";
const outputs = [
  `task_id=${result.id}`,
  `task_url=${taskUrl}`,
  `task_state=${result.state}`,
].join("\n");

await appendFile(process.env.GITHUB_OUTPUT, `${outputs}\n`);
console.log(`Started Copilot cloud agent task ${result.id} (${result.state}).`);
