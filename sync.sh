#!/usr/bin/env bash
#
# Sync live dotfiles into this repo.
#
# For .zshrc: strips everything below the "--- fzf ---" block (local
# aliases, PATH tweaks, secrets/tokens that vary per machine).
#
# For all other files: straight copy from the live location.

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

# ── zshrc (trim machine-local tail) ──────────────────────────────────
echo "syncing zshrc …"
# Keep everything up to and including the fzf block (the blank line after it).
awk '
  { print }
  /^\[ -f ~\/\.fzf\.zsh \]/ { found=1 }
  found && /^$/ { exit }
' ~/.zshrc > "$DOTFILES_DIR/zsh/zshrc"

# ── tmux ──────────────────────────────────────────────────────────────
echo "syncing tmux.conf …"
cp ~/.tmux.conf "$DOTFILES_DIR/tmux/tmux.conf"

# ── alacritty ─────────────────────────────────────────────────────────
echo "syncing alacritty.toml …"
cp ~/.config/alacritty/alacritty.toml "$DOTFILES_DIR/alacritty/alacritty.toml"

# ── nvim (whole directory, skip lazy-lock.json which churns) ─────────
echo "syncing nvim …"
rsync -a --delete \
  --exclude 'lazy-lock.json' \
  ~/.config/nvim/ "$DOTFILES_DIR/nvim/"

# ── p10k ──────────────────────────────────────────────────────────────
echo "syncing .p10k.zsh …"
cp ~/.p10k.zsh "$DOTFILES_DIR/.p10k.zsh"

echo "done."
