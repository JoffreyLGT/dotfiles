#!/bin/bash

# This script is written to help setup a new machine effortlessly.
# It is written for openSUSE Tumbleweed with KDE Plasma and works for machine
# installation and WSL2.
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

step() { printf "\n%s==> %s%s\n" "$BOLD$BLUE" "$1" "$RESET"; }
info() { printf "    %s\n" "$1"; }
success() { printf "    %s\xe2\x9c\x93 %s%s\n" "$GREEN" "$1" "$RESET"; }
skip() { printf "    %s\xe2\x80\xa2 %s (already present, skipping)%s\n" "$YELLOW" "$1" "$RESET"; }

# ---------------------------------------------------------------------------
# Idempotency helpers — never re-download or re-install what already exists
# ---------------------------------------------------------------------------
command_exists() { command -v "$1" >/dev/null 2>&1; }
font_installed() { fc-list 2>/dev/null | grep -qi "$1"; }
flatpak_installed() { flatpak info "$1" >/dev/null 2>&1; }

# Tumbleweed ships several tools under versioned package names (python313-pip,
# python313-devel, python313-podman-compose, ...) that only expose the generic
# name as an RPM *capability*. Querying by capability with --whatprovides makes
# the check work for both real package names and those virtual ones.
rpm_installed() { rpm -q --whatprovides "$1" >/dev/null 2>&1; }

