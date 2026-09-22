# Kinh nghiệm — bench

## L-020 · 2026-09-21 · chưa-chạy-thì-chưa-xong
**Lỗi:** bench đầu tiên "đúng về kỹ thuật" nhưng **chưa từng được thực thi**. Chạy thật
bằng Docker mới lộ ra 6 lỗi chặn:
1. thiếu hẳn class trung tâm mà test gọi tới (`service()` trỏ vào hư không)
2. `schema.sql` mồ côi — `RefreshDatabase` chạy thư mục `migrations/`, không đọc file .sql
3. namespace không khớp PSR-4 mặc định → trait và service không autoload
4. `new class extends Grammar {}` — Laravel 12 bắt constructor nhận `Connection`, mà
   anonymous class gọi constructor **ngay lúc định nghĩa** nên vá bằng reflection vô dụng
5. thư mục chưa `git add` → link trong bài 404
6. composer chặn cài Laravel 11 vì security advisory → không tái hiện được trên bản cũ
**Đã vá:** `/content-bench` — luật "chưa chạy thì chưa xong", bước 3 chạy Docker thật trên
**phiên bản mới nhất** của framework.

## L-021 · 2026-09-21 · bench-chứng-minh-nhầm-thứ
**Lỗi:** bench chứng minh *giải pháp hoạt động*, trong khi bài nói về *vì sao không ai
phát hiện ra vấn đề*. Hai thứ đó cần hai test khác nhau.
**Ai bắt:** người dùng, khi kịch bản bước 5 trong README không khớp thực tế chạy.
**Dấu hiệu:** đọc kịch bản chạy, hỏi "bước nào minh họa **phát hiện** của bài?" — không
có bước nào thì bench đang chứng minh nhầm.
**Đã vá:** thêm một test hành vi (`NaiveConcurrencyTest`) xanh ở **cả hai** cấu hình.
Chính sự tương phản giữa hai test mới là phát hiện.

## L-022 · 2026-09-21 · README-chạy-theo-code
**Lỗi (suýt):** khi bước chạy ra kết quả khác kỳ vọng, phản xạ là sửa README cho khớp.
**Luật:** sửa **code** hoặc sửa **kịch bản**, rồi chạy lại từ đầu. Sửa mỗi README là lặng
lẽ đổi lời hứa của bài.
**Đã vá:** `/content-bench` bước 3.
