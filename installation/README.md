# Installation Passbolt avec Docker

Ce dossier fournit une procedure d'installation Passbolt avec Docker, inspiree du tutoriel IT-Connect :
https://www.it-connect.fr/tuto-passbolt-installation-avec-docker/

Objectif : accelerer le deploiement technique avec un script reutilisable, puis terminer la configuration metier (SMTP + admin).

## Fichiers
- install_passbolt.sh : script d'installation de la stack (repertoires, compose officiel, checksum, volumes, URL, lancement)
- deploy.sh : lanceur en une commande base sur passbolt.env
- passbolt.env : fichier reel de configuration de deploiement
- smtp.env.example : exemple de variables SMTP a reporter dans le compose
- passbolt.env.example : modele de configuration centralisee pour le script

## Prerequis
- Linux avec sudo
- Docker installe
- Docker Compose v2 disponible via docker compose
- DNS/nom de domaine resolvable pour Passbolt

## 1) Lancer le script
Mode serveur recommande (une commande) :

cp passbolt.env.example passbolt.env
# editer passbolt.env
./deploy.sh

Methode recommandee (fichier de config) :

cp passbolt.env.example passbolt.env
# editer passbolt.env puis renseigner le domaine et SMTP
./install_passbolt.sh --config ./passbolt.env

Commande minimale :

./install_passbolt.sh --domain passbolt.example.com

Commande avec certificats TLS locaux :

./install_passbolt.sh --domain passbolt.example.com --tls-cert /tmp/cert.crt --tls-key /tmp/cert.key

## 2) Verifier le compose genere
Fichier : /opt/docker-compose/passbolt/docker-compose-ce.yaml

Points a verifier :
- APP_FULL_BASE_URL correspond a votre domaine
- Les volumes locaux commencent par ./
- Si vous ne passez pas de TLS local, publication HTTPS via reverse proxy recommandee

## 3) Configurer SMTP
Si les variables SMTP_* sont renseignees dans passbolt.env, le script les injecte automatiquement dans le compose.
Sinon, ouvrir le compose et renseigner les variables manuellement (modele dans smtp.env.example).

Puis redemarrer :

sudo docker compose -f /opt/docker-compose/passbolt/docker-compose-ce.yaml up -d

## 4) Creer le compte admin
Commande type :

sudo docker compose -f /opt/docker-compose/passbolt/docker-compose-ce.yaml exec passbolt su -m -c "/usr/share/php/passbolt/bin/cake passbolt register_user -u admin@example.com -f Admin -l Local -r admin" -s /bin/sh www-data

## 5) Verification finale
- Ouvrir https://votre-domaine-passbolt
- Finaliser l'inscription admin depuis l'URL de registration
- Installer l'extension navigateur Passbolt
- Sauvegarder le recovery kit dans un coffre separe

## Notes securite
- Conserver les volumes de donnees en stockage persistant
- Utiliser un certificat TLS valide
- Sauvegarder la stack et tester la restauration regulierement
- Ne pas exposer les mots de passe SMTP en clair dans un depot Git
