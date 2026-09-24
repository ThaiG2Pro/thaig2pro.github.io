# Kinh nghiệm — quy trình và môi trường

## L-050 · 2026-09-21 · rò-rỉ-nằm-ngoài-content/
**Lỗi:** quét định danh chỉ làm ở tầng bài viết. Hai rò rỉ thật lại nằm chỗ khác:
1. `pipeline/state.json` — 12 dòng history ghi mã dự án nội bộ
2. `CONTENT_STYLE.md` — chính mục luật khử định danh lại **dùng định danh thật** làm ví dụ
**Đã vá:** `scripts/scan-identifiers.sh` + hook `pre-commit`, quét **mọi** file sắp commit.

## L-051 · 2026-09-22 · bộ-quét-tự-match-chính-nó
**Lỗi:** script quét báo lỗi trên chính comment của nó (các ví dụ regex). Và tệ hơn, một
comment chứa **số ticket thật**.
**Đã vá:** đánh dấu `scan-ok` ở cuối dòng để bỏ qua; gỡ định danh thật khỏi comment.

## L-052 · 2026-09-21 · đánh-dấu-xong-khi-còn-placeholder
**Lỗi:** `/content-derive` sinh bản social còn `<link EN>`, `<link VI>`, `<link bench>`
nhưng đã đánh dấu mục là `done`. Dán lên là ra chữ trong ngoặc nhọn.
**Ai bắt:** người dùng, hôm sau — "mới tới phần social nhỉ? đã xong đâu".
**Luật:** file tồn tại không có nghĩa việc đã xong. Điền URL thật, `curl` kiểm 200.
**Đã vá:** `/content-derive` mục "Link phải thật, không được để placeholder".

## L-053 · 2026-09-21 · skill-không-nạp
**Lỗi:** gọi `/content-status` báo Unknown skill.
**Nguyên nhân:** Claude Code quét `.claude/skills/` ở **thư mục gốc của phiên**. Phiên mở
ở thư mục cha, còn skill nằm trong thư mục con chứa repo.
**Cách xử lý:** mở Claude Code từ **trong** repo blog. Skill mới tạo cũng cần mở lại phiên.

## L-054 · 2026-09-21 · skill-ôm-quá-nhiều-việc
**Lỗi:** `/content-write` ôm cả viết content, vẽ ảnh, lẫn code bench. Kết quả: content phải
sửa 3 vòng, ảnh bị đẩy sang "người dùng tự lo", bench viết ra 6 lỗi chặn.
**Luật:** mỗi skill một chuyên môn. Tách ra thì luật của từng skill mới đủ sâu.
**Đã vá:** tách `/content-artwork` và `/content-bench`.

## L-055 · 2026-09-22 · log-nhắc-tên-định-danh-để-chứng-minh-đã-khử
**Lỗi:** history của một mục trong `pipeline/state.json` ghi *"đã khử định danh"* rồi mở ngoặc
liệt kê luôn mã ticket, tên sản phẩm và tên file thiết kế "không xuất hiện trong bài" — chính câu
báo cáo đã khử lại chép nguyên ba định danh vào file công khai. Lặp lần hai của L-050
(cùng file, cùng loại rò), khác cơ chế: lần này là **bước viết tự ghi log**, không phải
người gõ tay.
**Ai bắt:** `scripts/scan-identifiers.sh` khi `/content-audit` vòng 2 stage file — bắt
được mã ticket theo regex chung; tên sản phẩm chỉ lộ khi đọc tay dòng bên cạnh, vì chưa
có trong `.git/identifiers.local`.
**Vì sao lọt:** bước viết kiểm bài xong thì muốn *chứng minh* đã kiểm, và cách chứng
minh tự nhiên nhất là liệt kê thứ đã loại — tức là chép định danh từ vùng riêng sang
vùng công khai. Checklist mục 6 chỉ hỏi "bài đã khử chưa", không hỏi "log ghi gì".
**Dấu hiệu:** trong `pipeline/state.json` hoặc `lessons/`, mọi cụm *"đã khử (…)"*, *"đã
loại (…)"*, *"không nhắc tới (…)"* có dấu ngoặc mở theo sau. Nội dung trong ngoặc gần
như chắc chắn là định danh thật. Phép thử một lệnh:
`grep -nE "khử định danh \(|đã loại \(|không xuất hiện" pipeline/state.json lessons/*.md`.
**Đã vá:** nâng thành luật ở `CONTENT_STYLE.md` mục 3b, gạch đầu dòng "Log và history".
Thêm tên sản phẩm vào `.git/identifiers.local` để lần sau bộ quét bắt được cả nó.

