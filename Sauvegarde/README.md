# Sauvegarde et restauration Passbolt

Ce dossier contient les scripts pour sauvegarder et restaurer une instance Passbolt installee via Docker.

## Structure cible
- Conteneur application : `passbolt`
- Conteneur base : `db`
- Dossier principal : `PASSBOLT_BASE_PATH` lu depuis `Installation/passbolt.env`
- Dossier backup : `${PASSBOLT_BASE_PATH}/backup`, cree automatiquement par `backup.sh` si besoin
- UID MariaDB : `999`
- Cle GPG backup : configurable dans `backup.sh` via `MANUAL_GPG_KEY`
- Utilisateur GPG optionnel : configurable dans `backup.sh` et `restore.sh` via `MANUAL_GPG_EXEC_USER`

Par defaut, si `Installation/passbolt.env` est present, les scripts chargent automatiquement `PASSBOLT_BASE_PATH` depuis ce fichier.
Par defaut, `backup.sh` chiffre et `restore.sh` dechiffre avec le trousseau GPG de l'utilisateur courant. Si le script est lance avec `sudo`, il essaie d'utiliser le trousseau de `SUDO_USER`. Tu peux forcer l'utilisateur a utiliser avec `MANUAL_GPG_EXEC_USER` dans le script.

Important : la variable `PASSBOLT_BASE_PATH` est chargee automatiquement par les scripts, mais pas par ton shell. Dans les commandes documentees ci-dessous, remplace `${PASSBOLT_BASE_PATH}` par le chemin reel si cette variable n'est pas exportee dans ton terminal.

## Creation de la cle GPG backup

1) Generer une nouvelle paire de cles :

```bash
gpg --full-generate-key
```

2) Lister les cles et recuperer le fingerprint :

```bash
gpg --list-secret-keys --keyid-format LONG
gpg --fingerprint <email_ou_keyid>
```

3) Exporter la cle publique si besoin de la partager :

```bash
gpg --armor --export <email_ou_keyid> > backup_public.asc
```

4) Configurer directement `Sauvegarde/backup.sh` avec le fingerprint trouve :

```bash
MANUAL_GPG_KEY="TON_FINGERPRINT_GPG"
MANUAL_GPG_EXEC_USER="ton_utilisateur"
```

## Fichiers
- `backup.sh` : cree un backup chiffre GPG + checksum SHA256 + rotation des archives
- `restore.sh` : dechiffre et restaure le dump SQL, les volumes Passbolt et les permissions, puis redemarre les conteneurs

## Permissions
Rendre les scripts executables :

```bash
chmod +x Sauvegarde/backup.sh Sauvegarde/restore.sh
```

## Backup manuel

Le dossier `${PASSBOLT_BASE_PATH}/backup` n'a pas besoin d'etre cree a la main : le script `backup.sh` le cree automatiquement au lancement.
Le script verifie aussi que la cle `GPG_KEY` est bien presente dans le trousseau GPG utilise avant de lancer le chiffrement.

Configuration directe dans `Sauvegarde/backup.sh` :

```bash
MANUAL_GPG_KEY="TON_FINGERPRINT_GPG"
MANUAL_GPG_EXEC_USER="ton_utilisateur"
```

Puis :

```bash
sudo ./Sauvegarde/backup.sh
```

Sortie attendue :

```text
Backup termine : ${PASSBOLT_BASE_PATH}/backup/passbolt_backup_YYYY-MM-DD_HH-MM-SS.tar.gz.gpg
Checksum : ${PASSBOLT_BASE_PATH}/backup/passbolt_backup_YYYY-MM-DD_HH-MM-SS.tar.gz.gpg.sha256
```

## Verifier une sauvegarde

Verifier d'abord l'integrite du fichier chiffre :

```bash
sudo sha256sum -c /app/passbolt/backup/passbolt_backup_YYYY-MM-DD_HH-MM-SS.tar.gz.gpg.sha256
```

Puis lister le contenu de l'archive dechiffree sans restaurer :

