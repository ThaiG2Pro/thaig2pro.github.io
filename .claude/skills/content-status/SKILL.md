---
name: content-status
description: Bảng điều khiển dây chuyền content của blog — cho biết tuần này cần làm gì tiếp theo, mục nào đang kẹt, tháng này đã đủ chỉ tiêu bài A/B chưa. Dùng skill này bất cứ khi nào người dùng hỏi "tuần này làm gì", "đang đến đâu rồi", "status content", "tiếp theo viết gì", "tôi đang kẹt ở đâu", mở đầu một phiên làm việc về blog, hoặc khi họ quay lại sau một thời gian không đụng tới blog. Đây cũng là skill mặc định khi người dùng nói về blog mà chưa rõ muốn làm gì cụ thể.
---

# Bảng điều khiển dây chuyền content

Đây là cửa vào của cả bộ skill. Người dùng có ADHD và làm quy trình này trong nhiều
tuần — họ sẽ không nhớ tuần trước dừng ở đâu. Việc của skill này là trả lời đúng một
câu: **bây giờ làm gì tiếp**, và chỉ đưa ra **một** hành động khởi động được ngay.

Spec dây chuyền: `CONTENT_STYLE.md` (đọc khi cần giải thích tầng nào đó).
Trạng thái: `pipeline/state.json`.

## Quy trình

1. Đọc `pipeline/state.json`. Không có hoặc rỗng → đây là lần đầu: nói thẳng là chưa
   có mục nào, và hành động duy nhất là chạy `/content-capture` để ghi nguyên liệu
   đầu tiên.
2. Đọc `drafts/inbox.md`, đếm các mục chưa có trong `pipeline.json` — đó là hàng chờ
   phân luồng.
3. Tính chỉ tiêu tháng hiện tại: đã publish mấy bài, trong đó mấy bài thuộc A/B.
4. Với mỗi mục đang chạy, xác định **việc kế tiếp** theo bảng dưới.
5. Chọn **một** việc ưu tiên nhất và đặt nó ở dòng đầu tiên của câu trả lời.

## Việc kế tiếp theo stage

| stage | Nghĩa | Việc kế tiếp | Skill |
|---|---|---|---|
| `inbox` | mới ghi, chưa qua cổng đo | chạy cổng đo + phân luồng | `/content-triage` |
| `needs-measure` | thiếu số hoặc thiếu phương pháp | thiết kế và chạy phép đo | `/content-measure` |
| `ready` | đã có bằng chứng + thể loại | viết bản gốc | `/content-write` |
| `drafting` | bản gốc đang dở | viết tiếp phần còn thiếu | `/content-write` |
| `needs-translation` | bản gốc xong, thiếu bản dịch | viết bản rút gọn | `/content-write` |
| `needs-assets` | thiếu ảnh cover/sơ đồ | thiết kế và dựng ảnh | `/content-artwork` |
| `needs-bench` | bench chưa viết, chưa chạy thử, hoặc đang lỗi | dựng và chạy thật bằng Docker | `/content-bench` |
| `published` | đã lên, chưa cắt dẫn xuất | cắt CV/STAR/video trong 24h | `/content-derive` |
| `done` | đã cắt xong | — | — |

## Ưu tiên khi nhiều mục cùng chạy

Xếp theo thứ tự này, lý do: mục càng gần đích càng nên đẩy nốt, vì giá trị chỉ hiện
thực hóa khi bài lên; còn mục `published` chưa cắt dẫn xuất thì mỗi ngày trôi qua càng
đắt vì trí nhớ phai.

1. `published` chưa dẫn xuất (quá 24h thì đánh dấu trễ)
2. `needs-translation` / `needs-assets` / `needs-bench` (gần xong nhất)
3. `drafting`
4. `ready`
5. `needs-measure`
6. `inbox`

Nếu tháng này chưa có bài A/B nào và đã qua ngày 15 → nâng mục A/B gần nhất lên đầu,
nói rõ lý do là chỉ tiêu tháng.

## Định dạng trả lời

Dòng đầu là **một** hành động chạy được ngay, kèm slug và skill cần gọi. Sau đó:

```
## Đang chạy
<bảng: slug | thể loại | stage | việc kế tiếp | kẹt ở>   ← tối đa 5 dòng

## Tháng này
<x/2 bài đã publish · y/1 bài A hoặc B>

## Kẹt
<chỉ liệt kê mục có blocked_on, tối đa 3>
```

Không tóm tắt lại cả dây chuyền, không giải thích các tầng trừ khi được hỏi. Quá 5
mục đang chạy thì chỉ hiện 5 mục ưu tiên cao nhất và ghi "còn N mục khác".

Kết thúc bằng đúng một dòng: việc kế tiếp và cách bắt đầu nó trong dưới 2 phút.
