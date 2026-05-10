#!/usr/bin/env node
// sibling-impact.mjs — QRSPI cross-task drift detector.
//
// Usage:
//   node scripts/sibling-impact.mjs --task-id <NN> --commit <SHA> \
//       [--base <branch>] [--tasks-dir <path>] [--code-path <path>]
//
// Diffs <base>..<commit>, finds sibling task dirs whose spec/code files
// reference changed files (substring match), and writes notification entries
// to those siblings' notifications/ directories.
//
// `--code-path` is the absolute path to the target code repository whose git
// history holds <commit>. Used to support split-workspace layouts where the
// QRSPI artifact directory and the target repo live on different filesystem
// branches (e.g. artifacts in Dropbox, code in ~/code/<repo>). When omitted,
// the script falls back to deriving projectRoot from `<tasksDir>/..` (the
// recommended sibling layout per `using-qrspi/SKILL.md` § Recommended
// Workspace Layout). See PR #153 issue #157 for the original incident.
//
// Pure Node 18+ stdlib. No npm dependencies.

import { execFileSync } from 'node:child_process';
import { readFileSync, readdirSync, mkdirSync, writeFileSync, statSync } from 'node:fs';
import { join, basename, resolve, isAbsolute } from 'node:path';
import { exit } from 'node:process';

// ---------------------------------------------------------------------------
// Argument parsing
// ---------------------------------------------------------------------------

function parseArgs(argv) {
  const args = {
    taskId: null,
    commit: null,
    base: 'main',
    tasksDir: 'tasks/',
    codePath: null,
  };
  let i = 0;
  while (i < argv.length) {
    const arg = argv[i];
    if (arg === '--task-id' && i + 1 < argv.length) {
      args.taskId = argv[i + 1];
      i += 2;
    } else if (arg === '--commit' && i + 1 < argv.length) {
      args.commit = argv[i + 1];
      i += 2;
    } else if (arg === '--base' && i + 1 < argv.length) {
      args.base = argv[i + 1];
      i += 2;
    } else if (arg === '--tasks-dir' && i + 1 < argv.length) {
      args.tasksDir = argv[i + 1];
      i += 2;
    } else if (arg === '--code-path' && i + 1 < argv.length) {
      args.codePath = argv[i + 1];
      i += 2;
    } else {
      i++;
    }
  }
  return args;
}

// ---------------------------------------------------------------------------
// Filesystem helpers
// ---------------------------------------------------------------------------

/**
 * Recursively collect all file paths under a directory.
 * Returns absolute paths.
 */
function walkDir(dirPath) {
  const results = [];
  let entries;
  try {
    entries = readdirSync(dirPath);
  } catch {
    return results;
  }
  for (const entry of entries) {
    const fullPath = join(dirPath, entry);
    let stat;
    try {
      stat = statSync(fullPath);
    } catch {
      continue;
    }
    if (stat.isDirectory()) {
      results.push(...walkDir(fullPath));
    } else if (stat.isFile()) {
      results.push(fullPath);
    }
  }
  return results;
}

// ---------------------------------------------------------------------------
// Timestamp helper
// ---------------------------------------------------------------------------

/**
 * Returns a filesystem-safe ISO 8601 timestamp.
 * Shape: 2026-05-09T18-04-22Z (colons replaced with hyphens, no ms).
 */
