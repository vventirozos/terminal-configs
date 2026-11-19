#!/bin/bash
# Install one profile's config files into the current user's home directory.
#
#   ./install.sh <profile>        install (asks before changing anything)
#   ./install.sh -n <profile>     dry run: only show what would change
#   ./install.sh -y <profile>     install without asking
#
# A profile is one of the directories next to this script (evolmonkey, nova,
# nova-work, eva); each mirrors a home directory. Files that already exist and
# differ are first copied to a single backup directory,
# ~/terminal-backup-<date>-<time>/, keeping the same layout.

set -euo pipefail
cd "$(dirname "$0")"

dry=0; yes=0
while [[ ${1:-} == -* ]]; do
  case $1 in
    -n|--dry-run) dry=1 ;;
    -y|--yes)     yes=1 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
  shift
done

profile=${1:-}
profile=${profile%/}
if [[ -z $profile || ! -f $profile/.zshrc ]]; then
  echo "usage: ./install.sh [-n] [-y] <profile>" >&2
  echo "profiles:" >&2
  for d in */; do [[ -f ${d}.zshrc ]] && echo "  ${d%/}" >&2; done
  exit 2
fi

files=()
while IFS= read -r f; do files+=("$f"); done \
  < <(find "$profile" -type f ! -name .DS_Store | sort)

# First pass: what would happen
new=(); changed=(); same=0
for src in "${files[@]}"; do
  rel=${src#"$profile"/}
  dst=$HOME/$rel
  if [[ ! -e $dst ]]; then new+=("$rel")
  elif cmp -s "$src" "$dst"; then same=$((same + 1))
  else changed+=("$rel")
  fi
done

echo "Profile '$profile' -> $HOME (user $(id -un) on $(hostname -s))"
for rel in ${new[@]+"${new[@]}"};         do echo "  new      ~/$rel"; done
for rel in ${changed[@]+"${changed[@]}"}; do echo "  replace  ~/$rel"; done
echo "  $same file(s) already identical"

if (( ${#new[@]} + ${#changed[@]} == 0 )); then echo "Nothing to do."; exit 0; fi
if (( dry )); then echo "Dry run: nothing changed."; exit 0; fi

if (( ! yes )); then
  read -r -p "Proceed? [y/N] " answer
  [[ $answer == [yY]* ]] || { echo "Aborted."; exit 1; }
fi

if pgrep -x -u "$(id -u)" mc >/dev/null 2>&1; then
  echo "Note: Midnight Commander is running and rewrites ~/.config/mc/ini when it exits;"
  echo "      quit it and run this script again if its skin does not change."
fi

backup=$HOME/terminal-backup-$(date +%Y-%m-%d-%H%M%S)
for rel in ${changed[@]+"${changed[@]}"}; do
  mkdir -p "$backup/$(dirname "$rel")"
  cp -p "$HOME/$rel" "$backup/$rel"
done
for rel in ${new[@]+"${new[@]}"} ${changed[@]+"${changed[@]}"}; do
  mkdir -p "$HOME/$(dirname "$rel")"
  cp "$profile/$rel" "$HOME/$rel"
done
chmod 600 "$HOME/.zshrc"

echo "Installed $(( ${#new[@]} + ${#changed[@]} )) file(s)."
(( ${#changed[@]} )) && echo "Previous versions are in $backup"

# Tools the configs expect
missing=()
for tool in eza fzf fd bat rg zoxide tmux mc pspg joe; do
  command -v "$tool" >/dev/null 2>&1 || [[ -x /opt/homebrew/bin/$tool ]] || missing+=("$tool")
done
for f in share/zsh-autosuggestions/zsh-autosuggestions.zsh \
         share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh; do
  [[ -r /opt/homebrew/$f ]] || missing+=("$(basename "$f" .zsh)")
done
if (( ${#missing[@]} )); then
  echo "Not installed yet: ${missing[*]}  (see README.md for the brew command)"
fi

echo "Open a new terminal (or run: exec zsh). In tmux, press prefix + r to reload."
