#!/usr/bin/env bash
# Baut die PG-Testdatenbank neu auf: DB neu, deploy, Datenkopie aus MSSQL-Test, post.
# Nur für Testinstanzen! Erwartet TEST_PG_DSN (DB energydwh) und TEST_MSSQL_CONN.
set -euo pipefail
cd "$(dirname "$0")/.."
admin_dsn="${TEST_PG_DSN%/*}/postgres"
uv run python - "$admin_dsn" <<'EOF'
import sys, psycopg
with psycopg.connect(sys.argv[1], autocommit=True) as c:
    c.execute("DROP DATABASE IF EXISTS energydwh WITH (FORCE)")
    c.execute("CREATE DATABASE energydwh TEMPLATE template0 ENCODING 'UTF8' "
              "LOCALE_PROVIDER icu ICU_LOCALE 'de-DE' LOCALE 'C.UTF-8'")
EOF
export PG_DSN="$TEST_PG_DSN" MSSQL_CONN="$TEST_MSSQL_CONN"
uv run energydwh deploy | tail -1
uv run energydwh copy -j 6 | tail -1
uv run energydwh post 2>/dev/null | tail -1
