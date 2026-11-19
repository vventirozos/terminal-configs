# Emacs-style line editing, stated explicitly: with EDITOR=vim zsh could
# otherwise pick vi keys, where Option/Cmd+Backspace word delete is unbound
bindkey -e

export PATH=/opt/homebrew/bin:/home/vasilis/.orbstack/bin:/Users/vasilis/Data/bin:/opt/homebrew/opt/postgresql@18/bin:$PATH
# Prompt: path + git branch, then the host name; ">" turns red after a failure
setopt PROMPT_SUBST
autoload -Uz vcs_info add-zsh-hook
zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:git:*' formats ' %b'
zstyle ':vcs_info:git:*' actionformats ' %b|%a'
add-zsh-hook precmd vcs_info
export PS1=$'%F{#737aa2}%d/%F{#9ece6a}${vcs_info_msg_0_}\n%054FNova %(?.%252F.%196F)>%252F '

export GHOST_HOME=/Users/vasilis/AI/Data/
export PI_VOICE_URL="http://disorder:8000"
# Secrets (tokens, API keys) live in a private file, mode 600
[[ -r ~/.zsh_secrets ]] && source ~/.zsh_secrets

# (ls is eza now: see the function near the end of this file)
alias ghost.log='tail -f /Users/vasilis/AI/Logs/ghost-agent.log'
alias llama.log='tail -f /Users/vasilis/Data/AI/Logs/llama-server.log'


stty stop '^-' start '^-'
setopt noflowcontrol

#
PROMPT_EOL_MARK=''
HISTFILE="$HOME/.zsh_history"
HISTSIZE=200000
SAVEHIST=200000
setopt share_history          # all shells read and write one history
setopt inc_append_history     # written as you go, not at exit
setopt extended_history       # with timestamps
setopt hist_ignore_all_dups   # a repeated command replaces its older copy
setopt hist_ignore_space      # a leading space keeps a command out of history
setopt hist_reduce_blanks

autoload -U select-word-style
select-word-style bash

#bindkey '^W' default-backward-delete-word
bindkey '^[[1;5D' backward-word
bindkey '^[[1;5C' forward-word
bindkey '^[[1;3D' backward-word
bindkey '^[[1;3C' forward-word


# Added by Antigravity
export PATH="/Users/vasilis/.antigravity/antigravity/bin:$PATH"
source /Users/vasilis/AI/venv/bin/activate
export PATH="$HOME/.local/bin:/Users/vasilis/Data/AI/bin/:$PATH"

# ============================================================
#  QoL additions 2026-11-18 / 2026-11-19 (same as evolmonkey)
# ============================================================
autoload -Uz compinit
compinit
zstyle ':completion:*' menu select                         # arrow-key menu
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'     # case-insensitive

# --- Environment ---
export COLORTERM=truecolor
export EZA_CONFIG_DIR=$HOME/.config/eza/
export EZA_ICON_SPACING=1
if (( $+commands[bat] )); then
  # bat: "ansi" takes its colours from the terminal palette, so it follows the terminal theme
  export BAT_THEME=ansi
  export MANPAGER="sh -c 'col -bx | bat -l man -p'"
  export MANROFFOPT=-c
fi

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
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}      # same colours as ls

# --- Shell behaviour ---
setopt interactive_comments   # "# ..." is a comment at the prompt too (pasted snippets)
setopt auto_pushd             # every cd is remembered: "cd -<Tab>" lists where you have been
setopt pushd_ignore_dups
setopt pushd_silent

# Home / End / Delete: every form Ghostty and tmux send
for k in '^[[H' '^[OH' '^[[1~' '^[[7~'; do bindkey $k beginning-of-line; done
for k in '^[[F' '^[OF' '^[[4~' '^[[8~'; do bindkey $k end-of-line; done
bindkey '^[[3~' delete-char

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

# Interactive helpers: only in a real terminal, so scripts and tools that
# start a shell without one are not affected.
if [[ -o interactive && -t 0 ]]; then
  if (( $+commands[eza] )); then
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
  fi

  # fzf: Ctrl-R history, Ctrl-T file picker (bat preview), Alt-C cd (tree preview);
  # Ctrl-/ moves or hides the preview.
  if (( $+commands[fzf] )); then
    source <(fzf --zsh)
    if (( $+commands[fd] )); then
      export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'
      export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND --color=always"
      export FZF_ALT_C_COMMAND='fd --type d --hidden --exclude .git --color=always'
    fi
    # Tokyo Night colours on the terminal's own (black) background
    export FZF_DEFAULT_OPTS="--info=inline-right --highlight-line \
    --color=fg:#c0caf5,bg:-1,hl:#2ac3de,fg+:#c0caf5,bg+:#283457,hl+:#2ac3de,gutter:-1 \
    --color=border:#27a1b9,header:#ff9e64,info:#545c7e,marker:#ff007c,pointer:#ff007c \
    --color=prompt:#2ac3de,query:#c0caf5:regular,scrollbar:#27a1b9,separator:#414868,spinner:#ff007c"
    export FZF_CTRL_T_OPTS="--ansi --preview 'bat --color=always --style=numbers --line-range=:300 {}' \
    --preview-window 'right,55%,border-left' --bind 'ctrl-/:change-preview-window(down,60%,border-top|hidden|)'"
    export FZF_ALT_C_OPTS="--ansi --preview 'eza --tree --level=2 --color=always --icons=always --group-directories-first {} | head -200' \
    --preview-window 'right,55%,border-left' --bind 'ctrl-/:change-preview-window(down,60%,border-top|hidden|)'"
  fi
  # zoxide: "z part-of-a-dir-name" jumps there, "zi" picks interactively
  (( $+commands[zoxide] )) && eval "$(zoxide init zsh)"
  # Suggestions from history as you type (Right arrow accepts), then colouring.
  # Syntax highlighting must stay last.
  [[ -r /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]] &&
    source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
  if [[ -r /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
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
  fi
fi