```bash
BACKUP_FILE="/app/passbolt/backup/passbolt_backup_YYYY-MM-DD_HH-MM-SS.tar.gz.gpg"
WORKDIR="/tmp/passbolt_check"

sudo rm -rf "$WORKDIR"
sudo mkdir -p "$WORKDIR"
sudo -u root env HOME=/root gpg --batch --yes --decrypt "$BACKUP_FILE" > "$WORKDIR/backup.tar.gz"
sudo tar -tzf "$WORKDIR/backup.tar.gz"
```

Tu dois au minimum retrouver : `db.sql`, `serverkey_private.asc`, `serverkey.asc`, `passbolt_config.json`, `db_config.json`, `gpg_volume/` et `jwt_volume/`.

## Backup automatique avec cron

Avant d'activer le cron :
- verifier qu'un backup manuel fonctionne
- utiliser le chemin absolu du projet dans la commande cron
- verifier que `MANUAL_GPG_KEY` et `MANUAL_GPG_EXEC_USER` sont correctement renseignes dans `backup.sh`

### 1. Identifier le chemin absolu du projet

Exemple :

```text
/opt/Passbolt_Smaug_Project
```

Dans ce cas, le script de backup sera :

```text
/opt/Passbolt_Smaug_Project/Sauvegarde/backup.sh
```

### 3. Ajouter la tache cron

Ouvrir `/etc/crontab` :

```bash
sudo nano /etc/crontab
```

Ajouter par exemple une sauvegarde tous les jours a minuit :

```cron
0 0 * * * root /opt/Passbolt_Smaug_Project/Sauvegarde/backup.sh >> /var/log/passbolt-backup.log 2>&1
```

### 3. Verifier que la tache est correcte

Points a verifier :
- le chemin vers `backup.sh` est absolu
- `MANUAL_GPG_KEY` est correcte dans `backup.sh`
- `MANUAL_GPG_EXEC_USER` est defini si la cle n'est pas dans le trousseau root
- le script est executable

Commande utile :

```bash
ls -l /opt/Passbolt_Smaug_Project/Sauvegarde/backup.sh
```

### 4. Surveiller l'execution

Apres le premier lancement cron, verifier le log :

```bash
sudo tail -n 50 /var/log/passbolt-backup.log
```

## Restauration

Configuration directe dans `Sauvegarde/restore.sh` :

```bash
MANUAL_GPG_EXEC_USER="ton_utilisateur"
```

Puis :

```bash
sudo ./Sauvegarde/restore.sh /app/passbolt/backup/passbolt_backup_YYYY-MM-DD_HH-MM-SS.tar.gz.gpg
```

Si ton installation utilise un autre chemin, remplace simplement `/app/passbolt/backup/...` par le chemin absolu reel du fichier `.tar.gz.gpg`.

Le script de restauration :
- verifie automatiquement le checksum SHA256 si le fichier `.sha256` est present
- nettoie automatiquement son repertoire temporaire apres execution
- dechiffre avec le trousseau GPG de l'utilisateur configure
- restaure la base a partir du dump SQL
- restaure `gpg_volume` et `jwt_volume`
- recree les repertoires cibles si necessaire
- reapplique les permissions `www-data:www-data` sur les repertoires Passbolt

Important :
- la restauration de la base repose sur le dump SQL, pas sur une copie brute du datadir MariaDB
- cela evite de melanger une restauration logique (SQL) et une restauration fichier a fichier de `database_volume`

## Verifications apres restauration
- Ouvrir l'instance : `http://localhost:8080` ou l'URL definie dans `APP_FULL_BASE_URL`
- Verifier la presence des mots de passe
- Verifier les partages
- Verifier les cles GPG

## Bonnes pratiques
- Tester une restauration au moins 1 fois par mois
- Copier `${PASSBOLT_BASE_PATH}/backup` vers un stockage externe (NAS, S3, etc.)
- Conserver la cle GPG privee separement
- Surveiller les logs : `/var/log/passbolt-backup.log`