# Install any zypper packages that are not already present, in a single call.
install_zypper() {
  local pkg missing=()
  for pkg in "$@"; do
    if rpm_installed "$pkg"; then
      skip "$pkg"
    else
      missing+=("$pkg")
    fi
  done
  if [ ${#missing[@]} -gt 0 ]; then
    info "Installing: ${missing[*]}"
    sudo zypper --non-interactive install --auto-agree-with-licenses \
      "${missing[@]}" && success "${missing[*]} installed"
  fi
}

# Add an OBS (or third-party) repository only when its alias is not registered
# yet, then refresh it while auto-importing its signing key.
add_repo() {
  local url="$1" alias="$2" name="${3:-$2}"
  if zypper lr "$alias" >/dev/null 2>&1; then
    skip "repository $alias"
  else
    info "Adding the $name repository..."
    sudo zypper --non-interactive addrepo --refresh --name "$name" \
      "$url" "$alias" || return 1
  fi
  sudo zypper --non-interactive --gpg-auto-import-keys refresh "$alias"
}

# Install a Flathub application, pulling in flatpak and the remote when needed.
install_flatpak() {
  local app_id="$1"
  if ! command_exists flatpak; then
    info "Installing flatpak..."
    sudo zypper --non-interactive install flatpak || return 1
  fi
  # --if-not-exists makes this a no-op when the remote is already configured.
  sudo flatpak remote-add --if-not-exists flathub \
    https://dl.flathub.org/repo/flathub.flatpakrepo || return 1
  info "Installing $app_id from Flathub..."
  sudo flatpak install -y flathub "$app_id"
}

# Register Microsoft's azure-cli rpm repository and install the package.
# This follows the documented manual steps rather than the curl|bash one-liner
# so the package stays verified against a pinned signing key.
install_azure_cli() {
  info "Adding the Microsoft signing key..."
  sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc || return 1
  add_repo https://packages.microsoft.com/yumrepos/azure-cli azure-cli "Azure CLI" || return 1
  # --from pins the package to the Microsoft repository, which is what the
  # official openSUSE/SLES instructions do.
  sudo zypper --non-interactive install --auto-agree-with-licenses \
    --from azure-cli azure-cli
}

# Install the .NET SDK. Tumbleweed carries no dotnet-sdk package and
# packages.microsoft.com has no Tumbleweed repository, so use Microsoft's
# official installer, which drops a self-contained SDK in ~/.dotnet.
install_dotnet() {
  local channel="$1"
  if command_exists dotnet; then
    skip "dotnet"
    return 0
  fi
  info "Downloading the .NET installer..."
  curl -fsSL https://dot.net/v1/dotnet-install.sh -o /tmp/dotnet-install.sh || return 1
  bash /tmp/dotnet-install.sh --channel "$channel" --install-dir "$HOME/.dotnet" || return 1
  rm -f /tmp/dotnet-install.sh
  # ~/.dotnet is not on the PATH by default, and .bashrc is tracked in the
  # dotfiles repository, so publish it through profile.d instead of editing it.
  sudo tee /etc/profile.d/dotnet.sh >/dev/null <<'EOF'
export DOTNET_ROOT="$HOME/.dotnet"
export PATH="$DOTNET_ROOT:$DOTNET_ROOT/tools:$PATH"
EOF
  export DOTNET_ROOT="$HOME/.dotnet"
  export PATH="$DOTNET_ROOT:$DOTNET_ROOT/tools:$PATH"
}

# ---------------------------------------------------------------------------
# Refresh the package metadata once up front
# ---------------------------------------------------------------------------
step "Refreshing the zypper package metadata"
sudo zypper --non-interactive --gpg-auto-import-keys refresh

# ---------------------------------------------------------------------------
# Bootstrap tooling needed by the rest of the script
# ---------------------------------------------------------------------------
step "Installing bootstrap tools"
install_zypper git curl tar gzip

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
  [ -e .tmux.conf ] && cp .tmux.conf .config-backup && info "Backed up .tmux.conf"
  [ -e .bashrc ] && cp .bashrc .config-backup && info "Backed up .bashrc"
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
DOTFILES_SSH_URL="git@github.com:JoffreyLGT/dotfiles.git"
DOTFILES_HTTPS_URL="https://github.com/JoffreyLGT/dotfiles.git"
freshly_cloned=false
cloned_via_https=false
if [ ! -d "$HOME/.cfg" ]; then
  # Prefer SSH, but fall back to HTTPS when SSH access is not available
  # (e.g. no key configured yet). The remote is reset to SSH afterwards.
  info "Cloning dotfiles repository over SSH..."
  if git clone --bare "$DOTFILES_SSH_URL" "$HOME/.cfg"; then
    success "Cloned over SSH"
  else
    info "SSH clone failed — falling back to HTTPS..."
    git clone --bare "$DOTFILES_HTTPS_URL" "$HOME/.cfg"
    cloned_via_https=true
  fi
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

# If we had to fall back to HTTPS, switch the remote back to SSH so future
# fetches/pushes use the key-based URL.
if [ "$cloned_via_https" = true ]; then
  info "Cloned over HTTPS because SSH was unavailable."
  info "Resetting the dotfiles remote to SSH for future operations..."
  config remote remove origin 2>/dev/null
  config remote add origin "$DOTFILES_SSH_URL"
  success "Dotfiles remote set to SSH"
fi

# Set global git config
git config --global push.autoSetupRemote true
success "Dotfiles checked out"

# ---------------------------------------------------------------------------
# Core CLI tooling
# Tumbleweed ships everything below in the OSS repository, so there is no need
# for snap here — zypper plus Flathub covers the whole toolchain.
# Note: the binary is packaged as `fd` on openSUSE (Debian calls it fd-find).
# ---------------------------------------------------------------------------
step "Installing CLI tools from zypper"
install_zypper neovim tree curl wl-clipboard tmux ripgrep fd unzip direnv \
  lazygit fontconfig

# ---------------------------------------------------------------------------
# KDE Plasma tweaks
# Caps Lock is remapped to Ctrl through kxkbrc, the file Plasma's keyboard
# KCM writes to. Writing it directly keeps the change idempotent.
# ---------------------------------------------------------------------------
step "Configuring KDE Plasma"
kwrite_bin=""
for candidate in kwriteconfig6 kwriteconfig5; do
  command_exists "$candidate" && kwrite_bin="$candidate" && break
done
if [ -n "$kwrite_bin" ]; then
  info "Mapping Caps Lock to Ctrl..."
  "$kwrite_bin" --file kxkbrc --group Layout --key ResetOldOptions true
  "$kwrite_bin" --file kxkbrc --group Layout --key Options ctrl:nocaps
  # Apply immediately on X11; on Wayland the setting is picked up at next login.
  setxkbmap -option ctrl:nocaps 2>/dev/null
  success "Caps Lock mapped to Ctrl (log out and back in to apply on Wayland)"
else
  info "Skipped (no Plasma tools found, e.g. WSL2)"
fi

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
# Fonts
# ---------------------------------------------------------------------------
step "Installing fonts"
FONT_DIR="$HOME/.local/share/fonts/JetBrainsMono"
# Check both fontconfig and the install directory: fc-list may be unavailable
# (e.g. WSL2 without fontconfig), so an on-disk check keeps re-runs idempotent.
if font_installed "JetBrainsMono" || ls "$FONT_DIR"/*.ttf >/dev/null 2>&1; then
  skip "JetBrainsMono Nerd Font"
else
  info "Downloading and installing the font..."
  curl -L -o /tmp/JetBrainsMono.zip https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/JetBrainsMono.zip
  mkdir -p "$FONT_DIR"
  unzip -o /tmp/JetBrainsMono.zip -d "$FONT_DIR"
  fc-cache -f
  success "JetBrainsMono Nerd Font installed"
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
install_zypper gcc gcc-c++ make clang clang-devel
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
  curl -fsSL https://claude.ai/install.sh | bash
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
# The -default metapackages track whatever Node LTS Tumbleweed currently ships.
install_zypper nodejs-default npm-default

step "Installing Python and dev tools"
# These are capabilities provided by the current python3XX packages; zypper
# resolves them to the default interpreter. venv ships with python3 itself.
install_zypper python3 python3-pip python3-devel

step "Installing Elixir"
if ! command_exists elixir; then
  info "Downloading the Elixir installer..."
  curl -fsSO https://elixir-lang.org/install.sh
  sh install.sh elixir@1.20.2 otp@28.4
  # The installer is downloaded into $HOME (cwd); clean it up so it does not
  # linger in the home folder.
  rm -f install.sh
  success "Elixir installed"
else
  skip "Elixir"
fi

step "Installing Ruby"
# rubygems is bundled with the ruby package on openSUSE.
install_zypper ruby ruby-devel

step "Installing tmuxinator"
if ! command_exists tmuxinator; then
  info "Installing the tmuxinator gem..."
  # Installed system-wide so the binary lands in /usr/bin: a --user-install
  # would land in ~/.local/share/gem/ruby/<version>/bin, and .bashrc pins a
  # single Ruby version there that Tumbleweed rolls forward.
  # --no-format-executable overrides /etc/gemrc, which would otherwise name the
  # binary after the interpreter (/usr/bin/tmuxinator.ruby4.0) and leave the
  # plain `tmuxinator` off PATH. RPM gems get a plain-name update-alternatives
  # link; a direct `gem install` does not.
  sudo gem install --no-format-executable tmuxinator
  success "tmuxinator installed"
else
  skip "tmuxinator"
fi
if [ ! -f /etc/bash_completion.d/tmuxinator.bash ]; then
  info "Installing tmuxinator bash completion..."
  sudo mkdir -p /etc/bash_completion.d
  sudo curl -L https://raw.githubusercontent.com/tmuxinator/tmuxinator/master/completion/tmuxinator.bash \
    -o /etc/bash_completion.d/tmuxinator.bash
else
  skip "tmuxinator bash completion"
fi

step "Installing .NET SDK 10"
install_dotnet 10.0

# ---------------------------------------------------------------------------
# Optional extra applications
# Add new apps as "Display name|check command|install command" entries.
# GUI apps come from Flathub; Ghostty is packaged in the Tumbleweed OSS repo.
# ---------------------------------------------------------------------------
step "Optional extra applications"
# GUI apps glitch under WSLg, so the extras are only proposed on native installs.
if grep -qi microsoft /proc/version; then
  info "Skipped (WSL detected)"
else
  EXTRA_APPS=(
    "Obsidian|md.obsidian.Obsidian|install_flatpak md.obsidian.Obsidian"
    "Ghostty|ghostty|install_zypper ghostty"
    "Bruno|com.usebruno.Bruno|install_flatpak com.usebruno.Bruno"
    "Podman|podman-compose|install_zypper podman podman-compose"
    "Podman Desktop|io.podman_desktop.PodmanDesktop|install_flatpak io.podman_desktop.PodmanDesktop"
    "Azure CLI|az|install_azure_cli"
  )

  for entry in "${EXTRA_APPS[@]}"; do
    IFS='|' read -r name check install <<<"$entry"
    if command_exists "$check" || rpm_installed "$check" || flatpak_installed "$check"; then
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
fi

# ---------------------------------------------------------------------------
# Podman socket
# Podman Desktop talks to the Podman CLI through the user socket, so enable it
# whenever Podman is present. `enable --now` is idempotent, so re-runs are safe.
# ---------------------------------------------------------------------------
if command_exists podman; then
  step "Enabling the Podman user socket"
  if systemctl --user enable --now podman.socket 2>/dev/null; then
    success "podman.socket enabled"
  else
    info "Skipped (no systemd user session, e.g. WSL2 without systemd)"
  fi
fi

step "All done! Your environment is ready."
info "Restart your shell (or run 'exec \$SHELL') to pick up every change."
