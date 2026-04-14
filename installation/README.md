# Installation de Passbolt

> ℹ️ **Statut** : cette installation est actuellement en phase de test.

> ℹ️ **Note** : l'integration Traefik a ete retiree temporairement et sera ajoutee plus tard.

Ce dossier contient une installation Docker Compose de Passbolt avec :
- une base MariaDB
- un conteneur Passbolt CE
- des bind mounts sur l'hote
- une exposition directe du service Passbolt sur le port 8080
- un fichier `passbolt.env` charge par les services

## Fichiers

- `docker-compose.yml` : definition des services
- `passbolt.env` : variables utilisees par le compose
- `passbolt.env.example` : exemple de configuration a copier

## Prerequis

Avant de lancer la stack, verifier les points suivants :
- Docker et Docker Compose sont installes sur l'hote
- le chemin hote defini dans `PASSBOLT_BASE_PATH` existe
- le port `8080` est libre sur l'hote

Si tu n'as pas encore recupere le projet :

```bash
git clone https://github.com/ghost1337john/Passbolt_Smaug_Project.git
cd Passbolt_Smaug_Project/Installation
```

## 1. Preparer le fichier d'environnement

Depuis ce dossier, copier le fichier d'exemple puis l'adapter :

```bash
cp passbolt.env.example passbolt.env
```

Variables a renseigner dans `passbolt.env` :
- `APP_FULL_BASE_URL` : URL publique de Passbolt
- `PASSBOLT_BASE_PATH` : dossier racine des donnees sur l'hote
- `MYSQL_USER` : utilisateur MariaDB pour Passbolt
- `MYSQL_PASSWORD` : mot de passe MariaDB
- `EMAIL_DEFAULT_FROM_NAME` : nom d'expediteur des emails
- `EMAIL_TRANSPORT_DEFAULT_USERNAME` : adresse email d'expedition
- `EMAIL_TRANSPORT_DEFAULT_HOST` : serveur SMTP
- `EMAIL_TRANSPORT_DEFAULT_PORT` : port SMTP
- `EMAIL_TRANSPORT_DEFAULT_PASSWORD` : mot de passe SMTP
- `EMAIL_TRANSPORT_DEFAULT_TLS` : `tls`, `ssl` ou `false` selon ton serveur SMTP

Exemple minimal :

```env
APP_FULL_BASE_URL=http://localhost:8080
PASSBOLT_BASE_PATH=/app/passbolt
MYSQL_USER=passbolt
MYSQL_PASSWORD=ChangeMeStrongPassword
EMAIL_DEFAULT_FROM_NAME=Passbolt
EMAIL_TRANSPORT_DEFAULT_USERNAME=passbolt@example.com
EMAIL_TRANSPORT_DEFAULT_HOST=smtp.example.com
EMAIL_TRANSPORT_DEFAULT_PORT=587
EMAIL_TRANSPORT_DEFAULT_PASSWORD=ChangeMe
EMAIL_TRANSPORT_DEFAULT_TLS=tls
```

## 2. Preparer les dossiers sur l'hote

Le compose utilise des bind mounts. Il faut donc creer les dossiers sur l'hote :

```bash
mkdir -p /app/passbolt/database_volume
mkdir -p /app/passbolt/gpg_volume
mkdir -p /app/passbolt/jwt_volume
```

Si tu utilises un autre chemin, adapte `PASSBOLT_BASE_PATH` en consequence.

Avant le premier demarrage, ajuster aussi les permissions sur les dossiers utilises par Passbolt, sinon l'application ne pourra pas ecrire dedans :

```bash
sudo chown www-data:www-data ${PASSBOLT_BASE_PATH}/gpg_volume
sudo chown www-data:www-data ${PASSBOLT_BASE_PATH}/jwt_volume
```

## 3. Adapter le domaine dans le compose

Dans `docker-compose.yml`, verifier les valeurs suivantes :
- `APP_FULL_BASE_URL` dans `passbolt.env`

Si tu utilises cette stack sans reverse proxy, remplace la valeur par l'URL d'acces reelle, par exemple `http://localhost:8080` pour un acces local.

## 4. Valider la configuration

Depuis le dossier `Installation`, verifier que les variables sont bien resolues :

```bash
docker compose --env-file passbolt.env config
```

Important : le `env_file` defini dans les services injecte les variables dans les conteneurs, mais l'option `--env-file` reste utile pour l'interpolation des variables dans le fichier Compose lui-meme.

## 5. Demarrer la stack

Depuis le dossier `Installation` :

```bash
docker compose --env-file passbolt.env up -d
```

## 6. Verifier le deploiement

Verifier l'etat des conteneurs :

```bash
docker compose ps
```

Verifier les logs Passbolt :

```bash
docker compose logs -f passbolt
```

Acces local par defaut :

```text
http://localhost:8080
http://IPHOST:8080
```

## Notes utiles

- Le service `db` stocke ses donnees dans `${PASSBOLT_BASE_PATH}/database_volume`
- Les cles GPG de Passbolt sont stockees dans `${PASSBOLT_BASE_PATH}/gpg_volume`
- Les cles JWT sont stockees dans `${PASSBOLT_BASE_PATH}/jwt_volume`
- Le compose utilise des bind mounts et non des volumes Docker nommes
- Le service Passbolt est expose directement sur le port `8080` de l'hote
- Si tu modifies `passbolt.env`, relance ensuite la stack pour appliquer les changements
