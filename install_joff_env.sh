#!/bin/bash

# Clone the bare repository from Github, clean local config and set alias
# NOTE: thanks to https://www.atlassian.com/git/tutorials/dotfiles
git clone --bare https://github.com/JoffreyLGT/dotfiles.git $HOME/.cfg
# Set config alias into .bashrc
alias config='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME' >> $HOME/.bashrc
source $HOME/.bashrc

#function config {
#   /usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME $@
#}
mkdir -p .config-backup
config checkout
if [ $? = 0 ]; then
  echo "Checked out config.";
  else
    echo "Backing up pre-existing dot files.";
    config checkout 2>&1 | egrep "\s+\." | awk {'print $1'} | xargs -I{} mv {} .config-backup/{}
fi;
config checkout
config config status.showUntrackedFiles no
