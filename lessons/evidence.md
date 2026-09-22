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

## L-016 · 2026-09-22 · sự-kiện-kể-chuyện-bịa
**Lỗi:** bài thể loại D (kể chuyện) viết ra **sự kiện chưa xảy ra**, không phải con số.
Bản nháp bài feature flag kể: "dựng ví dụ số giả định, trình bày cho người quản lý sản
phẩm và trưởng nhóm bên kia, họ đồng ý không cần tranh luận", "phải giải thích lại
nhiều lần", "nhắc lại nhiều lần", "khách hàng lớn đang chờ, ngày ra mắt đã chốt với đối
tác", "làm ngược thứ tự thì chậm lại vài giờ". Mục inbox tương ứng không có sự kiện nào
trong đó, và còn ghi rõ *"chưa đo, flag vẫn false trên production"* — tức là phần Cái giá
kể hậu quả của một việc **chưa kết thúc**.
**Ai bắt:** `/content-audit` vòng 1, lượt soi thứ hai (khẳng định không phải con số).
**Vì sao lọt:** thể loại D không bắt buộc có số, nên cổng số (checklist mục 5) gần như
không có gì để soi. L-014/L-015 nhắm vào **khẳng định bối cảnh** ("dự án không có X") và
**lượng từ**; một câu kể *"tôi đã làm A, họ phản ứng B"* không thuộc hai lớp đó nên đi
qua. Cơ chế sinh lỗi giống L-010: khung D yêu cầu mục "Quyết định" và "Cái giá" có
độ dài nhất định, inbox chỉ có ba dòng, nên bước viết **tự điền** cho đủ khung.
**Dấu hiệu:** trong bài D, mọi câu có **người khác hành động hoặc phản ứng** (đồng ý, hỏi
lại, từ chối, sốt ruột) và mọi câu ở mục Cái giá viết ở **thì quá khứ hoàn thành** trong
khi inbox ghi việc còn đang dở. Phép thử: với mỗi sự kiện, tìm được dòng inbox nào kể nó
không? Không có → hoặc bổ inbox bằng `/content-capture` (nếu thật), hoặc xóa.
**Đã vá:** chưa vá — lần đầu gặp. Đề xuất nếu lặp: thêm vào
`references/genre-d-storytelling.md` một bước "liệt kê từng sự kiện có người khác tham
gia, trỏ về dòng inbox", và `/content-audit` vòng 1 soi mục Cái giá của bài D trước.

## L-017 · 2026-09-22 · mốc-thời-gian-bịa
**Lỗi:** bài viết *"Đầu tháng 9 năm ngoái"* / *"Early last September"* trong khi mục inbox
ghi ngày 2026-09-08 và bài đăng ngày 2026-09-22 — sự việc xảy ra hai tuần trước, cùng
năm. Thể loại D **bắt buộc có mốc thời gian**, và mốc đó bị viết sai.
**Ai bắt:** `/content-audit` vòng 1.
**Vì sao lọt:** "năm ngoái" là chữ, không phải chữ số, nên cổng số không bắt. Checklist
D kiểm "có mốc thời gian chưa" (có/không), không kiểm "mốc đó khớp inbox chưa". Bước viết
điền mốc theo phản xạ kể chuyện (kể chuyện thì "hồi đó"), không tra ngày trong inbox.
**Dấu hiệu:** mọi cụm thời gian tương đối — *năm ngoái, hồi đó, vài tháng trước, gần đây*
— trong bài D. Phép thử một lệnh: `grep -n '^## 20' drafts/inbox.md` lấy ngày mục nguồn,
so với `date` trong front matter.
**Đã vá:** chưa vá — lần đầu gặp. Đề xuất nếu lặp: khung D đổi mục kiểm "có mốc" thành
"mốc khớp ngày mục inbox".

## L-018 · 2026-09-22 · suy-nghĩa-dữ-liệu-từ-hướng-sửa
**Lỗi:** bước viết **định nghĩa** một giá trị của hệ khác bằng suy luận. Inbox bài feature
flag chỉ ghi hành vi code — "chỗ này ép `NULL` về 0, chỗ kia coi `NULL` là vô hạn" — và
hướng sửa — "rào reserved trước, nới `NULL` sau". Từ hướng sửa, bản nháp suy ra *"`NULL` là
giá trị có nghĩa: không quota riêng thì bán theo kho chung"* và viết như thiết kế đã biết.
Tác giả tra lại: sai. Chế độ do một **cột riêng** mang; `NULL` chỉ là hệ quả của một bất
biến, và tài liệu thiết kế ghi rõ *không* mã hóa chế độ bằng `NULL`. Cùng lúc lộ thêm một
sai lệch nhỏ hơn trong chính inbox: "mọi đơn chế độ mới fail" — đúng là "mọi đơn **theo kho
chung** fail". Bản nháp lượt 1 còn gộp hai kịch bản lỗi ngược nhau (bật sớm = từ chối hết;
nới trước rào sau = bán vượt kho) thành một, vì đọc inbox chưa kỹ.
**Ai bắt:** `/content-audit` lượt 2 — không kiểm được nên chặn và hỏi ngược tác giả; tác
giả tra proposal và design doc rồi trả lời. Không cổng tự động nào bắt.
**Vì sao lọt:** mục inbox ba dòng ghi *code làm gì* và *sửa theo thứ tự nào*, không ghi
*giá trị đó nghĩa là gì theo nghiệp vụ* và *tập bị ảnh hưởng chính xác là tập nào*. Khung
bài đòi một đoạn cơ chế, nên bước viết lấp chỗ trống bằng suy luận nghe hợp lý — cùng cơ
chế với L-010 (số bịa) và L-016 (sự kiện bịa), lần này ở tầng **định nghĩa dữ liệu**.
L-014 soi khẳng định dạng "dự án không có X"; câu "X nghĩa là Y" không thuộc lớp đó nên
lượt audit đầu không hỏi. Tệ hơn: câu suy ra lại **hợp lý hơn** bản gốc của inbox, nên
tự đọc lại thấy trôi.
**Dấu hiệu:** mọi câu dạng *"`X` nghĩa là …"*, *"`NULL` means …"*, *"giá trị này biểu
thị …"* về dữ liệu của hệ **mình không sở hữu**, mà dòng inbox tương ứng chỉ mô tả code
đọc nó thế nào. Và mọi cụm *"mọi đơn / all orders / toàn bộ"* — hỏi ngay: mọi = tập nào,
inbox ghi tập đó chưa? Hai câu hỏi này rẻ, tác giả trả lời được trong một phút, và không
trả lời được thì interviewer sẽ hỏi đúng câu đó.
**Đã vá:** chưa vá — lần đầu gặp ở tầng này. Đề xuất nếu lặp: `/content-capture` với mục
có hành vi dữ liệu lệch nhau phải ghi thêm hai dòng — "nghĩa nghiệp vụ của giá trị trung
tâm, theo tài liệu nào" và "tập bị ảnh hưởng chính xác"; `/content-audit` vòng 1 thêm bước
"liệt kê mọi câu định nghĩa dữ liệu và trỏ về dòng inbox".
