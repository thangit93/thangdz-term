```
 _____ _                       ____ _____
|_   _| |__   __ _ _ __   __ _|  _ \__  /
  | | | '_ \ / _` | '_ \ / _` | | | |/ /
  | | | | | | (_| | | | | (_| | |_| / /_
  |_| |_| |_|\__,_|_| |_|\__, |____/____|
                         |___/
```

Personal cross-shell terminal setup for **zsh & bash** on **macOS & Linux** —
minimal, fast, managed with the built-in `dz` CLI.

## Install — zsh

### macOS

zsh is already the default shell. You just need `git` (installed with Xcode
Command Line Tools). Paste this one line in a terminal:

```zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/thangit93/thangdz-term/main/tools/install.sh)"
```

### Linux (Debian / Ubuntu)

```zsh
# 1. Install prerequisites
sudo apt update && sudo apt install -y git curl zsh

# 2. One-line install
sh -c "$(curl -fsSL https://raw.githubusercontent.com/thangit93/thangdz-term/main/tools/install.sh)"

# 3. (Optional) make zsh your default login shell
chsh -s "$(command -v zsh)"
```

### Linux (Fedora)

```zsh
sudo dnf install -y git curl zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/thangit93/thangdz-term/main/tools/install.sh)"
chsh -s "$(command -v zsh)"   # optional
```

## Install — bash

Same one-liner — just run it **from a bash shell** (the installer sets up
whichever shell you run it in):

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/thangit93/thangdz-term/main/tools/install.sh)"
```

Or manually:

```bash
git clone https://github.com/thangit93/thangdz-term ~/.thangdz-term
cd ~/.thangdz-term
./install.sh bash      # or: ./install.sh zsh | ./install.sh all
exec bash
```

Cloned it somewhere else? `./install.sh` moves the repo to `~/.thangdz-term`
automatically before symlinking, so `$THANGDZ` always resolves to the same
place regardless of where you ran `git clone`.

Custom install location (default `~/.thangdz-term`):

```zsh
THANGDZ_DIR=~/somewhere sh -c "$(curl -fsSL https://raw.githubusercontent.com/thangit93/thangdz-term/main/tools/install.sh)"
```

What install does, per shell: it backs up the old `~/.zshrc` / `~/.bashrc` to
`*.pre-thangdz-term.<timestamp>`, symlinks them into the repo, and for bash it
makes sure `~/.bash_profile` sources `~/.bashrc` (login shells read the
profile, not the rc). From then on, edit everything inside the repo and let
git track it all.

## Structure

```
thangdz-term/
├── tools/
│   └── install.sh        # remote one-line installer (curl | sh)
├── install.sh            # local install: [zsh|bash|all]
├── zshrc                 # zsh main file (symlinked to ~/.zshrc)
├── bashrc                # bash main file (symlinked to ~/.bashrc)
├── init.zsh              # zsh loader: lib → aliases → plugins → theme
├── init.bash             # bash loader: lib → aliases → theme
├── lib/                  # per-shell core settings
│   ├── options.zsh / options.bash
│   ├── history.zsh / history.bash
│   ├── completion.zsh / completion.bash
│   ├── key-bindings.zsh / key-bindings.bash
│   ├── greeting.zsh / greeting.bash     # logo on shell start
│   ├── dz.zsh / dz.bash                 # the dz CLI
│   └── logo.txt                         # bundled ThangDZ ASCII art
├── aliases/              # shared aliases (both shells), auto-loaded
│   ├── general.zsh
│   ├── git.zsh
│   └── macos.zsh
├── plugins/              # vendored zsh plugins (MIT licenses kept)
│   ├── zsh-autosuggestions
│   └── zsh-syntax-highlighting
├── games/                # terminal mini-games (dz games / dz game <n>)
│   ├── 01-guess-number.sh
│   ├── 02-catch-ball.sh  # real-time, keyboard-driven
│   ├── 03-breakout.sh    # real-time, keyboard-driven
│   └── 04-snake.sh       # real-time, walls wrap around
└── themes/
    ├── default.zsh       # prompt: ➜ dir (branch) ✗
    └── default.bash
```

## Shell support

| Feature                                   | zsh | bash |
|-------------------------------------------|-----|------|
| Shared aliases (general / git / macos)    | ✓   | ✓    |
| History, completion, key bindings          | ✓   | ✓    |
| Git-branch prompt theme                   | ✓   | ✓    |
| `dz` CLI (`update`, `doctor`, `logo`, …)  | ✓   | ✓    |
| Autosuggestions & syntax highlighting     | ✓   | —    |

> `zsh-autosuggestions` and `zsh-syntax-highlighting` are zsh-only plugins;
> the bash side focuses on aliases, prompt and history.

## The dz CLI

| Command     | Description                                        |
|-------------|----------------------------------------------------|
| `dz update` | hard-sync to `origin/main` (discards local commits), reload the shell |
| `dz reload` | restart the shell                                  |
| `dz doctor` | health check: symlink, theme, remote               |
| `dz uninstall` | remove thangdz-term: restore old rc file, leave the repo on disk |
| `dz games`  | list the bundled terminal mini-games               |
| `dz game <n>` | play mini-game number `<n>` (see `dz games`)     |
| `dz servers` | list the SSH servers defined in `~/.ssh/config`  |
| `dz path`   | print the repo directory                           |
| `dz logo`   | print the ThangDZ ASCII logo, or render custom text |
| `dz help`   | show help                                          |

## Customizing

- **Change theme**: create `themes/<name>.zsh` (or `.bash`), set `ZSH_THEME`
  / `BASH_THEME` in `zshrc` / `bashrc`
- **Add plugin** (zsh): `git clone <url> plugins/<name>`, then add `<name>` to
  `plugins=(...)` in `zshrc` (the loader accepts both `<name>.plugin.zsh` and
  `<name>.zsh`)
- **Add aliases**: drop a file in `aliases/<group>.zsh` — loaded automatically
  by both shells
- **Reload**: run `reload` (zsh) or `dz reload`