function safeTimestamp() {
  const now = new Date();
  return now.toISOString()
    .replace(/\.\d{3}Z$/, 'Z')   // drop milliseconds
    .replace(/:/g, '-');           // replace colons with hyphens
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

function main() {
  const args = parseArgs(process.argv.slice(2));

  // Validate required flags
  if (!args.taskId) {
    console.error('error: --task-id required');
    exit(1);
  }
  if (!args.commit) {
    console.error('error: --commit required');
    exit(1);
  }

  const tasksDir = isAbsolute(args.tasksDir)
    ? args.tasksDir
    : resolve(process.cwd(), args.tasksDir);

  // Validate tasks-dir
  let tasksDirStat;
  try {
    tasksDirStat = statSync(tasksDir);
  } catch (err) {
    console.error(`error: tasks-dir not found: ${tasksDir}`);
    exit(1);
  }
  if (!tasksDirStat.isDirectory()) {
    console.error(`error: tasks-dir is not a directory: ${tasksDir}`);
    exit(1);
  }

  // Derive project root.
  // - When --code-path is provided, use it verbatim. This supports split-workspace
  //   layouts where the QRSPI artifact directory and the target code repo live on
  //   different filesystem branches (issue #157).
  // - When --code-path is omitted, fall back to `<tasksDir>/..` — the recommended
  //   sibling layout per `using-qrspi/SKILL.md` § Recommended Workspace Layout.
  let projectRoot;
  if (args.codePath) {
    projectRoot = isAbsolute(args.codePath)
      ? args.codePath
      : resolve(process.cwd(), args.codePath);
    let codePathStat;
    try {
      codePathStat = statSync(projectRoot);
    } catch (err) {
      console.error(`error: code-path not found: ${projectRoot}`);
      exit(1);
    }
    if (!codePathStat.isDirectory()) {
      console.error(`error: code-path is not a directory: ${projectRoot}`);
      exit(1);
    }
  } else {
    projectRoot = resolve(tasksDir, '..');
  }

  // Run git diff to get changed files.
  // Diff the commit vs its immediate parent (commit^) to capture only what
  // this specific commit introduced. Fall back to diffing vs --base if the
  // commit has no parent (i.e., it is the root commit).
  let diffBase;
  try {
    execFileSync('git', ['rev-parse', '--verify', `${args.commit}^`], {
      cwd: projectRoot,
      encoding: 'utf8',
      stdio: 'pipe',
    });
    diffBase = `${args.commit}^`;
  } catch {
    // No parent — use --base
    diffBase = args.base;
  }

  let diffOutput;
  try {
    diffOutput = execFileSync(
      'git',
      ['diff', '--name-only', diffBase, args.commit],
      { cwd: projectRoot, encoding: 'utf8' }
    );
  } catch (err) {
    console.error(`error: git diff failed: ${err.message}`);
    exit(1);
  }

  const changedFiles = diffOutput
    .split('\n')
    .map(l => l.trim())
    .filter(l => l.length > 0);

  // The source task's own directory prefix (relative to project root)
  // e.g. "tasks/task-01/"
  const tasksDirRelative = 'tasks/';
  const sourceTaskPrefix = `tasks/task-${args.taskId}/`;

  // Filter to changes outside the source task's own directory
  const externalChanges = changedFiles.filter(f => !f.startsWith(sourceTaskPrefix));

  if (externalChanges.length === 0) {
    // Nothing to do
    exit(0);
  }

  // Discover sibling task directories
  let taskEntries;
  try {
    taskEntries = readdirSync(tasksDir);
  } catch (err) {
    console.error(`error: could not read tasks-dir: ${err.message}`);
    exit(1);
  }

  const siblingTaskDirs = taskEntries.filter(entry => {
    if (!/^task-\d+$/.test(entry)) return false;
    // Skip the source task itself
    const taskNum = entry.replace(/^task-/, '');
    return taskNum !== args.taskId;
  });

  const timestamp = safeTimestamp();

  for (const changedFile of externalChanges) {
    // Derive basename for matching when the changed path has no directory
    // component (root-level files). For files with directory components,
    // use the full path to avoid spurious matches on bare filenames.
    const changedBasename = basename(changedFile);
    const changedDir = changedFile.includes('/') ? changedFile.replace(/[^/]+$/, '').replace(/\/$/, '') : null;
    // Use full-path matching only. Basename-only matching causes too many
    // false positives when different tasks mention the filename in unrelated
    // contexts. The contract (Phase 1) is: match the full relative path.
    const matchStrings = [changedFile];
    if (!changedDir) {
      // Root-level file: basename == full path, no extra match needed
    }
    // (basename match deferred to Phase 2 symbol-aware diff)

    for (const siblingDir of siblingTaskDirs) {
      const siblingDirPath = join(tasksDir, siblingDir);
      const siblingFiles = walkDir(siblingDirPath);

      let isAffected = false;
      for (const siblingFile of siblingFiles) {
        // Skip already-existing notification files to avoid false self-referencing
        if (siblingFile.includes('/notifications/')) continue;

        let contents;
        try {
          contents = readFileSync(siblingFile, 'utf8');
        } catch {
          // Binary or unreadable file — skip
          continue;
        }

        for (const matchStr of matchStrings) {
          if (contents.includes(matchStr)) {
            isAffected = true;
            break;
          }
        }
        if (isAffected) break;
      }

      if (!isAffected) continue;

      // Extract task number from sibling dir name for display
      const siblingTaskNum = siblingDir.replace(/^task-/, '');

      // Write notification
      const notificationsDir = join(siblingDirPath, 'notifications');
      try {
        mkdirSync(notificationsDir, { recursive: true });
      } catch (err) {
        console.error(`error: could not create notifications dir: ${err.message}`);
        exit(1);
      }

      const notificationFilename = `${timestamp}-from-task-${args.taskId}.md`;
      const notificationPath = join(notificationsDir, notificationFilename);

      const suggestedAction = `Review the diff at ${args.commit} and refit, or mark n/a.`;

      const content = [
        '---',
        `source_task: ${args.taskId}`,
        `source_commit: ${args.commit}`,
        `target_file: ${changedFile}`,
        `change_shape: file_changed`,
        `suggested_action: ${suggestedAction}`,
        '---',
        '',
        '## Suggested action',
        '',
        suggestedAction,
        '',
      ].join('\n');

      try {
        writeFileSync(notificationPath, content, 'utf8');
      } catch (err) {
        console.error(`error: could not write notification: ${err.message}`);
        exit(1);
      }

      // Print relative path for readability
      const relPath = `tasks/${siblingDir}/notifications/${notificationFilename}`;
      console.log(`Wrote ${relPath}`);
    }
  }

  exit(0);
}

main();
