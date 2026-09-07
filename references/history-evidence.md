# Historical Evidence And Coverage

This file supports maintenance and evaluation of the skill. Do not load it for ordinary PowerShell command execution; the operational rules are already distilled into `SKILL.md` and the topic references.

## Loading Boundary

When the skill triggers, its metadata and `SKILL.md` are the normal context. Files under `references/` are progressive-disclosure resources: they are read only when the task or maintenance work needs them. Keeping evidence here preserves auditability without expanding every PowerShell interaction.

## Dataset Reviewed

Review date: 2026-09-07.

- 848 rollout JSONL files under `.codex/sessions` and `.codex/archived_sessions`.
- 6,622 PowerShell-hosted command records in `thread_history_1.sqlite`: 6,066 completed, 511 failed, and 45 declined.
- 2,109 older rollout `exec_command_end` records hosted by PowerShell, including 218 nonzero exits.
- `history.jsonl` for terminal errors pasted directly by the user.
- `logs_2.sqlite`, `state_5.sqlite`, and the thread catalog were inspected for schema and coverage.

The rollout and modern-database populations overlap; do not add their totals together. Counts below are observed command records, not necessarily unique incidents. Some categories overlap.

## Repeated Patterns

| Observed pattern | Count | Interpretation | Operational location |
| --- | ---: | --- | --- |
| Direct `foreach (...) { ... } | ...` | 47 | PowerShell parser failure: empty pipeline element | `SKILL.md`; `cmdlets-filesystem.md` |
| Missing paths used by dependent reads | 41 | Preflight failure, often followed by noisy secondary errors | `SKILL.md`; `diagnostics.md` |
| `rg` exit code 1 with empty output | 38 | No match, incorrectly treated as execution failure | `SKILL.md`; `native-commands.md` |
| Git command outside a repository | 29 | Wrong working directory or assumed repository | `native-commands.md`; `diagnostics.md` |
| File read/hash/copy blocked by an open handle | 18 | Windows sharing or process-lock issue | `process-encoding.md`; `diagnostics.md` |
| Missing executable or cmdlet | 15 | PATH, module, shell, or installation mismatch | `SKILL.md`; `native-commands.md`; `diagnostics.md` |
| Nested quoting or Bash-style `\"` corruption | 14 | PowerShell string ended early; fragments became syntax | `SKILL.md`; `cross-shell.md`; `diagnostics.md` |
| Native wildcard path passed literally | 11 | Typical Windows error 123; tool never received expanded files | `SKILL.md`; `native-commands.md`; `diagnostics.md` |
| Bash heredoc sent to PowerShell | 6 | `python - <<'PY'` is not PowerShell syntax | `SKILL.md`; `cross-shell.md`; `diagnostics.md` |
| Ungrouped range after `Select-Object -Index` | 1 | Argument mode treated `45..85` as a literal value | `SKILL.md`; `cmdlets-filesystem.md`; `diagnostics.md` |
| `$skill-installer` typed at a `PS>` prompt | 1 user-reported | `$` started a variable expression rather than invoking a command | `SKILL.md`; `cross-shell.md`; `diagnostics.md`; `README.md` |

The modern database contained 73 parser-error records. Besides the dominant direct-`foreach` failures, observed parser details included ten unexpected-token cases, six Bash-heredoc redirection failures, five missing-closing-delimiter cases, one invalid variable followed by a colon, one invalid array-index expression caused by nested quoting, and one attempt to append `-ErrorAction` to a .NET method call.

## Low-Frequency Or High-Impact Safeguards Retained

These rules remain even when history contains few or no direct failures because the consequence or misdiagnosis risk is high:

- Recursive delete/move/overwrite must verify the resolved target remains inside the intended root.
- Secrets must not be placed in command arguments, generated scripts, process listings, or retained logs.
- `Start-Process -ArgumentList` is a joined command-line string, not a structured argument API.
- `ProcessStartInfo.ArgumentList` is preferred when exact separate-process argument boundaries matter.
- Mapped drives are session- and identity-scoped; automation may need a verified UNC path.
- UTF-8/BOM and terminal-decoding problems must be distinguished from actual file corruption.
- Binary content must not pass through text cmdlets.
- Native nonzero exit codes must be interpreted using the target program's contract.
- Nested `pwsh -Command`, `cmd.exe /c`, `Invoke-Expression`, and multi-shell quoting add parser layers and should be removed before adding escapes.
- Common parameters such as `-ErrorAction` do not apply to .NET method calls or native executables.
- A command discovered by `Get-Command` may have multiple application candidates; select and verify one path.
- Do not stop unrelated processes merely to inspect a locked file.

