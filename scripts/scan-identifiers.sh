#!/usr/bin/env bash
# Quét định danh nội bộ trong các file SẮP COMMIT.
#
# Vì sao tồn tại: repo này công khai, nhưng nguyên liệu content đến từ công việc
# riêng tư. Hai rò rỉ thật đã xảy ra NGOÀI thư mục content/ — một trong pipeline
# state, một trong chính file spec dạy cách khử định danh. Kiểm bằng mắt ở tầng
# bài viết là không đủ.
#
# Mẫu dưới đây là REGEX CHUNG, không phải định danh thật — file này cũng công khai.
# Từ khóa riêng của công ty đặt ở .git/identifiers.local (không bao giờ commit),
# mỗi dòng một regex; dòng trống và dòng bắt đầu bằng # bị bỏ qua.
#
# Dương tính giả: thêm chuỗi scan-ok vào cuối dòng đó (trong comment) thì dòng
# được bỏ qua. Dùng cho tài liệu buộc phải nhắc tới dạng định danh.

set -uo pipefail
cd "$(git rev-parse --show-toplevel)" || exit 1

PATTERNS=(
  '\b[a-z]{3,}-[0-9]{4,6}\b'         # ma du an / ticket
  '(^|[^&#[:alnum:]])#[0-9]{4,6}\b'  # so ticket
  '\b[0-9a-f]{9,40}\b'               # commit hash
  'Modules?/[A-Z][A-Za-z]+'          # duong dan module noi bo
  '\b[A-Z]{2,}[0-9]{5,}[A-Z0-9-]*'   # ma hang / ma khach
  '\b(j''ira|red''mine|conf''luence)\b'
  'gitlab\.[a-z-]+\.[a-z]{2,}'
)

LOCAL=".git/identifiers.local"
if [[ -f "$LOCAL" ]]; then
  while IFS= read -r line; do
    [[ -z "$line" || "$line" == \#* ]] && continue
    PATTERNS+=("$line")
  done < "$LOCAL"
fi

EXCLUDE='^(themes|public|resources/_gen)/|\.(png|jpe?g|gif|webp|ico|svg|woff2?|ttf|pdf|lock)$|^\.gitmodules$'
# Có đối số -> quét đúng các file đó (skill gọi tay). Không có -> quét staged (hook pre-commit).
if [[ $# -gt 0 ]]; then
  FILES=$(printf '%s\n' "$@" | sed 's|^\./||' | grep -vE "$EXCLUDE" || true)
else
  FILES=$(git diff --cached --name-only --diff-filter=ACM | grep -vE "$EXCLUDE" || true)
fi
[[ -z "$FILES" ]] && { echo "Quét định danh: không có file nào để quét."; exit 0; }
NFILES=$(printf '%s\n' "$FILES" | grep -c .)

HITS=0
while IFS= read -r f; do
  [[ -f "$f" ]] || continue
  for p in "${PATTERNS[@]}"; do
    while IFS= read -r line; do
      [[ -z "$line" ]] && continue
      # bỏ qua dòng được đánh dấu dương tính giả
      lineno=${line%%:*}
      content=$(sed -n "${lineno}p" "$f" 2>/dev/null)
      [[ "$content" == *scan-ok* ]] && continue
      echo "  $f:$line"
      HITS=$((HITS + 1))
    done < <(grep -nEo "$p" "$f" 2>/dev/null | head -5)
  done
done <<< "$FILES"

if [[ $HITS -gt 0 ]]; then
  cat <<'EOF'

Quét định danh: có chỗ khả nghi ở trên.

Mỗi chỗ chọn một cách:
  - Định danh nội bộ thật -> sửa file (CONTENT_STYLE.md mục 3b)
  - Dương tính giả        -> thêm scan-ok vào cuối dòng đó, hoặc git commit --no-verify
EOF
  exit 1
fi

echo "Quét định danh: sạch ($NFILES file)."
