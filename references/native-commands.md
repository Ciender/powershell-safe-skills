# Native Commands

Use this reference when PowerShell launches native programs such as `git.exe`, `ssh.exe`, `python.exe`, `cargo.exe`, `docker.exe`, or project-specific `.exe` files.

## Argument Boundaries

Correct:

```powershell
$exe = 'C:\Program Files\App\tool.exe'
$nativeArgs = @(
    '--input'
    'C:\Data Folder\input.json'
    '--name'
    'value with spaces'
    '--empty'
    ''
)

& $exe @nativeArgs
$exitCode = $LASTEXITCODE
```

Do not use `$args` as your own variable name. It is a PowerShell automatic variable populated with unbound function or script arguments.

Keep these meanings distinct:

- omitted argument
- empty string `''`
- `$null`

Do not silently filter empty arguments unless the target tool's contract explicitly requires it.

## Debugging Arguments

When an argument is being split, swallowed, or over-escaped, print each value and length:

```powershell
$nativeArgs | ForEach-Object {
    '[{0}] Length={1}' -f $_, $_.Length
}
```

Then remove wrappers in this order:

1. Remove `cmd.exe /c`.
2. Remove `pwsh -Command`.
3. Remove `Invoke-Expression`.
4. Remove manually nested quotes.
5. Invoke the executable directly with `& $exe @nativeArgs`.

## Exit Codes

Capture `$LASTEXITCODE` before another native process can overwrite it:

```powershell
& $exe @nativeArgs
$exitCode = $LASTEXITCODE

if ($exitCode -ne 0) {
    throw "$exe failed with exit code $exitCode"
}
```

Some tools define special nonzero success codes. Handle those contracts explicitly, for example `robocopy`.

Do not use `$LASTEXITCODE` for normal PowerShell cmdlet success.

## JSON Payloads

Do not hand-escape JSON. Build objects and serialize:

```powershell
$payload = [ordered]@{
    name  = $name
    path  = $path
    flags = @('a', 'b')
}

$json = $payload | ConvertTo-Json -Depth 10
& $exe '--payload' $json
```

If the JSON is consumed from a file, write with explicit encoding:

```powershell
$json | Set-Content -LiteralPath $jsonPath -Encoding utf8NoBOM
```

## Avoid These Forms

```powershell
Invoke-Expression "$exe --input '$path'"
cmd.exe /c "`"$exe`" --input `"$path`""
& "$exe --input $path"
```

These forms flatten structured arguments or add another parser.
