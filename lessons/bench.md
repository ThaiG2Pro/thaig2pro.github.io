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

## L-064 · 2026-10-05 · bench-đúng-lần-đầu-sai-lần-hai
**Lỗi:** README và bài hướng dẫn `./run.sh 10 && ./ratio.py results-*.txt`. Lần chạy đầu
thư mục trống nên đúng. Người kiểm chạy lại: glob khớp file kết quả **cũ** của tác giả
trước (xếp theo abc), `ratio.py` in lại số của tác giả, trông như tái hiện được 100%.
**Ai bắt:** `/content-audit` vòng 3, khi so số in ra với file vừa sinh.
**Vì sao lọt:** `/content-bench` chạy thật một lần trên thư mục sạch. Lần hai mới có file
cũ để nhầm.
**Dấu hiệu:** lệnh hậu xử lý nhận glob hoặc "file mới nhất" ngầm; thư mục bench đã có
`results-*` commit sẵn.
**Đã vá:** `run.sh` tự gọi `ratio.py "$OUT"` trên đúng file vừa ghi; README nói rõ không
truyền glob. Luật cho `/content-bench` bước 3: chạy **hai lần** liên tiếp, lần hai phải
đọc đúng kết quả lần hai.

## L-066 · 2026-10-05 · thứ-tự-từ-một-lần-chạy
**Lỗi:** README bench và cả hai bản bài bo-dem-cung-ten viết "bench tái hiện được thứ tự mất
dữ liệu giữa các chế độ", dựa trên đúng một lượt `crash 5` (2 / 3653 / 7034). Audit chạy lại ra
3 / 3535 / 2058, lượt lưu thứ hai ra 4 / 4756 / 3809: hai chế độ sau đổi chỗ.
**Ai bắt:** `/content-audit` vòng 3, agent độc lập chạy lại bench.
**Vì sao lọt:** luật "chạy hai lần" của L-064 chỉ nói lần hai phải **đọc đúng file** của lần
hai. Nó không bắt **so** kết quả hai lần. Ở bài này, `lograte` và `crash` lại được chạy riêng
từng phần, nên toàn bộ kịch bản chưa từng chạy đủ hai lần.
**Dấu hiệu:** README khẳng định một **thứ tự** hoặc một **so sánh** giữa các chế độ, trong khi
`results/` chỉ có một file cho mỗi chế độ. Số mẫu nhỏ (5 lần kill) mà chênh giữa hai chế độ
nhỏ hơn dao động giữa các vòng.
**Đã vá:** lỗi lặp lần hai của nhóm "bench chỉ chạy một lần" (L-064) → nâng luật
`/content-bench` bước 3: chạy **toàn bộ** kịch bản hai lần, đặt kết quả cạnh nhau, README chỉ
khẳng định thứ đứng vững ở cả hai. `run.sh` của bài này tự lưu mọi lượt vào `results/run-*.txt`.
