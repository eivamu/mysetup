# Shared shell aliases (sourced by ~/.bashrc on Debian/Ubuntu).
#
# Debian/Ubuntu ship `bat` as `batcat` and `fd-find` as `fdfind` to avoid
# binary-name clashes with other packages. Restore the conventional names —
# but only when the renamed binary is actually present, so this stays a no-op
# on macOS (where the real `bat`/`fd` binaries are installed via Homebrew).
command -v batcat >/dev/null 2>&1 && alias bat='batcat'
command -v fdfind >/dev/null 2>&1 && alias fd='fdfind'
