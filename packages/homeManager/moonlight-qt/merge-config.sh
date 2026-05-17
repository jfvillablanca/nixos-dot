#!/usr/bin/env bash
# Merge declared INI sections into an existing Qt QSettings config.
#
# Usage: merge-config.sh <target.conf> <source.conf>
#
# Sections and keys declared in <source> overwrite matches in <target>;
# any section or key not present in <source> is left untouched, so
# runtime state (pairings, certificates, the embedded client private
# key) survives home-manager activations. File mode is preserved
# across runs and defaults to 0600 on first creation.
set -euo pipefail

target="$1"
source="$2"

mkdir -p "$(dirname "$target")"

if [ -f "$target" ]; then
  mode=$(stat -c '%a' "$target")
else
  # Contains private key material on first creation.
  mode=600
  : >"$target"
fi

# Ensure owner-write while we update.
chmod u+w "$target"

tmp=$(mktemp)
awk -v src="$source" '
BEGIN {
    cur = ""
    while ((getline line < src) > 0) {
        if (line ~ /^\[.*\]$/) {
            cur = substr(line, 2, length(line) - 2)
            src_sections[cur] = 1
        } else if (length(line) > 0 \
                   && substr(line, 1, 1) != "#" \
                   && substr(line, 1, 1) != ";") {
            eq = index(line, "=")
            if (eq > 0 && cur != "") {
                key = substr(line, 1, eq - 1)
                val = substr(line, eq + 1)
                src_data[cur, key] = val
            }
        }
    }
    close(src)
    target_section = ""
}

function flush_section(   combo, parts) {
    if (target_section in src_sections) {
        for (combo in src_data) {
            split(combo, parts, SUBSEP)
            if (parts[1] == target_section \
                && !((target_section, parts[2]) in written)) {
                print parts[2] "=" src_data[target_section, parts[2]]
                written[target_section, parts[2]] = 1
            }
        }
    }
}

/^\[.*\]$/ {
    flush_section()
    print
    target_section = substr($0, 2, length($0) - 2)
    seen_section[target_section] = 1
    next
}

{
    eq = index($0, "=")
    if (eq > 0 && target_section != "") {
        key = substr($0, 1, eq - 1)
        if ((target_section, key) in src_data) {
            print key "=" src_data[target_section, key]
            written[target_section, key] = 1
            next
        }
    }
    print
}

END {
    flush_section()
    for (s in src_sections) {
        if (!(s in seen_section)) {
            print ""
            print "[" s "]"
            for (combo in src_data) {
                split(combo, parts, SUBSEP)
                if (parts[1] == s && !((s, parts[2]) in written)) {
                    print parts[2] "=" src_data[s, parts[2]]
                    written[s, parts[2]] = 1
                }
            }
        }
    }
}
' "$target" >"$tmp"

mv "$tmp" "$target"
chmod "$mode" "$target"
