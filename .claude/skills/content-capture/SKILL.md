---
name: content-capture
description: Ghi nhanh nguyên liệu content vào inbox của blog — một sự cố, một quyết định kỹ thuật, một con số vừa thấy, hay một lần hiểu sai rồi vỡ ra. Dùng skill này khi người dùng kể một chuyện vừa xảy ra trong lúc code hoặc làm việc ("hôm nay fix được...", "query này chạy mất 4 giây", "tôi vừa chọn X thay vì Y vì...", "hóa ra tôi hiểu sai về..."), khi họ nói "ghi lại cái này", "cho vào inbox", "lưu ý tưởng bài viết", hoặc khi họ vừa kết thúc một phiên debug/tối ưu và có vẻ sắp quên mất chi tiết. Chủ động gợi ý dùng skill này khi thấy trong cuộc hội thoại vừa xuất hiện một con số đo được hoặc một quyết định đánh đổi.
---

# Bắt nguyên liệu vào inbox

Nút thắt của blog cá nhân không phải khả năng viết, mà là **quên mất chuyện gì đã xảy
ra**. Con số "trước khi sửa" không dựng lại được sau hai tuần — mà đó chính là con số
làm bài viết có giá trị. Skill này phải rẻ: dưới 2 phút, không hỏi nhiều.

Spec: `CONTENT_STYLE.md` mục 2.

## Quy trình

1. Phân loại nguyên liệu vào 1 trong 4 loại:
   - **1 — Sự cố:** một thứ vỡ/chậm/sai
   - **2 — Quyết định:** có ≥2 lựa chọn và bạn chốt một
   - **3 — Con số:** một số vô tình nhìn thấy
   - **4 — Vỡ lẽ:** hiểu sai rồi hiểu lại

2. Rút từ hội thoại càng nhiều càng tốt. **Chỉ hỏi lại những gì thật sự thiếu**, tối đa
   2 câu hỏi, gộp trong một lượt. Ưu tiên hỏi con số trước khi sửa và đường dẫn
   code/log — hai thứ này mất đi thì không lấy lại được.

3. Nếu người dùng không có con số, **đừng ép**. Ghi `Số: chưa đo` và để cổng đo ở
   `/content-triage` xử lý sau. Ép có số ngay tại đây sẽ khiến họ bịa hoặc bỏ ghi.

4. Nối vào cuối `drafts/inbox.md` theo đúng mẫu:

```
## YYYY-MM-DD — <một dòng chuyện gì>
- Loại: 1|2|3|4
- Số: <trước> → <sau>  |  chưa đo
- Nguồn: <đường dẫn code/log/PR/commit>
- Ghi chú: <2-3 câu, viết như nói, không cần hay>
```

5. Thêm mục vào `pipeline/state.json` với `stage: "inbox"`, `genre: null`, slug
   kebab-case đặt từ tiêu đề. Nối một dòng vào `log`.

   **`inbox.md` riêng tư, `state.json` công khai.** Inbox giữ nguyên ticket ID, mã SKU
   thật, đường dẫn module, commit hash — đó là thứ giúp dựng lại chi tiết sau này. Nhưng
   `state.json` được git track trên repo công khai, nên `title`, `evidence` và
   `next_action` phải khử định danh trước khi ghi: bỏ ID nội bộ, đổi mã hàng thật thành
   `SKU-A`, đổi đường dẫn module thành mô tả vai trò ("service tính tồn khả dụng").
   Giữ nguyên con số và cơ chế — chúng không cần định danh để hiểu được.
   Quy tắc đầy đủ: `CONTENT_STYLE.md` mục 3b.

## Nguyên tắc

- **Không viết hộ thành đoạn văn hay.** Inbox là ghi chú thô. Làm đẹp ở đây là lãng
  phí và làm người dùng ngại ghi lần sau.
- **Không đề xuất viết bài ngay.** Phân luồng là việc của `/content-triage`. Trộn hai
  việc làm hành động bắt đầu trở nên nặng.
- Một chuyện có thể sinh nhiều mục inbox — tách ra nếu chúng có số liệu khác nhau.

## Trả lời

Một dòng xác nhận đã ghi (slug + loại), và nếu đang thiếu con số hoặc nguồn thì nói rõ
sẽ cần bổ sung ở bước nào. Không tóm tắt lại nội dung vừa ghi.
