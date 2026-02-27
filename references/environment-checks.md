# Check 6: Environment and Workflow Configuration

1. **MCP server configuration**: If the project uses MCP servers, does the file specify which ones to use and for what purpose? Missing configuration causes Claude to use defaults or ask repeatedly. Suggest documenting the MCP tools in scope.

2. **Parallel session setup**: For larger codebases, does the file enable parallelism? If not, suggest adding: *"Use the Task tool to run independent checks (linting, type checking, unit tests) in parallel rather than sequentially."*

3. **Working directory assumptions**: Does the file state the expected working directory? Ambiguity causes path errors in projects with monorepo structures. Suggest: *"All commands run from the project root unless specified otherwise."*

4. **Required environment variables**: List environment variables required for the project to function and where to obtain them. This prevents Claude from attempting operations that will fail silently or prompt for credentials mid-task.

5. **Git and commit conventions**: If the project has branch naming conventions, commit message formats (Conventional Commits, etc.), or PR requirements, state them. Example: *"All commits must follow Conventional Commits: `feat:`, `fix:`, `chore:`. Do not amend published commits."*

6. **Context window management for large codebases**: If the repository is large (>50k LOC), does the file guide Claude on what to skip? Without explicit guidance, Claude will read generated files, vendored code, and build artifacts unnecessarily. Flag as MEDIUM if absent. The CLAUDE.md should explicitly list the no-read directories for this project's stack — generated output, dependency caches, build artifacts, and test coverage outputs. Common examples: `node_modules/`, `target/` (Maven), `build/` (Gradle), `.gradle/`, `dist/`, `__pycache__/`, `vendor/`. It should also name one or two high-signal entry files for Claude to start from: *"Start by reading `docs/architecture.md` before exploring further."*