## L-056 · 2026-09-22 · bộ-quét-bỏ-qua-đối-số
**Lỗi:** `scripts/scan-identifiers.sh <file...>` **không quét file được truyền vào**. Nó
chỉ đọc `git diff --cached`, tức file đang staged — đối số bị bỏ qua hoàn toàn. Trong một
phiên, `/content-write` và `/content-audit` gọi nó 6 lần với đường dẫn hai bài và đều nhận
"Quét định danh: sạch"; thực tế nó đang quét file mà một tiến trình khác vừa stage, hoặc
báo "không có file nào để quét" khi staging rỗng. Lần duy nhất nó bắt được gì (L-055) là
vì `pipeline/state.json` tình cờ đang staged.
**Ai bắt:** `/content-audit` lượt 3, khi câu "không có file nào để quét" xuất hiện dù đã
truyền 4 đường dẫn — đọc script mới thấy dòng `FILES=$(git diff --cached ...)`.
**Vì sao lọt:** script viết cho hook `pre-commit` (không có đối số) rồi được các skill gọi
như một CLI. Thông báo "sạch" không nói *đã quét file nào*, nên không ai nhận ra danh sách
rỗng hoặc lệch.
**Dấu hiệu:** bộ quét trả "sạch" nhanh bất thường, hoặc "không có file nào để quét" khi
đã truyền tên file. Phép thử: cố tình chèn một chuỗi khớp regex vào file rồi quét — không
báo thì bộ quét không nhìn file đó.
**Đã vá:** script nhận đối số: có đối số thì quét đúng các file đó (vẫn áp `EXCLUDE`),
không có thì quét staged như cũ; và in ra số file đã quét thay vì chỉ nói "sạch".

## L-057 · 2026-09-22 · code-nguyên-văn-từ-repo-không-sở-hữu
**Lỗi:** bài và cover chép **nguyên văn một dòng code kèm tên cột thật** từ repo của
team khác — đúng repo mà bài nói "tôi không có quyền merge". Lên site ở cả hai bản và
ảnh Open Graph. Bộ quét không bắt (tên cột không có trong `.git/identifiers.local`), bốn
lượt audit đọc tay cũng không, vì dòng code trông như "cơ chế" chứ không như "định danh".
**Ai bắt:** tác giả, trên bản đã live. So với hai bài trước cùng tuần đã khử sạch (`SKU-A`,
"service tính tồn khả dụng").
**Vì sao lọt:** mục 3b liệt kê ID, mã hàng, đường dẫn module, tên sản phẩm — không có
dòng "code nguyên văn". Bước viết coi snippet là bằng chứng kỹ thuật, và audit vòng 4 hỏi
"người ngoài có suy ra công ty không?" — một dòng code thì không suy ra công ty, nên qua.
Nhưng phép thử đúng ở đây là câu khác: *người trong câu chuyện (team kia) đọc được thì có
ổn không?* — code của họ, chưa xin phép, lên blog của người khác: không ổn.
**Dấu hiệu:** mọi đoạn `code` trong bài A/D không nằm trong `bench/<slug>/` (tức không
phải bản mình dựng lại) và có tên cột / tên hàm / tên biến cụ thể. Phép thử một lệnh:
`grep -nE '`[^`]*[a-z]_[a-z][^`]*`' content/posts/<slug>*.md` — tên có gạch dưới gần như
luôn là tên thật; mỗi hit phải trả lời được "cái này ở bench hay ở repo người khác?".
**Đã vá:** `CONTENT_STYLE.md` mục 3b thêm gạch đầu dòng "Code nguyên văn"; `/content-audit`
vòng 4 thêm bước grep trên.

