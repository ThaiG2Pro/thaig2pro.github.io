#!/usr/bin/env bash
# Same counter name, different meaning: when does redo leave the process?
#
#   ./run.sh lograte        # 3 s probe per mode, counters sampled every 5 ms
#   ./run.sh crash [N]      # kill -9 N times per mode (default 5), count lost commits
#   ./run.sh all [N]
#
# Needs only Docker. Images: MYSQL_IMAGE (default mysql:8.4),
# MARIADB_IMAGE (default mariadb:11.8).
set -euo pipefail
cd "$(dirname "$0")"

MYSQL_IMAGE=${MYSQL_IMAGE:-mysql:8.4}
MARIADB_IMAGE=${MARIADB_IMAGE:-mariadb:11.8}
NET=bench-redo
PW=bench

img() { [ "$1" = mysql ] && echo "$MYSQL_IMAGE" || echo "$MARIADB_IMAGE"; }
bin() { [ "$1" = mysql ] && echo mysql || echo mariadb; }

# q <kind> [args...] — run SQL from stdin against the bench DB, tab-separated, no header.
q() {
  local kind=$1; shift
  docker run --rm -i --network "$NET" "$(img "$kind")" \
    "$(bin "$kind")" -h "bench-$kind" -uroot -p"$PW" -N -B b "$@" 2> >(grep -v -i 'warning' >&2)
}

wait_db() {
  for _ in $(seq 1 90); do
    echo "SELECT 1" | q "$1" >/dev/null 2>&1 && return 0
    sleep 2
  done
  echo "bench-$1 did not come up" >&2; exit 1
}

start_db() {
  local kind=$1
  docker rm -f "bench-$kind" >/dev/null 2>&1 || true
  if [ "$kind" = mysql ]; then
    # Same flags as the measurements in the post (native AIO is unreliable on WSL2).
    docker run -d --name bench-mysql --network "$NET" -e MYSQL_ROOT_PASSWORD="$PW" \
      -e MYSQL_DATABASE=b "$MYSQL_IMAGE" --innodb-buffer-pool-size=256M \
      --innodb_use_native_aio=0 --innodb_flush_method=fsync >/dev/null
  else
    docker run -d --name bench-mariadb --network "$NET" -e MARIADB_ROOT_PASSWORD="$PW" \
      -e MARIADB_DATABASE=b "$MARIADB_IMAGE" --innodb-buffer-pool-size=256M >/dev/null
  fi
  wait_db "$kind"
  settings "$kind"
}

# Print the runtime values the post relies on (not compile-time defaults).
settings() {
  if [ "$1" = mysql ]; then
    echo "SELECT CONCAT('settings mysql: version=', @@version, ' flush_method=', @@innodb_flush_method,
      ' log_writer_threads=', @@innodb_log_writer_threads, ' flush_log_at_timeout=', @@innodb_flush_log_at_timeout)" | q mysql
  else
    echo "SELECT CONCAT('settings mariadb: version=', @@version, ' flush_method=', @@innodb_flush_method,
      ' log_file_buffering=', @@innodb_log_file_buffering, ' flush_log_at_timeout=', @@innodb_flush_log_at_timeout)" | q mariadb
  fi
}

# Modes: "<kind>|<label>|<SET statements>"
MODES=(
  "mysql|=0 + sync_binlog=0|SET GLOBAL innodb_flush_log_at_trx_commit=0; SET GLOBAL sync_binlog=0; SET GLOBAL innodb_log_writer_threads=ON;"
  "mysql|=0 + sync_binlog=0 + log_writer=OFF|SET GLOBAL innodb_flush_log_at_trx_commit=0; SET GLOBAL sync_binlog=0; SET GLOBAL innodb_log_writer_threads=OFF;"
  "mariadb|flush_log_at_trx_commit=0|SET GLOBAL innodb_flush_log_at_trx_commit=0;"
)

fresh_table() { echo "DROP TABLE IF EXISTS t; CREATE TABLE t (id BIGINT PRIMARY KEY) ENGINE=InnoDB;" | q "$1"; }

# Load: one INSERT per statement (autocommit = one commit each), followed by
# SELECT <id>. The client prints <id> only after the INSERT returned, so the
# last number in the log is the last commit the server acknowledged.
start_load() {
  local kind=$1
  docker rm -f bench-load >/dev/null 2>&1 || true
  docker run -d --name bench-load --network "$NET" "$(img "$kind")" bash -c \
    "i=0; while :; do i=\$((i+1)); echo \"INSERT INTO t VALUES(\$i); SELECT \$i;\"; done \
     | $(bin "$kind") -h bench-$kind -uroot -p$PW -N -B --unbuffered b" >/dev/null
}
last_acked() { docker logs bench-load 2>/dev/null | grep -E '^[0-9]+$' | tail -1 || true; }

