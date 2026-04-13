#!/bin/bash
set -euo pipefail

STACK_DIR="/opt/docker-compose/passbolt"
PASSBOLT_DOMAIN=""
TLS_CERT_PATH=""
TLS_KEY_PATH=""
CONFIG_FILE="./passbolt.env"

SMTP_FROM_NAME=""
SMTP_FROM_ADDRESS=""
SMTP_HOST=""
SMTP_PORT=""
SMTP_USERNAME=""
SMTP_PASSWORD=""
SMTP_TLS=""

COMPOSE_FILE="docker-compose-ce.yaml"

ARG_STACK_DIR=""
ARG_PASSBOLT_DOMAIN=""
ARG_TLS_CERT_PATH=""
ARG_TLS_KEY_PATH=""
ARG_CONFIG_FILE=""

usage() {
  echo "Usage: $0 --domain passbolt.example.com [--stack-dir /opt/docker-compose/passbolt] [--config ./passbolt.env] [--tls-cert /path/cert.crt --tls-key /path/key.key]"
}

upsert_compose_env() {
  local key="$1"
  local value="$2"
  local escaped
  escaped=$(printf '%s' "$value" | sed 's/[\\&/]/\\\\&/g')

  if grep -qE "^[[:space:]]+$key:" "$COMPOSE_FILE"; then
    sed -i -E "s#^([[:space:]]*)$key:.*#\\1$key: \"$escaped\"#" "$COMPOSE_FILE"
  else
    awk -v k="$key" -v v="$value" '
      { print }
      !done && $0 ~ /APP_FULL_BASE_URL:/ {
        print "      " k ": \"" v "\""
        done=1
      }
    ' "$COMPOSE_FILE" > "$COMPOSE_FILE.tmp"
    mv "$COMPOSE_FILE.tmp" "$COMPOSE_FILE"
  fi
}

while [ $# -gt 0 ]; do
  case "$1" in
    --domain)
      ARG_PASSBOLT_DOMAIN="${2:-}"
      shift 2
      ;;
    --stack-dir)
      ARG_STACK_DIR="${2:-}"
      shift 2
      ;;
    --config)
      ARG_CONFIG_FILE="${2:-}"
      shift 2
      ;;
    --tls-cert)
      ARG_TLS_CERT_PATH="${2:-}"
      shift 2
      ;;
    --tls-key)
      ARG_TLS_KEY_PATH="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Argument inconnu: $1"
      usage
      exit 1
      ;;
  esac
done

if [ -n "$ARG_CONFIG_FILE" ]; then
  CONFIG_FILE="$ARG_CONFIG_FILE"
fi

if [ -f "$CONFIG_FILE" ]; then
  # shellcheck disable=SC1090
  source "$CONFIG_FILE"
fi

if [ -n "$ARG_PASSBOLT_DOMAIN" ]; then
  PASSBOLT_DOMAIN="$ARG_PASSBOLT_DOMAIN"
fi
if [ -n "$ARG_STACK_DIR" ]; then
  STACK_DIR="$ARG_STACK_DIR"
fi
if [ -n "$ARG_TLS_CERT_PATH" ]; then
  TLS_CERT_PATH="$ARG_TLS_CERT_PATH"
fi
if [ -n "$ARG_TLS_KEY_PATH" ]; then
  TLS_KEY_PATH="$ARG_TLS_KEY_PATH"
fi

if [ -z "$PASSBOLT_DOMAIN" ]; then
  echo "Erreur: --domain est obligatoire."
  usage
  exit 1
fi

if { [ -n "$TLS_CERT_PATH" ] && [ -z "$TLS_KEY_PATH" ]; } || { [ -z "$TLS_CERT_PATH" ] && [ -n "$TLS_KEY_PATH" ]; }; then
  echo "Erreur: --tls-cert et --tls-key doivent etre fournis ensemble."
  exit 1
fi

if ! command -v docker >/dev/null 2>&1; then
  echo "Erreur: docker n'est pas installe."
  exit 1
fi

if ! docker compose version >/dev/null 2>&1; then
  echo "Erreur: docker compose (plugin v2) n'est pas disponible."
  exit 1
fi

echo "[1/7] Creation des repertoires persistants..."
sudo mkdir -p "$STACK_DIR"/{gpg_volume,jwt_volume,certs,database_volume}

