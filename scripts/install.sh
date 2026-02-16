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
is_pkg_installed() {
    if [[ $PLATFORM == "macos" ]]; then
        brew list --formula "$1" &>/dev/null
    elif command -v dpkg &>/dev/null; then
        dpkg -s "$1" &>/dev/null
    elif command -v rpm &>/dev/null; then
        rpm -q "$1" &>/dev/null
    fi
}

pkg_install() {
    local to_install=()
    for pkg in "$@"; do
        if is_pkg_installed "$pkg"; then
            echo "$pkg -> already installed"
        else
            echo "$pkg -> installing"
            to_install+=("$pkg")
        fi
    done
    if [[ ${#to_install[@]} -eq 0 ]]; then
        return
    fi
    if [[ $PLATFORM == "macos" ]]; then
        brew install "${to_install[@]}"
    elif command -v apt-get &>/dev/null; then
        sudo apt-get install -y "${to_install[@]}"
    elif command -v dnf &>/dev/null; then
        sudo dnf install -y "${to_install[@]}"
    else
        echo "Error: no supported package manager found (need apt-get or dnf)"
        exit 1
    fi
}

pkg_ask_install() {
    for pkg in "$@"; do
        if is_pkg_installed "$pkg"; then
            echo "$pkg -> already installed"
        else
            read -rp "Install $pkg? [y/N] " answer
            if [[ "${answer,,}" == "y" ]]; then
                pkg_install "$pkg"
            else
                echo "$pkg -> skipped"
            fi
        fi
    done
}

cask_install() {
    if [[ $PLATFORM != "macos" ]]; then
        return
    fi
    local to_install=()
    for cask in "$@"; do
        if brew list --cask "$cask" &>/dev/null; then
            echo "$cask -> already installed"
        else
            echo "$cask -> installing"
            to_install+=("$cask")
        fi
    done
    if [[ ${#to_install[@]} -gt 0 ]]; then
        brew install --cask "${to_install[@]}"
    fi
}

read_pkg_file() {
    local file="$1"
    local -n arr=$2
    while IFS= read -r line || [[ -n "$line" ]]; do
        line="${line%%#*}"       # strip comments
        line="${line// /}"       # strip whitespace
        [[ -z "$line" ]] && continue
        arr+=("$line")
    done < "$file"
}

install_packages() {
    local pkg_file="$REPO_ROOT/$PLATFORM/$ROLE/packages.txt"
    local ask_file="$REPO_ROOT/$PLATFORM/$ROLE/packages-ask.txt"
    local cask_file="$REPO_ROOT/$PLATFORM/$ROLE/casks.txt"

    if [[ -f "$pkg_file" ]]; then
        echo "Installing packages from $PLATFORM/$ROLE/packages.txt"
        local pkgs=()
        read_pkg_file "$pkg_file" pkgs
        if [[ ${#pkgs[@]} -gt 0 ]]; then
            pkg_install "${pkgs[@]}"
        fi
    else
        echo "No packages.txt found for $PLATFORM/$ROLE, skipping."
    fi

    if [[ -f "$ask_file" ]]; then
        echo ""
        echo "Optional packages from $PLATFORM/$ROLE/packages-ask.txt"
        local ask_pkgs=()
        read_pkg_file "$ask_file" ask_pkgs
        if [[ ${#ask_pkgs[@]} -gt 0 ]]; then
            pkg_ask_install "${ask_pkgs[@]}"
        fi
    fi

    if [[ -f "$cask_file" ]]; then
        echo "Installing casks from $PLATFORM/$ROLE/casks.txt"
        local casks=()
        read_pkg_file "$cask_file" casks
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
