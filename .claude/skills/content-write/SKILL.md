---
name: content-write
description: Viết bản gốc và bản dịch cho một bài blog kỹ thuật theo đúng giọng văn và khung của blog này, rồi chạy checklist publish (kiểm ảnh, front matter, hugo build). Dùng skill này khi người dùng nói "viết bài này", "soạn bản nháp", "viết bản tiếng Anh", "dịch bài", "publish bài", "bài này đã ổn chưa", khi một mục trong pipeline ở stage ready/drafting/needs-translation, hoặc khi họ sửa nội dung bất kỳ file nào trong content/posts/. Dùng cả khi họ hỏi "bài này viết đúng style chưa" hay muốn rà lại một bài cũ cho khớp chuẩn.
---

# Viết bản gốc + bản dịch + publish

Blog này có một giọng nhất quán — người đọc ba bài phải nhận ra cùng một người viết.
Skill này giữ giọng đó và chặn các lỗi làm bài mất giá trị với recruiter (số liệu không
nguồn, thiếu mục đánh đổi, ảnh hỏng).

Spec giọng văn và quy ước kỹ thuật: đọc `CONTENT_STYLE.md` mục 5 **trước khi viết dòng
đầu tiên**. Và đọc `lessons/writing-vi.md` — bảng từ điển dịch trật ở đầu file là những
lỗi đã thực sự xảy ra trên blog này, không phải ví dụ giả định.

## Bước 0 — Xác định thể loại và ngôn ngữ gốc

Đọc `genre` và `lang_primary` từ `pipeline/state.json`. Chưa có → chạy
`/content-triage` trước, đừng đoán. Viết sai thể loại sẽ phải dựng lại từ đầu vì khung
khác hẳn.

Rồi đọc **đúng một** file khung tương ứng:

| Thể loại | File khung |
|---|---|
| A — Case study | `references/genre-a-case-study.md` |
| B — Benchmark / deep-dive | `references/genre-b-benchmark.md` |
| C — Giới thiệu công nghệ | `references/genre-c-explainer.md` |
| D — Storytelling | `references/genre-d-storytelling.md` |

## Bước 1 — Bản gốc

Viết bằng `lang_primary`, dài **900-1100 từ**. Dùng khung của thể loại, kèm xương sống
bắt buộc (`CONTENT_STYLE.md` mục 5).

Ba thứ hay bị bỏ quên, kiểm lại trước khi coi là xong:

1. **Mọi con số phải truy được** về `bench/<slug>/` hoặc một link ngoài. Số không nguồn
   thì xóa hoặc đi đo — đừng để lại.
2. **Mục Đánh đổi** — nếu không nghĩ ra được đánh đổi nào, đó là dấu hiệu bài chưa đủ
   sâu, không phải dấu hiệu giải pháp hoàn hảo.
3. **Mục giới hạn / thứ chưa giải quyết được** — lấy từ ô "thứ không đo được" trong
   `bench/<slug>/README.md`.

Front matter YAML đủ 10 trường, đường dẫn ảnh bắt đầu bằng `/`.

## Bước 2 — Bản dịch

Cắt **ý** thừa, không cắt **chữ**. Bản VI dài hơn bản EN là bình thường — tiếng Việt
cần nhiều chữ hơn cho cùng một ý. Ép số từ xuống là cách chắc chắn nhất để sinh ra văn
dịch cứng.

Nếu bản còn lại là tiếng Việt, đọc `CONTENT_STYLE.md` mục "Viết tiếng Việt cho ra tiếng
Việt" trước khi viết — bốn lỗi dịch cứng ở đó là lỗi đã thực sự xảy ra trên blog này.

Đây là **bản viết lại, không phải bản dịch sát**:

- Cắt: ví dụ mang tính địa phương, đoạn dẫn dắt dài, lặp lại
- Giữ nguyên: mọi con số, phương pháp đo, mục đánh đổi, mục giới hạn, câu kết luận
- `tags` giữ nguyên tiếng Anh ở cả hai bản; `categories` dịch
- Tên file: `<slug>.en.md` cho bản EN; bản VI là `<slug>.md`

Lý do rút gọn thay vì dịch sát: bản dịch sát đọc như máy dịch và làm loãng bài, trong
khi người đọc bản thứ hai thường đã biết chủ đề và chỉ cần bằng chứng với kết luận.

## Bước 2b — Vòng đọc lại (đừng bỏ)

Bản nháp đầu bao giờ cũng được viết bởi người đã sống trong câu chuyện, cho người cũng
đã sống trong câu chuyện. Vòng này tìm những chỗ tác giả thấy hiển nhiên mà người đọc
thì không.

