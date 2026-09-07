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
Get-Module -ListAvailable 'ModuleName'
Get-Command 'CommandName' -Syntax
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
| `foreach (...) { ... } | ...` reports an empty pipe element | Statement syntax was piped directly | Assign loop output first or use `ForEach-Object` |
| `Drafts=(if (...) {...})` says `if` is not recognized | A statement was placed where an expression value was expected | Compute the value first or use `$(if (...) {...})` |
| `-Index 100..120` fails or behaves literally | Parameter expression was not grouped | Use `-Index (100..120)` or assign the range first |
| A native regex turns `link`, `@import`, or `--page` into PowerShell syntax | `\"` was used as if PowerShell were Bash/C | Put the regex in a single-quoted string, argument array, or pattern file |
| `rg root\*.md` returns Windows error 123 | The native program received a literal wildcard path | Use `rg -g '*.md' root` or enumerate files first |
| `rg` exits 1 with no output | No matches were found | Treat only exit codes above 1 as errors |
| Git reports `not a git repository` | The working directory was assumed rather than verified | Run `git -C $root rev-parse --is-inside-work-tree` before other Git commands |
| `$skill-installer` reports an unexpected `-installer` token | `$` started a variable expression, not a command | Invoke `skill-installer`, or store its path in `$skillInstaller` and use `&` |
| Remote `psql` connects as the wrong user or rejects the connection string | PowerShell damaged Bash variables or nested SQL quotes | Pipe a literal Bash script to `ssh ... 'bash -s'` |
| `X:\...` works interactively but not in automation | Mapped drive is not visible to this user/session | `whoami`, `Get-PSDrive`, use UNC or same-user session |
| A known executable or cmdlet is missing | PATH, module path, or active shell differs from expectation | `Get-Command`, `$env:PSModulePath`, `Get-Module -ListAvailable` |
| `$tool.Source` becomes several paths joined together | `Get-Command` returned multiple application candidates | Pipe to `Select-Object -First 1` or verify the exact executable path |
| A cmdlet parameter is rejected | PowerShell 5.1/7 parameter-set difference | `Get-Command <cmdlet> -Syntax` |
| `-ErrorAction` is unexpected after `[Type]::Method()` | Common parameters apply to cmdlets and advanced functions, not .NET method calls | Wrap the method call in `try/catch` or check its return value |
| `"$start-$end: ..."` reports an invalid variable reference | The colon is parsed as part of the variable-qualified syntax | Use `"$start-${end}: ..."` or the `-f` format operator |
| A `.ps1` file shows parser errors around mojibake Chinese text | The source file was decoded or rewritten with the wrong encoding | Inspect bytes and rewrite as UTF-8 before changing syntax |
| A read fails with `Cannot find path` | The command guessed a stale or wrong path | `Test-Path -LiteralPath` before the dependent read |
| `Get-FileHash` or `Copy-Item` says the file is in use | Another process opened the file without sharing | Handle per file, snapshot if valid, or identify the owner |
| Native args with spaces or empty strings break | Arguments were flattened into one string | Use `& $exe @nativeArgs` or `ProcessStartInfo.ArgumentList` |
| SSH/WSL command loses `$()` or `$VAR` | Local PowerShell expanded it before the remote shell | Single quotes or here-string piped to `bash -s` |
| Text looks corrupted in terminal | Console decoding differs from file encoding | Inspect bytes or read with explicit encoding |
| Build cannot overwrite `target\debug\*.exe` | Old process is still running | `Get-Process`, then stop the authorized stale process |

## Simplification Sequence

When invocation corruption occurs:

1. Classify the result: PowerShell parser error, expected native no-match code, missing dependency/path, lock, permission, or target-program failure.
2. Remove `cmd.exe /c`.
3. Remove nested `pwsh -Command` or `powershell -Command`.
4. Remove `Invoke-Expression`.
5. Remove manually nested quotes and every Bash-style `\"` escape.
6. Replace native wildcard paths with the tool's glob option or an enumerated file list.
7. Put multiline code in a minimal `.ps1` or target-language source file.
8. Invoke the native executable directly with `& $exe @nativeArgs`.
9. Print every argument and length.
10. Capture `$LASTEXITCODE` immediately and apply the target tool's documented exit-code contract.

## Scope Boundary

Linux binary ABI, glibc mismatch, and musl static builds are deployment compatibility issues. They may appear during PowerShell-driven deployment, but they are not PowerShell/Codex execution-layer problems. Treat build-target selection separately from the PowerShell command shape.