# analyze <file>: columns t n os_log_written lsn_current lsn_flushed
analyze() {
  awk -v label="$2" '
    NR==1 { t0=$1; n0=$2; for (c=3;c<=5;c++) { prev[c]=$c; first[c]=$c } next }
    { for (c=3;c<=5;c++) if ($c!=prev[c]) {
        if (last[c]!="") { k[c]++; g[c,k[c]]=($1-last[c])*1000 }
        last[c]=$1; jumps[c]++; prev[c]=$c } t1=$1; n1=$2 }
    function med(c,  i,j,x,m) { m=k[c]; if (m==0) return "-"
      for (i=1;i<=m;i++) a[i]=g[c,i]
      for (i=2;i<=m;i++) { x=a[i]; for (j=i-1;j>=1 && a[j]>x;j--) a[j+1]=a[j]; a[j+1]=x }
      return sprintf("%.1fms", (m%2) ? a[(m+1)/2] : (a[m/2]+a[m/2+1])/2) }
    function mx(c,  i,v) { v=0; for (i=1;i<=k[c];i++) if (g[c,i]>v) v=g[c,i]; return k[c] ? sprintf("%.1fms", v) : "-" }
    END {
      split("os_log_written lsn_current lsn_flushed", nm, " ")
      printf "%-40s commit/s %6.0f   (%.2f s, %d samples)\n", label, (n1-n0)/(t1-t0), t1-t0, NR
      for (c=3;c<=5;c++)
        printf "    %-16s jumps %4d  gap p50 %9s  gap max %9s  delta %12d bytes\n", nm[c-2], jumps[c], med(c), mx(c), prev[c]-first[c]
    }' "$1"
}

lograte() {
  echo "== lograte: counters sampled every 5 ms for 3 s, inserts running =="
  local m kind label set
  for m in "${MODES[@]}"; do
    IFS='|' read -r kind label set <<<"$m"
    [ "$(docker inspect -f '{{.State.Running}}' "bench-$kind" 2>/dev/null)" = true ] || start_db "$kind"
    fresh_table "$kind"
    q "$kind" < "probe-$kind.sql"
    echo "$set" | q "$kind"
    start_load "$kind"; sleep 1
    echo "CALL probe(3000)" | q "$kind"
    docker rm -f bench-load >/dev/null
    local out="results/samples-$kind-$(echo "$label" | tr -c 'a-zA-Z0-9=\n' '_').tsv"
    echo "SELECT UNIX_TIMESTAMP(t), n, os_log_written, lsn_current, lsn_flushed FROM samples ORDER BY t" \
      | q "$kind" > "$out"
    analyze "$out" "$kind $label"
  done
}

crash() {
  local rounds=${1:-5}
  echo "== crash: kill -9 after 1-3 s of inserts, $rounds rounds per mode =="
  printf "%-46s %8s %8s %6s\n" "mode" "acked" "lost" "extra"
  local m kind label set r last have extra tot_ack tot_lost tot_extra
  for m in "${MODES[@]}"; do
    IFS='|' read -r kind label set <<<"$m"
    tot_ack=0; tot_lost=0; tot_extra=0
    for r in $(seq 1 "$rounds"); do
      [ "$(docker inspect -f '{{.State.Running}}' "bench-$kind" 2>/dev/null)" = true ] || start_db "$kind"
      fresh_table "$kind"
      echo "$set" | q "$kind"
      start_load "$kind"
      sleep "$(awk -v s="$RANDOM" 'BEGIN { printf "%.2f", 1 + 2 * s / 32767 }')"
      docker kill -s KILL "bench-$kind" >/dev/null
      docker wait bench-load >/dev/null
      last=$(last_acked); last=${last:-0}
      docker rm -f bench-load >/dev/null
      docker start "bench-$kind" >/dev/null; wait_db "$kind"
      have=$(echo "SELECT COUNT(*) FROM t WHERE id <= $last" | q "$kind")
      extra=$(echo "SELECT COUNT(*) FROM t WHERE id > $last" | q "$kind")
      echo "    round $r: acked $last, lost $((last - have)), extra $extra" >&2
      tot_ack=$((tot_ack + last)); tot_lost=$((tot_lost + last - have)); tot_extra=$((tot_extra + extra))
    done
    printf "%-46s %8d %8d %6d\n" "$kind $label" "$tot_ack" "$tot_lost" "$tot_extra"
  done
}

cleanup() { docker rm -f bench-load bench-mysql bench-mariadb >/dev/null 2>&1 || true; docker network rm "$NET" >/dev/null 2>&1 || true; }
trap cleanup EXIT

docker network create "$NET" >/dev/null 2>&1 || true
mkdir -p results
# Every run is saved: one run is not evidence of an ordering.
exec > >(tee "results/run-$(date +%Y-%m-%d-%H%M).txt") 2>&1
echo "images: $MYSQL_IMAGE, $MARIADB_IMAGE · $(date -Iseconds)"
case "${1:-all}" in
  lograte) lograte ;;
  crash)   crash "${2:-5}" ;;
  all)     lograte; crash "${2:-5}" ;;
  *) echo "usage: $0 [lograte|crash [N]|all [N]]" >&2; exit 2 ;;
esac
