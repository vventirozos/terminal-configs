# Terminal configs

Snapshot of the terminal setup on each account, taken 2026-11-19.
Each directory mirrors the account's home directory, so a file at
`nova/.config/eza/theme.yml` lives at `~/.config/eza/theme.yml` on nova.

| Directory    | Account            |
|--------------|--------------------|
| `evolmonkey` | vasilis@evolmonkey |
| `nova`       | vasilis@nova       |
| `nova-work`  | work@nova          |
| `eva`        | vasilis@eva        |

## What is in here

| File                                     | What it configures                         |
|------------------------------------------|--------------------------------------------|
| `.zshrc`                                 | zsh: prompt, history, eza `ls`, fzf          |
| `.tmux.conf`                             | tmux                                       |
| `.psqlrc`                                | psql (pspg pager, prompt, per-db history)  |
| `.vimrc`                                 | vim                                        |
| `.joerc`                                 | joe: no backups, no word wrap, highlighting, indent step 4, tab 4 |
| `.joe/ftyperc`                           | joe file types (stock table minus its word-wrap lines) |
| `.config/ghostty/config`                 | Ghostty (evolmonkey, eva)                  |
| `.config/eza/theme.yml`                  | eza colours                                |
| `.config/mc/ini`                         | Midnight Commander settings                |
| `.local/share/mc/skins/tokyonight.ini`   | Midnight Commander Tokyo Night skin        |
| `.config/btop/btop.conf`                 | btop (evolmonkey, nova)                    |
| `.hammerspoon/init.lua`                  | F12 terminal toggle (evolmonkey)           |
| `Data/AI/bin/eva.tmux`                   | tmux dashboard launcher: llama-top, host-top, ghost log, ghost (eva) |
| `Data/AI/bin/host-top`                   | full-screen monitor for several machines at once (eva) |
| `Data/AI/bin/llama-top`                  | full-screen monitor for the llama-server log and slots (eva) |

## Installing

```
./install.sh -n nova     # dry run: show what would change
./install.sh nova        # install the "nova" profile into this user's home
```

Run it on the target machine, as the target user, with the profile that
matches (`evolmonkey`, `nova`, `nova-work` or `eva`). Files that already exist
and differ are copied to one directory, `~/terminal-backup-<date>-<time>/`,
before being replaced. Identical files are left alone, so the script is safe
to run again.

## What is deliberately not in here

- `~/.zsh_secrets` — API keys and tokens. Each `.zshrc` sources it if present.
- `~/.ssh/`, shell and psql history files.

## Homebrew packages the configs expect

```
brew install eza fzf fd bat ripgrep zoxide tmux midnight-commander btop pspg \
             joe zsh-autosuggestions zsh-syntax-highlighting
brew install direnv                      # evolmonkey only
brew install --cask font-jetbrains-mono  # where Ghostty runs
```

tmux plugins (vasilis accounts) are managed by tpm: clone
`https://github.com/tmux-plugins/tpm` to `~/.tmux/plugins/tpm`, then press
prefix + `I`.
