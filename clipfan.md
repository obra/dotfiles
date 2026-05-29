# clipfan setup

[clipfan](https://github.com/prime-radiant-inc/clipfan) keeps the clipboard in
sync across the fleet (Mac pasteboard + each remote's OS clipboard + tmux paste
buffer), and gives the Mac menubar app a searchable clipboard history.

These dotfiles carry only the **public** tmux integration. The shared key is a
credential and is **not** stored in any repo.

## tmux integration (in these dotfiles)

`tmux/clipfan.conf` rebinds copy-mode yanks (`y`, `Enter`, mouse-drag) to pipe
the selection through `clipfan copy`, which injects it into the local clipfan
daemon and emits OSC 52 to the client tty as a fallback. It is sourced at the
end of `.tmux.conf` so its bindings win over the earlier copy-mode bindings.

To pick it up after pulling: `tmux source-file ~/.tmux.conf` (or prefix + `r`).

## The shared key (host-local, never in git)

Every host authenticates to the mesh with the same HMAC shared key, stored in
each host's own config:

    ~/.config/clipfan/config.json        ->  field "shared_key" (base64, 32 bytes)

This file is host-local state, not a dotfile. It also holds that host's
`static_peers` list, so it differs per host. Keep `shared_key` identical
fleet-wide; the peer list varies.

### Bringing a new host online

1. Install the daemon binary at `~/.local/bin/clipfan` (and on macOS, the
   `~/.local/bin/clipfan-pasteboard-helper`), plus the supervisor unit
   (launchd plist on macOS, `systemctl --user` unit on Linux). The clipfan
   repo's `dist/install.sh` does this.
2. Copy the **same `shared_key`** from an existing host into the new host's
   `~/.config/clipfan/config.json`, and add the new host to each host's
   `static_peers` (or rely on tailscale discovery).
3. Symlink `~/.tmux.conf -> ~/git/dotfiles/.tmux.conf` so the clipfan copy
   bindings come along, then reload tmux.

The key never transits this public repo. Copy it host-to-host over ssh, or
keep it in your private store.
