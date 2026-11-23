# Periodic git snapshot of the Obsidian vault, plus the controls for pausing it.
#
#   obsidian-backup run             take a snapshot now (what the agent calls)
#   obsidian-backup pause [4h]      stop snapshotting for a while
#   obsidian-backup resume          start again
#   obsidian-backup status          what it is doing (also the bare default)
#
# Configured through the environment rather than baked-in Nix interpolation so
# it can be exercised against a throwaway repo with no Nix and no launchd:
#   OBSIDIAN_BACKUP_VAULT      path to the vault work tree
#   OBSIDIAN_BACKUP_REMOTE     remote name to push to
#   OBSIDIAN_BACKUP_MAX_MB     per-file ceiling, in MB
#   OBSIDIAN_BACKUP_STATE_DIR  where the pause marker lives
#   OBSIDIAN_BACKUP_LABEL      launchd label, for the agent line in `status`
#
# Every path expansion is quoted. The real vault lives at
# "~/Documents/Obsidian Vault" -- an unquoted $vault would split on the space
# and operate on the wrong directory.
set -uo pipefail

vault="${OBSIDIAN_BACKUP_VAULT-}"
remote="${OBSIDIAN_BACKUP_REMOTE:-origin}"
max_mb="${OBSIDIAN_BACKUP_MAX_MB:-50}"
state_dir="${OBSIDIAN_BACKUP_STATE_DIR:-${XDG_STATE_HOME:-$HOME/.local/state}/obsidian-backup}"
label="${OBSIDIAN_BACKUP_LABEL-}"
pause_file="$state_dir/paused"

usage() {
  echo "usage: obsidian-backup [run|pause [DURATION]|resume|status]" >&2
  echo "       DURATION is a number followed by m, h or d (default 4h)" >&2
}

# GNU date first, BSD second. The agent gets coreutils on PATH, but this script
# is also run straight from a shell during testing, where /bin/date is BSD.
fmt_epoch() {
  date -d "@$1" '+%Y-%m-%d %H:%M' 2>/dev/null || date -r "$1" '+%Y-%m-%d %H:%M'
}

fmt_remaining() {
  local h m
  h=$(($1 / 3600))
  m=$((($1 % 3600) / 60))
  if [ "$h" -gt 0 ]; then
    printf '%dh %dm' "$h" "$m"
  else
    printf '%dm' "$m"
  fi
}

parse_duration() {
  local spec="$1" n u
  n="${spec%[mhd]}"
  u="${spec#"$n"}"
  case "$n" in '' | *[!0-9]*) return 1 ;; esac
  [ "$n" -gt 0 ] || return 1
  case "$u" in
  m) printf '%s' "$((n * 60))" ;;
  h) printf '%s' "$((n * 3600))" ;;
  d) printf '%s' "$((n * 86400))" ;;
  *) return 1 ;;
  esac
}

# Prints the deadline and returns 0 while a pause is in force. An elapsed pause
# clears itself: forgetting to resume costs a few hours of history, not all of
# it, which is the whole reason the marker carries a deadline instead of a flag.
pause_deadline() {
  [ -f "$pause_file" ] || return 1
  local until
  until=$(cat "$pause_file" 2>/dev/null || true)
  case "$until" in '' | *[!0-9]*)
    rm -f "$pause_file"
    return 1
    ;;
  esac
  if [ "$(date +%s)" -ge "$until" ]; then
    rm -f "$pause_file"
    return 1
  fi
  printf '%s' "$until"
}

need_vault() {
  if [ -z "$vault" ]; then
    echo "obsidian-backup: OBSIDIAN_BACKUP_VAULT is not set" >&2
    exit 1
  fi
}

# Preflight. A backup that silently backs up nothing is worse than one that
# errors, so each of these is fatal rather than a skip.
preflight() {
  need_vault
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
  local top
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
}

cmd_pause() {
  local secs
  if ! secs=$(parse_duration "${1:-4h}"); then
    echo "obsidian-backup: '${1:-}' is not a duration -- use 30m, 4h or 2d" >&2
    exit 2
  fi
  local until
  until=$(($(date +%s) + secs))
  mkdir -p "$state_dir"
  printf '%s\n' "$until" >"$pause_file"
  echo "obsidian-backup: paused until $(fmt_epoch "$until") ($(fmt_remaining "$secs") from now)"
}

cmd_resume() {
  if [ -f "$pause_file" ]; then
    rm -f "$pause_file"
    # Deliberately does NOT snapshot here. Resuming is how you say "I am done
    # drafting", not "commit whatever is lying around this instant" -- the next
    # scheduled run picks it up.
    echo "obsidian-backup: resumed; the next scheduled run will snapshot."
  else
    echo "obsidian-backup: not paused."
  fi
}

cmd_status() {
  local until
  if until=$(pause_deadline); then
    echo "state    paused until $(fmt_epoch "$until") ($(fmt_remaining "$((until - $(date +%s)))") left)"
  else
    echo "state    active"
  fi

  if [ -n "$label" ] && [ -x /bin/launchctl ]; then
    if /bin/launchctl print "gui/$(id -u)/$label" >/dev/null 2>&1; then
      echo "agent    loaded"
    else
      echo "agent    NOT loaded -- nothing is scheduled"
    fi
  fi

  need_vault
  echo "vault    $vault"
  if [ ! -d "$vault" ] || ! git -C "$vault" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "repo     not a git work tree"
    return 0
  fi
  echo "changes  $(git -C "$vault" status --porcelain | wc -l | tr -d ' ') uncommitted"
  echo "last     $(git -C "$vault" log -1 --pretty='%h %s -- %cd' --date=format:'%Y-%m-%d %H:%M' 2>/dev/null || echo 'no commits yet')"

  local branch head upstream
  branch=$(git -C "$vault" branch --show-current 2>/dev/null || true)
  if [ -n "$branch" ] && head=$(git -C "$vault" rev-parse HEAD 2>/dev/null) &&
    upstream=$(git -C "$vault" rev-parse "$remote/$branch" 2>/dev/null); then
    if [ "$head" = "$upstream" ]; then
      echo "remote   in sync with $remote/$branch"
    else
      echo "remote   AHEAD of $remote/$branch -- the last push did not land"
    fi
  else
    echo "remote   no $remote/$branch to compare against"
  fi
}

cmd_run() {
  preflight

  # Pause gate, before `git add -A`. Staging is exactly what must not happen
  # while paused: the point of pausing is to keep the index and the working
  # tree usable as a drafting surface, and `git add -A` would flatten the
  # distinction between a draft and something meant to be committed.
  if pause_deadline >/dev/null; then
    exit 0
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
  local secrets ignore_removed
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
  local max_bytes oversized f size
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
  #
  # quotePath=false: it defaults on, and octal-escaping every accented note name
  # ("Caf\303\251") makes the one thing this archive exists for -- being
  # scannable during a recovery -- unreadable.
  local status added modified deleted renamed subject sep pair n total body
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
}

case "${1:-status}" in
run) cmd_run ;;
pause) cmd_pause "${2:-4h}" ;;
resume) cmd_resume ;;
status) cmd_status ;;
-h | --help | help)
  usage
  exit 0
  ;;
*)
  echo "obsidian-backup: unknown command '$1'" >&2
  usage
  exit 2
  ;;
esac
