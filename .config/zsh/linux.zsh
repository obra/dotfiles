# Linux-specific shell config.
# Sourced from ~/.config/zsh/.zshrc; deployed only on Linux (manifest 'linux' tag).

# Local env written by installers (rustup/uv put a shim at ~/.local/bin/env)
[ -r "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"

# z — directory jumper (zoxide provides the `z` command, matching macOS's rupa/z)
command -v zoxide >/dev/null && eval "$(zoxide init zsh)"

# Start an ssh-agent only if one isn't already provided
[ -z "${SSH_AUTH_SOCK:-}" ] && command -v ssh-agent >/dev/null && eval "$(ssh-agent -s)" >/dev/null 2>&1

# (Service-account token sourcing for headless machines moved to the common .zshrc —
# it's capability-based, not Linux-specific.)

# Shells inside tmux lack these: the tmux server is deliberately started
# without them (see tmux@.service) so it will not put panes in
# systemd --user scopes. Restore them so systemctl --user, gpg, etc. work.
if [[ -z $XDG_RUNTIME_DIR && -d /run/user/$UID ]]; then
  export XDG_RUNTIME_DIR=/run/user/$UID
fi
if [[ -z $DBUS_SESSION_BUS_ADDRESS && -S $XDG_RUNTIME_DIR/bus ]]; then
  export DBUS_SESSION_BUS_ADDRESS=unix:path=$XDG_RUNTIME_DIR/bus
fi
