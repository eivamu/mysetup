#!/usr/bin/env bash
set -euo pipefail

# Resolve the repo root relative to this script's location
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Detect platform
case "$(uname -s)" in
    Darwin) PLATFORM="macos" ;;
    Linux)  PLATFORM="linux" ;;
    *)
        echo "Unsupported platform: $(uname -s)"
        exit 1
        ;;
esac

# Ask for role
echo "Select role:"
echo "  1) client"
echo "  2) server"
read -rp "Choice [1]: " role_choice
case "${role_choice:-1}" in
    1) ROLE="client" ;;
    2) ROLE="server" ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac

echo ""
echo "Platform: $PLATFORM"
echo "Role:     $ROLE"
echo ""

# --- Git config ---
install_gitconfig() {
    local target="$HOME/.gitconfig"
    local includes=()

    # Collect config files that exist, in priority order
    local candidates=(
        "shared/.gitconfig"
        "shared/$ROLE/.gitconfig"
        "$PLATFORM/.gitconfig"
        "$PLATFORM/$ROLE/.gitconfig"
    )

    for candidate in "${candidates[@]}"; do
        if [[ -f "$REPO_ROOT/$candidate" ]]; then
            includes+=("$REPO_ROOT/$candidate")
        fi
    done

    if [[ ${#includes[@]} -eq 0 ]]; then
        echo "No .gitconfig files found to include, skipping."
        return
    fi

    # Back up existing config
    if [[ -f "$target" ]]; then
        local backup="$target.backup.$(date +%Y%m%d%H%M%S)"
        cp "$target" "$backup"
        echo "Backed up $target → $backup"
    fi

    # Write new config with include directives
    {
        echo "# Managed by mysetup/scripts/install.sh"
        echo "# Add machine-specific overrides below the [include] sections"
        echo ""
        for inc in "${includes[@]}"; do
            echo "[include]"
            echo "	path = $inc"
            echo ""
        done
    } > "$target"

    echo "Wrote $target with includes:"
    for inc in "${includes[@]}"; do
        echo "  - $inc"
    done
}

install_gitconfig

echo ""
echo "Done!"
