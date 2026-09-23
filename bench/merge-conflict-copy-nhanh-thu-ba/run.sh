#!/usr/bin/env bash
# One command. Needs: git >= 2.20, bash, coreutils (comm, sort, cut).
# Builds a tiny repo in raw/repo (gitignored), replays three ways of resolving
# the same conflict, runs two verifications on each, writes results/.
set -eu
cd "$(dirname "$0")"
HERE=$PWD
REPO=$HERE/raw/repo
FILE=kernel.txt
rm -rf "$REPO"; mkdir -p "$REPO" "$HERE/results"

# Fixed identity + timestamps so commit hashes are identical on every machine.
export GIT_AUTHOR_NAME=bench GIT_AUTHOR_EMAIL=bench@example.invalid
export GIT_COMMITTER_NAME=bench GIT_COMMITTER_EMAIL=bench@example.invalid
export GIT_AUTHOR_DATE='2026-09-22T17:00:00+07:00' GIT_COMMITTER_DATE='2026-09-22T17:00:00+07:00'
g() { git -C "$REPO" "$@"; }

# ---------- 1. history: base -> staging(B), feature(A), development(C) ----------
g init -q -b main
mkdir -p "$REPO/middleware"
for m in TrustProxies HandleCors TrimStrings EncryptCookies StartSession ThrottleRequests SubstituteBindings; do
  echo "class $m" > "$REPO/middleware/$m.txt"
done
cat > "$REPO/$FILE" <<'K'
# HTTP middleware stack (demo, not real code)
global:
  TrustProxies
  HandleCors
  TrimStrings
route-groups:
  web:
    EncryptCookies
    StartSession
  api:
    ThrottleRequests
    SubstituteBindings
K
g add -A; g commit -qm 'base kernel'

# staging (B): adds one api middleware right after ThrottleRequests
g checkout -qb staging
sed -i 's/^    ThrottleRequests$/    ThrottleRequests\n    CheckTenantHeader/' "$REPO/$FILE"
echo 'class CheckTenantHeader' > "$REPO/middleware/CheckTenantHeader.txt"
g add -A; g commit -qm 'staging: tenant header check'

# feature (A): adds a different api middleware at the SAME spot -> real conflict
g checkout -q main; g checkout -qb feature
sed -i 's/^    ThrottleRequests$/    ThrottleRequests\n    VerifyApiSignature/' "$REPO/$FILE"
echo 'class VerifyApiSignature' > "$REPO/middleware/VerifyApiSignature.txt"
g add -A; g commit -qm 'feature: api signature'

# development (C): integration branch, has A and B already, PLUS an unrelated
# ticket's RateLimitByPlan (and its class file) that staging never received.
g checkout -q main; g checkout -qb development
g merge -q --no-edit staging
g merge feature >/dev/null 2>&1 || true            # conflicts; resolve = keep both
cat > "$REPO/$FILE" <<'K'
# HTTP middleware stack (demo, not real code)
global:
  TrustProxies
  HandleCors
  TrimStrings
route-groups:
  web:
    EncryptCookies
    StartSession
  api:
    ThrottleRequests
    CheckTenantHeader
    VerifyApiSignature
    SubstituteBindings
K
g add -A; g commit -qm 'development: merge feature'
sed -i 's/^    VerifyApiSignature$/    VerifyApiSignature\n    RateLimitByPlan/' "$REPO/$FILE"
echo 'class RateLimitByPlan' > "$REPO/middleware/RateLimitByPlan.txt"
g add -A; g commit -qm 'development: rate limit by plan (other ticket)'

