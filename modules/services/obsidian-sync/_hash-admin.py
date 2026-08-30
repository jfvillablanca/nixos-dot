#!/usr/bin/env python3
"""Render CouchDB's [admins] ini stanza with a pre-hashed password.

CouchDB 3.5.1 stores administrator passwords as

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

with open(password_file, "rb") as handle:
    password = handle.read().strip()

if not password:
    sys.exit(f"{password_file} is empty; refusing to configure a blank admin password")

salt = os.urandom(16).hex()
derived = hashlib.pbkdf2_hmac("sha256", password, salt.encode(), iterations, 32).hex()

print("[admins]")
print(f"{user} = -pbkdf2:sha256-{derived},{salt},{iterations}")
