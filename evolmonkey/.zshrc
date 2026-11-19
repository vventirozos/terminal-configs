# ============================================================
#  ~/.zshrc
# ============================================================

# --- PATH: Homebrew first, then personal tools ---
eval "$(/opt/homebrew/bin/brew shellenv)"
typeset -U path
path+=(
  /Users/vasilis/Data/work/bin
  /Users/vasilis/Data/work/tools/PostgreSQL/pgsql/bin
  $HOME/.local/bin
)
export PATH

# --- Secrets (API keys) live in a private file, mode 600 ---
[[ -r ~/.zsh_secrets ]] && source ~/.zsh_secrets

# --- Environment ---
export EZA_CONFIG_DIR=/Users/vasilis/.config/eza/
export EZA_ICON_SPACING=1
export PGDATA=/Users/vasilis/Data/work/tools/PostgreSQL/pgdata
export PGDATABASE=evolmonkey
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export PAGER=less
export CLICOLOR=1
export LSCOLORS=exfxcxdxbxegedabagacad
export EDITOR='vim'
export VISUAL='vim'
export COLORTERM=truecolor
# bat: "ansi" takes its colours from the terminal palette, so it follows the Ghostty theme
export BAT_THEME=ansi
export MANPAGER="sh -c 'col -bx | bat -l man -p'"
export MANROFFOPT=-c

# LS_COLORS: the same colours as ~/.config/eza/theme.yml, for fd, fzf and the Tab menu
() {
  local c='38;2;' rgb ext out
  out="di=${c}0;135;215:ln=${c}215;0;215:ex=${c}158;206;106:pi=${c}65;72;104:so=${c}65;72;104"
  out+=":bd=${c}224;175;104:cd=${c}224;175;104:or=${c}255;0;124:mi=${c}255;0;124"
  local -A groups=(
    '137;221;255' 'png jpg jpeg gif webp svg heic ico bmp tif tiff'          # image
    '180;249;248' 'mp4 mkv mov avi webm m4v'                                 # video
    '115;218;202' 'mp3 m4a ogg opus aac'                                     # music
    '65;166;181'  'flac wav alac'                                            # lossless
    '219;75;75'   'gpg asc pem key crt p12 age'                              # crypto
    '169;177;214' 'pdf doc docx odt rtf md txt xls xlsx ods ppt pptx'        # document
    '255;158;100' 'zip gz tgz bz2 xz zst 7z rar tar dmg iso'                 # compressed
    '115;122;162' 'tmp bak swp o pyc class log'                              # temp / compiled
    '187;154;247' 'c h cpp rs go py js ts sh zsh sql lua rb java pl'         # source
  )
  for rgb in ${(k)groups}; do
    for ext in ${=groups[$rgb]}; do out+=":*.$ext=$c$rgb"; done
  done
  export LS_COLORS=$out
}

#export OLLAMA_HOST=100.66.145.50:8000
#export OLLAMA_HOST=100.66.145.50:11434
export OLLAMA_MODELS=/Users/vasilis/Data/Ext_data/Ollama/models/
# USER_AGENT and DATABASE_URL are no longer global: they live in
# ~/Data/work/AI/llmchatbot/.envrc and direnv loads them inside that project only.
export TOR_PROXY="socks5://ghost:9050"

ulimit -n 2048

# --- Terminal: free Ctrl-S / Ctrl-Q (tmux prefix is C-q) ---
stty stop '^-' start '^-'
setopt noflowcontrol

# --- Shell behaviour ---
setopt interactive_comments   # "# ..." is a comment at the prompt too (pasted snippets)
setopt auto_pushd             # every cd is remembered: "cd -<Tab>" lists where you have been
setopt pushd_ignore_dups
setopt pushd_silent

# --- History ---
HISTFILE="$HOME/.zsh_history"
HISTSIZE=200000
SAVEHIST=200000
setopt share_history          # all shells read and write one history
setopt inc_append_history     # written as you go, not at exit
setopt extended_history       # with timestamps
setopt hist_ignore_all_dups   # a repeated command replaces its older copy
setopt hist_ignore_space      # a leading space keeps a command out of history
setopt hist_reduce_blanks

# --- Emacs-style line editing, stated explicitly: with EDITOR=vim zsh would
#     otherwise pick vi keys, where Option/Cmd+Backspace word delete is unbound ---
bindkey -e

# --- Completion (fpath first, compinit once) ---
fpath=(/Users/vasilis/.docker/completions $fpath)
autoload -Uz compinit
compinit
autoload -U +X bashcompinit && bashcompinit

zstyle ':completion:*' menu select                         # arrow-key menu
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'     # case-insensitive
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}      # same colours as ls

