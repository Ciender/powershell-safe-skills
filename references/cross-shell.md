# Cross-Shell Boundaries

Use this reference when PowerShell calls another shell or interpreter: `pwsh -Command`, SSH, WSL, Bash, Python stdin scripts, cmd.exe, batch files, or tools that interpret `$`, quotes, pipes, and redirection.

## Parser Layers

A generated command can pass through several parsers:

```text
Codex / tool call
  -> JSON or host escaping
  -> PowerShell
  -> native program argument parser
  -> ssh / wsl / python / git / docker
  -> remote shell or target program
```

Each layer can reinterpret quotes, backslashes, dollar signs, backticks, pipes, redirection, parentheses, JSON, regular expressions, and Unicode text.

When a command crosses several parsers, stop adding quotes and write a `.ps1` file or pipe a here-string to the target interpreter.

## Nested PowerShell

If an outer PowerShell process invokes another PowerShell process with `-Command`, the outer process expands `$variables` before the child process sees the script.

Short snippet:

```powershell
pwsh.exe -NoLogo -NoProfile -Command '$p = "C:\Data Folder\input.txt"; Test-Path -LiteralPath $p'
```

Prefer `-File` for anything substantial:

```text
pwsh.exe -NoLogo -NoProfile -NonInteractive -File script.ps1
```

Do not start another PowerShell process merely to run a small snippet that can run in the current process.

## Here-Strings

Literal multiline text:

```powershell
$text = @'
{
  "name": "$literal"
}
'@
```

Expanded multiline text:

```powershell
$text = @"
Name: $name
"@
```

The opening `@'` or `@"` must be the last tokens on its line. The closing terminator must appear alone at the start of a line.

## SSH Remote Bash

Wrong:

```powershell
ssh root@example.com "backup=/opt/app/app.backup.$(date +%Y%m%d%H%M%S)"
```

Here `$()` is expanded by local PowerShell before remote Bash sees it.

Simple remote Bash:

```powershell
ssh root@example.com 'backup=/opt/app/app.backup.$(date +%Y%m%d%H%M%S); echo "$backup"'
```

Complex remote Bash:

```powershell
$script = @'
set -e
backup=/opt/app/app.backup.$(date +%Y%m%d%H%M%S)
systemctl stop app.service
cp -a /opt/app/app "$backup"
install -o root -g root -m 755 /tmp/app.new /opt/app/app
systemctl start app.service
'@

$script | ssh root@example.com 'bash -s'
```

## WSL And Bash

Do not write Bash heredocs directly in PowerShell:

```powershell
python - <<'PY'
print("hello")
PY
```

Use a PowerShell here-string instead:

```powershell
@'
print("hello")
'@ | python -
```

Complex WSL command:

```powershell
$script = @'
set -e
cd /mnt/c/project
cargo build --release
'@

$script | wsl -d Ubuntu -- bash -s
```

## cmd.exe, Batch, And Stop-Parsing

Use `cmd.exe /c` only when cmd-specific behavior is necessary:

- cmd built-ins
- required `.cmd` or `.bat` semantics
- cmd-specific expansion or redirection

PowerShell 7 supports `command1 && command2` and `command1 || command2`.

Avoid `--%` by default. It is Windows-specific and disables normal PowerShell parsing for the rest of the command. Use it only for a fixed literal native command that cannot be expressed reliably with an argument array.

## Environment Variables

PowerShell syntax:

```powershell
$env:NAME
$env:NAME = 'value'
```

Do not use `%NAME%` inside PowerShell. Changes made by a child process do not propagate back to its parent PowerShell process.
