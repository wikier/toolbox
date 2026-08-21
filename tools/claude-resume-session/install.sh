#!/usr/bin/env bash
#
# install.sh
# Installs resume_claude_session.sh into ~/bin as "resume-claude-session".

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_FILE="${SCRIPT_DIR}/resume_claude_session.sh"

INSTALL_DIR="${HOME}/bin"
INSTALL_NAME="resume-claude-session"
ALIAS_MARKER="# resume-claude-session alias (added by install.sh)"
SHELL_RC_FILES=("${HOME}/.bashrc" "${HOME}/.zshrc")

check_source_exists() {
    if [[ ! -f "$SOURCE_FILE" ]]; then
        echo "Error: ${SOURCE_FILE} not found." >&2
        exit 1
    fi
}

ensure_install_dir() {
    mkdir -p "$INSTALL_DIR"
}

copy_script() {
    cp "$SOURCE_FILE" "${INSTALL_DIR}/${INSTALL_NAME}"
    chmod +x "${INSTALL_DIR}/${INSTALL_NAME}"
}

check_path() {
    case ":${PATH}:" in
        *":${INSTALL_DIR}:"*)
            ;;
        *)
            echo "Note: ${INSTALL_DIR} is not on your PATH."
            echo "Add this to your shell profile (~/.zshrc):"
            echo "  export PATH=\"${INSTALL_DIR}:\$PATH\""
            ;;
    esac
}

add_alias() {
    local alias_line="alias claude=\"${INSTALL_DIR}/${INSTALL_NAME}\""
    local rc_file

    for rc_file in "${SHELL_RC_FILES[@]}"; do
        # Only touch rc files that already exist, to avoid creating configs
        # for a shell the user doesn't use.
        [[ -f "$rc_file" ]] || continue

        if grep -qF "$ALIAS_MARKER" "$rc_file"; then
            echo "Alias already present in ${rc_file}, skipping."
            continue
        fi

        {
            echo ""
            echo "$ALIAS_MARKER"
            echo "$alias_line"
        } >> "$rc_file"
        echo "Added alias to ${rc_file}. Run 'source ${rc_file}' or open a new shell to use it."
    done
}

main() {
    check_source_exists
    ensure_install_dir
    copy_script
    check_path
    add_alias
    echo "Installed: ${INSTALL_DIR}/${INSTALL_NAME}"
}

main "$@"
