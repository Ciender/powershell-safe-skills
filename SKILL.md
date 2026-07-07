---
name: powershell-safe-skills
description: Use when writing or running PowerShell on Windows, especially native programs, quoted paths, escaping, pwsh vs powershell.exe, Start-Process, ProcessStartInfo, file operations, SSH/WSL/Bash calls, JSON/regex quoting, encoding/BOM/Chinese text, running exe locks, mapped drives, or shell troubleshooting.
---

# PowerShell Safe Skills

Use this skill as a compact execution checklist for PowerShell-driven automation. Preserve argument boundaries; do not squeeze structured commands into nested quoted strings.

## Decision Order

Choose the first safe option that fits:

1. PowerShell cmdlet.
2. Native command with `& $exe @nativeArgs`.
3. Temporary `.ps1` with `pwsh.exe -NoLogo -NoProfile -NonInteractive -File script.ps1`.
4. `ProcessStartInfo.ArgumentList`.
5. `Start-Process` only for elevation, new/hidden windows, detached launch, or shell behavior.
6. `cmd.exe /c` only when cmd semantics are required.
7. `Invoke-Expression` only as a last resort for trusted PowerShell source.

## Verify The Shell

Prefer PowerShell 7 through `pwsh.exe` unless Windows PowerShell 5.1 is explicitly required.

```powershell
$PSVersionTable.PSVersion
$PSNativeCommandArgumentPassing
Get-Command pwsh -ErrorAction SilentlyContinue
Get-Command powershell -ErrorAction SilentlyContinue
```

Do not assume `powershell.exe` is PowerShell 7. On Windows, `pwsh.exe` is PowerShell 7 and `powershell.exe` is Windows PowerShell 5.1.

## Native Command Template

Use an argument array. Do not build one command string.

```powershell
$exe = 'C:\Path With Spaces\tool.exe'
$nativeArgs = @(
    '--input'
    'C:\Data Folder\input.json'
    '--empty'
    ''
)

& $exe @nativeArgs
$exitCode = $LASTEXITCODE
if ($exitCode -ne 0) {
    throw "$exe failed with exit code $exitCode"
}
```

Required habits:

- Treat every native argument as one array item.
- Invoke executable paths stored in variables with `&`.
- Capture `$LASTEXITCODE` immediately.
- Do not use `$args` as your own array name; it is a PowerShell automatic variable.
- Do not add `cmd.exe /c` merely to launch an executable.
- Do not use Bash-style `\"` escaping in PowerShell.
- Do not silently remove empty arguments; omitted argument, `''`, and `$null` are different.

## Cmdlets And Paths

Use splatting for cmdlets and `-LiteralPath` for real paths unless wildcard expansion is intentional.

```powershell
$params = @{
    LiteralPath = 'C:\Data[1]\input.txt'
    Destination = 'C:\Output'
    Force       = $true
    ErrorAction = 'Stop'
}

Copy-Item @params
```

Required habits:

- Use `$ErrorActionPreference = 'Stop'` or `-ErrorAction Stop` for cmdlet failures.
- Do not use `$LASTEXITCODE` to test a normal cmdlet.
- Wrap computed parameter values: use `Select-Object -Index (100..120)`, not `-Index 100..120`.
- Do not pipe directly from `foreach (...) { ... } | ...`; assign the output first or use `ForEach-Object`.
- Before recursive delete, move, or overwrite, resolve absolute root and target paths and verify the target is inside the intended root.
- Mapped drives are per user/session. If automation cannot see `X:\...`, check `whoami` and `Get-PSDrive`, then use a UNC path or the same-user session.

## When To Load References

- `references/native-commands.md`: native tools such as Git, SSH, Python, Cargo, Docker, argument arrays, exit codes, JSON payloads.
- `references/cmdlets-filesystem.md`: cmdlet splatting, parameter expressions, `foreach` pipelines, `-LiteralPath`, recursive mutation, mapped drives.
- `references/cross-shell.md`: `pwsh -Command`, SSH, WSL, Bash, here-strings, cmd.exe, batch files, stop-parsing, environment variables.
- `references/process-encoding.md`: `Start-Process`, `ProcessStartInfo`, stdout/stderr capture, UTF-8/BOM/Chinese text, binary files, Windows exe locks.
- `references/diagnostics.md`: symptom table and step-by-step simplification when invocation corruption occurs.

## Immediate Red Flags

Use a `.ps1` file or a PowerShell here-string when a command contains multiline code, nested quotes, JSON, XML, regex, pipes, redirection, SSH remote scripts, WSL/Bash scripts, `$()`, `$VAR`, `%VAR%`, or non-ASCII paths/output.

PowerShell parses before SSH, WSL, Bash, Python, Git, or Docker receive arguments. Do not write Bash heredocs directly in PowerShell:

```powershell
# Wrong in PowerShell
python - <<'PY'
```

For cross-platform source, Markdown, YAML, and JSON, prefer UTF-8 without BOM. Terminal mojibake does not prove file corruption; inspect bytes or read with explicit encoding.

Windows cannot overwrite a running `.exe`. If a build fails with access denied on `target\debug\*.exe`, find and stop the old process before rebuilding.
