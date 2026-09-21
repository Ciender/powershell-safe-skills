---
name: powershell-safe-skills
description: Use before constructing or running Windows commands hosted by PowerShell. Prevent shell, native-argument, path, encoding, and process failures; verify Windows automation outcomes. Requires PowerShell 7 for normal execution, with an explicit, isolated Windows PowerShell 5.1 fallback when necessary.
metadata:
  version: "3.0.0"
---

# PowerShell Safe Skills

Use supplied host facts and the smallest relevant checks. Do not inventory the
machine or load every reference for a simple command. This skill supplies
execution guidance, not access or permission to change unrelated resources.

## Runtime contract

Run normal work on Windows under a verified PowerShell **7.x / Core** process.
Inspect `$PSVersionTable`, not the executable's name. Reuse a verified host;
otherwise choose an installed `pwsh.exe` using the tool's shell option or a
script launched with `-NoLogo -NoProfile -NonInteractive -File`.

When 7 is unavailable or a dependency requires 5.1, follow
[runtime.md](references/runtime.md): verify the limitation, prefer a compatible
7.x API, then isolate only the necessary work in Windows PowerShell 5.1 and
report the reason. Never downgrade in response to an ordinary command failure,
override a user's explicit prohibition, or change PATH/policy to hide a blocker.

## Before execution

- Prefer a cmdlet, then `& $exe @nativeArgs`; use a script/file for multiline or quote-heavy content. Resolve one application path before using `.Source`.
- Keep native arguments separate. Omitted, empty-string, and null arguments differ; preservation depends on the engine and executable. Do not flatten them into a command string.
- Capture `$LASTEXITCODE` immediately and apply the tool's contract (`rg` 1 means no match). Use `-ErrorAction Stop` for required cmdlet operations, not native commands or .NET methods.
- Assign `foreach`/`if`/`switch` output before piping. Group computed parameter values, such as `-Index (100..120)`; use `${name}` before a colon. Do not overwrite automatic variables such as `$PID`, `$HOME`, `$Host`, or `$args`.
- PowerShell does not escape quotes with backslash and does not accept Bash heredocs. Use literal strings, a literal here-string, or a source file instead of stacking parser layers.
- Native globs are tool-specific: use `rg -g '*.md' $root` or enumerate files. For real paths use `-LiteralPath`; verify inputs and the working directory before dependent commands.
- Before recursive mutation, validate the exact filesystem boundary, including reparse points. Keep enumeration and mutation in one shell.
- Keep secrets out of arguments, scripts, process listings, and logs. Prefer credential stores, key/agent authentication, or the target's supported secure input.

## Load by task

| Need | Reference |
| --- | --- |
| Host selection, missing 7, older 7.x capabilities, 5.1 fallback | [Runtime](references/runtime.md) |
| Native arguments, globs, exit codes, statements, Git preflight | [Execution](references/execution.md) |
| Nested shells, here-strings, SSH/Plink/WSL/Bash/SQL | [Cross-shell](references/cross-shell.md) |
| Paths, encoding, JSON/CSV, bulk edits, mapped drives | [Files and configuration](references/files-and-config.md) |
| Output capture, background tasks, locks, ports, services, installations | [Processes and Windows](references/processes-and-windows.md) |
| An observed failure and its shortest diagnostic route | [Diagnostics](references/diagnostics.md) |

## Helpers and verification

Resolve helpers relative to this file, not the project's current directory.
Here `$skillRoot` is the absolute directory containing this `SKILL.md`:

```powershell
& (Join-Path $skillRoot 'scripts/Get-WindowsContext.ps1') -AsJson
& (Join-Path $skillRoot 'scripts/Test-PowerShellScript.ps1') -LiteralPath $scriptPath -AsJson
```

Use the context helper when host facts are missing or relevant to a failure.
For a new script that changes data, run the parser helper on the intended
engine before execution. It never executes the input; parsing alone does not
validate runtime behavior. Both helpers default to 7 and expose an explicit
`-AllowWindowsPowerShell51` switch only for the documented fallback.

For consequential changes, test the applicable risks in a temporary workspace:
special paths/Unicode, absent input, empty/singleton data, native failure, and
repeat execution. Use `-WhatIf` when supported, then verify the actual outcome.
Read back changed data; for app integration, verify the app loaded it. Report
the change, meaningful checks, and any fallback or unverified host behavior.

Maintenance only: [coverage and provenance](references/maintenance.md) records
the source merge and regression cases. Do not load it for routine execution.
