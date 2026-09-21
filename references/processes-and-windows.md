# Processes and Windows diagnostics

## Choose the launch API

Use `& $exe @nativeArgs` for ordinary foreground work. Use the host tool's
background/session facility for long validation, retain its identifier, and
collect completion and status. A `Start-Job` belongs to its hosting PowerShell
process and cannot be assumed to survive a short-lived tool invocation.

Use `Start-Process` for detachment, elevation, window behavior, shell association,
or its process-object semantics. Its `-ArgumentList` joins values into a command
line; an array alone does not preserve exact boundaries. For background Windows
helpers use `-WindowStyle Hidden`, `-PassThru`, an explicit working directory,
and distinct output/error files. Use a visible window only for a requested
interactive application. Track PID and start time.

## Capture stdout and stderr without deadlock

On 7, `ProcessStartInfo.ArgumentList` preserves separate arguments for native
executables. Set a verified executable and absolute working directory. Never
read stdout to completion before starting to drain stderr; either pipe can
fill and block the child. This example captures bounded **text** output:

```powershell
$psi = [Diagnostics.ProcessStartInfo]::new()
$psi.FileName = $exe
$psi.WorkingDirectory = $workingDirectory
$psi.UseShellExecute = $false
$psi.CreateNoWindow = $true
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError = $true
foreach ($nativeArg in $nativeArgs) { $psi.ArgumentList.Add($nativeArg) }
# Set StandardOutputEncoding/StandardErrorEncoding if the child's contract needs it.
$process = [Diagnostics.Process]::Start($psi)
try {
    $stdoutTask = $process.StandardOutput.ReadToEndAsync()
    $stderrTask = $process.StandardError.ReadToEndAsync()
    if (-not $process.WaitForExit(30000)) {
        throw 'Owned process exceeded the 30-second deadline.'
    }
    $drained = [Threading.Tasks.Task]::WaitAll(
        [Threading.Tasks.Task[]]@($stdoutTask, $stderrTask), 5000
    )
    if (-not $drained) { throw 'A descendant may still hold an output pipe open.' }
    $result = [pscustomobject]@{
        ExitCode = $process.ExitCode
        Stdout = $stdoutTask.GetAwaiter().GetResult()
        Stderr = $stderrTask.GetAwaiter().GetResult()
    }
} finally {
    if (-not $process.HasExited) {
        $process.Kill($true)
        $null = $process.WaitForExit(5000)
    }
    $process.Dispose()
}
```

Interpret `$result.ExitCode` using the program's contract before accepting its
output. Do not print raw captured secrets. The timeouts are example budgets;
choose them for the task. For large/continuous output, drain concurrently to
files or bounded buffers instead of keeping everything in memory. This example
does not provide a durable service lifecycle or guarantee cleanup of descendants
that outlive an exited parent; use tracked host sessions or appropriate process
containment for that case. Do not retry an operation merely because it timed out.

## Locks, ports, and services

Any file can have an incompatible open handle. For read/hash/copy scans, catch
failures per file and retain a `ReadError` rather than aborting unrelated reads.
Copy to a snapshot only if sharing permits it and the data contract supports a
consistent copy. Do not stop unrelated processes to inspect a locked file.
A rebuild blocked by a running executable requires identifying the intended
stale build/test process before stopping it.

For a busy port, find its listener and process, then inspect executable path and
start time. Inspect command lines only if needed and redact sensitive arguments:

```powershell
$listeners = @(Get-NetTCPConnection -State Listen -ErrorAction Stop |
    Where-Object { $_.LocalPort -eq $port })
$listeners | Select-Object LocalAddress, LocalPort, OwningProcess
$ownerIds = @($listeners | Select-Object -ExpandProperty OwningProcess -Unique)
foreach ($ownerId in $ownerIds) {
    Get-CimInstance Win32_Process -Filter "ProcessId = $ownerId" -ErrorAction Stop |
        Select-Object ProcessId, Name, ExecutablePath, CreationDate
}
```

PIDs can be reused: re-check identity immediately before stopping an authorized
process. Prefer the application's shutdown API or `Stop-Service` for services.
Never kill all Python, Node, or PowerShell processes to release one resource.
After any restart, re-query the relevant service/process/port.

Use `Get-Service` and filtered `Win32_Service` queries for state, executable,
dependencies, and relevant startup settings. Use narrow `Get-WinEvent` filters
for observed failures. Diagnose ACL, elevation, and lock issues separately.

## Installations and application integration

Resolve products from installed package metadata, official installers, or
uninstall registry entries. Avoid `Win32_Product`: enumeration can trigger MSI
consistency checks and repairs. Relevant registry locations include:

- `HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall`
- `HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall`
- `HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall`

Use `Get-AppxPackage` for MSIX. Verify exact package identity and documented
installer arguments; do not execute uninstall strings through `Invoke-Expression`.
An application, its source repository, profile data, and shared runtime are
different resources. Remove only those within the requested uninstall scope.

An MCP may be only a client config entry launching a program on demand. Identify
client and scope, edit structurally, and distinguish remaining services or
installations before claiming removal. A cached manifest does not prove activity.

MSIX can redirect application data under a package's `LocalCache`. If an app
ignores an edit, determine its actual config path and package context, using the
final path through a file handle when necessary. Do not copy credentials to
several guessed locations. Prefer reload/refresh; restart only the relevant app
when needed, accounting for active work. Verify its loader/UI or resulting
behavior, not just file existence.

Source: [Start-Process](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.management/start-process).
