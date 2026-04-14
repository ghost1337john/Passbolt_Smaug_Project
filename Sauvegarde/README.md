# Sauvegarde et restauration Passbolt

Ce dossier contient les scripts pour sauvegarder et restaurer une instance Passbolt installee via Docker.

## Structure cible
- Conteneur application : `passbolt`
- Conteneur base : `db`
- Dossier principal : `PASSBOLT_BASE_PATH` lu depuis `Installation/passbolt.env`
- Dossier backup : `${PASSBOLT_BASE_PATH}/backup`
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
- `restore.sh` : dechiffre et restaure base + volumes + permissions + redemarrage des conteneurs

## Permissions
Rendre les scripts executables :

```bash
chmod +x Sauvegarde/backup.sh Sauvegarde/restore.sh
```

## Backup manuel

```bash
export GPG_KEY="TON_FINGERPRINT_GPG"
sudo ./Sauvegarde/backup.sh
```

Sortie attendue :

```text
Backup termine : ${PASSBOLT_BASE_PATH}/backup/passbolt_backup_YYYY-MM-DD_HH-MM-SS.tar.gz.gpg
Checksum : ${PASSBOLT_BASE_PATH}/backup/passbolt_backup_YYYY-MM-DD_HH-MM-SS.tar.gz.gpg.sha256
```

## Backup automatique (cron a minuit)
Ajouter dans `/etc/crontab` :

```cron
0 0 * * * root . /etc/default/passbolt-backup; /chemin/vers/le/projet/Sauvegarde/backup.sh >> /var/log/passbolt-backup.log 2>&1
```

## Restauration

```bash
sudo ./Sauvegarde/restore.sh ${PASSBOLT_BASE_PATH}/backup/passbolt_backup_YYYY-MM-DD_HH-MM-SS.tar.gz.gpg
```

Le script de restauration :
- verifie automatiquement le checksum SHA256 si le fichier `.sha256` est present
- nettoie automatiquement son repertoire temporaire apres execution
- restaure `database_volume`, `gpg_volume` et `jwt_volume`

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
