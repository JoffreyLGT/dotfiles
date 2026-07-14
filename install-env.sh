#!/bin/bash

cd ~

# Save the files that will be erased if they exists
mkdir -p .config-backup
cp -R .config/nvim .config-backup
cp .tmux.conf .config-backup
cp .bashrc .config-backup

# Clone the bare repository from Github, clean local config and set alias
# NOTE: thanks to https://www.atlassian.com/git/tutorials/dotfiles
git clone --bare https://github.com/JoffreyLGT/dotfiles.git $HOME/.cfg

function config {
  /usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME $@
}

config checkout --force
config config status.showUntrackedFiles no

# Install packages from snap store
sudo snap install nvim --classic
sudo snap install tree lazygit direnv

# Install packages from apt
sudo apt install -y gnome-tweaks curl wl-clipboard tmux
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
