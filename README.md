# PowerShell Safe Skills

`powershell-safe-skills` is an Agent Skill for safe Windows PowerShell automation. It focuses on preserving native argument boundaries, avoiding nested quoting failures, and handling common Windows automation traps around paths, SSH/WSL/Bash, encoding, and running executable locks.

## Format

This repository is a **single-skill repository**. The repository root is the skill directory:

```text
.
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

This matches the Agent Skills shape used by Codex and Claude Code: a skill is a folder containing `SKILL.md`, with optional supporting directories such as `references/`, `scripts/`, `assets/`, and product-specific metadata such as `agents/openai.yaml`.

Because this is a single-skill repository, `SKILL.md` is at the repository root. If you later embed it into a multi-skill repository, place it under:

```text
skills/powershell-safe-skills/
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

Manual user install using the current Codex user-skill location:

```powershell
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.agents\skills" | Out-Null
git clone https://github.com/Ciender/powershell-safe-skills.git "$env:USERPROFILE\.agents\skills\powershell-safe-skills"
```

Repo-scoped install:

```powershell
New-Item -ItemType Directory -Force -Path '.agents\skills' | Out-Null
git clone https://github.com/Ciender/powershell-safe-skills.git '.agents\skills\powershell-safe-skills'
```

Using the Codex skill installer, when your Codex build provides it:

```powershell
python "$env:USERPROFILE\.codex\skills\.system\skill-installer\scripts\install-skill-from-github.py" `
  --repo Ciender/powershell-safe-skills `
  --path . `
  --name powershell-safe-skills
```

Older/local Codex builds may use `$CODEX_HOME/skills` or `$env:USERPROFILE\.codex\skills`:

```powershell
$dest = "$env:USERPROFILE\.codex\skills\powershell-safe-skills"
git clone https://github.com/Ciender/powershell-safe-skills.git $dest
```

Codex detects skill changes automatically in most cases. Restart Codex if the skill does not appear.

Invoke explicitly in Codex with:

```text
$powershell-safe-skills
```

## Install In Claude Code

Claude Code loads custom skills from filesystem directories containing `SKILL.md`. The directory name is the slash command name, so clone this repository into a directory named `powershell-safe-skills`.

Personal install:

```powershell
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.claude\skills" | Out-Null
git clone https://github.com/Ciender/powershell-safe-skills.git "$env:USERPROFILE\.claude\skills\powershell-safe-skills"
```

Project install:

```powershell
New-Item -ItemType Directory -Force -Path '.claude\skills' | Out-Null
git clone https://github.com/Ciender/powershell-safe-skills.git '.claude\skills\powershell-safe-skills'
```

Invoke explicitly in Claude Code with:

```text
/powershell-safe-skills
```

Claude Code uses `SKILL.md` and `references/`. The `agents/openai.yaml` file is Codex-facing metadata and can be ignored by Claude Code.

## Validate Locally

From the repository root:

```powershell
python "$env:USERPROFILE\.codex\skills\.system\skill-creator\scripts\quick_validate.py" .
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