# 1Password completion, cached; regenerated when the op binary changes
() {
  local cache=~/.cache/zsh/op_completion.zsh op_bin=${commands[op]}
  [[ -n $op_bin ]] || return
  if [[ ! -s $cache || $op_bin -nt $cache ]]; then
    mkdir -p ${cache:h} && op completion zsh >| $cache
  fi
  source $cache
  compdef _op op
}

# --- Prompt: path + git branch, then EvolMonkey; ">" turns red after a failure ---
setopt PROMPT_SUBST
autoload -Uz vcs_info add-zsh-hook
zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:git:*' formats ' %b'
zstyle ':vcs_info:git:*' actionformats ' %b|%a'
add-zsh-hook precmd vcs_info

# Path and branch use the Tokyo Night palette; Evol/Monkey keep the brand red and blue
PS1=$'%F{#737aa2}%d/%F{#9ece6a}${vcs_info_msg_0_}\n%196FEvol%27FMonkey %(?.%252F.%196F)>%252F '
PROMPT_EOL_MARK=''

# --- Line editing ---
autoload -U select-word-style
select-word-style bash

#bindkey '^W' default-backward-delete-word
bindkey '^[[1;5D' backward-word
bindkey '^[[1;5C' forward-word
bindkey '^[[1;3D' backward-word
bindkey '^[[1;3C' forward-word

# Home / End / Delete: every form Ghostty and tmux send
for k in '^[[H' '^[OH' '^[[1~' '^[[7~'; do bindkey $k beginning-of-line; done
for k in '^[[F' '^[OF' '^[[4~' '^[[8~'; do bindkey $k end-of-line; done
bindkey '^[[3~' delete-char
# Shift+PageUp/Down are handled by Ghostty/tmux; the shell ignores them
_noop_key() { }
zle -N _noop_key
bindkey '^[[5;2~' _noop_key
bindkey '^[[6;2~' _noop_key

# Up / Down: walk history, but only entries starting with what is already typed
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search edit-command-line
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
for k in '^[[A' '^[OA'; do bindkey $k up-line-or-beginning-search; done
for k in '^[[B' '^[OB'; do bindkey $k down-line-or-beginning-search; done
# Ctrl-X Ctrl-E: edit the current command line in $EDITOR
zle -N edit-command-line
bindkey '^X^E' edit-command-line
unset k

