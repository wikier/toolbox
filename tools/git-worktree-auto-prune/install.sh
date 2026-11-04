#!/usr/bin/env bash
#
# install.sh
# Installs git_worktree_auto_prune.sh into ~/bin as "git-worktree-auto-prune".
# Being on PATH with a git- prefix also enables `git worktree-auto-prune`.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_FILE="${SCRIPT_DIR}/git_worktree_auto_prune.sh"

INSTALL_DIR="${HOME}/bin"
INSTALL_NAME="git-worktree-auto-prune"

check_source_exists() {
    if [[ ! -f "$SOURCE_FILE" ]]; then
        echo "Error: ${SOURCE_FILE} not found." >&2
        exit 1
    fi
}

copy_script() {
    mkdir -p "$INSTALL_DIR"
    cp "$SOURCE_FILE" "${INSTALL_DIR}/${INSTALL_NAME}"
    chmod +x "${INSTALL_DIR}/${INSTALL_NAME}"
}

check_path() {
    case ":${PATH}:" in
        *":${INSTALL_DIR}:"*) ;;
        *)
            echo "Note: ${INSTALL_DIR} is not on your PATH."
            echo "Add this to your shell profile (~/.zshrc):"
            echo "  export PATH=\"${INSTALL_DIR}:\$PATH\""
            ;;
    esac
}

main() {
    check_source_exists
    copy_script
    check_path
    echo "Installed: ${INSTALL_DIR}/${INSTALL_NAME}"
}

main "$@"
