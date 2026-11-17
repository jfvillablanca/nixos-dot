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
# --is-inside-work-tree is true from any subdirectory, and pointing vaultPath
# one level down is silently catastrophic: `git add -A` stages the whole
# enclosing repository, while the size guard resolves its paths from the repo
# root and so matches nothing. Both guards would be off at once.
top=$(git rev-parse --show-toplevel)
if [ ! "$top" -ef "." ]; then
  echo "obsidian-backup: $vault is inside a git work tree but is not its root ($top)." >&2
  echo "obsidian-backup: refusing -- 'git add -A' would stage the whole enclosing repository." >&2
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

# Credential guard. The vault's .gitignore is the only thing keeping
# .obsidian/ out of this repository, and
# .obsidian/plugins/obsidian-livesync/data.json holds both the CouchDB
# password and the vault's end-to-end encryption passphrase. LiveSync
# replicates a deleted .gitignore like any other file, and `git add -A` would
# then stage those credentials straight into a repo that is pushed to GitHub.
# Undoing that costs a passphrase rotation, a full re-encryption of the vault
# and a history rewrite on a published remote, so refuse and wait for a human.
secrets=$(git diff --cached --name-only -z | tr '\0' '\n' | grep -E '^(\.obsidian/|\.trash/)' || true)
ignore_removed=$(git diff --cached --name-status -- .gitignore | grep '^D' || true)
if [ -n "$secrets" ] || [ -n "$ignore_removed" ]; then
  git reset -q
  {
    echo "obsidian-backup: refusing to commit -- the vault's ignore rules are not holding."
    if [ -n "$ignore_removed" ]; then
      echo "  .gitignore is staged for deletion"
    fi
    if [ -n "$secrets" ]; then
      echo "  these would have been committed:"
      head -10 <<<"$secrets" | sed 's/^/    /'
    fi
    echo "Restore .gitignore before the next run. .obsidian/ holds the LiveSync"
    echo "CouchDB password and the vault's end-to-end encryption passphrase."
  } >&2
  exit 1
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
# quotePath=false: it defaults on, and octal-escaping every accented note name
# ("Caf\303\251") makes the one thing this archive exists for -- being
# scannable during a recovery -- unreadable.
status=$(git -c core.quotePath=false diff --cached --name-status)
# Here-strings, not pipes. writeShellApplication runs this under errexit and
# pipefail, and on a bulk change -- a restored backup, a vault re-import -- the
# status text exceeds the 64 KiB pipe buffer. `head -20` then exits first,
# `printf` dies of SIGPIPE, pipefail turns that into 141, and errexit aborts
# the job with nothing written to either log. A here-string uses a temp file,
# so there is no reader to disappear.
count_of() { grep -c "^$1" <<<"$status" || true; }
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

total=$(wc -l <<<"$status" | tr -d ' ')
body=$(head -20 <<<"$status")
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
