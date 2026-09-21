#requires -Version 7.0
[CmdletBinding()]
param()

if ($PSVersionTable.PSEdition -ne 'Core' -or $PSVersionTable.PSVersion.Major -ne 7 -or -not $IsWindows) {
    throw 'Run these checks on Windows with PowerShell 7.'
}
Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'
$skillRoot = Split-Path -Parent $PSScriptRoot
$engine = (Get-Process -Id $PID -ErrorAction Stop).Path
$checks = [Collections.Generic.List[object]]::new()
$scratch = Join-Path ([IO.Path]::GetTempPath()) ('ps-safe-check-' + [guid]::NewGuid().ToString('N'))
$null = New-Item -ItemType Directory -Path $scratch -ErrorAction Stop

function Assert-Check {
    param([string]$Name, [bool]$Condition)
    if (-not $Condition) { throw "Check failed: $Name" }
    $checks.Add([pscustomobject]@{ Name = $Name; Status = 'Pass' })
}

function Invoke-Probe {
    param([string]$Executable, [string[]]$Arguments)
    $psi = [Diagnostics.ProcessStartInfo]::new()
    $psi.FileName = $Executable
    $psi.WorkingDirectory = $scratch
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.StandardOutputEncoding = [Text.UTF8Encoding]::new($false)
    $psi.StandardErrorEncoding = [Text.UTF8Encoding]::new($false)
    foreach ($argument in $Arguments) { $psi.ArgumentList.Add($argument) }
    $child = [Diagnostics.Process]::Start($psi)
    try {
        $stdout = $child.StandardOutput.ReadToEndAsync()
        $stderr = $child.StandardError.ReadToEndAsync()
        if (-not $child.WaitForExit(20000)) { throw 'Test child exceeded deadline.' }
        if (-not [Threading.Tasks.Task]::WaitAll([Threading.Tasks.Task[]]@($stdout, $stderr), 5000)) {
            throw 'Test child retained output handles.'
        }
        [pscustomobject]@{
            ExitCode = $child.ExitCode
            Out = $stdout.GetAwaiter().GetResult()
            Err = $stderr.GetAwaiter().GetResult()
        }
    } finally {
        if (-not $child.HasExited) { $child.Kill($true); $null = $child.WaitForExit(5000) }
        $child.Dispose()
    }
}

function Invoke-Helper {
    param([string]$Executable, [string]$Helper, [hashtable]$Parameters)
    # Transfer parameters as data and standardize redirected JSON encoding on 5.1.
    $payload = ConvertTo-Json -InputObject @{ Helper = $Helper; Parameters = $Parameters } -Depth 5 -Compress
    $payload64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($payload))
    $source = @'
[Console]::OutputEncoding = [Text.UTF8Encoding]::new($false)
$payload = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('__PAYLOAD__')) | ConvertFrom-Json
$helperParams = @{}
foreach ($property in $payload.Parameters.PSObject.Properties) { $helperParams[$property.Name] = $property.Value }
& $payload.Helper @helperParams
'@
    $source = $source.Replace('__PAYLOAD__', $payload64)
    $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($source))
    Invoke-Probe $Executable @('-NoLogo', '-NoProfile', '-NonInteractive', '-EncodedCommand', $encoded)
}

