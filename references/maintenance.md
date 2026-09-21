# Coverage and maintenance evidence

Maintenance only. Operational instructions live in SKILL.md and six topic
references; this appendix does not need to be loaded during normal execution.

## Sources and scope

This 3.0.0 merge combines the installed `powershell-safe-skills-main` skill and
the supplied `powershell-windows` 2.0.0 archive. The original entrypoint, README,
UI metadata, every operational reference, both historical appendices, and the
archive's two helpers were reviewed. The installed skill and archive are retained
outside this package; no private session logs or machine-specific paths are
needed to use the result.

| Source capability | Merged home |
| --- | --- |
| Native arguments, discovery, globs, exit codes, Git preflight | execution.md |
| Cmdlet/statement traps and automatic variables | SKILL.md and execution.md |
| SSH/Plink/WSL/Bash/SQL, here-strings, environment boundaries | cross-shell.md |
| Paths, recursive boundaries, mapped drives, Unicode, JSON/CSV | files-and-config.md |
| Capture, locks, background work, ports/services, app lifecycle | processes-and-windows.md |
| Failure symptom lookup | diagnostics.md |
| PS7-only policy reconciled with required fallback | runtime.md |
| Environment probe and parse-only diagnostics | scripts/ |
| Historical summary and detailed audit | This appendix, without repeated session narrative |

The original sequential stdout/stderr capture example was replaced with
concurrent reads and bounded waits. Reparse-point limitations, 5.1 source BOM,
native argument version differences, and structured-data fidelity are explicit.
The helper fallback switches are opt-in and do not select another engine.

## Historical observations, not new measurements

The installed evidence reports a 2026-09-07 review of 848 rollout files, 6,622
modern PowerShell command records (6,066 completed, 511 failed, 45 declined),
and 2,109 older command records (218 nonzero exits). Populations and categories
overlap; they must not be summed. These figures were **not independently
recomputed for this merge** and are not performance claims for the new skill.

| Recorded pattern | Count |
| --- | ---: |
| Direct foreach-to-pipeline syntax | 47 |
| Missing path used by dependent operations | 41 |
| rg no-match treated as failure | 38 |
| Git outside a repository | 29 |
| File handle conflicts | 18 |
| Missing executable/cmdlet | 15 |
| Nested quoting/backslash-quote corruption | 14 |
| Literal native globs | 11 |
| Bash heredoc in PowerShell | 6 |

Low-frequency but consequential safeguards remain: mutation containment,
credential handling, native exit contracts, exact process arguments, mapped
drives, binary data, and process identity. Original audit identifiers and verbose
change history are omitted; their operational conclusions are retained.

## Regression checks

Run `tests/Verify-Skill.ps1` on Windows PowerShell 7. It checks local Markdown
links, executable PowerShell examples, helper behavior, special paths, invalid
syntax, missing input, and default refusal/explicit opt-in on installed 5.1.
It also tests concurrent capture with large stderr and the native no-match
contract when `rg` is available. Missing optional engines/tools are reported as
skips, not successes. It creates and removes only its own temporary fixtures.

For future changes, also exercise scenarios affected by the edit: nested JSON
with empty/singleton arrays and date strings, a junction crossing the authorized
root, remote script bytes, inherited output handles, or a rerun of a batch move.
Do not claim these optional scenarios passed merely because Markdown parses.

Keep invalid examples in `text` fences and executable examples in `powershell`
fences. Parser checks do not execute snippets or prove behavior. Add a regression
for a demonstrated defect; keep each rule's detailed mechanics in one topic
instead of growing several duplicate checklists.
