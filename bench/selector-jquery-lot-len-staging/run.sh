#!/usr/bin/env bash
# Runs the spec suite in a clean container. Nothing is installed on your machine.
# Requires Docker and a network connection for the one npm install.
set -euo pipefail
cd "$(dirname "$0")"

docker run --rm \
  --user "$(id -u):$(id -g)" \
  -e HOME=/tmp \
  -e npm_config_cache=/tmp/.npm \
  -v "$PWD:/bench" -w /bench \
  mcr.microsoft.com/playwright:v1.63.0-noble \
  bash -lc 'npm install --no-audit --no-fund --silent && npx playwright test'
