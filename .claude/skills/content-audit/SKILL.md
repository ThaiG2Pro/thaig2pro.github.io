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

Rồi làm lượt thứ hai, cho thứ **không phải con số** (L-014, L-015). Liệt kê mọi câu nói
dự án **có** hay **không có** thứ gì, mọi câu ước lượng công sức ("mất vài ngày"), và
mọi lượng từ không đếm — **vài, nhiều, hầu hết, thường xuyên, một số, hiếm khi**. Với
mỗi câu, ghi **lệnh đã dùng để kiểm** nó: một dòng `git log`, `package.json`, hay một
lần `grep`. Không có lệnh → báo là **khẳng định không nguồn**, đề xuất một trong ba: đổi
thành con số đã đếm · hạ xuống điều chứng minh được · viết thẳng "tôi không kiểm lại chỗ
này".

Hai vị trí soi trước, vì lỗi này gần như luôn nằm ở đó: câu **loại một phương án** trong
mục Đánh đổi, và câu **giải thích vì sao bug lọt**. Ở cả hai, khẳng định luôn có lợi cho
tác giả — đó là dấu hiệu, không phải sự trùng hợp.

Rồi lượt thứ ba, cho **định nghĩa hệ thống** (L-018, L-019): mọi câu *"`X` nghĩa là …"*,
*"chế độ mới là …"*, *"trước đây … / bây giờ …"* trong mục Bối cảnh và mục cơ chế. Với
mỗi câu, ghi **số dòng inbox** nói đúng điều đó. Không có dòng → **chặn**, không được coi
là "bối cảnh chung". "Không tìm thấy trong inbox" với một định nghĩa nghĩa là bước viết
đã suy ra nó — và L-019 cho thấy suy ra thường ra đúng cái *đang chạy*, tức ngược với
cái mới. Thêm: ví dụ số có hai giá trị cho cùng một đại lượng (pool = 10 rồi pool = 0)
là dấu hiệu lẫn hai đại lượng.

Đọc luôn mục "What this does not measure" trong `bench/<slug>/README.md` và đối chiếu
với bài: thứ bench tự khai là **không chứng minh được** mà bài vẫn khẳng định chắc nịch,
là đúng chỗ cần soi.

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

Rồi **đếm khái niệm mới trên từng câu dài** (L-008): tên biến, tên hàm, trạng thái, giá
trị, hệ quả. Quá 2 thì đề xuất chẻ câu; một mệnh đề liệt kê từ ba chi phí trở lên cũng
tính. Đây là bước đếm, không phải bước cảm nhận — làm được mà không cần đọc to.

Hai lỗi giọng hay gặp, cùng nhóm: **gồng văn** (L-006) — câu không thêm thông tin nào cho
câu trước, xóa đi đoạn vẫn đủ nghĩa; và **lộ đáp án quá sớm** (L-007) — che mục Mổ xẻ
lại, nếu mục đầu đã trả lời được "vì sao hỏng" thì lộ rồi.

Báo cáo theo **số dòng**, kèm câu viết lại đề xuất. Nói "văn hơi cứng" là vô dụng.

### 4. Khử định danh
Chạy `scripts/scan-identifiers.sh` trên các file của bài. Rồi tự đọc một lượt tìm thứ
regex không bắt được: tên sản phẩm, tên đồng nghiệp, chi tiết đủ đặc trưng để nhận ra
công ty. Phép thử: *người ngoài đọc xong có suy ra được đây là công ty nào không?*

Rồi soi riêng **code nguyên văn** (L-057): chạy
`grep -nE '`[^`]*[a-z]_[a-z][^`]*`' content/posts/<slug>*.md static/images/posts/<slug>/*.svg`.
Mỗi hit phải trả lời được "cái này ở `bench/<slug>/` hay ở repo người khác?" — ở repo
người khác thì **chặn**, dù không suy ra được công ty. Phép thử thứ hai của mục 3b áp ở
đây: *team sở hữu đoạn code đó đọc được thì có ổn không?*

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