# ---------- 2. the merge under test: staging <- feature, three resolutions ----------
# verify1 = what was actually done in the incident: diff the result against the
#           branch you merged into and ask only "did any line disappear?"
verify1() { # $1 = merge commit ; prints removed-line count vs parent 1 (staging)
  local p1; p1=$(g show -s --format='%P' "$1" | cut -d' ' -f1)
  g diff -U0 --no-color "$p1" "$1" -- "$FILE" | grep '^-' | grep -v '^---' | wc -l
}
# boot = does every middleware named in the file exist as a class in that tree?
boot() { # $1 = commit ; prints missing class names
  g show "$1:$FILE" | grep -E '^ {2,}[A-Za-z]+$' | tr -d ' ' | while read -r m; do
    g cat-file -e "$1:middleware/$m.txt" 2>/dev/null || echo "$m"
  done
}

resolve() { # $1 = branch name for this scenario, $2 = how to fill the file
  g checkout -q staging; g checkout -qb "$1"
  g merge feature >/dev/null 2>&1 || true
  case $2 in
    copy-third-branch) g checkout development -- "$FILE" ;;
    correct)           g show development~1:"$FILE" > "$REPO/$FILE" ;;
    drop-a-line)       g show development~1:"$FILE" | grep -v '^    StartSession$' > "$REPO/$FILE" ;;
  esac
  g add "$FILE"; g commit -qm "merge feature into staging ($2)"
}

json="{ \"date\": \"$(date -u +%F)\", \"git\": \"$(git --version | cut -d' ' -f3)\", \"scenarios\": ["
first=1
: > "$HERE/results/run.log"
for sc in correct copy-third-branch drop-a-line; do
  resolve "merge-$sc" "$sc"
  m=$(g rev-parse HEAD)
  v1=$(verify1 "$m")
  v2out=$("$HERE/verify-merge.sh" "$REPO" "$m" "$FILE" || true)
  stray_added=$(grep -c '^STRAY_ADDED' <<<"$v2out" || true)
  stray_removed=$(grep -c '^STRAY_REMOVED' <<<"$v2out" || true)
  stray_lines=$(grep '^STRAY_' <<<"$v2out" | sed 's/^STRAY_[A-Z]* *//' | sed 's/"/\\"/g' | awk '{printf "%s\"%s\"", (NR>1?",":""), $0}')
  missing=$(boot "$m" | awk '{printf "%s\"%s\"", (NR>1?",":""), $0}')
  v1pass=$([ "$v1" -eq 0 ] && echo true || echo false)
  v2pass=$([ "$stray_added" -eq 0 ] && [ "$stray_removed" -eq 0 ] && echo true || echo false)
  bootpass=$([ -z "$missing" ] && echo true || echo false)
  {
    echo "== scenario: $sc  merge=$(g rev-parse --short "$m")  parents=$(g show -s --format='%P' "$m" | sed 's/\([0-9a-f]\{7\}\)[0-9a-f]*/\1/g')"
    echo "-- verify 1 (diff vs staging only, count '-' lines): $v1  -> $([ "$v1pass" = true ] && echo PASS || echo FAIL)"
    echo "-- verify 2 (two-parent provenance):"; sed 's/^/   /' <<<"$v2out"
    echo "   -> $([ "$v2pass" = true ] && echo PASS || echo FAIL)"
    echo "-- boot check (every listed middleware has a class in this tree): $([ "$bootpass" = true ] && echo PASS || echo "FAIL missing=[$missing]")"
    echo
  } | tee -a "$HERE/results/run.log"
  [ $first = 1 ] || json+=","; first=0
  json+="{ \"scenario\": \"$sc\", \"verify1_removed_lines\": $v1, \"verify1_pass\": $v1pass,"
  json+=" \"verify2_stray_added\": $stray_added, \"verify2_stray_removed\": $stray_removed, \"verify2_stray_lines\": [$stray_lines], \"verify2_pass\": $v2pass,"
  json+=" \"boot_missing_classes\": [$missing], \"boot_pass\": $bootpass }"
done
json+=" ] }"
printf '%s\n' "$json" | python3 -m json.tool > "$HERE/results/summary.json" 2>/dev/null || printf '%s\n' "$json" > "$HERE/results/summary.json"
g log --oneline --graph --all > "$HERE/results/history.txt"
echo "results/summary.json written"
