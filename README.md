# Joff's dotfiles

## Install script

The script targets Kubuntu (KDE Plasma) and works for a machine install as
well as WSL2.

```shell
curl https://raw.githubusercontent.com/JoffreyLGT/dotfiles/refs/heads/main/.install-env.sh | /bin/bash
```

Piping into `bash` leaves the script without a TTY on stdin, so the config
backup and the optional extra applications are skipped automatically. To get
those prompts, download and run the script instead:

```shell
curl -fsSLO https://raw.githubusercontent.com/JoffreyLGT/dotfiles/refs/heads/main/.install-env.sh
bash .install-env.sh
```

## KDE Plasma

The repository syncs the keyboard layout (`.config/kxkbrc`, alongside
`.XCompose`) and the global shortcuts (`.config/kglobalshortcutsrc`). Both are
read at session start, so log out and back in after pulling them.

Nothing else from KDE is tracked. Panels, virtual desktops, window rules and
themes are bound to per-machine state — monitor UUIDs, EDID hashes, screen
indices, per-resolution icon geometry — so they are configured per machine.
