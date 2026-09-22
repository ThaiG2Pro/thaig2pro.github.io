# Kinh nghiệm — số liệu và bằng chứng

## L-010 · 2026-09-21 · số-bịa
**Lỗi:** bài viết ra con số "suite chậm thêm 1,2 giây" — không có trong `drafts/inbox.md`,
không có trong `bench/`, không có ở đâu cả. Sinh ra ngay lúc viết.
**Ai bắt:** người dùng hỏi "nguồn ở đâu vậy?".
**Vì sao lọt:** cổng đo chạy ở bước triage; sau khi mục thành `ready` thì không ai kiểm
lại, nên con số **mới sinh ra lúc viết** đi thẳng vào bài.
**Dấu hiệu:** con số **khiêm tốn và bất lợi cho tác giả** là loại dễ lọt nhất — nó nghe
như tự phê bình nên không gây nghi ngờ. Soi kỹ những con số làm mình xấu đi.
**Đã vá:** `/content-write` checklist mục 5 — liệt kê **từng** con số và truy nguồn từng cái.

## L-011 · 2026-09-21 · gộp-hai-loại-bằng-chứng
**Lỗi:** bài viết "Nguồn: bench/... — cùng máy, cùng một lần chạy phpunit". Sai: con số
1101→1184 đến từ codebase riêng tư, còn `bench/` là bản dựng lại và không bao giờ sinh
ra con số đó.
**Ai bắt:** người dùng hỏi "tại sao yêu cầu github, repo công ty private mà?".
**Dấu hiệu:** một câu "nguồn:" duy nhất trỏ tới `bench/` cho **mọi** con số trong bài A.
**Đã vá:** `CONTENT_STYLE.md` mục "Bằng chứng của thể loại A: tách hai loại".
Tự khai "số này bạn không kiểm chứng được" làm bài **đáng tin hơn**, không phải yếu đi.

## L-012 · 2026-09-21 · số-minh-họa-tưởng-là-thật
**Lỗi:** "Một mã hàng có 200 sản phẩm trong kho" trình bày như dữ kiện hệ thống thật,
trong khi chỉ là ví dụ.
**Đã vá:** số minh họa phải mở đầu bằng "Giả sử" / "Say". Ghi trong `/content-write` mục 5.

## L-013 · 2026-09-21 · link-không-bấm-được
**Lỗi:** bài ghi `` `bench/<slug>/` `` dạng text. Người đọc đang ở trên trang blog, không
có repo trong tay — nên lời mời "chạy lại được" là nói suông.
**Dấu hiệu:** tham chiếu `bench/` không nằm trong `[...](https://...)`.
**Đã vá:** `CONTENT_STYLE.md` mục Quy ước kỹ thuật — **bằng chứng không bấm vào được thì
không phải bằng chứng**. Thư mục bench phải trùng slug bài.

## L-014 · 2026-09-22 · khẳng-định-bối-cảnh-không-ai-kiểm
**Lỗi:** bài A viết một khẳng định **phủ định về bối cảnh** mà không ai kiểm, vì nó
không phải con số nên không rơi vào cổng nào. Ví dụ thật: bản nháp bài selector giải
thích vì sao bug lọt lên staging bằng câu *"dự án chưa có bộ khung test trình duyệt nào;
dựng lên là việc vài ngày"* — dùng làm lý do loại một phương án trong mục Đánh đổi. Đi
kiểm thì ngược hẳn: Playwright được khai sẵn trong `package.json`, tám thay đổi khác
cùng repo đều có thư mục spec riêng, đồng nghiệp đang dùng nó ngay trong tháng đó. Phần
việc này chỉ không có spec của riêng nó.
**Ai bắt:** tác giả, khi `/content-audit` hỏi ngược "sau khi sửa có chạy lại QC hay thêm
test nào không" — câu hỏi nhắm vào con số, nhưng lúc đi tra `git log` và `package.json`
để trả lời thì lộ ra khẳng định bối cảnh sai.
**Vì sao lọt:** cổng đo (`CONTENT_STYLE.md` mục 3) và checklist mục 5 đều chỉ soi **con
số**. Một câu như "chúng tôi không có công cụ X" không có chữ số nào nên đi thẳng qua cả
hai. Tệ hơn: nó nghe như một hạn chế khách quan, tức là **có lợi cho tác giả** — nó giải
thích vì sao không làm việc lẽ ra phải làm, nên chính tác giả cũng không muốn kiểm lại.
**Dấu hiệu:** mọi câu dạng *"dự án không có X"*, *"không có ai/không có môi trường để
Y"*, *"X sẽ mất vài ngày"* — đặc biệt khi nó đứng làm **lý do loại một phương án** trong
mục Đánh đổi, hoặc làm **lời giải thích vì sao bug lọt**. Phép thử một lệnh: khẳng định
đó có tra được bằng `git log`, `package.json`, hay một lần `grep` trong repo không? Tra
được mà chưa tra thì chưa được viết.
**Vì sao nó đắt hơn số bịa:** đây đúng chỗ interviewer đào — "thế sao anh không viết
test?". Trả lời "chúng tôi không có hạ tầng" mà sự thật là có, thì mất nhiều hơn một con
số sai. Ngược lại, bản đúng lại làm bài mạnh hơn hẳn: "hạ tầng có sẵn, đồng nghiệp đang
dùng ở ticket khác, phần việc này không dùng" là một vòng lặp khép kín, mạnh hơn nhiều
so với "chúng tôi thiếu công cụ".
**Đã vá:** lần đầu chỉ ghi nhận. Lặp lần hai trong cùng một bài — xem L-015 — nên đã
nâng thành luật: `CONTENT_STYLE.md` mục 3 ("Khẳng định về bối cảnh cũng phải truy nguồn")
và `/content-audit` vòng 1.

