---
name: content-review
description: Rà soát định kỳ cả dây chuyền content của blog — kiểm chỉ tiêu bài A/B, tìm lỗ hổng trong kho đạn phỏng vấn (thất bại, mâu thuẫn, deadline, tự học, quyết định khó), phát hiện mục kẹt lâu và bài cũ không còn đạt chuẩn. Dùng skill này khi người dùng nói "rà soát lại", "review quý", "kiểm tra blog tổng thể", "tôi sắp đi phỏng vấn, đủ đạn chưa", "bài cũ có cần sửa không", khi đã qua 3 tháng kể từ lần rà soát trước, hoặc khi họ chuẩn bị nộp CV và cần biết blog đang thiếu gì.
---

# Rà soát dây chuyền

Chạy mỗi quý, hoặc ngay trước khi nộp CV. Mục đích không phải kiểm tra năng suất — mà
là phát hiện **lệch hướng**: blog vẫn ra đều nhưng toàn thể loại dễ, hoặc kho đạn phỏng
vấn thiếu hẳn một loại câu hỏi.

Spec: `CONTENT_STYLE.md` mục 7.

## Bốn phép kiểm

### 1. Chỉ tiêu thể loại

Đếm bài đã publish trong kỳ theo thể loại. Ràng buộc: **2 bài/tháng, ≥1 bài A hoặc B**.

C và D dễ viết hơn nhiều; nếu tỷ lệ A/B tụt dưới ngưỡng qua hai tháng liên tiếp, nói
thẳng rằng blog đang trôi về phía content giải trí và tài sản CV đang đứng yên. Đề xuất
mục cụ thể trong inbox có thể nâng lên A/B, kèm phép đo cần chạy.

### 2. Lỗ hổng behavioral

Đọc `behavioral_coverage` trong `pipeline/state.json` và các file trong `career/`.

Năm câu kinh điển: **thất bại · mâu thuẫn · deadline · tự học · quyết định khó**.

Câu nào chưa có bài nào trả lời → đó là lỗ hổng. Đề xuất loại nguyên liệu cần chủ động
sinh ra trong quý tới. Đây là phép kiểm có giá trị nhất, vì nó biến "viết blog đều đặn"
thành "chuẩn bị phỏng vấn có mục tiêu".

### 3. Mục kẹt

Mục nào ở cùng một stage quá 3 tuần → hỏi thẳng: bỏ hay làm tiếp? Một pipeline đầy mục
kẹt gây tê liệt nhiều hơn là động lực. Đề xuất **xóa** những mục không còn hứng thú —
xóa là một kết quả hợp lệ, và nó làm bảng điều khiển đọc được trở lại.

### 4. Bài cũ so với chuẩn hiện tại

Quét `content/posts/` tìm:

- Con số không truy được nguồn đo
- Thiếu mục Đánh đổi hoặc mục giới hạn
- Front matter không phải YAML, hoặc thiếu trường
- Ảnh được tham chiếu nhưng không tồn tại
- Bài chưa có bản dịch

Xếp theo mức hại: **số liệu không nguồn** nặng nhất (interviewer sẽ đào đúng vào đó),
rồi tới ảnh hỏng (recruiter nhìn thấy ngay), rồi tới thiếu bản dịch.

## Trả lời

Dòng đầu: việc quan trọng nhất của quý tới, một câu.

```
## Chỉ tiêu
<đã publish x bài, y thuộc A/B — đạt/không đạt>

## Lỗ hổng behavioral
<câu nào chưa có đạn>

## Kẹt
<mục quá 3 tuần, đề xuất bỏ hay đẩy tiếp — tối đa 5>

## Bài cũ cần sửa
<xếp theo mức hại — tối đa 5>
```

Không liệt kê thành tích. Không quá 5 dòng mỗi mục; nhiều hơn thì ghi "còn N mục nữa".
Kết bằng đúng một việc bắt đầu được trong dưới 2 phút.
