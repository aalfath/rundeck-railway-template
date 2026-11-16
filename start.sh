#!/bin/bash
# Railway wrapper for the official Rundeck image.
set -euo pipefail

RD_HOME=/home/rundeck

# 1. Admin login. The image ships admin:admin and user:user; replace them.
if [[ -z "${RUNDECK_ADMIN_PASSWORD:-}" ]]; then
  echo "ERROR: RUNDECK_ADMIN_PASSWORD is empty. Set it to a long random value." >&2
  exit 1
fi
case "${RUNDECK_ADMIN_PASSWORD}" in
  *,*|*:*) echo "ERROR: RUNDECK_ADMIN_PASSWORD must not contain ',' or ':'." >&2; exit 1 ;;
esac
ADMIN_USER="${RUNDECK_ADMIN_USER:-admin}"
umask 077
cat > "${RD_HOME}/server/config/realm.properties" <<REALM
# Written at start from RUNDECK_ADMIN_USER / RUNDECK_ADMIN_PASSWORD (Railway variables).
${ADMIN_USER}:${RUNDECK_ADMIN_PASSWORD},user,admin
REALM
chown rundeck:root "${RD_HOME}/server/config/realm.properties"
chmod 600 "${RD_HOME}/server/config/realm.properties"
umask 022

# 2. Public URL. Railway terminates TLS, so trust X-Forwarded-* headers.
if [[ -z "${RUNDECK_GRAILS_URL:-}" && -n "${RAILWAY_PUBLIC_DOMAIN:-}" ]]; then
  export RUNDECK_GRAILS_URL="https://${RAILWAY_PUBLIC_DOMAIN}"
fi
export RUNDECK_SERVER_FORWARDED="${RUNDECK_SERVER_FORWARDED:-true}"

# 3. Database: Postgres when PG* variables are present, else the image's H2 default.
if [[ -z "${RUNDECK_DATABASE_URL:-}" && -n "${PGHOST:-}" ]]; then
  export RUNDECK_DATABASE_DRIVER="org.postgresql.Driver"
  export RUNDECK_DATABASE_URL="jdbc:postgresql://${PGHOST}:${PGPORT:-5432}/${PGDATABASE:-railway}"
  export RUNDECK_DATABASE_USERNAME="${PGUSER:-postgres}"
  export RUNDECK_DATABASE_PASSWORD="${PGPASSWORD:-}"
fi

# 4. Key storage and project config encryption (both stored in the database).
if [[ -n "${RUNDECK_ENCRYPTION_PASSWORD:-}" ]]; then
  export RUNDECK_STORAGE_CONVERTER_1_CONFIG_PASSWORD="${RUNDECK_STORAGE_CONVERTER_1_CONFIG_PASSWORD:-$RUNDECK_ENCRYPTION_PASSWORD}"
  export RUNDECK_CONFIG_STORAGE_CONVERTER_1_CONFIG_PASSWORD="${RUNDECK_CONFIG_STORAGE_CONVERTER_1_CONFIG_PASSWORD:-$RUNDECK_ENCRYPTION_PASSWORD}"
fi
unset RUNDECK_ENCRYPTION_PASSWORD RUNDECK_ADMIN_PASSWORD

# 5. Persistent data: execution logs and local files live in /home/rundeck/var
#    (a Railway volume). New volumes are owned by root, so hand them to rundeck.
mkdir -p "${RD_HOME}/var/logs" "${RD_HOME}/var/tmp"
if [[ "$(stat -c %u "${RD_HOME}/var")" != "1000" || "$(stat -c %u "${RD_HOME}/var/logs")" != "1000" ]]; then
  chown -R rundeck:root "${RD_HOME}/var"
fi
chown rundeck:root "${RD_HOME}/var/logs" "${RD_HOME}/var/tmp"

# 6. Listen on Railway's PORT (default 4440) and start Rundeck as the rundeck user.
PORT="${PORT:-4440}"
cd "${RD_HOME}"
exec setpriv --reuid=rundeck --regid=root --init-groups \
  env HOME="${RD_HOME}" USER=rundeck \
  "${RD_HOME}/docker-lib/entry.sh" -Dserver.port="${PORT}" -Dserver.http.port="${PORT}" "$@"
