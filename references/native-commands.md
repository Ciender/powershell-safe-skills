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

## Command Discovery

Do not assume a developer tool is installed or visible on the current `PATH`:

```powershell
$tool = Get-Command 'rg' -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $tool) {
    throw 'Required executable rg was not found on PATH.'
}

& $tool.Source @nativeArgs
```

If multiple applications share a command name, choose one deterministically with `Select-Object -First 1` or verify the exact path. Otherwise `$tool.Source` can become an array of paths and fail as one invalid executable name. If a known installation path is required, verify it with `Test-Path -LiteralPath` before invocation. Do not repeatedly retry a missing command under different quoting.

## Ripgrep Exit Codes

`rg` uses exit code 1 for a successful search with no matches:

```powershell
& $rg @rgArgs
$exitCode = $LASTEXITCODE

if ($exitCode -gt 1) {
    throw "rg failed with exit code $exitCode"
}
```

Do not report an empty `rg` result as a PowerShell failure.

## Native Globs

Do not rely on PowerShell to expand `*.ext` for a native executable. A quoted path such as `C:\root\*.md` can reach the program literally and fail with Windows error 123.

Use the native tool's glob option:

```powershell
$rgArgs = @('-n', $pattern, '-g', '*.md', $root)
& $rg @rgArgs
```

For tools without a glob option, enumerate with `Get-ChildItem -LiteralPath` and pass each full path as a separate argument.

## Git Working Directory

Do not assume the current directory is a repository. Before chaining `status`, `log`, or `diff` in an arbitrary path, verify the root:

```powershell
$git = Get-Command 'git' -CommandType Application -ErrorAction SilentlyContinue |
    Select-Object -First 1
if (-not $git) {
    throw 'Required executable git was not found on PATH.'
}

& $git.Source '-C' $root 'rev-parse' '--is-inside-work-tree' 2>$null
$exitCode = $LASTEXITCODE
if ($exitCode -ne 0) {
    throw "Not a Git repository: $root"
}
```

Stop after a failed preflight instead of running several follow-on Git commands that produce duplicate errors.

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

## Secrets Are Not Arguments

Do not place API keys, tokens, cookies, passwords, or private keys in native command arguments. Arguments can be exposed through process inspection, terminal history, and retained automation logs.

Prefer environment variables scoped to the child process, standard input when the target explicitly supports secure input, credential stores, or key/agent-based authentication. Never invent a quoted inline-password workaround.

## Avoid These Forms

```powershell
Invoke-Expression "$exe --input '$path'"
cmd.exe /c "`"$exe`" --input `"$path`""
& "$exe --input $path"
```

These forms flatten structured arguments or add another parser.
