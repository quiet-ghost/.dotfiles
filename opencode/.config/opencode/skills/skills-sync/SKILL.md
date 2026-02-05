---
name: skills-sync
description: Sync skills repository, pull updates, and automatically manage symlinks in ~/.config/opencode/skills/. Creates symlinks for new skills, removes symlinks for deleted skills, and shows detailed summary of changes.
---

## What I Do

I keep your opencode skills synchronized with the upstream repository at `/home/ghost/dev/repos/skills`:

1. Check for updates in the skills repository
2. Pull latest changes (fast-forward only, safe)
3. Sync symlinks in `~/.config/opencode/skills/`:
   - Create symlinks for new skills found in the repo
   - Remove symlinks for skills that no longer exist
   - Clean up any broken symlinks
4. Show a detailed summary of all changes

## When to Use Me

Ask me to "sync my skills" or "update skills" and I'll handle everything automatically. I should be run periodically to keep your skills up-to-date.

## How I Work

When you invoke me, I will:

1. Navigate to `/home/ghost/dev/repos/skills`
2. Run `git fetch origin` to check for remote changes
3. Check if local branch is behind origin/main
4. If updates exist:
   - Capture the list of new commits (for the summary)
   - Run `git pull --ff-only` to safely pull changes
   - If pull fails due to local changes, warn you and stop
5. Scan the skills directory in the repo
6. Compare with current symlinks in `~/.config/opencode/skills/`
7. For each skill in the repo:
   - Verify it has a valid `SKILL.md` file
   - Create symlink in `~/.config/opencode/skills/` if missing
8. For each symlink in `~/.config/opencode/skills/`:
   - If the target skill no longer exists in repo, remove the symlink
   - If the symlink is broken (points to non-existent location), remove it
   - Skip skills-sync (I manage myself, I'm not symlinked)
9. Display summary showing:
   - Number of new commits pulled
   - New skills added (with names)
   - Skills removed (with names)
   - Total skills now available
   - Any errors or warnings

## Safety Measures

- **Never push**: I only pull from the remote repository
- **Fast-forward only**: I use `--ff-only` to avoid merge conflicts
- **Local changes protection**: If you have uncommitted local changes, I warn you and skip the update
- **Symlink only**: I only create/remove symlinks, never touch the actual skill files in the repo
- **Validation**: I verify each skill has a SKILL.md before creating symlinks

## Directory Structure

```
~/.config/opencode/skills/          # Skills live here (opencode reads from here)
├── skills-sync/                     # Me! (standalone, not symlinked)
│   └── SKILL.md
├── cloudflare -> /home/ghost/dev/repos/skills/skills/cloudflare  (symlink)
├── vim -> /home/ghost/dev/repos/skills/skills/vim               (symlink)
└── ... (other symlinks)

/home/ghost/dev/repos/skills/        # Actual repo (upstream source)
├── skills/
│   ├── cloudflare/SKILL.md
│   ├── vim/SKILL.md
│   └── ...
└── (other repo files)
```

## Expected Output

After running, you should see something like:

```
=== Skills Sync Summary ===

Repository: /home/ghost/dev/repos/skills
Status: Successfully updated

New commits pulled (3):
  a1b2c3d Add cloudflare D1 database examples
  e4f5g6h Update vim.lsp API reference
  i7j8k9l Fix printf_debug formatting

Skills Added (1):
  - cloudflare-d1 (symlink created)

Skills Removed (0):
  - None

Skills Updated (2):
  - cloudflare
  - vim.lsp

Total skills available: 7

Next sync: Run "sync my skills" anytime or wait for automatic check
```

## Troubleshooting

**If sync fails due to local changes:**
- The repo at `/home/ghost/dev/repos/skills` has uncommitted changes
- Options: Commit your changes, stash them, or discard them
- Then run "sync my skills" again

**If a skill isn't showing up:**
- Check that it has a valid `SKILL.md` in the repo
- Verify the symlink was created: `ls -la ~/.config/opencode/skills/`
- Check opencode can read it: the skill should appear in available skills list

**If opencode doesn't see new skills:**
- Restart opencode to refresh the skill cache
- Or wait a moment - skill discovery happens automatically
