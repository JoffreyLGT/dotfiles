#!/bin/bash

# This script is written to help setup a new machine effortlessly.
# It is written for Ubuntu and works for machine installation and WSL2.
#
# It is safe to re-run: every step checks whether the software is already
# present before downloading or installing anything.

set -o pipefail

# Set the current directory to the user's home
cd ~ || exit 1

# ---------------------------------------------------------------------------
# Logging helpers — give the user clear feedback about what is happening
# ---------------------------------------------------------------------------
if [ -t 1 ]; then
  BOLD="$(tput bold 2>/dev/null)"
  BLUE="$(tput setaf 4 2>/dev/null)"
  GREEN="$(tput setaf 2 2>/dev/null)"
  YELLOW="$(tput setaf 3 2>/dev/null)"
  RESET="$(tput sgr0 2>/dev/null)"
else
  BOLD="" BLUE="" GREEN="" YELLOW="" RESET=""
fi

step()    { printf "\n%s==> %s%s\n" "$BOLD$BLUE" "$1" "$RESET"; }
info()    { printf "    %s\n" "$1"; }
success() { printf "    %s\xe2\x9c\x93 %s%s\n" "$GREEN" "$1" "$RESET"; }
skip()    { printf "    %s\xe2\x80\xa2 %s (already present, skipping)%s\n" "$YELLOW" "$1" "$RESET"; }

# ---------------------------------------------------------------------------
# Idempotency helpers — never re-download or re-install what already exists
# ---------------------------------------------------------------------------
command_exists() { command -v "$1" >/dev/null 2>&1; }
font_installed() { fc-list 2>/dev/null | grep -qi "$1"; }
snap_installed() { snap list "$1" >/dev/null 2>&1; }
apt_installed()  { dpkg -s "$1" >/dev/null 2>&1; }

# Install a snap package only if it is missing.
install_snap() {
  local pkg="$1"; shift
  if snap_installed "$pkg"; then
    skip "$pkg"
  else
    info "Installing $pkg from the snap store..."
    sudo snap install "$pkg" "$@" && success "$pkg installed"
  fi
}

# Install any apt packages that are not already present, in a single call.
install_apt() {
  local pkg missing=()
  for pkg in "$@"; do
    if apt_installed "$pkg"; then
      skip "$pkg"
    else
      missing+=("$pkg")
    fi
  done
  if [ ${#missing[@]} -gt 0 ]; then
    info "Installing: ${missing[*]}"
    sudo apt install -y "${missing[@]}" && success "${missing[*]} installed"
  fi
}

# ---------------------------------------------------------------------------
# Refresh the package index once up front
# ---------------------------------------------------------------------------
step "Refreshing the apt package index"
sudo apt update

# ---------------------------------------------------------------------------
# Back up config files that the dotfiles checkout would overwrite
# Only meaningful on the first run, since the repository is cloned once and
# the checkout only overwrites files then — so ask before backing up.
# ---------------------------------------------------------------------------
step "Backing up existing config files"
if [ -t 0 ]; then
  read -rp "    Back up existing config files to ~/.config-backup? [y/N] " backup_answer
else
  backup_answer="n"
fi
case "$backup_answer" in
  [yY]*)
    mkdir -p .config-backup
    [ -e .config/nvim ] && cp -R .config/nvim .config-backup && info "Backed up .config/nvim"
    [ -e .tmux.conf ]   && cp .tmux.conf .config-backup    && info "Backed up .tmux.conf"
    [ -e .bashrc ]      && cp .bashrc .config-backup       && info "Backed up .bashrc"
    success "Backups stored in ~/.config-backup"
    ;;
  *)
    info "Skipping config backup"
    ;;
esac

# ---------------------------------------------------------------------------
# Clone the bare dotfiles repository, clean local config and set alias
# NOTE: thanks to https://www.atlassian.com/git/tutorials/dotfiles
# ---------------------------------------------------------------------------
step "Setting up dotfiles"
freshly_cloned=false
if [ ! -d "$HOME/.cfg" ]; then
  info "Cloning dotfiles repository..."
  git clone --bare git@github.com:JoffreyLGT/dotfiles.git "$HOME/.cfg"
  freshly_cloned=true
else
  skip "dotfiles repository"
fi

function config {
  /usr/bin/git --git-dir="$HOME/.cfg/" --work-tree="$HOME" "$@"
}

# On a fresh clone $HOME already holds files the repo tracks (.bashrc, etc.),
# so --force is needed to overwrite them. On re-runs, use a plain checkout so
# uncommitted local edits to tracked dotfiles are never silently discarded.
if [ "$freshly_cloned" = true ]; then
  config checkout --force
else
  config checkout
fi
config config status.showUntrackedFiles no

# Set global git config
git config --global push.autoSetupRemote true
success "Dotfiles checked out"

# ---------------------------------------------------------------------------
# Core CLI tooling
# ---------------------------------------------------------------------------
step "Installing CLI tools from the snap store"
install_snap nvim --classic
install_snap tree
install_snap lazygit
install_snap direnv

step "Installing CLI tools from apt"
install_apt gnome-tweaks curl wl-clipboard tmux ripgrep fd-find unzip

# Set Capslock as Ctrl
info "Mapping Caps Lock to Ctrl..."
gsettings set org.gnome.desktop.input-sources xkb-options "['ctrl:nocaps']" 2>/dev/null \
  && success "Caps Lock mapped to Ctrl" \
  || info "Skipped (no GNOME session, e.g. WSL2)"

