# Processes, Encoding, And Locks

Use this reference for `Start-Process`, `ProcessStartInfo`, stdout/stderr capture, text encoding, binary data, Chinese text, and Windows executable locks.

## Start-Process

For normal foreground execution, prefer:

```powershell
& $exe @nativeArgs
```

Use `Start-Process` only when you need:

- elevation
- new or hidden window behavior
- detached/background launch
- shell association behavior
- an explicit process object under its semantics

`Start-Process -ArgumentList` joins values into a command-line string. It is not a reliable structured-argument API.

## ProcessStartInfo.ArgumentList

For exact argument boundaries in a separate process, use `ProcessStartInfo.ArgumentList`:

```powershell
$psi = [System.Diagnostics.ProcessStartInfo]::new()
$psi.FileName = $exe
$psi.UseShellExecute = $false

$psi.ArgumentList.Add('--input')
$psi.ArgumentList.Add('C:\Path With Spaces\input.json')
$psi.ArgumentList.Add('--empty')
$psi.ArgumentList.Add('')

$process = [System.Diagnostics.Process]::Start($psi)
$process.WaitForExit()

if ($process.ExitCode -ne 0) {
    throw "Process failed with exit code $($process.ExitCode)"
}
```

## Capturing Stdout And Stderr

Use `ProcessStartInfo` when stdout and stderr must be captured separately:

```powershell
$psi = [System.Diagnostics.ProcessStartInfo]::new()
$psi.FileName = $exe
$psi.UseShellExecute = $false
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError = $true

foreach ($arg in $nativeArgs) {
    $psi.ArgumentList.Add($arg)
}

$process = [System.Diagnostics.Process]::Start($psi)
$stdout = $process.StandardOutput.ReadToEnd()
$stderr = $process.StandardError.ReadToEnd()
$process.WaitForExit()

if ($process.ExitCode -ne 0) {
    throw "Command failed with exit code $($process.ExitCode): $stderr"
}
```

Do not pipe binary output through text cmdlets.

## Encoding And BOM

For cross-platform source code, Markdown, YAML, and JSON, prefer:

```text
UTF-8 no BOM
```

PowerShell 7 supports:

```powershell
Set-Content -LiteralPath $path -Value $text -Encoding utf8NoBOM
```

Windows PowerShell 5.1 `-Encoding utf8` commonly writes a UTF-8 BOM. If only 5.1 is available, use .NET:

```powershell
$utf8NoBom = [System.Text.UTF8Encoding]::new($false)
[System.IO.File]::WriteAllText($path, $text, $utf8NoBom)
```

Check BOM:

```powershell
$bytes = [System.IO.File]::ReadAllBytes('README.md')
($bytes[0..2] | ForEach-Object { $_.ToString('X2') }) -join ' '
```

UTF-8 BOM is:

```text
EF BB BF
```

## Chinese Text And Mojibake

Terminal mojibake does not prove the file is corrupt. Verify bytes or read with explicit encoding:

```powershell
[System.IO.File]::ReadAllText(
    'README.md',
    [System.Text.UTF8Encoding]::new($false)
)
```

Use `utf-8-sig` when reading files that may contain a BOM from Python:

```powershell
@'
from pathlib import Path
text = Path("README.md").read_text(encoding="utf-8-sig")
print(text[:200])
'@ | python -
```

Do not truncate UTF-8 text by arbitrary byte index unless the cut point is a valid character boundary. This matters for logs, AI summaries, CLI output limits, and Rust `String` truncation.

## Binary Data

For binary data, use byte APIs:

```powershell
[System.IO.File]::WriteAllBytes($path, $bytes)
```

Do not use text cmdlets for images, archives, executables, or other binary files.

## Windows Running Exe Locks

Windows cannot overwrite a running executable. Common failure:

```text
failed to remove file target\debug\app.exe
Access is denied. (os error 5)
```

Find and stop the old process:

```powershell
Get-Process | Where-Object { $_.ProcessName -like '*app*' }
Stop-Process -Id <pid>
```

Before automated builds, ensure the target executable is not held by a previous `cargo run`, test process, or background service.
