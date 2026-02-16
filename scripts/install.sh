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

# --- Package helpers ---
pkg_install() {
    if [[ $PLATFORM == "macos" ]]; then
        local to_install=()
        for pkg in "$@"; do
            if ! brew list --formula "$pkg" &>/dev/null; then
                to_install+=("$pkg")
            fi
        done
        if [[ ${#to_install[@]} -gt 0 ]]; then
            echo "brew install ${to_install[*]}"
            brew install "${to_install[@]}"
        fi
    else
        if command -v apt-get &>/dev/null; then
            local to_install=()
            for pkg in "$@"; do
                if ! dpkg -s "$pkg" &>/dev/null; then
                    to_install+=("$pkg")
                fi
            done
            if [[ ${#to_install[@]} -gt 0 ]]; then
                echo "apt-get install ${to_install[*]}"
                sudo apt-get install -y "${to_install[@]}"
            fi
        elif command -v dnf &>/dev/null; then
            local to_install=()
            for pkg in "$@"; do
                if ! rpm -q "$pkg" &>/dev/null; then
                    to_install+=("$pkg")
                fi
            done
            if [[ ${#to_install[@]} -gt 0 ]]; then
                echo "dnf install ${to_install[*]}"
                sudo dnf install -y "${to_install[@]}"
            fi
        else
            echo "Error: no supported package manager found (need apt-get or dnf)"
            exit 1
        fi
    fi
}

cask_install() {
    if [[ $PLATFORM != "macos" ]]; then
        return
    fi
    local to_install=()
    for cask in "$@"; do
        if ! brew list --cask "$cask" &>/dev/null; then
            to_install+=("$cask")
        fi
    done
    if [[ ${#to_install[@]} -gt 0 ]]; then
        echo "brew install --cask ${to_install[*]}"
        brew install --cask "${to_install[@]}"
    fi
}

install_packages() {
    local pkg_file="$REPO_ROOT/$PLATFORM/$ROLE/packages.txt"
    local cask_file="$REPO_ROOT/$PLATFORM/$ROLE/casks.txt"

    if [[ -f "$pkg_file" ]]; then
        echo "Reading $PLATFORM/$ROLE/packages.txt"
        local pkgs=()
        while IFS= read -r line || [[ -n "$line" ]]; do
            line="${line%%#*}"       # strip comments
            line="${line// /}"       # strip whitespace
            [[ -z "$line" ]] && continue
            pkgs+=("$line")
        done < "$pkg_file"
        if [[ ${#pkgs[@]} -gt 0 ]]; then
            pkg_install "${pkgs[@]}"
        fi
    else
        echo "No packages.txt found for $PLATFORM/$ROLE, skipping formulae."
    fi

    if [[ -f "$cask_file" ]]; then
        echo "Reading $PLATFORM/$ROLE/casks.txt"
        local casks=()
        while IFS= read -r line || [[ -n "$line" ]]; do
            line="${line%%#*}"
            line="${line// /}"
            [[ -z "$line" ]] && continue
            casks+=("$line")
        done < "$cask_file"
        if [[ ${#casks[@]} -gt 0 ]]; then
            cask_install "${casks[@]}"
        fi
    fi
}

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

# --- Tmux config ---
install_tmux() {
    # Symlink .tmux.conf
    local candidates=(
        "$PLATFORM/$ROLE/.tmux.conf"
        "$PLATFORM/.tmux.conf"
        "shared/$ROLE/.tmux.conf"
        "shared/.tmux.conf"
    )

    local source=""
    for candidate in "${candidates[@]}"; do
        if [[ -f "$REPO_ROOT/$candidate" ]]; then
            source="$REPO_ROOT/$candidate"
            break
        fi
    done

    if [[ -z "$source" ]]; then
        echo "No .tmux.conf found, skipping."
        return
    fi

    local target="$HOME/.tmux.conf"
    if [[ -f "$target" && ! -L "$target" ]]; then
        local backup="$target.backup.$(date +%Y%m%d%H%M%S)"
        cp "$target" "$backup"
        echo "Backed up $target → $backup"
    fi
    ln -sf "$source" "$target"
    echo "Linked $target → $source"

    # Symlink .tmux/ helper scripts
    local source_dir
    source_dir="$(dirname "$source")/.tmux"
    if [[ -d "$source_dir" ]]; then
        mkdir -p "$HOME/.tmux"
        for script in "$source_dir"/*; do
            local name
            name="$(basename "$script")"
            ln -sf "$script" "$HOME/.tmux/$name"
            echo "Linked ~/.tmux/$name → $script"
        done
    fi
}

install_tmux

# --- Packages ---
install_packages

echo ""
echo "Done!"
