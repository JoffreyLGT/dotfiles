#!/bin/bash

# Save the files that will be erased if they exists
mkdir -p .config-backup
cp -R .config/nvim .config-backup
cp .tmux.conf .config-backup

# Clone the bare repository from Github, clean local config and set alias
# NOTE: thanks to https://www.atlassian.com/git/tutorials/dotfiles
git clone --bare https://github.com/JoffreyLGT/dotfiles.git $HOME/.cfg

function config {
   /usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME $@
}

config checkout --force
config config status.showUntrackedFiles no

# Set config alias into .bashrc
echo 'alias config="/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME' >> $HOME/Workspace/bash/testfile

# Install Homebrew
NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
(echo; echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"') >> $HOME/.profile
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# Install Neovim and ripgrep
brew install neovim ripgrep gnu-sed tmux tmuxinator direnv lazygit tree

