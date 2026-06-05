# Auditing the dotfiles

These repos are public (`dotfiles`) and private (`dotfiles-private`) and deploy across a fleet
of machines. Run an audit periodically — and always before pushing something new — to catch the
things that rot silently: a leaked secret, a config that drifted out of deployment, a machine that
fell behind.

## The mechanical part: `dotfiles-audit`

`bin/dotfiles-audit` (on `PATH` once deployed) automates the checks that don't need judgement:

```sh
dotfiles-audit        # full report
dotfiles-audit -q     # findings + summary only
```

It checks, across **both** repos:

1. **Secret leaks** — scans every *tracked* file for credential shapes that must never be
   committed: private keys, `ops_…` (1Password service-account tokens), `ghp_…`/`github_pat_…`,
   `sk-…`, `xox?-…`, `AKIA…`, and suspicious tracked filenames (`.env`, `*.pem`, `*.key`,
   `credentials`). Any hit means **investigate and rotate** — a value in git history is burned
   even after deletion.
2. **Deploy drift** — every manifest entry (for this OS) exists in the repo and is actually
   symlinked into `$HOME`. Catches "added to the manifest but never ran `install.sh`" and broken
   links.
3. **Permissions** — local secret-bearing files (`~/.config/op/env`) are `600`.

Exit status is `0` clean / `1` with findings, so it drops into a pre-push hook or CI.

## The judgement part (do this by eye, ~quarterly)

The script can't decide these — walk them manually:

- **Coverage.** Skim `~/.config` and `$HOME` for new tool configs worth tracking, and tracked
  files no longer worth keeping. The manifest is the source of truth for what's managed.
- **Secret hygiene.** Confirm every secret a tool needs comes from `fnox`/`op`/`bw`, not a
  plaintext file. See [SECRETS.md](SECRETS.md). Any new plaintext credential found in `$HOME`
  should be moved into a manager and quarantined.
- **Fleet consistency.** Every machine on the same `HEAD`, same login shell, secrets resolving.
  Quick check from one host:
  ```sh
  for h in <host> …; do ssh "$h" 'git -C ~/git/dotfiles rev-parse --short HEAD'; done
  ```
- **Skills/agents drift.** Standalone skills under `~/.claude/skills` are versioned (individual
  manifest entries). If a host grew a new standalone skill, fold it into the repo; project-linked
  skills (symlinks into a project repo) are intentionally left per-host.

## When the audit finds a leak

1. Do **not** just delete the line — the value is already in history. Rotate the credential at its
   source first.
2. Remove it from the working tree, move the real value into a manager (SECRETS.md), and add the
   path/pattern to `.gitignore`.
3. If it was ever pushed, treat it as fully compromised regardless of later history rewrites.
