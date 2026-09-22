---
name: content-lesson
description: Ghi một lỗi vừa gặp vào kho kinh nghiệm lessons/ để không lặp lại, và nâng lỗi tái phát thành luật trong CONTENT_STYLE.md. Dùng skill này ngay khi phát hiện ra một lỗi trong quy trình content — người dùng nói "ghi lại lỗi này", "lần sau đừng lặp lại", "thêm vào từ điển dịch", "cái này sai rồi", "rút kinh nghiệm", hoặc khi /content-audit tìm ra lỗi chưa có trong kho. Dùng cả khi người dùng chỉ ra một chỗ dịch trật hay một cách nói nghe không tự nhiên.
---

# Ghi kinh nghiệm

Một lỗi chỉ đáng gọi là kinh nghiệm khi lần sau nó bị chặn. Kho `lessons/` tồn tại để
biến lỗi thành thứ có thể tra cứu, và để `/content-audit` biết soi vào đâu trước.

## Chọn file

| Lỗi về | File |
|---|---|
| Câu chữ, dịch trật, văn khó đọc | `lessons/writing-vi.md` |
| Số liệu, nguồn, bằng chứng | `lessons/evidence.md` |
| Code bench, môi trường chạy | `lessons/bench.md` |
| Ảnh, SVG, công cụ xuất ảnh | `lessons/artwork.md` |
| Phân loại thể loại, cổng đo | `lessons/triage.md` |
| Quy trình, bảo mật, môi trường | `lessons/process.md` |

## Viết một mục

Đánh số tiếp theo trong file đó, không dùng lại số cũ.

```markdown
## L-0NN · YYYY-MM-DD · <nhãn ngắn>
**Lỗi:** một câu, cụ thể, có ví dụ thật
**Ai bắt:** người đọc / bộ quét / chạy thật / reviewer
**Vì sao lọt:** cơ chế nào đáng lẽ chặn mà không chặn
**Dấu hiệu:** cách nhận ra lỗi này ở bài khác
**Đã vá:** file + mục luật, hoặc "chưa vá"
```

Hai trường quan trọng nhất và hay bị viết qua loa:

- **Vì sao lọt** — nếu không trả lời được thì bạn chưa hiểu lỗi, và bản vá sẽ trượt.
  Thường câu trả lời là "cổng kiểm nằm ở bước trước đó nên bước này không ai kiểm lại".
- **Dấu hiệu** — phải là thứ **quan sát được ở bài khác**, không phải mô tả lại lỗi này.
  "Con số bất lợi cho tác giả" là dấu hiệu tốt. "Con số sai" thì không.

Lỗi về câu chữ: thêm luôn một dòng vào **bảng từ điển dịch trật** ở đầu
`lessons/writing-vi.md`, ngoài mục L-0NN.

## Nâng thành luật

Một lỗi lặp **lần thứ hai** thì không được để nằm mãi ở `lessons/` — phải thành luật
trong `CONTENT_STYLE.md` hoặc thành một bước trong skill chuyên môn. Kho kinh nghiệm là
nơi ghi nhận, không phải nơi thay thế cổng chặn.

Khi nâng: viết luật ở dạng **hành động kiểm được**, không phải lời khuyên. "Liệt kê từng
con số và truy nguồn từng cái" kiểm được; "cẩn thận với số liệu" thì không. Rồi ghi
`**Đã vá:**` trỏ về chỗ luật vừa thêm.

## Ranh giới

`lessons/` là file công khai. Ví dụ lỗi phải đã khử định danh — đừng chép nguyên mã
ticket, mã hàng, đường dẫn module thật vào đây (`CONTENT_STYLE.md` mục 3b). Bộ quét
`pre-commit` sẽ chặn, nhưng đừng để nó phải chặn.

## Trả lời

Một dòng: đã ghi mục nào vào file nào. Nếu là lỗi lặp lần hai thì nói rõ và đề xuất luật
cụ thể để nâng lên.
