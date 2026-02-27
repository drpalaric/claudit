# Check 5: Instruction Clarity and Specificity

1. **Vague verbs**: Flag phrases like "be careful with", "handle properly", "use best practices for", "make sure it's secure". Replace with specific, observable actions: *"Before deleting any file, confirm with the user"* or *"After every code change, run `[test command]` and report failures."*

2. **Contradictory instructions**: Scan for logical conflicts — e.g., *"Always ask before running commands"* alongside *"Run tests automatically after each change."* Flag the conflict and note which instruction takes precedence, or ask the user to decide.

3. **Audience mismatch**: Instructions written as if explaining to a junior developer (*"remember that X is important"*, *"be aware that..."*) provide no actionable direction to Claude. Rewrite as directives: "Do X when Y."

4. **Missing build/test/lint commands**: If the file doesn't include the exact commands to build, test, and lint the project, flag as HIGH. This is the single highest-ROI addition to any `CLAUDE.md`. Document these five command types for the project's stack:
   ```
   Build:   [compile or validate the project builds cleanly]
   Test:    [run the full test suite, non-interactive, fail-fast]
   Lint:    [run the configured linter — errors block completion]
   Format:  [verify formatting without mutating files]
   Audit:   [scan dependencies for known vulnerabilities]
   ```
   The specific tools vary by language. What matters is that Claude knows the exact invocation — not a description of what to run.

5. **Missing tool or runtime version constraints**: If the project has strict version requirements (Node 20+, Python 3.11+, Go 1.22+), they should be stated. This prevents Claude from suggesting deprecated APIs or incompatible patterns.

6. **Missing rationale on important rules**: Constraints without a "why" are treated as optional suggestions. For any rule that a developer might reasonably question, add a one-line reason. This is especially important for rules that prohibit common patterns — Claude may silently consider them outdated. See Check 4 for detailed guidance.

7. **Verbose or narrative writing style**: Flag paragraphs that could be bullet points, explanations that could be code examples, and preamble that adds no directive. Principles:
   - Lead with the rule, explain "why" second (if needed at all)
   - Show with code examples rather than describing in prose
   - Use bullet points over paragraphs
   - Skip the obvious
