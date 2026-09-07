# Cmdlets And Filesystem

Use this reference for PowerShell cmdlets, path handling, recursive mutation, and mapped drives.

## Cmdlet Splatting

Use a hashtable for cmdlet parameters:

```powershell
$params = @{
    LiteralPath = $source
    Destination = $destination
    Force       = $true
    ErrorAction = 'Stop'
}

Copy-Item @params
```

Use terminating errors when failure must stop execution:

```powershell
$ErrorActionPreference = 'Stop'

try {
    Copy-Item -LiteralPath $source -Destination $destination -ErrorAction Stop
}
catch {
    throw "Copy failed: $($_.Exception.Message)"
}
```

## Parameter Values That Are Expressions

PowerShell command arguments are parsed in argument mode. A range or arithmetic expression after a parameter name may be treated as a literal argument.

Avoid:

```powershell
Get-Content -LiteralPath $path | Select-Object -Index 100..120
```

Use parentheses or assign first:

```powershell
Get-Content -LiteralPath $path | Select-Object -Index (100..120)

$lineRange = 100..120
Get-Content -LiteralPath $path | Select-Object -Index $lineRange
```

The same habit helps computed values:

```powershell
Get-ChildItem -LiteralPath $root | Select-Object -First ($count + 1)
```

## Statement Output And Values

`foreach`, `if`, and `switch` are statements. Capture their output before piping or embedding it; do not write `foreach (...) { ... } | ...` or `Drafts = (if (...) {...})`.

```powershell
$rows = foreach ($file in $files) {
    [pscustomobject]@{ File = $file }
}
$rows | Format-Table -AutoSize

$draftCount = if (Test-Path -LiteralPath $draftRoot) {
    (Get-ChildItem -LiteralPath $draftRoot -Recurse -File).Count
}
else {
    0
}

[pscustomobject]@{ Drafts = $draftCount }
```

Use `ForEach-Object` when input is already a pipeline. Use `$()` only when an inline statement subexpression is genuinely clearer.

## Literal Paths

Use `-LiteralPath` for real paths:

```powershell
Get-Item -LiteralPath $path
Copy-Item -LiteralPath $source -Destination $destination
Remove-Item -LiteralPath $target
```

Use `-Path` only when wildcard expansion is intentional. Paths containing `[`, `]`, `*`, or `?` are common failure cases.

Build paths with `Join-Path` or `[System.IO.Path]::Combine()`:

```powershell
$path = Join-Path -Path $root -ChildPath 'subdir\file.txt'
```

Use `Resolve-Path -LiteralPath` for existing paths and `[System.IO.Path]::GetFullPath()` when a target may not exist yet.

## Recursive Mutation Boundary

Before recursive delete, move, or overwrite, resolve and verify that the target is inside the intended root:

```powershell
$root = (Resolve-Path -LiteralPath 'C:\ExpectedRoot').Path
$target = (Resolve-Path -LiteralPath $candidate).Path

$rootPrefix = $root.TrimEnd(
    [System.IO.Path]::DirectorySeparatorChar,
    [System.IO.Path]::AltDirectorySeparatorChar
) + [System.IO.Path]::DirectorySeparatorChar

if (-not $target.StartsWith(
    $rootPrefix,
    [System.StringComparison]::OrdinalIgnoreCase
)) {
    throw "Refusing to modify path outside expected root: $target"
}
```

Reject empty paths, filesystem roots, unresolved targets, unexpected targets, and the intended root itself unless explicitly allowed.

Do not enumerate paths in PowerShell and then pass them to `cmd.exe`, Bash, or another shell for deletion or moving.

## Mapped Drives

Mapped drives such as `X:\` are scoped to a user logon session. A path can work interactively and fail in automation, a service, an elevated process, a sandbox, or a scheduled task.

Check:

```powershell
whoami
Get-PSDrive -Name X -ErrorAction SilentlyContinue
Test-Path -LiteralPath 'X:\Expected\file.rdc'
```

If the mapping is missing, use a UNC path verified under the same account or create the mapping in that same process/session. If the UNC path cannot be discovered, ask the user instead of guessing.
