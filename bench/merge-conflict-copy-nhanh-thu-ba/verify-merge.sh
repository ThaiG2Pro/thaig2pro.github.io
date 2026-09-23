#!/usr/bin/env bash
# Two-parent provenance check for one file in a merge commit.
#
#   verify-merge.sh <repo-dir> <merge-commit> <path>
#
# Every merge commit has exactly two true parents (git show -s --format=%P).
# A line that the merge ADDED relative to the merge-base must have been added
# by parent 1 or parent 2 relative to that same base; a line the merge REMOVED
# must have been removed by one of them. Anything else came from somewhere
# else (a third branch, a hand edit) and is printed as stray.
#
# Exit 0 = every line explained. Exit 1 = at least one stray line.
# Output: one line per finding, "STRAY_ADDED <text>" / "STRAY_REMOVED <text>",
# then a final "SUMMARY added=<n> removed=<n>".
set -eu
repo=$1; merge=$2; path=$3
cd "$repo"

parents=$(git show -s --format='%P' "$merge")
p1=${parents%% *}; p2=${parents##* }
if [ "$p1" = "$p2" ]; then echo "not a merge commit: $merge" >&2; exit 2; fi
base=$(git merge-base "$p1" "$p2")

# Added/removed line sets vs merge-base, -U0 so no context lines, headers stripped.
added()   { git diff -U0 --no-color "$base" "$1" -- "$path" | grep '^+' | grep -v '^+++' | cut -c2- | sort -u; }
removed() { git diff -U0 --no-color "$base" "$1" -- "$path" | grep '^-' | grep -v '^---' | cut -c2- | sort -u; }

explained_add=$( { added "$p1" || true; added "$p2" || true; } | sort -u)
explained_rm=$(  { removed "$p1" || true; removed "$p2" || true; } | sort -u)

stray_add=$(comm -23 <(added "$merge" || true) <(printf '%s\n' "$explained_add"))
stray_rm=$( comm -23 <(removed "$merge" || true) <(printf '%s\n' "$explained_rm"))

na=0; nr=0
if [ -n "$stray_add" ]; then while IFS= read -r l; do echo "STRAY_ADDED $l"; na=$((na+1)); done <<<"$stray_add"; fi
if [ -n "$stray_rm" ];  then while IFS= read -r l; do echo "STRAY_REMOVED $l"; nr=$((nr+1)); done <<<"$stray_rm"; fi
echo "SUMMARY added=$na removed=$nr base=$(git rev-parse --short "$base") p1=$(git rev-parse --short "$p1") p2=$(git rev-parse --short "$p2")"
[ "$na" -eq 0 ] && [ "$nr" -eq 0 ]
