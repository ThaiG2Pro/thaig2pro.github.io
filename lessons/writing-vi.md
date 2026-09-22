# Kinh nghiệm viết — tiếng Việt

## Từ điển dịch trật

Thành ngữ kỹ thuật tiếng Anh dịch thẳng ra thì đúng chữ nhưng không ai nói vậy. Người
đọc phải dừng lại đoán — đó là cảm giác "ghép từ rời".

| Tiếng Anh | Dịch trật | Viết đúng |
|---|---|---|
| write path / read path | đường ghi / đường đọc | chỗ ghi dữ liệu / lượt đọc |
| a live MySQL | một MySQL sống | một MySQL thật đang chạy |
| the trait rots | cái trait mục ruỗng | đoạn code âm thầm hỏng mà không ai biết |
| catches the shape of the mistake | bắt hình dạng của sai lầm | chỉ bắt được lỗi *trông giống* lỗi |
| the call disappeared | lời gọi biến mất | dòng gọi khóa bị xóa mất |
| the boring one | cái nhàm chán nhất | ban đầu tôi nghĩ đơn giản |
| silent no-op | no-op im lặng | im lặng biến mất / không làm gì mà không báo |
| drop-in | thả vào là chạy | không phải bản dùng ngay, phải chỉnh |

Gặp thành ngữ mới dịch trật thì thêm một dòng vào bảng này.

---

## L-001 · 2026-09-21 · dịch-thành-ngữ
**Lỗi:** bản VI đầy thành ngữ Anh dịch thẳng, người đọc bản ngữ không hiểu nổi.
**Ai bắt:** người đọc, sau khi bài đã qua checklist publish.
**Vì sao lọt:** checklist chỉ kiểm cấu trúc và số liệu, không kiểm văn có đọc được không.
**Dấu hiệu:** đọc to một đoạn mà phải dừng giữa câu để ghép nghĩa.
**Đã vá:** `CONTENT_STYLE.md` mục "Viết tiếng Việt cho ra tiếng Việt" + bảng trên.

## L-002 · 2026-09-21 · ép-số-từ
**Lỗi:** luật cũ bắt bản dịch rút xuống 600-750 từ (cắt 60-70%). Để đạt con số đó, mọi
câu bị nén tối đa, từ nối bị nuốt, ra văn điện tín.
**Ai bắt:** người đọc.
**Vì sao lọt:** luật do tôi viết, và nó nghe hợp lý — "bản phụ thì ngắn hơn".
**Dấu hiệu:** bản VI ngắn hơn bản EN. Tiếng Việt cần **nhiều** chữ hơn cho cùng một ý.
**Đã vá:** `CONTENT_STYLE.md` mục Độ dài — cắt **ý** thừa, không cắt **chữ**.

## L-003 · 2026-09-21 · bỏ-mắt-xích
**Lỗi:** bài do người đã sống trong sự cố viết, nên bỏ qua những mắt xích với tác giả là
hiển nhiên. Ba chỗ thiếu: hậu quả không có ví dụ số, không giải thích vì sao review vẫn
duyệt, và nói "công cụ cư xử lạ" mà không nói vì sao.
**Ai bắt:** người đọc, hỏi "cái này là gì" ở 10 chỗ.
**Vì sao lọt:** tác giả tự đọc lại thì thấy trôi chảy — vì đã biết đáp án.
**Dấu hiệu:** đưa cho kỹ sư không làm trong dự án; chỗ nào họ hỏi là chỗ thiếu.
**Đã vá:** `CONTENT_STYLE.md` mục "Giải thích mắt xích"; `/content-write` Bước 2b.

## L-004 · 2026-09-21 · danh-từ-hóa
**Lỗi:** "khẳng định trên SQL sinh ra", "lượt đọc pool có lock" — tiếng Anh sống bằng
danh từ, tiếng Việt sống bằng động từ.
**Dấu hiệu:** câu nhiều danh từ ghép liên tiếp, ít động từ.
**Đã vá:** cùng mục với L-001. Nguyên tắc: **ưu tiên động từ hơn danh từ**.

## L-005 · 2026-09-21 · gloss-không-phải-lỗi
**Lỗi (ngược):** có lúc reviewer đề nghị bỏ ngoặc tiếng Anh ở tiêu đề — `## Đánh đổi
(Trade-offs)` → `## Đánh đổi`. Sai: đó là giọng sẵn có của blog từ các bài đầu.
**Vì sao nhầm:** hai luật trong spec đọc thành mâu thuẫn.
**Ranh giới đúng:** tiêu đề và lần đầu xuất hiện khái niệm → Việt kèm Anh trong ngoặc.
Trong thân câu sau lần đầu → dùng từ tiếng Việt ("cái khóa", không phải "cái lock").
**Đã vá:** `CONTENT_STYLE.md`, đoạn "Chú giải trong ngoặc là quy ước của blog này".
