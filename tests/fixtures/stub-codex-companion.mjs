#!/usr/bin/env node
// ----------------------------------------------------------------------------
// stub-codex-companion.mjs
//
// Test fixture mimicking the real Codex companion CLI surface used by
// scripts/codex-companion-bg.sh. Implements `task --background --prompt-file`,
// `status <jobId> --json`, and `result <jobId> --json` only.
//
// JSON payload shapes mirror the real companion verbatim:
//   - task --background --json     → { jobId, status, title, summary, logFile }
//                                     (codex-companion.mjs:670-679, v1.0.4)
//   - status <id> --json           → { workspaceRoot, job: { id, status, ... } }
//                                     (codex-companion.mjs:840-857; lib/job-control.mjs:242-254)
//   - result <id> --json           → { job, storedJob }
//                                     where storedJob.result.rawOutput holds
//                                     the review markdown
//                                     (codex-companion.mjs:867-883; lib/render.mjs:401-404)
//
// Job-not-found in the real companion is signalled by main() catching the
// error from matchJobReference() and writing the error message to stderr
// while exiting 1 (codex-companion.mjs:1023-1027). The error message text
// includes the literal substring "No job found" or "No finished job found".
//
// Behaviour is controlled via the following environment variables (set by
// the bats test before invoking the wrapper, which propagates them to the
// stub via CODEX_COMPANION):
//
//   STUB_STATE_FILE        path to JSON file used to persist {jobId, polls}
//                          across subprocess invocations within a single test
//   STUB_LAUNCH_HANG_MS    on `task` subcommand, sleep this many ms before
//                          emitting the JSON (used for the 5s timeout test)
//   STUB_LAUNCH_EXIT       on `task` subcommand, exit non-zero with this code
//   STUB_LAUNCH_BAD_JSON   if "1", emit malformed JSON from `task`
//   STUB_LAUNCH_NO_JOBID   if "1", emit JSON without `jobId` field
//   STUB_COMPLETE_AT_POLL  on `status`, return "completed" once the recorded
//                          poll count reaches this value (1-indexed); before
//                          that, return "running"
//   STUB_NEVER_COMPLETE    if "1", `status` always returns "running"
//   STUB_JOB_NOT_FOUND     if "1", `status` and `result` exit 1 with a
//                          "No job found" stderr message (real companion's
//                          job-not-found shape)
//   STUB_RESULT_RAW        markdown text returned at storedJob.result.rawOutput
//   STUB_RESULT_STDOUT     markdown text returned at storedJob.result.codex.stdout
//                          (used for the rawOutput-fallback test)
//   STUB_RESULT_BAD_JSON   if "1", `result` emits malformed JSON
//   STUB_STATUS_BAD_JSON   if "1", `status` emits malformed JSON
//   STUB_STATUS_EXIT       on `status`, exit non-zero with this code
//                          (distinct from job-not-found)
//   STUB_TERMINAL_STATUS   when `status` reports a terminal state, return this
//                          string instead of "completed" (e.g. "failed",
//                          "cancelled"). result subcommand uses it too.
//   STUB_RESULT_RENDERED   markdown text returned at storedJob.rendered
//                          (used for failed/cancelled fallback test)
//   STUB_RESULT_JOB_ERROR_MESSAGE
//                          string returned at job.errorMessage only
//                          (exercises render.mjs link (d) in isolation)
//   STUB_RESULT_STORED_JOB_ERROR_MESSAGE
//                          string returned at storedJob.errorMessage only
//                          (exercises render.mjs link (e) in isolation)
//   STUB_RESULT_ERROR_MESSAGE
//                          back-compat alias: when set and the two specific
//                          variables above are both unset, populates BOTH
//                          job.errorMessage and storedJob.errorMessage. New
//                          tests should prefer the specific variables.
//
// Phase-fallback variables:
//   STUB_PHASE_ONLY        when set (non-empty), `status` emits a payload that
//                          carries only job.phase (not job.status), simulating
//                          the broker-omitting-job.status pattern.  The value
//                          becomes job.phase in the emitted JSON.
//   STUB_PHASE_ONLY_UNTIL_POLL
//                          when set, `status` emits phase-only payloads for the
//                          first N polls (1-indexed), then reverts to the normal
//                          job.status path governed by STUB_COMPLETE_AT_POLL.
//   STUB_NO_STATUS_NO_PHASE
//                          if "1", `status` emits a payload with neither
//                          job.status nor job.phase — the genuine protocol
//                          violation case that must still exit 14.
//   STUB_EMPTY_PHASE       if "1", `status` emits job.phase: "" (empty string)
//                          instead of the value in STUB_PHASE_ONLY.
//   STUB_NULL_PHASE        if "1", `status` emits job.phase: null (JSON null,
//                          not a string) — covers brokers that serialize unset
//                          optional fields as null rather than omitting them.
//   STUB_PHASE_NUMERIC     when set to a number, `status` emits job.phase as a
//                          JSON number (e.g. 42) instead of a string — covers
//                          the case where extract_json_field would stringify the
//                          number and the case statement falls to the wildcard arm.
// ----------------------------------------------------------------------------

