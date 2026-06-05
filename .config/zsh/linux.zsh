# Linux-specific shell config.
# Sourced from ~/.config/zsh/.zshrc; deployed only on Linux (manifest 'linux' tag).

# Local env written by installers (rustup/uv put a shim at ~/.local/bin/env)
[ -r "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"

# Start an ssh-agent only if one isn't already provided
[ -z "${SSH_AUTH_SOCK:-}" ] && command -v ssh-agent >/dev/null && eval "$(ssh-agent -s)" >/dev/null 2>&1

# Headless 1Password: no desktop app here, so op needs a service-account token.
# Put `export OP_SERVICE_ACCOUNT_TOKEN=ops_...` in ~/.config/op/env (chmod 600, never tracked).
# That lets op read items non-interactively, which in turn drives bw-unlock + fnox.
[ -r "$HOME/.config/op/env" ] && . "$HOME/.config/op/env"