if getent passwd www-data >/dev/null 2>&1; then
  sudo chown www-data:www-data "$STACK_DIR/gpg_volume" "$STACK_DIR/jwt_volume"
else
  sudo chown 33:33 "$STACK_DIR/gpg_volume" "$STACK_DIR/jwt_volume"
fi

echo "[2/7] Recuperation du compose officiel Passbolt + checksum..."
cd "$STACK_DIR"

if [ -f "$COMPOSE_FILE" ]; then
  cp "$COMPOSE_FILE" "$COMPOSE_FILE.bak.$(date +"%Y%m%d_%H%M%S")"
fi

curl -fsSLO https://download.passbolt.com/ce/docker/docker-compose-ce.yaml
curl -fsSLO https://github.com/passbolt/passbolt_docker/releases/latest/download/docker-compose-ce-SHA512SUM.txt

echo "[3/7] Verification checksum..."
sha512sum -c docker-compose-ce-SHA512SUM.txt >/dev/null
echo "Checksum OK"

echo "[4/7] Adaptation des volumes locaux..."
sed -i 's#database_volume:/var/lib/mysql#./database_volume:/var/lib/mysql#g' docker-compose-ce.yaml
sed -i 's#gpg_volume:/etc/passbolt/gpg#./gpg_volume:/etc/passbolt/gpg#g' docker-compose-ce.yaml
sed -i 's#jwt_volume:/etc/passbolt/jwt#./jwt_volume:/etc/passbolt/jwt#g' docker-compose-ce.yaml

echo "[5/7] Configuration URL Passbolt..."
upsert_compose_env "APP_FULL_BASE_URL" "https://$PASSBOLT_DOMAIN"

if [ -n "$SMTP_HOST" ] && [ -n "$SMTP_PORT" ] && [ -n "$SMTP_FROM_ADDRESS" ]; then
  upsert_compose_env "EMAIL_DEFAULT_FROM_NAME" "${SMTP_FROM_NAME:-Passbolt}"
  upsert_compose_env "EMAIL_DEFAULT_FROM" "$SMTP_FROM_ADDRESS"
  upsert_compose_env "EMAIL_TRANSPORT_DEFAULT_HOST" "$SMTP_HOST"
  upsert_compose_env "EMAIL_TRANSPORT_DEFAULT_PORT" "$SMTP_PORT"
  if [ -n "$SMTP_USERNAME" ]; then
    upsert_compose_env "EMAIL_TRANSPORT_DEFAULT_USERNAME" "$SMTP_USERNAME"
  fi
  if [ -n "$SMTP_PASSWORD" ]; then
    upsert_compose_env "EMAIL_TRANSPORT_DEFAULT_PASSWORD" "$SMTP_PASSWORD"
  fi
  if [ -n "$SMTP_TLS" ]; then
    upsert_compose_env "EMAIL_TRANSPORT_DEFAULT_TLS" "$SMTP_TLS"
  fi
  echo "SMTP configure via variables." 
else
  echo "SMTP non configure automatiquement (variables SMTP_* absentes)."
fi

if [ -n "$TLS_CERT_PATH" ] && [ -n "$TLS_KEY_PATH" ]; then
  echo "[6/7] Copie certificat TLS..."
  sudo cp "$TLS_CERT_PATH" "$STACK_DIR/certs/certificate.crt"
  sudo cp "$TLS_KEY_PATH" "$STACK_DIR/certs/certificate.key"

  if ! grep -q "certificate.crt" docker-compose-ce.yaml; then
    echo "Note: ajoute manuellement ces 2 volumes au service passbolt dans docker-compose-ce.yaml"
    echo "- ./certs/certificate.crt:/etc/ssl/certs/certificate.crt:ro"
    echo "- ./certs/certificate.key:/etc/ssl/certs/certificate.key:ro"
  fi
else
  echo "[6/7] TLS externe ou reverse proxy: aucun certificat local copie."
fi

echo "[7/7] Demarrage de la stack..."
sudo docker compose -f "$COMPOSE_FILE" up -d

echo "Installation technique terminee."
echo "Commande logs: sudo docker compose -f $STACK_DIR/$COMPOSE_FILE logs -f"
echo "Commande creation admin:"
echo "sudo docker compose -f $STACK_DIR/$COMPOSE_FILE exec passbolt su -m -c \"/usr/share/php/passbolt/bin/cake passbolt register_user -u admin@example.com -f Admin -l Local -r admin\" -s /bin/sh www-data"
