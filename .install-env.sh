#!/bin/bash

# This script is written to help setup a new machine effortlessly.
# It is written for Ubuntu and work for machine installation and WSL2.

# Set the current directory to the user's home
cd ~

# Helper functions to make the script safe to re-run on an already-configured machine
command_exists() { command -v "$1" >/dev/null 2>&1; }
font_installed() { fc-list 2>/dev/null | grep -qi "$1"; }

# Save the files that will be erased if they exists
mkdir -p .config-backup
[ -e .config/nvim ] && cp -R .config/nvim .config-backup
[ -e .tmux.conf ] && cp .tmux.conf .config-backup
[ -e .bashrc ] && cp .bashrc .config-backup

# Clone the bare repository from Github, clean local config and set alias
# NOTE: thanks to https://www.atlassian.com/git/tutorials/dotfiles
if [ ! -d "$HOME/.cfg" ]; then
  git clone --bare git@github.com:JoffreyLGT/dotfiles.git $HOME/.cfg
fi

function config {
  /usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME $@
}

config checkout --force
config config status.showUntrackedFiles no

# Set global git config
git config --global push.autoSetupRemote true

# Install packages from snap store
sudo snap install nvim --classic
sudo snap install tree lazygit direnv

# Install packages from apt
sudo apt install -y gnome-tweaks curl wl-clipboard tmux ripgrep fd-find unzip
# Set Capslock as Ctrl
gsettings set org.gnome.desktop.input-sources xkb-options "['ctrl:nocaps']"

# Install tmux packages manager (tpm)
if [ ! -d ~/.tmux/plugins/tpm ]; then
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

# Install JetBrainsMono Nerd Font and set it as default font for gnome terminal
# Download, unzip and install the font
if ! font_installed "JetBrainsMono"; then
  curl -L -o /tmp/JetBrainsMono.zip https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/JetBrainsMono.zip
  mkdir -p ~/.local/share/fonts/JetBrainsMono
  unzip /tmp/JetBrainsMono.zip -d ~/.local/share/fonts/JetBrainsMono
  fc-cache -fv
fi

# Install lazyvim
if [ ! -d ~/.config/nvim ]; then
  git clone https://github.com/LazyVim/starter ~/.config/nvim
  rm -rf ~/.config/nvim/.git
fi

# Install the C toolchain used by Rust
sudo apt install clang libclang-dev
# Install Rust to be able to install the latest version of treesitter
if ! command_exists rustc && ! command_exists cargo; then
  curl https://sh.rustup.rs -sSf | sh
fi
# Make the freshly installed toolchain available in the current shell
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
# Install treesitter
if ! command_exists tree-sitter; then
  cargo install --locked tree-sitter-cli
fi

# Install claude code
if ! command_exists claude; then
  sudo install -d -m 0755 /etc/apt/keyrings
  sudo curl -fsSL https://downloads.claude.ai/keys/claude-code.asc \
    -o /etc/apt/keyrings/claude-code.asc
  echo "deb [signed-by=/etc/apt/keyrings/claude-code.asc] https://downloads.claude.ai/claude-code/apt/stable stable main" |
    sudo tee /etc/apt/sources.list.d/claude-code.list
  sudo apt update
  sudo apt install claude-code
fi

# Install starship shell
if ! command_exists starship; then
  curl -sS https://starship.rs/install.sh | sh
fi

# Install NPM
sudo apt install -y npm

# Install Python and dev tools
sudo apt install -y python3 python3-pip python3-venv python3-dev

# Install Elixir
if ! command_exists elixir; then
  curl -fsSO https://elixir-lang.org/install.sh
  sh install.sh elixir@1.20.2 otp@28.4
fi

echo "Install Ruby"
sudo apt install -y ruby-full
echo "Install tmuxinator"
gem install tmuxinator
sudo curl -L https://raw.githubusercontent.com/tmuxinator/tmuxinator/master/completion/tmuxinator.bash -o /etc/bash_completion.d/tmuxinator.bash

echo "Install dotnet 10"
sudo apt install -y dotnet-sdk-10.0