## L-058 · 2026-09-24 · build-sạch-nhưng-không-sinh-trang
**Lỗi:** bài có `date` 17:00 nhưng push lúc 14:42 cùng ngày. Hugo coi đó là bài tương lai và
bỏ qua **không một dòng cảnh báo**; `hugo --gc --minify` báo sạch, audit hai lượt cũng ghi
"build sạch", nhưng `public/` không có trang. Site live trả 404 cho cả hai ngôn ngữ trong
khi ảnh cover và link bench đều 200.
**Ai bắt:** chạy thật — `curl` URL bài sau deploy, rồi `find public -name index.html` ra rỗng.
**Vì sao lọt:** mọi cổng chỉ hỏi "build có lỗi không". Không cổng nào hỏi "build có sinh ra
trang này không". Archetype đặt `date` bằng giờ tạo file, nhưng bước viết đặt tay 17:00 theo
thói quen "giờ đăng đẹp", và không ai so `date` với giờ build.
**Dấu hiệu:** `date` trong front matter lớn hơn giờ hiện tại, dù chỉ vài giờ. Hoặc
`hugo list future` có dòng. Phép thử một lệnh: `find public -path '*<slug>*' -name
index.html | wc -l` phải ra đúng 2.
**Lặp:** lần thứ hai trong cùng ngày — bài `cong-thuc-tru-hai-lan` gặp y hệt ở phiên khác
(date 14:00 đặt lại sau khi phát hiện `public/` thiếu trang). Hai lần → nâng thành luật.
**Đã vá:** `CONTENT_STYLE.md` mục 8 (bước 1 và 8) và `/content-write` checklist bước 1 và 7:
sau build phải đếm được đúng 2 `index.html` của slug.

## L-059 · 2026-09-24 · hai-phiên-một-repo
**Lỗi:** hai phiên làm hai bài song song trên cùng working tree. (1) Phiên A stage 10 file của
bài của mình chờ commit; phiên B chạy `git add <file của B>` rồi `git commit` — commit gom cả
10 file của A với message nói về bài của B. Bài của A lên site "nhầm", đúng nội dung nhưng
không qua bước push có chủ ý, và lịch sử git nói dối về commit đó. (2) Cả hai phiên nạp
`pipeline/state.json` vào bộ nhớ rồi ghi lại toàn file; bản ghi sau đè bản ghi trước, mất
hai lượt history audit của A và để stage của A kẹt ở `needs-assets` trong khi bài đã live.
**Ai bắt:** `/content-audit` lượt sau, khi thấy bài live mà state nói chưa có ảnh, và
`git log -- content/posts/<slug>` trỏ về một commit tên khác.
**Vì sao lọt:** `git commit` commit **cả index**, không chỉ thứ vừa `add`; và ghi state bằng
"đọc → sửa → ghi cả file" không có gì bảo vệ. Cả hai đều vô hình khi chỉ có một phiên.
**Dấu hiệu:** `git status` trước commit có file staged mà mình không nhớ đã add. `git log
--oneline -- <file>` của một bài trỏ về commit có message nói bài khác. State có `paths`
trỏ tới file không tồn tại.
**Đã vá:** chưa nâng thành luật — lần đầu gặp. Cổng rẻ nên làm ngay: `git diff --cached
--stat` trước mỗi commit và chỉ commit khi mọi dòng thuộc bài đang làm; với state.json, đọc
lại file **ngay trước** khi ghi, không dùng bản đã nạp từ đầu phiên.