## L-015 · 2026-09-22 · lượng-từ-thay-cho-số-đếm
**Lỗi:** L-014 tái phát trong **chính bài đã sinh ra nó**, ở dạng khác: thay vì một
khẳng định phủ định, lần này là một **lượng từ mơ hồ đứng thay cho con số chưa đếm**.
Mục Đánh đổi loại phương án "sửa selector rồi ship" bằng câu *"thông báo tiếp theo trỏ
vào một ô đang ẩn — mà modal này có **vài** ô như vậy — sẽ biến mất y hệt"*. Không có
nguồn nào cho chữ "vài": `grep` toàn bộ `drafts/inbox.md` ra 0 kết quả, mục inbox chỉ
ghi đúng **một** field. Con số đó chưa bao giờ được đếm.
**Ai bắt:** `/content-audit` vòng 1, lượt soi thứ hai của cùng một bài — sau khi L-014
đã được ghi vào kho. Vòng soi đầu không bắt được.
**Vì sao lọt:** "vài" không phải chữ số nên nó đi qua cổng đo (`CONTENT_STYLE.md` mục 3)
và checklist mục 5, y hệt L-014 — hai cổng đó đều tìm **ký tự số**. Tệ hơn: L-014 lúc
ấy đã nằm trong `lessons/` rồi, nhưng nó được viết bằng ví dụ *phủ định* ("dự án không
có X"), nên lượt soi đầu đọc L-014 xong vẫn không nhận ra một câu **khẳng định** cùng
lớp. Ghi nhận ở kho kinh nghiệm không thay được một cổng chặn.
**Bằng chứng tôi tự viết ra rồi bỏ qua:** `bench/selector-jquery-lot-len-staging/README.md`
mục "What this does not measure" ghi thẳng *"the count in the real modal is a claim from
the incident, not something reconstructed here"*. Viết được câu đó mà vẫn để nguyên chữ
"vài" trong bài.
**Dấu hiệu:** mọi lượng từ không đếm — **vài, nhiều, hầu hết, thường xuyên, một số, đa
số, hiếm khi** — đứng ở chỗ lẽ ra là một con số. Soi trước hai vị trí, giống L-014: câu
**loại một phương án** trong mục Đánh đổi, và câu **giải thích vì sao bug lọt**. Ở hai
chỗ đó, lượng từ luôn có lợi cho tác giả: nó phóng to vấn đề vừa đủ để phương án đã chọn
nghe hợp lý.
**Vì sao nó đắt:** interviewer hỏi "vài là mấy?" là câu hỏi rẻ nhất trên đời, và không
trả lời được thì mọi con số khác trong bài cũng mất giá theo.
**Đã vá:** nâng thành luật ở hai chỗ, cùng với L-014 — `CONTENT_STYLE.md` mục 3, tiểu
mục "Khẳng định về bối cảnh cũng phải truy nguồn"; và `/content-audit` vòng 1, bước liệt
kê khẳng định bối cảnh kèm lệnh đã dùng để kiểm.
