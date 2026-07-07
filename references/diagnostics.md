# Diagnostics

Use this reference when a PowerShell invocation fails with quoting, escaping, argument loss, encoding, path, or process-lock symptoms.

## First Checks

```powershell
$PSVersionTable
$PSNativeCommandArgumentPassing
Get-Command pwsh -ErrorAction SilentlyContinue
Get-Command powershell -ErrorAction SilentlyContinue
Get-Command $exe -ErrorAction SilentlyContinue
```

If command discovery behaves strangely:

```powershell
$env:PSModulePath -split [IO.Path]::PathSeparator
Get-Module -ListAvailable <ModuleName>
Get-Command <CommandName> -Syntax
```

PowerShell 5.1 and PowerShell 7 can expose the same command with different parameters. For example, `Format-Hex -Count` is available in PowerShell 7 but not in Windows PowerShell 5.1; use pipeline limiting in 5.1:

```powershell
Format-Hex -LiteralPath 'C:\Data\buffer.bin' | Select-Object -First 2
```

## Symptom Table

| Symptom | Likely cause | First check |
| --- | --- | --- |
| `$p` or `$env:NAME` disappears in an inner `-Command` | Outer PowerShell expanded the variable first | Use outer single quotes or a `.ps1` file |
| `python - <<'PY'` fails with parser errors | Bash heredoc syntax was used in PowerShell | Use a temporary script or PowerShell here-string |
| `-Index 100..120` fails or behaves literally | Parameter expression was not grouped | Use `-Index (100..120)` or assign the range first |
| `foreach (...) { ... } | ...` reports an empty pipe element | Statement syntax was piped directly | Assign loop output first or use `ForEach-Object` |
| `X:\...` works interactively but not in automation | Mapped drive is not visible to this user/session | `whoami`, `Get-PSDrive`, use UNC or same-user session |
| A known cmdlet is missing | Module path or active shell differs from expectation | `$PSVersionTable`, `$env:PSModulePath`, `Get-Module -ListAvailable` |
| A cmdlet parameter is rejected | PowerShell 5.1/7 parameter-set difference | `Get-Command <cmdlet> -Syntax` |
| Native args with spaces or empty strings break | Arguments were flattened into one string | Use `& $exe @nativeArgs` or `ProcessStartInfo.ArgumentList` |
| SSH/WSL command loses `$()` or `$VAR` | Local PowerShell expanded it before remote shell | Single quotes or here-string piped to `bash -s` |
| Text looks corrupted in terminal | Console decoding differs from file encoding | Inspect bytes or read with explicit encoding |
| Build cannot overwrite `target\debug\*.exe` | Old process is still running | `Get-Process`, then stop stale process |

## Simplification Sequence

When invocation corruption occurs:

1. Remove `cmd.exe /c`.
2. Remove `-Command`.
3. Remove `Invoke-Expression`.
4. Remove manually nested quotes.
5. Put code in a minimal `.ps1` file.
6. Invoke the native executable directly with `& $exe @nativeArgs`.
7. Print every argument and length.
8. Capture `$LASTEXITCODE` immediately.

## Scope Boundary

Linux binary ABI, glibc mismatch, and musl static builds are deployment compatibility issues. They may appear during PowerShell-driven deployment, but they are not PowerShell/Codex execution-layer problems. Treat build-target selection separately from the PowerShell command shape.
