---
name: content-artwork
description: Thiết kế và dựng ảnh cho bài blog — ảnh cover 1200×630 và sơ đồ kiến trúc trong bài, viết bằng SVG rồi xuất PNG. Dùng skill này khi một bài ở stage needs-assets, khi người dùng nói "làm ảnh cover", "vẽ sơ đồ cho bài", "thiếu ảnh", "ảnh bìa trông chán", "làm lại cái hình", hoặc khi checklist publish báo thiếu file ảnh. Dùng cả khi cần sửa một ảnh đã có cho hợp với nội dung bài hơn.
---

# Dựng ảnh cho bài

Ảnh cover là thứ duy nhất của bài xuất hiện trên trang chủ, trên LinkedIn và trong kết
quả tìm kiếm. Nó phải **kể được ý chính của bài trong hai giây**, không phải làm nền
cho cái tiêu đề.

## Nguyên tắc thiết kế

Trước khi vẽ, trả lời: *ý bất ngờ nhất của bài là gì, và nó có hình dạng không?*

- **Có hình dạng** → vẽ chính nó. Bài về một câu SQL mất đi mệnh đề khóa thì vẽ hai câu
  SQL chồng lên nhau, câu dưới thiếu một ô. Người đọc hiểu trước cả khi đọc tiêu đề.
- **Không có hình dạng** → vẽ cái đối lập, hoặc vẽ con số. Đừng vẽ icon chung chung
  (ổ khóa, bóng đèn, bánh răng) — chúng không nói gì và trông như ảnh stock.

Tránh: chữ tiêu đề to phủ kín ảnh, gradient tím, hình người, logo công nghệ.

## Quy ước kỹ thuật

- **Cover:** 1200×630 (tỷ lệ Open Graph). Sơ đồ trong bài: rộng 1200, cao tùy nội dung.
- Vẽ bằng **SVG viết tay**, lưu `cover.svg` cạnh file PNG — sửa lại về sau rẻ hơn nhiều
  so với sửa ảnh bitmap.
- Xuất PNG: `rsvg-convert -w 1200 -h 630 cover.svg -o cover.png`
  (thiếu công cụ thì bảo người dùng chạy `sudo apt install -y librsvg2-bin`).
- Đường dẫn: `static/images/posts/<slug>/cover.png`, tham chiếu trong bài luôn có `/` đầu.
- Font: chỉ dùng họ generic (`ui-monospace, monospace` hoặc `serif`) — SVG render trên
  máy khác không có font riêng của bạn.
- Nền tối hợp với cả giao diện sáng lẫn tối của blog. Chữ tối thiểu 22px ở khổ 1200 để
  còn đọc được khi thu nhỏ thành thumbnail.
- **Xem lại ảnh sau khi xuất** bằng công cụ đọc ảnh, đừng tin vào code SVG. Chữ tràn
  khung và chữ chồng nhau chỉ lộ ra khi nhìn.

## Sau khi xong

Cập nhật `pipeline/state.json`: `paths.cover`, gỡ `blocked_on` nếu ảnh là thứ duy nhất
đang chặn. Nói rõ ảnh đã tạo và bài sẵn sàng chạy lại checklist `/content-write`.

Không tự ý đổi nội dung bài. Nếu `alt` trong front matter không khớp ảnh vừa vẽ thì
sửa `alt`, và nói cho người dùng biết.
