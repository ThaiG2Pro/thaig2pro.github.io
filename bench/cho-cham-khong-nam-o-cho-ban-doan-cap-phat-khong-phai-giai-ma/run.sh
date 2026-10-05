#!/usr/bin/env bash
# Paired A/B of the version-chain read path in minidb across three pinned commits.
# Clones the public repo (no source is vendored here), then alternates benchmark runs
# before / fix1 / after, before / fix1 / after, ... so every side sees the same noise.
# Usage: ./run.sh [pairs]   default 10. Needs Go >= 1.26 and git. No Docker required.
set -euo pipefail
cd "$(dirname "$0")"
REPO=https://github.com/ThaiG2Pro/mini-kv-db.git
BEFORE=348f120   # 2026-09-02 state: DecodeChain builds the whole chain, tree copies the value out
FIX1=e48552f     # fix 1 (2026-10-01): lazy decoding (VisibleRaw); prediction said this alone would do
AFTER=4a4ef0f    # fix 2 (2026-10-01): GetFunc view + head() — no copy, no per-version struct
COPYBENCH=807b7be # BenchmarkCopyVsAlloc was added to the repo after fix 2
PAIRS="${1:-10}"
OUT="results-$(hostname)-$(date +%Y%m%d).txt"
clone() { [ -d "src-$1" ] || { git clone -q "$REPO" "src-$1" && git -C "src-$1" checkout -q "$1"; }; }
for c in $BEFORE $FIX1 $AFTER $COPYBENCH; do clone "$c"; done
for c in $BEFORE $FIX1 $AFTER; do   # warm the build cache so pair 1 is not penalised
  (cd "src-$c" && go test ./internal/txn/ -run '^$' -bench 'GetChainDepth/depth=1$/newest' -benchtime=1x >/dev/null)
done
{
  echo "# host: $(hostname)  date: $(date -Is)  go: $(go version)  pairs: $PAIRS"
  echo "# before=$BEFORE fix1=$FIX1 after=$AFTER copybench=$COPYBENCH"
  for i in $(seq "$PAIRS"); do
    for c in $BEFORE $FIX1 $AFTER; do
      echo "## pair $i  commit $c"
      (cd "src-$c" && go test ./internal/txn/ -run '^$' \
         -bench 'GetChainDepth/depth=(1|60)$/(newest|oldest)' -benchtime=200000x -benchmem) \
        | grep '^Benchmark'
    done
  done
  echo "## copy vs alloc  commit $COPYBENCH"
  (cd "src-$COPYBENCH" && go test ./internal/btree -run '^$' -bench CopyVsAlloc -benchmem -count 5) | grep '^Benchmark'
} | tee "$OUT"
echo; echo "wrote $OUT"; echo; ./ratio.py "$OUT"
