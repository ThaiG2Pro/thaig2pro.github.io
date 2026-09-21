---
name: content-bench
description: Viết và CHẠY THỬ code bằng chứng trong bench/<slug>/ cho một bài blog — dựng lại cơ chế của bài thành một demo người lạ chạy được, xác minh nó bằng Docker, rồi ghi kết quả thật vào README. Dùng skill này khi một bài cần bằng chứng chạy lại được, khi người dùng nói "viết bench", "code minh họa", "làm sao người đọc chạy lại được", "kiểm tra bench có chạy không", "bench bị lỗi", hoặc khi checklist publish báo bench chưa được xác minh. Dùng cả khi rà lại một bench cũ đã publish.
---

# Dựng bench chạy được

Bench là lời hứa công khai: *bạn chạy lại được cái này*. Một bench chưa từng chạy còn
hại hơn không có bench — người đọc thử, gặp lỗi, và mất niềm tin vào cả bài lẫn các con
số trong đó.

Luật duy nhất không được vi phạm: **chưa chạy thì chưa xong.** Code trông đúng không
phải là bằng chứng. Trên blog này, một bench "đúng về kỹ thuật" đã có bốn lỗi chặn
(thiếu class trung tâm, file schema mồ côi, sai namespace nên không autoload, và không
tương thích phiên bản framework mới) — cả bốn chỉ lộ ra khi thực sự chạy.

## Bench phải đạt hai việc cùng lúc

1. **Tái hiện đúng phát hiện của bài.** Nếu bài nói "test xanh cả khi có lỗi", thì bench
   phải có một bước chạy ra đúng cảnh đó. Đây là phần khó, và là chỗ hay sai nhất: dễ
   viết ra một bench chứng minh *giải pháp hoạt động* trong khi bài nói về *vì sao không
   ai phát hiện ra vấn đề*. Hai thứ đó cần hai test khác nhau.
2. **Người lạ chạy được.** Không có code công ty, không có biến môi trường bí mật, không
   có bước "sửa cho hợp dự án của bạn" nằm giữa đường.

## Quy trình

### Bước 1 — Viết ra kịch bản chạy trước khi viết code

Liệt kê từng bước người đọc sẽ gõ, kèm kết quả **kỳ vọng** ở mỗi bước. Kịch bản này về
sau thành mục *How to run* trong README. Viết trước để phát hiện sớm những bước không
có thật.

Đặc biệt kiểm: bước nào minh họa **phát hiện** của bài? Nếu không có bước nào, bench
đang chứng minh nhầm thứ.

### Bước 2 — Viết code, đủ tự chứa

- Mọi class mà test gọi tới đều phải có mặt trong thư mục. Đừng để `service()` trỏ vào
  hư không.
- Schema phải được **nạp thật** trong code test, đừng để file `.sql` nằm đó mà không ai
  đọc.
- Namespace phải khớp quy tắc autoload mặc định của framework, để khỏi đụng
  `composer.json`.
- Một hằng số hoặc một cờ để lật giữa bản hỏng và bản đã sửa — đó là cách rẻ nhất cho
  người đọc thấy khác biệt.

### Bước 3 — Chạy thật bằng Docker

Không cài runtime lên máy người dùng. Dựng môi trường sạch, chạy **từng bước trong kịch
bản**, so với kết quả kỳ vọng.

```bash
docker run --rm -v "$PWD/bench/<slug>:/b:ro" -v "/path/verify.sh:/verify.sh:ro" \
  <image>:<tag> bash /verify.sh
```

Chạy trên **phiên bản mới nhất** của framework/thư viện, không chỉ phiên bản bạn dùng
ở công ty — người đọc sẽ cài bản mới nhất. Không tương thích thì sửa code cho chạy được
cả hai, hoặc ghi rõ phiên bản trong README.

Bước nào ra khác kỳ vọng thì **sửa code hoặc sửa kịch bản**, rồi chạy lại từ đầu. Đừng
sửa mỗi README cho khớp cái đang chạy — làm vậy là lặng lẽ đổi lời hứa của bài.

### Bước 4 — README ghi đúng cái đã chạy

Gồm: câu hỏi bench trả lời · phương pháp · kịch bản từng bước với kết quả thật · phiên
bản đã kiểm · và mục **"What this does not measure"** liệt kê thẳng những gì bench
không chứng minh được.

Mục cuối là mục đáng giá nhất. Nó chặn trước câu hỏi khó nhất trong phỏng vấn, và nó
cho thấy bạn phân biệt được cái mình chứng minh được với cái mình chỉ kể lại.

### Bước 5 — Ghi lại

`git add bench/<slug>/` — thư mục chưa commit thì link trong bài là 404. Kiểm bằng
`git ls-files bench/`.

Cập nhật `pipeline/state.json`: `evidence.repro`, `paths.bench`, và ghi vào `history`
rằng bench đã chạy thật trên phiên bản nào.

## Ranh giới

Bench dựng lại **cơ chế**, không mang theo code công ty. Số đo từ hệ thống riêng tư thì
không tái hiện được — bài phải nói thẳng điều đó thay vì để người đọc tưởng bench sinh
ra những con số ấy (`CONTENT_STYLE.md` mục "Bằng chứng của thể loại A").
