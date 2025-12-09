#!/usr/bin/env bash
set -euo pipefail

# Stop compose services; add -v/--volumes to remove volumes too.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMPOSE_FILE="$ROOT_DIR/docker-compose.yml"

log() { printf '[compose-down] %s\n' "$*"; }
die() { log "error: $*" >&2; exit 1; }
usage() {
  cat <<'USAGE'
Usage: scripts/compose-down.sh [-v|--volumes] [--remove-orphans]

Stops services defined in docker-compose.yml from the project root.
USAGE
}

command -v docker >/dev/null 2>&1 || die "docker is not installed or not on PATH."
[[ -f "$COMPOSE_FILE" ]] || die "docker-compose.yml not found at $COMPOSE_FILE."

args=(docker compose -f "$COMPOSE_FILE" down)
while [[ $# -gt 0 ]]; do
  case "$1" in
    -v|--volumes) args+=(-v) ;;
    --remove-orphans) args+=(--remove-orphans) ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown option: $1 (use --help for usage)" ;;
  esac
  shift
done

log "Running: ${args[*]}"
"${args[@]}"
