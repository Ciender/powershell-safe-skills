# Historical Failure Summary

This maintenance summary names the recurring PowerShell-hosted failures that
are covered by the operational rules. Detailed counts, provenance, and audit
notes remain in [`history-evidence.md`](history-evidence.md); this file exists
as the stable summary reference used by `SKILL.md`.

| Failure pattern | Count | Primary safeguard |
| --- | ---: | --- |
| Direct `foreach (...) { ... } | ...` | 47 | Capture statement output before piping. |
| Missing paths used by dependent reads | 41 | Verify with `Test-Path -LiteralPath`. |
| `rg` exit code 1 with no output | 38 | Treat only codes above 1 as errors. |
| Git command outside a repository | 29 | Preflight with `git -C <root> rev-parse`. |
| File read/hash/copy blocked by an open handle | 18 | Handle locks per file; stop only authorized stale processes. |
| Missing executable or cmdlet | 15 | Resolve and verify the command before invocation. |
| Nested quoting or Bash-style `\"` | 14 | Use single-quoted literals, arrays, or script files. |
| Native wildcard path passed literally | 11 | Use native glob options or enumerate files. |
| Bash heredoc sent to PowerShell | 6 | Use a PowerShell here-string or `.ps1` file. |
| `$skill-installer` typed at a `PS>` prompt | 1 | Use skill syntax in chat; invoke an executable in PowerShell. |

This file is for maintenance and evaluation, not routine command execution.