# ---------------------------------------------------------------------------
# tmux plugin manager (tpm)
# ---------------------------------------------------------------------------
step "Installing tmux plugin manager (tpm)"
if [ ! -d ~/.tmux/plugins/tpm ]; then
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
  success "tpm installed"
else
  skip "tpm"
fi

# ---------------------------------------------------------------------------
# JetBrainsMono Nerd Font
# ---------------------------------------------------------------------------
step "Installing JetBrainsMono Nerd Font"
if ! font_installed "JetBrainsMono"; then
  info "Downloading and installing the font..."
  curl -L -o /tmp/JetBrainsMono.zip https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/JetBrainsMono.zip
  mkdir -p ~/.local/share/fonts/JetBrainsMono
  unzip -o /tmp/JetBrainsMono.zip -d ~/.local/share/fonts/JetBrainsMono
  fc-cache -f
  success "JetBrainsMono Nerd Font installed"
else
  skip "JetBrainsMono Nerd Font"
fi

# ---------------------------------------------------------------------------
# LazyVim
# ---------------------------------------------------------------------------
step "Installing LazyVim"
if [ ! -d ~/.config/nvim ]; then
  git clone https://github.com/LazyVim/starter ~/.config/nvim
  rm -rf ~/.config/nvim/.git
  success "LazyVim installed"
else
  skip "LazyVim"
fi

# ---------------------------------------------------------------------------
# Rust toolchain + tree-sitter (used to build the latest treesitter parsers)
# ---------------------------------------------------------------------------
step "Installing the Rust toolchain"
# Install the C toolchain used by Rust
install_apt clang libclang-dev
if ! command_exists rustc && ! command_exists cargo; then
  info "Installing Rust via rustup (non-interactive)..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  success "Rust installed"
else
  skip "Rust"
fi
# Make the freshly installed toolchain available in the current shell
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

step "Installing tree-sitter CLI"
if ! command_exists tree-sitter; then
  info "Building tree-sitter-cli with cargo (this can take a while)..."
  cargo install --locked tree-sitter-cli
  success "tree-sitter installed"
else
  skip "tree-sitter"
fi

# ---------------------------------------------------------------------------
# Claude Code
# ---------------------------------------------------------------------------
step "Installing Claude Code"
if ! command_exists claude; then
  info "Adding the Claude Code apt repository..."
  sudo install -d -m 0755 /etc/apt/keyrings
  sudo curl -fsSL https://downloads.claude.ai/keys/claude-code.asc \
    -o /etc/apt/keyrings/claude-code.asc
  echo "deb [signed-by=/etc/apt/keyrings/claude-code.asc] https://downloads.claude.ai/claude-code/apt/stable stable main" |
    sudo tee /etc/apt/sources.list.d/claude-code.list
  sudo apt update
  install_apt claude-code
else
  skip "Claude Code"
fi

# ---------------------------------------------------------------------------
# Starship prompt
# ---------------------------------------------------------------------------
step "Installing the Starship prompt"
if ! command_exists starship; then
  info "Downloading and running the Starship installer (non-interactive)..."
  curl -sS https://starship.rs/install.sh | sh -s -- --yes
  success "Starship installed"
else
  skip "Starship"
fi

# ---------------------------------------------------------------------------
# Language runtimes and dev tools
# ---------------------------------------------------------------------------
step "Installing Node.js / npm"
install_apt npm

step "Installing Python and dev tools"
install_apt python3 python3-pip python3-venv python3-dev

step "Installing Elixir"
if ! command_exists elixir; then
  info "Downloading the Elixir installer..."
  curl -fsSO https://elixir-lang.org/install.sh
  sh install.sh elixir@1.20.2 otp@28.4
  success "Elixir installed"
else
  skip "Elixir"
fi

step "Installing Ruby"
install_apt ruby-full

step "Installing tmuxinator"
if ! command_exists tmuxinator; then
  info "Installing the tmuxinator gem..."
  gem install tmuxinator
  success "tmuxinator installed"
else
  skip "tmuxinator"
fi
if [ ! -f /etc/bash_completion.d/tmuxinator.bash ]; then
  info "Installing tmuxinator bash completion..."
  sudo curl -L https://raw.githubusercontent.com/tmuxinator/tmuxinator/master/completion/tmuxinator.bash \
    -o /etc/bash_completion.d/tmuxinator.bash
else
  skip "tmuxinator bash completion"
fi

step "Installing .NET SDK 10"
install_apt dotnet-sdk-10.0

# ---------------------------------------------------------------------------
# Optional extra applications
# Add new apps as "Display name|check command|install command" entries.
# ---------------------------------------------------------------------------
step "Optional extra applications"
EXTRA_APPS=(
  "Obsidian|obsidian|sudo snap install obsidian --classic"
  "Ghostty|ghostty|sudo snap install ghostty --classic" # community-maintained snap
)

for entry in "${EXTRA_APPS[@]}"; do
  IFS='|' read -r name check install <<<"$entry"
  if command_exists "$check" || snap_installed "$check"; then
    skip "$name"
    continue
  fi
  if [ -t 0 ]; then
    read -rp "    Install $name? [y/N] " answer
  else
    answer="n"
  fi
  case "$answer" in
    [yY]*)
      info "Installing $name..."
      eval "$install" && success "$name installed"
      ;;
    *)
      info "Skipping $name"
      ;;
  esac
done

step "All done! Your environment is ready."
info "Restart your shell (or run 'exec \$SHELL') to pick up every change."
