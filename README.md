# PowerShell Safe Skills

**Version 3.0.0** | PowerShell 7 by default, explicit Windows PowerShell 5.1 fallback.

A Codex / Claude Code skill for reliable Windows automation: build commands
with correct shell semantics, preserve files and structured data, manage owned
processes, and verify the resulting application state.

It applies before constructing Windows commands hosted by PowerShell, even when
the request does not explicitly mention PowerShell. It provides instructions
and diagnostic helpers; it does not add a Windows execution connection or grant
permission to change unrelated machine settings.

## What changed in 3.0

This reconstruction combines the original `powershell-safe-skills` guidance
with `powershell-windows` 2.0.0. Useful capabilities from both are retained, with
one primary reference per topic and a short execution checklist at the entry point.

- Retains concrete safeguards for statement pipelines, native globs, exit codes,
  missing paths, Git working directories, nested quoting, and SSH/WSL/SQL.
- Adds configuration fidelity: encoding/newlines, JSON arrays and date strings,
  serialization depth, staged replacement, CSV, and bulk rename collisions.
- Adds process identity, background lifecycle, ports/services, package detection,
  MSIX path redirection, and verification that an app actually loaded a change.
- Replaces sequential stdout/stderr capture with concurrent reads and bounded
  waits, preventing the documented pipe-buffer deadlock.
- Provides environment and parse-only helpers with observable runtime selection.
- Consolidates historical evidence and supplies reproducible regression checks.

The skill name remains `powershell-safe-skills`. Old reference filenames have
been replaced by the topic layout below; historical Git commits retain the
previous package. This is a replacement package, not an overlay of old files.

## Install

Run the appropriate command in PowerShell with Git installed. The destination
must not already contain another checkout.

**Codex** (standard user-level skill directory):

```powershell
$skillBase = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $HOME '.codex' }
$destination = Join-Path $skillBase 'skills/powershell-safe-skills'
git clone 'https://github.com/Ciender/powershell-safe-skills.git' $destination
if ($LASTEXITCODE -ne 0) { throw 'Skill installation failed.' }
```

**Claude Code**:

```powershell
$destination = Join-Path $HOME '.claude/skills/powershell-safe-skills'
git clone 'https://github.com/Ciender/powershell-safe-skills.git' $destination
if ($LASTEXITCODE -ne 0) { throw 'Skill installation failed.' }
```

Reload/restart the client and verify the skill appears in its skill discovery.
Enter `$powershell-safe-skills` in Codex chat or `/powershell-safe-skills` in
Claude Code. These are chat invocations, not commands for a `PS>` prompt.

## Upgrade an existing installation

For a clean Git checkout, inspect `git status` and update with `git pull --ff-only`
from that checkout. Preserve local modifications before updating; do not reset
them automatically.

For a manually copied folder such as `powershell-safe-skills-main`, retain a
backup outside the client's skill discovery directory, then replace the entire
old skill folder with this package. An overlay leaves obsolete references behind.
Keep only one discoverable copy with the `powershell-safe-skills` identifier.

## Runtime and fallback policy

| Situation | Behavior |
| --- | --- |
| Verified Windows PowerShell 7.x / Core is available | Run normal work on that engine |
| A required feature is missing in an earlier 7.x | Use a compatible API, parser, or file/stdin input first |
| PowerShell 7 is confirmed absent | Use a faithful, isolated 5.1 fallback only where necessary and report it |
| A dependency specifically requires Windows PowerShell 5.1 | Isolate that subtask; return to 7 for the remaining work |
| The user prohibits 5.1 or no faithful fallback exists | Report the prerequisite and prepare the 7 artifact |
| A command fails, a file is locked, or access is denied | Diagnose the actual failure; do not downgrade automatically |

Normal generated scripts require 7. The two helpers deliberately have a
5.1-compatible bootstrap plus a runtime guard: **5.1 is rejected by default**.
`-AllowWindowsPowerShell51` enables only the current helper invocation on a
verified 5.1 Desktop engine. It neither launches another engine nor changes
execution policy. Results include `CompatibilityFallback` and the actual version.

The skill does not silently install a runtime, edit PATH/profiles, or relax
execution policy. Detailed compatibility rules are in [runtime.md](references/runtime.md).

## Layout and loading

| File | Purpose |
| --- | --- |
| [SKILL.md](SKILL.md) | Entry point, essential checks, and task routing |
| [runtime.md](references/runtime.md) | Host verification and controlled fallback |
| [execution.md](references/execution.md) | Native commands and PowerShell semantics |
| [cross-shell.md](references/cross-shell.md) | SSH/Plink/WSL/Bash/SQL and nested interpreters |
| [files-and-config.md](references/files-and-config.md) | Paths, encoding, configuration, and bulk edits |
| [processes-and-windows.md](references/processes-and-windows.md) | Capture, lifecycle, services, and app state |
| [diagnostics.md](references/diagnostics.md) | Observed symptom to targeted check |
| [maintenance.md](references/maintenance.md) | Merge coverage, inherited evidence, and regression scope |
| [Get-WindowsContext.ps1](scripts/Get-WindowsContext.ps1) | Selected runtime facts and executable discovery |
| [Test-PowerShellScript.ps1](scripts/Test-PowerShellScript.ps1) | Parse-only diagnostics on the executing engine |
| [Verify-Skill.ps1](tests/Verify-Skill.ps1) | Maintainer regression checks |

`agents/openai.yaml` supplies UI metadata. Only the entry point is needed at
initial use; operational references load by task. Maintenance evidence and tests
are not part of routine command context.

## Helpers

From the package root in PowerShell 7:

```powershell
& './scripts/Get-WindowsContext.ps1' -AsJson
& './scripts/Test-PowerShellScript.ps1' -LiteralPath './scripts/Get-WindowsContext.ps1' -AsJson
```

The context helper reports selected runtime facts and command paths without
executing discovered programs or dumping environment variable values. The parser
accepts `.ps1`, `.psm1`, and `.psd1` files and reports file, line, column, and
error identifier; invalid syntax or input returns exit code 1. It never executes
the inspected file. A parser pass does not prove runtime behavior or API support.

## Validation

From the repository root, under an execution policy permitting local scripts:

```powershell
pwsh -NoLogo -NoProfile -NonInteractive -File './tests/Verify-Skill.ps1'
if ($LASTEXITCODE -ne 0) { throw 'Skill regression checks failed.' }
```

The suite checks local links, executable Markdown examples, helper success/error
contracts, Chinese/spaced/bracketed paths, parse-only behavior, explicit 5.1
fallback, concurrent capture of 1 MiB stderr, and expected `rg` no-match status.
Unavailable optional runtimes/tools are reported as skipped. A present but
blocked runtime fails visibly rather than being reported as a successful check.
Temporary fixtures are isolated and removed; installed skills, application
configuration, profiles, PATH, and execution policy are not modified.

The 3.0.0 checks were run on Windows with PowerShell 7.6.0 and installed Windows
PowerShell 5.1. Earlier 7.x minors and application-specific operations are not
exhaustively tested. Historical failure frequencies in the maintenance appendix
are inherited evidence, not fresh measurements or success-rate claims.
