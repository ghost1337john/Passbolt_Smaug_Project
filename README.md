<img width="1536" height="1024" alt="Copilot_20260413_171725" src="https://github.com/user-attachments/assets/7e57c814-8793-43ea-af06-c2752075048b" />

# 🛡️ Passbolt Docker Stack — Installation & Sauvegarde

## 🐉 Smaug, Gardien du Trésor des Mots de Passe

> Dans les profondeurs numériques de la Montagne Solitaire, là où les hackers rôdent et les failles sommeillent, un dragon veille. Son nom : **Smaug**.
>
> Nul ne franchit ses défenses sans y laisser des plumes : il enserre dans ses griffes acérées le plus précieux des trésors — vos mots de passe.
>
> Tel un feu dévorant, il réduit à néant les intrus, protège chaque secret, et ne dort jamais. Seuls les élus, porteurs de la bonne clé, peuvent espérer approcher la caverne et y puiser, sans risquer la colère du dragon.
>
> **Passbolt_Smaug_Project** : là où la sécurité n’est pas un mythe, mais une légende.

> ℹ️ **Statut** : projet actuellement en phase de test, avec une stack Docker Compose simple, sans Traefik pour le moment.

> ℹ️ **Note** : les elements d'integration Traefik seront ajoutes plus tard, une fois la base du projet validee.

Ce depot contient une installation Passbolt basee sur Docker Compose et un dossier de scripts de sauvegarde/restauration.

## Presentation

Le projet fournit :
- une instance Passbolt CE
- une base MariaDB dediee
- des donnees persistantes via bind mounts
- une exposition directe de Passbolt sur `http://localhost:8080`
- des scripts de sauvegarde et restauration dans le dossier Sauvegarde

## Structure du projet

```text
passbolt_smaug_project/
├── Installation/
│   ├── docker-compose.yml
│   ├── passbolt.env
│   ├── passbolt.env.example
│   └── README.md
├── Sauvegarde/
│   ├── backup.sh
│   ├── restore.sh
│   └── README.md
└── README.md
```

## Installation

Le detail de l'installation est documente dans [Installation/README.md](Installation/README.md).

En resume :
1. Cloner le depot puis entrer dans [Installation/](Installation).
2. Copier [Installation/passbolt.env.example](Installation/passbolt.env.example) vers [Installation/passbolt.env](Installation/passbolt.env).
3. Adapter les variables SMTP, base de donnees, chemins de volumes et URL publique.
4. Valider le compose avec `docker compose --env-file passbolt.env config`.
5. Demarrer avec `docker compose --env-file passbolt.env up -d`.
6. Consulter les logs avec `docker compose logs -f passbolt`.

## Sauvegarde et restauration

Le dossier [Sauvegarde](Sauvegarde) contient :
- [Sauvegarde/backup.sh](Sauvegarde/backup.sh) pour sauvegarder l'instance
- [Sauvegarde/restore.sh](Sauvegarde/restore.sh) pour restaurer une sauvegarde
- [Sauvegarde/README.md](Sauvegarde/README.md) pour la procedure detaillee

Les scripts de sauvegarde et restauration se configurent directement en tete de script pour la partie GPG.

## Notes de securite

- Ne versionnez jamais de mots de passe reels dans [Installation/passbolt.env](Installation/passbolt.env).
- Limitez l'exposition reseau du port `8080` si l'instance n'est pas uniquement locale.
- Conservez les sauvegardes et les cles sensibles hors du serveur principal quand c'est possible.
- Testez la restauration regulierement avant de considerer la sauvegarde comme fiable.

## References

- [Tutoriel IT-Connect](https://www.it-connect.fr/tuto-passbolt-installation-avec-docker/)
- [Documentation Passbolt](https://www.passbolt.com/docs/)
