# PowerShell Safe Skills

`powershell-safe-skills` is a Codex/Claude Code skill for every Windows shell task hosted by PowerShell: native argument boundaries, pipelines, ripgrep globs and exit codes, quoted paths, SSH/Plink/WSL/Bash/SQL calls, encoding, filesystem mutation, file locks, and common shell traps.

## Install

Codex:

```powershell
$repositoryUrl = 'https://github.com/Ciender/powershell-safe-skills.git'
git clone $repositoryUrl "$HOME/.codex/skills/powershell-safe-skills"
```

Claude Code:

```powershell
$repositoryUrl = 'https://github.com/Ciender/powershell-safe-skills.git'
git clone $repositoryUrl "$HOME/.claude/skills/powershell-safe-skills"
```

Or tell Codex/Claude Code:

```text
Install the powershell-safe-skills repository as a user-level skill named powershell-safe-skills.
```

Restart Codex or Claude Code after installing.

## Recent update

This release expands the trigger to all Windows shell commands hosted by
PowerShell and adds preflight guidance for the most frequent failure modes:

- capture `foreach`/`if`/`switch` output before piping;
- treat `rg` exit code 1 as “no matches”, not a command failure;
- avoid Bash-style `\"` escaping and native wildcard paths;
- replace Bash heredocs with PowerShell here-strings or script files;
- verify paths, Git roots, executable discovery, and the active PowerShell
  version before dependent operations;
- keep passwords, tokens, cookies, and private keys out of command arguments;
- use literal stdin scripts across SSH/WSL/Bash/SQL boundaries; and
- distinguish file locks and encoding issues from syntax failures.

The historical evidence and maintenance summary are kept under
`references/history-evidence.md` and `references/history-derived-failures.md`.

## Invoke

Codex:

```text
$powershell-safe-skills
```

Claude Code:

```text
/powershell-safe-skills
```

Important: enter `$powershell-safe-skills` in the Codex chat box, not at a `PS C:\...>` terminal prompt. In PowerShell, `$powershell-safe-skills` is parsed as a variable/expression, not as a skill invocation or executable command.

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
    ├── diagnostics.md
    ├── history-derived-failures.md
    └── history-evidence.md
```

`history-derived-failures.md` and `history-evidence.md` are audit/maintenance appendices. They are not intended to be loaded for ordinary PowerShell command execution.

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
