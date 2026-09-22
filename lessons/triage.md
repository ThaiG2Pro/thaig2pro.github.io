# Kinh nghiệm — phân luồng

## L-040 · 2026-09-21 · lọc-theo-bằng-chứng-không-theo-chủ-đề
**Nguyên tắc gốc:** độ sâu của bài không phải thứ bạn chọn — nó là thứ bạn **có hoặc
không có**. Lọc theo chủ đề sẽ dẫn tới "chủ đề này sâu đấy, viết thể loại A đi", rồi phải
bịa phần Situation.
**Dấu hiệu sai:** đang quyết định thể loại mà chưa nhìn vào `evidence` của mục đó.

## L-041 · 2026-09-21 · một-nguyên-liệu-ra-nhiều-bài
**Lỗi:** ép mỗi mục inbox thành đúng một bài là vứt bỏ vật liệu.
**Ví dụ:** cùng một việc ra được bản giới thiệu VI (C) + bản benchmark EN (B); một sự cố
ra được bài kỹ thuật (A) + bài chuyện nghề (D).
**Cách làm:** tạo mục riêng cho từng bài, đừng chọn một.

## L-042 · 2026-09-21 · ranh-giới-A-và-B
**Hay nhầm:** A là "hệ thống của tôi đang chạy và tôi đã sửa nó". B là "tôi dựng phép đo
để trả lời một câu hỏi". Không có hệ thống thật thì **không phải A**, dù chủ đề sâu đến đâu.
Một mục đã bị phân nhầm A, sửa lại thành B khi thấy đó là phép đo tự dựng.

## L-043 · 2026-09-21 · chặn-phải-kèm-việc-cụ-thể
**Lỗi:** ghi "cần đo thêm" là vô dụng — người dùng không bắt đầu được.
**Đúng:** "chèn 1M bản ghi vào Postgres 16, đo `pg_relation_size`, 5 lần chạy, ~1 buổi tối".
