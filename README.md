# PowerShell Safe Skills

`powershell-safe-skills` is an Agent Skill for safe Windows PowerShell automation. It focuses on preserving native argument boundaries, avoiding nested quoting failures, and handling common Windows automation traps around paths, SSH/WSL/Bash, encoding, and running executable locks.

## Format

This repository uses a **multi-skill-compatible layout** even though it currently contains one skill:

```text
.
├── README.md
└── skills/
    └── powershell-safe-skills/
        ├── SKILL.md
        ├── agents/
        │   └── openai.yaml
        └── references/
            ├── native-commands.md
            ├── cmdlets-filesystem.md
            ├── cross-shell.md
            ├── process-encoding.md
            └── diagnostics.md
```

The installable skill path is:

```text
skills/powershell-safe-skills
```

This keeps the GitHub repository readable while keeping the skill folder name aligned with the `SKILL.md` name:

```yaml
name: powershell-safe-skills
```

## PowerShell Version Scope

Default target:

- Windows
- PowerShell 7+ through `pwsh.exe`
- Codex, Claude Code, or other automation layers that run commands through PowerShell

Compatibility scope:

- Windows PowerShell 5.1 through `powershell.exe`
- Use 5.1 only when explicitly required.
- Verify syntax and behavior in the active shell because cmdlet parameters and native argument behavior can differ between 5.1 and 7+.

The core rules apply to both PowerShell 7+ and Windows PowerShell 5.1:

- Use native argument arrays: `& $exe @nativeArgs`.
- Do not flatten structured commands into one quoted string.
- Prefer `.ps1` files or here-strings for multiline code, JSON, regex, SSH, WSL, Bash, and non-ASCII text.
- Use `-LiteralPath` for real filesystem paths.
- Capture `$LASTEXITCODE` immediately after native commands.
- Do not use `$LASTEXITCODE` for normal cmdlet success.
- Treat encoding, BOM, Chinese text, and running `.exe` locks as Windows automation concerns.

## Install In Codex

Using the Codex skill installer:

```powershell
python "$env:USERPROFILE\.codex\skills\.system\skill-installer\scripts\install-skill-from-github.py" `
  --repo Ciender/powershell-safe-skills `
  --path skills/powershell-safe-skills
```

Manual user install for Codex builds that scan `$env:USERPROFILE\.agents\skills`:

```powershell
$repo = Join-Path $env:TEMP 'powershell-safe-skills-repo'
$dest = "$env:USERPROFILE\.agents\skills\powershell-safe-skills"

Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue
if (Test-Path -LiteralPath $dest) {
    throw "Destination already exists: $dest"
}

git clone --depth 1 https://github.com/Ciender/powershell-safe-skills.git $repo
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dest) | Out-Null
Copy-Item -LiteralPath (Join-Path $repo 'skills\powershell-safe-skills') -Destination $dest -Recurse
Remove-Item -LiteralPath $repo -Recurse -Force
```

Manual repo-scoped install for Codex builds that scan `.agents/skills`:

```powershell
$repo = Join-Path $env:TEMP 'powershell-safe-skills-repo'
$dest = '.agents\skills\powershell-safe-skills'

Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue
if (Test-Path -LiteralPath $dest) {
    throw "Destination already exists: $dest"
}

git clone --depth 1 https://github.com/Ciender/powershell-safe-skills.git $repo
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dest) | Out-Null
Copy-Item -LiteralPath (Join-Path $repo 'skills\powershell-safe-skills') -Destination $dest -Recurse
Remove-Item -LiteralPath $repo -Recurse -Force
```

Invoke explicitly in Codex with:

```text
$powershell-safe-skills
```

## Install In Claude Code

Claude Code loads custom skills from filesystem directories containing `SKILL.md`. The directory name is the slash command name, so install the skill directory as `powershell-safe-skills`.

Personal install:

```powershell
$repo = Join-Path $env:TEMP 'powershell-safe-skills-repo'
$dest = "$env:USERPROFILE\.claude\skills\powershell-safe-skills"

Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue
if (Test-Path -LiteralPath $dest) {
    throw "Destination already exists: $dest"
}

git clone --depth 1 https://github.com/Ciender/powershell-safe-skills.git $repo
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dest) | Out-Null
Copy-Item -LiteralPath (Join-Path $repo 'skills\powershell-safe-skills') -Destination $dest -Recurse
Remove-Item -LiteralPath $repo -Recurse -Force
```

Project install:

```powershell
$repo = Join-Path $env:TEMP 'powershell-safe-skills-repo'
$dest = '.claude\skills\powershell-safe-skills'

Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue
if (Test-Path -LiteralPath $dest) {
    throw "Destination already exists: $dest"
}

git clone --depth 1 https://github.com/Ciender/powershell-safe-skills.git $repo
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dest) | Out-Null
Copy-Item -LiteralPath (Join-Path $repo 'skills\powershell-safe-skills') -Destination $dest -Recurse
Remove-Item -LiteralPath $repo -Recurse -Force
```

Invoke explicitly in Claude Code with:

```text
/powershell-safe-skills
```

Claude Code uses `SKILL.md` and `references/`. The `agents/openai.yaml` file is Codex-facing metadata and can be ignored by Claude Code.

## Validate Locally

From the repository root:

```powershell
python "$env:USERPROFILE\.codex\skills\.system\skill-creator\scripts\quick_validate.py" '.\skills\powershell-safe-skills'
```

Expected result:

```text
Skill is valid!
```

## References

- Codex Agent Skills: https://developers.openai.com/codex/skills
- Claude Code Skills: https://code.claude.com/docs/en/skills
- Agent Skills open format: https://agentskills.io/
- Anthropic Skills examples: https://github.com/anthropics/skills
