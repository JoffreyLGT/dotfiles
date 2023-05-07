# Joff's NeoVim config

## Install script

```shell
curl https://raw.githubusercontent.com/JoffreyLGT/dotfiles/main/install_joff_env.sh | /bin/bash && source .profile
```

## Requirements

### MacOS

```Bash
# Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
# Install NeoVim
brew install neovim
# Install ripgrep for <leader>ps command to work
brew install ripgrep
# Go to user's .config folder and clone repository
cd ~/.config && git@github.com:JoffreyLGT/nvim-config.git
```
