
# 🛡️ Passbolt Docker Stack — Installation & Sauvegarde

## 🐉 Smaug, Gardien du Trésor des Mots de Passe

> Dans les profondeurs numériques de la Montagne Solitaire, là où les hackers rôdent et les failles sommeillent, un dragon veille. Son nom : **Smaug**.
>
> Nul ne franchit ses défenses sans y laisser des plumes : il enserre dans ses griffes acérées le plus précieux des trésors — vos mots de passe.
>
> Tel un feu dévorant, il réduit à néant les intrus, protège chaque secret, et ne dort jamais. Seuls les élus, porteurs de la bonne clé, peuvent espérer approcher la caverne et y puiser, sans risquer la colère du dragon.
>
> **Passbolt_Smaug_Project** : là où la sécurité n’est pas un mythe, mais une légende.

> ℹ️ **Statut** : Projet en cours de validation et de tests.

Bienvenue dans la stack Passbolt prête à l’emploi ! Ici, tout est pensé pour déployer, sauvegarder et restaurer Passbolt de façon fiable, automatisée et documentée.

---

## 🚀 Sommaire
- [Présentation](#présentation)
- [Objectifs](#objectifs)
- [Démarrage rapide](#démarrage-rapide)
- [Structure du projet](#structure-du-projet)
- [Installation](#installation)
- [Sauvegarde & Restauration](#sauvegarde--restauration)
- [Notes de sécurité](#notes-de-sécurité)
- [Références](#références)

---

## ✨ Présentation

Dans un monde où la sécurité des mots de passe est cruciale, cette stack Docker Passbolt vous permet de :

• Déployer Passbolt en quelques minutes, sans galère de configuration.
• Sauvegarder toute l’instance (base, clés, volumes) de façon chiffrée.
• Restaurer en un clin d’œil, avec vérification d’intégrité.

Inspiré par les meilleures pratiques et la clarté de projets comme GreyWizard-Filter.

---

## 🎯 Objectifs
- Déploiement Passbolt ultra-rapide via Docker Compose
- Configuration centralisée (un seul fichier à éditer)
- Sauvegarde chiffrée GPG + rotation + checksum
- Restauration fiable, vérifiée, automatisée

---

## ⚡ Démarrage rapide

```bash
# 1. Aller dans le dossier installation
cd installation
# 2. Copier et adapter la config
cp passbolt.env.example passbolt.env
vim passbolt.env   # ou nano passbolt.env
# 3. Lancer le déploiement
./deploy.sh
# 4. Créer le compte admin (voir README installation)
# 5. Mettre en place la sauvegarde automatique (voir README Sauvegarde)
```

---

## 🗂️ Structure du projet

```text
Passbolt/
├── installation/
│   ├── deploy.sh              # Déploiement en une commande
│   ├── install_passbolt.sh    # Script d'installation détaillé
│   ├── passbolt.env           # Configuration réelle (à adapter)
│   ├── passbolt.env.example   # Modèle de config
│   └── README.md              # Guide d'installation
├── Sauvegarde/
│   ├── backup.sh              # Sauvegarde chiffrée GPG
│   ├── restore.sh             # Restauration + vérification
│   └── README.md              # Guide backup/restore
├── CHANGELOG.md
└── README.md                  # (ce fichier)
```

---

## 🏗️ Installation

Tout est expliqué dans [installation/README.md](installation/README.md), mais en résumé :

1. Adapter `installation/passbolt.env` (domaine, SMTP, TLS…)
2. Lancer `./deploy.sh` pour tout automatiser
3. Créer le compte admin Passbolt

> 💡 **Astuce** : Le script injecte automatiquement la config SMTP si renseignée dans `passbolt.env`.

---

## 💾 Sauvegarde & Restauration

Scripts dédiés dans le dossier [Sauvegarde](Sauvegarde) :

- `backup.sh` : Sauvegarde complète chiffrée (base, clés, volumes, configs)
- `restore.sh` : Restauration automatisée, vérification SHA256 si présente
- Voir [Sauvegarde/README.md](Sauvegarde/README.md) pour la mise en place du cron et la procédure détaillée

---

## 🔐 Notes de sécurité

- Ne versionnez jamais de mots de passe réels dans les fichiers `.env`
- Utilisez un certificat TLS valide (ou reverse proxy)
- Conservez la clé privée GPG de backup hors du serveur
- Testez régulièrement la restauration sur un environnement de test

---

## 📚 Références

- [Tutoriel IT-Connect (base technique)](https://www.it-connect.fr/tuto-passbolt-installation-avec-docker/)
- [Documentation Passbolt](https://www.passbolt.com/docs/)

---

> 🛠️ Projet adaptable, évolutif, et en amélioration continue. Pour toute suggestion, ouvrez une issue ou contactez le mainteneur.
