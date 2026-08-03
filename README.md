# Joff's dotfiles

## Install script

Pick the script matching your distribution.

### Ubuntu (and WSL2)

```shell
curl https://raw.githubusercontent.com/JoffreyLGT/dotfiles/refs/heads/main/.install-env.sh | /bin/bash
```

### Fedora KDE

```shell
curl https://raw.githubusercontent.com/JoffreyLGT/dotfiles/refs/heads/main/.install-env-fedora.sh | /bin/bash
```

### openSUSE Tumbleweed (KDE Plasma)

```shell
curl https://raw.githubusercontent.com/JoffreyLGT/dotfiles/refs/heads/main/.install-env-opensuse.sh | /bin/bash
```

Piping into `bash` leaves the scripts without a TTY on stdin, so the config
backup and the optional extra applications are skipped automatically. To get
those prompts, download and run the script instead:

```shell
curl -fsSLO https://raw.githubusercontent.com/JoffreyLGT/dotfiles/refs/heads/main/.install-env-opensuse.sh
bash .install-env-opensuse.sh
```