import fs from "node:fs";

function readState(path) {
  try {
    return JSON.parse(fs.readFileSync(path, "utf8"));
  } catch {
    return { polls: 0 };
  }
}

function writeState(path, state) {
  fs.writeFileSync(path, JSON.stringify(state));
}

function fail(message, code = 1) {
  // Mirror real companion main() error handler: write to stderr + exit nonzero.
  process.stderr.write(message + "\n");
  process.exit(code);
}

async function sleep(ms) {
  return new Promise((r) => setTimeout(r, ms));
}

const argv = process.argv.slice(2);
const subcommand = argv[0];
const stateFile = process.env.STUB_STATE_FILE;

async function handleTask() {
  // Optional hang to exercise launch's 5-second guard.
  const hangMs = Number(process.env.STUB_LAUNCH_HANG_MS || 0);
  if (hangMs > 0) await sleep(hangMs);

  const exitCode = Number(process.env.STUB_LAUNCH_EXIT || 0);
  if (exitCode !== 0) fail("simulated launch failure", exitCode);

  if (process.env.STUB_LAUNCH_BAD_JSON === "1") {
    process.stdout.write("{not json at all\n");
    return;
  }

  // Generate a deterministic job id; persist for status/result.
  const jobId = `task-stub-${process.pid}-${Date.now()}`;
  if (stateFile) writeState(stateFile, { jobId, polls: 0 });

  if (process.env.STUB_LAUNCH_NO_JOBID === "1") {
    process.stdout.write(
      JSON.stringify({ status: "queued", title: "stub", summary: "" }) + "\n"
    );
    return;
  }

  // Real shape: { jobId, status, title, summary, logFile }
  process.stdout.write(
    JSON.stringify({
      jobId,
      status: "queued",
      title: "stub task",
      summary: "stub task summary",
      logFile: "/tmp/stub.log"
    }) + "\n"
  );
}

function handleStatus() {
  if (process.env.STUB_JOB_NOT_FOUND === "1") {
    // Real companion's job-not-found path: matchJobReference throws
    // 'No job found for "<ref>". Run /codex:status to inspect known jobs.'
    fail(`No job found for "${argv[1] || "?"}". Run /codex:status to inspect known jobs.`, 1);
  }

  const exitCode = Number(process.env.STUB_STATUS_EXIT || 0);
  if (exitCode !== 0) fail("simulated status failure (not job-not-found)", exitCode);

  if (process.env.STUB_STATUS_BAD_JSON === "1") {
    process.stdout.write("not-json-here\n");
    return;
  }

  const state = stateFile ? readState(stateFile) : { polls: 0 };
  state.polls = (state.polls || 0) + 1;
  if (stateFile) writeState(stateFile, state);

  // STUB_NO_STATUS_NO_PHASE — emit a payload with neither job.status nor job.phase.
  if (process.env.STUB_NO_STATUS_NO_PHASE === "1") {
    const payload = {
      workspaceRoot: process.cwd(),
      job: {
        id: argv[1] || state.jobId || "unknown",
        title: "stub task",
        summary: "stub",
        pid: null
      }
    };
    process.stdout.write(JSON.stringify(payload) + "\n");
    return;
  }

  // STUB_NULL_PHASE — emit a phase-only payload where job.phase is JSON null.
  // Covers brokers that serialize unset optional fields as null rather than omitting.
  if (process.env.STUB_NULL_PHASE === "1") {
    const payload = {
      workspaceRoot: process.cwd(),
      job: {
        id: argv[1] || state.jobId || "unknown",
        phase: null,
        title: "stub task",
        summary: "stub",
        pid: null
      }
    };
    process.stdout.write(JSON.stringify(payload) + "\n");
    return;
  }

  // STUB_PHASE_NUMERIC — emit a phase-only payload where job.phase is a JSON number.
  // extract_json_field stringifies numbers, so the case statement receives e.g. "42"
  // which does not appear in the mapping table and must fall through to malformed.
  if (process.env.STUB_PHASE_NUMERIC !== undefined) {
    const numPhase = Number(process.env.STUB_PHASE_NUMERIC);
    if (isNaN(numPhase)) {
      process.stderr.write(`stub: STUB_PHASE_NUMERIC=${process.env.STUB_PHASE_NUMERIC} is not numeric\n`);
      process.exit(1);
    }
    const payload = {
      workspaceRoot: process.cwd(),
      job: {
        id: argv[1] || state.jobId || "unknown",
        phase: numPhase,
        title: "stub task",
        summary: "stub",
        pid: null
      }
    };
    process.stdout.write(JSON.stringify(payload) + "\n");
    return;
  }

  // STUB_PHASE_ONLY / STUB_PHASE_ONLY_UNTIL_POLL — emit phase-only payload (no job.status).
  const phaseOnlyUntil = process.env.STUB_PHASE_ONLY_UNTIL_POLL
    ? Number(process.env.STUB_PHASE_ONLY_UNTIL_POLL)
    : 0;
  const phaseOnlyAlways = process.env.STUB_PHASE_ONLY !== undefined &&
    process.env.STUB_PHASE_ONLY_UNTIL_POLL === undefined &&
    process.env.STUB_NO_STATUS_NO_PHASE !== "1";

  const usePhaseOnly = phaseOnlyAlways ||
    (phaseOnlyUntil > 0 && state.polls <= phaseOnlyUntil);

  if (usePhaseOnly) {
    // Emit a payload with job.phase but NO job.status.
    let phase;
    if (process.env.STUB_EMPTY_PHASE === "1") {
      phase = "";
    } else {
      phase = process.env.STUB_PHASE_ONLY || "finalizing";
    }
    const jobObj = {
      id: argv[1] || state.jobId || "unknown",
      phase,
      title: "stub task",
      summary: "stub",
      pid: null
    };
    // Deliberately omit job.status to simulate the broker-omitting-status pattern.
    const payload = {
      workspaceRoot: process.cwd(),
      job: jobObj
    };
    process.stdout.write(JSON.stringify(payload) + "\n");
    return;
  }

  let jobStatus = "running";
  if (process.env.STUB_NEVER_COMPLETE !== "1") {
    const completeAt = Number(process.env.STUB_COMPLETE_AT_POLL || 1);
    if (state.polls >= completeAt) {
      jobStatus = process.env.STUB_TERMINAL_STATUS || "completed";
    }
  }

  // Real shape: { workspaceRoot, job: { id, status, title, ... } }
  const payload = {
    workspaceRoot: process.cwd(),
    job: {
      id: argv[1] || state.jobId || "unknown",
      status: jobStatus,
      title: "stub task",
      summary: "stub",
      pid: null
    }
  };
  process.stdout.write(JSON.stringify(payload) + "\n");
}

