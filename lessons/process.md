# Kinh nghiệm — quy trình và môi trường

## L-050 · 2026-09-21 · rò-rỉ-nằm-ngoài-content/
**Lỗi:** quét định danh chỉ làm ở tầng bài viết. Hai rò rỉ thật lại nằm chỗ khác:
1. `pipeline/state.json` — 12 dòng history ghi mã dự án nội bộ
2. `CONTENT_STYLE.md` — chính mục luật khử định danh lại **dùng định danh thật** làm ví dụ
**Đã vá:** `scripts/scan-identifiers.sh` + hook `pre-commit`, quét **mọi** file sắp commit.

## L-051 · 2026-09-22 · bộ-quét-tự-match-chính-nó
**Lỗi:** script quét báo lỗi trên chính comment của nó (các ví dụ regex). Và tệ hơn, một
comment chứa **số ticket thật**.
**Đã vá:** đánh dấu `scan-ok` ở cuối dòng để bỏ qua; gỡ định danh thật khỏi comment.

## L-052 · 2026-09-21 · đánh-dấu-xong-khi-còn-placeholder
**Lỗi:** `/content-derive` sinh bản social còn `<link EN>`, `<link VI>`, `<link bench>`
nhưng đã đánh dấu mục là `done`. Dán lên là ra chữ trong ngoặc nhọn.
**Ai bắt:** người dùng, hôm sau — "mới tới phần social nhỉ? đã xong đâu".
**Luật:** file tồn tại không có nghĩa việc đã xong. Điền URL thật, `curl` kiểm 200.
**Đã vá:** `/content-derive` mục "Link phải thật, không được để placeholder".

## L-053 · 2026-09-21 · skill-không-nạp
**Lỗi:** gọi `/content-status` báo Unknown skill.
**Nguyên nhân:** Claude Code quét `.claude/skills/` ở **thư mục gốc của phiên**. Phiên mở
ở thư mục cha, còn skill nằm trong thư mục con chứa repo.
**Cách xử lý:** mở Claude Code từ **trong** repo blog. Skill mới tạo cũng cần mở lại phiên.

## L-054 · 2026-09-21 · skill-ôm-quá-nhiều-việc
**Lỗi:** `/content-write` ôm cả viết content, vẽ ảnh, lẫn code bench. Kết quả: content phải
sửa 3 vòng, ảnh bị đẩy sang "người dùng tự lo", bench viết ra 6 lỗi chặn.
**Luật:** mỗi skill một chuyên môn. Tách ra thì luật của từng skill mới đủ sâu.
**Đã vá:** tách `/content-artwork` và `/content-bench`.
