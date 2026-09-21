---
name: content-triage
description: Chạy cổng đo và phân luồng thể loại cho các mục trong inbox content của blog — quyết định mục nào đủ bằng chứng để viết, mục nào phải đi đo trước, và mỗi mục thuộc thể loại A (case study) / B (benchmark) / C (giới thiệu công nghệ) / D (storytelling). Dùng skill này khi người dùng hỏi "viết bài gì tiếp", "cái này viết được chưa", "phân loại inbox", "cái này nên làm blog hay video", "ý tưởng này đủ chưa", khi inbox đã tích vài mục chưa xử lý, hoặc khi họ đang phân vân giữa nhiều chủ đề. Dùng cả khi họ đề xuất một ý tưởng bài viết mới và cần kiểm tra xem có đủ bằng chứng không.
---

# Cổng đo + phân luồng

Hai việc này đi liền nhau vì chúng trả lời cùng một câu hỏi: **bằng chứng đang cầm là
gì**. Thể loại bài không do chủ đề quyết định — nó do bằng chứng quyết định. Đây là
chỗ chặn thất bại nguy hiểm nhất: số liệu bịa trên một artifact công khai mà
interviewer sẽ đào đúng vào đó.

Spec: `CONTENT_STYLE.md` mục 3 và 4.

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

### Bước 2 — Phân luồng

| Bằng chứng | Thể loại | Ngôn ngữ gốc |
|---|---|---|
| Hệ thống thật + số trước/sau + quyết định của người dùng | **A** | EN |
| Benchmark tự chạy + phương pháp đo | **B** | EN |
| Kiến thức + ví dụ đời thường, chưa đo | **C** | VI |
| Trải nghiệm ngành/con người, không có số | **D** | VI |

Ranh giới hay nhầm:
- **A vs B:** A là "hệ thống của tôi đang chạy và tôi đã sửa nó". B là "tôi dựng phép
  đo để trả lời một câu hỏi". Không có hệ thống thật thì không phải A, dù chủ đề sâu
  đến đâu.
- **B vs C:** đã tự chạy phép đo là B. Chỉ trích dẫn số của người khác là C.
- Một nguyên liệu có thể **ra nhiều bài**. Đừng ép chọn một. Ví dụ: bản giới thiệu VI
  (C) + bản benchmark EN (B) từ cùng một việc. Tạo mục riêng cho từng bài.

### Bước 3 — Ghi lại

Mọi thứ ghi vào `state.json` phải đã khử định danh (`CONTENT_STYLE.md` mục 3b) — file
này công khai, còn `drafts/inbox.md` thì không.

Cập nhật `pipeline/state.json`: `genre`, `lang_primary`, `evidence`, `stage`
(`ready` hoặc `needs-measure`), `next_action`, `paths`. Nối dòng vào `log`.

## Trả lời

Dòng đầu: mục nào **viết được ngay** (hoặc nếu không có mục nào, thì phép đo nào cần
chạy trước). Sau đó một bảng: slug | thể loại | stage | việc kế tiếp | ước lượng giờ.

Với mục bị chặn, nói rõ **thiếu đúng cái gì** — không nói chung chung. Người dùng phải
đọc xong là bắt tay vào được.
