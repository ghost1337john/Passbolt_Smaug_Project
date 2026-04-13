# Changelog

Toutes les modifications notables de ce projet sont documentees dans ce fichier.

## [0.1.0] - 2026-04-13
### Ajoute
- Structure initiale du projet avec les dossiers installation et Sauvegarde.
- Script d'installation Passbolt via Docker dans installation/install_passbolt.sh.
- Lanceur en une commande dans installation/deploy.sh.
- Fichiers de configuration d'exemple et de travail (passbolt.env.example, passbolt.env, smtp.env.example).
- Scripts de sauvegarde/restauration dans Sauvegarde/backup.sh et Sauvegarde/restore.sh.
- Documentation dediee dans installation/README.md et Sauvegarde/README.md.
- README general du projet a la racine.

### Change
- Durcissement du script de restauration avec verification SHA256 optionnelle.
- Clarification du workflow de deploiement et de sauvegarde.

### Note
- Le projet est actuellement en cours de validation et de tests.
