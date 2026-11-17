# Periodic git snapshot of the Obsidian vault.
#
# Configured through the environment rather than baked-in Nix interpolation so
# it can be exercised against a throwaway repo with no Nix and no launchd:
#   OBSIDIAN_BACKUP_VAULT   path to the vault work tree
#   OBSIDIAN_BACKUP_REMOTE  remote name to push to
#   OBSIDIAN_BACKUP_MAX_MB  per-file ceiling, in MB
#
# Every path expansion is quoted. The real vault lives at
# "~/Documents/Obsidian Vault" -- an unquoted $vault would split on the space
# and operate on the wrong directory.
set -uo pipefail

vault="${OBSIDIAN_BACKUP_VAULT:?OBSIDIAN_BACKUP_VAULT is not set}"
remote="${OBSIDIAN_BACKUP_REMOTE:-origin}"
max_mb="${OBSIDIAN_BACKUP_MAX_MB:-50}"

# Preflight. A backup that silently backs up nothing is worse than one that
# errors, so each of these is fatal rather than a skip.
if [ ! -d "$vault" ]; then
  echo "obsidian-backup: vault path does not exist: $vault" >&2
  exit 1
fi
cd "$vault" || exit 1
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "obsidian-backup: not a git work tree: $vault" >&2
  exit 1
fi
if ! git remote get-url "$remote" >/dev/null 2>&1; then
  echo "obsidian-backup: remote '$remote' is not configured in $vault" >&2
  exit 1
fi

git add -A

# Self-gate. This is the whole of "has anything changed" -- no watcher, no
# state file. Exit silently so a quiet half-hour leaves nothing in the log.
if git diff --cached --quiet; then
  exit 0
fi

# Size guard, before the commit because history is permanent: a large file
# committed once stays in every clone forever and only a history rewrite
# removes it. This is what replaces Git LFS in this design.
max_bytes=$((max_mb * 1024 * 1024))
oversized=""
while IFS= read -r -d '' f; do
  [ -f "$f" ] || continue # skip staged deletions
  size=$(wc -c <"$f" | tr -d ' ')
  if [ "$size" -gt "$max_bytes" ]; then
    oversized="${oversized}  ${f} ($((size / 1024 / 1024)) MB)"$'\n'
  fi
done < <(git diff --cached --name-only -z)

if [ -n "$oversized" ]; then
  git reset -q
  {
    echo "obsidian-backup: refusing to commit, file(s) exceed ${max_mb}MB:"
    printf '%s' "$oversized"
    echo "Remove or shrink them; git history is permanent."
  } >&2
  exit 1
fi

# Commit message. A bare timestamp 48 times a day produces history nobody can
# navigate; the point of this archive is being scannable during a recovery.
status=$(git diff --cached --name-status)
count_of() { printf '%s\n' "$status" | grep -c "^$1" || true; }
added=$(count_of A)
modified=$(count_of M)
deleted=$(count_of D)
renamed=$(count_of R)

subject="backup:"
sep=" "
for pair in "$added added" "$modified modified" "$deleted deleted" "$renamed renamed"; do
  n="${pair%% *}"
  if [ "$n" -gt 0 ]; then
    subject="${subject}${sep}${pair}"
    sep=", "
  fi
done

total=$(printf '%s\n' "$status" | wc -l | tr -d ' ')
body=$(printf '%s\n' "$status" | head -20)
if [ "$total" -gt 20 ]; then
  body="${body}"$'\n'"... and $((total - 20)) more"
fi

git commit -q -m "$subject" -m "$body"

# Plain push. Never --force, never --force-with-lease: an unattended job must
# not decide whose history wins. The commit is already safe locally, so a
# failed push costs nothing but a log line and the next run retries.
if ! git push -q "$remote" HEAD; then
  echo "obsidian-backup: push to '$remote' failed; refusing to force. Resolve by hand." >&2
  exit 1
fi
