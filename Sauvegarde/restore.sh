#!/bin/bash
set -euo pipefail

# Configuration manuelle (optionnel)
# Renseigne ici l'utilisateur GPG si tu ne veux pas utiliser la variable exportee GPG_EXEC_USER.
MANUAL_GPG_EXEC_USER=""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${PASSBOLT_ENV_FILE:-$SCRIPT_DIR/../Installation/passbolt.env}"

if [ -f "$ENV_FILE" ]; then
  set -a
  . "$ENV_FILE"
  set +a
fi

PASSBOLT_BASE_PATH="${PASSBOLT_BASE_PATH:-/app/passbolt}"
BACKUP_FILE="${1:-}"
GPG_EXEC_USER="${MANUAL_GPG_EXEC_USER:-${GPG_EXEC_USER:-${SUDO_USER:-}}}"

if [ -z "$BACKUP_FILE" ]; then
  echo "Usage: ./restore.sh <backup_file.tar.gz.gpg>"
  exit 1
fi

WORKDIR="/tmp/passbolt_restore"
DB_CONTAINER="db"
PASSBOLT_CONTAINER="passbolt"

if [ -n "$GPG_EXEC_USER" ] && [ "$EUID" -eq 0 ]; then
  GPG_EXEC_HOME=$(getent passwd "$GPG_EXEC_USER" | cut -d: -f6)
  if [ -z "$GPG_EXEC_HOME" ]; then
    echo "Erreur: impossible de determiner le HOME de l'utilisateur GPG '$GPG_EXEC_USER'."
    exit 1
  fi
  GPG_CMD=(sudo -u "$GPG_EXEC_USER" env HOME="$GPG_EXEC_HOME" gpg)
else
  GPG_CMD=(gpg)
fi

if [ ! -f "$BACKUP_FILE" ]; then
  echo "Erreur: fichier backup introuvable: $BACKUP_FILE"
  exit 1
fi

if [ -f "$BACKUP_FILE.sha256" ]; then
  echo "[0/6] Verification checksum SHA256..."
  sha256sum -c "$BACKUP_FILE.sha256"
fi

cleanup() {
  rm -rf "$WORKDIR"
}
trap cleanup EXIT

echo "[1/6] Dechiffrement du backup..."
mkdir -p "$WORKDIR"
if [ -n "$GPG_EXEC_USER" ] && [ "$EUID" -eq 0 ]; then
  echo "Dechiffrement avec le trousseau GPG de '$GPG_EXEC_USER'..."
else
  echo "Dechiffrement avec le trousseau GPG de l'utilisateur '$(id -un)'..."
fi
"${GPG_CMD[@]}" --batch --yes --decrypt "$BACKUP_FILE" > "$WORKDIR/restore.tar.gz"

echo "[2/6] Extraction de l'archive..."
tar -xzf "$WORKDIR/restore.tar.gz" -C "$WORKDIR"

echo "[3/6] Restauration de la base de donnees..."
MYSQL_USER=$(sudo docker exec "$DB_CONTAINER" printenv MYSQL_USER)
MYSQL_PASSWORD=$(sudo docker exec "$DB_CONTAINER" printenv MYSQL_PASSWORD)
MYSQL_DATABASE=$(sudo docker exec "$DB_CONTAINER" printenv MYSQL_DATABASE)

sudo docker exec -i -e MYSQL_PWD="$MYSQL_PASSWORD" "$DB_CONTAINER" \
  mariadb -u"$MYSQL_USER" "$MYSQL_DATABASE" < "$WORKDIR/db.sql"

echo "[4/6] Restauration des volumes Passbolt..."
sudo mkdir -p "$PASSBOLT_BASE_PATH/gpg_volume" "$PASSBOLT_BASE_PATH/jwt_volume"
sudo cp -a "$WORKDIR/gpg_volume/." "$PASSBOLT_BASE_PATH/gpg_volume/"
sudo cp -a "$WORKDIR/jwt_volume/." "$PASSBOLT_BASE_PATH/jwt_volume/"

echo "[5/6] Verification des permissions..."
sudo chown -R www-data:www-data "$PASSBOLT_BASE_PATH/gpg_volume"
sudo chown -R www-data:www-data "$PASSBOLT_BASE_PATH/jwt_volume"

echo "[6/6] Redemarrage des conteneurs..."
sudo docker restart "$DB_CONTAINER"
sudo docker restart "$PASSBOLT_CONTAINER"

echo "Restauration terminee avec succes."
