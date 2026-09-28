#!/usr/bin/env bash
# Runs bench.sql at each size inside a throwaway MariaDB container.
# Usage: ./run.sh [sizes...]   default: 3217 100000 1000000
#   MARIADB_IMAGE=mariadb:10.11 ./run.sh   to try another version
set -euo pipefail
cd "$(dirname "$0")"
IMAGE="${MARIADB_IMAGE:-mariadb:latest}"
SIZES=("${@:-3217 100000 1000000}")
NAME="vb-$$"
docker run -d --rm --name "$NAME" -e MARIADB_ALLOW_EMPTY_ROOT_PASSWORD=1 \
  -v "$PWD/bench.sql:/bench.sql:ro" "$IMAGE" >/dev/null
trap 'docker rm -f "$NAME" >/dev/null 2>&1 || true' EXIT
# the entrypoint starts a temporary server first; wait for the real one
for _ in $(seq 90); do
  docker exec "$NAME" healthcheck.sh --connect --innodb_initialized >/dev/null 2>&1 && break; sleep 1
done
echo "image: $IMAGE"; docker exec "$NAME" mariadb -N -e 'SELECT VERSION()'
for n in ${SIZES[@]}; do
  echo; echo "=== order_vouchers = $n rows ==="
  docker exec "$NAME" bash -c "{ echo 'SET @n = $n;'; cat /bench.sql; } | mariadb -t"
done
