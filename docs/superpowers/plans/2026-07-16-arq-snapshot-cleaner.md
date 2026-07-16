# Arq Snapshot Cleaner Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a dotfiles-managed `~/bin/arq-clear-snapshots` command that safely stops Arq, deletes only live Arq APFS snapshots, restores Arq, and verifies the result.

**Architecture:** A single Bash command owns the lifecycle and resolves macOS tools through `PATH` so behavior tests can supply deterministic fakes. A plain-shell test fixture models snapshot and launch-service state; tests assert resulting state, exit status, and only the narrow system calls that are public safety contracts.

**Tech Stack:** Bash 3.2-compatible script, POSIX shell test harness, macOS `diskutil`, `launchctl`, `mount`, `df`, and `sudo`.

## Global Constraints

- Select only live snapshot names beginning `com_haystacksoftware_arqagent_`.
- Never act on stale mount-directory names alone or delete unrelated APFS snapshots.
- Stop and restore both loaded Arq services, including after errors or interruption.
- Require interactive confirmation unless `--yes` is supplied.
- Do not claim success without a fresh snapshot listing proving selected snapshots are gone.

---

### Task 1: Test the safe lifecycle contracts

**Files:**
- Create: `test/test_arq_clear_snapshots.sh`
- Create during Task 2: `bin/arq-clear-snapshots`

**Interfaces:**
- Consumes: executable `bin/arq-clear-snapshots [--yes]`
- Produces: fake-command fixture state for APFS snapshot names and loaded Arq services

- [ ] **Step 1: Add a fake macOS command fixture and failing behavior tests**

Create temporary `diskutil`, `launchctl`, `sudo`, `mount`, `df`, `uname`, and `id` executables at the front of `PATH`. Store snapshots one name per line in `$FAKE_STATE/snapshots`; store loaded labels in `$FAKE_STATE/services`; append mutations to `$FAKE_STATE/calls`. Cover these behaviors:

```sh
# No Arq snapshot: exits zero without sudo or service changes.
run_cleaner --yes
assert_eq 0 "$status" "no snapshot is a successful no-op"
assert_eq "" "$(cat "$FAKE_STATE/calls")" "no snapshot changes nothing"

# Happy path: deletes two Arq names, retains an OS update name, and restores services.
assert_eq "com.apple.os.update-example" "$(cat "$FAKE_STATE/snapshots")" \
  "unrelated snapshot remains"
assert_services_restored

# Declined prompt: no mutations.
printf 'n\n' | run_cleaner

# Failed or ineffective deletion: exits nonzero and restores services.
FAKE_DELETE_MODE=fail run_cleaner --yes
FAKE_DELETE_MODE=noop run_cleaner --yes
```

- [ ] **Step 2: Run the focused test and verify RED**

Run: `sh test/test_arq_clear_snapshots.sh`

Expected: failure because `bin/arq-clear-snapshots` does not exist.

- [ ] **Step 3: Commit the failing tests**

```bash
git add test/test_arq_clear_snapshots.sh
git commit -m "Test Arq snapshot cleanup lifecycle"
```

### Task 2: Implement targeted cleanup and service restoration

**Files:**
- Create: `bin/arq-clear-snapshots`
- Test: `test/test_arq_clear_snapshots.sh`

**Interfaces:**
- Consumes: `--yes`; macOS commands named in `PATH`; Arq launch plist paths
- Produces: exit 0 only for a no-op or verified removal; human-readable snapshot and free-space reporting

- [ ] **Step 1: Implement discovery and confirmation**

Use Bash arrays and parse only `Name:` fields from `diskutil apfs listSnapshots "$data_volume"`:

```bash
data_volume=$(diskutil info /System/Volumes/Data | awk -F: '/Device Identifier/ { gsub(/[[:space:]]/, "", $2); print $2; exit }')
while IFS= read -r snapshot; do
  [[ $snapshot == com_haystacksoftware_arqagent_* ]] && snapshots+=("$snapshot")
done < <(diskutil apfs listSnapshots "$data_volume" | awk -F': ' '/^[[:space:]]*Name:/ { print $2 }')
```

Exit zero before `sudo` when the array is empty. Otherwise list every selected name and require `y`/`yes`, unless `--yes` was passed.

- [ ] **Step 2: Implement service lifecycle with unconditional cleanup**

Acquire privileges with `sudo -v`, record which labels are loaded using `launchctl print`, then stop only those services. Install a trap before the first stop. Cleanup restarts the system daemon first and user monitor second, records restoration failures, and preserves a primary failure status.

```bash
trap 'finish $?' EXIT HUP INT TERM
launchctl bootout "gui/$uid" "$monitor_plist"
sudo launchctl bootout system "$agent_plist"
```

- [ ] **Step 3: Implement mounted-snapshot cleanup, deletion, and verification**

Read current mount output and unmount only paths below `/Library/Application Support/ArqAgentAPFS.noindex/` whose basename corresponds to the Data-volume UUID plus an Arq snapshot suffix. Delete every selected live name with:

```bash
sudo diskutil apfs deleteSnapshot "$data_volume" -name "$snapshot"
```

List snapshots again and fail if any startup-selected name remains. Print `df -h /System/Volumes/Data` before and after.

- [ ] **Step 4: Run the focused test and verify GREEN**

Run: `sh test/test_arq_clear_snapshots.sh`

Expected: all assertions pass and `RESULT ... failed=0` is printed.

- [ ] **Step 5: Run the complete dotfiles test suite**

Run: `sh test/run.sh`

Expected: `TOTAL run=<n> failed=0`.

- [ ] **Step 6: Commit the implementation**

```bash
git add bin/arq-clear-snapshots test/test_arq_clear_snapshots.sh
git commit -m "Add safe Arq snapshot cleaner"
```

### Task 3: Deploy and verify the user command

**Files:**
- Modify: `manifest`
- Modify: `README.md`
- Deploy: `~/bin/arq-clear-snapshots` symlink

**Interfaces:**
- Consumes: `homedir-manager install`
- Produces: executable `arq-clear-snapshots` on Jesse's `PATH`

- [ ] **Step 1: Add the utility to the manifest and command documentation**

Add `bin/arq-clear-snapshots` beside the other `bin/` entries in `manifest`. Add one README command bullet explaining that Arq must be paused and the script manages both services around targeted snapshot removal.

- [ ] **Step 2: Verify and deploy the manifest change**

Run:

```bash
homedir-manager install --dry-run
homedir-manager install
```

Expected: `~/bin/arq-clear-snapshots` becomes a symlink to the tracked script without replacing unrelated files.

- [ ] **Step 3: Run a safe live no-op verification**

First confirm `diskutil apfs listSnapshots /System/Volumes/Data` has no Arq-prefixed snapshot. Then run `~/bin/arq-clear-snapshots --yes` only in that no-op state.

Expected: it reports no Arq snapshots and exits 0 without invoking `sudo` or changing services.

- [ ] **Step 4: Run final repository verification**

Run:

```bash
sh test/run.sh
git diff --check
git status --short
```

Expected: all tests pass, no whitespace errors, and only intentional tracked changes are present.

- [ ] **Step 5: Commit deployment metadata**

```bash
git add manifest README.md
git commit -m "Deploy Arq snapshot cleaner through dotfiles"
```
