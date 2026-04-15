#!/bin/bash
set -euo pipefail

# Configuration manuelle GPG
# Renseigne ici la cle GPG et l'utilisateur GPG utilises par le script.
MANUAL_GPG_KEY=""
MANUAL_GPG_EXEC_USER=""
# Renseigne ici un dossier de backup fixe (recommande pour cron).
# Exemple : MANUAL_BACKUP_DIR="/mnt/backup/passbolt"
MANUAL_BACKUP_DIR=""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${PASSBOLT_ENV_FILE:-$SCRIPT_DIR/../Installation/passbolt.env}"

if [ -f "$ENV_FILE" ]; then
  set -a
  . "$ENV_FILE"
  set +a
fi

PASSBOLT_BASE_PATH="${PASSBOLT_BASE_PATH:-/app/passbolt}"
BACKUP_DIR="${MANUAL_BACKUP_DIR:-${BACKUP_DIR:-$PASSBOLT_BASE_PATH/backup}}"
DB_CONTAINER="db"
PASSBOLT_CONTAINER="passbolt"
DATE=$(date +"%Y-%m-%d_%H-%M-%S")
ARCHIVE="$BACKUP_DIR/passbolt_backup_$DATE.tar.gz"
MAX_BACKUPS=10
GPG_KEY="${MANUAL_GPG_KEY:-${GPG_KEY:-}}"
GPG_EXEC_USER="${MANUAL_GPG_EXEC_USER:-${GPG_EXEC_USER:-${SUDO_USER:-}}}"

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

if [ -z "$GPG_KEY" ]; then
  echo "Erreur: variable GPG_KEY non definie."
  echo "Definis MANUAL_GPG_KEY en haut du script avant execution."
  exit 1
fi

echo "Verification de la cle GPG de destination..."
if ! "${GPG_CMD[@]}" --list-keys "$GPG_KEY" >/dev/null 2>&1; then
  echo "Erreur: la cle GPG '$GPG_KEY' est introuvable dans le trousseau utilise par le script."
  if [ -n "$GPG_EXEC_USER" ] && [ "$EUID" -eq 0 ]; then
    echo "Trousseau utilise: utilisateur '$GPG_EXEC_USER'."
  else
    echo "Trousseau utilise: utilisateur courant '$(id -un)'."
  fi
  exit 1
fi

mkdir -p "$BACKUP_DIR"

echo "[1/7] Recuperation des variables DB..."
MYSQL_USER=$(sudo docker exec "$DB_CONTAINER" printenv MYSQL_USER)
MYSQL_PASSWORD=$(sudo docker exec "$DB_CONTAINER" printenv MYSQL_PASSWORD)
MYSQL_DATABASE=$(sudo docker exec "$DB_CONTAINER" printenv MYSQL_DATABASE)

echo "[2/7] Dump MariaDB..."
sudo docker exec -e MYSQL_PWD="$MYSQL_PASSWORD" "$DB_CONTAINER" \
  mariadb-dump -u"$MYSQL_USER" "$MYSQL_DATABASE" > "$BACKUP_DIR/db.sql"

echo "[3/7] Sauvegarde des cles GPG..."
sudo docker cp "$PASSBOLT_CONTAINER":/etc/passbolt/gpg/serverkey_private.asc "$BACKUP_DIR/serverkey_private.asc"
sudo docker cp "$PASSBOLT_CONTAINER":/etc/passbolt/gpg/serverkey.asc "$BACKUP_DIR/serverkey.asc"

echo "[4/7] Sauvegarde des configs..."
sudo docker inspect "$PASSBOLT_CONTAINER" > "$BACKUP_DIR/passbolt_config.json"
sudo docker inspect "$DB_CONTAINER" > "$BACKUP_DIR/db_config.json"

echo "[5/7] Creation de l'archive..."
sudo tar -czf "$ARCHIVE" \
  -C "$BACKUP_DIR" db.sql serverkey_private.asc serverkey.asc passbolt_config.json db_config.json \
  -C "$PASSBOLT_BASE_PATH" gpg_volume jwt_volume

echo "Nettoyage des fichiers temporaires..."
rm -f "$BACKUP_DIR/db.sql" "$BACKUP_DIR/serverkey_private.asc" "$BACKUP_DIR/serverkey.asc" "$BACKUP_DIR/passbolt_config.json" "$BACKUP_DIR/db_config.json"

echo "[6/7] Chiffrement GPG..."
if [ -n "$GPG_EXEC_USER" ] && [ "$EUID" -eq 0 ]; then
  echo "Chiffrement avec le trousseau GPG de '$GPG_EXEC_USER'..."
else
  echo "Chiffrement avec le trousseau GPG de l'utilisateur '$(id -un)'..."
fi
"${GPG_CMD[@]}" --batch --yes --recipient "$GPG_KEY" --encrypt "$ARCHIVE"
rm -f "$ARCHIVE"
ARCHIVE="$ARCHIVE.gpg"

echo "[7/7] Verification d'integrite..."
sha256sum "$ARCHIVE" > "$ARCHIVE.sha256"

echo "Rotation : garder seulement les $MAX_BACKUPS derniers backups..."
ls -1t "$BACKUP_DIR"/passbolt_backup_*.tar.gz.gpg 2>/dev/null | tail -n +$((MAX_BACKUPS + 1)) | while read -r oldfile; do
  rm -f "$oldfile" "$oldfile.sha256"
done

echo "Backup termine : $ARCHIVE"
echo "Checksum : $ARCHIVE.sha256"
