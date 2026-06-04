# clipfan setup

[clipfan](https://github.com/prime-radiant-inc/clipfan) keeps the clipboard in
sync across the fleet (Mac pasteboard + each remote's OS clipboard + tmux paste
buffer), and gives the Mac menubar app a searchable clipboard history.

The product owns its own config and tmux integration. These dotfiles only
*source* what clipfan installs — they carry no clipfan code and no secrets.

## tmux integration

clipfan's `dist/install.sh` installs its copy snippet to
`~/.config/clipfan/tmux.conf` and ensures `~/.tmux.conf` sources it. Our
`.tmux.conf` already has that line:

    source-file ~/.config/clipfan/tmux.conf

The snippet rebinds copy-mode yanks (`y` / `Enter` / mouse-drag, in both the vi
and emacs tables) and hooks the tmux paste buffer (`after-set-buffer` /
`after-load-buffer`) so copies made anywhere in tmux — including full-screen
TUIs like Claude Code that bypass copy-mode — flow into the clipfan daemon and
sync to the fleet. The source line is harmless on a host where clipfan isn't
installed (tmux warns and continues).

To pick it up after install or a pull: `tmux source-file ~/.tmux.conf` (or
prefix + `r`).

## The shared key (host-local, never in git)

Every host authenticates to the mesh with the same HMAC shared key, stored in
each host's own config:

    ~/.config/clipfan/config.json        ->  field "shared_key" (base64, 32 bytes)

This file is host-local state, not a dotfile. It also holds that host's
`static_peers` list, so it differs per host. Keep `shared_key` identical
fleet-wide; the peer list varies. The key never transits this public repo — copy
it host-to-host over ssh, or keep it in your private store.

## Bringing a new host online

1. Run clipfan's `dist/install.sh` (from a built dist tree, or via the menubar
   app's "Add Peer…"). It installs the daemon at `~/.local/bin/clipfan` (plus
   the pasteboard helper on macOS / the xclip shim on Linux), registers the
   launchd/systemd unit, installs the tmux snippet, and wires `~/.tmux.conf`.
2. Copy the **same `shared_key`** from an existing host into the new host's
   `~/.config/clipfan/config.json`, and add the new host to the others'
   `static_peers` (or rely on tailscale discovery).
3. Make sure `~/.tmux.conf` is in place (symlinked to this repo, or your own),
   then reload tmux.
