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
| noisy (for anything else) | ồn với thứ khác | sinh báo nhầm với file khác |

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

## L-006 · 2026-09-22 · gồng-văn
**Lỗi:** viết câu để tạo hiệu ứng chứ không để truyền thông tin. Bản nháp bài selector
mở bằng *"«Không có gì» mới là chỗ khó... một modal đứng im và một người dùng không biết
hệ thống đã nghe thấy mình hay chưa"* — đẹp, nhưng người đọc kỹ thuật nhận ra ngay là
tác giả đang diễn. Viết lại thành câu chẩn đoán: *"«Không có gì» là triệu chứng khó nhận
nhất. Sập thì còn stack trace, sai kết quả thì còn con số sai; màn hình không đổi gì thì
không để lại chỗ nào để bắt đầu."* Cùng một ý, bỏ phần diễn.
**Ai bắt:** người đọc, sau khi bài đã qua checklist publish.
**Vì sao lọt:** checklist kiểm cấu trúc, số liệu, thành ngữ dịch trật — không có mục nào
hỏi "câu này để làm gì". Câu gồng lại thường là câu tác giả thích nhất nên càng khó tự cắt.
**Dấu hiệu:** một câu không thêm thông tin nào mới cho câu trước nó, và nếu xóa đi thì
đoạn văn vẫn đủ nghĩa. Hay gặp nhất ở câu thứ hai của bài và ở câu kết mỗi mục.
**Ranh giới:** không phải mọi hình ảnh đều là gồng văn. Câu kết *"Một hệ thống hỏng mà
im lặng lịch sự thì chỉ nhận về một dòng báo lỗi: «bấm vào không thấy gì»"* giữ lại được,
vì nó đóng lại luận điểm của bài chứ không chỉ tạo không khí.
**Đã vá:** chưa nâng thành luật — lần đầu gặp. Ghi ở đây để `/content-audit` soi.

## L-007 · 2026-09-22 · lộ-đáp-án-quá-sớm
**Lỗi:** mục đầu bài selector đã nói thẳng nguyên nhân (*"server từ chối một yêu cầu đòi
giảm số lượng đi 0 đơn vị"*) trước cả mục Mổ xẻ. Người đọc mất lý do đi tiếp: phần điều
tra phía sau chỉ còn là xác nhận thứ họ đã biết. Sửa: mục đầu dừng ở nghịch lý (*"phía
server không có gì sai, mà thao tác vẫn hỏng mọi lần bấm"*), chi tiết `decrease` /
`quantity = 0` để dành cho đúng lúc đọc tab network trong mục Mổ xẻ.
**Ai bắt:** người đọc.
**Vì sao lọt:** đây là mặt trái của L-003. Sợ bỏ mắt xích nên giải thích sớm, mà bỏ mắt
xích và lộ đáp án là hai lỗi khác nhau: **mắt xích là thứ người đọc cần để hiểu câu đang
đọc; đáp án là thứ họ cần để hiểu câu ở mục sau.** Giải thích đủ ≠ giải thích trước.
**Dấu hiệu:** mục Mổ xẻ không còn câu nào làm người đọc bất ngờ. Phép thử: che mục Mổ xẻ
lại, đọc mục đầu — nếu đã trả lời được "vì sao hỏng" thì lộ sớm rồi.
**Đã vá:** chưa nâng thành luật — lần đầu gặp. Ghi ở đây để `/content-audit` soi.

## L-008 · 2026-09-22 · câu-nén-quá-tay
**Lỗi:** nhồi 3-5 ý kỹ thuật độc lập vào một câu, người đọc phải đọc lại lượt hai.
Ví dụ thật trong bản nháp bài selector: *"Gọi `.data('type')` trên một tập rỗng thì nhận
về `undefined`, đoạn ráp dữ liệu rơi vào nhánh mặc định, nên mọi lần gửi đều đi ra dưới
dạng mặc định: giảm, số lượng 0."* — một câu bắt giữ 5 khái niệm cùng lúc. Tách làm ba
câu thì hết vấp, không mất chữ nào. Chỗ thứ hai: câu "cái giá" trong mục Đánh đổi gói ba
loại chi phí khác nhau vào một mệnh đề nối.
**Ai bắt:** người đọc. Cả hai lần đều là người đọc, không phải checklist.
**Vì sao lọt:** đây là **lần lặp thứ hai** — lỗi đã được liệt kê sẵn ở `/content-write`
bước 2b nhóm 3, nhưng nằm trong phần hướng dẫn *đọc lại cùng người dùng*, tức là chỉ
chạy khi có người đọc. Không có cổng nào kiểm được bằng mắt tác giả, và tác giả thì đọc
trôi vì đã biết trước cả 5 ý trong câu.
**Dấu hiệu:** đếm khái niệm kỹ thuật mới trong một câu (tên biến, tên hàm, trạng thái,
giá trị, hệ quả). Quá 2 là nghi; quá 3 gần như chắc chắn phải tách. Dấu hiệu phụ: câu
dài có "nên", "và", ":" nối liên tiếp, hoặc một mệnh đề liệt kê ba chi phí.
**Đã vá:** nâng thành luật — `CONTENT_STYLE.md` mục "Một câu, tối đa hai khái niệm mới"
và mục 8 checklist (bước 6).

## L-009 · 2026-09-24 · noisy-thành-ồn
**Lỗi:** *"treats whitespace as content, which is right for a manifest and noisy for anything
else"* dịch thành *"đúng với manifest nhưng ồn với thứ khác"*. "Noisy" trong tiếng Anh kỹ
thuật nghĩa là "sinh nhiều báo động giả"; "ồn" trong tiếng Việt chỉ là âm thanh.
**Ai bắt:** `/content-audit` vòng 3, đối chiếu bảng từ điển.
**Vì sao lọt:** từ này chưa có trong bảng; hai lượt audit trước đọc trôi vì người đọc đã biết
nghĩa gốc tiếng Anh.
**Dấu hiệu:** tính từ tiếng Anh về **chất lượng tín hiệu** (noisy, flaky, brittle, clean)
dịch bằng tính từ cảm giác tiếng Việt (ồn, bở, sạch) mà không kèm động từ nói nó *làm gì*.
**Đã vá:** thêm dòng vào bảng từ điển đầu file.
