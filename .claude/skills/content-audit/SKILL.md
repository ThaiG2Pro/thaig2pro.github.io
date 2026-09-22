---
name: content-audit
description: Kiểm duyệt độc lập một bài blog trước khi publish — đóng vai người soát lỗi khó tính, tự truy lại từ nguồn thay vì tin báo cáo của bước viết. Dùng skill này khi người dùng nói "kiểm bài này", "soát lỗi giúp", "bài đã ổn chưa", "review trước khi đăng", "audit", khi một bài vừa qua /content-write, hoặc trước bất kỳ lần publish nào. Dùng cả khi rà lại một bài cũ đã đăng.
---

# Kiểm duyệt độc lập

Bước viết tự kiểm chính nó thì không đáng tin — người vừa viết xong đọc lại chỉ thấy
trôi chảy, vì đã biết đáp án. Skill này tồn tại để **không tin báo cáo của bước viết**,
mà tự truy lại từ nguồn gốc.

Nguyên tắc: **mọi khẳng định đều giả định là sai cho tới khi tự mình kiểm được.**
Checklist của `/content-write` nói "đạt" không có giá trị ở đây.

## Bước 0 — Nạp kinh nghiệm cũ

Đọc `lessons/` trước khi soi bài, ít nhất `writing-vi.md`, `evidence.md`, và file của
thể loại tương ứng. Đó là danh sách lỗi **đã thực sự xảy ra** trên blog này — soi đúng
những chỗ đó trước, vì chúng có xác suất tái phát cao nhất.

## Sáu vòng kiểm

Chạy theo thứ tự này. Vòng nào cũng phải tự thực thi, không suy luận.

### 1. Truy nguồn từng con số
Liệt kê **mọi** con số trong bài. Với mỗi con số, tìm nó trong `drafts/inbox.md`,
`bench/<slug>/`, hoặc một link ngoài. Không tìm thấy → báo là **số không nguồn**, đề xuất
xóa hoặc đổi thành lời tự khai.

Soi kỹ nhất những con số **bất lợi cho tác giả** (L-010): chúng nghe như tự phê bình nên
dễ lọt qua mọi vòng kiểm.

### 2. Chạy lại bằng chứng
Đừng đọc `bench/README.md` rồi tin. **Chạy** kịch bản trong đó bằng Docker, so từng bước
với kết quả được ghi. Đồng thời `curl` mọi link trong bài — link `bench/` chỉ sống sau
khi thư mục đã push.

Hỏi thêm: bước nào trong bench minh họa **phát hiện** của bài? Không có → bench đang
chứng minh nhầm thứ (L-021).

### 3. Đọc to
Với bản tiếng Việt: đối chiếu bảng từ điển dịch trật trong `lessons/writing-vi.md`. Tìm
thành ngữ Anh dịch thẳng, câu nhiều danh từ ghép, câu bị nuốt từ nối.

Rồi tìm **mắt xích bị bỏ** (L-003): hậu quả có ví dụ số chưa · đã giải thích vì sao không
ai phát hiện ra chưa · công cụ cư xử lạ đã nói vì sao chưa.

Báo cáo theo **số dòng**, kèm câu viết lại đề xuất. Nói "văn hơi cứng" là vô dụng.

### 4. Khử định danh
Chạy `scripts/scan-identifiers.sh` trên các file của bài. Rồi tự đọc một lượt tìm thứ
regex không bắt được: tên sản phẩm, tên đồng nghiệp, chi tiết đủ đặc trưng để nhận ra
công ty. Phép thử: *người ngoài đọc xong có suy ra được đây là công ty nào không?*

### 5. Ảnh
Mọi ảnh được tham chiếu có tồn tại không. **Mở ảnh ra nhìn** — chữ tràn khung và chữ
chồng nhau không lộ ra trong code SVG (L-032).

### 6. Cấu trúc và tính nhất quán hai bản
Có mục Đánh đổi và mục giới hạn. Hai bản cùng bộ tiêu đề. Front matter đủ trường. Con số
trong hai bản khớp nhau. `hugo --gc --minify` sạch.

## Báo cáo

Dòng đầu: **đạt** hay **chưa đạt**, và nếu chưa thì thứ nặng nhất là gì.

```
## Chặn publish
<mỗi lỗi: file:dòng · lỗi gì · sửa thế nào>

## Nên sửa
<không chặn nhưng làm bài yếu đi>

## Đã kiểm, đạt
<một dòng cho mỗi vòng, nói rõ đã chạy gì — không nói "OK" suông>
```

Xếp theo mức hại: **số không nguồn** nặng nhất (interviewer sẽ đào đúng vào đó) → bằng
chứng không chạy được → rò rỉ định danh → ảnh hỏng → văn khó đọc → lệch cấu trúc.

Không tự sửa bài trong skill này. Việc của nó là **tìm ra**, việc sửa thuộc về skill
chuyên môn tương ứng. Trộn hai việc thì người kiểm lại thành người tự chấm bài mình.

## Sau khi kiểm

Mỗi lỗi mới tìm được mà chưa có trong `lessons/` → ghi lại bằng `/content-lesson`. Đó là
cách kho kinh nghiệm lớn lên, và là cách lần sau đỡ việc hơn.
