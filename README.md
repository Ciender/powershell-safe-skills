# PowerShell Safe Skills

`powershell-safe-skills` is an Agent Skill for safe Windows PowerShell automation. It focuses on preserving native argument boundaries, avoiding nested quoting failures, and handling common Windows automation traps around paths, SSH/WSL/Bash, encoding, and running executable locks.

## Repository Layout

This is a single-skill repository using the same `skills/<skill-name>/` layout used by public skill collections:

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

The installable skill directory is:

```text
skills/powershell-safe-skills
```

The repository name, skill directory, Codex invocation, Claude Code invocation, and `SKILL.md` frontmatter all use the same name:

```text
powershell-safe-skills
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

Codex can install a skill when you prompt it with the skill directory URL. In Codex, paste:

```text
$skill-installer install https://github.com/Ciender/powershell-safe-skills/tree/main/skills/powershell-safe-skills
```

You can also ask Codex in plain language:

```text
Install https://github.com/Ciender/powershell-safe-skills/tree/main/skills/powershell-safe-skills as a user-level Codex skill named powershell-safe-skills. Put the skill folder at $HOME/.agents/skills/powershell-safe-skills. Do not overwrite an existing install without asking.
```

Manual user-level install with `git clone`:

```powershell
$repo = Join-Path $env:TEMP 'powershell-safe-skills-repo'
$dest = Join-Path $HOME '.agents\skills\powershell-safe-skills'

Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue
if (Test-Path -LiteralPath $dest) {
    throw "Destination already exists: $dest"
}

git clone --depth 1 https://github.com/Ciender/powershell-safe-skills.git $repo
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dest) | Out-Null
Copy-Item -LiteralPath (Join-Path $repo 'skills\powershell-safe-skills') -Destination $dest -Recurse
Remove-Item -LiteralPath $repo -Recurse -Force
```

Manual repo-level install:

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

Codex detects skill changes automatically. If the skill does not appear, restart Codex.

## Install In Claude Code

Claude Code loads personal skills from `~/.claude/skills/<skill-name>/SKILL.md` and project skills from `.claude/skills/<skill-name>/SKILL.md`.

You can ask Claude Code in plain language:

```text
Install https://github.com/Ciender/powershell-safe-skills/tree/main/skills/powershell-safe-skills as a personal Claude Code skill named powershell-safe-skills. Put the skill folder at ~/.claude/skills/powershell-safe-skills. Do not overwrite an existing install without asking.
```

Manual personal install with `git clone`:

```powershell
$repo = Join-Path $env:TEMP 'powershell-safe-skills-repo'
$dest = Join-Path $HOME '.claude\skills\powershell-safe-skills'

Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue
if (Test-Path -LiteralPath $dest) {
    throw "Destination already exists: $dest"
}

git clone --depth 1 https://github.com/Ciender/powershell-safe-skills.git $repo
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dest) | Out-Null
Copy-Item -LiteralPath (Join-Path $repo 'skills\powershell-safe-skills') -Destination $dest -Recurse
Remove-Item -LiteralPath $repo -Recurse -Force
```

Manual project install:

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

Claude Code watches existing skill directories for `SKILL.md` changes. If the top-level skills directory did not exist when Claude Code started, restart Claude Code.

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
- Codex Customization: https://developers.openai.com/codex/concepts/customization
- Claude Code Skills: https://code.claude.com/docs/en/skills
- Agent Skills open standard: https://agentskills.io/
- Anthropic Skills examples: https://github.com/anthropics/skills
