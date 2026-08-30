# Idempotent CouchDB provisioning for Self-hosted LiveSync.
#
# Upstream's provisioner hands clients the server administrator credential --
# docs/setup_own_server.md states it "does not create a separate
# non-administrator synchronisation account". Behind a public Funnel endpoint
# that credential could rewrite server configuration and read every database,
# so this creates a members-only account scoped to the vault database instead.
#
# Environment: COUCH_URL, DATABASE, ADMIN_USER, ADMIN_PASSWORD_FILE, SYNC_USER,
# SYNC_PASSWORD_FILE. Passwords are read from files so they never appear in the
# unit definition, the store, or the process table.

admin_password=$(cat "$ADMIN_PASSWORD_FILE")

# Credentials go through a curl config file rather than --user, which would put
# the password in argv where any local user could read it out of `ps`.
curl_admin() {
  curl --fail --silent --show-error \
    --config <(printf 'user = "%s:%s"\n' "$ADMIN_USER" "$admin_password") \
    "$@"
}

status_admin() {
  curl --silent --output /dev/null --write-out '%{http_code}' \
    --config <(printf 'user = "%s:%s"\n' "$ADMIN_USER" "$admin_password") \
    "$@"
}

# 1. Wait for CouchDB. require_valid_user is on, so even /_up needs credentials.
for _ in $(seq 1 60); do
  if curl_admin "$COUCH_URL/_up" >/dev/null 2>&1; then
    break
  fi
  sleep 1
done
curl_admin "$COUCH_URL/_up" >/dev/null

# 2. System databases. Normally created by _cluster_setup, which this module
# skips because it would also rewrite bind_address to 0.0.0.0. 412 means the
# database already exists.
for db in _users _replicator _global_changes; do
  code=$(status_admin -X PUT "$COUCH_URL/$db")
  case "$code" in
  201 | 202 | 412) ;;
  *)
    echo "creating $db failed: HTTP $code" >&2
    exit 1
    ;;
  esac
done

# 3. The vault database.
code=$(status_admin -X PUT "$COUCH_URL/$DATABASE")
case "$code" in
201 | 202 | 412) ;;
*)
  echo "creating $DATABASE failed: HTTP $code" >&2
  exit 1
  ;;
esac

# 4. The sync account. Upserted rather than created, so changing the password
# in sops and rebuilding is a complete rotation. CouchDB hashes the plaintext
# `password` field itself using chttpd_auth/iterations.
#
# The existing revision is fetched in two steps -- a status check, then a body
# fetch only on 200 -- rather than swallowing curl's exit code with
# `|| true`. That would mask a real failure (network blip, permission error)
# as "no existing document", surfacing later as a confusing 409 on the PUT
# below instead of an actionable message here.
user_doc="org.couchdb.user:$SYNC_USER"
code=$(status_admin "$COUCH_URL/_users/$user_doc")
case "$code" in
200)
  rev=$(curl_admin "$COUCH_URL/_users/$user_doc" | jq -r '._rev // empty')
  ;;
404)
  rev=""
  ;;
*)
  echo "checking $user_doc failed: HTTP $code" >&2
  exit 1
  ;;
esac

# --rawfile reads the password straight from its file into jq rather than
# through a shell variable passed as --arg. jq is an external binary in
# runtimeInputs, so an --arg value becomes part of jq's own argv and is
# readable from /proc/<pid>/cmdline for the life of the call -- the same
# hazard --config avoids for curl above, just one step removed. rtrimstr
# strips the trailing newline a password file conventionally ends with,
# which --rawfile (unlike the `cat` command substitution used for
# admin_password) does not do on its own.
jq -n \
  --arg name "$SYNC_USER" \
  --rawfile password "$SYNC_PASSWORD_FILE" \
  --arg rev "$rev" \
  '{name: $name, password: ($password | rtrimstr("\n")), roles: [], type: "user"}
   + (if $rev == "" then {} else {_rev: $rev} end)' |
  curl_admin -X PUT -H 'Content-Type: application/json' \
    --data @- "$COUCH_URL/_users/$user_doc" >/dev/null

# 5. Scope the account to this database only. An empty admins list means the
# sync user cannot alter _security itself.
jq -n --arg name "$SYNC_USER" \
  '{admins: {names: [], roles: []}, members: {names: [$name], roles: []}}' |
  curl_admin -X PUT -H 'Content-Type: application/json' \
    --data @- "$COUCH_URL/$DATABASE/_security" >/dev/null

echo "obsidian-sync: provisioned $DATABASE for $SYNC_USER"