try {
    $markdown = @(Get-ChildItem -LiteralPath $skillRoot -Recurse -File -Filter '*.md')
    $blockCount = 0
    $linkCount = 0
    foreach ($file in $markdown) {
        $content = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8
        foreach ($match in [regex]::Matches($content, '(?ms)^```powershell\r?\n(.*?)^```\s*$')) {
            $tokens = $null
            $errors = $null
            $null = [Management.Automation.Language.Parser]::ParseInput($match.Groups[1].Value, [ref]$tokens, [ref]$errors)
            if ($errors.Count -ne 0) { throw "Invalid example in $($file.Name): $($errors[0].Message)" }
            $blockCount++
        }
        foreach ($match in [regex]::Matches($content, '\[[^\]]+\]\(([^)]+)\)')) {
            $target = $match.Groups[1].Value
            if ($target -match '^[a-z]+://' -or $target.StartsWith('#')) { continue }
            $resolved = Join-Path $file.DirectoryName ($target.Split('#')[0])
            if (-not (Test-Path -LiteralPath $resolved)) { throw "Missing link: $resolved" }
            $linkCount++
        }
    }
    Assert-Check "PowerShell examples parse ($blockCount)" ($blockCount -gt 0)
    Assert-Check "Local Markdown links resolve ($linkCount)" ($linkCount -gt 0)

    $contextHelper = Join-Path $skillRoot 'scripts/Get-WindowsContext.ps1'
    $parserHelper = Join-Path $skillRoot 'scripts/Test-PowerShellScript.ps1'
    $unicodeLeaf = ([string][char]0x4E2D) + ([string][char]0x6587) + ' [one] space.ps1'
    $validPath = Join-Path $scratch $unicodeLeaf
    $invalidPath = Join-Path $scratch 'invalid.ps1'
    $modernPath = Join-Path $scratch 'modern.ps1'
    $textPath = Join-Path $scratch 'not-script.txt'
    $utf8Bom = [Text.UTF8Encoding]::new($true)
    [IO.File]::WriteAllText($validPath, 'throw "Input scripts must never execute during parsing."', $utf8Bom)
    [IO.File]::WriteAllText($invalidPath, 'foreach ($x in 1) { $x } | Out-Null', $utf8Bom)
    [IO.File]::WriteAllText($modernPath, '$value = $null ?? "fallback"', $utf8Bom)
    [IO.File]::WriteAllText($textPath, 'plain text', $utf8Bom)

    $response = Invoke-Helper $engine $contextHelper @{ CommandName = 'missing-skill-test-command-9714'; AsJson = $true }
    $data = $response.Out | ConvertFrom-Json
    Assert-Check '7 context, singleton/missing discovery, no fallback' (
        $response.ExitCode -eq 0 -and $data.Windows -and -not $data.CompatibilityFallback -and
        $data.Commands.Count -eq 1 -and -not $data.Commands[0].Found -and $data.Commands[0].Paths.Count -eq 0
    )
    foreach ($scriptFile in @($contextHelper, $parserHelper, $PSCommandPath, $validPath, $modernPath)) {
        $response = Invoke-Helper $engine $parserHelper @{ LiteralPath = $scriptFile; AsJson = $true }
        $data = $response.Out | ConvertFrom-Json
        Assert-Check "7 parses without executing: $([IO.Path]::GetFileName($scriptFile))" (
            $response.ExitCode -eq 0 -and $data.Valid -and $data.Files.Count -eq 1 -and -not $data.CompatibilityFallback
        )
    }
    $response = Invoke-Helper $engine $parserHelper @{ LiteralPath = $invalidPath; AsJson = $true }
    $data = $response.Out | ConvertFrom-Json
    Assert-Check 'Invalid syntax has nonzero status and line/column' (
        $response.ExitCode -eq 1 -and -not $data.Valid -and
        $data.Files[0].Errors[0].Line -gt 0 -and $data.Files[0].Errors[0].Column -gt 0
    )
    foreach ($badInput in @((Join-Path $scratch 'absent.ps1'), $scratch, $textPath)) {
        $response = Invoke-Helper $engine $parserHelper @{ LiteralPath = $badInput; AsJson = $true }
        $data = $response.Out | ConvertFrom-Json
        Assert-Check "Input error: $([IO.Path]::GetFileName($badInput))" (
            $response.ExitCode -eq 1 -and -not $data.Valid -and $data.Files[0].Errors[0].ErrorId -eq 'InputFileError'
        )
    }

    $legacyEngine = Join-Path $env:SystemRoot 'System32/WindowsPowerShell/v1.0/powershell.exe'
    if (Test-Path -LiteralPath $legacyEngine) {
        foreach ($helper in @($contextHelper, $parserHelper)) {
            $parameters = @{ AsJson = $true }
            if ($helper -eq $parserHelper) { $parameters.LiteralPath = $validPath }
            $response = Invoke-Helper $legacyEngine $helper $parameters
            Assert-Check "5.1 refuses default: $([IO.Path]::GetFileName($helper))" (
                $response.ExitCode -ne 0 -and $response.Err.Contains('PowerShell 7 is required')
            )
            $parameters.AllowWindowsPowerShell51 = $true
            $response = Invoke-Helper $legacyEngine $helper $parameters
            $data = $response.Out | ConvertFrom-Json
            Assert-Check "5.1 explicit fallback: $([IO.Path]::GetFileName($helper))" (
                $response.ExitCode -eq 0 -and $data.CompatibilityFallback -and $data.Edition -eq 'Desktop'
            )
        }
        $response = Invoke-Helper $legacyEngine $parserHelper @{ LiteralPath = $modernPath; AsJson = $true; AllowWindowsPowerShell51 = $true }
        $data = $response.Out | ConvertFrom-Json
        Assert-Check '5.1 parser rejects 7-only syntax' ($response.ExitCode -eq 1 -and -not $data.Valid)
    } else {
        $checks.Add([pscustomobject]@{ Name = '5.1 fallback behavior'; Status = 'Skipped: runtime absent' })
    }

    $processDoc = Get-Content -LiteralPath (Join-Path $skillRoot 'references/processes-and-windows.md') -Raw
    $captureCode = [regex]::Match($processDoc, '(?ms)^```powershell\r?\n(.*?)^```\s*$').Groups[1].Value
    $captured = & {
        $exe = $engine
        $workingDirectory = $scratch
        $source = '[Console]::Error.Write(("x" * 1048576)); [Console]::Out.Write("done")'
        $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($source))
        $nativeArgs = @('-NoLogo', '-NoProfile', '-NonInteractive', '-EncodedCommand', $encoded)
        . ([scriptblock]::Create($captureCode))
        $result
    }
    Assert-Check 'Documented capture drains 1 MiB stderr without deadlock' (
        $captured.ExitCode -eq 0 -and $captured.Stdout -eq 'done' -and $captured.Stderr.Length -eq 1048576
    )

    $rg = Get-Command rg -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($rg) {
        $contractCode = [regex]::Matches(
            (Get-Content -LiteralPath (Join-Path $skillRoot 'references/execution.md') -Raw),
            '(?ms)^```powershell\r?\n(.*?)^```\s*$'
        )[1].Groups[1].Value
        $emptyRoot = Join-Path $scratch 'empty'
        $null = New-Item -ItemType Directory -Path $emptyRoot
        & {
            $PSNativeCommandUseErrorActionPreference = $true
            $rgExe = $rg.Source
            $taskRoot = $emptyRoot
            & ([scriptblock]::Create($contractCode))
            Assert-Check 'Expected native status preserves parent preference' $PSNativeCommandUseErrorActionPreference
        }
        Assert-Check 'Documented rg no-match handling does not throw' $true
    } else {
        $checks.Add([pscustomobject]@{ Name = 'rg no-match contract'; Status = 'Skipped: rg absent' })
    }
    $checks | Format-Table -AutoSize
    [pscustomobject]@{
        Passed = @($checks | Where-Object Status -eq 'Pass').Count
        Skipped = @($checks | Where-Object Status -like 'Skipped*').Count
        Engine = $PSVersionTable.PSVersion.ToString()
    } | ConvertTo-Json
} finally {
    $tempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([char[]]'\/') + [IO.Path]::DirectorySeparatorChar
    $scratchFull = [IO.Path]::GetFullPath($scratch)
    if ($scratchFull.StartsWith($tempRoot, [StringComparison]::OrdinalIgnoreCase) -and
        [IO.Path]::GetFileName($scratchFull) -match '^ps-safe-check-[a-f0-9]{32}$') {
        Remove-Item -LiteralPath $scratchFull -Recurse -Force -ErrorAction Stop
    } else { throw 'Refusing cleanup outside the generated test directory.' }
}
