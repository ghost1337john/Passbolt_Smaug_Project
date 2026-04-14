# Sauvegarde et restauration Passbolt

Ce dossier contient les scripts pour sauvegarder et restaurer une instance Passbolt installee via Docker.

## Structure cible
- Conteneur application : `passbolt`
- Conteneur base : `db`
- Dossier principal : `PASSBOLT_BASE_PATH` lu depuis `Installation/passbolt.env`
- Dossier backup : `${PASSBOLT_BASE_PATH}/backup`, cree automatiquement par `backup.sh` si besoin
- UID MariaDB : `999`
- Cle GPG backup : variable d'environnement `GPG_KEY`

Par defaut, si `Installation/passbolt.env` est present, les scripts chargent automatiquement `PASSBOLT_BASE_PATH` depuis ce fichier.

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

4) Configurer le script avec le fingerprint trouve :

```bash
export GPG_KEY="TON_FINGERPRINT_GPG"
```

Option persistante recommandee (pour cron) :

```bash
echo 'GPG_KEY="TON_FINGERPRINT_GPG"' | sudo tee /etc/default/passbolt-backup > /dev/null
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

```bash
export GPG_KEY="TON_FINGERPRINT_GPG"
sudo ./Sauvegarde/backup.sh
```

Sortie attendue :

```text
Backup termine : ${PASSBOLT_BASE_PATH}/backup/passbolt_backup_YYYY-MM-DD_HH-MM-SS.tar.gz.gpg
Checksum : ${PASSBOLT_BASE_PATH}/backup/passbolt_backup_YYYY-MM-DD_HH-MM-SS.tar.gz.gpg.sha256
```

## Backup automatique avec cron

Avant d'activer le cron :
- verifier qu'un backup manuel fonctionne
- utiliser le chemin absolu du projet dans la commande cron
- enregistrer la variable `GPG_KEY` dans un fichier charge par cron

### 1. Definir la cle GPG pour cron

Creer le fichier `/etc/default/passbolt-backup` :

```bash
echo 'GPG_KEY="TON_FINGERPRINT_GPG"' | sudo tee /etc/default/passbolt-backup > /dev/null
```

Verifier ensuite son contenu :

```bash
sudo cat /etc/default/passbolt-backup
```

### 2. Identifier le chemin absolu du projet

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
0 0 * * * root . /etc/default/passbolt-backup; /opt/Passbolt_Smaug_Project/Sauvegarde/backup.sh >> /var/log/passbolt-backup.log 2>&1
```

### 4. Verifier que la tache est correcte

Points a verifier :
- le chemin vers `backup.sh` est absolu
- le fichier `/etc/default/passbolt-backup` existe
- `GPG_KEY` est correcte
- le script est executable

Commande utile :

```bash
ls -l /opt/Passbolt_Smaug_Project/Sauvegarde/backup.sh
```

### 5. Surveiller l'execution

Apres le premier lancement cron, verifier le log :

```bash
sudo tail -n 50 /var/log/passbolt-backup.log
```

## Restauration

```bash
sudo ./Sauvegarde/restore.sh ${PASSBOLT_BASE_PATH}/backup/passbolt_backup_YYYY-MM-DD_HH-MM-SS.tar.gz.gpg
```

Le script de restauration :
- verifie automatiquement le checksum SHA256 si le fichier `.sha256` est present
- nettoie automatiquement son repertoire temporaire apres execution
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
