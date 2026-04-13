#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
CONFIG_FILE="$SCRIPT_DIR/passbolt.env"
INSTALL_SCRIPT="$SCRIPT_DIR/install_passbolt.sh"

if [ ! -f "$CONFIG_FILE" ]; then
  echo "Erreur: fichier de configuration introuvable: $CONFIG_FILE"
  echo "Copie d'abord passbolt.env.example vers passbolt.env"
  exit 1
fi

if [ ! -f "$INSTALL_SCRIPT" ]; then
  echo "Erreur: script introuvable: $INSTALL_SCRIPT"
  exit 1
fi

if [ ! -x "$INSTALL_SCRIPT" ]; then
  chmod +x "$INSTALL_SCRIPT"
fi

echo "Lancement du deploiement Passbolt avec $CONFIG_FILE"
"$INSTALL_SCRIPT" --config "$CONFIG_FILE"

echo "Deploiement termine."
