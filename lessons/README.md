# Kho kinh nghiệm

Ghi lại **lỗi đã thực sự xảy ra** trên blog này, để không lặp lại.

## Khác gì CONTENT_STYLE.md

| | `CONTENT_STYLE.md` | `lessons/` |
|---|---|---|
| Nội dung | **luật** — phải làm gì | **sự cố** — đã sai như thế nào |
| Giọng | mệnh lệnh, ổn định | kể lại, còn nguyên bối cảnh |
| Khi nào đọc | trước khi viết | trước khi kiểm (`/content-audit`) |

Luật sinh ra **từ** lessons. Một lỗi lặp lần hai thì phải thành luật trong spec, không để
nằm mãi ở đây.

## File

| File | Dùng bởi |
|---|---|
| `writing-vi.md` | `/content-write` — từ điển dịch trật + lỗi văn |
| `evidence.md` | `/content-write`, `/content-measure` — số liệu, nguồn, bằng chứng |
| `bench.md` | `/content-bench` |
| `artwork.md` | `/content-artwork` |
| `triage.md` | `/content-triage` |
| `process.md` | `/content-status`, `/content-derive` — lỗi quy trình, môi trường |

## Mẫu một mục

```markdown
## L-001 · YYYY-MM-DD · <nhãn>
**Lỗi:** một câu, cụ thể
**Ai bắt:** người đọc / bộ quét / chạy thật / reviewer
**Vì sao lọt:** cơ chế nào đáng lẽ chặn mà không chặn
**Dấu hiệu:** cách nhận ra lỗi này ở bài khác
**Đã vá:** file + mục luật, hoặc "chưa vá"
```

Đánh số tăng dần, không dùng lại số cũ. Thêm bằng `/content-lesson`.

## Luật khử định danh vẫn áp dụng

File này công khai. Đừng chép ví dụ lỗi kèm mã ticket, mã hàng, đường dẫn module thật —
viết lại dạng chung (`CONTENT_STYLE.md` mục 3b).
