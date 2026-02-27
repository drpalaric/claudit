# Check 7: Verification and Validation Hooks

Claude performs significantly better when the `CLAUDE.md` tells it how to verify its own work. These hooks are the highest-leverage prompt engineering additions.

1. **Self-check commands**: Does the file instruct Claude to run tests, type checkers, or linters after making changes? If not, flag as HIGH and suggest: *"After any code change, run `[test command]`. Do not consider a task complete if tests fail."*

2. **Expected output anchors**: For non-trivial workflows, does the file describe what success looks like? Example: *"A successful build produces a `dist/` directory with no errors in stderr."*

3. **Error escalation rules**: Does the file describe what Claude should do when stuck or uncertain? Suggest adding: *"If you encounter an error you cannot resolve in two attempts, stop and report what you tried and what you expected."*

4. **Scope guardrails**: Does the file define what Claude should not do autonomously? Flag the absence for infosec contexts especially. Suggest: *"Do not modify files outside the `src/` directory without explicit confirmation."* and *"Do not run destructive commands (drop, delete, truncate, rm -rf) without confirmation."*
