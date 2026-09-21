# Mẫu thẻ `career/<slug>.md`

Không commit. Đây là file người dùng mở ra đọc trước buổi phỏng vấn.

```markdown
# <Tiêu đề bài> — thẻ phỏng vấn
Bài: <url blog> · Bằng chứng: bench/<slug>/ · Thể loại: <A|B|D>

## Gạch đầu dòng CV
<Động từ hành động> <thứ cụ thể>, <cơ chế>, giảm/tăng <số> <đơn vị>
(<cách đo>).

Ví dụ: "Chuyển primary key sang UUIDv7 trên 1M bản ghi PostgreSQL 16, giảm
kích thước index 37% (812MB → 511MB, đo bằng pg_relation_size, 5 lần chạy)."

## Thẻ STAR
- **Situation:** <1-2 câu, có bối cảnh và thứ bị đe dọa>
- **Task:** <trách nhiệm cụ thể của tôi, không phải của nhóm>
- **Action:** <3-4 gạch đầu dòng, mỗi cái là một hành động tôi tự làm;
  gồm ít nhất một lần tôi sai rồi sửa>
- **Result:** <số trước → sau, kèm cả chỉ số xấu đi nếu có>

## Ba lát cắt

| Nơi nộp | Nhấn vào | Câu mở đầu gợi ý |
|---|---|---|
| Meta | tốc độ thực thi + tác động | ... |
| Google | độ phức tạp + khả năng chịu tải + cơ chế tầng dưới | ... |
| Amazon | tiết kiệm chi phí + tự tay làm từ A-Z + Dive Deep | ... |

## Câu behavioral bài này trả lời được
- [ ] thất bại  - [ ] mâu thuẫn  - [ ] deadline  - [ ] tự học  - [ ] quyết định khó

## Ba câu hỏi đào sâu tôi phải trả lời được
1. <câu interviewer chắc chắn hỏi về con số này>
2. <vì sao không chọn phương án kia>
3. <giới hạn của giải pháp / phép đo>
```

Mục cuối quan trọng nhất: nó buộc chuẩn bị trước cho phần Dive Deep, chỗ mà một con số
không bảo vệ được sẽ làm hỏng cả buổi.
