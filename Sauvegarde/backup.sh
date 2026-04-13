#!/bin/bash
set -euo pipefail

BACKUP_DIR="/app/passbolt/backup"
DB_CONTAINER="db"
PASSBOLT_CONTAINER="passbolt"
DATE=$(date +"%Y-%m-%d_%H-%M-%S")
ARCHIVE="$BACKUP_DIR/passbolt_backup_$DATE.tar.gz"
MAX_BACKUPS=10
GPG_KEY="${GPG_KEY:-}"

if [ -z "$GPG_KEY" ]; then
  echo "Erreur: variable GPG_KEY non definie."
  echo "Exemple: export GPG_KEY=TON_FINGERPRINT_GPG"
  exit 1
fi

mkdir -p "$BACKUP_DIR"

echo "[1/7] Recuperation des variables DB..."
MYSQL_USER=$(sudo docker exec "$DB_CONTAINER" printenv MYSQL_USER)
MYSQL_PASSWORD=$(sudo docker exec "$DB_CONTAINER" printenv MYSQL_PASSWORD)
MYSQL_DATABASE=$(sudo docker exec "$DB_CONTAINER" printenv MYSQL_DATABASE)

echo "[2/7] Dump MariaDB..."
sudo sh -c "docker exec $DB_CONTAINER bash -c \"mariadb-dump -u$MYSQL_USER -p$MYSQL_PASSWORD $MYSQL_DATABASE\" > $BACKUP_DIR/db.sql"

echo "[3/7] Sauvegarde des cles GPG..."
sudo docker cp "$PASSBOLT_CONTAINER":/etc/passbolt/gpg/serverkey_private.asc "$BACKUP_DIR/serverkey_private.asc"
sudo docker cp "$PASSBOLT_CONTAINER":/etc/passbolt/gpg/serverkey.asc "$BACKUP_DIR/serverkey.asc"

echo "[4/7] Sauvegarde des configs..."
sudo docker inspect "$PASSBOLT_CONTAINER" > "$BACKUP_DIR/passbolt_config.json"
sudo docker inspect "$DB_CONTAINER" > "$BACKUP_DIR/db_config.json"

echo "[5/7] Creation de l'archive..."
sudo tar -czf "$ARCHIVE" \
  -C "$BACKUP_DIR" db.sql serverkey_private.asc serverkey.asc passbolt_config.json db_config.json \
  -C /app/passbolt database_volume gpg_volume jwt_volume certs

echo "Nettoyage des fichiers temporaires..."
rm -f "$BACKUP_DIR/db.sql" "$BACKUP_DIR/serverkey_private.asc" "$BACKUP_DIR/serverkey.asc" "$BACKUP_DIR/passbolt_config.json" "$BACKUP_DIR/db_config.json"

echo "[6/7] Chiffrement GPG..."
gpg --batch --yes --recipient "$GPG_KEY" --encrypt "$ARCHIVE"
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