Đưa bản nháp cho người dùng và hỏi **đúng một câu**: *đọc to đoạn X, chỗ nào phải dừng
lại để ghép nghĩa?* Rồi sửa theo từng chỗ họ chỉ. Không hỏi "bài ổn chưa" — câu đó
nhận về "ổn" rồi bài lên với nguyên lỗi.

Ba nhóm lỗi vòng này bắt được, xếp theo tần suất thực tế trên blog này:

1. **Thành ngữ Anh dịch thẳng** — "đường ghi", "MySQL sống", "cái trait mục ruỗng".
   Bảng đối chiếu ở `CONTENT_STYLE.md` mục "Viết tiếng Việt cho ra tiếng Việt".
2. **Mắt xích bị bỏ** — hậu quả chưa có ví dụ số, "vì sao không ai phát hiện ra" chưa
   giải thích, công cụ cư xử lạ mà chưa nói vì sao.
3. **Câu nén quá tay** — một câu mang bốn mệnh đề. Tách thành danh sách đánh số.

Thường mất 2-3 vòng. Đó là bình thường, không phải dấu hiệu bản nháp tệ.

## Bước 3 — Checklist publish

Chạy hết, báo cáo từng mục:

1. `draft: false`, `date` không lớn hơn giờ hiện tại — Hugo bỏ qua bài tương lai mà không
   cảnh báo, build vẫn "sạch" (L-058)
2. Có đủ bản gốc + bản dịch
3. **Mọi ảnh được tham chiếu đều tồn tại** trong `static/images/posts/<slug>/` — liệt
   kê chính xác file nào còn thiếu, đừng báo chung chung
4. Có mục Trade-offs và mục giới hạn
5. **Kiểm nguồn từng con số một.** Liệt kê mọi con số xuất hiện trong bài và truy nó
   về `drafts/inbox.md`, `bench/<slug>/`, hoặc một link ngoài. Con số nào không truy
   được thì **xóa hoặc đổi thành lời tự khai "tôi chưa đo cái này"** — không được giữ
   lại vì nó "nghe hợp lý".

   Đây là lỗi đã thực sự xảy ra trên blog này: bài đầu tiên viết ra một con số "suite
   chậm thêm 1,2 giây" mà không có trong inbox lẫn bench. Số liệu bịa lọt vào đúng ở
   bước viết, vì cổng đo chạy ở bước triage rồi thì không ai kiểm lại nữa. Con số càng
   khiêm tốn và càng bất lợi cho mình thì càng dễ lọt — nó không gây nghi ngờ.

   Số dùng làm **ví dụ minh họa** thì phải nói rõ là ví dụ ("giả sử kho còn 10"), đừng
   trình bày như dữ kiện của hệ thống thật.

   Mọi tham chiếu `bench/` là **link GitHub bấm được** (không phải đường dẫn trần) —
   thư mục bench phải trùng slug bài.
6. **Đã khử định danh** — không còn ticket ID, mã hàng/khách thật, đường dẫn module
   nội bộ, commit hash, hay tên công ty/sản phẩm/đồng nghiệp. Phép thử: người ngoài đọc
   xong có suy ra được đây là công ty nào không? (`CONTENT_STYLE.md` mục 3b)
7. `hugo --gc --minify` chạy sạch, không warning, **và** `find public -path '*<slug>*'
   -name index.html | wc -l` ra đúng 2 — build sạch không chứng minh trang được sinh ra

Thiếu ảnh → stage `needs-assets`, gọi `/content-artwork`. Bench chưa chạy thử hoặc
đang lỗi → gọi `/content-bench`. Skill này **không** vẽ ảnh và **không** viết bench —
mỗi việc có skill riêng, vì gộp vào đây thì cả ba đều bị làm qua loa.

Checklist này là **tự kiểm**, nên đừng coi nó là bằng chứng. Xong hết thì chuyển sang
`/content-audit` để có một vòng soi độc lập trước khi publish — người vừa viết xong đọc
lại chỉ thấy trôi chảy vì đã biết đáp án.

Qua được vòng audit → `stage: "published"`, và nói ngay rằng bước dẫn xuất (`/content-derive`) nên
làm trong 24h khi còn nhớ chi tiết.

## Trả lời

Dòng đầu: đường dẫn file vừa viết và việc kế tiếp. Không dán lại toàn văn bài vào câu
trả lời — người dùng mở file đọc. Chỉ nêu các mục checklist **không đạt**.
