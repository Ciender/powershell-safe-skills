# Runtime and controlled fallback

## Select and verify

Use host-provided environment facts first. If uncertain, inspect:

```powershell
$PSVersionTable
Get-Command pwsh -CommandType Application -All -ErrorAction SilentlyContinue
```

Check known host-provided runtimes and standard installation locations before
declaring 7 absent; do not recursively search the whole machine. Verify the
candidate by querying its executing `$PSVersionTable`. Use an absolute path
once selected. Check process architecture when COM or native modules require it.

A container, WSL session, or remote tool is not automatically the user's Windows
host. PowerShell on Linux cannot verify Windows registry, COM, services, or
drive paths. Without a Windows execution tool, prepare/review the artifact and
state that host execution is unverified.

Regular reusable scripts should begin with this contract:

```powershell
#requires -Version 7.0
[CmdletBinding()]
param()
if ($PSVersionTable.PSEdition -ne 'Core' -or $PSVersionTable.PSVersion.Major -ne 7) {
    throw 'Run this script with a verified PowerShell 7 executable.'
}
$ErrorActionPreference = 'Stop'
```

The two bundled diagnostic helpers deliberately use a 5.1-compatible bootstrap
and runtime guard, so the same checks remain available during explicit fallback.
This is not permission to lower every generated script's requirement.

## Fallback ladder

1. **Stay on 7 when possible.** A default host running 5.1 is not evidence that
   7 is missing. Select a verified installed 7 first. Prefer a 7-compatible API
   or executable for a legacy dependency when it meets the task faithfully.
2. **Adapt within 7.x.** Check the specific API/parameter, not just the major
   version. Earlier 7 releases may lack modern native argument passing or JSON
   options. Use file/stdin input, supported .NET APIs, or an available parser.
   Do not upgrade the machine merely to simplify one command.
3. **Isolate 5.1 only when necessary.** After verified absence of 7 or a concrete
   legacy dependency, use the installed Windows PowerShell 5.1 Desktop engine
   for the smallest compatible subtask. State the reason and scope. Existing
   task authorization suffices for this execution choice unless the user has
   prohibited it; installation or unrelated system changes need their own scope.
4. **Stop the dependent operation if no faithful fallback exists.** Prepare the
   7 script and report the exact missing prerequisite. Continue independent work.

Never retry a failed mutation under another engine until its actual outcome is
known. A parser error, permission denial, file lock, or nonzero native exit does
not establish a need to downgrade. Do not silently substitute PowerShell 6 or a
future major version. If 7 is present, a dependency-specific 5.1 step returns
control to 7 afterward; do not move the whole workflow to 5.1.

## Isolated 5.1 mechanics

- Launch a verified `powershell.exe` with `-NoLogo -NoProfile -NonInteractive -File`.
  Check `PSEdition = Desktop` and version `5.1`. Use script parameters and files
  for data. `Import-Module -UseWindowsPowerShell` also starts 5.1 and must be
  treated as fallback, not a transparent workaround.
- Write a separate compatibility script with `#requires -Version 5.1` and an
  explicit 5.1 guard; keep the normal 7 script's guard intact. Test on 5.1 itself.
- No `&&`, `||`, `??`, ternary operator, `utf8NoBOM`, `ConvertFrom-Json -AsHashtable`,
  or `.NET ProcessStartInfo.ArgumentList` in 5.1. Avoid assuming parameter parity;
  inspect `Get-Command ... -Syntax`. Prefer target file/stdin input over manual
  Windows command-line quoting. If exact boundaries cannot be preserved, stop.
- Non-ASCII 5.1 script source needs UTF-8 **with BOM** (or another explicitly
  supported encoding). Data encoding follows its consumer. For UTF-8 data without
  BOM, use `[IO.File]::WriteAllText` with `UTF8Encoding($false, $true)`.
- Exchange typed data via a supported structured format and verify the round
  trip. Do not transfer credentials in command lines or generated source files.
- The diagnostic helpers require `-AllowWindowsPowerShell51` on that invocation.
  Their `CompatibilityFallback` result makes the selected mode observable.

Do not change execution policy, profiles, PATH, or install a runtime to conceal
a prerequisite. Report which engine was actually used and which checks ran.
