#!/usr/bin/env bash
#
# resume_session.sh
# Finds the most recent Claude Code session for the current directory
# and (optionally) resumes it.

set -euo pipefail

CLAUDE_PROJECTS_DIR="${HOME}/.claude/projects"

# 1. Get the current working directory.
get_cwd() {
    pwd
}

# 2. Apply Claude's internal path-mapping function.
#    e.g. "/Users/sergio/tmp" -> "-Users-sergio-tmp"
map_cwd_to_project_dir() {
    local cwd="$1"
    echo "${cwd//\//-}"
}

# 3. Find the most recently written *.jsonl file for that project dir.
find_latest_session_file() {
    local project_dir="$1"
    local full_path="${CLAUDE_PROJECTS_DIR}/${project_dir}"

    if [[ ! -d "$full_path" ]]; then
        echo "No project directory found at: ${full_path}" >&2
        return 1
    fi

    # -t sorts by modification time, newest first.
    local latest
    latest="$(ls -t "${full_path}"/*.jsonl 2>/dev/null | head -n 1)"

    if [[ -z "$latest" ]]; then
        echo "No .jsonl files found in: ${full_path}" >&2
        return 1
    fi

    echo "$latest"
}

# 4. Parse the sessionId from the last line of the file.
parse_session_id() {
    local session_file="$1"
    local last_line
    last_line="$(tail -n 1 "$session_file")"

    if command -v jq >/dev/null 2>&1; then
        echo "$last_line" | jq -r '.sessionId'
    else
        echo "$last_line" | grep -o '"sessionId"[[:space:]]*:[[:space:]]*"[^"]*"' | sed -E 's/.*:"([^"]*)"/\1/'
    fi
}

# 5. Prompt the user to confirm resuming.
confirm_resume() {
    local session_id="$1"
    local answer

    read -r -p "Do you want to resume session ${session_id}? (y/N) " answer
    [[ "$answer" =~ ^[Yy]$ ]]
}

# 6. Execute the resume command.
resume_claude_session() {
    local session_id="$1"
    exec claude --resume "${session_id}"
}
exec_claude() {
    exec claude
}

main() {
    local cwd project_dir session_file session_id

    cwd="$(get_cwd)"
    project_dir="$(map_cwd_to_project_dir "$cwd")"

    if ! session_file="$(find_latest_session_file "$project_dir")"; then
        exec_claude
        return
    fi

    session_id="$(parse_session_id "$session_file")"

    if confirm_resume "$session_id"; then
        resume_claude_session "$session_id"
    else
        exec_claude
    fi
}

main "$@"
