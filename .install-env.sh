#!/bin/bash

cd ~

# Save the files that will be erased if they exists
mkdir -p .config-backup
cp -R .config/nvim .config-backup
cp .tmux.conf .config-backup
cp .bashrc .config-backup

# Clone the bare repository from Github, clean local config and set alias
# NOTE: thanks to https://www.atlassian.com/git/tutorials/dotfiles
git clone --bare git@github.com:JoffreyLGT/dotfiles.git $HOME/.cfg

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
sudo apt install -y gnome-tweaks curl wl-clipboard tmux ripgrep
# Set Capslock as Ctrl
gsettings set org.gnome.desktop.input-sources xkb-options "['ctrl:nocaps']"

# Install tmux packages manager (tpm)
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# Install JetBrainsMono Nerd Font and set it as default font for gnome terminal
# Download, unzip and install the font
curl -L -o /tmp/JetBrainsMono.zip https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/JetBrainsMono.zip
mkdir -p ~/.local/share/fonts/JetBrainsMono
unzip /tmp/JetBrainsMono.zip -d ~/.local/share/fonts/JetBrainsMono
fc-cache -fv

# Install lazyvim
git clone https://github.com/LazyVim/starter ~/.config/nvim
rm -rf ~/.config/nvim/.git

# Install the C toolchain used by Rust
sudo apt install clang libclang-dev
# Install Rust to be able to install the latest version of treesitter
curl https://sh.rustup.rs -sSf | sh
# Install treesitter
cargo install --locked tree-sitter-cli

# Install claude code
sudo install -d -m 0755 /etc/apt/keyrings
sudo curl -fsSL https://downloads.claude.ai/keys/claude-code.asc \
  -o /etc/apt/keyrings/claude-code.asc
echo "deb [signed-by=/etc/apt/keyrings/claude-code.asc] https://downloads.claude.ai/claude-code/apt/stable stable main" |
  sudo tee /etc/apt/sources.list.d/claude-code.list
sudo apt update
sudo apt install claude-code

# Install starship shell
curl -sS https://starship.rs/install.sh | sh
