# Linux-specific shell config.
# Sourced from ~/.config/zsh/.zshrc; deployed only on Linux (manifest 'linux' tag).

# Local env written by installers (rustup/uv put a shim at ~/.local/bin/env)
[ -r "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"

# Start an ssh-agent only if one isn't already provided
[ -z "${SSH_AUTH_SOCK:-}" ] && command -v ssh-agent >/dev/null && eval "$(ssh-agent -s)" >/dev/null 2>&1

# (Service-account token sourcing for headless machines moved to the common .zshrc —
# it's capability-based, not Linux-specific.)
