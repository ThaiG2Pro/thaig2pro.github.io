#!/usr/bin/env bash
# Runs the bench twice inside php:8.2-cli: once with the original lookup,
# once with the fix. Needs Docker and nothing else.
set -u
cd "$(dirname "$0")"

IMAGE="${PHP_IMAGE:-php:8.2-cli}"
run() { docker run --rm -v "$PWD:/b:ro" -w /b "$IMAGE" php run.php "$1"; }

echo "=== 1/2 BROKEN — the original lookup ==="
run broken; broken_rc=$?
echo
echo "=== 2/2 FIXED — lookup by (SKU, campaign) pair ==="
run fixed; fixed_rc=$?
echo

# Expected pattern: BROKEN has a failure (test 2), FIXED is clean.
if [ "$broken_rc" -ne 0 ] && [ "$fixed_rc" -eq 0 ]; then
  echo "Bench reproduces the finding: test 1 is green on the broken code, test 2 is not."
  exit 0
fi
echo "Unexpected pattern (broken rc=$broken_rc, fixed rc=$fixed_rc) — read the output above."
exit 1
