# Kinh nghiệm — ảnh

## L-030 · 2026-09-21 · hugo-không-nạp-thư-mục-static-mới
**Lỗi:** tạo `static/images/posts/<slug>/cover.png` xong, trang vẫn không hiện ảnh. Tưởng
ảnh hỏng hoặc đường dẫn sai — mất thời gian chẩn đoán.
**Nguyên nhân thật:** `hugo server` theo dõi các thư mục **đã tồn tại lúc khởi động**.
Thư mục con mới tạo dưới `static/` không được nạp. File và bản build ra đĩa đều đúng.
**Dấu hiệu:** `curl -sI http://localhost:1313/<đường dẫn ảnh>` trả 404 nhưng file có thật
và `public/` có ảnh.
**Cách xử lý:** khởi động lại `hugo server` sau khi tạo thư mục ảnh mới.

## L-031 · 2026-09-21 · SVG-không-dùng-cho-og:image
**Lỗi (tránh được):** định dùng thẳng SVG làm cover cho nhanh.
**Vì sao không được:** Hugo render SVG bình thường, nhưng Facebook/LinkedIn **không**
render SVG cho ảnh preview — mà đó đúng là chỗ cần nó.
**Luật:** giữ cả hai — `cover.svg` để sửa về sau, `cover.png` để dùng thật.

## L-032 · 2026-09-21 · phải-mở-ảnh-ra-nhìn
**Luật:** sau khi xuất PNG, **mở ảnh ra xem** bằng công cụ đọc ảnh. Chữ tràn khung, chữ
chồng nhau, chữ quá nhỏ khi thu nhỏ — không thứ nào lộ ra trong code SVG.

## L-033 · 2026-09-21 · thiếu-công-cụ-xuất-ảnh
**Bối cảnh:** máy không có `pip`, `PIL`, `cairosvg`, `rsvg-convert`.
**Cách xử lý:** `sudo apt install -y librsvg2-bin` rồi
`rsvg-convert -w 1200 -h 630 cover.svg -o cover.png`. Người dùng phải tự chạy lệnh `sudo`.
