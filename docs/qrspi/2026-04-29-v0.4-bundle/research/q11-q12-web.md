---
status: draft
question_ids: [11, 12]
research_type: web
---

# Q11 + Q12: Claude Code native sandbox; shell-command analysis literature

## Summary

**TL;DR:** Claude Code's native sandbox (open-sourced as `@anthropic-ai/sandbox-runtime`) wraps Bash subprocesses in OS-level isolation — Seatbelt on macOS, bubblewrap + seccomp on Linux/WSL2, Windows unsupported — mediating filesystem reads/writes, network access (via HTTP/SOCKS5 proxy with hostname-only allowlisting, no TLS inspection), and Unix-socket creation; documented gaps include domain fronting, Linux mandatory-deny only blocking existing files, an autonomous `dangerouslyDisableSandbox` escape hatch in auto-allow mode, and an AST-parser layer that fires above the permission/auto-approve check. The shell-analysis literature characterizes shell-effect inference as fundamentally hard because of word expansion, command substitution, eval, dynamic aliases, and parser-differential bugs — static tools (ShellCheck, taint analysis) work well on intentional patterns but cannot resolve runtime-only effects, and modern systems (PaSh-JIT, sandbox-runtime) explicitly switch to runtime/JIT or OS-level mediation rather than relying on pure static parsing.

