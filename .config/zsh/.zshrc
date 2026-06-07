# Personal Zsh configuration file. It is strongly recommended to keep all
# shell customization and configuration (including exported environment
# variables such as PATH) in this file or in files sourced from it.
#
# Documentation: https://github.com/romkatv/zsh4humans/blob/v5/README.md.

# Periodic auto-update on Zsh startup: 'ask' or 'no'.
# You can manually run `z4h update` to update everything.
zstyle ':z4h:' auto-update      'no'
# Ask whether to auto-update this often; has no effect if auto-update is 'no'.
zstyle ':z4h:' auto-update-days '28'

# Keyboard type: 'mac' or 'pc'.
zstyle ':z4h:bindkey' keyboard  'mac'

# Don't start tmux.
zstyle ':z4h:' start-tmux       no

# Mark up shell's output with semantic information.
zstyle ':z4h:' term-shell-integration 'yes'

# Right-arrow key accepts one character ('partial-accept') from
# command autosuggestions or the whole thing ('accept')?
zstyle ':z4h:autosuggestions' forward-char 'accept'

# Recursively traverse directories when TAB-completing files.
zstyle ':z4h:fzf-complete' recurse-dirs 'no'

# Enable direnv to automatically source .envrc files.
zstyle ':z4h:direnv'         enable 'no'
# Show "loading" and "unloading" notifications from direnv.
zstyle ':z4h:direnv:success' notify 'yes'

# Enable ('yes') or disable ('no') automatic teleportation of z4h over
# SSH when connecting to these hosts.
zstyle ':z4h:ssh:example-hostname1'   enable 'yes'
zstyle ':z4h:ssh:*.example-hostname2' enable 'no'
# The default value if none of the overrides above match the hostname.
zstyle ':z4h:ssh:*'                   enable 'no'

# Send these files over to the remote host when connecting over SSH to the
# enabled hosts.
zstyle ':z4h:ssh:*' send-extra-files '~/.nanorc' '~/.env.zsh'

# Clone additional Git repositories from GitHub.
#
# This doesn't do anything apart from cloning the repository and keeping it
# up-to-date. Cloned files can be used after `z4h init`. This is just an
# example. If you don't plan to use Oh My Zsh, delete this line.
z4h install ohmyzsh/ohmyzsh || return

# Install or update core components (fzf, zsh-autosuggestions, etc.) and
# initialize Zsh. After this point console I/O is unavailable until Zsh
# is fully initialized. Everything that requires user interaction or can
# perform network I/O must be done above. Everything else is best done below.
z4h init || return

# Extend PATH.
path=(~/bin $path)

# Export environment variables.
export GPG_TTY=$TTY

# Headless machines (no 1Password app): a service-account token in ~/.config/op/env lets
# op run unattended. Absent on app-integration machines (e.g. a primary Mac) = harmless no-op.
[ -r "$HOME/.config/op/env" ] && . "$HOME/.config/op/env"

# Lazy secret loading via fnox (see ~/git/homedir-manager/share/SECRETS.md). fnox is the
# single secrets mechanism: every secret is a declared entry in ~/.config/fnox/config.toml,
# resolved at runtime. Bitwarden unlocks silently from 1Password via `bw-unlock`; BW_SESSION
# is set on first wrapped-tool use, so a bare shell — including remote SSH — never touches a
# password manager.
_bw_session() { [ -n "${BW_SESSION:-}" ] || export BW_SESSION="$(bw-unlock 2>/dev/null)"; }
withsecrets() { _bw_session; fnox exec -- "$@"; }          # ad-hoc: run any tool with all secrets
# Tool-specific secret wrappers live in the private repo (~/.config/zsh/private.zsh).

# Source additional local files if they exist.
z4h source ~/.env.zsh

# Use additional Git repositories pulled in with `z4h install`.
#
# This is just an example that you should delete. It does nothing useful.
z4h source ohmyzsh/ohmyzsh/lib/diagnostics.zsh  # source an individual file
z4h load   ohmyzsh/ohmyzsh/plugins/emoji-clock  # load a plugin

# Define key bindings.
z4h bindkey undo Ctrl+/   Shift+Tab  # undo the last command line change
z4h bindkey redo Option+/            # redo the last undone command line change

z4h bindkey z4h-cd-back    Shift+Left   # cd into the previous directory
z4h bindkey z4h-cd-forward Shift+Right  # cd into the next directory
z4h bindkey z4h-cd-up      Shift+Up     # cd into the parent directory
z4h bindkey z4h-cd-down    Shift+Down   # cd into a child directory

# Autoload functions.
autoload -Uz zmv

# Define functions and completions.
function md() { [[ $# == 1 ]] && mkdir -p -- "$1" && cd -- "$1" }
compdef _directories md

# Define named directories: ~w <=> Windows home directory on WSL.
[[ -z $z4h_win_home ]] || hash -d w=$z4h_win_home


# Add flags to existing aliases.
alias ls="${aliases[ls]:-ls} -A"

# Set shell options: http://zsh.sourceforge.net/Doc/Release/Options.html.
setopt glob_dots     # no special treatment for file names with a leading dot
setopt no_auto_menu  # require an extra TAB press to open the completion menu

command -v mise >/dev/null && eval "$(mise activate zsh)"

# OS-specific shell config (deployed per-OS via dotfiles; absent elsewhere = no-op).
[ -r "${ZDOTDIR}/macos.zsh" ] && source "${ZDOTDIR}/macos.zsh"
[ -r "${ZDOTDIR}/linux.zsh" ] && source "${ZDOTDIR}/linux.zsh"
# Private/work fragments (from the private dotfiles repo).
[ -r "${ZDOTDIR}/private.zsh" ] && source "${ZDOTDIR}/private.zsh"

# LM Studio CLI
[ -d "$HOME/.cache/lm-studio/bin" ] && export PATH="$PATH:$HOME/.cache/lm-studio/bin"

export EDITOR=vim
alias mroe=less

# Docker Desktop CLI completions
[ -d "$HOME/.docker/completions" ] && fpath=("$HOME/.docker/completions" $fpath)
autoload -Uz compinit
compinit

alias rgp='rg --glob "!**/__tests__/**" --glob "!**/*.test.*" --glob "!**/*.spec.*"'

google(){
  gemini -p "Search google for <query>$1</query> and summarize the results"
}

# pnpm
if [ -d "$HOME/Library/pnpm" ]; then
  export PNPM_HOME="$HOME/Library/pnpm"
  case ":$PATH:" in
    *":$PNPM_HOME:"*) ;;
    *) export PATH="$PNPM_HOME:$PATH" ;;
  esac
fi

export PATH="$HOME/.claude/local/:$HOME/go/bin:$PATH"
[ -d "$HOME/.rbenv/bin" ] && export PATH="$HOME/.rbenv/bin:$PATH"
command -v rbenv >/dev/null && eval "$(rbenv init - --no-rehash zsh)"

# (machine/work-specific tool integrations live in the private repo's private.zsh)

# Generic local bin
[ -d "$HOME/.local/bin" ] && export PATH="$HOME/.local/bin:$PATH"
