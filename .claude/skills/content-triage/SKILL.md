---
name: content-triage
description: Chạy cổng đo, cổng nhận ra mình, và phân luồng thể loại cho các mục trong inbox content của blog — quyết định mục nào đủ bằng chứng để viết, mục nào phải đi đo trước, và mỗi mục thuộc thể loại A (case study) / B (benchmark) / C (giới thiệu công nghệ) / D (storytelling). Dùng skill này khi người dùng hỏi "viết bài gì tiếp", "cái này viết được chưa", "bài này có đáng viết không", "phân loại inbox", "cái này nên làm blog hay video", "ý tưởng này đủ chưa", khi inbox đã tích vài mục chưa xử lý, hoặc khi họ đang phân vân giữa nhiều chủ đề. Dùng cả khi họ đề xuất một ý tưởng bài viết mới và cần kiểm tra xem có đủ bằng chứng không.
---

# Cổng đo + phân luồng

Ba việc này đi liền nhau vì chúng trả lời cùng một câu hỏi: **bằng chứng đang cầm là
gì, và nó chuyển giao được cho ai**. Thể loại bài không do chủ đề quyết định — nó do bằng chứng quyết định. Đây là
chỗ chặn thất bại nguy hiểm nhất: số liệu bịa trên một artifact công khai mà
interviewer sẽ đào đúng vào đó.

Spec: `CONTENT_STYLE.md` mục 3 (cổng đo) và mục 4 (cổng nhận ra mình + phân luồng).

Đọc `lessons/triage.md` trước khi phân loại.

## Quy trình

Với mỗi mục `stage: "inbox"` trong `pipeline/state.json` (hoặc mục người dùng vừa nêu):

### Bước 1 — Cổng đo

Trả lời cả 3 câu. Trả lời bằng dữ kiện có thật trong inbox/hội thoại, **không suy đoán
hộ**:

| Câu hỏi | Đạt | Không đạt |
|---|---|---|
| Con số là bao nhiêu (before/after)? | ghi vào `evidence.numbers` | → `needs-measure` |
| Đo bằng gì (công cụ, dataset, số lần chạy)? | ghi vào `evidence.method` | → `needs-measure` |
| Người khác chạy lại được không? | ghi `evidence.repro` = `bench/<slug>/` | → `needs-measure` |

Không đạt bất kỳ câu nào → stage `needs-measure`, và `next_action` phải là **việc đo cụ
thể**, ước lượng thời gian. Ví dụ: "chèn 1M bản ghi UUIDv4 vs UUIDv7 vào Postgres 16,
đo kích thước index bằng `pg_relation_size`, ~1 buổi tối". Viết "cần đo thêm" chung
chung là vô dụng — người dùng sẽ không bắt đầu được.

**Ngoại lệ:** thể loại D không cần số. Thay vào đó phải có mốc thời gian, vai trò cụ
thể của người dùng, và quyết định họ đã ra. Thiếu ba thứ đó thì đó chỉ là ý kiến, chưa
phải câu chuyện.

### Bước 1b — Cổng nhận ra mình

Qua cổng đo nghĩa là bài sẽ **đúng**. Cổng này hỏi bài có **đáng đọc** không. Một bài
đúng mà không ai cần đọc vẫn tốn 4-7 tiếng và không đổi được gì.

Ba câu, phải trả lời bằng dữ kiện thật, **không tự nghĩ hộ tác giả**:

| Câu hỏi | Đạt | Không đạt |
|---|---|---|
| 1. Viết cái sai thành **một câu không chứa tên công nghệ nào** | ghi vào `transfer` | → `needs-angle` |
| 2. **Swap test**: thay hết tên công nghệ, mục Mổ xẻ dự định còn đúng không? | phải **hỏng** | còn đúng → `needs-angle` |
| 3. Dòng inbox nào ghi **lúc tác giả tin điều sai đó** (ngày, tin vào đâu)? | ghi số dòng vào `evidence.moment` | → `needs-angle` |

Ba dấu hiệu trượt, gặp nhiều nhất theo thứ tự:

