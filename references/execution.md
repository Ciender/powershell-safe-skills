# PowerShell and native execution

## Keep syntax and data separate

Use hashtable splatting for cmdlets and arrays for native arguments. Resolve
one concrete application path, not an array of `.Source` values:

```powershell
$exe = Get-Command 'git' -CommandType Application -ErrorAction SilentlyContinue |
    Select-Object -First 1 -ExpandProperty Source
if (-not $exe) { throw 'Required executable git was not found.' }
$nativeArgs = @('-C', $repoRoot, 'rev-parse', '--is-inside-work-tree')
& $exe @nativeArgs
$nativeExitCode = $LASTEXITCODE
if ($nativeExitCode -ne 0) { throw 'The selected directory is not a Git worktree.' }
```

Use that Git preflight before dependent Git operations in an uncertain directory.
Stop after a failed prerequisite instead of generating repeated secondary errors.
For missing cmdlets inspect `Get-Command ... -Syntax`, module versions, and
`$env:PSModulePath`. Never treat an alias or script shim as a verified executable.

An argument array prevents PowerShell re-evaluation of its values, but does not
neutralize the target's options. Use the target's end-of-options marker where
supported. Omitted arguments, `''`, and `$null` have different contracts.

PowerShell 7.3+ improves empty strings and embedded quotes. On Windows, the
`Windows` native argument mode still falls back to legacy handling for batch
files and selected executables. Prefer the real executable over `.cmd` shims;
use file/stdin input for complex JSON or text. Test exact delivery when it
matters. Do not change `$PSNativeCommandArgumentPassing` globally for one tool.
For a separate 7 process requiring exact boundaries, see
[processes-and-windows.md](processes-and-windows.md).

Do not rely on native wildcard expansion. Use `rg -g '*.md' $root`, or enumerate
full paths with `Get-ChildItem -LiteralPath` for tools without a glob option.
For argument debugging, inspect each value and length **only after redaction**.
Construct JSON through a serializer, not hand-escaped strings.

## Exit status and error policy

Cmdlet failures need `-ErrorAction Stop` to become catchable where appropriate.
Native exit codes are separate; stderr text alone does not establish failure.
Common contracts: `rg` 1 = no match; `git diff --exit-code` 1 = differences;
`robocopy` 0 through 7 = nonfatal outcomes (which may still deserve reporting).

When interpreting a native contract yourself, contain preference changes in a
child scope so an enabled native-error preference does not throw prematurely:

```powershell
& {
    $PSNativeCommandUseErrorActionPreference = $false
    & $rgExe '--files' $taskRoot
    $nativeExitCode = $LASTEXITCODE
    if ($nativeExitCode -notin @(0, 1)) {
        throw "File enumeration failed: $nativeExitCode"
    }
}
```

`$LASTEXITCODE` does not describe cmdlet success. Do not attach `-ErrorAction`
to a .NET method or native tool. Use `try/finally` for handles and location
restoration; `return` in `try` still runs `finally`. Avoid session-wide
`Set-StrictMode` or preference changes as ad hoc repairs.

## Statements, objects, and interpolation

```powershell
$rows = @(foreach ($file in $files) {
    [pscustomobject]@{ Name = $file.Name; Path = $file.FullName }
})
$draftCount = if (Test-Path -LiteralPath $draftRoot) {
    @(Get-ChildItem -LiteralPath $draftRoot -File -ErrorAction Stop).Count
} else { 0 }
$summary = [pscustomobject]@{ Drafts = $draftCount; Files = $rows }
```

Use `ForEach-Object` for an existing pipeline. An inline statement can use `$()`
when clearer; `(if (...) {...})` is not an expression. Normalize variable-sized
results with `@(...)`; retain objects until presentation. `Format-Table` produces
formatting records, not data suitable for JSON, CSV, or comparisons.

Group computed parameter values: `Select-Object -Index (100..120)`. Delimit a
variable before `:` with `${name}`; use `$($item.Name)` for property interpolation.
Chinese text and valid subexpressions are not parser defects by themselves.
Avoid automatic/read-only names such as `$PID`, `$HOME`, `$Host`, `$PSHOME`,
`$Error`, `$Matches`, and `$args` for task variables; names are case-insensitive.

References: [parsing](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_parsing),
[preferences](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_preference_variables).
