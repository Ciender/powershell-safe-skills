# Cross-shell boundaries

Prefer executing directly in the verified host. Each wrapper adds a parser:
tool serialization, PowerShell, a native argument parser, SSH/WSL, then Bash or
SQL. JSON escaping is not shell escaping. An outer double-quoted PowerShell
string expands `$variables` and `$()` before an inner `-Command` receives them.
A Bash double-quoted wrapper can also expand dollar signs and backticks first.

For substantial code, create a `.ps1` or target-language file through the host's
editing tool, then invoke it with parameters. Use `-File` for nested PowerShell.
Do not run dynamic data through `Invoke-Expression` or a constructed `cmd /c`.
Use `cmd.exe /c` only for required cmd/batch semantics. `--%` is for fixed literal
Windows-native commands, not a general quoting solution for dynamic data.

## Literal scripts and stdin

PowerShell here-strings preserve multiline text; a single-quoted here-string
does not interpolate it. The opening marker ends its line and the closing
marker starts at column one. Bash heredocs do not work in PowerShell:

```powershell
@'
print("hello")
'@ | python -
$nativeExitCode = $LASTEXITCODE
if ($nativeExitCode -ne 0) { throw "Python failed: $nativeExitCode" }
```

For SSH/Plink/WSL/Bash/SQL, transport a literal script instead of mixing local
interpolation, remote variables, and SQL quoting:

```powershell
$remoteScript = @'
set -euo pipefail
cd /opt/app
psql -X -v ON_ERROR_STOP=1 <<'SQL'
SELECT current_database(), current_user;
SQL
'@
$remoteHost = 'remote-host'
& {
    $PSNativeCommandUseErrorActionPreference = $false
    $OutputEncoding = [Text.UTF8Encoding]::new($false)
    $remoteScript.Replace("`r`n", "`n") | ssh $remoteHost 'bash -s'
    $nativeExitCode = $LASTEXITCODE
    if ($nativeExitCode -ne 0) { throw "Remote script failed: $nativeExitCode" }
}
```

The example relies on the remote account's libpq service/environment and secure
authentication configuration. Do not interpolate credentials into source or
pass a credential-bearing connection URL as a process argument. Remote variables
in a literal script are expanded by the remote shell, not local PowerShell.

The same stdin transport works with `plink` or `wsl -- bash -s`. Verify the target
supports stdin scripts. Windows text pipes can append CRLF; scripts with strict
LF requirements or embedded binary data should be written as UTF-8/LF files and
transferred or streamed using byte APIs. If the script consumes stdin itself,
use a transferred script file so source and input do not compete for the stream.

Use SSH keys/agent or the tool's secure credential mechanism, never `plink -pw`.
Use `$env:NAME` locally; `%NAME%` is cmd syntax. Child processes cannot modify
their parent's environment. Scope environment changes to the child or restore
them in `finally`.

`$powershell-safe-skills` is an invocation in Codex chat, not a `PS>` command.
At a PowerShell prompt, `$` starts a variable expression; use an executable name
or a non-hyphenated variable with the call operator.
