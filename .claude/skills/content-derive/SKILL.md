---
name: content-derive
description: Cắt một bài blog vừa publish thành các tài sản dùng được — gạch đầu dòng CV, thẻ STAR kèm 3 lát cắt Meta/Google/Amazon, kịch bản video 60-90 giây, và post LinkedIn/Facebook. Dùng skill này ngay sau khi publish một bài, khi người dùng nói "cắt bài này ra", "làm kịch bản video từ bài", "viết bullet CV từ cái này", "chuẩn bị kể chuyện này trong phỏng vấn", "làm post LinkedIn", hoặc khi pipeline có mục ở stage published quá 24h chưa dẫn xuất. Dùng cả khi họ đang sửa CV và cần lấy nguyên liệu từ blog.
---

# Cắt dẫn xuất từ bài đã publish

"Một mũi tên trúng bốn đích" là cách **đóng gói lại** một bài đã viết, không phải cách
viết bài. Ép blog viết theo STAR thì blog dở; viết blog tử tế rồi cắt ra STAR thì được
cả hai.

Làm trong 24h sau publish. Lý do: cắt lại rẻ khi còn nhớ chi tiết; để ba tháng sau phải
đọc lại bài từ đầu và những chi tiết không nằm trong bài thì mất luôn.

Spec: `CONTENT_STYLE.md` mục 6.

## Cắt gì theo thể loại

| Thể loại | Dẫn xuất | Nơi lưu |
|---|---|---|
| A, B | gạch đầu dòng CV + thẻ STAR 3 lát cắt | `career/<slug>.md` |
| A, D | thẻ STAR 3 lát cắt | `career/<slug>.md` |
| C, D | kịch bản video 60-90s | `drafts/video-<slug>.md` |
| mọi | post LinkedIn/Facebook | `drafts/social-<slug>.md` |

`career/` nằm trong `.gitignore` — repo này là GitHub Pages công khai, thẻ chuẩn bị
phỏng vấn không được lộ. Kiểm tra lại trước khi ghi.

Mẫu chi tiết: `references/career-card.md` và `references/video-script.md`.

## Nguyên tắc

- **Không thêm dữ kiện mới.** Chỉ dùng thứ đã có trong bài hoặc trong `bench/<slug>/`.
  Nếu thẻ STAR cần chi tiết bài không có, hỏi người dùng — đừng dựng.
- **Gạch đầu dòng CV phải có số.** Không có số thì bài đó không sinh bullet CV được;
  nói thẳng thay vì viết một dòng chung chung.
- **Kịch bản video chỉ một ý.** Bài blog chịu được mật độ chứng cứ cao, video thì
  không. Chọn ý gây ngạc nhiên nhất, bỏ phần còn lại.
- **Không bê nguyên bài kỹ thuật thành video.** Video cần hook 3 giây và một cung cảm
  xúc; blog cần bằng chứng. Cùng nguyên liệu, hai cách đóng gói.

## Sau khi cắt

Cập nhật `pipeline/state.json`: `stage: "done"`, ghi `paths.career`, `paths.video`.
Nếu bài trả lời được một câu behavioral kinh điển (thất bại, mâu thuẫn, deadline, tự
học, quyết định khó), đánh dấu vào `behavioral_coverage` — `/content-review` dùng dữ
liệu này để phát hiện lỗ hổng.

## Trả lời

Dòng đầu: đường dẫn các file vừa sinh. Dán nguyên văn **gạch đầu dòng CV** và **hook
video** vào câu trả lời (hai thứ này ngắn và người dùng sẽ copy ngay); các thứ còn lại
chỉ nêu đường dẫn.
