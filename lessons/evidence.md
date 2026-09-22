# Kinh nghiệm — số liệu và bằng chứng

## L-010 · 2026-09-21 · số-bịa
**Lỗi:** bài viết ra con số "suite chậm thêm 1,2 giây" — không có trong `drafts/inbox.md`,
không có trong `bench/`, không có ở đâu cả. Sinh ra ngay lúc viết.
**Ai bắt:** người dùng hỏi "nguồn ở đâu vậy?".
**Vì sao lọt:** cổng đo chạy ở bước triage; sau khi mục thành `ready` thì không ai kiểm
lại, nên con số **mới sinh ra lúc viết** đi thẳng vào bài.
**Dấu hiệu:** con số **khiêm tốn và bất lợi cho tác giả** là loại dễ lọt nhất — nó nghe
như tự phê bình nên không gây nghi ngờ. Soi kỹ những con số làm mình xấu đi.
**Đã vá:** `/content-write` checklist mục 5 — liệt kê **từng** con số và truy nguồn từng cái.

## L-011 · 2026-09-21 · gộp-hai-loại-bằng-chứng
**Lỗi:** bài viết "Nguồn: bench/... — cùng máy, cùng một lần chạy phpunit". Sai: con số
1101→1184 đến từ codebase riêng tư, còn `bench/` là bản dựng lại và không bao giờ sinh
ra con số đó.
**Ai bắt:** người dùng hỏi "tại sao yêu cầu github, repo công ty private mà?".
**Dấu hiệu:** một câu "nguồn:" duy nhất trỏ tới `bench/` cho **mọi** con số trong bài A.
**Đã vá:** `CONTENT_STYLE.md` mục "Bằng chứng của thể loại A: tách hai loại".
Tự khai "số này bạn không kiểm chứng được" làm bài **đáng tin hơn**, không phải yếu đi.

## L-012 · 2026-09-21 · số-minh-họa-tưởng-là-thật
**Lỗi:** "Một mã hàng có 200 sản phẩm trong kho" trình bày như dữ kiện hệ thống thật,
trong khi chỉ là ví dụ.
**Đã vá:** số minh họa phải mở đầu bằng "Giả sử" / "Say". Ghi trong `/content-write` mục 5.

## L-013 · 2026-09-21 · link-không-bấm-được
**Lỗi:** bài ghi `` `bench/<slug>/` `` dạng text. Người đọc đang ở trên trang blog, không
có repo trong tay — nên lời mời "chạy lại được" là nói suông.
**Dấu hiệu:** tham chiếu `bench/` không nằm trong `[...](https://...)`.
**Đã vá:** `CONTENT_STYLE.md` mục Quy ước kỹ thuật — **bằng chứng không bấm vào được thì
không phải bằng chứng**. Thư mục bench phải trùng slug bài.
