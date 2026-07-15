#!/bin/sh
# Seed Pi-hole gravity with the adlists in adlists.list, then rebuild gravity.
# Runs inside the pihole container (see `make blocklists`). Idempotent:
# INSERT OR IGNORE means re-running never duplicates rows.
set -eu

LIST="${1:-/etc/pihole/infra-adlists.list}"
DB="/etc/pihole/gravity.db"

if [ ! -f "$DB" ]; then
	echo "gravity.db not found at $DB - has Pi-hole finished starting?" >&2
	exit 1
fi

count=0
while IFS= read -r line || [ -n "$line" ]; do
	# Strip inline/full-line comments and all whitespace (URLs have none).
	url=$(printf '%s' "$line" | sed 's/#.*//' | tr -d '[:space:]')
	[ -z "$url" ] && continue
	pihole-FTL sqlite3 "$DB" \
		"INSERT OR IGNORE INTO adlist (address, enabled, comment) VALUES ('$url', 1, 'infra-managed');"
	echo "  + $url"
	count=$((count + 1))
done <"$LIST"

echo "Ensured $count adlist(s) present; rebuilding gravity..."
pihole -g
