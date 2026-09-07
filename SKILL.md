---
name: powershell-safe-skills
description: Use before any Windows shell command hosted by PowerShell or pwsh, even when the user does not mention PowerShell. Prevents common PowerShell 7 and Windows PowerShell 5.1 failures involving native arguments, foreach/pipelines, quoting, globs, SSH/Plink/WSL/Bash/SQL, encoding, paths, processes, and file locks.
---

# PowerShell Safe Skills

Use this checklist before constructing a Windows shell command. Prefer PowerShell 7 through `pwsh.exe`; use `powershell.exe` only when Windows PowerShell 5.1 is explicitly required.

## Choose The Execution Form

Use the first option that fits:

1. PowerShell cmdlet.
2. Native executable with `& $exe @nativeArgs`.
3. Temporary `.ps1` or target-language source file for multiline or quote-heavy code.
4. `ProcessStartInfo.ArgumentList` when a separate process needs exact argument boundaries or captured streams.
5. `Start-Process` only for elevation, window behavior, detachment, or shell association.
6. `cmd.exe /c` only for required cmd/batch semantics.
7. `Invoke-Expression` only as a last resort for trusted PowerShell source.

## Verify The Shell

PowerShell 7 (`pwsh.exe`) is the preferred runtime. Use Windows PowerShell 5.1
(`powershell.exe`) only when compatibility requires it, and verify the active
shell because cmdlet parameters and native argument behavior can differ.

```powershell
$PSVersionTable.PSVersion
$PSNativeCommandArgumentPassing
Get-Command pwsh -ErrorAction SilentlyContinue
Get-Command powershell -ErrorAction SilentlyContinue
```

## Mandatory Preflight

- Keep each native argument as one array item. Never flatten a command into one quoted string.
- Capture `$LASTEXITCODE` immediately after native commands; use `-ErrorAction Stop` for cmdlets. Apply the program's exit-code contract—`rg` code 1 means no matches.
- Capture output from `foreach`, `if`, or `switch` before piping or embedding it. `foreach (...) { ... } | ...` is invalid.
- Never use Bash heredocs such as `python - <<'PY'` in PowerShell. Pipe a literal here-string to the interpreter or use a file.
- Backslash does not escape quotes in PowerShell. If regex, JSON, SQL, or nested quotes become difficult to inspect, use a file instead of adding escapes.
- Do not rely on native wildcard expansion. Use the tool's glob option, such as `rg -g '*.md' $root`, or enumerate paths first.
- Resolve one concrete executable before using `.Source`: `Get-Command ... -CommandType Application | Select-Object -First 1`.
- Use `-LiteralPath` for real paths. Verify required paths before dependent operations and verify boundaries before recursive mutation.
- Do not put passwords, tokens, cookies, or private keys in command arguments. For SSH/Plink/WSL/Bash/SQL, send literal scripts through stdin and use key/agent or another secure credential mechanism.

## Native Command Template

```powershell
$exe = Get-Command 'tool' -CommandType Application -ErrorAction SilentlyContinue |
    Select-Object -First 1 -ExpandProperty Source
if (-not $exe) {
    throw 'Required executable tool was not found.'
}

$nativeArgs = @(
    '--input'
    'C:\Path With Spaces\input.json'
    '--empty'
    ''
)

& $exe @nativeArgs
$exitCode = $LASTEXITCODE
if ($exitCode -ne 0) {
    throw "$exe failed with exit code $exitCode"
}
```

Do not use `$args` as a custom variable name. Omitted arguments, `''`, and `$null` have different meanings.

## PowerShell-Specific Traps

- Group computed parameter values: `Select-Object -Index (100..120)`.
- Common parameters such as `-ErrorAction` apply to cmdlets and advanced functions, not .NET method calls.
- Delimit variables before a colon: `"${name}: value"`, or use the `-f` operator.
- `$powershell-safe-skills` is Codex chat syntax, not a command for a `PS>` prompt. In PowerShell, `$name` denotes a variable.
- Prefer UTF-8 without BOM for cross-platform source and data. Mojibake in the terminal does not prove file corruption.
- Treat file locks separately from syntax errors. Do not stop unrelated processes merely to read a locked file.

## Load Only The Relevant Reference

- `references/native-commands.md`: native arguments, discovery, globs, exit codes, JSON, and secrets.
- `references/cmdlets-filesystem.md`: cmdlet errors, statement output, literal paths, recursive mutation, and mapped drives.
- `references/cross-shell.md`: nested PowerShell, here-strings, SSH/Plink/WSL/Bash/SQL, cmd, and environment variables.
- `references/process-encoding.md`: process launch/capture, UTF-8/BOM, binary data, Chinese text, and file locks.
- `references/diagnostics.md`: symptom lookup and command simplification after a failure.
- `references/history-derived-failures.md`: maintenance/evaluation summary of the historical failure patterns that drove these rules. Do not load for routine command execution.
- `references/history-evidence.md`: detailed audit evidence and provenance. Do not load for routine command execution.
