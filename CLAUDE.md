# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

Personal dotfiles and system setup repo. One install script configures a machine based on its **platform** (`macos`, `linux`) and **role** (`client`, `server`).

## Running the Install Script

```bash
./scripts/install.sh
```

Prompts for role (client/server), auto-detects platform, then:
1. Writes `~/.gitconfig` with layered includes
2. Symlinks `~/.tmux.conf` (and helper scripts from `.tmux/`)
3. Installs packages from text-file lists

There are no tests, linters, or build steps.

## Architecture

### Directory Convention

```
{platform}/{role}/   — platform-and-role-specific files
{platform}/          — platform-wide files (any role)
shared/{role}/       — cross-platform, role-specific files
shared/              — cross-platform defaults
```

**Dotfiles** (`.gitconfig`, `.tmux.conf`) use layered merging: the install script searches all four levels (shared → shared/$ROLE → $PLATFORM → $PLATFORM/$ROLE) and includes/symlinks whichever exist. Most specific wins or all get included (git uses `[include]`; tmux uses first-match).

**Package lists** are flat — no layering. Each `{platform}/{role}/` has self-contained `.txt` files:
- `packages.txt` — CLI packages (brew formulae / apt / dnf)
- `casks.txt` — GUI apps (macOS only, brew casks)

Format: one package per line, `#` comments allowed, blank lines ignored.

### Package Helpers

`pkg_install` and `cask_install` in `install.sh` are idempotent — they check whether each package is already installed before calling the package manager. Supported: `brew` (macOS), `apt-get` and `dnf` (Linux).

## Current Targets

- **macOS client** — full package list + casks
- **Linux client** — CLI tools only (uses `fd-find` instead of `fd`)
- **Linux server** — minimal subset of CLI tools
