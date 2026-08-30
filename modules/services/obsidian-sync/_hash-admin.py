#!/usr/bin/env python3
"""Render CouchDB's [admins] ini stanza with a pre-hashed password.

CouchDB 3.5.2 stores administrator passwords as

    -pbkdf2:<prf>-<derived_key_hex>,<salt_hex>,<iterations>

(src/couch/src/couch_passwords.erl:45-57, parsed back in
src/couch/src/couch_auth_cache.erl:83). Writing the hashed form rather than the
plaintext matters: get_unhashed_admins/0 (couch_passwords.erl:68-88) treats this
prefix as already hashed and leaves it alone, whereas a plaintext value would be
hashed and persisted into /var/lib/couchdb/local.ini -- which is last in the
-couch_ini precedence chain, so the stale copy would win over Nix forever and
password rotation would silently stop working.

The salt is 16 random bytes rendered as 32 hex characters, matching
couch_uuids:random/0, and is fed to PBKDF2 as that hex *string*. The derived key
length equals the PRF digest size (couch_passwords.erl:95-97), so 32 bytes for
sha256.
"""

import hashlib
import os
import sys

user, password_file, iterations = sys.argv[1], sys.argv[2], int(sys.argv[3])

# 20 bytes of mixed-case-alnum-or-better is ~119 bits of entropy -- comfortably
# past what a slow hash would need to defend, which is the whole premise
# pbkdf2Iterations=10000 (see its option doc) relies on. This is a floor
# against a future rotation to a memorable password, not a target: keep
# generating long random secrets.
MIN_PASSWORD_LENGTH = 20

try:
    with open(password_file, "rb") as handle:
        # Trailing newlines only -- not other whitespace, not leading bytes.
        # This must match _provision.sh exactly: `$(cat file)` for the admin
        # password strips every trailing newline the same way, and the sync
        # password's `sub("\n+$"; "")` does too. Before this, this file used
        # Python's `.strip()` (all leading/trailing whitespace) while the
        # jq path used `rtrimstr("\n")` (exactly one trailing newline) --
        # a secret file ending in two newlines hashed a different string
        # here than the one actually sent over the wire.
        password = handle.read().rstrip(b"\n")
except FileNotFoundError:
    sys.exit(f"{password_file} does not exist; point adminPasswordFile/syncPasswordFile at a real secret")

if not password:
    sys.exit(f"{password_file} is empty; refusing to configure a blank admin password")

if len(password) < MIN_PASSWORD_LENGTH:
    sys.exit(
        f"{password_file}: password is {len(password)} bytes, below the "
        f"{MIN_PASSWORD_LENGTH}-byte floor; refusing to configure a low-entropy admin password"
    )

# _provision.sh embeds this password in a double-quoted curl config value
# (`user = "%s:%s"`). curl unescapes \" and \\ there (curl(1), config file
# format), so a password containing either would authenticate as a
# different string than the one hashed below -- a permanent 401 with no
# indication why.
if b'"' in password or b"\\" in password:
    sys.exit(f'{password_file}: password contains a literal " or \\, which curl unescapes inside its config file; choose a password without either')

salt = os.urandom(16).hex()
derived = hashlib.pbkdf2_hmac("sha256", password, salt.encode(), iterations, 32).hex()

print("[admins]")
print(f"{user} = -pbkdf2:sha256-{derived},{salt},{iterations}")
