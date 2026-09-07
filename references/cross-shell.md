# Cross-Shell Boundaries

Use this reference when PowerShell calls another shell or interpreter.

## Reduce Parser Layers

Commands may pass through JSON/host escaping, PowerShell, a native argument parser, and then SSH, WSL, Bash, Python, Git, Docker, or SQL. Each layer can reinterpret quotes, backslashes, dollar signs, pipes, redirection, and Unicode.

PowerShell does not use `\"` to escape a double quote. Prefer single-quoted literals and argument arrays. When content is multiline or quote-heavy, stop escaping and use a `.ps1`, target-language file, or literal here-string.

## Nested PowerShell

An outer PowerShell expands variables in a double-quoted child `-Command` before the child sees them. Use an outer single-quoted snippet only for short code:

```powershell
pwsh.exe -NoLogo -NoProfile -Command '$p = "C:\Data Folder\input.txt"; Test-Path -LiteralPath $p'
```

Use `pwsh.exe -NoLogo -NoProfile -NonInteractive -File script.ps1` for anything substantial. Do not launch another PowerShell merely to run code that can execute in the current process.

## Here-Strings And Interpreter Stdin

Literal here-strings do not expand PowerShell variables:

```powershell
$text = @'
{
  "name": "$literal"
}
'@
```

The opening marker must end its line; the closing marker must be alone at the start of a line.

Bash heredocs are not PowerShell syntax. Replace `python - <<'PY'` with:

```powershell
@'
print("hello")
'@ | python -
```

## SSH, Plink, WSL, Bash, And SQL

Do not combine local interpolation, remote variables, SQL quoting, and credentials in one command string. Send a literal script through stdin:

```powershell
$remoteScript = @'
set -euo pipefail
cd /opt/app
psql "$DATABASE_URL" -X -v ON_ERROR_STOP=1 <<'SQL'
SELECT current_database(), current_user;
SQL
'@

$remoteHost = 'remote-host'
$remoteScript | ssh $remoteHost 'bash -s'
$exitCode = $LASTEXITCODE
if ($exitCode -ne 0) {
    throw "Remote script failed with exit code $exitCode"
}
```

The same stdin pattern applies to `plink` and `wsl -- bash -s`. Use SSH keys or an agent; never put passwords in `plink -pw` or secrets in command arguments and generated logs.

## cmd.exe And Batch Files

Use `cmd.exe /c` only for cmd built-ins, required `.cmd`/`.bat` behavior, or cmd-specific expansion/redirection. PowerShell 7 already supports `&&` and `||`.

Avoid `--%` unless a fixed literal Windows-native command cannot be represented with an argument array. It disables normal PowerShell parsing for the rest of the command.

## Environment And Invocation Syntax

Use `$env:NAME`; `%NAME%` is cmd syntax. A child process cannot modify its parent PowerShell environment.

`$powershell-safe-skills` belongs in Codex chat. At a `PS>` prompt, invoke an executable directly or use a non-hyphenated variable with the call operator:

```powershell
$skillInstaller = 'C:\Tools\skill-installer.exe'
& $skillInstaller 'install' $url
```