function handleResult() {
  if (process.env.STUB_JOB_NOT_FOUND === "1") {
    fail(`No finished job found for "${argv[1] || "?"}". Run /codex:status to inspect active jobs.`, 1);
  }

  if (process.env.STUB_RESULT_BAD_JSON === "1") {
    process.stdout.write("definitely not json\n");
    return;
  }

  // Real shape: { job, storedJob }. Markdown lookup chain (render.mjs:401-445):
  //   storedJob.result.rawOutput → storedJob.result.codex.stdout →
  //   storedJob.rendered → job.errorMessage → storedJob.errorMessage
  const rawOutput = process.env.STUB_RESULT_RAW || "";
  const codexStdout = process.env.STUB_RESULT_STDOUT || "";
  const rendered = process.env.STUB_RESULT_RENDERED || "";
  const terminal = process.env.STUB_TERMINAL_STATUS || "completed";

  // Split error-message vars so tests can populate link (d) and link (e) in
  // isolation. The legacy STUB_RESULT_ERROR_MESSAGE env var stays as a
  // both-locations alias for tests written before the split.
  const jobErrorRaw = process.env.STUB_RESULT_JOB_ERROR_MESSAGE;
  const storedJobErrorRaw = process.env.STUB_RESULT_STORED_JOB_ERROR_MESSAGE;
  const legacyErrorRaw = process.env.STUB_RESULT_ERROR_MESSAGE;
  const useLegacy = jobErrorRaw === undefined && storedJobErrorRaw === undefined;
  const jobErrorMessage = useLegacy ? (legacyErrorRaw || "") : (jobErrorRaw || "");
  const storedJobErrorMessage = useLegacy ? (legacyErrorRaw || "") : (storedJobErrorRaw || "");

  // Real companion attaches `result` only on `completed` jobs; failed/cancelled
  // jobs carry only storedJob.rendered + errorMessage. Mirror that.
  const includeResult = terminal === "completed" && (rawOutput || codexStdout);

  const payload = {
    job: {
      id: argv[1] || "unknown",
      status: terminal,
      title: "stub task",
      errorMessage: jobErrorMessage || undefined
    },
    storedJob: {
      id: argv[1] || "unknown",
      status: terminal,
      result: includeResult
        ? {
            status: "completed",
            rawOutput: rawOutput || undefined,
            codex: codexStdout ? { stdout: codexStdout } : undefined
          }
        : undefined,
      rendered: rendered || undefined,
      errorMessage: storedJobErrorMessage || undefined
    }
  };
  process.stdout.write(JSON.stringify(payload) + "\n");
}

(async () => {
  switch (subcommand) {
    case "task":
      await handleTask();
      break;
    case "status":
      handleStatus();
      break;
    case "result":
      handleResult();
      break;
    default:
      fail(`Unknown subcommand: ${subcommand}`);
  }
})();
