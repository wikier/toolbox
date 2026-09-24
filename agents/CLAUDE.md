## Style

- Write common English
- Brief but concise is better than longwinded
- Don't use em-dashes

## Cooperation

- Do not assume, ask if you there is ambiguity
- Act always in a chalenging way, be self-critic

## Workflow Orchestration

### 1. Plan Node Default
Plan mode for ANY non-trivial task (3+ steps or arch decisions). Something goes sideways: STOP, re-plan, don't push. Plan mode for verification too, not just building. Write detailed specs upfront.

### 2. Subagent Strategy
- Use subagents liberally — keep main context clean
- Offload research, exploration, parallel analysis to subagents
- Complex problems: throw more compute via subagents
- One tack per subagent

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
- Ask if I want to commit every iteration (project dependant): `[step <n>] <prompt>`
- PR: squash all worktree commits, ask for details

### Autonomous Bug Fixing
Bug report: just fix it. No hand-holding.
- Use logs, errors, failing tests — resolve them
- Zero context switching from user
- Fix failing CI tests without being told how

### Python coding

#### General Instructions
- All Python code must be [PEP 8](https://www.python.org) compliant.
- 4 spaces indent, never tabs.
- All new functions/classes: docstrings (Google Style).
- Before file mod or shell command: present plan for review.

#### Project Structure
- App logic: `/src`
- Tests: `/tests` — uses `pytest`
- Config: `/config`

#### Dependencies
- Follow  PEP 668, so use a virtual environment (`.venv/`)
- Managed via `pip3`, specified in `requirements.txt`
- Dependencies are declare in the pyproject toml file int he root of the project 
  and managed with `uv`

#### Available Scripts
*   `just install`: Installs dependencies.
*   `just start`: Starts the application server (runs `python src/app.py`).
*   `just test`: Runs tests using `pytest`.
*   `just lint`: Runs linters (e.g., `flake8`, `mypy`).
