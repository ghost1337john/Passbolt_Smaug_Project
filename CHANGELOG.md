# Changelog

Toutes les evolutions notables de ce projet sont documentees dans ce fichier.

Le format suit l'esprit de Keep a Changelog et la versioning SemVer.

## [1.0.0] - 2026-04-15

### Added
- Mise en place de la stack Docker Compose Passbolt CE + MariaDB avec bind mounts.
- Ajout des scripts de sauvegarde et restauration:
  - `Sauvegarde/backup.sh`
  - `Sauvegarde/restore.sh`
- Ajout d'un chiffrement GPG des sauvegardes avec generation de checksum SHA256.
- Ajout d'une rotation automatique des sauvegardes (conservation des 10 plus recentes).
- Ajout de healthchecks Docker Compose:
  - `db` via `mariadb-admin ping`
  - `passbolt` via endpoint HTTP de sante
- Ajout d'une dependance de demarrage `passbolt -> db` conditionnee a `service_healthy`.
- Ajout d'une section de configuration manuelle GPG dans les scripts:
  - `MANUAL_GPG_KEY` dans `backup.sh`
  - `MANUAL_GPG_EXEC_USER` dans `backup.sh` et `restore.sh`

### Changed
- Harmonisation de la logique GPG entre sauvegarde et restauration:
  - detection de l'utilisateur de trousseau GPG
  - execution `gpg` avec le `HOME` de l'utilisateur cible
  - messages explicites sur le trousseau effectivement utilise
- Durcissement des commandes MariaDB dans `backup.sh` et `restore.sh`:
  - suppression des commandes shell imbriquees fragiles
  - utilisation de `MYSQL_PWD` pour eviter les erreurs de quoting et de caracteres speciaux
- Clarification et harmonisation des documentations:
  - `README.md`
  - `Installation/README.md`
  - `Sauvegarde/README.md`
- Standardisation de la procedure en mode manuel pour GPG dans la documentation.

### Fixed
- Correction d'une erreur de dump SQL liee au quoting shell (`EOF in backquote substitution`).
- Correction des commandes de restauration SQL pour eviter les echecs avec mots de passe speciaux.
- Correction de plusieurs incoherences de procedure entre backup, restore et README.
- Correction des exemples de chemins/variables pour limiter les erreurs d'execution en shell.

### Security
- Verification de presence de la cle GPG de destination avant chiffrement.
- Verification optionnelle du checksum `.sha256` avant restauration.
- Rappel des bonnes pratiques de sauvegarde/restauration et de conservation des cles.

### Docs
- Documentation de la verification d'une sauvegarde (integrite + inspection contenu archive).
- Documentation explicite du mode manuel GPG pour backup/restore.
- Mise a jour des exemples cron et des commandes d'exploitation.

## [0.9.0] - 2026-04-14

Commits concernes: `43340ec`, `5ab98b1`, `5fba202`, `bc3003b`, `27298c1`, `c76a649`, `f62d88d`

### Added
- Ajout/reintroduction de la base compose et installation:
  - `installation/docker-compose.yml`
  - `installation/README.md`
  - `installation/passbolt.env.example`

### Changed
- Mise a jour iterative de la configuration `installation/passbolt.env`.
- Mise a jour du README principal pour aligner la presentation du projet.
- Serie de revisions des scripts et de la documentation de sauvegarde/restauration:
  - `Sauvegarde/backup.sh`
  - `Sauvegarde/restore.sh`
  - `Sauvegarde/README.md`

### Docs
- Revisions successives de la documentation d'installation et d'exploitation en vue de la v1.0.

### Removed
- Retrait de scripts d'installation/deploiement historiques:
  - `installation/deploy.sh`
  - `installation/install_passbolt.sh`
- Retrait de `installation/smtp.env.example`.
- Retrait temporaire de `CHANGELOG.md` dans une revision intermediaire.

## [0.1.0] - 2026-04-13

### Added
- Initial commit du projet Passbolt Smaug.
- Mise en place initiale de la structure du depot.
- Ajout de l'image de presentation dans le README principal.
