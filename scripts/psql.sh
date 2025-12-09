#!/usr/bin/env bash

set -euo pipefail

# Open a psql shell into the compose-managed Postgres service using .env values.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ENV_FILE:-$ROOT_DIR/.env}"
COMPOSE_FILE="$ROOT_DIR/docker-compose.yml"
SERVICE_NAME="postgres"

log() { printf '[psql] %s\n' "$*"; }
die() { log "error: $*" >&2; exit 1; }
usage() {
  cat <<'USAGE'
Usage: scripts/psql.sh [--env-file PATH] [--] [psql args...]

Loads connection details from .env (or --env-file) and opens psql inside the
compose-managed Postgres container. Extra arguments after -- are passed to psql.
USAGE
}

psql_args=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --env-file)
      [[ $# -ge 2 ]] || die "--env-file requires a value"
      ENV_FILE="$2"
      shift
      ;;
    --help)
      usage
      exit 0
      ;;
    --)
      shift
      psql_args+=("$@")
      break
      ;;
    *)
      psql_args+=("$1")
      ;;
  esac
  shift
done

command -v docker >/dev/null 2>&1 || die "docker is not installed or not on PATH."
[[ -f "$COMPOSE_FILE" ]] || die "docker-compose.yml not found at $COMPOSE_FILE."
[[ -f "$ENV_FILE" ]] || die "Missing env file at $ENV_FILE. Copy .env.example to .env and set values."

# shellcheck source=/dev/null
set -a
source "$ENV_FILE"
set +a

DB_USER="${POSTGRES_USER:-mini_pos}"
DB_NAME="${POSTGRES_DB:-mini_pos}"
DB_PASSWORD="${POSTGRES_PASSWORD:-mini_pos_password}"

[[ -n "$DB_USER" ]] || die "POSTGRES_USER is empty in $ENV_FILE."
[[ -n "$DB_NAME" ]] || die "POSTGRES_DB is empty in $ENV_FILE."

if ! docker compose -f "$COMPOSE_FILE" ps -q "$SERVICE_NAME" | grep -q .; then
  log "Postgres is not running; starting it with docker compose up -d $SERVICE_NAME"
  docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" up -d "$SERVICE_NAME"
fi

log "Opening psql for database '$DB_NAME' as '$DB_USER' (env: $ENV_FILE)"
docker compose -f "$COMPOSE_FILE" exec \
  -e PGPASSWORD="$DB_PASSWORD" \
  "$SERVICE_NAME" \
  psql -U "$DB_USER" -d "$DB_NAME" "${psql_args[@]}"