## Maintenance Rule

Keep historical evidence separate from the operational checklist. When revising the skill:

1. Re-scan current history rather than assuming old frequencies remain representative.
2. Preserve low-frequency safeguards when impact is high or failure is hard to diagnose.
3. Promote only the shortest actionable form into `SKILL.md`.
4. Put detailed mechanics in the existing topic reference instead of creating a second operational guide.
5. Update this evidence file with counts and rationale; do not duplicate full how-to examples here.

## Maintenance Session Provenance

This section is derived from the local database and the current session JSONL, not from a user-pasted summary or an assistant final response.

### Source Handling

- The maintenance run was verified against its local conversation database and primary event stream before statistics were recorded.
- Exact session identifiers, database row identifiers, conversation titles, usernames, machine names, and absolute local paths are intentionally omitted.
- The active window had not yet been projected into the standard Codex thread-history database when checked; the verified local runtime record was used instead.

### Historical Statistics Extracted By This Session

The following values come from tool-result records in the session JSONL:

- Modern database: 6,622 PowerShell command executions—6,066 completed, 511 failed, and 45 declined.
- Older rollout population: 2,109 PowerShell-wrapped executions, including 218 nonzero exits.
- Core classified patterns: 47 direct `foreach` pipelines, 41 missing paths, 38 `rg` no-match exits, 29 Git wrong-directory cases, 18 file locks, 15 missing commands, 14 backslash-quote parser breaks, 11 literal native globs, and 6 Bash heredocs executed through PowerShell.
- The modern category pass classified 73 parser errors, 50 path/glob cases, 25 Git wrong-directory cases, 20 network/HTTP failures, 14 access/lock cases, 13 timeouts, 12 missing-command cases, 11 encoding cases, and one each for native-regex, SSH-authentication, and parameter-binding failures. These broad categories differ from the core-signature counts above and must not be summed.

### Session-Native Validation Evidence

- The first parser pass inspected 65 PowerShell-fenced blocks and found three unexpected parse failures plus four intentionally invalid examples.
- The three unexpected failures were documentation defects: Bash heredoc text fenced as PowerShell, command-style angle-bracket placeholders, and `$skill-installer` shown in an executable PowerShell fence.
- After correcting fences and placeholders, the session parser inspected 61 executable PowerShell examples with zero parse failures.
- The PowerShell 7.6 smoke result reported `ForeachCapture=ok`, `ConditionalValue=ok`, and `PythonStdin=ok`.
- `RipgrepContract=skipped`: the isolated process could not resolve `rg.exe`. The subsequent `where.exe rg` probe exited 1 and emitted mojibake, so no live-ripgrep success was claimed.
- Later deduplication left 40 executable examples; a subsequent validation parsed all 40 with zero failures in both PowerShell 7.6 and Windows PowerShell 5.1.
- Git preflight smoke verification observed exit 128 outside a repository and exit 0 after repository initialization.

### Failures Observed In The Maintenance Session Itself

- A missing-executable discovery probe (`where.exe rg`) returned exit 1. This is an expected negative lookup result, not proof that `where.exe` malfunctioned; the target command's exit contract still matters.
- The same probe's Chinese diagnostic was decoded incorrectly. This reinforces the rule that terminal mojibake is an encoding observation and does not by itself prove file corruption.
- Parser validation initially treated prose/negative examples as executable because their Markdown fences or placeholders were wrong. Intentionally invalid commands must use `text` fences, and PowerShell examples must contain syntactically valid placeholders.
- Six SQLite lookup attempts in the correction phase failed because old schema assumptions or incompatible raw-query parameters were reused. These were database-query mistakes, not PowerShell failures, and were not promoted into the PowerShell runtime checklist.

### Change History Confirmed By Session Records

- The initial pass created `references/history-derived-failures.md` and expanded the operational references.
- A later consolidation deleted that assistant-created duplicate file after moving its evidence into `history-evidence.md`; no pre-existing user-authored file was deleted.
- The runtime-facing `SKILL.md` was reduced while evidence and low-frequency/high-impact safeguards remained in progressive-disclosure references.
- The Git working-directory preflight, temporarily lost during consolidation, was restored to `native-commands.md` and `diagnostics.md`.
- No password, token, cookie, private key, or secret value from any database, JSONL, log, or token-store path was copied into the skill.
