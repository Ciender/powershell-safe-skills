# Files, encoding, and configuration

## Resolve the actual target

Build paths with `Join-Path`; use `-LiteralPath` for real names, including brackets.
Use `-Path` only when wildcard expansion is intended. Verify filesystem provider
and file/directory type when they matter. Resolve existing paths with
`Resolve-Path -LiteralPath`; for a new target, resolve its existing parent and
validate the leaf. .NET file APIs need absolute paths: their process working
directory can differ from PowerShell's `Get-Location`.

Before recursive delete, move, or overwrite, reject empty paths, filesystem roots,
unexpected targets, and the authorized root itself unless explicitly included.
Compare full paths using a separator boundary, not a raw string prefix:

```powershell
$rootPath = (Resolve-Path -LiteralPath $authorizedRoot -ErrorAction Stop).ProviderPath
$targetPath = (Resolve-Path -LiteralPath $candidate -ErrorAction Stop).ProviderPath
$rootPrefix = $rootPath.TrimEnd([char[]]'\/') + [IO.Path]::DirectorySeparatorChar
if (-not $targetPath.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)) {
    throw 'Target is not a descendant of the authorized root.'
}
```

This is only a lexical boundary check. Inspect reparse points/junctions in the
target, its ancestors, and traversed descendants before mutation; `GetFullPath`
and `Resolve-Path` do not establish final physical containment. Reject an
unexpected link or resolve and authorize its actual destination. Re-check just
before mutation; a preflight cannot prevent every concurrent path change. Keep
enumeration and mutation in PowerShell end to end. Do not mirror directories
destructively unless that behavior was requested.

Mapped drives are scoped to a logon session. An elevated process, service,
sandbox, or scheduled task may not see the interactive user's mapping. Check
the executing identity, `Get-PSDrive`, and `Test-Path`; use a verified UNC path
or establish the mapping in the authorized session. Do not guess a network share.

## Encoding follows the consumer

| Data | Choice |
| --- | --- |
| New cross-platform JSON/source | Explicit UTF-8 without BOM unless the consumer requires otherwise |
| PowerShell 7 source with Chinese text | UTF-8, with or without BOM |
| Windows PowerShell 5.1 source with non-ASCII text | UTF-8 with BOM; see [runtime](runtime.md) |
| Existing text/CSV | Preserve detected encoding and newline convention |
| Excel-facing CSV | Explicit delimiter; UTF-8 with BOM is often appropriate |
| Native streams | Check the program's encoding separately from file encoding |

No BOM does not prove UTF-8. Check format conventions or decode strictly; a
successful replacement-character decode is not proof. For known UTF-8 data:

```powershell
$utf8NoBom = [Text.UTF8Encoding]::new($false, $true)
$text = [IO.File]::ReadAllText($absoluteInputPath, $utf8NoBom)
[IO.File]::WriteAllText($absoluteOutputPath, $text, $utf8NoBom)
```

Inspect the first bytes when a BOM matters (`EF BB BF` is UTF-8). Terminal
mojibake alone does not establish file corruption. Python readers may use
`utf-8-sig` for optional UTF-8 BOM. Distinguish source decoding, data encoding,
`[Console]::OutputEncoding`, and `$OutputEncoding` for native stdin; `chcp 65001`
does not fix every boundary. Scope changes and restore process-wide settings.

Binary data belongs in file/byte APIs, not text cmdlets. Do not truncate UTF-8
at an arbitrary byte index; that can split a character.

## Structured configuration

Use format-aware parsers for JSON, JSONC, TOML, YAML, XML, and CSV. Change only
requested values. JSON is not JSONC; do not silently discard comments. Do not
print whole configurations when selected keys or redacted values suffice.

For JSON, use `ConvertFrom-Json -AsHashtable` on 7 for case-distinct or empty
property names. Keep date-like strings unchanged with `-DateKind String` where
available, or a parser with equivalent behavior. Duplicate keys or syntax that
the parser cannot preserve require an appropriate editing strategy. Account for
these constraints before using the simple object-shaped example below:

```powershell
$config = Get-Content -LiteralPath $configPath -Raw -Encoding UTF8 -ErrorAction Stop |
    ConvertFrom-Json -ErrorAction Stop
# Change the requested property on $config before serialization.
$serialized = ConvertTo-Json -InputObject $config -Depth 50 -WarningAction Stop
$roundTrip = ConvertFrom-Json -InputObject $serialized -ErrorAction Stop
```

Choose depth for the actual document; treat truncation warnings as failure.
Use `-InputObject` when serializing arrays to preserve empty/singleton shape.
When parsing a top-level array with `ConvertFrom-Json`, use `-NoEnumerate` on a
supporting engine or an equivalent parser so the pipeline does not collapse it.
Validate requested values and unrelated fields, not merely parse success.

When practical, stage beside the destination, read back and validate, then
replace it. `[IO.File]::Replace` needs an existing destination and supporting
filesystem and can retain a backup. For new files, move with overwrite disabled.
Check for concurrent edits before replacement. A host-mandated editing tool
takes precedence; perform equivalent structural checks afterward.

## CSV and batch operations

Use `Import-Csv`/`Export-Csv` with explicit delimiter, encoding, and deliberate
column order; never split on commas. Keep values as data. Do not evaluate
formulas or shell fragments encountered in inputs.

Before bulk rename/move, compute the mapping and check absent inputs, duplicate
destinations, existing outputs, and source/destination overlap. Use two-stage
renaming for cycles or case-only changes when needed. Verify counts and names;
a second run should be idempotent or clearly identify completed work.

Source: [character encoding](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_character_encoding).
