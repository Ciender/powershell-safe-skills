# Diagnose the observed boundary

Use the smallest relevant probe; do not run every check. Separate parser errors,
expected native status, missing prerequisites, locks, permission failures, and
target-program failures before changing syntax or considering runtime fallback.

| Symptom | Check or correction | Details |
| --- | --- | --- |
| `foreach (...) { ... } | ...` / empty pipeline element | Assign statement output, then pipe | [Execution](execution.md) |
| `(if (...) {...})` is treated as a command | Compute first or use `$(if (...) {...})` | [Execution](execution.md) |
| `-Index 100..120` conversion failure | Group the range with parentheses | [Execution](execution.md) |
| Variable before `:` rejected | Use `${name}:` or the `-f` operator | [Execution](execution.md) |
| `.NETMethod()` rejects `-ErrorAction` | Use `try/catch`; common parameters are not method arguments | [Execution](execution.md) |
| `rg` exits 1 without output | Expected no-match contract; inspect native-error preference | [Execution](execution.md) |
| Git says not a repository | Verify working directory with `git -C ... rev-parse` | [Execution](execution.md) |
| Native wildcard path gives error 123 | Tool glob option or enumerate actual paths | [Execution](execution.md) |
| Missing command or `.Source` becomes several paths | Check discovery, pick one verified application | [Execution](execution.md) |
| Empty/quoted native arguments change | Engine mode, batch shim, file/stdin input | [Execution](execution.md) |
| Inner `$p` / `$env:NAME` disappears | Outer shell expanded it; prefer a script file | [Cross-shell](cross-shell.md) |
| `python - <<'PY'` or Bash-style quote escaping fails | PowerShell here-string or target-language file | [Cross-shell](cross-shell.md) |
| SSH/SQL command loses variables or quoting | Literal stdin script; verify remote authentication/config | [Cross-shell](cross-shell.md) |
| `$powershell-safe-skills` fails at `PS>` | Skill invocation belongs in chat | [Cross-shell](cross-shell.md) |
| Path is missing, bracketed, or wrong provider | `Test-Path` / `Get-Item -LiteralPath` and correct type | [Files](files-and-config.md) |
| Mapped drive works only interactively | User/session mapping; verify UNC path | [Files](files-and-config.md) |
| Terminal text is garbled | Check bytes, data and stream encodings separately | [Files](files-and-config.md) |
| JSON arrays/strings change after an edit | Parser/serializer fidelity and round-trip verification | [Files](files-and-config.md) |
| File read/hash/copy or rebuild is blocked | Incompatible handle; identify owner, preserve per-file errors | [Processes](processes-and-windows.md) |
| Captured process hangs despite little stdout | Drain stderr concurrently; check inherited pipe handles | [Processes](processes-and-windows.md) |
| Port busy or permission denied | Resource owner, process identity, ACL/elevation vs lock | [Processes](processes-and-windows.md) |
| App ignores an existing config file | Actual app path, MSIX redirection, load/reload behavior | [Processes](processes-and-windows.md) |
| Cmdlet/API unavailable | Verify runtime, minor version, modules, parameter syntax | [Runtime](runtime.md) |

For invocation corruption, remove unnecessary `cmd /c`, nested `-Command`,
`Invoke-Expression`, and manual quoting. Move substantial source to a file,
resolve one executable, inspect redacted arguments, and capture its exit code.
Do not repeatedly retry an absent tool under different quoting.

A PowerShell 7 parser pass cannot prove 5.1 compatibility or Windows API behavior
on a Linux host. Linux ABI/glibc/musl deployment failures and SQL schema errors
are target-domain issues; do not turn them into universal PowerShell rules.
