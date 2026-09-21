# Thể loại B — Benchmark / deep-dive

Bằng chứng bắt buộc: phép đo do chính người viết chạy, có script reproduce.
Ngôn ngữ gốc: **EN**. Đích chính: CV + traffic.

Đây là thể loại **dễ sản xuất trung thực nhất** khi chưa có kinh nghiệm production —
và nó vẫn là đạn phỏng vấn tốt, vì nó chứng minh phương pháp chứ không phải thâm niên.

## Khung

```
Câu hỏi (150-200 từ)
  Một câu hỏi có biến độc lập và biến phụ thuộc, nêu rõ quy mô.
  Vì sao câu hỏi này đáng hỏi: ai đang phải ra quyết định này?

---
Phương pháp đo (250-300 từ)
  Chép từ bench/<slug>/README.md: baseline, dataset, môi trường,
  số lần chạy, cách xử lý số liệu.
  Đặt sớm, không giấu xuống cuối — người đọc kỹ thuật cần biết có nên tin số không
  trước khi đọc số.
  Kèm lệnh chạy lại và link tới bench/<slug>/.

---
Số liệu thô (200-250 từ)
  Bảng. Số trước, diễn giải sau.
  Kèm cả kết quả ngoài kỳ vọng — đừng lọc bỏ.

---
Diễn giải (250-300 từ)
  Vì sao ra con số đó, ở tầng cơ chế (B-Tree page split, cache line, GC, syscall...).
  Đây là phần phân biệt bài benchmark với bài đăng số liệu.

---
Giới hạn phép đo
  Thứ phép đo này KHÔNG trả lời được. Lấy từ ô "thứ không đo được" trong bench README.
  Điều kiện nào sẽ làm kết luận đảo chiều?

---
Đúc kết + khi nào nên / không nên dùng
```

## Kiểm tra trước khi coi là xong

- Người lạ chạy lại được bằng một lệnh?
- Mục "giới hạn phép đo" có nêu điều kiện làm kết luận đảo chiều?
- Phần diễn giải có chạm tới cơ chế tầng dưới, hay chỉ mô tả lại bảng số?
