# PowerShell Safe Skills

`powershell-safe-skills` is a Codex/Claude Code skill for safe Windows PowerShell automation: native argument boundaries, quoted paths, SSH/WSL/Bash calls, encoding, filesystem mutation, and common shell traps.

## Install

Codex:

```powershell
git clone https://github.com/Ciender/powershell-safe-skills.git "$HOME/.codex/skills/powershell-safe-skills"
```

Claude Code:

```powershell
git clone https://github.com/Ciender/powershell-safe-skills.git "$HOME/.claude/skills/powershell-safe-skills"
```

Or tell Codex/Claude Code:

```text
Install https://github.com/Ciender/powershell-safe-skills as a user-level skill named powershell-safe-skills.
```

Restart Codex or Claude Code after installing.

## Invoke

Codex:

```text
$powershell-safe-skills
```

Claude Code:

```text
/powershell-safe-skills
```

## Layout

This repository is directly cloneable as a single skill:

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

## PowerShell Scope

Default target: Windows PowerShell automation through PowerShell 7+ (`pwsh.exe`).

Compatibility target: Windows PowerShell 5.1 (`powershell.exe`) when explicitly required. Core safety rules still apply, but command behavior and parameters can differ, so verify in the active shell.

## Validate

From this repository root:

```powershell
python "$env:USERPROFILE\.codex\skills\.system\skill-creator\scripts\quick_validate.py" .
```

Expected result:

```text
Skill is valid!
```