- **Câu tư duy vẫn còn tên công nghệ** — "phải thêm index sớm" không phải tư duy, đó là
  mẹo. "Tôi ngoại suy từ một điểm dữ liệu" mới là.
- **Swap test không hỏng** — thay MySQL bằng Postgres mà cả bài vẫn đúng: bài đang kể
  kiến thức chung, chưa kể hệ thống thật. Quay lại tìm số đo riêng của hệ này.
- **Không có khoảnh khắc tin sai** — inbox chỉ ghi sự việc và quyết định, không ghi lúc
  tác giả nghĩ gì. Đây là ca phổ biến nhất và **không** được suy ra hộ (L-016, L-061).

Trượt câu 3 → `stage: "needs-angle"`, `next_action` phải là **hai câu hỏi cụ thể** đặt
cho tác giả kèm mốc thời gian, ví dụ: *"31/08 lúc viết ngưỡng vào tài liệu thiết kế, bạn
tin vào cái gì? Lúc thấy con số 1M lần đầu, phản ứng đầu tiên là gì?"* Rồi
`/content-capture` ghi câu trả lời vào inbox **trước khi** viết.

Trượt câu 1 hoặc 2 → cũng `needs-angle`, nhưng `next_action` là việc tìm góc: mục nào
trong bài chỉ đúng với hệ này, hoặc bài này khác gì 500 bài cùng chủ đề đã có.

**Kiểm trùng:** so `transfer` với trường `transfer` của mọi mục đã `published` trong
`state.json`. Trùng nghĩa là cùng một bài viết lại bằng công nghệ khác — báo cho người
dùng, đừng lặng lẽ cho qua.

### Bước 2 — Phân luồng

| Bằng chứng | Thể loại | Ngôn ngữ gốc |
|---|---|---|
| Hệ thống thật + số trước/sau + quyết định của người dùng | **A** | EN |
| Benchmark tự chạy + phương pháp đo | **B** | EN |
| Kiến thức + **một lần tự dùng và hỏng** hoặc một con số tự đo | **C** | VI |
| Trải nghiệm ngành/con người, không có số | **D** | VI |

Ranh giới hay nhầm:
- **A vs B:** A là "hệ thống của tôi đang chạy và tôi đã sửa nó". B là "tôi dựng phép
  đo để trả lời một câu hỏi". Không có hệ thống thật thì không phải A, dù chủ đề sâu
  đến đâu.
- **B vs C:** đã dựng phép đo để trả lời một câu hỏi là B. C là kiến thức trích dẫn
  **cộng với** một lần tác giả tự dùng và hỏng. Chỉ trích dẫn số của người khác, không có
  lần hỏng nào của mình → **không phải C**, chưa phải bài (siết 2026-09-28).
  Kiểm: che mục "một lần tôi dùng và hỏng" đi, phần còn lại có khác trang tài liệu chính
  thức không? Không khác thì trả về `needs-angle`.
- Một nguyên liệu có thể **ra nhiều bài**. Đừng ép chọn một. Ví dụ: bản giới thiệu VI
  (C) + bản benchmark EN (B) từ cùng một việc. Tạo mục riêng cho từng bài.

### Bước 3 — Ghi lại

Mọi thứ ghi vào `state.json` phải đã khử định danh (`CONTENT_STYLE.md` mục 3b) — file
này công khai, còn `drafts/inbox.md` thì không.

Cập nhật `pipeline/state.json`: `genre`, `lang_primary`, `evidence`, `transfer`, `stage`
(`ready`, `needs-measure`, hoặc `needs-angle`), `next_action`, `paths`. Nối dòng vào `log`.

Thứ tự chặn: `needs-measure` nặng hơn `needs-angle` — chưa có số thì chưa bàn góc.

## Trả lời

Dòng đầu: mục nào **viết được ngay** (hoặc nếu không có mục nào, thì phép đo nào cần
chạy trước). Sau đó một bảng: slug | thể loại | stage | câu tư duy | việc kế tiếp |
ước lượng giờ.

Với mục bị chặn, nói rõ **thiếu đúng cái gì** — không nói chung chung. Người dùng phải
đọc xong là bắt tay vào được.
