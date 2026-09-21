# Thể loại A — Case study (war story)

Bằng chứng bắt buộc: hệ thống thật + số trước/sau + quyết định của chính người viết.
Ngôn ngữ gốc: **EN**. Đích chính: CV + vòng behavioral.

Đây là thể loại có giá trị CV cao nhất và hiếm nhất — mỗi năm được 2-3 bài là nhiều.

## Khung

```
Nỗi đau (200-250 từ)
  Mở bằng hậu quả đo được, không bằng tên công nghệ.
  "Sync mất 5s, rớt 15% đơn giờ cao điểm" — không phải "Cách tôi dùng Kafka".
  Nêu rõ ai chịu thiệt: người dùng, đồng đội, hay hóa đơn.

---
Mổ xẻ (300-350 từ)
  Đây là chỗ khoe "vết sẹo". Kể quá trình thật:
  giả thuyết đầu tiên → cách bạn kiểm chứng → nó sai ở đâu → giả thuyết đúng.
  Nêu công cụ cụ thể (log gì, metric nào, profiler nào).
  Bottleneck nằm ở đâu: CPU, RAM, I/O, network, hay khóa?
  Một giả thuyết sai được kể ra có giá trị hơn ba kết luận đúng kể suông —
  nó chứng minh bạn thật sự đã ở đó.

---
Đánh đổi (200-250 từ)
  Liệt kê các phương án đã cân nhắc, kèm chi phí thật: tiền, thời gian, nợ kỹ thuật.
  Nói rõ vì sao bạn chốt phương án này chứ không phải phương án kia.
  Kèm cả phương án bạn đã loại và lý do — đây là phần interviewer đào sâu nhất.

---
Kết quả đo được (150-200 từ)
  Chỉ số trước → sau, kèm cách đo.
  Cấm: "nhanh hơn", "mượt hơn", "tốt hơn".
  Kèm cả chỉ số **xấu đi** nếu có (ví dụ: dung lượng tăng, build chậm hơn).

---
Giới hạn & điều tôi sẽ làm khác
  Thứ chưa giải quyết được, và với hiểu biết hiện tại bạn sẽ tiếp cận khác ở đâu.
```

## Kiểm tra trước khi coi là xong

- Có ít nhất một chỗ bạn **sai** rồi sửa? Không có thì bài đang được kể lại quá gọn.
- Mỗi con số có nguồn đo?
- Quyết định nào cũng có "vì sao không chọn cái kia"?
- Có chỉ số nào xấu đi được nêu ra không?
