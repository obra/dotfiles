# Arq Snapshot Cleaner Design

## Goal

Provide one command that Jesse can run after pausing Arq to remove APFS snapshots created by Arq and restore Arq's background services afterward.

## Location and installation

The tracked script will live at `bin/arq-clear-snapshots` in the dotfiles repository. The dotfiles manifest will expose it as `~/bin/arq-clear-snapshots`, matching the existing managed-bin convention.

## Behavior

The script will:

1. Require macOS and the system tools it uses.
2. Discover the live Data volume rather than hardcoding `disk3s5`.
3. List that volume's current APFS snapshots and select only snapshot names beginning with `com_haystacksoftware_arqagent_`.
4. Exit successfully without changing services when no matching snapshot exists.
5. Show the matching snapshots and require confirmation that Arq is paused. `--yes` will provide an explicit noninteractive path.
6. Acquire `sudo` before stopping services so a failed authentication does not disturb Arq.
7. Stop the per-user `ArqMonitor` launch agent and the system `arqagent` daemon when they are loaded.
8. Unmount matching snapshot mounts below `/Library/Application Support/ArqAgentAPFS.noindex` and delete only the snapshots discovered in step 3.
9. Verify that no discovered Arq snapshot remains and print Data-volume free space before and after.
10. Attempt to restore every Arq service that the script stopped, including on errors or interruption. A restoration failure is loud and returns a nonzero status.

The script will never delete Time Machine, OS update, or other purgeable snapshots. It will not use stale mount-directory names as evidence that a snapshot exists.

## Error handling

Deletion stops on the first failure. The exit trap then restores stopped services. If both the primary operation and restoration fail, the output reports both conditions and exits nonzero.

The script reports partial deletion accurately: it will not claim success unless a fresh snapshot listing proves that all snapshots selected at startup are gone.

## Testing

Shell behavior tests will run the script with temporary fake implementations of `diskutil`, `launchctl`, `mount`, and `sudo`. They will exercise observable contracts:

- no matching snapshots means no service or deletion changes;
- only exact Arq-prefixed snapshots are selected;
- declined confirmation makes no changes;
- loaded services are stopped and restored around deletion;
- deletion failure still restores services and exits nonzero;
- verification failure prevents a success result;
- `--yes` supports intentional noninteractive execution.

The tests will inspect fake command call logs and resulting exit/output behavior, not compare a rendered shell program or large command string.