# --- Aliases ---
# df: human sizes. Bare "df" hides the TimeMachine / System / devfs noise;
# with arguments ("df /some/path") they go to df and nothing is filtered.
df() {
  if (( $# )); then command df -h "$@"
  else command df -h | command grep -vi TimeMachine | command grep -v System | command grep -v devfs
  fi
}
alias du='du -k'
alias history='history 0'
alias grep='grep --color=auto'
# ls -> eza, translating the GNU/BSD sort flags eza treats differently:
#   -t = sort by mtime (newest first), -S = sort by size (largest first), -r = reverse
# Long listings also get a git status column and ISO dates; names are Cmd-clickable links.
# LS_COLORS is hidden from eza so its colours come from ~/.config/eza/theme.yml alone.
ls() {
  local -a args base=(--icons=auto --hyperlink=auto)
  local a flags sort="" rev=0 parse=1 long=0
  for a in "$@"; do
    if (( parse )) && [[ $a == "--" ]]; then
      parse=0; args+=("$a")
    elif (( parse )) && [[ $a == -[^-]* ]]; then
      flags=${a#-}
      [[ $flags == *t* ]] && sort=modified
      [[ $flags == *S* ]] && sort=size
      [[ $flags == *r* ]] && rev=1
      [[ $flags == *l* ]] && long=1
      flags=${flags//[tSr]/}
      [[ -n $flags ]] && args+=("-$flags")
    else
      (( parse )) && [[ $a == --long ]] && long=1
      args+=("$a")
    fi
  done
  (( long )) && base+=(--git --time-style=long-iso)
  if [[ -n $sort ]]; then
    # eza sorts ascending, ls -t/-S descending: flip the meaning of -r
    (( rev )) || args=(--reverse "${args[@]}")
    LS_COLORS= command eza $base --sort=$sort "${args[@]}"
  else
    (( rev )) && args=(--reverse "${args[@]}")
    LS_COLORS= command eza $base --group-directories-first "${args[@]}"
  fi
}
alias ll='ls -l'       # long
alias la='ls -la'      # long, with dotfiles
alias lt='ls -ltr'     # long, newest at the bottom
alias tree='LS_COLORS= eza --icons=auto --hyperlink=auto --group-directories-first --tree'
alias ai='cd ~/Data/work/AI/'

alias push_agent='/Users/vasilis/Data/work/bin/sync_agent.sh && cd /Users/vasilis/AGENT && git add -A && git commit ; git push ; cd '

alias pg_stuff='bat -p --paging=never -l sql /Users/vasilis/Data/work/tools/scripts/postgres/useful_sql/pg_stuff.txt'
alias docker_stuff='bat -p --paging=never -l bash /Users/vasilis/Data/work/tools/scripts/docker/docker_stuff.txt'
alias citus_stuff='bat -p --paging=never -l sql /Users/vasilis/Data/work/tools/scripts/citus/useful_sql.txt'
alias joe_defs='cat /Users/vasilis/Data/work/tools/scripts/linux/joe.defaults'
alias todo='cat ~/data/work/TODO/TODO.txt'
alias gen_pass='openssl rand -base64 24'
alias encrypt_file='gpg -e -r vasilis'
alias decrypt_file='gpg -d'
alias export_gpg_key='gpg --armor --export vasilis'
alias ts='ts "[%F %H:%M:%S]"'
alias redir_all='echo "> /dev/null 2>&1"'
alias screen_fix='echo script /dev/null - screen as user'

# Hosts are defined in ~/.ssh/config (so scp/rsync and tab completion work too)
alias ssh_home='ssh evolmonkey.home'
alias diso='ssh diso'
alias nova='ssh nova'
alias work='ssh work@nova'
alias eva='ssh eva'

# --- Tools ---
# fzf: Ctrl-R history, Ctrl-T file picker, Alt-C cd
#      Ctrl-T previews the file with bat, Alt-C previews the directory as a tree;
#      Ctrl-/ moves or hides the preview.
source <(fzf --zsh)
export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND --color=always"
export FZF_ALT_C_COMMAND='fd --type d --hidden --exclude .git --color=always'
# Tokyo Night colours on the terminal's own (black) background
export FZF_DEFAULT_OPTS="--info=inline-right --highlight-line \
--color=fg:#c0caf5,bg:-1,hl:#2ac3de,fg+:#c0caf5,bg+:#283457,hl+:#2ac3de,gutter:-1 \
--color=border:#27a1b9,header:#ff9e64,info:#545c7e,marker:#ff007c,pointer:#ff007c \
--color=prompt:#2ac3de,query:#c0caf5:regular,scrollbar:#27a1b9,separator:#414868,spinner:#ff007c"
export FZF_CTRL_T_OPTS="--ansi --preview 'bat --color=always --style=numbers --line-range=:300 {}' \
--preview-window 'right,55%,border-left' --bind 'ctrl-/:change-preview-window(down,60%,border-top|hidden|)'"
export FZF_ALT_C_OPTS="--ansi --preview 'eza --tree --level=2 --color=always --icons=always --group-directories-first {} | head -200' \
--preview-window 'right,55%,border-left' --bind 'ctrl-/:change-preview-window(down,60%,border-top|hidden|)'"

# direnv: per-project environment from a .envrc file ("direnv allow" once per file)
eval "$(direnv hook zsh)"

# zoxide: "z part-of-a-dir-name" jumps there, "zi" picks interactively
eval "$(zoxide init zsh)"

# Suggestions from history as you type (Right arrow accepts), then colouring.
# Syntax highlighting must stay last.
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# No underlines on paths and commands
for k in ${(k)ZSH_HIGHLIGHT_STYLES}; do
  [[ ${ZSH_HIGHLIGHT_STYLES[$k]} == *underline* ]] && ZSH_HIGHLIGHT_STYLES[$k]=${${ZSH_HIGHLIGHT_STYLES[$k]//,underline/}//underline/none}
done
unset k

# Tokyo Night colours for the command line as you type
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#565f89'
() {
  local k
  for k in command builtin function alias precommand hashed-command; do ZSH_HIGHLIGHT_STYLES[$k]='fg=#7aa2f7'; done
  for k in single-quoted-argument double-quoted-argument dollar-quoted-argument; do ZSH_HIGHLIGHT_STYLES[$k]='fg=#9ece6a'; done
  for k in dollar-double-quoted-argument back-double-quoted-argument back-dollar-quoted-argument; do ZSH_HIGHLIGHT_STYLES[$k]='fg=#2ac3de'; done
  for k in single-hyphen-option double-hyphen-option; do ZSH_HIGHLIGHT_STYLES[$k]='fg=#e0af68'; done
  for k in commandseparator redirection; do ZSH_HIGHLIGHT_STYLES[$k]='fg=#89ddff'; done
  for k in reserved-word history-expansion; do ZSH_HIGHLIGHT_STYLES[$k]='fg=#bb9af7'; done
  ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=#f7768e'
  ZSH_HIGHLIGHT_STYLES[globbing]='fg=#ff9e64'
  ZSH_HIGHLIGHT_STYLES[path]='fg=#7dcfff'
  ZSH_HIGHLIGHT_STYLES[comment]='fg=#565f89'
}
