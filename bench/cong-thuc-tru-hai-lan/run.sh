#!/usr/bin/env bash
# One command. Uses local python3 (3.8+) if present, otherwise python:3.12-alpine via Docker.
set -u
cd "$(dirname "$0")"
if command -v python3 >/dev/null 2>&1; then
  python3 check.py
else
  docker run --rm -v "$PWD:/b" -w /b python:3.12-alpine python3 check.py
fi
