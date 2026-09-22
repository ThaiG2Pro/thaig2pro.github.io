---
name: content-measure
description: Thiết kế và chạy phép đo cho một bài blog kỹ thuật — chọn baseline, dựng dataset, viết script reproduce vào bench/<slug>/, chạy nhiều lần, ghi số liệu thô. Dùng skill này khi người dùng nói "đi đo cái này", "benchmark thử", "làm sao chứng minh nó nhanh hơn", "cần số liệu cho bài", khi một mục trong pipeline ở stage needs-measure, hoặc khi họ định viết một con số vào bài mà chưa có nguồn đo. Dùng cả khi họ hỏi "đo thế nào cho đúng" hay khi phát hiện bài đang có số liệu không truy được nguồn.
---

# Thiết kế và chạy phép đo

Một bài blog kèm script reproduce mạnh hơn hẳn một bài chỉ có kết luận — vì nó biến
lời khẳng định thành thứ người khác kiểm chứng được. Đây cũng là thứ trả lời trực diện
câu hỏi phỏng vấn "bạn đo bằng cách nào", chỗ mà phần lớn ứng viên lúng túng.

Spec: `CONTENT_STYLE.md` mục 3.

Đọc `lessons/evidence.md` trước.

## Quy trình

### Bước 1 — Phát biểu câu hỏi đo trước khi viết code

Một câu, có biến độc lập và biến phụ thuộc. Ví dụ tốt: "Với 1 triệu bản ghi, kích thước
index và write throughput khác nhau thế nào giữa UUIDv4 và UUIDv7 trên PostgreSQL 16?"

Ví dụ xấu: "UUIDv7 có nhanh hơn không?" — không nêu quy mô, không nêu thứ đo.

Câu hỏi mơ hồ sinh ra phép đo mơ hồ, và đó là nguồn gốc của những con số không bảo vệ
được khi bị hỏi lại.

### Bước 2 — Chốt 5 tham số, viết vào `bench/<slug>/README.md`

| Tham số                                          | Vì sao cần                                 |
| ------------------------------------------------ | ------------------------------------------ |
| Baseline                                         | không có baseline thì "nhanh hơn" vô nghĩa |
| Dataset (kích thước, cách sinh)                  | quyết định kết quả có đại diện không       |
| Môi trường (phiên bản, máy, cấu hình)            | người đọc cần biết để so sánh              |
| Số lần chạy + cách xử lý (trung vị? bỏ lần đầu?) | một lần chạy là giai thoại                 |
| Thứ **không** đo được                            | phần "Giới hạn phép đo" của bài lấy từ đây |

Ô cuối quan trọng nhất. Tự nêu giới hạn phép đo của mình là tín hiệu senior rõ nhất, và
nó chặn trước câu hỏi khó nhất trong phỏng vấn.

### Bước 3 — Viết script

Đặt tại `bench/<slug>/`. Yêu cầu: chạy được từ máy sạch bằng **một lệnh**, in ra số
liệu thô dạng CSV/JSON vào `bench/<slug>/results/`. Dữ liệu thô nặng thì để
`bench/<slug>/raw/` (đã gitignore) và chỉ commit bản tổng hợp.

Ưu tiên công cụ chuẩn của hệ sinh thái (`pgbench`, `hyperfine`, `pytest-benchmark`,
`wrk`) hơn là tự viết vòng lặp đo thời gian — người đọc tin công cụ họ biết, và bạn
tránh được các lỗi đo kinh điển (warm-up, cache, jitter).

### Bước 4 — Chạy và ghi

Chạy đủ số lần đã chốt. Ghi **cả số liệu bất lợi**. Nếu kết quả không như kỳ vọng, đó
là bài viết hay hơn, không phải thất bại — "tôi tưởng X nhanh hơn, hóa ra không, đây là
lý do" là một trong những bài đáng đọc nhất.

Cập nhật `pipeline/state.json`: `evidence.numbers`, `evidence.method`,
`evidence.repro`, `stage: "ready"`, `paths.bench`.

## Nguyên tắc

- **Không suy ra số liệu từ tài liệu.** Nếu số đến từ blog/paper của người khác, đó là
  trích dẫn có link, không phải phép đo của bạn, và bài thuộc thể loại C chứ không phải B.
- **Không làm đẹp số.** Làm tròn thì nói rõ đang làm tròn.
- Phép đo mất quá 1 buổi tối → cắt phạm vi, đừng cắt độ chặt. Một phép đo nhỏ mà chắc
  tốt hơn một phép đo lớn mà mơ hồ.

## Trả lời

Dòng đầu: lệnh để chạy phép đo. Sau đó bảng 5 tham số đã chốt, rồi số liệu thu được và
mục "giới hạn 68 + (không phải đường dẫn trần) — thư mục bench phải trùng slug bàiphép đo" dạng bullet — phần này chép thẳng vào bài ở bước sau.
