```
 _____ _                       ____ _____
|_   _| |__   __ _ _ __   __ _|  _ \__  /
  | | | '_ \ / _` | '_ \ / _` | | | |/ /
  | | | | | | (_| | | | | (_| | |_| / /_
  |_| |_| |_|\__,_|_| |_|\__, |____/____|
                         |___/
```

Personal cross-shell terminal setup (zsh today, bash planned) — a minimal, fast
replacement for Oh My Zsh, managed with the built-in `dz` CLI.

## Install (new machine)

One line — clone, install, and start a fresh shell:

```zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/thangit93/thangdz-term/main/tools/install.sh)"
```

Custom install location (default `~/Projects/thangdz-term`):

```zsh
THANGDZ_DIR=~/somewhere sh -c "$(curl -fsSL https://raw.githubusercontent.com/thangit93/thangdz-term/main/tools/install.sh)"
```

Or manually:

```zsh
git clone https://github.com/thangit93/thangdz-term ~/Projects/thangdz-term
cd ~/Projects/thangdz-term && ./install.sh
```

`install.sh` backs up the old `.zshrc` to `~/.zshrc.pre-thangdz-term.<timestamp>`
and symlinks `~/.zshrc` → `repo/zshrc`. From then on, edit everything inside
the repo and let git track it all.

## Structure

```
thangdz-term/
├── tools/
│   └── install.sh    # remote one-line installer (curl | sh)
├── install.sh        # local install: back up old .zshrc + symlink
├── zshrc             # main file (symlinked to ~/.zshrc)
├── init.zsh          # loader: lib → aliases → plugins → theme
├── lib/              # core settings
│   ├── options.zsh       # shell options (auto_cd, ...)
│   ├── history.zsh       # command history
│   ├── completion.zsh    # tab completion
│   ├── key-bindings.zsh  # key bindings
│   └── dz.zsh            # the dz CLI
├── aliases/          # aliases by group, auto-loaded
│   ├── general.zsh
│   ├── git.zsh
│   └── macos.zsh
├── plugins/          # vendored plugins (MIT licenses kept)
│   ├── zsh-autosuggestions
│   └── zsh-syntax-highlighting
└── themes/
    └── default.zsh   # prompt: ➜ dir (branch) ✗
```

## The dz CLI

| Command     | Description                                        |
|-------------|----------------------------------------------------|
| `dz update` | `git pull` the latest config, reload the shell     |
| `dz reload` | restart the shell (`exec zsh`)                     |
| `dz doctor` | health check: symlink, plugins, theme, remote      |
| `dz path`   | print the repo directory                           |
| `dz logo`   | print the ThangDZ ASCII logo, or render custom text |
| `dz help`   | show help                                          |

## Customizing

- **Change theme**: create `themes/<name>.zsh`, set `ZSH_THEME` in `zshrc`
- **Add plugin**: `git clone <url> plugins/<name>`, then add `<name>` to
  `plugins=(...)` in `zshrc` (the loader accepts both `<name>.plugin.zsh` and
  `<name>.zsh`, oh-my-zsh style)
- **Add aliases**: drop a file in `aliases/<group>.zsh` — loaded automatically
- **Reload**: run `reload`

## Backups from the omz removal (2026-08-21)

- `~/.zshrc.omz-backup-20260821` — the old omz `.zshrc`
- `~/omz-custom-backup-20260821.tar.gz` — the whole old `~/.oh-my-zsh/custom`

To reinstall oh-my-zsh:
`sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"`