**Key findings:**
- Claude Code's sandbox is open-source (`anthropic-experimental/sandbox-runtime`, npm `@anthropic-ai/sandbox-runtime`), uses `sandbox-exec`/Seatbelt on macOS and `bubblewrap` + seccomp BPF on Linux/WSL2; Windows is "not yet supported"; pre-built binaries only for x64/arm64.
- Sandbox scope is **only Bash subprocesses** — Read/Edit/Write tools use the permission system directly, and computer-use runs on the actual desktop.
- Configuration surface: `~/.srt-settings.json` and Claude Code `settings.json` `sandbox.*`; allow/deny lists for filesystem reads/writes (merged across scopes), `allowedDomains`/`deniedDomains`, `allowUnixSockets`, `enableWeakerNestedSandbox`, `enableWeakerNetworkIsolation`, `excludedCommands`, `failIfUnavailable`, `allowUnsandboxedCommands`, `httpProxyPort`/`socksProxyPort`.
- Documented gaps: hostname-only proxy (no TLS inspection → domain-fronting risk); Linux mandatory-deny blocks only existing files; `allowLocalBinding` lifts outbound TCP restrictions (issue #225); `denyRead` fails to block individual files inside an `allowRead` directory (issue #193); Docker-nested mode "considerably weakens security"; an "intentional escape hatch" lets Claude retry with `dangerouslyDisableSandbox` (issue #97 reports auto-allow approving this without prompt); AST-parser warnings fire above the auto-approve check (issue #45421).
- Multiple Claude Code permission-bypass issues (#4956, #13371, #16180, #20085, #28784) document that prefix-matched `Bash()` rules were defeated by `&&`, `;`, `|`, options, and `cd` chaining; the documented fix path is "re-architect the permission check to use a proper shell AST parser."
- Claude Code's current bash analysis pipeline (per the leaked source write-up) is defense-in-depth: tree-sitter AST analysis, ~23 regex-based validators when tree-sitter is unavailable, permission rules, then OS-level sandbox; parser-differential bugs are documented (e.g., shell-quote treats CR as a word separator while bash IFS does not; backslash-escaped whitespace decodes differently).
- Shell-analysis literature (Greenberg et al., Smoosh) emphasizes that POSIX shell semantics — particularly word expansion (variable/command substitution, globbing) — make static effect inference unreliable; PaSh moved to a JIT design specifically because pure static parallelization is "always sound and effective impossible."

**Surprises:** The Claude Code documentation explicitly claims shell-operator awareness for prefix rules ("`Bash(safe-cmd:*)` won't give it permission to run `safe-cmd && other-cmd`"), but multiple open issues demonstrate this claim has been historically false; the fix is ongoing AST work. Also, the sandbox has an explicit, documented escape hatch (`dangerouslyDisableSandbox`) that the model can invoke autonomously when commands fail.

**Caveats:** Some community write-ups (zread.ai source-leak summary) reference internal Claude Code source not officially published; specific version numbers and the exact validator count (~23) come from that summary and may drift. Some academic papers (Mazurak/Zdancewic) are referenced via Smoosh's related-work and not directly fetched here.

## Full findings

### Q11: Claude Code native sandbox

#### Per-platform coverage (macOS Seatbelt, Linux bubblewrap, WSL)

- **macOS:** uses `sandbox-exec` with dynamically generated Seatbelt profiles; works out of the box; supports git-style glob patterns; automatic violation detection via macOS system log store. https://github.com/anthropic-experimental/sandbox-runtime/blob/main/README.md and https://code.claude.com/docs/en/sandboxing
- **Linux:** uses `bubblewrap` (filesystem isolation) + `socat` (proxy) + seccomp BPF (blocks `socket()` AF_UNIX, `io_uring_setup/_enter/_register`); literal paths only (no globs); manual violation detection via `strace`. https://code.claude.com/docs/en/sandboxing and https://github.com/anthropic-experimental/sandbox-runtime/blob/main/README.md
- **WSL2** uses bubblewrap, same as Linux. **WSL1 not supported** (lacks Linux namespace primitives). On WSL2, sandboxed commands cannot launch Windows binaries (`cmd.exe`, `powershell.exe`, `/mnt/c/...`); requires `excludedCommands`. https://code.claude.com/docs/en/sandboxing
- **Windows native:** "Not yet supported"; "Native Windows support is planned." https://github.com/anthropic-experimental/sandbox-runtime/blob/main/README.md and https://code.claude.com/docs/en/sandboxing
- **Architectures:** x64 and arm64 only with pre-built binaries. https://www.npmjs.com/package/@anthropic-ai/sandbox-runtime

#### Per-tool coverage (which tool calls are sandboxed)

- The sandbox isolates **Bash subprocesses only**. Quoting docs: "The sandbox isolates Bash subprocesses. Other tools operate under different boundaries: Built-in file tools — Read, Edit, and Write use the permission system directly rather than running through the sandbox." https://code.claude.com/docs/en/sandboxing
- Restrictions apply to **all child processes** spawned by sandboxed bash commands (kubectl, terraform, npm), at the OS level. https://code.claude.com/docs/en/sandboxing
- Computer use (CLI/Desktop) "runs on your actual desktop rather than in an isolated environment." https://code.claude.com/docs/en/sandboxing
- Sandbox can also wrap arbitrary processes via `npx @anthropic-ai/sandbox-runtime <cmd>` or the `srt` binary, including MCP servers. https://github.com/anthropic-experimental/sandbox-runtime/blob/main/README.md

#### Configuration surface

- Settings file: `~/.srt-settings.json` (overridable with `--settings`); Claude Code `settings.json` `sandbox.*` block. https://github.com/anthropic-experimental/sandbox-runtime/blob/main/README.md and https://code.claude.com/docs/en/sandboxing
- **Filesystem:** `filesystem.allowWrite`, `filesystem.denyWrite`, `filesystem.allowRead`, `filesystem.denyRead`, `mandatoryDenySearchDepth` (1–10, Linux only, default 3); paths support `/`, `~/`, `./`, with documented merge semantics across managed/user/project/local scopes. https://code.claude.com/docs/en/sandboxing
- **Network:** `network.allowedDomains`, `network.deniedDomains`, `network.allowUnixSockets` (macOS), `network.allowAllUnixSockets`, `network.allowLocalBinding`; custom proxy via `httpProxyPort`/`socksProxyPort`. https://github.com/anthropic-experimental/sandbox-runtime/blob/main/README.md
- **Modes:** `/sandbox` slash command toggles between Auto-allow and Regular permissions modes. `failIfUnavailable` (hard fail if dependencies missing), `allowUnsandboxedCommands` (disable the `dangerouslyDisableSandbox` escape hatch), `allowManagedDomainsOnly`, `allowManagedReadPathsOnly`. https://code.claude.com/docs/en/sandboxing
- **Weakening switches:** `enableWeakerNestedSandbox` (Docker compatibility), `enableWeakerNetworkIsolation` (macOS trustd access for Go TLS verification). https://github.com/anthropic-experimental/sandbox-runtime/blob/main/README.md
- **Per-command exclusion:** `excludedCommands` runs specific binaries outside the sandbox (recommended for `docker`, `watchman`-using tools). https://code.claude.com/docs/en/sandboxing

#### Documented gaps and limitations

- **No TLS inspection:** built-in proxy decides allow/deny "from the client-supplied hostname without inspecting TLS"; documented domain-fronting risk on broad allows like `github.com`. https://code.claude.com/docs/en/sandboxing
- **Privilege escalation via Unix sockets:** `allowUnixSockets` granting `/var/run/docker.sock` "would effectively grant access to the host system." https://code.claude.com/docs/en/sandboxing
- **Filesystem permission escalation:** broad write access to `$PATH` or shell-rc files enables code execution in different security contexts. https://code.claude.com/docs/en/sandboxing
- **Linux mandatory-deny blocks only existing files** (non-existent files unblocked). https://github.com/anthropic-experimental/sandbox-runtime/blob/main/README.md
- **HTTP_PROXY-ignoring programs** can bypass Linux network filtering. https://github.com/anthropic-experimental/sandbox-runtime/blob/main/README.md
- **Issue #225:** `allowLocalBinding: true` unintentionally lifts outbound TCP restrictions. https://github.com/anthropic-experimental/sandbox-runtime/issues
- **Issue #193:** `denyRead` fails inside `allowRead` directories. https://github.com/anthropic-experimental/sandbox-runtime/issues
- **Issue #221:** sandbox creation fails when `.git/hooks` is a symlink to a directory. https://github.com/anthropic-experimental/sandbox-runtime/issues
- **Issue #213:** bridge socket silently fails when `TMPDIR` exceeds the 108-char Unix socket limit. https://github.com/anthropic-experimental/sandbox-runtime/issues
- **Issue #180:** fails inside unprivileged Docker containers. https://github.com/anthropic-experimental/sandbox-runtime/issues
- **Issue #97:** in auto-allow mode, Claude can autonomously retry failed commands with `dangerouslyDisableSandbox: true`; reporter received no permission dialog. https://github.com/anthropic-experimental/sandbox-runtime/issues/97
- **Issue #45421:** Bash AST parser warning fires above the permission check, bypassing auto-approve (e.g., on `python -c "print('here')\n# comment\n"`). https://github.com/anthropic-experimental/claude-code/issues/45421 (canonical: https://github.com/anthropics/claude-code/issues/45421)
- **Custom proxy:** "Custom proxy configuration is not yet supported in the new configuration format." https://github.com/anthropic-experimental/sandbox-runtime/blob/main/README.md
- **Performance:** "Minimal, but some filesystem operations may be slightly slower." https://code.claude.com/docs/en/sandboxing
- **Internal effectiveness statistic:** "sandboxing safely reduces permission prompts by 84%" (internal usage). https://www.anthropic.com/engineering/claude-code-sandboxing

### Q12: Shell-command analysis literature

#### Techniques used

- **Lexer + AST parsing.** Tools like ShellCheck and `koalaman/shellcheck`-style analyzers parse scripts to a syntax tree to flag bug patterns. https://www.shellcheck.net/ and https://github.com/koalaman/shellcheck
- **Bash AST tooling for permission checks.** Claude Code currently uses tree-sitter–based AST analysis to isolate individual commands inside chained inputs, plus a "chain of 23+ regex-based validators" as a tree-sitter-unavailable fallback (per source-leak write-up). https://www.straiker.ai/blog/claude-code-source-leak-with-great-agency-comes-great-responsibility
- **Static taint analysis.** Tracking user-controlled data into `subprocess.run(shell=True)`, `os.system`, `popen`, `exec` sinks. https://docs.moderne.io/openrewrite-advanced-program-analysis/security/command-injection/ and https://www.sonarsource.com/solutions/taint-analysis/
- **LLM-assisted taint analysis** for embedded firmware command injection (95% accuracy on sink identification with double-check). https://www.sciencedirect.com/science/article/abs/pii/S0167404824002761
- **Formal executable semantics.** Greenberg & Blatt's Smoosh defines a formal mechanized small-step semantics for the POSIX shell. https://arxiv.org/abs/1907.05308 and https://dl.acm.org/doi/10.1145/3371111
- **JIT/dynamic interposition.** PaSh-JIT alternates interpretation and compilation, using runtime shell state, variables, directory, and file contents because "shell execution depends on dynamic components like file system and environment variables, making a static parallelization procedure that is always sound and effective impossible." https://www.usenix.org/system/files/osdi22-kallas.pdf and https://github.com/binpash/pash
- **AST-based ML for malicious script classification.** PowerShell AST + L-moments / CNN-BiLSTM detectors for malware family classification. https://arxiv.org/pdf/1810.09230 and https://www.sciencedirect.com/science/article/pii/S0167404824003870

#### Accuracy properties / known limits

- **Theoretical bound:** "all static-program-analysis problems of interest are undecidable"; reduces from the halting problem. https://dl.acm.org/doi/10.1145/161494.161501
- **Bash's intentional command injection:** "Bash performs Command Injection intentionally and often, and static analyses cannot distinguish between the intentional and unintentional instances." https://blogs.grammatech.com/static-analysis-and-bash-bug
- **Word expansion is the central difficulty.** Smoosh authors describe word expansion (variable substitution, command substitution, globbing) as "simultaneously part of the shell's power and part of its danger" because "it is very easy for word expansion to generate too many or too few arguments to a command." https://arxiv.org/abs/1907.05308
- **Aliases and parsing-unit boundaries.** "Alias expansion happens at parse time… aliases can't be defined and used in the same parsing unit." https://www.shellcheck.net/wiki/
- **Hard parse failures.** ShellCheck "completely stops parsing" on certain advanced bash syntax (e.g., assigning file descriptors to specific array indices). https://github.com/koalaman/shellcheck/issues/2947 and https://www.shellcheck.net/wiki/Parser-error
- **Parser-differential vulnerabilities.** Real-world: shell-quote's `[^\s]` treats CR as a word separator while bash IFS does not; backslash-escaped whitespace tokenizes differently between shell-quote and bash, enabling injection. https://wh0.github.io/2021/10/24/shell-quote-rce.html and https://security.snyk.io/vuln/npm:shell-quote:20160621
- **Shell-conformance variance** across implementations: Smoosh tested against bash, dash, zsh, OSH, mksh, ksh93, yash and found differences in POSIX conformance even on standardized features. https://arxiv.org/abs/1907.05308
- **Practical-correctness reframing.** PaSh-JIT explicitly trades soundness guarantees for "practical correctness" — runtime checks plus annotated command specs — because pure static analysis cannot capture the needed invariants. https://www.usenix.org/system/files/osdi22-kallas.pdf
- **Permission-bypass class (operational).** Multiple Claude Code issues document prefix-match permission bypass via `&&`, `;`, `|`, option insertion, and `cd path && cmd` chaining: https://github.com/anthropics/claude-code/issues/4956, https://github.com/anthropics/claude-code/issues/13371, https://github.com/anthropics/claude-code/issues/16180, https://github.com/anthropics/claude-code/issues/20085, https://github.com/anthropics/claude-code/issues/28784. The acknowledged remediation: "re-architect to use a proper shell Abstract Syntax Tree (AST) parser."

#### Alternative mechanisms compared

- **OS-level sandboxing (Seatbelt, bubblewrap+seccomp).** Mediates effects at the kernel boundary regardless of how the shell parses them, side-stepping word-expansion ambiguity. https://code.claude.com/docs/en/sandboxing and https://github.com/anthropic-experimental/sandbox-runtime/blob/main/README.md
- **Network proxying.** Hostname-allowlist proxies block effects post-DNS regardless of shell-level intent, but cannot inspect TLS payloads (domain-fronting limitation). https://code.claude.com/docs/en/sandboxing
- **Containers/VMs.** Stronger isolation than Seatbelt/bubblewrap but heavier; community write-ups document Docker/firejail/Apple Container wrappers around Claude Code. https://github.com/CaptainMcCrank/SandboxedClaudeCode and https://www.mintmcp.com/blog/sandbox-claude-code
- **Defense-in-depth combinations.** Claude Code's stack: tree-sitter AST + regex validators + permission rules + OS sandbox; the AST layer feeds the permission system to mitigate chaining-bypass classes. https://www.straiker.ai/blog/claude-code-source-leak-with-great-agency-comes-great-responsibility
- **Quoting/escaping libraries vs. parsing.** `shlex.quote` (Python) and `shell-quote` (JS) escape inputs rather than analyze them; their failure modes are parser-differential (analyzer's parse ≠ shell's parse). https://wh0.github.io/2021/10/24/shell-quote-rce.html and https://research.cs.wisc.edu/mist/SoftwareSecurityCourse/Chapters/3_8_2-Command-Injections.pdf
- **JIT/runtime mediation (PaSh-JIT) vs. pure static analysis.** PaSh moved from static-only to JIT precisely because dynamic shell features defeated soundness. https://www.usenix.org/system/files/osdi22-kallas.pdf
- **Formal semantics as a foundation, not a runtime check.** Smoosh provides a reference oracle for shell behavior but is positioned as enabling "new shells, new tooling for shells, and new shell designs" rather than direct runtime defense. https://arxiv.org/abs/1907.05308

## Sources

- https://github.com/anthropic-experimental/sandbox-runtime
- https://github.com/anthropic-experimental/sandbox-runtime/blob/main/README.md
- https://github.com/anthropic-experimental/sandbox-runtime/issues
- https://github.com/anthropic-experimental/sandbox-runtime/issues/97
- https://github.com/anthropic-experimental/sandbox-runtime/blob/main/src/sandbox/macos-sandbox-utils.ts
- https://www.npmjs.com/package/@anthropic-ai/sandbox-runtime
- https://code.claude.com/docs/en/sandboxing
- https://www.anthropic.com/engineering/claude-code-sandboxing
- https://github.com/anthropics/claude-code/issues/32251
- https://github.com/anthropics/claude-code/issues/4956
- https://github.com/anthropics/claude-code/issues/13371
- https://github.com/anthropics/claude-code/issues/16180
- https://github.com/anthropics/claude-code/issues/20085
- https://github.com/anthropics/claude-code/issues/28784
- https://github.com/anthropics/claude-code/issues/45421
- https://www.shellcheck.net/
- https://github.com/koalaman/shellcheck
- https://www.shellcheck.net/wiki/Parser-error
- https://github.com/koalaman/shellcheck/issues/2947
- https://arxiv.org/abs/1907.05308
- https://dl.acm.org/doi/10.1145/3371111
- https://greenberg.science/papers/obt2017.pdf
- https://greenberg.science/papers/hotos2021_shell.pdf
- https://www.usenix.org/system/files/osdi22-kallas.pdf
- https://arxiv.org/pdf/2007.09436
- https://github.com/binpash/pash
- https://blogs.grammatech.com/static-analysis-and-bash-bug
- https://dl.acm.org/doi/10.1145/161494.161501
- https://docs.moderne.io/openrewrite-advanced-program-analysis/security/command-injection/
- https://www.sciencedirect.com/science/article/abs/pii/S0167404824002761
- https://wh0.github.io/2021/10/24/shell-quote-rce.html
- https://security.snyk.io/vuln/npm:shell-quote:20160621
- https://research.cs.wisc.edu/mist/SoftwareSecurityCourse/Chapters/3_8_2-Command-Injections.pdf
- https://www.straiker.ai/blog/claude-code-source-leak-with-great-agency-comes-great-responsibility
- https://www.infralovers.com/blog/2026-02-15-sandboxing-claude-code-macos/
- https://claudefa.st/blog/guide/sandboxing-guide
- https://www.truefoundry.com/blog/claude-code-sandboxing
- https://github.com/CaptainMcCrank/SandboxedClaudeCode
- https://github.com/nikvdp/cco
- https://www.mintmcp.com/blog/sandbox-claude-code
- https://arxiv.org/pdf/1810.09230
- https://www.sciencedirect.com/science/article/pii/S0167404824003870
