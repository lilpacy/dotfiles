#!/usr/bin/env bash
set -euo pipefail

# Usage: send.sh <team> <from> <to> <message>

TEAM="${1:?Usage: send.sh <team> <from> <to> <message>}"
FROM="${2:?Missing from agent}"
TO="${3:?Missing to agent}"
BODY="${4:?Missing message body}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib/storage.sh"
DB="$(agmsg_db_path)"

[ -f "$DB" ] || bash "$SCRIPT_DIR/internal/init-db.sh" >/dev/null

# Escape EVERY interpolated value as a SQL string literal, not just body: a
# team/agent name containing a single quote would otherwise break the INSERT
# (correctness) or change its meaning (injection surface).
_agmsg_sqlesc() { printf %s "$1" | sed "s/'/''/g"; }
INSERT="INSERT INTO messages (team, from_agent, to_agent, body) VALUES ('$(_agmsg_sqlesc "$TEAM")', '$(_agmsg_sqlesc "$FROM")', '$(_agmsg_sqlesc "$TO")', '$(_agmsg_sqlesc "$BODY")');"

# Retry once after ensuring the schema. Under a concurrent first-write fan-out
# (leader → N members against a fresh/override store), one process can see the
# DB file exist before the winning initializer has finished creating the table,
# so its INSERT would hit "no such table". init-db.sh is idempotent + uses the
# busy_timeout, so re-running it waits for the schema, then the INSERT lands.
# See #114.
# Pipe the SQL via stdin (not as an argv) so a large body cannot overflow the
# OS command-line limit (the "Argument list too long" crash).
if ! printf '%s
' "$INSERT" | agmsg_sqlite "$DB" 2>/dev/null; then
  bash "$SCRIPT_DIR/internal/init-db.sh" >/dev/null
  printf '%s
' "$INSERT" | agmsg_sqlite "$DB"
fi

echo "Sent to $TO in team $TEAM"
