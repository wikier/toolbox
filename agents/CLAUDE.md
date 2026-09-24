## Style

- Write common English
- Brief and clear
- Don't use em-dashes

## Cooperation

- Do not assume, ask if there is any ambiguity
- Act always in a challenging way, use self-criticism
- If you feel there is an obvious counterpart that will review the output, act as them

## Workflow Orchestration

### 1. Plan Mode as Default
Plan mode for ANY non-trivial task (3+ steps or arch decisions). Something goes sideways: STOP, re-plan, don't push. Plan mode for verification too, not just building. Write detailed specs upfront.

### 2. Subagent Strategy
- Use subagents liberally, keep main context clean
- Offload research, exploration, parallel analysis to subagents
- Complex problems: throw more compute via subagents
- One task per subagent

### 3. Self-Improvement Loop
- After ANY correction: update `tasks/lessons.md`. Write rules preventing same mistake.
- Iterate ruthlessly until mistake rate drops
- Review lessons at session start

### 4. Verification Before Done
- Never mark complete without proving it works
- Diff main vs changes when relevant
- "Would staff engineer approve this?" Run tests, check logs, demonstrate correctness.

### 5. Demand Elegance (Balanced)
Non-trivial changes: ask "more elegant way?" Hacky fix: implement elegant solution. Skip for simple/obvious. Challenge own work first.

## Task Management
1. **Plan First**: Write plan to `tasks/todo.md` with checkable items
2. **Verify Plan**: Check in before implementation
3. **Track Progress**: Mark items complete as you go
4. **Explain Changes**: High-level summary each step
5. **Document Results**: Add review section to `tasks/todo.md`
6. **Capture Lessons**: Update `tasks/lessons.md` after corrections

## Coding

### Core Principles
1. **Simplicity First**: Changes as simple as possible. Minimal code impact.
2. **No Laziness**: Root causes. No temp fixes. Senior dev standards.
3. **Minimal Impact**: Touch only what's necessary. No new bugs.
4. **Test-driven**: Tests first. Then implementation.

### Source control
- git for versions. Init repo if missing.
- Ignore artifacts: app outputs, OS stuff (`.DS_Store`, `.idea`, etc.)
- Spinout new worktree for current working set
- Ask if I want to commit every iteration (project dependent): `[step <n>] <prompt>`
- PR: squash all worktree commits, ask for details

### Bug Fixing
- Report bugs
- Fix without asking only if there is a clear bug
- Otherwise, provide context on how the bug happens and provide recommendations before acting

#### Available Scripts
Use a `justfile` to abstract task from the specific stack:
- `just install`: Installs dependencies
- `just lint`: Runs linters 
- `just build`: builds the code (if it applies)
- `just start`: Starts the application/server
- `just test`: Runs tests

#### Project Structure
- App logic: `/src`
- Tests: `/tests` uses `pytest`
- Config: `/config`

### Python coding

(Only for Python projects, ignore otherwise)

#### General Instructions
- All Python code must be [PEP 8](https://peps.python.org/pep-0008/) compliant.
- 4 spaces indent, never tabs.
- All new functions/classes: docstrings (Google Style).
- Before file mod or shell command: present plan for review.

#### Dependencies
- Follow PEP 668, so use a virtual environment (`.venv/`)
- Dependencies are declared in the pyproject.toml file in the root of the project 
  and managed with `uv`
