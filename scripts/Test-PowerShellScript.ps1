#requires -Version 5.1
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string[]]$LiteralPath,
    [switch]$AllowWindowsPowerShell51,
    [switch]$AsJson
)

$onWindows = [Environment]::OSVersion.Platform -eq [PlatformID]::Win32NT
$isSeven = $PSVersionTable.PSEdition -eq 'Core' -and $PSVersionTable.PSVersion.Major -eq 7
$isLegacy = $onWindows -and $PSVersionTable.PSEdition -eq 'Desktop' -and
    $PSVersionTable.PSVersion.Major -eq 5 -and $PSVersionTable.PSVersion.Minor -eq 1
if (-not ($isSeven -or ($isLegacy -and $AllowWindowsPowerShell51))) {
    throw 'PowerShell 7 is required. An isolated 5.1 fallback needs -AllowWindowsPowerShell51.'
}
Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'
$failed = $false
$files = @(foreach ($candidatePath in $LiteralPath) {
    $diagnostics = @()
    $displayPath = $candidatePath
    try {
        $item = Get-Item -LiteralPath $candidatePath -ErrorAction Stop
        if ($item.PSProvider.Name -ne 'FileSystem' -or $item.PSIsContainer) {
            throw 'Expected a filesystem script file.'
        }
        if ($item.Extension -notin @('.ps1', '.psm1', '.psd1')) {
            throw 'Expected a .ps1, .psm1, or .psd1 file.'
        }
        $displayPath = $item.FullName
        $tokens = $null
        $parseErrors = $null
        $null = [Management.Automation.Language.Parser]::ParseFile(
            $item.FullName, [ref]$tokens, [ref]$parseErrors
        )
        $diagnostics = @($parseErrors | ForEach-Object {
            [pscustomobject][ordered]@{
                ErrorId = $_.ErrorId
                Message = $_.Message
                Line = $_.Extent.StartLineNumber
                Column = $_.Extent.StartColumnNumber
            }
        })
    } catch {
        $diagnostics = @([pscustomobject][ordered]@{
            ErrorId = 'InputFileError'
            Message = $_.Exception.Message
            Line = $null
            Column = $null
        })
    }
    $valid = $diagnostics.Count -eq 0
    if (-not $valid) { $failed = $true }
    [pscustomobject][ordered]@{
        Path = $displayPath
        Valid = $valid
        ErrorCount = $diagnostics.Count
        Errors = $diagnostics
    }
})

$result = [pscustomobject][ordered]@{
    PowerShellVersion = $PSVersionTable.PSVersion.ToString()
    Edition = $PSVersionTable.PSEdition
    CompatibilityFallback = [bool]$isLegacy
    Valid = -not $failed
    Files = $files
}
if ($AsJson) { ConvertTo-Json -InputObject $result -Depth 8 }
else { $result }
if ($failed) { exit 1 }
exit 0
